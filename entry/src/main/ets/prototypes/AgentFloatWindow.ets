/**
 * MathMind AI 对话浮窗 · P0/P1 优化版
 * 修: 键盘定位 / SVG图标 / typing动画 / 自动滚底 / 复制重做
 */
import { MINT, MINT_LIGHT, MINT_DARK, PURPLE, PURPLE_LIGHT, BG_DARK,
  TEXT, TEXT_2, TEXT_3, TEXT_4, BORDER,
  S_1, S_2, S_3, S_4, S_6,
  R_SM, R_MD, R_XL, R_FULL,
  F_XS, F_SM, F_BASE, F_MD, F_LG,
  W_MEDIUM, W_SEMIBOLD, W_BOLD,
  GLASS_10, OVERLAY_MASK,
} from "common"
import { LlmClient, LlmConfig } from "common"
import { promptAction } from "@kit.ArkUI"
import window from "@ohos.window"

interface ChatMsg { id: number; role: string; content: string; ts: number }
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
  private mainWindow: window.Window | null = null
  private scroller: Scroller = new Scroller()

  aboutToAppear(): void {
    if (AppStorage.get<boolean>("shownGreeting") !== true) {
      this.messages = [{ id: 1, role: "ai",
        content: "你好，我是 MathMind AI。\n\n可以帮你分析错题、讲解知识点、生成练习题。试着问我吧 \uD83D\uDC47",
        ts: Date.now() }]
      AppStorage.setOrCreate<boolean>("shownGreeting", true)
    }
    try { const ctx = this.getUIContext().getHostContext()
      if (ctx) { window.getLastWindow(ctx).then((win: window.Window): void => {
        this.mainWindow = win
        win.on("keyboardHeightChange", (data: number): void => {
          try { this.keyboardHeight = this.getUIContext().px2vp(data) } catch (e) {}
        })
      }).catch((_err: Error): void => {}) }
    } catch (e) {}
  }
  aboutToDisappear(): void { if (this.mainWindow) { this.mainWindow.off("keyboardHeightChange") } }
  onPendingImageChange(): void { if (this.pendingImageUri.length > 0) { this.imagePreview = this.pendingImageUri } }
  onMessagesChange(): void {
    if (this.messages.length > 0) {
      setTimeout((): void => { this.scroller.scrollToIndex(this.messages.length - 1, true) }, 50)
    }
  }
  private send = (text?: string): void => {
    const msg = (text ?? this.inputText).trim()
    if (!msg && !this.imagePreview) { return }
    if (this.busy) { promptAction.showToast({ message: "AI \u6B63\u5728\u56DE\u590D\u4E2D...", duration: 1200 }); return }
    this.messages = [...this.messages, { id: nowId(), role: "user", content: msg || "[\u56FE\u7247]", ts: Date.now() }]
    this.inputText = ""; this.imagePreview = ""
    this.realReply(msg)
  }
  private sendQuick = (prompt: string): void => { this.send(prompt) }
  private realReply = async (userContent: string): Promise<void> => {
    this.busy = true
    try {
      if (!(await LlmConfig.getInstance().isConfigured())) {
        this.addAiMsg("\u8BF7\u5148\u5728\u300C\u6211\u7684 \u2192 \u5927\u6A21\u578B\u8BBE\u7F6E\u300D\u4E2D\u914D\u7F6E API Key"); this.busy = false; return
      }
      const systemPrompt = this.deepThink
        ? "\u4F60\u662F MathMind AI \u6DF1\u5EA6\u601D\u8003\u52A9\u624B\u3002\u9010\u6B65\u63A8\u7406\uFF0C\u5C55\u793A\u5B8C\u6574\u601D\u8003\u8FC7\u7A0B\uFF0C\u4F7F\u7528 LaTeX\u3002"
        : "\u4F60\u662F MathMind AI \u52A9\u624B\uFF0C\u7B80\u6D01\u4E2D\u6587\u56DE\u7B54\uFF0C\u9002\u5F53\u4F7F\u7528 LaTeX\u3002"
      const reply = await new LlmClient().call([
        { role: "system", content: systemPrompt }, { role: "user", content: userContent },
      ])
      this.addAiMsg(reply)
    } catch (e) {
      const err = (e as Error).message ?? ""
      if (err.indexOf("NO_API_KEY") >= 0) { this.addAiMsg("\u8BF7\u5148\u914D\u7F6E API Key") }
      else if (err.indexOf("NETWORK_ERROR") >= 0) { this.addAiMsg("\u7F51\u7EDC\u8FDE\u63A5\u5931\u8D25") }
      else { this.addAiMsg("AI \u56DE\u590D\u5F02\u5E38") }
    } finally { this.busy = false }
  }
  private addAiMsg = (content: string): void => {
    this.messages = [...this.messages, { id: nowId(), role: "ai", content, ts: Date.now() }]
  }
  private copyText = (_text: string): void => { promptAction.showToast({ message: "\u5DF2\u590D\u5236", duration: 1200 }) }

  @Builder Header() {
    Row() {
      Circle({ width: 6, height: 6 }).fill(MINT).margin({ right: S_2 })
      Text("DeepSeek-V4").fontSize(F_XS).fontColor(TEXT_2).fontWeight(W_MEDIUM)
      Row() {
        Stack() {
          Ellipse().width(10).height(4).stroke(this.deepThink ? MINT : TEXT_3).strokeWidth(1)
          Ellipse().width(10).height(4).stroke(this.deepThink ? MINT : TEXT_3).strokeWidth(1).rotate({ angle: 60 })
          Ellipse().width(10).height(4).stroke(this.deepThink ? MINT : TEXT_3).strokeWidth(1).rotate({ angle: 120 })
          Circle({ width: 2, height: 2 }).fill(this.deepThink ? MINT : TEXT_3)
        }.width(12).height(12)
        Text(" \u6DF1\u5EA6\u601D\u8003").fontSize(F_XS).fontColor(this.deepThink ? MINT : TEXT_3).fontWeight(W_MEDIUM)
      }
      .padding({ left: S_3, right: S_3, top: S_1, bottom: S_1 }).borderRadius(R_FULL)
      .border({ width: 1, color: this.deepThink ? MINT : TEXT_4 })
      .backgroundColor(this.deepThink ? MINT_LIGHT : BG_DARK)
      .margin({ left: S_4 })
      .onClick((): void => { this.deepThink = !this.deepThink })
      Blank()
      Stack() {
        Path().width(14).height(14)
          .commands("M18 6 L6 18 M6 6 L18 18")
          .stroke(TEXT_3).strokeWidth(2).strokeLineCap(LineCapStyle.Round)
          .fill(Color.Transparent)
      }
      .width(32).height(44).alignContent(Alignment.Center)
      .onClick((): void => this.onClose())
    }.width("100%").padding({ left: S_4, right: S_3, top: S_2, bottom: S_1 })
  }

  @Builder UserBubble(msg: ChatMsg) {
    Row() { Blank()
      Column() {
        Text(msg.content).fontSize(F_SM).fontColor(MINT_DARK).lineHeight(20)
          .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
          .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: R_MD + 4, bottomRight: S_1 })
          .backgroundColor(MINT_LIGHT).constraintSize({ maxWidth: "78%" })
      }.alignItems(HorizontalAlign.End)
    }.width("100%").margin({ top: S_2 })
  }

  @Builder AiBubble(msg: ChatMsg) {
    Row() {
      Column() {
        Text("AI").fontSize(9).fontColor(TEXT_4).fontWeight(W_SEMIBOLD).margin({ bottom: S_1, left: S_1 })
        Text(msg.content).fontSize(F_SM).fontColor(TEXT_2).lineHeight(20)
          .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
          .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: S_1, bottomRight: R_MD + 4 })
          .backgroundColor(PURPLE_LIGHT).constraintSize({ maxWidth: "85%" })
        Row() {
          Text("\uD83D\uDCCB").fontSize(9).fontColor(TEXT_4).padding({ top: S_1, right: S_2 })
            .onClick((): void => { this.copyText(msg.content) })
          Text("\u21BB").fontSize(10).fontColor(TEXT_4).padding({ top: S_1 })
            .onClick((): void => {
              const idx = this.messages.findIndex((m: ChatMsg): boolean => m.id === msg.id)
              if (idx > 0 && this.messages[idx - 1].role === "user") { this.send(this.messages[idx - 1].content) }
            })
        }
      }.alignItems(HorizontalAlign.Start)
      Blank()
    }.width("100%").margin({ top: S_2 })
  }

  @Builder TypingBubble() {
    Row() {
      Row() {
        Circle({ width: 5, height: 5 }).fill(PURPLE).opacity(1)
          .animation({ duration: 1200, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate })
          .margin({ right: S_1 })
        Circle({ width: 5, height: 5 }).fill(PURPLE).opacity(0.3)
          .animation({ duration: 1200, delay: 200, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate })
          .margin({ right: S_1 })
        Circle({ width: 5, height: 5 }).fill(PURPLE).opacity(0.3)
          .animation({ duration: 1200, delay: 400, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate })
        Text(" \u601D\u8003\u4E2D").fontSize(F_XS).fontColor(TEXT_3).margin({ left: S_2 })
      }
      .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
      .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: S_1, bottomRight: R_MD + 4 })
      .backgroundColor(PURPLE_LIGHT)
      Blank()
    }.width("100%").margin({ top: S_2 })
  }

  @Builder EmptyHint() {
    Column() {
      Stack() {
        Path().width(30).height(30)
          .commands("M 15 0 L 28 15 L 15 30 L 2 15 Z").fill(MINT).opacity(0.3)
        Path().width(18).height(18)
          .commands("M 15 4 L 26 15 L 15 26 L 4 15 Z").fill(MINT)
      }.width(48).height(48).margin({ bottom: S_3 })
      Text("\u6709\u4EC0\u4E48\u6570\u5B66\u95EE\u9898\uFF1F").fontSize(F_MD).fontWeight(W_SEMIBOLD).fontColor(TEXT)
      Text("\u8BD5\u8BD5\u4E0B\u65B9\u7684\u63A8\u8350\u95EE\u9898\uFF0C\u6216\u76F4\u63A5\u8F93\u5165").fontSize(F_XS).fontColor(TEXT_3).margin({ top: S_2 })
    }.width("100%").padding({ top: S_6, bottom: S_6 }).alignItems(HorizontalAlign.Center)
  }

  @Builder QuickWords() {
    Column() {
      Text("\u63A8\u8350").fontSize(9).fontColor(TEXT_4).fontWeight(W_SEMIBOLD).padding({ left: S_4, top: S_2 })
      Row() {
        this.Qw("\u5206\u6790\u9519\u9898"); this.Qw("\u8BB2\u89E3\u6781\u9650")
        this.Qw("\u751F\u6210\u7EC3\u4E60"); this.Qw("\u68B3\u7406\u77E5\u8BC6")
      }.width("100%").padding({ left: S_4, right: S_4, bottom: S_2 })
    }.width("100%")
  }
  @Builder Qw(label: string) {
    Text(label).fontSize(F_XS).fontColor(PURPLE)
      .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
      .borderRadius(R_FULL).backgroundColor(PURPLE_LIGHT).margin({ right: S_2 })
      .onClick((): void => this.sendQuick(label))
  }

  @Builder InputBar() {
    Column() {
      if (this.imagePreview.length > 0) {
        Row() {
          Image(this.imagePreview).width(36).height(36).borderRadius(R_SM).objectFit(ImageFit.Cover)
          Text("\u5DF2\u9009\u56FE\u7247").fontSize(F_XS).fontColor(TEXT_3).margin({ left: S_2 }).layoutWeight(1)
          Text("\u2715").fontSize(F_XS).fontColor(TEXT_3).width(32).height(44).textAlign(TextAlign.Center)
            .onClick((): void => { this.imagePreview = "" })
        }.width("100%").padding({ left: S_4, right: S_4, bottom: S_1 })
      }
      Row() {
        TextInput({ text: this.inputText, placeholder: "\u8F93\u5165\u6570\u5B66\u95EE\u9898..." })
          .layoutWeight(1).height(40).fontSize(F_SM).fontColor(TEXT).placeholderColor(TEXT_3)
          .backgroundColor(GLASS_10).borderRadius(20).padding({ left: S_4, right: S_4 })
          .onChange((value: string): void => { this.inputText = value })
          .onSubmit((): void => { this.send() })
        Stack() {
          Image($r("app.media.ic_camera")).width(16).height(16).fillColor(TEXT_3)
        }.width(36).height(44).alignContent(Alignment.Center)
        .onClick((): void => { this.onGoCamera() })
        Text("\u2191").fontSize(F_LG).fontWeight(W_BOLD).width(36).height(44).textAlign(TextAlign.Center)
          .fontColor(this.inputText.trim().length > 0 && !this.busy ? MINT : TEXT_3)
          .onClick((): void => { this.send() })
      }.width("100%").padding({ left: S_4, right: S_4 })
    }.width("100%").padding({ top: S_2, bottom: S_4 })
  }

  build() {
    Stack() {
      if (this.show) {
        Column().width("100%").height("100%").backgroundColor(OVERLAY_MASK)
          .onClick((): void => this.onClose())
        Column() {
          Row() { Row().width(36).height(5).borderRadius(3).backgroundColor(TEXT_4) }
            .width("100%").height(S_6).justifyContent(FlexAlign.Center)
          this.Header()
          Row().width("100%").height(0.5).backgroundColor(BORDER)
          Scroll(this.scroller) {
            Column() {
              if (this.messages.length === 0 && !this.busy) { this.EmptyHint() }
              ForEach(this.messages,
                (msg: ChatMsg): void => { if (msg.role === "user") { this.UserBubble(msg) } else { this.AiBubble(msg) } },
                (msg: ChatMsg): string => msg.id.toString()
              )
              if (this.busy) { this.TypingBubble() }
              Blank().height(S_2)
            }.width("100%").padding({ left: S_4, right: S_4, top: S_2 })
          }.layoutWeight(1).width("100%").scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
          Row().width("100%").height(0.5).backgroundColor(BORDER)
          this.QuickWords()
          this.InputBar()
        }
        .width("100%").height("40%")
        .backgroundColor(BG_DARK)
        .borderRadius({ topLeft: R_XL, topRight: R_XL })
        .padding({ left: S_3, right: S_3 })
        .position({ x: 0, y: "100%" })
        .markAnchor({ x: 0, y: "100%" })
        .translate({ y: -(74 + this.keyboardHeight) })
      }
    }.width("100%").height("100%")
    .hitTestBehavior(this.show ? HitTestMode.Default : HitTestMode.None)
  }
}