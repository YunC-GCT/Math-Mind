// chat/ChatBubble.ets — 聊天气泡 + LaTeX 视觉区分
import { MINT, MINT_LIGHT, MINT_DARK, PURPLE, PURPLE_LIGHT,
  TEXT, TEXT_2, TEXT_4, S_1, S_2, S_3, R_MD, F_XS, F_SM, W_SEMIBOLD,
} from "common"

interface ChatMsg { id: number; role: string; content: string; ts: number }

function formatLatex(raw: string): string {
  return raw.replace(/\$\$(.+?)\$\$/g, "\n[ \u2710 $1 ]\n")
            .replace(/\$(.+?)\$/g, " { \u00B7 $1 \u00B7 } ")
}

@Component
export struct ChatBubble {
  @Prop msg: ChatMsg = { id: 0, role: "ai", content: "", ts: 0 }
  onCopy?: (text: string) => void
  onRegen?: (msg: ChatMsg) => void

  build() {
    const display = formatLatex(this.msg.content)
    if (this.msg.role === "user") {
      Row() { Blank()
        Column() {
          Text(display).fontSize(F_SM).fontColor(MINT_DARK).lineHeight(20)
            .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
            .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: R_MD + 4, bottomRight: S_1 })
            .backgroundColor(MINT_LIGHT).constraintSize({ maxWidth: "78%" })
        }.alignItems(HorizontalAlign.End)
      }.width("100%").margin({ top: S_2 })
    } else {
      Row() {
        Column() {
          Text("AI").fontSize(9).fontColor(TEXT_4).fontWeight(W_SEMIBOLD).margin({ bottom: S_1, left: S_1 })
          Text(display).fontSize(F_SM).fontColor(TEXT_2).lineHeight(20)
            .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
            .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: S_1, bottomRight: R_MD + 4 })
            .backgroundColor(PURPLE_LIGHT).constraintSize({ maxWidth: "85%" })
          Row() {
            Text("\uD83D\uDCCB").fontSize(9).fontColor(TEXT_4).padding({ top: S_1, right: S_2 })
              .onClick((): void => { if (this.onCopy) { this.onCopy(this.msg.content) } })
            Text("\u21BB").fontSize(10).fontColor(TEXT_4).padding({ top: S_1 })
              .onClick((): void => { if (this.onRegen) { this.onRegen(this.msg) } })
          }
        }.alignItems(HorizontalAlign.Start)
        Blank()
      }.width("100%").margin({ top: S_2 })
    }
  }
}