// MathMind - 模型配置页
// W3 重构: StatusCard/SectionHeader/ParamRow 提取, build() 嵌套 6→2

import {
  MINT, MINT_DARK, PURPLE, PURPLE_LIGHT,
  BG_DARK, BG_CARD, TEXT, TEXT_2, TEXT_3, TEXT_4, BORDER,
  S_2, R_MD, R_LG, R_FULL,
  F_XS, F_SM, F_BASE, F_MD, W_SEMIBOLD, GLASS_8,
} from "common"
import { LlmConfig, LlmClient } from "common"
import { promptAction, KeyboardAvoidMode } from "@kit.ArkUI"
import { router } from "@kit.ArkUI"
import { StatusCard } from "../molecules/StatusCard"
import { SectionHeader } from "../atoms/SectionHeader"
import { ParamRow } from "../atoms/ParamRow"`nimport { SettingsActionBar } from "../atoms/SettingsActionBar"

const EP_PRESETS: string[] = [
  "https://api.siliconflow.cn/v1/chat/completions",
  "https://api.deepseek.com/chat/completions",
]
const EP_LABELS: string[] = ["硅基流动", "DeepSeek 官方"]

interface ModelPreset { label: string; value: string; ctx?: string; price?: string }
const SF_MODELS: ModelPreset[] = [
  { label: "DeepSeek-V3", value: "deepseek-ai/DeepSeek-V3" },
  { label: "DeepSeek-R1", value: "deepseek-ai/DeepSeek-R1" },
]
const DS_MODELS: ModelPreset[] = [
  { label: "DeepSeek-V4-Flash", value: "deepseek-v4-flash" },
  { label: "DeepSeek-V4-Pro", value: "deepseek-v4-pro" },
]

// ========== 端点选择器 ==========
@Component
struct EndpointPicker {
  @Prop epIdx: number = 0
  @Prop useCustom: boolean = false
  @Link customText: string
  onSelect?: (idx: number) => void
  onCustom?: () => void

  build() {
    Column() {
      ForEach(EP_PRESETS,
        (ep: string, i: number): void => {
          Row() {
            Radio({ value: "ep" + i, group: "ep" })
              .checked(!this.useCustom && this.epIdx === i)
              .onChange((v: boolean): void => { if (v && this.onSelect) { this.onSelect(i) } })
            Column() {
              Text(EP_LABELS[i]).fontSize(F_SM).fontColor(TEXT)
              Text(ep).fontSize(10).fontColor(TEXT_4).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            }.alignItems(HorizontalAlign.Start).margin({ left: 8 }).layoutWeight(1)
          }.width("100%").padding({ left: 4, right: 4, top: 6, bottom: 6 })
        },
        (_ep: string, i: number): string => i.toString()
      )
      Row() {
        Radio({ value: "epC", group: "ep" })
          .checked(this.useCustom).onChange((v: boolean): void => { if (v && this.onCustom) { this.onCustom() } })
        Text("自定义").fontSize(F_SM).fontColor(TEXT_3).margin({ left: 8 }).width(50)
        TextInput({ text: this.customText, placeholder: "https://..." })
          .layoutWeight(1).height(44).fontSize(F_XS).fontColor(TEXT).placeholderColor(TEXT_4)
          .backgroundColor(GLASS_8).borderRadius(R_MD)
          .onChange((v: string): void => { this.customText = v })
      }.width("100%").padding({ left: 4, right: 8, top: 6, bottom: 10 })
    }.width("100%").borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: S_2, right: S_2 })
  }
}

// ========== 模型选择器 ==========
@Component
struct ModelPicker {
  @Prop presets: ModelPreset[] = SF_MODELS
  @Prop mdlIdx: number = 0
  @Prop useCustom: boolean = false
  @Link customText: string
  onSelect?: (idx: number) => void
  onCustom?: () => void

  build() {
    Column() {
      ForEach(this.presets,
        (mp: ModelPreset, i: number): void => {
          Row() {
            Radio({ value: "md" + i, group: "md" })
              .checked(!this.useCustom && this.mdlIdx === i)
              .onChange((v: boolean): void => { if (v && this.onSelect) { this.onSelect(i) } })
            Column() {
              Text(mp.label).fontSize(F_SM).fontColor(TEXT)
              if (mp.ctx) { Text((mp.ctx ?? '') + ' · ' + (mp.price ?? '')).fontSize(9).fontColor(TEXT_4).margin({ top: 1 }) }
            }.alignItems(HorizontalAlign.Start).margin({ left: 8 }).layoutWeight(1)
          }.width("100%").padding({ left: 4, right: 4, top: 6, bottom: 6 })
        },
        (mp: ModelPreset, i: number): string => i.toString()
      )
      Row() {
        Radio({ value: "mdC", group: "md" })
          .checked(this.useCustom).onChange((v: boolean): void => { if (v && this.onCustom) { this.onCustom() } })
        Text("自定义").fontSize(F_SM).fontColor(TEXT_3).margin({ left: 8 }).width(50)
        TextInput({ text: this.customText, placeholder: "model-id" })
          .layoutWeight(1).height(44).fontSize(F_XS).fontColor(TEXT).placeholderColor(TEXT_4)
          .backgroundColor(GLASS_8).borderRadius(R_MD)
          .onChange((v: string): void => { this.customText = v })
      }.width("100%").padding({ left: 4, right: 8, top: 6, bottom: 10 })
    }.width("100%").borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: S_2, right: S_2 })
  }
}

// ========== API Key 行 ==========
@Component
struct ApiKeyRow {
  @Link apiKey: string
  @Link showKey: boolean
  @Prop testing: boolean = false
  onTest?: () => void

  build() {
    Row() {
      Text(this.showKey ? "🙈" : "👁").fontSize(18).width(36).textAlign(TextAlign.Center)
        .onClick((): void => { this.showKey = !this.showKey })
      TextInput({ text: this.apiKey, placeholder: "sk-..." })
        .type(this.showKey ? InputType.Normal : InputType.Password)
        .layoutWeight(1).height(42).fontSize(F_SM).fontColor(TEXT).placeholderColor(TEXT_4)
        .backgroundColor("transparent")
        .onChange((v: string): void => { this.apiKey = v })
      Button(this.testing ? "..." : "测试").fontSize(F_XS).fontColor(BG_DARK)
        .height(44).borderRadius(R_MD).backgroundColor(MINT).enabled(!this.testing).margin({ left: 8 })
        .onClick((): void => { if (this.onTest) { this.onTest() } })
    }.width("100%").padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: S_2, right: S_2 })
  }
}

// ========== 主页面 ==========
@Entry
@Component
struct AiSettingsPage {
  @StorageProp("statusBarHeight") statusBarH: number = 0
  @State apiKey: string = ""
  @State endpoints: string[] = EP_PRESETS
  @State @Watch('onEndpointChange') endpointIdx: number = 0
  @State endpointCustom: string = ""
  @State @Watch('onEndpointChange') useCustomEP: boolean = false
  @State modelIdx: number = 0
  @State modelCustom: string = ""
  @State useCustomMD: boolean = false
  @State temperature: number = 0.1
  @State maxTokens: number = 256
  @State timeoutMs: number = 5000
  @State configured: boolean = false
  @State testing: boolean = false
  @State showKey: boolean = false
  @State statusText: string = "未配置"
  @State tempText: string = "0.1"
  @State maxTokensText: string = "256"
  @State timeoutText: string = "5000"
  @State currentPresets: ModelPreset[] = SF_MODELS

  onEndpointChange(): void {
    this.currentPresets = (this.useCustomEP || this.endpointIdx !== 1) ? SF_MODELS : DS_MODELS
  }

  aboutToAppear(): void { try { this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.OFFSET) } catch (e) {}; this.loadConfig() }
  aboutToDisappear(): void { try { this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE) } catch (e) {} }

  async loadConfig(): Promise<void> {
    const c = LlmConfig.getInstance()
    const key = await c.getApiKey()
    if (key !== null && key.length > 0) { this.apiKey = key; this.configured = true; this.statusText = "已配置" }
    const ep = c.getEndpoint(); const m = c.getModel()
    let epMatch = -1
    for (let i = 0; i < EP_PRESETS.length; i++) { if (ep === EP_PRESETS[i]) { epMatch = i; break } }
    if (epMatch >= 0) { this.endpointIdx = epMatch; this.useCustomEP = false; this.onEndpointChange() } else { this.endpointCustom = ep; this.useCustomEP = true }
    let mMatch = -1
    for (let i = 0; i < this.currentPresets.length; i++) { if (m === this.currentPresets[i].value) { mMatch = i; break } }
    if (mMatch >= 0) { this.modelIdx = mMatch; this.useCustomMD = false } else { this.modelCustom = m; this.useCustomMD = true }
    this.temperature = c.getTemperature(); this.maxTokens = c.getMaxTokens(); this.timeoutMs = c.getTimeoutMs()
    this.tempText = this.temperature.toString(); this.maxTokensText = this.maxTokens.toString(); this.timeoutText = this.timeoutMs.toString()
  }

  private getEP(): string { return this.useCustomEP ? this.endpointCustom : EP_PRESETS[this.endpointIdx] }
  private getPresets(): ModelPreset[] { return this.useCustomEP || this.endpointIdx !== 1 ? SF_MODELS : DS_MODELS }
  private getModel(): string { return this.useCustomMD ? this.modelCustom : this.currentPresets[this.modelIdx].value }

  async handleSave(): Promise<void> {
    try {
      const tp = parseFloat(this.tempText); const mt = parseInt(this.maxTokensText); const to = parseInt(this.timeoutText)
      if (isNaN(tp) || isNaN(mt) || isNaN(to)) { promptAction.showToast({ message: "参数必须为数字", duration: 2000 }); return }
      const c = LlmConfig.getInstance()
      await c.saveAll(this.getEP(), this.getModel(), tp, mt, to)
      if (this.apiKey.trim().length > 0) { await c.setApiKey(this.apiKey.trim()); this.configured = true; this.statusText = "已保存" }
      promptAction.showToast({ message: "配置已保存", duration: 1500 }); await this.loadConfig()
    } catch (e) { promptAction.showToast({ message: "保存失败", duration: 2000 }) }
  }
  async handleReset(): Promise<void> {
    try {
      await LlmConfig.getInstance().resetDefaults(); await LlmConfig.getInstance().clearApiKey()
      this.apiKey = ""; this.endpointIdx = 0; this.useCustomEP = false; this.endpointCustom = ""
      this.modelIdx = 0; this.useCustomMD = false; this.modelCustom = ""
      this.configured = false; this.statusText = "已恢复默认"
      promptAction.showToast({ message: "已恢复默认", duration: 1500 })
    } catch (e) { promptAction.showToast({ message: "恢复失败", duration: 1500 }) }
  }
  async handleTest(): Promise<void> {
    const key = this.apiKey.trim()
    if (key.length === 0) { promptAction.showToast({ message: "请先输入 API Key", duration: 1500 }); return }
    const c = LlmConfig.getInstance(); await c.setApiKey(key)
    await c.saveAll(this.getEP(), this.getModel(), this.temperature, this.maxTokens, this.timeoutMs)
    this.testing = true
    try {
      await new LlmClient().call([{ role: "system", content: 'Reply "OK".' }, { role: "user", content: "OK" }])
      promptAction.showToast({ message: "连接成功", duration: 1500 }); this.statusText = "已配置 · 连接正常"
    } catch (e) {
      promptAction.showToast({ message: "连接失败", duration: 2500 }); this.statusText = "已配置 · 连接失败"
    } finally { this.testing = false }
  }

  // ========== build() 嵌套仅 2 层 ==========
  build() {
    Column() {
      // 顶栏
      Row() {
        Text("← 返回").fontSize(F_SM).fontColor(MINT).onClick((): void => { router.back() })
        Blank()
        Text("模型配置").fontSize(F_MD).fontWeight(W_SEMIBOLD).fontColor(TEXT)
        Blank(); Row().width(60)
      }.width("100%").padding({ left: S_2, right: S_2, top: 12, bottom: 12 }).margin({ top: this.statusBarH })
      Row().width("100%").height(0.5).backgroundColor(BORDER)

      Scroll() {
        Column() {
          StatusCard({ configured: this.configured, statusText: this.statusText })
            .margin({ left: S_2, right: S_2, top: 16 })

          SectionHeader({ title: "服务端点", desc: "选择预设或输入自定义地址" })
          EndpointPicker({
            epIdx: this.endpointIdx, useCustom: this.useCustomEP, customText: $this.endpointCustom,
            onSelect: (i: number): void => { this.useCustomEP = false; this.endpointIdx = i },
            onCustom: (): void => { this.useCustomEP = true },
          })

          SectionHeader({ title: "模型", desc: "选择 DeepSeek 模型或自定义" })
          ModelPicker({
            presets: this.currentPresets, mdlIdx: this.modelIdx, useCustom: this.useCustomMD, customText: $this.modelCustom,
            onSelect: (i: number): void => { this.useCustomMD = false; this.modelIdx = i },
            onCustom: (): void => { this.useCustomMD = true },
          })

          SectionHeader({ title: "API Key", desc: "从模型服务商获取的密钥" })
          ApiKeyRow({ apiKey: $this.apiKey, showKey: $this.showKey, testing: this.testing, onTest: (): void => { this.handleTest() } })

          SectionHeader({ title: "请求参数", desc: "" })
          Column() {
            ParamRow({ label: "温度", value: this.tempText, hint: "0-2", onChange: (v: string): void => { this.tempText = v } })
            Row().width("100%").height(0.5).backgroundColor(BORDER)
            ParamRow({ label: "最大 Token", value: this.maxTokensText, hint: "1-8192", onChange: (v: string): void => { this.maxTokensText = v } })
            Row().width("100%").height(0.5).backgroundColor(BORDER)
            ParamRow({ label: "超时(ms)", value: this.timeoutText, hint: "1000-60000", onChange: (v: string): void => { this.timeoutText = v } })
          }.width("100%").borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: S_2, right: S_2 })

          Row() {
            Button("恢复默认").fontSize(F_SM).fontColor(PURPLE).height(44).borderRadius(R_MD).backgroundColor(PURPLE_LIGHT)
              .layoutWeight(1).onClick((): void => { this.handleReset() })
            Button("保存配置").fontSize(F_SM).fontColor(BG_DARK).height(44).borderRadius(R_MD).backgroundColor(MINT)
              .layoutWeight(1).margin({ left: 12 }).onClick((): void => { this.handleSave() })
          }.width("100%").padding({ left: S_2, right: S_2, top: 20 })
          Blank().height(40)
        }.width("100%")
      }.layoutWeight(1).width("100%")
    }.width("100%").height("100%").backgroundColor(BG_DARK)
  }
}
