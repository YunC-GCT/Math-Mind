/**
 * FloatingButton 原子组件 — 渐变圆形 FAB
 * 从 HomePage 提取，全量 token 化
 */
import { MINT, MINT_DARK, BG_DARK, FAB_SIZE, SHADOW_FAB, S_4, S_5 } from "common"

@Component
export struct FloatingButton {
  @Prop icon: string = "+"
  onTap: () => void = (): void => {}

  build() {
    Stack() {
      Text(this.icon)
        .fontSize(22)
        .fontColor(BG_DARK)
        .fontWeight(FontWeight.Bold)
    }
    .width(FAB_SIZE).height(FAB_SIZE)
    .borderRadius(FAB_SIZE / 2)
    .linearGradient({ angle: 180, colors: [[MINT, 0], [MINT_DARK, 1]] })
    .shadow(SHADOW_FAB)
    .margin({ right: S_5, bottom: S_4 })
    .onClick((): void => { this.onTap() })
  }
}
