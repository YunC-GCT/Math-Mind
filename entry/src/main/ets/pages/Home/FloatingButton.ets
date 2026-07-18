// ============================================================================
//  pages/Home/FloatingButton.ets — 渐变圆形 FAB 原子组件
//  ----------------------------------------------------------------------------
//  职责: MINT→MINT_DARK 渐变圆形悬浮按钮，带 SHADOW_FAB 投影。
//  来源: 从 HomePage.ets 提取，替换内联 Stack 实现。
//  接口:
//    @Prop  icon   — 按钮文字 (默认 "+")
//    onTap          — 点击回调
//  ============================================================================

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
