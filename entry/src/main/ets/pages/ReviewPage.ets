// MathMind - ReviewPage (复习 Tab)
// 来源: Web MVP index.html page-review 区块
// 任务编号: UI 批次 2 · 第 2 步
// 责任: 你 + Mavis
// 状态: 真实 UI 实现(第 2 批,空状态 + 引导)
//
// 结构(对照 Web MVP):
//   居中布局:
//     📋 emoji (48vp)
//     复习计划 标题 (16sp 粗体)
//     副标题 (13sp 灰,两行)
//     "去 AI 对话" 按钮 (mint 渐变)
//       → 调 onGoAI callback 切到 AI Tab

import {
  BG, MINT, MINT_DARK, TEXT, TEXT_3,
  S_2, S_3, S_4, S_5, S_6,
  T_SM, T_MD, T_LG
} from 'common/src/main/ets/constants/ColorTokens';

@Component
export struct ReviewPage {
  // 父级传入的回调,通知父级切到 AI Tab
  onGoAI: () => void = () => {};

  build() {
    Column() {
      Blank()  // 顶部弹性空白
      Text('📋')
        .fontSize(48)
        .textAlign(TextAlign.Center)
        .width('100%')
      Text('复习计划')
        .fontSize(T_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT)
        .margin({ top: S_3 })
      Text('通过 AI 对话分析笔记后\n自动生成个性化复习计划')
        .fontSize(T_SM)
        .fontColor(TEXT_3)
        .textAlign(TextAlign.Center)
        .margin({ top: S_2 })
        .padding({ left: 40, right: 40 })
        .lineHeight(20)
      Button('去 AI 对话')
        .padding({ left: S_5, right: S_5, top: S_3, bottom: S_3 })
        .margin({ top: S_4 })
        .fontSize(T_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor(BG)
        .backgroundColor(MINT)
        .linearGradient({
          angle: 135,
          colors: [[MINT, 0.0], [MINT_DARK, 1.0]]
        })
        .borderRadius(S_3)
        .onClick(() => {
          this.onGoAI();
        })
      Blank()  // 底部弹性空白
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG)
    .justifyContent(FlexAlign.Center)
  }
}
