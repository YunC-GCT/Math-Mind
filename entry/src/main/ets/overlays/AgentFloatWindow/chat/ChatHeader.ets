// ============================================================================
//  overlays/AgentFloatWindow/chat/ChatHeader.ets — 浮窗头部
//  ----------------------------------------------------------------------------
//  职责: 模型名 + 在线状态 + 深度思考开关 + 新建对话 + 关闭按钮。
//
//  布局:
//    [● 模型名]  [◜◝◞ 深度思考]  [+]  [✕]
//
//  Props:
//    modelName:     模型名(默认 "DeepSeek-V4")
//    deepThink:     深度思考开关状态
//    onToggleThink: 切换思考模式回调
//    onNewChat:     新建对话回调
//    onClose:       关闭浮窗回调
//
//  依赖: common ColorTokens + SVG Ellipse/Circle/Path
//  ============================================================================

import { MINT, MINT_LIGHT, BG_DARK, TEXT_2, TEXT_3, TEXT_4,
  S_1, S_2, S_3, S_4,
  R_FULL, F_XS, F_MD, W_MEDIUM,
} from "common"

@Component
export struct ChatHeader {
  // 模型名
  @Prop modelName: string = "DeepSeek-V4"

  // 深度思考开关
  @Prop deepThink: boolean = false

  // 切换思考模式回调
  onToggleThink?: () => void = (): void => {}

  // 新建对话回调
  onNewChat?: () => void = (): void => {}

  // 关闭回调
  onClose?: () => void = (): void => {}

  build() {
    Row() {
      // [● 模型名]
      Circle({ width: 6, height: 6 })
        .fill(MINT)
        .margin({ right: S_2 })
      Text(this.modelName)
        .fontSize(F_XS)
        .fontColor(TEXT_2)
        .fontWeight(W_MEDIUM)

      // [◜◝◞ 深度思考] 开关
      Row() {
        Stack() {
          // 三个椭圆组成的"花瓣"图标
          Ellipse().width(10).height(4).stroke(this.deepThink ? MINT : TEXT_3).strokeWidth(1)
          Ellipse().width(10).height(4).stroke(this.deepThink ? MINT : TEXT_3).strokeWidth(1).rotate({ angle: 60 })
          Ellipse().width(10).height(4).stroke(this.deepThink ? MINT : TEXT_3).strokeWidth(1).rotate({ angle: 120 })
          Circle({ width: 2, height: 2 }).fill(this.deepThink ? MINT : TEXT_3)
        }
        .width(12).height(12)
        Text(" 深度思考")
          .fontSize(F_XS)
          .fontColor(this.deepThink ? MINT : TEXT_3)
          .fontWeight(W_MEDIUM)
      }
      .padding({ left: S_3, right: S_3, top: S_1, bottom: S_1 })
      .borderRadius(R_FULL)
      .border({ width: 1, color: this.deepThink ? MINT : TEXT_4 })
      .backgroundColor(this.deepThink ? MINT_LIGHT : BG_DARK)
      .margin({ left: S_4 })
      .onClick((): void => {
        if (this.onToggleThink) { this.onToggleThink() }
      })

      // [+] 新建对话
      Text("+")
        .fontSize(F_MD)
        .fontColor(TEXT_3)
        .width(32).height(44)
        .textAlign(TextAlign.Center)
        .onClick((): void => {
          if (this.onNewChat) { this.onNewChat() }
        })

      Blank()

      // [✕] 关闭浮窗(用 Path 画 X,不用 emoji)
      Stack() {
        Path()
          .width(14).height(14)
          .commands("M18 6 L6 18 M6 6 L18 18")
          .stroke(TEXT_3)
          .strokeWidth(2)
          .strokeLineCap(LineCapStyle.Round)
          .fill(Color.Transparent)
      }
      .width(32).height(44)
      .alignContent(Alignment.Center)
      .onClick((): void => {
        if (this.onClose) { this.onClose() }
      })
    }
    .width("100%")
    .padding({ left: S_4, right: S_3, top: S_2, bottom: S_1 })
  }
}
