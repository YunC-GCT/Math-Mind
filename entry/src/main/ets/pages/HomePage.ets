/**
 * MathMind 首页
 * 严格对照 iOS Web MVP: styles.css Hero/.note-card/.fab/progress-ring
 *                      + app.js updateHome() / noteCardHTML()
 */

import {
  MINT,
  MINT_DARK,
  PURPLE,
  BG_DARK,
  BORDER,
  TEXT,
  TEXT_2,
  TEXT_3,
  TEXT_4,
  S_1,
  S_2,
  S_3,
  S_4,
  R_SM,
  R_MD,
  R_LG,
  R_XL,
  R_2XL,
  F_XS,
  F_SM,
  F_BASE,
  F_MD,
  F_LG,
  F_XL,
  F_2XL,
  F_3XL,
} from 'common';
import { promptAction } from '@kit.ArkUI';
import {
  NoteItem,
  NOTES,
  stripMD,
  typeChar,
  typeColor,
  subjectColor,
} from 'common';
import { NoteDetailOverlay } from '../overlays/NoteDetailOverlay';
import { HexLogo } from '../components/HexLogo';

// ========== 本地工具函数 ==========
function greet(): string {
  const h = new Date().getHours();
  if (h < 6) {
    return '凌晨好';
  }
  if (h < 11) {
    return '上午好';
  }
  if (h < 13) {
    return '中午好';
  }
  if (h < 18) {
    return '下午好';
  }
  return '晚上好';
}

