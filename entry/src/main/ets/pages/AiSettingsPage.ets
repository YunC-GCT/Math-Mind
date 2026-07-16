// ============================================================================
//  AiSettingsPage.ets — 大模型设置（精简版）
//  端点: DeepSeek 官方 + 自定义
//  模型: DeepSeek-V3 默认 + 自定义
// ============================================================================

import {
  MINT, BG_DARK, BG_CARD, TEXT, TEXT_3, TEXT_4, BORDER,
  S_2, S_4, R_MD, R_LG,
  F_XS, F_SM, F_BASE, W_SEMIBOLD,
} from "common"
import { LlmConfig, LlmClient } from "common"
import { promptAction, KeyboardAvoidMode } from "@kit.ArkUI"
import { router } from "@kit.ArkUI"

const DS_ENDPOINT = "https://api.deepseek.com/chat/completions"
const DEFAULT_MODEL = "deepseek-chat"

@Entry
@Component
struct AiSettingsPage {
  @StorageProp("statusBarHeight") statusBarH: number = 0
  @State apiKey: string = ""
  @State useCustomEP: boolean = false
  @State customEP: string = ""
  @State useCustomMD: boolean = false
  @State customMD: string = ""
  @State configured: boolean = false
  @State testing: boolean = false
  @State statusText: string = "未配置"
  @State tempText: string = "0.1"
  @State maxTText: string = "256"
  @State toText: string = "5000"
  @State temperature: number = 0.1
  @State maxTokens: number = 256
  @State timeoutMs: number = 5000

