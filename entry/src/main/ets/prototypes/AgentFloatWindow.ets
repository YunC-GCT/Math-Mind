/**
 * MathMind AI 对话浮窗
 * W3 重制: 参照 swiftui-to-arkiu Sheet 规范 — 简洁/原生拖拽条/顶部圆角/现代化气泡
 */

import {
  MINT, MINT_DARK, MINT_LIGHT,
  PURPLE, PURPLE_LIGHT,
  BG_DARK, BG_CARD,
  TEXT, TEXT_2, TEXT_3, TEXT_4, BORDER,
  S_1, S_2, S_3, S_4, S_5, S_6,
  R_SM, R_MD, R_LG, R_XL, R_FULL,
  F_XS, F_SM, F_BASE, F_MD, F_LG, F_XL,
  W_MEDIUM, W_SEMIBOLD, W_BOLD,
  GLASS_10, OVERLAY_MASK,
} from "common"
import { LlmClient, LlmConfig } from "common"
import { promptAction } from "@kit.ArkUI"
import window from "@ohos.window"

interface ChatMsg {
  id: number
  role: "user" | "ai"
  content: string
  ts: number
}

function nowId(): number {
  return Date.now() * 1000 + Math.floor(Math.random() * 1000)
}

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
  private mainWindow: window.Window | null = null

  aboutToAppear(): void {
    if (AppStorage.get<boolean>("shownGreeting") !== true) {
      this.messages = [{
        id: 1, role: "ai",
        content: "👋 你好，我是 MathMind AI 助手\n\n点击快捷按钮开始，或直接输入问题",
        ts: Date.now(),
      }]
      AppStorage.setOrCreate<boolean>("shownGreeting", true)
    }
    try {
      const ctx = this.getUIContext().getHostContext()
      if (ctx) {
        window.getLastWindow(ctx).then((win: window.Window): void => {
          this.mainWindow = win
          win.on("keyboardHeightChange", (data: number): void => {
            try { this.keyboardHeight = this.getUIContext().px2vp(data) } catch (e) {}
          })
        }).catch((_err: Error): void => {})
      }
    } catch (e) {}
  }

  aboutToDisappear(): void {
    if (this.mainWindow) { this.mainWindow.off("keyboardHeightChange") }
  }

  onPendingImageChange(): void {
    if (this.pendingImageUri.length > 0) { this.imagePreview = this.pendingImageUri }
  }

  // ========== 逻辑 ==========

  private send = (): void => {
    const text = this.inputText.trim()
    if (!text && !this.imagePreview) { return }
    if (this.busy) {
      promptAction.showToast({ message: "AI 正在回复中...", duration: 1200 })
      return
    }
    const content = text || "分享了一张照片"
    this.messages = [...this.messages, { id: nowId(), role: "user", content, ts: Date.now() }]
    this.inputText = ""
    this.imagePreview = ""
    this.realReply(content)
  }

  private sendQuick = (prompt: string): void => {
    if (this.busy) {
      promptAction.showToast({ message: "AI 正在回复中...", duration: 1200 })
      return
    }
    let content = prompt
    if (this.inputText.trim()) { content += "\n" + this.inputText.trim() }
    if (this.imagePreview) { content += "\n[图片]" }
    this.messages = [...this.messages, { id: nowId(), role: "user", content, ts: Date.now() }]
    this.inputText = ""
    this.imagePreview = ""
    this.realReply(content)
  }

  private realReply = async (userContent: string): Promise<void> => {
    this.busy = true
    try {
      const configured = await LlmConfig.getInstance().isConfigured()
      if (!configured) {
        this.addAiMsg("⚠️ 请先在「我的 → 模型」中配置 API Key")
        this.busy = false
        return
      }
      const client = new LlmClient()
      const systemPrompt = this.deepThink
        ? "你是 MathMind AI 深度思考助手。请逐步推理、深入分析，展示完整思考过程，使用 LaTeX 公式。"
        : "你是 MathMind AI 助手，用简洁清晰的中文回答，适当使用 LaTeX 公式。"
      const reply = await client.call([
        { role: "system", content: systemPrompt },
        { role: "user", content: userContent },
      ])
      this.addAiMsg(reply)
    } catch (e) {
      const err = (e as Error).message ?? ""
      if (err.indexOf("NO_API_KEY") >= 0) {
        this.addAiMsg("⚠️ 请先配置 API Key")
      } else if (err.indexOf("NETWORK_ERROR") >= 0) {
        this.addAiMsg("⚠️ 网络连接失败，请检查网络后重试")
      } else {
        this.addAiMsg("⚠️ AI 回复异常")
      }
    } finally {
      this.busy = false
    }
  }

  private addAiMsg = (content: string): void => {
    this.messages = [...this.messages, { id: nowId(), role: "ai", content, ts: Date.now() }]
  }

  // ========== UI ==========

  @Builder
  DragBar() {
    Row().width(36).height(5).borderRadius(3).backgroundColor(TEXT_4)
  }

  @Builder
  Header() {
    Row() {
      Text("MathMind AI").fontSize(F_BASE).fontWeight(W_SEMIBOLD).fontColor(TEXT)
      Blank()
      // 深度思考开关
      Text(this.deepThink ? "🧠 深度" : "🧠")
        .fontSize(F_XS)
        .fontColor(this.deepThink ? MINT : TEXT_3)
        .padding({ left: S_3, right: S_3, top: S_3, bottom: S_3 })
        .borderRadius(R_FULL)
        .backgroundColor(this.deepThink ? MINT_LIGHT : GLASS_10)
        .margin({ right: S_2 })
        .onClick((): void => { this.deepThink = !this.deepThink })
      // 关闭
      Stack() {
        Text("✕").fontSize(F_MD).fontColor(TEXT_3)
      }
      .width(36).height(44).borderRadius(22)
      .alignContent(Alignment.Center)
      .onClick((): void => this.onClose())
    }
    .width("100%").padding({ left: S_4, right: S_3, top: S_2, bottom: S_2 })
  }

  @Builder
  QuickBar() {
    Row() {
      this.SugBtn("分析题目", "帮我分析这道题")
      this.SugBtn("总结知识", "总结这个知识点")
      this.SugBtn("出练习题", "出几道练习题")
      this.SugBtn("学习路径", "推荐学习路径")
    }
    .width("100%")
    .padding({ left: S_3, right: S_3, top: S_1, bottom: S_2 })
  }

  @Builder
  SugBtn(label: string, prompt: string) {
    Text(label)
      .fontSize(F_XS).fontColor(PURPLE)
      .padding({ left: S_3, right: S_3, top: S_3, bottom: S_3 })
      .borderRadius(R_SM)
      .backgroundColor(PURPLE_LIGHT)
      .margin({ right: S_2 })
      .onClick((): void => this.sendQuick(prompt))
  }

  @Builder
  UserBubble(msg: ChatMsg) {
    Row() {
      Blank()
      Text(msg.content)
        .fontSize(F_SM).fontColor(MINT).lineHeight(20)
        .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
        .borderRadius(R_MD + 4)
        .backgroundColor(MINT_LIGHT)
        .constraintSize({ maxWidth: "78%" })
    }
    .width("100%").margin({ top: S_2 })
  }

  @Builder
  AiBubble(msg: ChatMsg) {
    Row() {
      Text(msg.content)
        .fontSize(F_SM).fontColor(TEXT_2).lineHeight(20)
        .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
        .borderRadius(R_MD + 4)
        .backgroundColor(PURPLE_LIGHT)
        .constraintSize({ maxWidth: "85%" })
      Blank()
    }
    .width("100%").margin({ top: S_2 })
  }

  @Builder
  TypingBubble() {
    Row() {
      Row() {
        LoadingProgress().width(12).height(12).color(PURPLE)
        Text(" 思考中...").fontSize(F_XS).fontColor(TEXT_3)
      }
      .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
      .borderRadius(R_MD + 4)
      .backgroundColor(PURPLE_LIGHT)
      Blank()
    }
    .width("100%").margin({ top: S_2 })
  }

  @Builder
  EmptyHint() {
    Column() {
      Text("👋").fontSize(36).margin({ bottom: S_2 })
      Text("MathMind AI").fontSize(F_BASE).fontWeight(W_SEMIBOLD).fontColor(TEXT)
      Text("点击快捷按钮或输入问题开始对话").fontSize(F_XS).fontColor(TEXT_3).margin({ top: S_1 })
    }
    .width("100%").padding({ top: S_6, bottom: S_6 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  InputBar() {
    Column() {
      // 图片预览
      if (this.imagePreview.length > 0) {
        Row() {
          Image(this.imagePreview).width(44).height(44).borderRadius(R_SM).objectFit(ImageFit.Cover)
          Text("已选图片").fontSize(F_XS).fontColor(TEXT_3).margin({ left: S_2 }).layoutWeight(1)
          Text("✕").fontSize(F_XS).fontColor(TEXT_3)
            .width(36).height(44).borderRadius(22).textAlign(TextAlign.Center)
            .backgroundColor(GLASS_10)
            .onClick((): void => { this.imagePreview = "" })
        }
        .width("100%").padding({ left: S_4, right: S_4, bottom: S_1 })
      }
      // 输入行
      Row() {
        TextInput({ text: this.inputText, placeholder: "输入问题..." })
          .layoutWeight(1).height(44)
          .fontSize(F_SM).fontColor(TEXT).placeholderColor(TEXT_3)
          .backgroundColor(GLASS_10).borderRadius(22)
          .padding({ left: S_4, right: S_2 })
          .onChange((value: string): void => { this.inputText = value })
          .onSubmit((): void => { this.send() })

        // 拍照
        Stack() {
          Image($r("app.media.ic_camera")).width(16).height(16).fillColor(TEXT_3)
        }
        .width(40).height(40).borderRadius(20)
        .backgroundColor(GLASS_10)
        .alignContent(Alignment.Center)
        .margin({ left: S_2 })
        .onClick((): void => { this.onGoCamera() })

        // 发送
        Stack() {
          Text("➤").fontSize(16).fontWeight(W_BOLD)
            .fontColor(this.inputText.trim().length > 0 && !this.busy ? BG_DARK : TEXT_3)
        }
        .width(40).height(40).borderRadius(20)
        .backgroundColor(this.inputText.trim().length > 0 && !this.busy ? MINT : GLASS_10)
        .alignContent(Alignment.Center)
        .margin({ left: S_1 })
        .onClick((): void => { this.send() })
      }
      .width("100%").padding({ left: S_4, right: S_4 })
    }
    .width("100%").padding({ top: S_2, bottom: S_4 })
  }

  build() {
    Stack() {
      if (this.show) {
        // 遮罩
        Column()
          .width("100%").height("100%")
          .backgroundColor(OVERLAY_MASK)
          .onClick((): void => this.onClose())

        // 浮窗主体
        Column() {
          // 拖拽条
          Row() {
            this.DragBar()
          }
          .width("100%").height(S_6).justifyContent(FlexAlign.Center)

          // Header
          this.Header()

          // 快捷按钮
          this.QuickBar()

          // 分隔
          Row().width("100%").height(0.5).backgroundColor(BORDER)

          // 消息区
          Scroll() {
            Column() {
              if (this.messages.length === 0 && !this.busy) { this.EmptyHint() }
              ForEach(this.messages,
                (msg: ChatMsg): void => {
                  if (msg.role === "user") { this.UserBubble(msg) }
                  else { this.AiBubble(msg) }
                },
                (msg: ChatMsg): string => msg.id.toString()
              )
              if (this.busy) { this.TypingBubble() }
              Blank().height(S_2)
            }
            .width("100%").padding({ left: S_4, right: S_4, top: S_2 })
          }
          .layoutWeight(1).width("100%")
          .scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)

          // 分隔
          Row().width("100%").height(0.5).backgroundColor(BORDER)

          // 输入栏
          this.InputBar()
        }
        .width("100%").height("42%")
        .borderRadius({ topLeft: R_XL, topRight: R_XL })
        .backgroundColor(BG_DARK)
        .position({ x: 0, y: "100%" })
        .markAnchor({ x: 0, y: "100%" })
        .translate({ y: -(74 + this.keyboardHeight) })
        .margin({ left: S_3, right: S_3 })
      }
    }
    .width("100%").height("100%")
    .hitTestBehavior(this.show ? HitTestMode.Default : HitTestMode.None)
  }
}
