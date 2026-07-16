/**
 * MathMind 澶嶄範璁″垝椤? * W3: 鐘舵€佹爮閬胯 + 浠ょ墝鍖? */

import {
  S_1, S_2, S_3, S_4, LH_COMFORT, 
  MINT, MINT_DARK, BG_DARK, TEXT, TEXT_3, R_FULL,
  F_SM, F_BASE, F_2XL, W_SEMIBOLD, LH_COMFORT,
} from "common"
import {
  S_1, S_2, S_3, S_4, LH_COMFORT,  router } from "@kit.ArkUI"

@Component
export struct ReviewPage {
  @StorageProp("statusBarHeight") sbh: number = 0

  build() {
    Column() {
      Row().width("100%").height(this.sbh).backgroundColor(BG_DARK)
      Scroll() {
        Column() {
          Blank()
          Column() {
            Text("馃搵").fontSize(F_2XL + 18).margin({ bottom: S_3 })
            Text("瀛︿範璁″垝").fontSize(F_BASE + 1).fontWeight(W_SEMIBOLD).fontColor(TEXT).margin({ bottom: S_2 })
            Text("閫氳繃 AI 瀵硅瘽鍒嗘瀽绗旇鍚嶾n鑷姩鐢熸垚涓€у寲澶嶄範璁″垝").fontSize(F_SM + 1).fontColor(TEXT_3)
              .textAlign(TextAlign.Center).lineHeight(LH_COMFORT).margin({ bottom: S_4 })
            Button("鎵撳紑瀛︿範璁″垝").fontSize(F_SM).fontWeight(W_SEMIBOLD)
              .fontColor(BG_DARK).width(S_6 * 6 - S_1).height(S_6 * 2 - S_1).borderRadius(R_FULL)
              .linearGradient({ angle: 135, colors: [[MINT, 0], [MINT_DARK, 1]] })
              .onClick((): void => { router.pushUrl({ url: "pages/StudyPlanPage" }) })
          }.alignItems(HorizontalAlign.Center).width("100%")
          Blank()
        }.width("100%").height("100%")
      }.width("100%").height("100%")
    }.width("100%").height("100%").backgroundColor(BG_DARK)
  }
}
