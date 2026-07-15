/**
 * MathMind AI · Variant B — 沉浸对话型
 * P0/P1 修复: 模型状态指示 · typing 三点动画 · 气泡三重区分 · 推荐分组
 */

import {
  MINT, MINT_LIGHT, MINT_DARK,
  PURPLE, PURPLE_LIGHT,
  BG_DARK,
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

interface ChatMsg { id: number; role: "user" | "ai"; content: string; ts: number }
function nowId(): number { return Date.now() * 1000 + Math.floor(Math.random() * 1000) }

@Component
export struct AgentFloatWindow {
  @Prop show: boolean = false
  onClose: () => void = (): void => {}
  onGoCamera: () => void = (): void => {}
  @Prop @Watch("onPendingImageChange") pendingImageUri: string = ""

  @State messages: ChatMsg[] = []
  @State inputText: string = ""
  @State busy: boolean = false
  @State deepThink: boolean = false
  @State imagePreview: string = ""
  @State keyboardHeight: number = 0
  // typing dots animation tick
  @State typingTick: number = 0
  private mainWindow: window.Window | null = null
  private typingTimer: number = -1

  aboutToAppear(): void {
    if (AppStorage.get<boolean>("shownGreeting") !== true) {
      this.messages = [{ id: 1, role: "ai",
        content: "你好，我是 MathMind AI。\n\n可以帮你分析错题、讲解知识点、生成练习题。试着问我吧 👇",
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
  aboutToDisappear(): void {
    if (this.mainWindow) { this.mainWindow.off("keyboardHeightChange") }
    if (this.typingTimer !== -1) { clearInterval(this.typingTimer); this.typingTimer = -1 }
  }
  onPendingImageChange(): void { if (this.pendingImageUri.length > 0) { this.imagePreview = this.pendingImageUri } }

  // ========== typing 三点动画控制 ==========
  private startTyping = (): void => {
    this.typingTick = 0
    this.typingTimer = setInterval((): void => {
      this.typingTick = (this.typingTick + 1) % 3
    }, 500)
  }
  private stopTyping = (): void => {
    if (this.typingTimer !== -1) { clearInterval(this.typingTimer); this.typingTimer = -1 }
    this.typingTick = 0
  }

  // ========== 逻辑 ==========
  private send = (text?: string): void => {
    const msg = (text ?? this.inputText).trim()
    if (!msg && !this.imagePreview) { return }
    if (this.busy) { promptAction.showToast({ message: "AI 正在回复中...", duration: 1200 }); return }
    this.messages = [...this.messages, { id: nowId(), role: "user", content: msg || "[图片]", ts: Date.now() }]
    this.inputText = ""; this.imagePreview = ""
    this.realReply(msg)
  }
  private sendQuick = (prompt: string): void => { this.send(prompt) }
  private realReply = async (userContent: string): Promise<void> => {
    this.busy = true; this.startTyping()
    try {
      if (!(await LlmConfig.getInstance().isConfigured())) {
        this.addAiMsg("请先在「我的 → 大模型设置」中配置 API Key"); this.busy = false; this.stopTyping(); return
      }
      const systemPrompt = this.deepThink
        ? "你是 MathMind AI 深度思考助手。逐步推理，展示完整思考过程，使用 LaTeX。"
        : "你是 MathMind AI 助手，简洁中文回答，适当使用 LaTeX。"
      const reply = await new LlmClient().call([
        { role: "system", content: systemPrompt }, { role: "user", content: userContent },
      ])
      this.addAiMsg(reply)
    } catch (e) {
      const err = (e as Error).message ?? ""
      if (err.indexOf("NO_API_KEY") >= 0) { this.addAiMsg("请先配置 API Key") }
      else if (err.indexOf("NETWORK_ERROR") >= 0) { this.addAiMsg("网络连接失败") }
      else { this.addAiMsg("AI 回复异常") }
    } finally { this.busy = false; this.stopTyping() }
  }
  private addAiMsg = (content: string): void => {
    this.messages = [...this.messages, { id: nowId(), role: "ai", content, ts: Date.now() }]
  }

  // ========== P0-2: 头部 · 模型名 + 在线状态 ==========
  @Builder Header() {
    Row() {
      // 在线状态绿点 + 模型名
      Circle({ width: 6, height: 6 }).fill(MINT).margin({ right: S_2 })
      Text("DeepSeek-V3").fontSize(F_XS).fontColor(TEXT_2).fontWeight(W_MEDIUM)
      // 花瓣形思考开关: ◌·◌
      Row() {
        Circle({ width: 10, height: 14 }).fill(this.deepThink ? MINT : '#00000000').stroke(this.deepThink ? MINT : TEXT_4).strokeWidth(1.5)
        Circle({ width: 5, height: 5 }).fill(this.deepThink ? MINT_DARK : TEXT_4).margin({ left: 2, right: 2 })
        Circle({ width: 10, height: 14 }).fill(this.deepThink ? MINT : '#00000000').stroke(this.deepThink ? MINT : TEXT_4).strokeWidth(1.5)
      }
      .width(52).height(44).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center).margin({ left: S_4 })
      .onClick((): void => { this.deepThink = !this.deepThink })
      Blank()
      Stack() { Text("✕").fontSize(F_BASE).fontColor(TEXT_3) }
        .width(32).height(44).alignContent(Alignment.Center)
        .onClick((): void => this.onClose())
    }.width("100%").padding({ left: S_4, right: S_3, top: S_2, bottom: S_1 })
  }

  // ========== P1-6: 气泡三重区分(对齐/颜色/圆角) ==========
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
      }.alignItems(HorizontalAlign.Start)
      Blank()
    }.width("100%").margin({ top: S_2 })
  }

  // ========== P0-3: typing 三点跳动 ==========
  @Builder TypingBubble() {
    Row() {
      Row() {
        // 三点跳动动画
        Text("●").fontSize(10).fontColor(this.typingTick === 0 ? PURPLE : TEXT_4).margin({ right: S_1 })
        Text("●").fontSize(10).fontColor(this.typingTick === 1 ? PURPLE : TEXT_4).margin({ right: S_1 })
        Text("●").fontSize(10).fontColor(this.typingTick === 2 ? PURPLE : TEXT_4)
        Text(" 思考中").fontSize(F_XS).fontColor(TEXT_3).margin({ left: S_2 })
      }
      .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
      .borderRadius({ topLeft: R_MD + 4, topRight: R_MD + 4, bottomLeft: S_1, bottomRight: R_MD + 4 })
      .backgroundColor(PURPLE_LIGHT)
      Blank()
    }.width("100%").margin({ top: S_2 })
  }

  @Builder EmptyHint() {
    Column() {
      // P0-1: 空状态用几何结晶 logo（文字代替 SVG）
      Text("✦").fontSize(48).fontColor(MINT).margin({ bottom: S_3 })
      Text("有什么数学问题？").fontSize(F_MD).fontWeight(W_SEMIBOLD).fontColor(TEXT)
      Text("试试下方的推荐问题，或直接输入").fontSize(F_XS).fontColor(TEXT_3).margin({ top: S_2 })
    }.width("100%").padding({ top: S_6, bottom: S_6 }).alignItems(HorizontalAlign.Center)
  }

  // ========== P1-4: 推荐问题分组 ==========
  @Builder QuickWords() {
    Column() {
      Text("推荐").fontSize(9).fontColor(TEXT_4).fontWeight(W_SEMIBOLD).padding({ left: S_4, top: S_2 })
      Row() {
        this.Qw("分析错题")
        this.Qw("讲解极限")
        this.Qw("生成练习")
        this.Qw("梳理知识")
      }.width("100%").padding({ left: S_4, right: S_4, bottom: S_2 })
    }.width("100%")
  }
  @Builder Qw(label: string) {
    Text(label).fontSize(F_XS).fontColor(PURPLE)
      .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
      .borderRadius(R_FULL).backgroundColor(PURPLE_LIGHT).margin({ right: S_2 })
      .onClick((): void => this.sendQuick(label))
  }

  // ========== 单行输入 ==========
  @Builder InputBar() {
    Column() {
      if (this.imagePreview.length > 0) {
        Row() {
          Image(this.imagePreview).width(36).height(36).borderRadius(R_SM).objectFit(ImageFit.Cover)
          Text("已选图片").fontSize(F_XS).fontColor(TEXT_3).margin({ left: S_2 }).layoutWeight(1)
          Text("✕").fontSize(F_XS).fontColor(TEXT_3).width(32).height(44).textAlign(TextAlign.Center)
            .onClick((): void => { this.imagePreview = "" })
        }.width("100%").padding({ left: S_4, right: S_4, bottom: S_1 })
      }
      Row() {
        TextInput({ text: this.inputText, placeholder: "输入数学问题..." })
          .layoutWeight(1).height(40).fontSize(F_SM).fontColor(TEXT).placeholderColor(TEXT_3)
          .backgroundColor(GLASS_10).borderRadius(20).padding({ left: S_4, right: S_4 })
          .onChange((value: string): void => { this.inputText = value })
          .onSubmit((): void => { this.send() })
        // 拍照 (P1-5: 用圆形图标代替 emoji)
        Stack() {
          Image($r("app.media.ic_camera")).width(16).height(16).fillColor(TEXT_3)
        }
        .width(36).height(44).alignContent(Alignment.Center)
        .onClick((): void => { this.onGoCamera() })
        // 发送
        Text("↑").fontSize(F_LG).fontWeight(W_BOLD).width(36).height(44).textAlign(TextAlign.Center)
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
          Scroll() {
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
        .width("100%").height("44%")
        .borderRadius({ topLeft: R_XL, topRight: R_XL }).backgroundColor(BG_DARK)
        .width('100%').padding({ left: S_3, right: S_3 }).position({ x: 0, y: '100%' }).markAnchor({ x: 0, y: '100%' }).translate({ y: -(74 + this.keyboardHeight) })
        .translate({ y: -this.keyboardHeight })
      }
    }.width("100%").height("100%")
    .hitTestBehavior(this.show ? HitTestMode.Default : HitTestMode.None)
  }
}
