// chat/MessageInput.ets — 输入栏: 图片预览 + 输入框 + 拍照 + 发送
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
          Image(this.imagePreview).width(36).height(36).borderRadius(R_SM).objectFit(ImageFit.Cover)
          Text("\u5DF2\u9009\u56FE\u7247").fontSize(F_XS).fontColor(TEXT_3).margin({ left: S_2 }).layoutWeight(1)
          Text("\u2715").fontSize(F_XS).fontColor(TEXT_3).width(32).height(44).textAlign(TextAlign.Center)
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
