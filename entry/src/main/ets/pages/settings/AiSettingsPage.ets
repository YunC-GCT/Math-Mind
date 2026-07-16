// ============================================================================
//  AiSettingsPage.ets — 大模型设置 · 7 行装配
//  仅 DeepSeek + 自定义端点/模型
// ============================================================================

import { BG_DARK, BORDER } from "common"
import { KeyboardAvoidMode } from "@kit.ArkUI"
import { LlmConfig, LlmClient } from "common"
import { promptAction } from "@kit.ArkUI"
import { SettingsTopBar } from "../../atoms/SettingsTopBar"
import { SettingsStatus } from "./SettingsStatus"
import { SettingsSection } from "./SettingsSection"
import { SettingsActionBar } from "./SettingsActionBar"
import { EndpointPicker, DS_ENDPOINT } from "./EndpointPicker"
import { ModelPicker, DEFAULT_MODEL } from "./ModelPicker"
import { KeyInput } from "./KeyInput"

@Entry
@Component
struct AiSettingsPage {
  @StorageProp("statusBarHeight") sbh: number = 0
  @State apiKey: string = ""
  @State useCustomEP: boolean = false; @State customEP: string = ""
  @State useCustomMD: boolean = false; @State customMD: string = ""
  @State configured: boolean = false; @State testing: boolean = false
  @State statusText: string = "未配置"
  @State temp: number = 0.1; @State maxT: number = 256; @State to: number = 5000

  aboutToAppear(): void { try { this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.OFFSET) } catch (e) {}; this.load() }
  aboutToDisappear(): void { try { this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE) } catch (e) {} }

  private ep(): string { return this.useCustomEP && this.customEP ? this.customEP : DS_ENDPOINT }
  private md(): string { return this.useCustomMD && this.customMD ? this.customMD : DEFAULT_MODEL }

  async load(): Promise<void> {
    const c = LlmConfig.getInstance()
    const key = await c.getApiKey()
    if (key && key.length > 0) { this.apiKey = key; this.configured = true; this.statusText = "已配置" }
  }

  async handleSave(): Promise<void> {
    try {
      await LlmConfig.getInstance().saveAll(this.ep(), this.md(), this.temp, this.maxT, this.to)
      if (this.apiKey.trim()) { await LlmConfig.getInstance().setApiKey(this.apiKey.trim()); this.configured = true }
      this.statusText = "已保存"
      promptAction.showToast({ message: "已保存", duration: 1500 })
    } catch (e) { promptAction.showToast({ message: "保存失败", duration: 1500 }) }
  }

  async handleReset(): Promise<void> {
    try { await LlmConfig.getInstance().resetDefaults(); await LlmConfig.getInstance().clearApiKey()
      this.apiKey = ""; this.useCustomEP = false; this.customEP = ""; this.useCustomMD = false; this.customMD = ""
      this.configured = false; this.statusText = "已重置"
    } catch (e) {}
  }

  async handleTest(): Promise<void> {
    if (!this.apiKey.trim()) { promptAction.showToast({ message: "请先输入 API Key", duration: 1500 }); return }
    await LlmConfig.getInstance().setApiKey(this.apiKey.trim())
    await LlmConfig.getInstance().saveAll(this.ep(), this.md(), this.temp, this.maxT, this.to)
    this.testing = true
    try { await new LlmClient().call([{ role: "system", content: "OK" }, { role: "user", content: "OK" }])
      this.statusText = "已配置 · 连接正常"; this.configured = true
    } catch (e) { this.statusText = "连接失败" }
    finally { this.testing = false }
  }

  build() {
    Column() {
      Row().width("100%").height(this.sbh).backgroundColor(BG_DARK)
      SettingsTopBar({ title: "模型配置" })
      Row().width("100%").height(0.5).backgroundColor(BORDER)
      Scroll() {
        Column() {
          SettingsStatus({ configured: this.configured, statusText: this.statusText })
          SettingsSection({ title: "服务端点", desc: "DeepSeek 官方或自定义" })
          EndpointPicker({ useCustom: this.useCustomEP, customText: this.customEP,
            onToggle: (v: boolean): void => { this.useCustomEP = v },
            onCustomChange: (v: string): void => { this.customEP = v } })
          SettingsSection({ title: "模型", desc: "DeepSeek-V3 或自定义" })
          ModelPicker({ useCustom: this.useCustomMD, customText: this.customMD,
            onToggle: (v: boolean): void => { this.useCustomMD = v },
            onCustomChange: (v: string): void => { this.customMD = v } })
          SettingsSection({ title: "API Key", desc: "从 DeepSeek 获取的密钥" })
          KeyInput({ apiKey: this.apiKey, testing: this.testing,
            onChange: (v: string): void => { this.apiKey = v },
            onTest: (): void => { this.handleTest() } })
          SettingsActionBar({ onReset: (): void => { this.handleReset() }, onSave: (): void => { this.handleSave() } })
          Blank().height(40)
        }.width("100%")
      }.layoutWeight(1)
    }.width("100%").height("100%").backgroundColor(BG_DARK)
  }
}
