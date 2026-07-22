import {
  BG_DARK, BORDER, GLASS_8, MINT, TEXT_3,
  R_FULL,
  F_XS,
  W_SEMIBOLD,
} from "common"

@Component
export struct ReviewTabSwitch {
  @Prop activeTab: number = 0
  onChange: (tab: number) => void = (_tab: number): void => {}

  build() {
    Row() {
      this.TabItem("复习计划", 0)
      this.TabItem("知识星系", 1)
    }
    .height(40)
    .padding({ left: 4, right: 4 })
    .borderRadius(R_FULL)
    .backgroundColor(GLASS_8)
    .border({ width: 0.5, color: BORDER })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  TabItem(label: string, tab: number) {
    Text(label)
      .fontSize(F_XS + 1)
      .fontWeight(W_SEMIBOLD)
      .fontColor(this.activeTab === tab ? BG_DARK : TEXT_3)
      .textAlign(TextAlign.Center)
      .height(32)
      .layoutWeight(1)
      .borderRadius(R_FULL)
      .backgroundColor(this.activeTab === tab ? MINT : Color.Transparent)
      .onClick((): void => this.onChange(tab))
  }
}
