/**
 * MathMind AI 浮窗 · 装配层 (7 子组件 + 会话管理)
 */
import { MINT, MINT_LIGHT, BG_DARK, TEXT_4, BORDER, S_1, S_2, S_3, S_4, S_6, R_XL, R_FULL, F_XS, F_SM, W_MEDIUM, GLASS_10, OVERLAY_MASK } from "common"
import { LlmClient, LlmConfig } from "common"
import { promptAction } from "@kit.ArkUI"
import window from "@ohos.window"
import { ChatHeader } from "./chat/ChatHeader"
import { ChatBubble } from "./chat/ChatBubble"
import { TypingIndicator } from "./chat/TypingIndicator"
import { EmptyStateHint } from "./chat/EmptyStateHint"
import { QuickSuggestions } from "./chat/QuickSuggestions"
import { MessageInput } from "./chat/MessageInput"
import { ChatSessionManager, sid } from "./chat/ChatSession"

interface ChatMsg { id: number; role: string; content: string; ts: number }
interface Session { id: string; name: string; messages: ChatMsg[] }
function nowId(): number { return Date.now() * 1000 + Math.floor(Math.random() * 1000) }

@Component
export struct AgentFloatWindow {
  @Prop show: boolean = false
  onClose: () => void = (): void => {}
  onGoCamera: () => void = (): void => {}
  @Prop @Watch("onPendingImageChange") pendingImageUri: string = ""
  @State @Watch("onMessagesChange") messages: ChatMsg[] = []
  @State inputText: string = ""
  @State busy: boolean = false
  @State deepThink: boolean = false
  @State imagePreview: string = ""
  @State streamBuffer: string = ""
  @State keyboardHeight: number = 0
  @State sessions: Session[] = [{ id: "s1", name: "会话 1", messages: [] }]
  @State activeSid: string = "s1"
  private mainWindow: window.Window | null = null
  private scroller: Scroller = new Scroller()
  private sm: ChatSessionManager = new ChatSessionManager()

  aboutToAppear(): void { this.loadHistory(); this.initKeyboard() }
  aboutToDisappear(): void { if (this.mainWindow) { this.mainWindow.off("keyboardHeightChange") }; this.sm.save(this.sessions) }
  onPendingImageChange(): void { if (this.pendingImageUri.length > 0) { this.imagePreview = this.pendingImageUri } }
  onMessagesChange(): void {
    if (this.messages.length > 0) {
      setTimeout((): void => { this.scroller.scrollToIndex(this.messages.length - 1, false) }, 100)
      this.sync(); this.sm.save(this.sessions)
    }
  }

  private initKeyboard(): void {
    try { const ctx = this.getUIContext().getHostContext()
      if (ctx) { window.getLastWindow(ctx).then((win: window.Window): void => {
        this.mainWindow = win; win.on("keyboardHeightChange", (d: number): void => { try { this.keyboardHeight = this.getUIContext().px2vp(d) } catch (e) {} })
      }).catch((): void => {}) }
    } catch (e) {}
  }

  private async loadHistory(): Promise<void> {
    const ss = await this.sm.init(getContext(this))
    if (ss.length > 0) { this.sessions = ss; this.activeSid = ss[0].id; this.messages = ss[0].messages; return }
    this.messages = [{ id: 1, role: "ai", content: "你好，我是 MathMind AI。\n\n可以帮你分析错题、讲解知识点、生成练习题。试着问我吧 👇", ts: Date.now() }]
  }

  private sync(): void { for (let i = 0; i < this.sessions.length; i++) { if (this.sessions[i].id === this.activeSid) { this.sessions[i].messages = this.messages; return } } }
  private switchSession(sid: string): void { this.sync(); for (let i = 0; i < this.sessions.length; i++) { if (this.sessions[i].id === sid) { this.activeSid = sid; this.messages = this.sessions[i].messages; return } } }
  private newSession(): void { this.sync(); const s: Session = { id: sid(), name: "会话 " + (this.sessions.length + 1).toString(), messages: [] }; this.sessions = [...this.sessions, s]; this.activeSid = s.id; this.messages = []; this.sm.save(this.sessions) }
  private deleteSession(sid: string): void { if (this.sessions.length <= 1) return; const f = this.sessions.filter((s: Session): boolean => s.id !== sid); this.sessions = f; if (sid === this.activeSid) { this.activeSid = f[0].id; this.messages = f[0].messages }; this.sm.save(this.sessions) }

  private send = (text?: string): void => {
    const msg = (text ?? this.inputText).trim()
    if (!msg && !this.imagePreview) { return }
    if (this.busy) { promptAction.showToast({ message: "AI 正在回复", duration: 1200 }); return }
    this.messages = [...this.messages, { id: nowId(), role: "user", content: msg || "[图片]", ts: Date.now() }]
    this.inputText = ""; this.imagePreview = ""
    this.realReply(msg)
  }

