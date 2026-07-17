import {
  MINT, TEXT, TEXT_3,
  S_1, S_3, S_6,
  F_XS, F_XL,
  W_BOLD,
  GLASS_10,
  AVATAR_SIZE,
} from "common"

@Component
export struct ProfileHeader {
  @Prop name: string = "Mini"
  @Prop subtitle: string = "\u6570\u5b66\u7231\u597d\u8005 \u00b7 \u5b66\u4e60 30 \u5929"
  @Prop initial: string = "M"

  build() {
    Column() {
      Stack() {
        Circle({ width: AVATAR_SIZE, height: AVATAR_SIZE })
          .fill(GLASS_10)
        Text(this.initial)
          .fontSize(F_XL + 8)
          .fontWeight(W_BOLD)
          .fontColor(MINT)
      }
      .margin({ bottom: S_3 })

      Text(this.name)
        .fontSize(F_XL)
        .fontWeight(W_BOLD)
        .fontColor(TEXT)

      Text(this.subtitle)
        .fontSize(F_XS)
        .fontColor(TEXT_3)
        .margin({ top: S_1 })
    }
    .width("100%")
    .padding({ top: S_6, bottom: S_6 })
    .alignItems(HorizontalAlign.Center)
  }
}