/**
 * ==========================================================================
 *  MessageInput.ets — 消息输入栏组件
 *  ==========================================================================
 *  职责: 图片预览 + 输入框 + 拍照按钮 + 发送按钮。
 *
 *  UI:
 *    [图片预览] (有图片时)
 *    [📷] [输入数学问题...________________] [↑]
 *
 *  接口:
 *    @Prop inputText      — 输入文本 (双向: onTextChange)
 *    @Prop imagePreview   — 图片预览 URI
 *    @Prop busy           — AI 是否忙碌 (发送按钮禁用)
 *    onTextChange(v)       — 文本变更回调
 *    onSend()              — 发送回调
 *    onCamera()            — 拍照回调
 *    onClearImage()        — 清除图片回调
 *
 *  依赖: common ColorTokens + app.media.ic_camera
 * ==========================================================================
 */// chat/MessageInput.ets — 输入栏: 图片预览 + 输入框 + 拍照 + 发送
import { MINT, TEXT, TEXT_3, S_1, S_2, S_4, R_SM, F_XS, F_SM, F_LG, W_BOLD, GLASS_10 } from "common"
@Component
export struct MessageInput {
  @Prop inputText: string = ""
  @Prop imagePreview: string = ""
  @Prop busy: boolean = false
  onTextChange?: (v: string) => void
  onSend?: () => void
  onCamera?: () => void
  onClearImage?: () => void
  build() {
    Column() {
      if (this.imagePreview.length > 0) {
        Row() {
          Image($r("app.media.ic_camera")).width(20).height(20).fillColor(MINT)
          Text("\u5DF2\u9644\u56FE\u7247").fontSize(F_XS).fontColor(TEXT_3).margin({ left: S_2 }).layoutWeight(1)
          Text("\u2715").fontSize(F_SM).fontColor(TEXT_3).width(32).height(44).textAlign(TextAlign.Center)
            .onClick((): void => { if (this.onClearImage) { this.onClearImage() } })
        }.width("100%").padding({ left: S_4, right: S_4, bottom: S_1 })
      }
      Row() {
        TextInput({ text: this.inputText, placeholder: "\u8F93\u5165\u6570\u5B66\u95EE\u9898..." })
          .layoutWeight(1).height(40).fontSize(F_SM).fontColor(TEXT).placeholderColor(TEXT_3)
          .backgroundColor(GLASS_10).borderRadius(20).padding({ left: S_4, right: S_4 })
          .onChange((value: string): void => { if (this.onTextChange) { this.onTextChange(value) } })
          .onSubmit((): void => { if (this.onSend) { this.onSend() } })
        Stack() {
          Image($r("app.media.ic_camera")).width(16).height(16).fillColor(TEXT_3)
        }.width(36).height(44).alignContent(Alignment.Center)
        .onClick((): void => { if (this.onCamera) { this.onCamera() } })
        Text("\u2191").fontSize(F_LG).fontWeight(W_BOLD).width(36).height(44).textAlign(TextAlign.Center)
          .fontColor(this.inputText.trim().length > 0 && !this.busy ? MINT : TEXT_3)
          .onClick((): void => { if (this.onSend) { this.onSend() } })
      }.width("100%").padding({ left: S_4, right: S_4 })
    }.width("100%").padding({ top: S_2, bottom: S_4 })
  }
}