  private realReply = async (userContent: string): Promise<void> => {
    this.busy = true; this.streamBuffer = ""
    try {
      if (!(await LlmConfig.getInstance().isConfigured())) { this.addFinal("请先配置 API Key"); return }
      const sp = this.deepThink ? "你是 MathMind AI 深度思考助手。逐步推理，展示完整思考过程，使用 LaTeX。" : "你是 MathMind AI 助手，简洁中文回答，适当使用 LaTeX。"
      this.streamOut(await new LlmClient().call([{ role: "system", content: sp }, { role: "user", content: userContent }]))
    } catch (e) { this.addFinal((e as Error).message ?? "AI 回复异常") }
  }

  private streamOut(text: string): void { let pos = 0; const t = setInterval((): void => { pos = Math.min(pos + 3, text.length); this.streamBuffer = text.substring(0, pos); if (pos >= text.length) { clearInterval(t); this.addFinal(text) } }, 25) }
  private addFinal(text: string): void { this.messages = [...this.messages, { id: nowId(), role: "ai", content: text, ts: Date.now() }]; this.busy = false; this.streamBuffer = ""; setTimeout((): void => { this.scroller.scrollEdge(Edge.Bottom) }, 150) }

  @Builder SessionBar() {
    Row() {
      Scroll() {
        Row() {
          ForEach(this.sessions, (s: Session): void => {
            Row() {
              Text(s.id === this.activeSid ? "● " + s.name : "○ " + s.name).fontSize(F_XS).fontColor(s.id === this.activeSid ? MINT : TEXT_3).fontWeight(W_MEDIUM)
              if (this.sessions.length > 1) { Text("✕").fontSize(9).fontColor(TEXT_4).margin({ left: S_1 }).onClick((): void => { this.deleteSession(s.id) }) }
            }.padding({ left: S_2, right: S_2, top: S_1, bottom: S_1 }).borderRadius(R_FULL).backgroundColor(s.id === this.activeSid ? MINT_LIGHT : GLASS_10).margin({ right: S_2 }).onClick((): void => { this.switchSession(s.id) })
          }, (s: Session): string => s.id)
          Text("+").fontSize(F_SM).fontColor(TEXT_3).width(28).height(28).borderRadius(14).textAlign(TextAlign.Center).backgroundColor(GLASS_10).onClick((): void => { this.newSession() })
        }.padding({ left: S_2, right: S_2 })
      }.layoutWeight(1).scrollBar(BarState.Off)
    }.width("100%").height(36).padding({ top: S_1, bottom: S_1 })
  }

  build() {
    Stack() {
      if (this.show) {
        Column().width("100%").height("100%").backgroundColor(OVERLAY_MASK).onClick((): void => this.onClose())
        Column() {
          Row() { Row().width(36).height(5).borderRadius(3).backgroundColor(TEXT_4) }.width("100%").height(S_6).justifyContent(FlexAlign.Center)
          ChatHeader({ deepThink: this.deepThink, onToggleThink: (): void => { this.deepThink = !this.deepThink }, onNewChat: (): void => { this.newSession() }, onClose: this.onClose })
          Row().width("100%").height(0.5).backgroundColor(BORDER)
          this.SessionBar()
          Scroll(this.scroller) {
            Column() {
              if (this.messages.length === 0 && !this.busy) { EmptyStateHint() }
              ForEach(this.messages, (msg: ChatMsg): void => { ChatBubble({ msg: msg, onCopy: (): void => {}, onFeedback: (): void => {}, onRegen: (m: ChatMsg): void => { if(m.role==="ai"){const idx=this.messages.findIndex(x=>x.id===m.id);if(idx>0&&this.messages[idx-1].role==="user")this.send(this.messages[idx-1].content)}} }) }, (msg: ChatMsg): string => msg.id.toString())
              if (this.streamBuffer.length > 0) { ChatBubble({ msg: { id: 0, role: "ai", content: this.streamBuffer, ts: Date.now() }, onCopy: (): void => {}, onFeedback: (): void => {}, onRegen: (): void => {} }) }
              else if (this.busy) { TypingIndicator() }
              Blank().height(S_2)
            }.width("100%").padding({ left: S_4, right: S_4, top: S_2 })
          }.layoutWeight(1).width("100%").scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
          Row().width("100%").height(0.5).backgroundColor(BORDER)
          QuickSuggestions({ onSelect: (p: string): void => { this.send(p) } })
          MessageInput({ inputText: this.inputText, imagePreview: this.imagePreview, busy: this.busy, onTextChange: (v: string): void => { this.inputText = v }, onSend: (): void => { this.send() }, onCamera: (): void => { this.onGoCamera() }, onClearImage: (): void => { this.imagePreview = "" } })
        }
        .width("100%").height("48%").backgroundColor(BG_DARK).borderRadius({ topLeft: R_XL, topRight: R_XL }).padding({ left: S_3, right: S_3 }).position({ x: 0, y: "100%" }).markAnchor({ x: 0, y: "100%" }).translate({ y: -(74 + this.keyboardHeight) })
      }
    }.width("100%").height("100%").hitTestBehavior(this.show ? HitTestMode.Default : HitTestMode.None)
  }
}