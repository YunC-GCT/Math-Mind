// ============================================================================
//  pages/AiSettings/AiSettingsPage.ets - ai settings shell
// ============================================================================

import { BG_DARK, BORDER } from "common"
import { KeyboardAvoidMode, promptAction } from "@kit.ArkUI"
import { PageHeader } from "./PageHeader"
import { ConnectionStatus } from "./ConnectionStatus"
import { SectionHeader } from "./SectionHeader"
import { ActionBar } from "./ActionBar"
import { EndpointPicker } from "./EndpointPicker"
import { ModelPicker } from "./ModelPicker"
import { KeyInput } from "./KeyInput"
import { OcrConfigSection } from "./OcrConfigSection"
import { AiSettingsViewModel } from "../../viewmodels/AiSettingsViewModel"

@Entry
@Component
struct AiSettingsPage {
  @StorageProp("statusBarHeight") sbh: number = 0
  @State vm: AiSettingsViewModel = new AiSettingsViewModel()

  aboutToAppear(): void {
    try {
      this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.OFFSET)
    } catch (_e) {}
    this.reload()
  }

  aboutToDisappear(): void {
    try {
      this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE)
    } catch (_e) {}
  }

  private reload(): void {
    this.vm.load().then((ok: boolean): void => {
      if (!ok) {
        try { promptAction.showToast({ message: "配置加载失败", duration: 1500 }) } catch (_e) {}
      }
    })
  }

  private save(): void {
    this.vm.save().then((ok: boolean): void => {
      try {
        promptAction.showToast({ message: ok ? "已保存" : "保存失败", duration: 1500 })
      } catch (_e) {}
    })
  }

  private reset(): void {
    this.vm.reset()
  }

  private test(): void {
    if (this.vm.apiKey.trim().length === 0) {
      try { promptAction.showToast({ message: "请先输入 API Key", duration: 1500 }) } catch (_e) {}
      return
    }
    this.vm.test()
  }

  build() {
    Column() {
      Row().width("100%").height(this.sbh).backgroundColor(BG_DARK)
      PageHeader({ title: "模型设置" })
      Row().width("100%").height(0.5).backgroundColor(BORDER)
      Scroll() {
        Column() {
          ConnectionStatus({ configured: this.vm.configured, statusText: this.vm.statusText })
          SectionHeader({ title: "服务端点", desc: "DeepSeek 官方或自定义" })
          EndpointPicker({
            useCustom: this.vm.useCustomEP,
            customText: this.vm.customEP,
            onToggle: (v: boolean): void => { this.vm.toggleCustomEndpoint(v) },
            onCustomChange: (v: string): void => { this.vm.setCustomEndpoint(v) },
          })
          SectionHeader({ title: "模型", desc: "DeepSeek-V3 或自定义" })
          ModelPicker({
            mdlIdx: this.vm.mdlIdx,
            useCustom: this.vm.useCustomMD,
            customText: this.vm.customMD,
            onSelect: (i: number): void => { this.vm.selectModel(i) },
            onToggle: (v: boolean): void => { this.vm.toggleCustomModel(v) },
            onCustomChange: (v: string): void => { this.vm.setCustomModel(v) },
          })
          SectionHeader({ title: "API Key", desc: "来自 DeepSeek 的密钥" })
          KeyInput({
            apiKey: this.vm.apiKey,
            testing: this.vm.testing,
            onChange: (v: string): void => { this.vm.setApiKey(v) },
            onTest: (): void => { this.test() },
          })
          SectionHeader({ title: "OCR 服务", desc: "拍照识别后端，本地 FastAPI" })
          OcrConfigSection({
            endpoint: this.vm.ocrEndpoint,
            isEnabled: this.vm.ocrEnabled,
            onEndpointChange: (v: string): void => { this.vm.setOcrEndpoint(v) },
            onEnabledChange: (v: boolean): void => { this.vm.setOcrEnabled(v) },
            onReset: (): void => { this.vm.resetOcrEndpoint() },
          })
          ActionBar({ onReset: (): void => { this.reset() }, onSave: (): void => { this.save() } })
          Blank().height(40)
        }.width("100%")
      }.layoutWeight(1)
    }.width("100%").height("100%").backgroundColor(BG_DARK)
  }
}
