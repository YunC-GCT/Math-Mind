/**
 * MathMind 复习计划页
 * W3: 状态栏避让 + 令牌化
 */

import {
  MINT, MINT_DARK, BG_DARK, TEXT, TEXT_3, R_FULL,
  F_SM, F_BASE, F_2XL, W_SEMIBOLD,
} from "common"
import { router } from "@kit.ArkUI"

@Component
export struct ReviewPage {
  @StorageProp("statusBarHeight") sbh: number = 0
  onGoAI: () => void = (): void => {}

  build() {
    Column() {
      Row().width("100%").height(this.sbh).backgroundColor(BG_DARK)
      Scroll() {
        Column() {
          Blank()
          Column() {
            Text("📋").fontSize(F_2XL + 18).margin({ bottom: 12 })
            Text("学习计划").fontSize(F_BASE + 1).fontWeight(W_SEMIBOLD).fontColor(TEXT).margin({ bottom: 8 })
            Text("通过 AI 对话分析笔记后\n自动生成个性化复习计划").fontSize(F_SM + 1).fontColor(TEXT_3)
              .textAlign(TextAlign.Center).lineHeight(20).margin({ bottom: 16 })
            Button("打开学习计划").fontSize(F_SM).fontWeight(W_SEMIBOLD)
              .fontColor(BG_DARK).width(140).height(44).borderRadius(R_FULL)
              .linearGradient({ angle: 135, colors: [[MINT, 0], [MINT_DARK, 1]] })
              .onClick((): void => { router.pushUrl({ url: "pages/StudyPlanPage" }) })
          }.alignItems(HorizontalAlign.Center).width("100%")
          Blank()
        }.width("100%").height("100%")
      }.width("100%").height("100%")
    }.width("100%").height("100%").backgroundColor(BG_DARK)
  }
}