function dateStr(): string {
  const d = new Date();
  const w = ['日', '一', '二', '三', '四', '五', '六'];
  return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日 · 周${w[d.getDay()]}`;
}

function confidenceColor(c: number): string {
  if (c > 0.8) {
    return MINT;
  }
  if (c > 0.5) {
    return '#FFFBBF24';
  }
  return '#FFFF6B6B';
}

// ========== 渐变进度环子组件 ==========
@Component
struct GradientRing {
  @Prop pct: number = 75;
  // 动画用的中间值 (从 0 增长到 pct), @State 触发重 render → Canvas 重画
  @State animPct: number = 0;
  // 光晕呼吸: 0.45 ↔ 0.85, 2.6s 循环
  @State glow: number = 0.45;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private fillTimerId: number = -1;
  private glowTimerId: number = -1;
  private glowDir: number = 1;

  aboutToAppear(): void {
    // === 加载填充: 1.4s 内 animPct 从 0 → pct (ease-out cubic) ===
    const startTs: number = Date.now();
    const duration: number = 1400;
    this.fillTimerId = setInterval(() => {
      const elapsed: number = Date.now() - startTs;
      const t: number = Math.min(1, elapsed / duration);
      const eased: number = 1 - Math.pow(1 - t, 3);
      this.animPct = this.pct * eased;
      this.draw();
      if (t >= 1) {
        clearInterval(this.fillTimerId);
        this.fillTimerId = -1;
      }
    }, 16);

    // === 光晕呼吸: glow 在 [0.30, 0.80] 三角波, 步进 0.020 ≈ 3s 一周期 ===
    this.glowTimerId = setInterval(() => {
      this.glow = this.glow + this.glowDir * 0.020;
      if (this.glow >= 0.80) { this.glow = 0.80; this.glowDir = -1; }
      if (this.glow <= 0.30) { this.glow = 0.30; this.glowDir = 1; }
    }, 30);
  }

  aboutToDisappear(): void {
    if (this.fillTimerId !== -1) {
      clearInterval(this.fillTimerId);
      this.fillTimerId = -1;
    }
    if (this.glowTimerId !== -1) {
      clearInterval(this.glowTimerId);
      this.glowTimerId = -1;
    }
  }

  build() {
    Stack() {
      // 背景灰环
      Circle({ width: 104, height: 104 })
        .fill('#00000000')
        .stroke('#0FFFFFFF')
        .strokeWidth(10);

      // Canvas 渐变弧段
      Canvas(this.ctx)
        .width(120).height(120)
        .onReady(() => {
          this.draw();
        });
    }
    .width(120).height(120)
    // 圆形裁切 + 圆角 — 让 shadow 按圆形渲染 (不按矩形边), 模拟真正圆形 glow
    .borderRadius(60)
    .clip(true)
    // 整体 MINT 光晕 (rgba 透明度跟 glow @State 联动, 呼吸效果)
    .shadow({
      radius: 32,
      color: `rgba(91, 227, 176, ${this.glow.toFixed(2)})`,
      offsetX: 0,
      offsetY: 0,
    });
  }

  draw(): void {
    const ctx = this.ctx;
    const cx = 60;
    const cy = 60;
    const r = 52;
    const lw = 10;

    ctx.clearRect(0, 0, 120, 120);

    // 渐变
    const grad = ctx.createLinearGradient(0, 0, 120, 120);
    grad.addColorStop(0, MINT);
    grad.addColorStop(1, PURPLE);

    // 从 12 点钟方向顺时针画弧 (用 animPct 配合动画)
    const start = -Math.PI / 2;
    const sweep = (this.animPct / 100) * 2 * Math.PI;

    ctx.beginPath();
    ctx.arc(cx, cy, r, start, start + sweep);
    ctx.strokeStyle = grad;
    ctx.lineWidth = lw;
    ctx.lineCap = 'round';
    ctx.stroke();
  }
}

// ========== 首页主组件 ==========
@Component
export struct HomePage {
  @StorageProp('statusBarHeight') sbh: number = 0;
  @State notes: NoteItem[] = NOTES;
  @State g: string = '';
  @State d: string = '';
  @State avg: number = 75;
  @State today: number = 0;
  @State selectedNote: NoteItem | null = null;

  // 关闭笔记详情浮层
  closeDetail = (): void => { this.selectedNote = null; };

  // 回调(由 Index.ets 传入,触发 CameraOverlay 浮层)
  onGoCamera: () => void = () => {};

  // 回调(由 Index.ets 传入,点击进度环切到复习 Tab)
  onGoReview: () => void = () => {};

  aboutToAppear(): void {
    this.g = greet();
    this.d = dateStr();
    this.avg = this.notes.length > 0
      ? Math.round(this.notes.reduce((a, n) => a + n.conf, 0) / this.notes.length * 100)
      : 75;
    // 算今日新增笔记数 (date 格式 YYYY-MM-DD 补 0, 对齐 MOCK_NOTES 的 ISO 格式)
    const now: Date = new Date();
    const ts: string = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    this.today = this.notes.filter((n: NoteItem) => n.date === ts).length;
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
          // ===== 状态栏占位 =====
          Row().width('100%').height(this.sbh).backgroundColor(BG_DARK);

          // ===== Header 60vp (W1: 22×22 ic_brand → 32×32 浮空旋转 6 边形 Logo) =====
          Row() {
            HexLogo();
            Text('MathMind')
              .fontFamily('HarmonyOS Sans Condensed')
              .fontSize(18)
              .fontWeight(500)
              .fontColor(TEXT)
              .letterSpacing(0)
              .margin({ left: S_2 });
          }
          .width('100%').height(60)
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor(BG_DARK);

          // ===== Hero 区 =====
          Column() {
            // --- 问候行 ---
            Row() {
              Circle({ width: 6, height: 6 })
                .fill(MINT);
              Text(`${this.g}, Mini`)
                .fontSize(F_XL).fontWeight(600)
                .fontColor(TEXT)
                .margin({ left: 6 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis });
            }
            .width('100%')
            .alignItems(VerticalAlign.Center);

            Text(this.d)
              .fontSize(F_SM).fontColor(TEXT_3)
              .width('100%')
              .textAlign(TextAlign.Start)
              .margin({ top: 4 });

            // --- 进度环 (独立居中，无两侧重复统计) — 点击跳复习 ---
            Stack() {
              GradientRing({ pct: this.avg });
              Column() {
                Text(`${this.avg}%`)
                  .fontSize(26).fontWeight(700).fontColor(TEXT);
                Text('去复习 ›')
                  .fontSize(F_XS).fontColor(MINT).fontWeight(600)
                  .margin({ top: 4 });
              }.alignItems(HorizontalAlign.Center);
            }
            .width(120).height(120)
            .alignSelf(ItemAlign.Center)
            .margin({ top: 16 })
            .onClick(() => this.onGoReview());

            // --- 3 统计方块 ---
            Row() {
              this.SBox(`${this.notes.length}`, '笔记');
              this.SBox(`${this.avg}%`, '掌握率');
              this.SBox(`${this.today}`, '今日新增');
            }
            .width('100%').justifyContent(FlexAlign.SpaceEvenly).margin({ top: 14 });
          }
          .width('100%')
          .padding({
            left: 20,
            right: 20,
            top: 16,
            bottom: 20
          })
          .borderRadius({ bottomLeft: R_2XL, bottomRight: R_2XL })
          // CSS .hero: rgba(91,227,176,0.18)→rgba(151,117,250,0.18)→rgba(255,107,157,0.10)
          .linearGradient({
            angle: 180,
            colors: [
              ['#2E5BE3B0', 0],
              ['#2E9775FA', 0.5],
              ['#1AFF6B9D', 1],
            ],
          });

          // ===== 提醒横幅 (< 3 条才显示) =====
          if (this.notes.length < 3) {
            Row() {
              Text(this.notes.length === 0
                ? '👋 欢迎使用 MathMind！试试 AI 对话或拍照，帮你整理知识笔记 ›'
                : `⏰ 已有 ${this.notes.length} 条笔记，继续用 AI 充实知识库 ›`)
                .fontSize(F_SM).fontColor(MINT).lineHeight(18);
            }
            .width('100%')
            .padding({
              left: 14,
              right: 14,
              top: 10,
              bottom: 10
            })
            .margin({ left: 16, right: 16, top: S_1 })
            .borderRadius(R_MD)
            // CSS .home-reminder: linear-gradient 135deg
            .linearGradient({
              angle: 135,
              colors: [['#1F5BE3B0', 0], ['#0D9775FA', 1]],
            })
            .border({ width: 1, color: '#335BE3B0' });
          }

          // ===== 最近笔记标题 =====
          Text('最近笔记')
            .fontSize(F_BASE)
            .fontWeight(600)
            .fontColor(TEXT)
            .width('100%')
            .padding({
              left: 20,
              right: 20,
              top: S_1,
              bottom: S_1
            })
            .margin({ top: S_1 });

          // ===== 笔记列表（分隔线模式） =====
          Scroll() {
            Column() {
              ForEach(this.notes, (note: NoteItem, i: number) => {
                this.NCard(note, i === this.notes.length - 1);
              }, (note: NoteItem) => note.id.toString());

              Blank().height(48);
            }
            .width('100%')
            .padding({
              left: 20,
              right: 20,
              top: 14,
              bottom: 20
            });
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(BG_DARK);

      // ===== FAB (W1 调整: 改为"用户自定义笔记 - 待开发"提示) =====
      Stack() {
        Text('+')
          .fontSize(22)
          .fontColor('#FF0A0C10')
          .fontWeight(FontWeight.Bold);
      }
      .width(54).height(54)
      .borderRadius(27)
      .linearGradient({ angle: 180, colors: [[MINT, 0], [MINT_DARK, 1]] })
      .shadow({ radius: 28, color: '#595BE3B0', offsetX: 0, offsetY: 8 })
      .margin({ right: 20, bottom: 16 })
      .onClick(() => {
        // FAB 暂不接相机 (后续 W2 改为"用户自定义笔记"创建入口)
        promptAction.showToast({ message: '用户自定义笔记开发中', duration: 1500 });
      });

      // ===== NoteDetailOverlay 浮层 =====
      if (this.selectedNote !== null) {
        NoteDetailOverlay({
          note: this.selectedNote!,
          onClose: () => { this.selectedNote = null; }
        })
      }
    }
    .width('100%').height('100%').backgroundColor(BG_DARK);
  }

  // ========== 统计方块 ==========
  @Builder
  SBox(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(F_MD + 1).fontWeight(700).fontColor(TEXT);
      Text(label)
        .fontSize(F_XS).fontColor(TEXT_3).margin({ top: 2 });
    }
    .layoutWeight(1)
    .padding({ top: 10, bottom: 10 })
    .borderRadius(12)
    .backgroundColor('#08FFFFFF')
    .border({ width: 1, color: BORDER })
    .alignItems(HorizontalAlign.Center);
  }

  // ========== 笔记卡片（分隔线模式） ==========
  @Builder
  NCard(note: NoteItem, isLast: boolean) {
    Row() {
      // 图标 36×36, border-radius 10
      Stack() {
        Row()
          .width(36).height(36).borderRadius(10)
          .linearGradient({
            angle: 135,
            colors: [[typeColor(note.type), 0], [subjectColor(note.subject), 1]],
          });
        Text(typeChar(note.type))
          .fontSize(F_BASE).fontWeight(700).fontColor('#FF0A0C10');
      }
      .width(36).height(36);

      Column() {
        // Meta 行
        Row() {
          Text(note.subject)
            .fontSize(10.5).fontWeight(700).fontColor(subjectColor(note.subject));
          Text(` ${note.type}`)
            .fontSize(10.5).fontWeight(600).fontColor(typeColor(note.type));
          Text(` ${note.date}  `)
            .fontSize(10.5).fontColor(TEXT_3);
          Blank();
          Text(`${Math.round(note.conf * 100)}%`)
            .fontSize(10.5).fontWeight(600).fontColor(confidenceColor(note.conf));
        }
        .width('100%').margin({ bottom: 4 });

        // 标题
        Text(note.title)
          .fontSize(F_MD)
          .fontWeight(600)
          .fontColor(TEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ bottom: 3 })
          .lineHeight(20);

        // 摘要
        Text(stripMD(note.body, 60))
          .fontSize(12.5)
          .fontColor(TEXT_3)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(18.75)
          .width('100%');
      }
      .layoutWeight(1).margin({ left: 12 });
    }
    .width('100%').alignItems(VerticalAlign.Top)
    .padding({ top: 14, bottom: 14 })
    // 分隔线 — 不是独立卡片背景
    .border({
      width: { bottom: isLast ? 0 : 1 },
      color: BORDER,
    })
    .onClick(() => { this.selectedNote = note; });
  }
}
