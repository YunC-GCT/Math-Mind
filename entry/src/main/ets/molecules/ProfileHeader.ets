// ============================================================================
//  molecules/ProfileHeader.ets — 个人中心头像区分子组件
//  ----------------------------------------------------------------------------
//  职责: 渲染头像圆 + 昵称 + 副标题。
//  来源: 从 MePage.ets 提取，消除内联 20 行 UI。
//  接口:
//    @Prop  name     — 用户昵称
//    @Prop  subtitle — 副标题文案
//    @Prop  initial  — 头像字母
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
  @Prop name: string = "Mini"
  @Prop subtitle: string = "数学爱好者 · 学习 30 天"
  @Prop initial: string = "M"

  build() {
    Column() {
      // 头像
      Stack() {
        Circle({ width: AVATAR_SIZE, height: AVATAR_SIZE })
          .fill(GLASS_10)
        Text(this.initial)
          .fontSize(F_XL + 8)
          .fontWeight(W_BOLD)
          .fontColor(MINT)
      }
      .margin({ bottom: S_3 })

      // 昵称
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