  aboutToAppear(): void { try { this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.OFFSET) } catch (e) {}; this.loadConfig() }
  aboutToDisappear(): void { try { this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE) } catch (e) {} }

  private ep(): string { return this.useCustomEP ? this.customEP : DS_ENDPOINT }
  private md(): string { return this.useCustomMD ? this.customMD : DEFAULT_MODEL }

  async loadConfig(): Promise<void> {
    const c = LlmConfig.getInstance()
    const key = await c.getApiKey()
    if (key !== null && key.length > 0) { this.apiKey = key; this.configured = true; this.statusText = "已配置" }
    // 自定义端点/模型留空，由用户手动填写
    this.temperature = c.getTemperature(); this.maxTokens = c.getMaxTokens(); this.timeoutMs = c.getTimeoutMs()
    this.tempText = this.temperature.toString(); this.maxTText = this.maxTokens.toString(); this.toText = this.timeoutMs.toString()
  }

  async handleSave(): Promise<void> {
    const tp = parseFloat(this.tempText); const mt = parseInt(this.maxTText); const to = parseInt(this.toText)
    if (isNaN(tp) || isNaN(mt) || isNaN(to)) { promptAction.showToast({ message: "参数必须为数字", duration: 2000 }); return }
    try {
      await LlmConfig.getInstance().saveAll(this.ep(), this.md(), tp, mt, to)
      if (this.apiKey.trim().length > 0) { await LlmConfig.getInstance().setApiKey(this.apiKey.trim()); this.configured = true; this.statusText = "已保存" }
      promptAction.showToast({ message: "配置已保存", duration: 1500 }); await this.loadConfig()
    } catch (e) { promptAction.showToast({ message: "保存失败", duration: 2000 }) }
  }

  async handleReset(): Promise<void> {
    try { await LlmConfig.getInstance().resetDefaults(); await LlmConfig.getInstance().clearApiKey()
      this.apiKey = ""; this.useCustomEP = false; this.customEP = ""; this.useCustomMD = false; this.customMD = ""
      this.configured = false; this.statusText = "已恢复默认"
      promptAction.showToast({ message: "已恢复默认", duration: 1500 })
    } catch (e) { promptAction.showToast({ message: "恢复失败", duration: 1500 }) }
  }

  async handleTest(): Promise<void> {
    if (this.apiKey.trim().length === 0) { promptAction.showToast({ message: "请先输入 API Key", duration: 1500 }); return }
    await LlmConfig.getInstance().setApiKey(this.apiKey.trim())
    const tp = parseFloat(this.tempText); const mt = parseInt(this.maxTText); const to = parseInt(this.toText)
    await LlmConfig.getInstance().saveAll(this.ep(), this.md(), this.temperature, this.maxTokens, this.timeoutMs)
    this.testing = true
    try { await new LlmClient().call([{ role: "system", content: "Reply OK." }, { role: "user", content: "OK" }])
      promptAction.showToast({ message: "连接成功", duration: 1500 }); this.statusText = "已配置 · 连接正常"
    } catch (e) { promptAction.showToast({ message: "连接失败", duration: 2500 }); this.statusText = "已配置 · 连接失败" }
    finally { this.testing = false }
  }

  build() {
    Column() {
      Row() {
        Text("← 返回").fontSize(F_SM).fontColor(MINT).onClick((): void => { router.back() })
        Blank(); Text("模型配置").fontSize(F_MD).fontWeight(W_SEMIBOLD).fontColor(TEXT); Blank(); Row().width(60)
      }.width("100%").padding({ left: S_2, right: S_2, top: S_3, bottom: S_3 }).margin({ top: this.statusBarH })
      Row().width("100%").height(0.5).backgroundColor(BORDER)
      Scroll() {
        Column() {
          // ---- 连接状态 ----
          Row() {
            Column() {
              Text("连接状态").fontSize(F_XS).fontColor(TEXT_3).margin({ bottom: 4 })
              Text(this.statusText).fontSize(F_BASE).fontWeight(W_SEMIBOLD).fontColor(this.configured ? MINT : TEXT_4)
            }.alignItems(HorizontalAlign.Start)
            Blank()
            Circle({ width: 10, height: 10 }).fill(this.configured ? MINT : TEXT_4)
          }.width("100%").padding(S_4).borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: S_2, right: S_2 })

          // ---- 服务端点 ----
          this.Section("服务端点", "DeepSeek 官方或自定义")
          Column() {
            Row() {
              Radio({ value: "ep_default", group: "ep" }).checked(!this.useCustomEP)
                .onChange((v: boolean): void => { if (v) { this.useCustomEP = false } })
              Column() {
                Text("DeepSeek 官方").fontSize(F_SM).fontColor(TEXT)
                Text(DS_ENDPOINT).fontSize(10).fontColor(TEXT_4).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              }.alignItems(HorizontalAlign.Start).margin({ left: 8 }).layoutWeight(1)
            }.width("100%").padding({ left: 4, right: 4, top: 6, bottom: 6 })

            Row() {
              Radio({ value: "ep_custom", group: "ep" }).checked(this.useCustomEP)
                .onChange((v: boolean): void => { if (v) { this.useCustomEP = true } })
              TextInput({ text: this.customEP, placeholder: "自定义端点地址..." }).layoutWeight(1).height(44)
                .fontSize(F_XS).fontColor(TEXT).placeholderColor(TEXT_4)
                .backgroundColor("#0AFFFFFF").borderRadius(R_MD)
                .onChange((v: string): void => { this.customEP = v })
            }.width("100%").padding({ left: 4, right: 8, top: 6, bottom: 10 })
          }.width("100%").borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: S_2, right: S_2 })

          // ---- 模型 ----
          this.Section("模型", "默认 DeepSeek-V3 或自定义")
          Column() {
            Row() {
              Radio({ value: "md_default", group: "md" }).checked(!this.useCustomMD)
                .onChange((v: boolean): void => { if (v) { this.useCustomMD = false } })
              Column() {
                Text("DeepSeek-V3").fontSize(F_SM).fontColor(TEXT)
                Text(DEFAULT_MODEL + " · 64K").fontSize(9).fontColor(TEXT_4).margin({ top: 1 })
              }.alignItems(HorizontalAlign.Start).margin({ left: 8 }).layoutWeight(1)
            }.width("100%").padding({ left: 4, right: 4, top: 6, bottom: 6 })

            Row() {
              Radio({ value: "md_custom", group: "md" }).checked(this.useCustomMD)
                .onChange((v: boolean): void => { if (v) { this.useCustomMD = true } })
              TextInput({ text: this.customMD, placeholder: "自定义模型 ID..." }).layoutWeight(1).height(44)
                .fontSize(F_XS).fontColor(TEXT).placeholderColor(TEXT_4)
                .backgroundColor("#0AFFFFFF").borderRadius(R_MD)
                .onChange((v: string): void => { this.customMD = v })
            }.width("100%").padding({ left: 4, right: 8, top: 6, bottom: 10 })
          }.width("100%").borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: S_2, right: S_2 })

          // ---- API Key ----
          this.Section("API Key", "从 DeepSeek 获取的密钥")
          Row() {
            TextInput({ text: this.apiKey, placeholder: "sk-..." }).type(InputType.Password)
              .layoutWeight(1).height(42).fontSize(F_SM).fontColor(TEXT).placeholderColor(TEXT_4).backgroundColor("transparent")
              .onChange((v: string): void => { this.apiKey = v })
            Button(this.testing ? "..." : "测试").fontSize(F_XS).fontColor(BG_DARK)
              .height(44).borderRadius(R_MD).backgroundColor(MINT).enabled(!this.testing).margin({ left: 8 })
              .onClick((): void => { this.handleTest() })
          }.width("100%").padding({ left: 16, right: 16, top: 8, bottom: 8 }).borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: S_2, right: S_2 })

          // ---- 操作按钮 ----
          Row() {
            Button("恢复默认").fontSize(F_SM).fontColor(TEXT_3).height(44).borderRadius(R_MD)
              .backgroundColor("#1AFFFFFF").layoutWeight(1)
              .onClick((): void => { this.handleReset() })
            Button("保存配置").fontSize(F_SM).fontColor(BG_DARK).height(44).borderRadius(R_MD)
              .backgroundColor(MINT).layoutWeight(1).margin({ left: 12 })
              .onClick((): void => { this.handleSave() })
          }.width("100%").padding({ left: S_2, right: S_2, top: 20 })

          Blank().height(40)
        }.width("100%")
      }.layoutWeight(1).width("100%")
    }.width("100%").height("100%").backgroundColor(BG_DARK)
  }

  @Builder Section(title: string, desc: string) {
    Column() {
      Text(title).fontSize(F_SM).fontWeight(W_SEMIBOLD).fontColor(TEXT)
      if (desc.length > 0) { Text(desc).fontSize(F_XS).fontColor(TEXT_4).margin({ top: 2 }) }
    }.alignItems(HorizontalAlign.Start).width("100%").padding({ left: 20, right: S_2, top: 20, bottom: 8 })
  }

