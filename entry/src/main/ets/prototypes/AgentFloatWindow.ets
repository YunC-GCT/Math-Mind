/**
 * ==========================================================================
 *  AgentFloatWindow.ets 鈥?AI 瀵硅瘽娴獥瑁呴厤灞? *  ==========================================================================
 *  鑱岃矗: 鎸佹湁鍏ㄩ儴 @State + 涓氬姟閫昏緫, build() 浠呯粍瑁?8 涓瓙缁勪欢銆? *
 *  鏁版嵁娴?(鍗曞悜 Parent 鈫?Child):
 *    messages/inputText/busy 鈫?@Prop 鈫?ChatBubble/MessageInput/...
 *    瀛愮粍浠跺洖璋?鈫?onChange/onSend 绛?鈫?鐖舵洿鏂?@State
 *
 *  瀛愮粍浠?(prototypes/chat/):
 *    ChatHeader      鈥?澶撮儴: 妯″瀷鍚?+ 娣卞害鎬濊€?SVG 鑳跺泭 + [+]鏂板璇?+ [鉁昡鍏抽棴
 *    SessionBar      鈥?浼氳瘽鍒囨崲鏍? 姘村钩婊氬姩 鈼忊棆 鏍囩 + [+]鏂板缓
 *    ChatBubble      鈥?鑱婂ぉ姘旀场: 鐢ㄦ埛(鍙矼INT) + AI(宸URPLE) + 馃搵鈫火煈庢搷浣? *    TypingIndicator 鈥?typing 涓夌偣鍔ㄧ敾 (ArkUI animation)
 *    EmptyStateHint  鈥?绌虹姸鎬佸紩瀵? 閽荤煶 SVG + 鏂囨
 *    QuickSuggestions 鈥?鎺ㄨ崘蹇嵎璇? 鍒嗘瀽閿欓/璁茶В鏋侀檺/鐢熸垚缁冧範/姊崇悊鐭ヨ瘑
 *    MessageInput    鈥?杈撳叆鏍? 鍥剧墖棰勮 + 杈撳叆妗?+ 鎷嶇収鎸夐挳 + 鍙戦€佹寜閽? *    ChatSession     鈥?闈濽I宸ュ叿绫? preferences 浼氳瘽鎸佷箙鍖? *
 *  瀵规帴:
 *    LlmClient.call()  鈥?AI 璋冪敤 (DeepSeek API)
 *    LlmConfig         鈥?绔偣/妯″瀷/Key 閰嶇疆
 *    preferences       鈥?浼氳瘽鍘嗗彶鎸佷箙鍖? *    Index.ets          鈥?鐖剁粍浠舵帶鍒?show/onClose/onGoCamera/pendingImageUri
 *
 *  娴佸紡杈撳嚭:
 *    鎻掑叆绌哄崰浣嶆秷鎭?鈫?LlmClient.call() 鈫?streamInto() 鍘熷湴鏇存柊 content
 *    鈫?鍗曟皵娉″師鍦板闀? 鏃犺烦鍙? 鏃犳埅鏂? *
 *  鑷姩婊氬姩:
 *    @Watch onMessagesChange 鈫?setTimeout 200ms 鈫?scrollEdge(Bottom)
 *
 *  浼氳瘽鎸佷箙鍖?
 *    ChatSessionManager 灏佽 preferences CRUD
 *    loadHistory() / saveHistory() / sync() 绠＄悊澶氫細璇? * ==========================================================================
 */
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
  @State sessions: Session[] = [{ id: "s1", name: "浼氳瘽 1", messages: [] }]
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
    this.messages = [{ id: 1, role: "ai", content: "浣犲ソ锛屾垜鏄?MathMind AI銆傚彲浠ュ府浣犲垎鏋愰敊棰樸€佽瑙ｇ煡璇嗙偣銆佺敓鎴愮粌涔犻銆傝瘯璇曢棶鎴戝惂 馃憞", ts: Date.now() }]
  }

  private sync(): void { for (let i = 0; i < this.sessions.length; i++) { if (this.sessions[i].id === this.activeSid) { this.sessions[i].messages = this.messages; return } } }
  private switchSession(sid: string): void { this.sync(); for (let i = 0; i < this.sessions.length; i++) { if (this.sessions[i].id === sid) { this.activeSid = sid; this.messages = this.sessions[i].messages; return } } }
  private newSession(): void { this.sync(); const s: Session = { id: sid(), name: "浼氳瘽 " + (this.sessions.length + 1).toString(), messages: [] }; this.sessions = [...this.sessions, s]; this.activeSid = s.id; this.messages = []; this.sm.save(this.sessions) }
  private deleteSession(sid: string): void { if (this.sessions.length <= 1) return; const f = this.sessions.filter((s: Session): boolean => s.id !== sid); this.sessions = f; if (sid === this.activeSid) { this.activeSid = f[0].id; this.messages = f[0].messages }; this.sm.save(this.sessions) }

  private send = (text?: string): void => {
    const msg = (text ?? this.inputText).trim()
    if (!msg && !this.imagePreview) { return }
    if (this.busy) { promptAction.showToast({ message: "AI 姝ｅ湪鍥炲", duration: 1200 }); return }
    this.messages = [...this.messages, { id: nowId(), role: "user", content: msg || "[鍥剧墖]", ts: Date.now() }]
    this.inputText = ""; this.imagePreview = ""
    this.realReply(msg)
  }

  private realReply = async (userContent: string): Promise<void> => {
    this.busy = true
    // 鍏堟彃鍏ュ崰浣嶆秷鎭紙娴佸紡鏈熼棿鏄剧ず TypingIndicator锛?    this.messages = [...this.messages, { id: nowId(), role: "ai", content: "", ts: Date.now() }]
    try {
      if (!(await LlmConfig.getInstance().isConfigured())) { this.fillLast("璇峰厛閰嶇疆 API Key"); return }
      const sp = this.deepThink
        ? "浣犳槸 MathMind AI 娣卞害鎬濊€冨姪鎵嬨€傞€愭鎺ㄧ悊锛屽睍绀哄畬鏁存€濊€冭繃绋嬨€傛暟瀛︾敤 Unicode 鐩存帴杈撳嚭濡?鈭玸in x dx, lim(n鈫掆垶), 危x虏銆備笉鐢?$ 鎴?$$ 鍖呰９銆?
        : "浣犳槸 MathMind AI 鍔╂墜锛岀畝娲佷腑鏂囧洖绛斻€傛暟瀛︾敤 Unicode 鐩存帴杈撳嚭濡?鈭玸in x dx, lim(n鈫掆垶), 危x虏銆備笉鐢?$ 鎴?$$ 鍖呰９銆?
      const fullReply = await new LlmClient().call([{ role: "system", content: sp }, { role: "user", content: userContent }])
      this.streamInto(fullReply)
      this.busy = false
      setTimeout((): void => { this.scroller.scrollEdge(Edge.Bottom) }, 200)
    } catch (e) { this.fillLast((e as Error).message ?? "AI 鍥炲寮傚父"); this.busy = false }
  }

  private streamInto(fullText: string): void {
    const target = this.messages[this.messages.length - 1]
    let pos = 0
    const t = setInterval((): void => {
      pos = Math.min(pos + 4, fullText.length)
      target.content = fullText.substring(0, pos)
      this.messages = [...this.messages] // 瑙﹀彂閲嶆覆鏌?      if (pos >= fullText.length) { clearInterval(t) }
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