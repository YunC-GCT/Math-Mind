// ============================================================================
//  prototypes/AgentFloatWindow.ets — AI 对话浮窗装配层
//  ----------------------------------------------------------------------------
//  职责: 持有全部 @State + 业务逻辑, build() 仅组装 8 个子组件。
//  (完整文档见代码头部注释)
// ============================================================================

import { BG_DARK, TEXT_4, BORDER, S_2, S_3, S_4, S_6, R_XL, OVERLAY_MASK } from "common"
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
import { SessionBar } from "./chat/SessionBar"

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
      this.sync(); this.sm.save(this.sessions)
      setTimeout((): void => { this.scroller.scrollEdge(Edge.Bottom) }, 200)
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
    this.messages = [{ id: 1, role: "ai", content: "你好，我是 MathMind AI。可以帮你分析错题、讲解知识点、生成练习题。试试问我吧 👉", ts: Date.now() }]
  }

  private sync(): void { for (let i = 0; i < this.sessions.length; i++) { if (this.sessions[i].id === this.activeSid) { this.sessions[i].messages = this.messages; return } } }
  private switchSession(sid: string): void { this.sync(); for (let i = 0; i < this.sessions.length; i++) { if (this.sessions[i].id === sid) { this.activeSid = sid; this.messages = this.sessions[i].messages; return } } }
  private newSession(): void { this.sync(); const s: Session = { id: sid(), name: "会话 " + (this.sessions.length + 1).toString(), messages: [] }; this.sessions = [...this.sessions, s]; this.activeSid = s.id; this.messages = []; this.sm.save(this.sessions) }
  private deleteSession(sid: string): void { if (this.sessions.length <= 1) return; const f = this.sessions.filter((s: Session): boolean => s.id !== sid); this.sessions = f; if (sid === this.activeSid) { this.activeSid = f[0].id; this.messages = f[0].messages }; this.sm.save(this.sessions) }

  private send = (text?: string): void => {
    const msg = (text ?? this.inputText).trim()
    if (!msg && !this.imagePreview) { return }
    if (this.busy) { try { promptAction.showToast({ message: "AI 正在回复", duration: 1200 }) } catch (e) {}; return }
    this.messages = [...this.messages, { id: nowId(), role: "user", content: msg || "[图片]", ts: Date.now() }]
    this.inputText = ""; this.imagePreview = ""
    this.realReply(msg)
  }

  private realReply = async (userContent: string): Promise<void> => {
    this.busy = true
    const placeholder: ChatMsg = { id: nowId(), role: "ai", content: "思考中...", ts: Date.now() }
    this.messages = [...this.messages, placeholder]
    try {
      if (!(await LlmConfig.getInstance().isConfigured())) { this.fillLast("请先配置 API Key"); return }
      const sp = this.deepThink
        ? "你是 MathMind AI 深度思考助手。逐步推理，展示完整思考过程。数学用 Unicode 直接输出如 ∫sin x dx, lim(n→∞), Σx²。不用 $ 或 $$ 包裹。"
        : "你是 MathMind AI 助手，简洁中文回答。数学用 Unicode 直接输出如 ∫sin x dx, lim(n→∞), Σx²。不用 $ 或 $$ 包裹。"
      const fullReply = await new LlmClient().call([{ role: "system", content: sp }, { role: "user", content: userContent }])
      if (typeof fullReply !== "string" || fullReply.trim().length === 0) {
        this.fillLast("（AI 返回了空内容，请重试）"); return
      }
      placeholder.content = ""
      this.streamInto(placeholder, fullReply)
    } catch (e) {
      const errMsg: string = (e as Error).message ?? "AI 回复异常"
      placeholder.content = errMsg
      this.messages = [...this.messages]
      this.busy = false
    }
  }

  private streamInto(target: ChatMsg, fullText: string): void {
    let pos = 0
    const total = fullText.length
    const t = setInterval((): void => {
      pos = Math.min(pos + 4, total)
      target.content = fullText.substring(0, pos)
      this.messages = [...this.messages]
      if (pos >= total) { clearInterval(t); this.busy = false; this.scroller.scrollEdge(Edge.Bottom) }
    }, 20)
  }

  private fillLast(text: string): void {
    const last = this.messages[this.messages.length - 1]
    if (last && last.role === "ai") { last.content = text; this.messages = [...this.messages] }
    this.busy = false
  }

  build() {
    Stack() {
      if (this.show) {
        Column().width("100%").height("100%").backgroundColor(OVERLAY_MASK).onClick((): void => this.onClose())
        Column() {
          Row() { Row().width(36).height(5).borderRadius(3).backgroundColor(TEXT_4) }.width("100%").height(S_6).justifyContent(FlexAlign.Center)
          ChatHeader({ deepThink: this.deepThink, onToggleThink: (): void => { this.deepThink = !this.deepThink }, onNewChat: (): void => { this.newSession() }, onClose: this.onClose })
          Row().width("100%").height(0.5).backgroundColor(BORDER)
          SessionBar({ sessions: this.sessions, activeSid: this.activeSid, onSwitch: (sid: string): void => { this.switchSession(sid) }, onDelete: (sid: string): void => { this.deleteSession(sid) }, onNew: (): void => { this.newSession() } })
          Scroll(this.scroller) {
            Column() {
              if (this.messages.length === 0 && !this.busy) { EmptyStateHint() }
              ForEach(this.messages, (msg: ChatMsg): void => { ChatBubble({ msg: msg, onCopy: (): void => {}, onFeedback: (): void => {}, onRegen: (m: ChatMsg): void => { if(m.role==="ai"){const idx=this.messages.findIndex(x=>x.id===m.id);if(idx>0&&this.messages[idx-1].role==="user")this.send(this.messages[idx-1].content)}} }) }, (msg: ChatMsg): string => msg.id.toString())
              if (this.busy && this.messages.length > 0 && this.messages[this.messages.length - 1].content === "思考中...") { TypingIndicator() }
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
