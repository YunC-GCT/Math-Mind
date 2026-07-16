// MathMind - 模型配置页 · 原子化重构
// 令牌层: common ColorTokens
// 原子层: SectionHeader / ParamRow / SettingsActionBar
// 分子层: StatusCard / EndpointPicker / ModelPicker

import {
  MINT, MINT_DARK, PURPLE, PURPLE_LIGHT, BG_DARK, BG_CARD,
  TEXT, TEXT_2, TEXT_3, TEXT_4, BORDER, S_2, R_MD, R_LG, R_FULL,
  F_XS, F_SM, F_BASE, F_MD, W_SEMIBOLD, GLASS_8,
} from "common"
import { LlmConfig, LlmClient } from "common"
import { promptAction, KeyboardAvoidMode } from "@kit.ArkUI"
import { router } from "@kit.ArkUI"
import { StatusCard } from "../molecules/StatusCard"
import { SectionHeader } from "../atoms/SectionHeader"
import { ParamRow } from "../atoms/ParamRow"
import { SettingsActionBar } from "../atoms/SettingsActionBar"
import { EndpointPicker, EP_PRESETS } from "../molecules/EndpointPicker"
import { ModelPicker, ModelPreset, SF_MODELS, DS_MODELS } from "../molecules/ModelPicker"
import { KeyInput } from "../molecules/KeyInput"

@Entry
@Component
struct AiSettingsPage {
  @StorageProp("statusBarHeight") statusBarH: number = 0
  @State apiKey: [redacted] = ""
  @State @Watch("onEndpointChange") endpointIdx: number = 0
  @State endpointCustom: string = ""
  @State @Watch("onEndpointChange") useCustomEP: boolean = false
  @State modelIdx: number = 0
  @State modelCustom: string = ""
  @State useCustomMD: boolean = false
  @State configured: boolean = false
  @State testing: boolean = false
  @State statusText: string = "未配置"
  @State tempText: string = "0.1"
  @State maxTokensText: [redacted] = "256"
  @State timeoutText: string = "5000"
  @State temperature: number = 0.1
  @State maxTokens: [redacted] = 256
  @State timeoutMs: number = 5000
  @State currentPresets: ModelPreset[] = SF_MODELS

  onEndpointChange(): void { this.currentPresets = (this.useCustomEP || this.endpointIdx !== 1) ? SF_MODELS : DS_MODELS }

