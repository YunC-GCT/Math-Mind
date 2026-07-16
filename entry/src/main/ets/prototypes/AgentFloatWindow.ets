/**
 * ==========================================================================
 *  AgentFloatWindow.ets — AI 对话浮窗装配层
 *  ==========================================================================
 *  职责: 持有全部 @State + 业务逻辑, build() 仅组装 8 个子组件。
 *
 *  数据流 (单向 Parent → Child):
 *    messages/inputText/busy → @Prop → ChatBubble/MessageInput/...
 *    子组件回调 → onChange/onSend 等 → 父更新 @State
 *
 *  子组件 (prototypes/chat/):
 *    ChatHeader      — 头部: 模型名 + 深度思考 SVG 胶囊 + [+]新对话 + [✕]关闭
 *    SessionBar      — 会话切换栏: 水平滚动 ●○ 标签 + [+]新建
 *    ChatBubble      — 聊天气泡: 用户(右MINT) + AI(左PURPLE) + 📋↻👎操作
 *    TypingIndicator — typing 三点动画 (ArkUI animation)
 *    EmptyStateHint  — 空状态引导: 钻石 SVG + 文案
 *    QuickSuggestions — 推荐快捷词: 分析错题/讲解极限/生成练习/梳理知识
 *    MessageInput    — 输入栏: 图片预览 + 输入框 + 拍照按钮 + 发送按钮
 *    ChatSession     — 非UI工具类: preferences 会话持久化
 *
 *  对接:
 *    LlmClient.call()  — AI 调用 (DeepSeek API)
 *    LlmConfig         — 端点/模型/Key 配置
 *    preferences       — 会话历史持久化
 *    Index.ets          — 父组件控制 show/onClose/onGoCamera/pendingImageUri
 *
 *  流式输出:
 *    插入空占位消息 → LlmClient.call() → streamInto() 原地更新 content
 *    → 单气泡原地增长, 无跳变, 无截断
 *
 *  自动滚动:
 *    @Watch onMessagesChange → setTimeout 200ms → scrollEdge(Bottom)
 *
 *  会话持久化:
 *    ChatSessionManager 封装 preferences CRUD
 *    loadHistory() / saveHistory() / sync() 管理多会话
 * ==========================================================================
 */import { MINT, MINT_LIGHT, BG_DARK, TEXT_4, BORDER, S_1, S_2, S_3, S_4, S_6, R_XL, R_FULL, F_XS, F_SM, W_MEDIUM, GLASS_10, OVERLAY_MASK } from "common"
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
    this.messages = [{ id: 1, role: "ai", content: "你好，我是 MathMind AI。可以帮你分析错题、讲解知识点、生成练习题。试试问我吧 👇", ts: Date.now() }]
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
    this.busy = true
    // 先插入占位消息（流式期间显示 TypingIndicator）
    this.messages = [...this.messages, { id: nowId(), role: "ai", content: "", ts: Date.now() }]
    try {
      if (!(await LlmConfig.getInstance().isConfigured())) { this.fillLast("请先配置 API Key"); return }
      const sp = this.deepThink
        ? "你是 MathMind AI 深度思考助手。逐步推理，展示完整思考过程。数学用 Unicode 直接输出如 ∫sin x dx, lim(n→∞), Σx²。不用 $ 或 $$ 包裹。"
        : "你是 MathMind AI 助手，简洁中文回答。数学用 Unicode 直接输出如 ∫sin x dx, lim(n→∞), Σx²。不用 $ 或 $$ 包裹。"
      const fullReply = await new LlmClient().call([{ role: "system", content: sp }, { role: "user", content: userContent }])
      this.streamInto(fullReply)
      this.busy = false
      setTimeout((): void => { this.scroller.scrollEdge(Edge.Bottom) }, 200)
    } catch (e) { this.fillLast((e as Error).message ?? "AI 回复异常"); this.busy = false }
  }

  private streamInto(fullText: string): void {
    const target = this.messages[this.messages.length - 1]
    let pos = 0
    const t = setInterval((): void => {
      pos = Math.min(pos + 4, fullText.length)
      target.content = fullText.substring(0, pos)
      this.messages = [...this.messages] // 触发重渲染
      if (pos >= fullText.length) { clearInterval(t) }
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
              if (this.busy && this.messages.length > 0 && this.messages[this.messages.length - 1].content.length === 0) { TypingIndicator() }
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