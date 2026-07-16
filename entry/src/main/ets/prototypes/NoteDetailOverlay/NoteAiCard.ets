import {
  MINT, MINT_BORDER, PURPLE,
  BG_DARK, TEXT, TEXT_3,
  S_4, R_LG, F_XS, F_BASE, W_BOLD,
} from "common"
import { AppIcon } from "../../atoms/AppIcon"

@Component
export struct NoteAiCard {
  onTap: () => void = (): void => {}

  build() {
    Column() {
      Row() {
        Stack() {
          AppIcon({ name: "star", iconSize: 14, color: BG_DARK, strokeWidth: 2 })
        }
        .width(28).height(28)
        .borderRadius(14)
        .linearGradient({ angle: 135, colors: [[MINT, 0], [PURPLE, 1]] })
        .alignContent(Alignment.Center)
        .margin({ right: 10 })

        Column() {
          Text("AI 解答")
            .fontSize(F_BASE).fontWeight(W_BOLD)
            .fontColor(TEXT)
          Text("让 MathMind AI 解释这道题")
            .fontSize(F_XS)
            .fontColor(TEXT_3)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        AppIcon({ name: "chevron-right", iconSize: 18, color: MINT, strokeWidth: 2 })
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)
    }
    .width("100%")
    .padding({ left: S_4, right: S_4, top: S_4, bottom: S_4 })
    .borderRadius(R_LG)
    .backgroundColor("#0DFFFFFF")
    .border({ width: 1, color: MINT_BORDER })
    .linearGradient({
      angle: 135,
      colors: [["#1A5BE3B0", 0], ["#0D9775FA", 1]],
    })
    .onClick((): void => this.onTap())
  }
}
