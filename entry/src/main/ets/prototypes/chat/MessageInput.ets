// ============================================================================
//  prototypes/chat/MessageInput.ets — 消息输入栏
//  ----------------------------------------------------------------------------
//  职责: 图片预览(可选) + 输入框 + 拍照按钮 + 发送按钮。
//
//  布局(有图):
//    [📷 已附图片 ........................ ✕]
//    [输入数学问题...________________] [📷] [↑]
//
//  布局(无图):
//    [输入数学问题...________________] [📷] [↑]
//
//  发送按钮状态:
//    输入为空 / AI 忙: 灰色禁用
//    否则: MINT 高亮
//
//  Props:
//    inputText:   输入文本(双向 onTextChange)
//    imagePreview: 图片预览 URI(空时无图)
//    busy:        AI 是否忙碌(决定发送按钮禁用)
//    onTextChange: 文本变更回调
//    onSend:      发送回调
//    onCamera:    拍照回调
//    onClearImage: 清除图片回调
//
//  依赖: common ColorTokens + app.media.ic_camera
//
//  来源: 从 AgentFloatWindow 内联代码拆出
//  ============================================================================

import { MINT, TEXT, TEXT_3, S_1, S_2, S_4, R_SM, F_XS, F_SM, F_LG, W_BOLD, GLASS_10 } from "common"

@Component
export struct MessageInput {
  // 输入文本
  @Prop inputText: string = ""

  // 图片预览 URI(空时无图)
  @Prop imagePreview: string = ""

  // AI 是否忙碌
  @Prop busy: boolean = false

  // 文本变更回调
  onTextChange?: (v: string) => void = (_v: string): void => {}

  // 发送回调
  onSend?: () => void = (): void => {}

  // 拍照回调
  onCamera?: () => void = (): void => {}

  // 清除图片回调
  onClearImage?: () => void = (): void => {}

  build() {
    Column() {
      // 图片预览行(有图时显示)
      if (this.imagePreview.length > 0) {
        Row() {
          // 用 ic_camera 图标占位(实际显示图片是 W2 计划)
          Image($r("app.media.ic_camera"))
            .width(20).height(20)
            .fillColor(MINT)
          Text("已附图片")
            .fontSize(F_XS)
            .fontColor(TEXT_3)
            .margin({ left: S_2 })
            .layoutWeight(1)
          // 清除按钮
          Text("✕")
            .fontSize(F_SM)
            .fontColor(TEXT_3)
            .width(32).height(44)
            .textAlign(TextAlign.Center)
            .onClick((): void => {
              if (this.onClearImage) { this.onClearImage() }
            })
        }
        .width("100%")
        .padding({ left: S_4, right: S_4, bottom: S_1 })
      }

      // 输入行: [TextInput] [📷] [↑]
      Row() {
        // 输入框
        TextInput({ text: this.inputText, placeholder: "输入数学问题..." })
          .layoutWeight(1)
          .height(40)
          .fontSize(F_SM)
          .fontColor(TEXT)
          .placeholderColor(TEXT_3)
          .backgroundColor(GLASS_10)
          .borderRadius(20)
          .padding({ left: S_4, right: S_4 })
          .onChange((value: string): void => {
            if (this.onTextChange) { this.onTextChange(value) }
          })
          .onSubmit((): void => {
            if (this.onSend) { this.onSend() }
          })

        // 拍照按钮
        Stack() {
          Image($r("app.media.ic_camera"))
            .width(16).height(16)
            .fillColor(TEXT_3)
        }
        .width(36).height(44)
        .alignContent(Alignment.Center)
        .onClick((): void => {
          if (this.onCamera) { this.onCamera() }
        })

        // 发送按钮(↑) — 输入空 / busy 时灰色,否则 MINT
        Text("↑")
          .fontSize(F_LG)
          .fontWeight(W_BOLD)
          .width(36).height(44)
          .textAlign(TextAlign.Center)
          .fontColor(this.inputText.trim().length > 0 && !this.busy ? MINT : TEXT_3)
          .onClick((): void => {
            if (this.onSend) { this.onSend() }
          })
      }
      .width("100%")
      .padding({ left: S_4, right: S_4 })
    }
    .width("100%")
    .padding({ top: S_2, bottom: S_4 })
  }
}
