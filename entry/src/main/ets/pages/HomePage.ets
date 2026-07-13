// MathMind - HomePage (首页)
// 来源: C:\Users\YunCeH\Desktop\仓库\MathMind-MVP\index.html (page-home 区块)
// 任务编号: UI 批次 1 · 第 2 步
// 责任: 你 + Mavis
// 状态: 真实 UI 实现(第 1 批,用于 build 验证)
//
// 结构(对照 Web MVP):
//   1. 状态栏(48vp)
//   2. Header: 六边形 logo + "MathMind" 标题(54vp)
//   3. Hero 区: 渐变背景 + 问候 + 进度环 + 3 统计
//   4. 提醒横幅(可选,根据笔记数)
//   5. "最近笔记" 滚动列表
//   6. FAB [+] 浮动按钮(绝对定位,bottom: 90vp, right: 20vp, 54×54)
//
// 设计基准: 377 vp 宽(对应 HUAWEI Pura 90,6.8 寸 1320×2856 / 560 dpi / HarmonyOS 6.1.1)
// 配色: 全部从 common/src/main/ets/constants/ColorTokens 引用

import {
  MINT, MINT_DARK, MINT_LIGHT, MINT_GLOW, MINT_BORDER,
  PURPLE, PURPLE_LIGHT,
  TEXT, TEXT_2, TEXT_3, TEXT_4,
  BG, BG_2, BG_3, BG_4,
  SURFACE, SURFACE_2, BORDER,
  SUBJECT_COLORS, SUBJECT_DEFAULT,
  TYPE_COLORS, TYPE_DEFAULT,
  R, R_SM, R_MD, R_FULL, R_LG,
  S_1, S_2, S_3, S_4, S_5, S_6,
  T_XS, T_SM, T_BASE, T_MD, T_LG, T_XL, T_2XL, T_3XL,
  STATUS_BAR_H, HEADER_H
} from 'common/src/main/ets/constants/ColorTokens';

// ==================== 本地 View 接口 ====================
interface NoteView {
  id: number;
  title: string;
  type: string;
  subject: string;
  chapter: string;
  conf: number;
  body: string;
  tags: string[];
  date: string;
}

// ==================== Mock 数据(对照 app.js NOTES)===================
const MOCK_NOTES: NoteView[] = [
  { id: 1, title: '拉格朗日中值定理', type: '概念', subject: '数学分析', chapter: '微分中值定理', conf: 0.92, body: '## 定义\n若函数 f(x) 在闭区间 [a,b] 连续...', tags: ['中值定理', '导数'], date: '2026-07-05' },
  { id: 2, title: '矩阵行列式计算', type: '计算', subject: '高等代数', chapter: '行列式', conf: 0.88, body: '## 题目\n求 n 阶行列式 |A|...', tags: ['行列式', '矩阵'], date: '2026-07-04' },
  { id: 3, title: '极限 ε-δ 定义', type: '概念', subject: '数学分析', chapter: '极限', conf: 0.85, body: '## 定义\n对任意 ε>0,存在 δ>0...', tags: ['极限', '定义'], date: '2026-07-03' },
  { id: 4, title: '空间直线方程', type: '计算', subject: '解析几何', chapter: '直线与平面', conf: 0.78, body: '## 题目\n求过点(1,2,3)...', tags: ['直线', '参数方程'], date: '2026-07-02' },
  { id: 5, title: '证明向量组线性无关', type: '证明', subject: '高等代数', chapter: '线性空间', conf: 0.82, body: '## 命题\n设 α₁,α₂,α₃ 线性无关...', tags: ['线性无关', '向量组'], date: '2026-07-01' }
];

// ==================== 顶层工具函数 ====================
// ArkTS 严格语法禁止 struct 内普通方法,所有 util 提到模块顶层

function getTypeColor(type: string): string {
  return TYPE_COLORS[type] || TYPE_DEFAULT;
}

function getSubjectColor(subject: string): string {
  return SUBJECT_COLORS[subject] || SUBJECT_DEFAULT;
}

function getConfColor(conf: number): string {
  if (conf >= 0.8) return MINT;
  if (conf >= 0.5) return '#F0C674';
  return '#FF6B6B';
}

function getConfText(conf: number): string {
  return (conf * 100).toFixed(0) + '%';
}

