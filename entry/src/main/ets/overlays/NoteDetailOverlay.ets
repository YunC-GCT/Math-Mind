/**
 * MathMind 笔记详情浮层 — 第 3 批
 *
 * 触发: HomePage / NotesPage 点笔记卡片
 * 流程: 显示笔记详情(学科条 / 标题 / meta / 标签 / 正文 / AI 卡)
 *
 * MVP 阶段:
 *   - 正文章节按 ## 切分渲染(不解析 LaTeX,直接显示纯文本)
 *   - AI 卡按钮 toast 提示"W1 接真 AI"
 *   - 底部"编辑"按钮 toast 提示(后续再做)
 *
 * 依赖:
 *   - common.NoteItem (class, 9 字段)
 *   - common.typeColor / subjectColor (工具函数)
 */

import {
  MINT, MINT_DARK, PURPLE, PINK, AMBER,
  BG_DARK, BG_CARD,
  TEXT, TEXT_2, TEXT_3, TEXT_4, BORDER,
  S_1, S_2, S_3, S_4, S_5,
  R_SM, R_MD, R_LG, R_XL, R_2XL, R_FULL,
  F_XS, F_SM, F_BASE, F_MD, F_LG, F_XL, F_2XL,
  NoteItem, typeColor, subjectColor, recentDate, stripMD,
} from 'common';
import { promptAction } from '@kit.ArkUI';

// 顶层工具(ArkTS 禁 struct 内普通方法)
function confColor(c: number): string {
  if (c >= 0.85) {
    return MINT;
  }
  if (c >= 0.6) {
    return AMBER;
  }
  return '#FF6B6B';
}

function confLabel(c: number): string {
  if (c >= 0.85) {
    return '已掌握';
  }
  if (c >= 0.6) {
    return '一般';
  }
  return '待巩固';
}

// 解析 body 成章节
interface Section {
  title: string;
  content: string;
}

function parseSections(body: string): Section[] {
  if (!body) {
    return [];
  }
  const lines: string[] = body.split('\n');
  const sections: Section[] = [];
  let curTitle = '内容';
  let curLines: string[] = [];

  for (const line of lines) {
    if (line.indexOf('## ') === 0) {
      // 切到新章节
      if (curLines.length > 0) {
        sections.push({ title: curTitle, content: curLines.join('\n').trim() });
      }
      curTitle = line.substring(3).trim();
      curLines = [];
    } else {
      curLines.push(line);
    }
  }
  // 推最后一段
  if (curLines.length > 0 || sections.length === 0) {
    sections.push({ title: curTitle, content: curLines.join('\n').trim() });
  }
  return sections;
}

@Component
export struct NoteDetailOverlay {
  @Prop note: NoteItem = new NoteItem(0, '', '', '', '', 0, '', [], '');

  onClose: () => void = () => {};
  onAskAi: (note: NoteItem) => void = () => {};
  onEdit: (id: number) => void = () => {};
  onDelete: (id: number) => void = () => {};

