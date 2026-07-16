/**
 * ==========================================================================
 *  ChatBubble.ets — 聊天气泡组件
 *  ==========================================================================
 *  职责: 渲染一条聊天消息气泡, 区分用户/AI 角色, 内嵌操作按钮。
 *  UI:
 *    用户消息 (右对齐, MINT_LIGHT 背景, 右下小圆角):
 *      ┌──────────────────┐
 *      │ 消息内容...       │
 *      └──────────────────┘
 *    AI 消息 (左对齐, PURPLE_LIGHT 背景, AI 标签, 📋↻👎):
 *      AI
 *      ┌──────────────────┐
 *      │ 消息内容...       │  📋 ↻ 👎
 *      └──────────────────┘
 *
 *  接口:
 *    @Prop msg        — 消息对象 {id, role, content, ts}
 *    onCopy(text)     — 复制回调 → 父 toast "已复制"
 *    onRegen(msg)     — 重新生成 → 父重新发送上一条用户消息
 *    onFeedback(msg)  — 反馈回调 → 父记录
 *
 *  MD 净化(cleanMarkdown):
 *    移除 **bold** / __underline__ / ### 标题
 *    LaTeX 残量转换: \lim_{x→} → lim(x→), \frac{a}{b} → (a)/(b)
 *
 *  依赖: common ColorTokens (MINT/PURPLE/TEXT/FONT/SPACING)
 * ==========================================================================
 */// chat/ChatBubble.ets — 聊天气泡 + LaTeX/MD 净化
import { MINT, MINT_LIGHT, MINT_DARK, PURPLE, PURPLE_LIGHT,
  TEXT, TEXT_2, TEXT_4, S_1, S_2, S_3, R_MD, F_XS, F_SM, W_SEMIBOLD,
} from "common"

interface ChatMsg { id: number; role: string; content: string; ts: number }

function cleanMarkdown(raw: string): string {
  let r = raw
  // 移除 **bold** / *italic* / __underline__
  while (r.indexOf("**") >= 0) { const s = r.indexOf("**") + 2; const e = r.indexOf("**", s); if (e < 0) break; r = r.substring(0, s-2) + r.substring(s, e) + r.substring(e+2) }
  while (r.indexOf("__") >= 0) { const s = r.indexOf("__") + 2; const e = r.indexOf("__", s); if (e < 0) break; r = r.substring(0, s-2) + r.substring(s, e) + r.substring(e+2) }
  // LaTeX: \lim_{x\to 0} → lim(x→0)
  while (r.indexOf("\\lim_{") >= 0) { const s = r.indexOf("\\lim_{") + 5; const e = r.indexOf("}", s); if (e < 0) break; const body = r.substring(s, e+1); r = r.substring(0, s-5) + "lim" + body + r.substring(e+1) }
  r = r.replace(/\\to/g, "→")
  // LaTeX: \frac{a}{b} → (a)/(b)
  while (r.indexOf("\\frac{") >= 0) { const s1 = r.indexOf("\\frac{") + 6; const e1 = r.indexOf("}", s1); const s2 = r.indexOf("{", e1) + 1; const e2 = r.indexOf("}", s2); if (e1 < 0 || e2 < 0) break; r = r.substring(0, s1-6) + "(" + r.substring(s1, e1) + ")/(" + r.substring(s2, e2) + ")" + r.substring(e2+1) }
  // 通用: 移除剩余反斜杠命令和花括号
  while (r.indexOf("\\") >= 0) { const s = r.indexOf("\\"); let e = s+1; while (e < r.length && r[e] !== " " && r[e] !== "{" && r[e] !== "\n") e++; r = r.substring(0, s) + r.substring(e) }
  r = r.replace(/{/g, "").replace(/}/g, "")
  // 移除 ### 标题
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
            Text(this.msg.content).fontSize(F_SM).fontColor(MINT_DARK).lineHeight(20)
              .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
              .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: R_MD + 4, bottomRight: S_1 })
              .backgroundColor(MINT_LIGHT).constraintSize({ maxWidth: "88%" })
          }.alignItems(HorizontalAlign.End)
        }.width("100%").margin({ top: S_2 })
      } else {
        Row() {
          Column() {
            Text("AI").fontSize(9).fontColor(TEXT_4).fontWeight(W_SEMIBOLD).margin({ bottom: S_1, left: S_1 })
            Text(this.msg.content).fontSize(F_SM).fontColor(TEXT_2).lineHeight(20)
              .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
              .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: S_1, bottomRight: R_MD + 4 })
              .backgroundColor(PURPLE_LIGHT).constraintSize({ maxWidth: "92%" })
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