// 摘要:去掉 ## 标题行(无 regex,无 C 风格 for),截 60 字
function getBodyPreview(body: string): string {
  if (!body) return '';
  const lines: string[] = body.split('\n');
  // ArkTS 严格语法禁 C 风格 for(...;...;...),改用 for...of
  const kept: string[] = [];
  for (const line of lines) {
    if (line.indexOf('## ') !== 0) {
      kept.push(line);
    }
  }
  const stripped = kept.join(' ').trim();
  if (stripped.length <= 60) return stripped;
  return stripped.substring(0, 60) + '…';
}

@Component
export struct HomePage {
  @State notes: NoteView[] = MOCK_NOTES;
  @State progress: number = 75;  // 0-100
  @State greet: string = '晚上好';
  @State userName: string = 'Mini';
  @State dateStr: string = '2026-07-13';
  // Canvas 上下文(进度环用)
  private canvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(
    new RenderingContextSettings(true)
  );

  aboutToAppear() {
    // 简化:greet 直接 hardcode
    // ArkTS 严格语法禁 struct 内调普通方法
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 1. Header (固定不滚动)
        this.Header()

        // 2. 可滚动区域: Hero + Reminder + 最近笔记
        Scroll() {
          Column() {
            // Hero 区
            this.Hero()

            // 提醒横幅
            if (this.notes.length === 0) {
              this.Reminder('👋 欢迎使用 MathMind！试试 AI 对话或拍照，帮你整理知识笔记 ›')
            } else if (this.notes.length < 3) {
              this.Reminder(`⏰ 已有 ${this.notes.length} 条笔记，继续用 AI 充实知识库 ›`)
            }

            // "最近笔记" 标题
            Text('最近笔记')
              .fontSize(T_BASE)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT)
              .padding({ left: S_5, top: S_2, bottom: S_2 })
              .width('100%')

            // 笔记列表 (改用 ForEach + Column,避免 List 嵌套 Scroll 的 nested scroll 问题)
            if (this.notes.length > 0) {
              Column() {
                ForEach(this.notes, (note: NoteView) => {
                  this.NoteCard(note)
                }, (note: NoteView) => note.id.toString())
              }
              .width('100%')
            } else {
              Column() {
                Text('还没有笔记\n试试 AI 对话或拍照吧 👇')
                  .fontSize(T_BASE)
                  .fontColor(TEXT_3)
                  .textAlign(TextAlign.Center)
                  .padding(S_5)
              }
              .width('100%')

              // 底部留白让 FAB 不遮内容
              Blank().height(80)
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .friction(0.6)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(BG)

      // 3. FAB 浮动按钮
      this.FAB()
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 子组件 ====================

  @Builder
  Header() {
    Row({ space: S_2 }) {
      // 六边形 brand logo (SVG,对照 Web MVP)
      // objectFit: Contain 让 SVG 自适应,fillColor 切色
      Image($r('app.media.ic_brand'))
        .width(24).height(24)
        .objectFit(ImageFit.Contain)
        .fillColor(MINT)

      Text('MathMind')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT)
    }
    .width('100%')
    // 沉浸式 + 安全区:status bar 透明浮在 app 上,但 Header 内容向下挪 48vp
    // 避免跟系统时间 06:50 / 电量文字重叠
    .height(HEADER_H + STATUS_BAR_H)
    .padding({ left: S_4, right: S_4, top: STATUS_BAR_H })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  Hero() {
    Column() {
      // 问候行
      Row() {
        Column({ space: 2 }) {
          Row({ space: 5 }) {
            Text('')
              .width(5).height(5)
              .borderRadius(R_FULL)
              .backgroundColor(MINT)
            Text(this.greet + ', ')
              .fontSize(T_BASE)
              .fontColor(TEXT)
              .fontWeight(FontWeight.Bold)
            Text(this.userName)
              .fontSize(T_BASE)
              .fontColor(TEXT)
              .fontWeight(FontWeight.Bold)
          }

          Text(this.dateStr + ' · 周一')
            .fontSize(10.5)
            .fontColor(TEXT_4)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 进度环 - 用 Canvas 真实画(空 Text 不会渲染 border)
      Stack({ alignContent: Alignment.Center }) {
        // 背景圆环(灰色,完整 360°)
        Canvas()
          .width(120).height(120)
          .onReady(() => {
            this.canvasCtx.strokeStyle = '#0FFFFFFF'
            this.canvasCtx.lineWidth = 10
            this.canvasCtx.beginPath()
            this.canvasCtx.arc(60, 60, 52, 0, Math.PI * 2)
            this.canvasCtx.stroke()
          })

        // 前景圆弧(mint 绿,按 progress 比例)
        Canvas()
          .width(120).height(120)
          .onReady(() => {
            this.canvasCtx.strokeStyle = MINT
            this.canvasCtx.lineWidth = 10
            this.canvasCtx.lineCap = 'round'
            this.canvasCtx.beginPath()
            // 从 -90°(顶部)顺时针画 progress%
            const endAngle = -Math.PI / 2 + (Math.PI * 2 * this.progress / 100)
            this.canvasCtx.arc(60, 60, 52, -Math.PI / 2, endAngle, false)
            this.canvasCtx.stroke()
          })

        // 中央文字
        Column() {
          Text(this.progress + '%')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT)
          Text('已掌握')
            .fontSize(10)
            .fontColor(TEXT_3)
            .margin({ top: 2 })
        }
      }
      .width(120).height(120)
      .margin({ top: S_3, bottom: S_1 })

      // 3 统计方块
      Row({ space: 10 }) {
        this.StatBox(this.notes.length.toString(), '笔记')
        this.StatBox(this.progress + '%', '掌握率')
        this.StatBox('0', '今日新增')
      }
      .width('100%')
      .margin({ top: S_3 })
    }
    .width('100%')
    .padding(S_4)
    .linearGradient({
      angle: 135,
      colors: [
        [MINT_LIGHT, 0.0],
        [PURPLE_LIGHT, 0.5],
        ['#1AFF6B9D', 1.0]
      ]
    })
  }

  @Builder
  StatBox(num: string, label: string) {
    Column() {
      Text(num)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT)
      Text(label)
        .fontSize(10)
        .fontColor(TEXT_3)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .backgroundColor(SURFACE)
    .border({ width: 1, color: BORDER })
    .borderRadius(R_SM + 4)
    .padding(S_2 + 2)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  Reminder(text: string) {
    Row({ space: S_2 }) {
      Text(text)
        .fontSize(T_SM)
        .fontColor(MINT)
        .layoutWeight(1)
    }
    .width('100%')
    .margin({ top: S_1, left: S_4, right: S_4 })
    .padding({ left: S_3, right: S_3, top: S_2 + 2, bottom: S_2 + 2 })
    .borderRadius(R)
    .linearGradient({
      angle: 135,
      colors: [
        [MINT_LIGHT, 0.0],
        [PURPLE_LIGHT, 1.0]
      ]
    })
    .border({ width: 1, color: MINT_BORDER })
  }

  @Builder
  NoteCard(note: NoteView) {
    Row({ space: S_3 }) {
      // 类型图标(渐变)
      Text(getTypeColor(note.type).substring(1, 2))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(BG)
        .width(36).height(36)
        .borderRadius(10)
        .linearGradient({
          angle: 135,
          colors: [
            [getTypeColor(note.type), 0.0],
            [getSubjectColor(note.subject), 1.0]
          ]
        })
        .textAlign(TextAlign.Center)

      // 笔记信息
      Column({ space: 3 }) {
        // meta 行
        Row() {
          Text(note.subject)
            .fontSize(10.5)
            .fontColor(getSubjectColor(note.subject))
            .fontWeight(FontWeight.Bold)
            .margin({ right: 6 })
          Text(note.type)
            .fontSize(10.5)
            .fontColor(getTypeColor(note.type))
            .fontWeight(FontWeight.Bold)
            .margin({ right: 6 })
          Text(note.date)
            .fontSize(10.5)
            .fontColor(TEXT_3)
          Text('· ' + getConfText(note.conf))
            .fontSize(10.5)
            .fontColor(getConfColor(note.conf))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        // 标题
        Text(note.title)
          .fontSize(T_MD)
          .fontColor(TEXT)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 摘要
        Text(getBodyPreview(note.body))
          .fontSize(12.5)
          .fontColor(TEXT_3)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: S_5, right: S_5, top: S_3 + 2, bottom: S_3 + 2 })
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  FAB() {
    Button('+')
      .width(54).height(54)
      .borderRadius(R_FULL)
      .fontSize(28)
      .fontWeight(FontWeight.Bold)
      .fontColor(BG)
      .linearGradient({
        angle: 180,
        colors: [[MINT, 0.0], [MINT_DARK, 1.0]]
      })
      .margin({ right: 20, bottom: 90 })
  }
}