  build() {
    Stack() {
      // ===== 半透明遮罩 =====
      Column()
        .width('100%').height('100%')
        .backgroundColor('#CC000000')
        .onClick(() => this.onClose());

      // ===== 浮层主体 =====
      Column() {
        // drag bar
        Row() {
          Row()
            .width(40).height(4)
            .borderRadius(2)
            .backgroundColor(TEXT_4);
        }
        .width('100%')
        .height(24)
        .margin({ top: 8 })
        .justifyContent(FlexAlign.Center);

        // 顶栏
        Row() {
          // 学科 · 类型条
          Row() {
            Text(this.note.subject)
              .fontSize(F_XS)
              .fontColor(subjectColor(this.note.subject))
              .fontWeight(700);
            Text(' · ')
              .fontSize(F_XS)
              .fontColor(TEXT_4);
            Text(this.note.type)
              .fontSize(F_XS)
              .fontColor(typeColor(this.note.type))
              .fontWeight(600);
          }
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(R_FULL)
          .backgroundColor('#1AFFFFFF')
          .border({ width: 1, color: BORDER });

          Blank();

          // 关闭
          this.CloseBtn();
        }
        .width('100%')
        .padding({ left: 20, right: 16, top: 4, bottom: 8 });

        // ===== 内容 Scroll 区 =====
        Scroll() {
          Column() {
            // 标题
            Text(this.note.title)
              .fontSize(F_2XL)
              .fontWeight(700)
              .fontColor(TEXT)
              .lineHeight(30)
              .width('100%')
              .padding({ left: 20, right: 20, top: 8, bottom: 4 });

            // meta 行(章节 + 日期 + 置信度)
            Row() {
              // 章节
              if (this.note.chapter && this.note.chapter.length > 0) {
                Text(`📖 ${this.note.chapter}`)
                  .fontSize(F_XS)
                  .fontColor(TEXT_2);
                Text('  ·  ')
                  .fontSize(F_XS)
                  .fontColor(TEXT_4);
              }
              // 日期
              Text(recentDate(this.note.date))
                .fontSize(F_XS)
                .fontColor(TEXT_3);

              Blank();

              // 置信度条
              this.ConfBadge();
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 4, bottom: 12 });

            // 标签 chips
            if (this.note.tags && this.note.tags.length > 0) {
              Row() {
                ForEach(this.note.tags, (tag: string) => {
                  this.TagChip(tag);
                }, (tag: string) => tag);
              }
              .width('100%')
              .padding({ left: 20, right: 20, bottom: 16 });
            }

            // 分隔线
            Row()
              .width('100%')
              .height(1)
              .backgroundColor(BORDER)
              .margin({ left: 20, right: 20, bottom: 12 });

            // 正文(按章节渲染)
            Column() {
              ForEach(parseSections(this.note.body), (sec: Section) => {
                this.SectionView(sec);
              }, (sec: Section) => sec.title + '_' + sec.content.length.toString());
            }
            .width('100%')
            .padding({ left: 20, right: 20, bottom: 16 });

            // AI 卡
            this.AiCard();

            // 底部留白
            Blank().height(80);
          }
          .width('100%');
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring);

        // ===== 底部操作栏 =====
        Row() {
          // 删除
          this.ActionBtn('🗑', '删除', '#FF6B6B', () => this.confirmDelete());
          Blank().width(8);
          // 编辑
          this.ActionBtn('✎', '编辑', TEXT_2, () => this.mockEdit());
          Blank().width(8);
          // 分享
          this.ActionBtn('↗', '分享', TEXT_2, () => this.mockShare());
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 28 })
        .backgroundColor(BG_DARK)
        .border({ width: { top: 1 }, color: BORDER });
      }
      .width('100%')
      .height('100%')
      .backgroundColor(BG_DARK);
    }
    .width('100%').height('100%');
  }

  // ========== 章节渲染 ==========
  @Builder
  SectionView(sec: Section) {
    Column() {
      // 章节标题
      Text(sec.title)
        .fontSize(F_SM)
        .fontWeight(700)
        .fontColor(MINT)
        .letterSpacing(0.5)
        .width('100%')
        .margin({ top: 12, bottom: 6 });

      // 章节内容
      Text(sec.content && sec.content.length > 0 ? sec.content : '—')
        .fontSize(F_BASE)
        .fontColor(TEXT_2)
        .lineHeight(22)
        .width('100%');
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  // ========== 置信度徽章 ==========
  @Builder
  ConfBadge() {
    Row() {
      // 圆点
      Column()
        .width(6).height(6)
        .borderRadius(3)
        .backgroundColor(confColor(this.note.conf));
      Text('  ')
        .fontSize(F_XS);
      Text(`${Math.round(this.note.conf * 100)}% ${confLabel(this.note.conf)}`)
        .fontSize(F_XS)
        .fontWeight(600)
        .fontColor(confColor(this.note.conf));
    }
    .alignItems(VerticalAlign.Center);
  }

  // ========== 标签 chip ==========
  @Builder
  TagChip(tag: string) {
    Text(`#${tag}`)
      .fontSize(F_XS)
      .fontColor(MINT)
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .borderRadius(R_FULL)
      .backgroundColor(MINT_GLOW)
      .margin({ right: 6, bottom: 6 });
  }

  // ========== AI 卡 ==========
  @Builder
  AiCard() {
    Column() {
      Row() {
        // AI 图标
        Stack() {
          Text('✦')
            .fontSize(14)
            .fontWeight(700)
            .fontColor(BG_DARK);
        }
        .width(28).height(28)
        .borderRadius(14)
        .linearGradient({ angle: 135, colors: [[MINT, 0], [PURPLE, 1]] })
        .alignContent(Alignment.Center)
        .margin({ right: 10 });

        Column() {
          Text('AI 解答')
            .fontSize(F_BASE)
            .fontWeight(700)
            .fontColor(TEXT);
          Text('让 MathMind AI 解释这道题')
            .fontSize(F_XS)
            .fontColor(TEXT_3)
            .margin({ top: 2 });
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1);

        Text('›')
          .fontSize(20)
          .fontColor(MINT)
          .fontWeight(500);
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .borderRadius(R_LG)
    .backgroundColor('#0DFFFFFF')
    .border({ width: 1, color: MINT_BORDER })
    .linearGradient({
      angle: 135,
      colors: [['#1A5BE3B0', 0], ['#0D9775FA', 1]],
    })
    .onClick(() => this.handleAskAi());
  }

  // ========== 顶栏按钮 ==========
  @Builder
  CloseBtn() {
    Stack() {
      Text('✕')
        .fontSize(16)
        .fontWeight(500)
        .fontColor(TEXT_2);
    }
    .width(32).height(32)
    .borderRadius(16)
    .backgroundColor('#1AFFFFFF')
    .alignContent(Alignment.Center)
    .onClick(() => this.onClose());
  }

  // ========== 底部操作按钮 ==========
  @Builder
  ActionBtn(icon: string, label: string, color: string, action: () => void) {
    Column() {
      Text(icon)
        .fontSize(16)
        .fontColor(color);
      Text(label)
        .fontSize(10)
        .fontColor(color)
        .margin({ top: 2 });
    }
    .layoutWeight(1)
    .height(44)
    .borderRadius(R_MD)
    .backgroundColor('#1AFFFFFF')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => action());
  }

  // ========== 行为(箭头函数) ==========
  private handleAskAi = (): void => {
    promptAction.showToast({ message: '正在呼叫 AI...', duration: 1500 });
    this.onAskAi(this.note);
  };

  private mockEdit = (): void => {
    promptAction.showToast({ message: '编辑功能 W2 上线', duration: 1500 });
    this.onEdit(this.note.id);
  };

  private mockShare = (): void => {
    promptAction.showToast({ message: '已复制笔记到剪贴板', duration: 1500 });
  };

  private confirmDelete = (): void => {
    promptAction.showToast({ message: '删除功能 W2 上线', duration: 1500 });
    this.onDelete(this.note.id);
  };
}
