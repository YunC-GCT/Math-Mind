/**
 * ==========================================================================
 *  ChatBubble.ets 鈥?鑱婂ぉ姘旀场缁勪欢
 *  ==========================================================================
 *  鑱岃矗: 娓叉煋涓€鏉¤亰澶╂秷鎭皵娉? 鍖哄垎鐢ㄦ埛/AI 瑙掕壊, 鍐呭祵鎿嶄綔鎸夐挳銆? *
 *  UI:
 *    鐢ㄦ埛娑堟伅 (鍙冲榻? MINT_LIGHT 鑳屾櫙, 鍙充笅灏忓渾瑙?:
 *      鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹? *      鈹?娑堟伅鍐呭...       鈹? *      鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹? *    AI 娑堟伅 (宸﹀榻? PURPLE_LIGHT 鑳屾櫙, AI 鏍囩, 馃搵鈫火煈?:
 *      AI
 *      鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹? *      鈹?娑堟伅鍐呭...       鈹? 馃搵 鈫?馃憥
 *      鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹? *
 *  鎺ュ彛:
 *    @Prop msg        鈥?娑堟伅瀵硅薄 {id, role, content, ts}
 *    onCopy(text)     鈥?澶嶅埗鍥炶皟 鈫?鐖?toast "宸插鍒?
 *    onRegen(msg)     鈥?閲嶆柊鐢熸垚 鈫?鐖堕噸鏂板彂閫佷笂涓€鏉＄敤鎴锋秷鎭? *    onFeedback(msg)  鈥?鍙嶉鍥炶皟 鈫?鐖惰褰? *
 *  MD 鍑€鍖?(cleanMarkdown):
 *    绉婚櫎 **bold** / __underline__ / ### 鏍囬
 *    LaTeX 娈嬮噺杞崲: \lim_{x鈫?} 鈫?lim(x鈫?), \frac{a}{b} 鈫?(a)/(b)
 *
 *  渚濊禆: common ColorTokens (MINT/PURPLE/TEXT/FONT/SPACING)
 * ==========================================================================
 */// chat/ChatBubble.ets 鈥?鑱婂ぉ姘旀场 + LaTeX/MD 鍑€鍖?
import { MINT, MINT_LIGHT, MINT_DARK, PURPLE, PURPLE_LIGHT,
  TEXT, TEXT_2, TEXT_4, S_1, S_2, S_3, R_MD, F_XS, F_SM, W_SEMIBOLD,
} from "common"

interface ChatMsg { id: number; role: string; content: string; ts: number }

function cleanMarkdown(raw: string): string {
  let r = raw
  // 绉婚櫎 **bold** / *italic* / __underline__
  while (r.indexOf("**") >= 0) { const s = r.indexOf("**") + 2; const e = r.indexOf("**", s); if (e < 0) break; r = r.substring(0, s-2) + r.substring(s, e) + r.substring(e+2) }
  while (r.indexOf("__") >= 0) { const s = r.indexOf("__") + 2; const e = r.indexOf("__", s); if (e < 0) break; r = r.substring(0, s-2) + r.substring(s, e) + r.substring(e+2) }
  // LaTeX: \lim_{x\to 0} 鈫?lim(x鈫?)
  while (r.indexOf("\\lim_{") >= 0) { const s = r.indexOf("\\lim_{") + 5; const e = r.indexOf("}", s); if (e < 0) break; const body = r.substring(s, e+1); r = r.substring(0, s-5) + "lim" + body + r.substring(e+1) }
  r = r.replace(/\\to/g, "鈫?)
  // LaTeX: \frac{a}{b} 鈫?(a)/(b)
  while (r.indexOf("\\frac{") >= 0) { const s1 = r.indexOf("\\frac{") + 6; const e1 = r.indexOf("}", s1); const s2 = r.indexOf("{", e1) + 1; const e2 = r.indexOf("}", s2); if (e1 < 0 || e2 < 0) break; r = r.substring(0, s1-6) + "(" + r.substring(s1, e1) + ")/(" + r.substring(s2, e2) + ")" + r.substring(e2+1) }
  // 閫氱敤: 绉婚櫎鍓╀綑鍙嶆枩鏉犲懡浠ゅ拰鑺辨嫭鍙?
  while (r.indexOf("\\") >= 0) { const s = r.indexOf("\\"); let e = s+1; while (e < r.length && r[e] !== " " && r[e] !== "{" && r[e] !== "\n") e++; r = r.substring(0, s) + r.substring(e) }
  r = r.replace(/{/g, "").replace(/}/g, "")
  // 绉婚櫎 ### 鏍囬
  r = r.replace(/#{1,3}\s/g, "")
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
            Text(cleanMarkdown(this.msg.content)).fontSize(F_SM).fontColor(MINT_DARK).lineHeight(20)
              .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
              .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: R_MD + 4, bottomRight: S_1 })
              .backgroundColor(MINT_LIGHT).constraintSize({ maxWidth: "78%" })
          }.alignItems(HorizontalAlign.End)
        }.width("100%").margin({ top: S_2 })
      } else {
        Row() {
          Column() {
            Text("AI").fontSize(9).fontColor(TEXT_4).fontWeight(W_SEMIBOLD).margin({ bottom: S_1, left: S_1 })
            Text(cleanMarkdown(this.msg.content)).fontSize(F_SM).fontColor(TEXT_2).lineHeight(20)
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