  aboutToAppear(): void { try { this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.OFFSET) } catch (e) {}; this.loadConfig() }
  aboutToDisappear(): void { try { this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE) } catch (e) {} }

  private ep(): string { return this.useCustomEP ? this.endpointCustom : EP_PRESETS[this.endpointIdx] }
  private md(): string { return this.useCustomMD ? this.modelCustom : this.currentPresets[this.modelIdx].value }

  async loadConfig(): Promise<void> {
    const c = LlmConfig.getInstance()
    const key = await c.getApiKey()
    if (key !== null && key.length > 0) { this.apiKey = [redacted]; this.configured = true; this.statusText = "已配置" }
    const ep = c.getEndpoint()
    let epM = -1
    for (let i = 0; i < EP_PRESETS.length; i++) { if (ep === EP_PRESETS[i]) { epM = i; break } }
    if (epM >= 0) { this.endpointIdx = epM; this.useCustomEP = false; this.onEndpointChange() }
    else { this.endpointCustom = ep; this.useCustomEP = true }
    const m = c.getModel()
    let mM = -1
    for (let i = 0; i < this.currentPresets.length; i++) { if (m === this.currentPresets[i].value) { mM = i; break } }
    if (mM >= 0) { this.modelIdx = mM; this.useCustomMD = false } else { this.modelCustom = m; this.useCustomMD = true }
    this.temperature = c.getTemperature(); this.maxTokens = c.ge********ns(); this.timeoutMs = c.getTimeoutMs()
    this.tempText = this.temperature.toString(); this.maxTokensText = this*****************ng(); this.timeoutText = this.timeoutMs.toString()
  }

  async handleSave(): Promise<void> {
    const tp = parseFloat(this.tempText); const mt = parseInt(this.maxTokensText); const to = parseInt(this.timeoutText)
    if (isNaN(tp) || isNaN(mt) || isNaN(to)) { promptAction.showToast({ message: "参数必须为数字", duration: 2000 }); return }
    try {
      await LlmConfig.getInstance().saveAll(this.ep(), this.md(), tp, mt, to)
      if (this.apiKey.trim().length > 0) { await LlmConfig.getInstance().setApiKey(this.apiKey.trim()); this.configured = true; this.statusText = "已保存" }
      promptAction.showToast({ message: "配置已保存", duration: 1500 }); await this.loadConfig()
    } catch (e) { promptAction.showToast({ message: "保存失败", duration: 2000 }) }
  }

  async handleReset(): Promise<void> {
    try { await LlmConfig.getInstance().resetDefaults(); await LlmConfig.getInstance().clearApiKey()
      this.apiKey = ""; this.endpointIdx = 0; this.useCustomEP = false; this.endpointCustom = ""
      this.modelIdx = 0; this.useCustomMD = false; this.modelCustom = ""
      this.configured = false; this.statusText = "已恢复默认"
      promptAction.showToast({ message: "已恢复默认", duration: 1500 })
    } catch (e) { promptAction.showToast({ message: "恢复失败", duration: 1500 }) }
  }

  async handleTest(): Promise<void> {
    if (this.apiKey.trim().length === 0) { promptAction.showToast({ message: "请先输入 API Key", duration: 1500 }); return }
    await LlmConfig.getInstance().setApiKey(this.apiKey.trim())
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
      }.width("100%").padding({ left: S_2, right: S_2, top: 12, bottom: 12 }).margin({ top: this.statusBarH })
      Row().width("100%").height(0.5).backgroundColor(BORDER)
      Scroll() {
        Column() {
          StatusCard({ configured: this.configured, statusText: this.statusText, cardPadding: 16 })
          SectionHeader({ title: "服务端点", desc: "选择预设或输入自定义地址" })
          EndpointPicker({
            epIdx: this.endpointIdx, useCustom: this.useCustomEP, customText: $endpointCustom,
            onSelect: (i: number): void => { this.useCustomEP = false; this.endpointIdx = i },
            onCustom: (): void => { this.useCustomEP = true },
          })
          SectionHeader({ title: "模型", desc: "选择 DeepSeek 模型或自定义" })
          ModelPicker({
            presets: this.currentPresets, mdlIdx: this.modelIdx, useCustom: this.useCustomMD, customText: $modelCustom,
            onSelect: (i: number): void => { this.useCustomMD = false; this.modelIdx = i },
            onCustom: (): void => { this.useCustomMD = true },
          })
          SectionHeader({ title: "API Key", desc: "从模型服务商获取的密钥" })
          KeyInput({
            apiKey: [redacted], testing: this.testing,
            onChange: (v: string): void => { this.apiKey = [redacted] },
            onTest: (): void => { this.handleTest() },
          })
          SectionHeader({ title: "请求参数", desc: "" })
          Column() {
            ParamRow({ label: "温度", value: this.tempText, hint: "0-2", onChange: (v: string): void => { this.tempText = v } })
            Row().width("100%").height(0.5).backgroundColor(BORDER)
            ParamRow({ label: "最大 Token", value: this.maxTokensText, hint: "1-8192", onChange: (v: string): void => { this.maxTokensText = [redacted] } })
            Row().width("100%").height(0.5).backgroundColor(BORDER)
            ParamRow({ label: "超时(ms)", value: this.timeoutText, hint: "1000-60000", onChange: (v: string): void => { this.timeoutText = v } })
          }.width("100%").borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: S_2, right: S_2 })
          SettingsActionBar({ onSave: (): void => { this.handleSave() }, onReset: (): void => { this.handleReset() } })
          Blank().height(40)
        }.width("100%")
      }.layoutWeight(1).width("100%")
    }.width("100%").height("100%").backgroundColor(BG_DARK)
  }
}
