// chat/ChatBubble.ets — 聊天气泡 + LaTeX 兜底
import { MINT, MINT_LIGHT, MINT_DARK, PURPLE, PURPLE_LIGHT,
  TEXT, TEXT_2, TEXT_4, S_1, S_2, S_3, R_MD, F_XS, F_SM, W_SEMIBOLD,
} from "common"

interface ChatMsg { id: number; role: string; content: string; ts: number }

function formatLatex(raw: string): string {
  let r = raw
  while (r.indexOf("$$") >= 0) {
    const s = r.indexOf("$$") + 2; const e = r.indexOf("$$", s)
    if (e < 0) break
    const f = r.substring(s, e)
    r = r.substring(0, s-2) + "\n\u2523 " + f + " \u252B\n" + r.substring(e+2)
  }
  while (r.indexOf("$") >= 0) {
    const s = r.indexOf("$") + 1; const e = r.indexOf("$", s)
    if (e < 0) break
    const f = r.substring(s, e)
    r = r.substring(0, s-1) + " \u3008" + f + "\u3009 " + r.substring(e+1)
  }
  return r
}

@Component
export struct ChatBubble {
  @Prop msg: ChatMsg = { id: 0, role: "ai", content: "", ts: 0 }
  onCopy?: (text: string) => void
  onRegen?: (msg: ChatMsg) => void
  onFeedback?: (msg: ChatMsg) => void

  build() {
    Column() {
      if (this.msg.role === "user") {
        Row() { Blank()
          Column() {
            Text(formatLatex(this.msg.content)).fontSize(F_SM).fontColor(MINT_DARK).lineHeight(20)
              .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
              .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: R_MD + 4, bottomRight: S_1 })
              .backgroundColor(MINT_LIGHT).constraintSize({ maxWidth: "78%" })
          }.alignItems(HorizontalAlign.End)
        }.width("100%").margin({ top: S_2 })
      } else {
        Row() {
          Column() {
            Text("AI").fontSize(9).fontColor(TEXT_4).fontWeight(W_SEMIBOLD).margin({ bottom: S_1, left: S_1 })
            Text(formatLatex(this.msg.content)).fontSize(F_SM).fontColor(TEXT_2).lineHeight(20)
              .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
              .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: S_1, bottomRight: R_MD + 4 })
              .backgroundColor(PURPLE_LIGHT).constraintSize({ maxWidth: "85%" })
            Row() {
              Text("\uD83D\uDCCB").fontSize(9).fontColor(TEXT_4).padding({ top: S_1, right: S_2 })
                .onClick((): void => { if (this.onCopy) { this.onCopy(this.msg.content) } })
              Text("\u21BB").fontSize(10).fontColor(TEXT_4).padding({ top: S_1 })
                .onClick((): void => { if (this.onRegen) { this.onRegen(this.msg) } })
              Text("\uD83D\uDC4E").fontSize(9).fontColor(TEXT_4).padding({ top: S_1, left: S_2 })
                .onClick((): void => { if (this.onFeedback) { this.onFeedback(this.msg) } })
            }
          }.alignItems(HorizontalAlign.Start)
          Blank()
        }.width("100%").margin({ top: S_2 })
      }
    }
  }
}
