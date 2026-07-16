/**
 * MathMind AI 浮窗 · 装配层 (6 子组件 + 多会话持久化)
 */
import { MINT, MINT_LIGHT, BG_DARK, TEXT, TEXT_3, TEXT_4, BORDER, S_1, S_2, S_3, S_4, S_6, R_MD, R_XL, R_FULL, F_XS, F_SM, W_MEDIUM, GLASS_10, OVERLAY_MASK } from "common"
import { LlmClient, LlmConfig } from "common"
import { promptAction } from "@kit.ArkUI"
import window from "@ohos.window"
import { preferences } from "@kit.ArkData"
import { ChatHeader } from "./chat/ChatHeader"
import { ChatBubble } from "./chat/ChatBubble"
import { TypingIndicator } from "./chat/TypingIndicator"
import { EmptyStateHint } from "./chat/EmptyStateHint"
import { QuickSuggestions } from "./chat/QuickSuggestions"
import { MessageInput } from "./chat/MessageInput"

interface ChatMsg { id: number; role: string; content: string; ts: number }
interface Session { id: string; name: string; messages: ChatMsg[] }
function nowId(): number { return Date.now() * 1000 + Math.floor(Math.random() * 1000) }
function sid(): string { return Date.now().toString(36) }

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
  @State sessions: Session[] = [{ id: "s1", name: "\u5BF9\u8BDD 1", messages: [] }]
  @State activeSid: string = "s1"
  @State showSessions: boolean = false
  private mainWindow: window.Window | null = null
  private scroller: Scroller = new Scroller()
  private prefs: preferences.Preferences | null = null

  aboutToAppear(): void { this.loadHistory(); this.initKeyboard() }
  aboutToDisappear(): void { if (this.mainWindow) { this.mainWindow.off("keyboardHeightChange") }; this.saveHistory() }
  onPendingImageChange(): void { if (this.pendingImageUri.length > 0) { this.imagePreview = this.pendingImageUri } }
  onMessagesChange(): void {
    if (this.messages.length > 0) {
      setTimeout((): void => { this.scroller.scrollEdge(Edge.Bottom) }, 80)
      this.syncSession(); this.saveHistory()
    }
  }

  private initKeyboard(): void {
    try { const ctx = this.getUIContext().getHostContext()
      if (ctx) { window.getLastWindow(ctx).then((win: window.Window): void => {
        this.mainWindow = win; win.on("keyboardHeightChange", (data: number): void => {
          try { this.keyboardHeight = this.getUIContext().px2vp(data) } catch (e) {}
        })
      }).catch((_err: Error): void => {}) }
    } catch (e) {}
  }

  private async loadHistory(): Promise<void> {
    try {
      this.prefs = await preferences.getPreferences(getContext(this), "chat_history")
      const raw = this.prefs.getSync("sessions", "") as string
      if (raw && raw.length > 0) {
        try { const parsed = JSON.parse(raw) as Session[]; if (parsed.length > 0) { this.sessions = parsed; this.activeSid = parsed[0].id; this.messages = parsed[0].messages; return } } catch (e) {}
      }
    } catch (e) {}
    this.sessions = [{ id: "s1", name: "\u5BF9\u8BDD 1", messages: [] }]
    this.activeSid = "s1"
    this.messages = [{ id: 1, role: "ai", content: "\u4F60\u597D\uFF0C\u6211\u662F MathMind AI\u3002\n\n\u53EF\u4EE5\u5E2E\u4F60\u5206\u6790\u9519\u9898\u3001\u8BB2\u89E3\u77E5\u8BC6\u70B9\u3001\u751F\u6210\u7EC3\u4E60\u9898\u3002\u8BD5\u7740\u95EE\u6211\u5427 \uD83D\uDC47", ts: Date.now() }]
    this.syncSession()
  }
  private saveHistory(): void {
    if (this.prefs) { try { this.prefs.putSync("sessions", JSON.stringify(this.sessions)); this.prefs.flush() } catch (e) {} }
  }
  private syncSession(): void {
    for (let i = 0; i < this.sessions.length; i++) { if (this.sessions[i].id === this.activeSid) { this.sessions[i].messages = this.messages; return } }
  }
  private switchSession(sid: string): void {
    this.syncSession()
    for (let i = 0; i < this.sessions.length; i++) { if (this.sessions[i].id === sid) { this.activeSid = sid; this.messages = this.sessions[i].messages; this.showSessions = false; return } }
  }
  private newSession(): void {
    this.syncSession()
    const n = this.sessions.length + 1
    const s: Session = { id: sid(), name: "\u5BF9\u8BDD " + n.toString(), messages: [] }
    this.sessions = [...this.sessions, s]
    this.activeSid = s.id; this.messages = []; this.showSessions = false
    this.saveHistory()
  }
  private deleteSession(sid: string): void {
    if (this.sessions.length <= 1) return
    const filtered = this.sessions.filter((s: Session): boolean => s.id !== sid)
    this.sessions = filtered
    if (sid === this.activeSid) { this.activeSid = filtered[0].id; this.messages = filtered[0].messages }
    this.saveHistory()
  }

  private send = (text?: string): void => {
    const msg = (text ?? this.inputText).trim()
    if (!msg && !this.imagePreview) { return }
    if (this.busy) { promptAction.showToast({ message: "AI\u6B63\u5728\u56DE\u590D", duration: 1200 }); return }
    this.messages = [...this.messages, { id: nowId(), role: "user", content: msg || "[\u56FE\u7247]", ts: Date.now() }]
    this.inputText = ""; this.imagePreview = ""
    this.realReply(msg)
  }
  private realReply = async (userContent: string): Promise<void> => {
    this.busy = true; this.streamBuffer = ""
    try {
      if (!(await LlmConfig.getInstance().isConfigured())) { this.streamBuffer = "\u8BF7\u5148\u914D\u7F6E API Key"; this.finishStream(); return }
      const sp = this.deepThink ? "\u4F60\u662F MathMind AI \u6DF1\u5EA6\u601D\u8003\u52A9\u624B\u3002\u9010\u6B65\u63A8\u7406\uFF0C\u4F7F\u7528 LaTeX\u3002" : "\u4F60\u662F MathMind AI \u52A9\u624B\uFF0C\u7B80\u6D01\u4E2D\u6587\u56DE\u7B54\uFF0C\u4F7F\u7528 LaTeX\u3002"
      const fullReply = await new LlmClient().call([{ role: "system", content: sp }, { role: "user", content: userContent }])
      this.streamOut(fullReply)
    } catch (e) {
      const err = (e as Error).message ?? ""
      const errMsg = err.indexOf("NO_API_KEY") >= 0 ? "\u8BF7\u5148\u914D\u7F6E API Key" : err.indexOf("NETWORK_ERROR") >= 0 ? "\u7F51\u7EDC\u8FDE\u63A5\u5931\u8D25" : "AI\u56DE\u590D\u5F02\u5E38"
      this.messages = [...this.messages, { id: nowId(), role: "ai", content: errMsg, ts: Date.now() }]
      this.busy = false; this.streamBuffer = ""
    }
  }
  private streamOut(fullText: string): void {
    const msgId = nowId(); let pos = 0
    const timer = setInterval((): void => {
      if (pos < fullText.length) { pos = Math.min(pos + 4, fullText.length); this.streamBuffer = fullText.substring(0, pos) }
      else { clearInterval(timer); this.finishStream() }
    }, 25)
  }
  private finishStream(): void {
    if (this.streamBuffer.length > 0) { this.messages = [...this.messages, { id: nowId(), role: "ai", content: this.streamBuffer, ts: Date.now() }] }
    this.busy = false; this.streamBuffer = ""
  }
  private addAiMsg = (content: string): void => {
    this.messages = [...this.messages, { id: nowId(), role: "ai", content, ts: Date.now() }]
  }

  @Builder SessionBar() {
    Row() {
      Scroll() {
        Row() {
          ForEach(this.sessions,
            (s: Session): void => {
              Row() {
                Text(s.id === this.activeSid ? "\u25CF " + s.name : "\u25CB " + s.name)
                  .fontSize(F_XS).fontColor(s.id === this.activeSid ? MINT : TEXT_3).fontWeight(W_MEDIUM)
                if (this.sessions.length > 1) {
                  Text("\u2715").fontSize(9).fontColor(TEXT_4).margin({ left: S_1 })
                    .onClick((): void => { this.deleteSession(s.id) })
                }
              }
              .padding({ left: S_2, right: S_2, top: S_1, bottom: S_1 }).borderRadius(R_FULL)
              .backgroundColor(s.id === this.activeSid ? MINT_LIGHT : GLASS_10)
              .margin({ right: S_2 })
              .onClick((): void => { this.switchSession(s.id) })
            }, (s: Session): string => s.id)
          Text("+").fontSize(F_SM).fontColor(TEXT_3).width(28).height(28).borderRadius(14)
            .textAlign(TextAlign.Center).backgroundColor(GLASS_10)
            .onClick((): void => { this.newSession() })
        }.padding({ left: S_2, right: S_2 })
      }.layoutWeight(1).scrollBar(BarState.Off)
    }.width("100%").height(36).padding({ top: S_1, bottom: S_1 })
  }

  build() {
    Stack() {
      if (this.show) {
        Column().width("100%").height("100%").backgroundColor(OVERLAY_MASK).onClick((): void => this.onClose())
        Column() {
          Row() { Row().width(36).height(5).borderRadius(3).backgroundColor(TEXT_4) }
            .width("100%").height(S_6).justifyContent(FlexAlign.Center)
          ChatHeader({ deepThink: this.deepThink, onToggleThink: (): void => { this.deepThink = !this.deepThink }, onNewChat: (): void => { this.newSession() }, onClose: this.onClose })
          Row().width("100%").height(0.5).backgroundColor(BORDER)
          this.SessionBar()
          Scroll(this.scroller) {
            Column() {
              if (this.messages.length === 0 && !this.busy) { EmptyStateHint() }
              ForEach(this.messages,
                (msg: ChatMsg): void => { ChatBubble({ msg: msg, onCopy: (): void => {}, onFeedback: (): void => {}, onRegen: (m: ChatMsg): void => { if(m.role==="ai"){const idx=this.messages.findIndex(x=>x.id===m.id);if(idx>0&&this.messages[idx-1].role==="user")this.send(this.messages[idx-1].content)}} }) },
                (msg: ChatMsg): string => msg.id.toString()
              )
              if (this.streamBuffer.length > 0) { ChatBubble({ msg: { id: 0, role: "ai", content: this.streamBuffer, ts: Date.now() }, onCopy: (): void => {}, onFeedback: (): void => {}, onRegen: (): void => {} }) }
              else if (this.busy) { TypingIndicator() }
              Blank().height(S_2)
            }.width("100%").padding({ left: S_4, right: S_4, top: S_2 })
          }.layoutWeight(1).width("100%").scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
          Row().width("100%").height(0.5).backgroundColor(BORDER)
          QuickSuggestions({ onSelect: (p: string): void => { this.send(p) } })
          MessageInput({ inputText: this.inputText, imagePreview: this.imagePreview, busy: this.busy,
            onTextChange: (v: string): void => { this.inputText = v }, onSend: (): void => { this.send() },
            onCamera: (): void => { this.onGoCamera() }, onClearImage: (): void => { this.imagePreview = "" } })
        }
        .width("100%").height("48%").backgroundColor(BG_DARK).borderRadius({ topLeft: R_XL, topRight: R_XL })
        .padding({ left: S_3, right: S_3 }).position({ x: 0, y: "100%" }).markAnchor({ x: 0, y: "100%" })
        .translate({ y: -(74 + this.keyboardHeight) })
      }
    }.width("100%").height("100%").hitTestBehavior(this.show ? HitTestMode.Default : HitTestMode.None)
  }
}
