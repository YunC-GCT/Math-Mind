// ============================================================================
//  pages/Profile/ProfileHeader.ets — 我的页头像区
//  ----------------------------------------------------------------------------
//  职责: 圆形头像 + 用户名 + 副标题(垂直居中)。
//
//  布局:
//    [圆形头像 (M 首字母)]
//    "Mini"
//    "数学爱好者 · 学习 30 天"
//
//  依赖: common 令牌(MINT / TEXT / TEXT_3 / S_1 / S_3 / S_6 /
//         F_XS / F_XL / W_BOLD / GLASS_10 / AVATAR_SIZE)
//
//  Props:
//    name:     用户名
//    subtitle: 副标题
//    initial:  头像首字母
//  ============================================================================

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
  // 用户名
  @Prop name: string = "Mini"

  // 副标题
  @Prop subtitle: string = "数学爱好者 · 学习 30 天"

  // 头像首字母
  @Prop initial: string = "M"

  build() {
    Column() {
      // 头像(圆形 + 首字母)
      Stack() {
        Circle({ width: AVATAR_SIZE, height: AVATAR_SIZE })
          .fill(GLASS_10)
        Text(this.initial)
          .fontSize(F_XL + 8)
          .fontWeight(W_BOLD)
          .fontColor(MINT)
      }
      .margin({ bottom: S_3 })

      // 用户名
      Text(this.name)
        .fontSize(F_XL)
        .fontWeight(W_BOLD)
        .fontColor(TEXT)

      // 副标题
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
