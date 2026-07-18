// ============================================================================
//  viewmodels/AiSettingsViewModel.ets - ai settings data logic
// ============================================================================

import { LlmClient, LlmConfig, OcrConfig } from "common"
import { DS_ENDPOINT } from "../pages/AiSettings/EndpointPicker"
import { DEFAULT_MODEL } from "../pages/AiSettings/ModelPicker"

const DEFAULT_OCR_ENDPOINT: string = "http://127.0.0.1:8000/api/v1/ocr/recognize"

@Observed
export class AiSettingsViewModel {
  apiKey: string = ""
  useCustomEP: boolean = false
  customEP: string = ""
  mdlIdx: number = 0
  useCustomMD: boolean = false
  customMD: string = ""
  configured: boolean = false
  testing: boolean = false
  statusText: string = "未配置"
  temp: number = 0.1
  maxT: number = 1024
  to: number = 5000
  ocrEndpoint: string = DEFAULT_OCR_ENDPOINT
  ocrEnabled: boolean = true

  async load(): Promise<boolean> {
    let ok: boolean = true
    const llm: LlmConfig = LlmConfig.getInstance()
    try {
      const key: string | null = await llm.getApiKey()
      this.apiKey = key === null ? "" : key
      this.configured = this.apiKey.trim().length > 0
      this.statusText = this.configured ? "已配置" : "未配置"
    } catch (_e) {
      ok = false
      this.apiKey = ""
      this.configured = false
      this.statusText = "未配置"
    }

    this.syncEndpoint(llm.getEndpoint())
    this.syncModel(llm.getModel())
    this.temp = llm.getTemperature()
    this.maxT = llm.getMaxTokens()
    this.to = llm.getTimeoutMs()

    const ocr: OcrConfig = OcrConfig.getInstance()
    try {
      this.ocrEndpoint = ocr.getEndpoint()
      this.ocrEnabled = ocr.isEnabled()
    } catch (_e) {
      ok = false
      this.ocrEndpoint = DEFAULT_OCR_ENDPOINT
      this.ocrEnabled = true
    }
    return ok
  }

  async save(): Promise<boolean> {
    try {
      const llm: LlmConfig = LlmConfig.getInstance()
      await llm.saveAll(this.resolveEndpoint(), this.resolveModel(), this.temp, this.maxT, this.to)
      const key: string = this.apiKey.trim()
      if (key.length > 0) {
        await llm.setApiKey(key)
        this.configured = true
      }
      const ocr: OcrConfig = OcrConfig.getInstance()
      await ocr.setEndpoint(this.ocrEndpoint)
      await ocr.setEnabled(this.ocrEnabled)
      this.statusText = "已保存"
      return true
    } catch (_e) {
      return false
    }
  }

  async reset(): Promise<boolean> {
    try {
      const llm: LlmConfig = LlmConfig.getInstance()
      await llm.resetDefaults()
      await llm.clearApiKey()
      this.apiKey = ""
      this.useCustomEP = false
      this.customEP = ""
      this.mdlIdx = 0
      this.useCustomMD = false
      this.customMD = ""
      this.configured = false
      this.statusText = "已重置"
      this.temp = 0.1
      this.maxT = 1024
      this.to = 5000
      const ocr: OcrConfig = OcrConfig.getInstance()
      await ocr.resetDefaults()
      this.ocrEndpoint = ocr.getEndpoint()
      this.ocrEnabled = ocr.isEnabled()
      return true
    } catch (_e) {
      return false
    }
  }

  async test(): Promise<boolean> {
    const key: string = this.apiKey.trim()
    if (key.length === 0) {
      return false
    }
    this.testing = true
    try {
      const llm: LlmConfig = LlmConfig.getInstance()
      await llm.setApiKey(key)
      await llm.saveAll(this.resolveEndpoint(), this.resolveModel(), this.temp, this.maxT, this.to)
      await new LlmClient().call([
        { role: "system", content: "OK" },
        { role: "user", content: "OK" },
      ])
      this.statusText = "已配置 · 连接正常"
      this.configured = true
      return true
    } catch (_e) {
      this.statusText = "连接失败"
      return false
    } finally {
      this.testing = false
    }
  }

  setApiKey(value: string): void {
    this.apiKey = value
  }

  setCustomEndpoint(value: string): void {
    this.customEP = value
    this.useCustomEP = value.trim().length > 0
  }

  toggleCustomEndpoint(value: boolean): void {
    this.useCustomEP = value
    if (!value) {
      this.customEP = ""
    }
  }

  selectModel(index: number): void {
    this.mdlIdx = index
    this.useCustomMD = false
    this.customMD = ""
  }

  setCustomModel(value: string): void {
    this.customMD = value
    this.useCustomMD = value.trim().length > 0
  }

  toggleCustomModel(value: boolean): void {
    this.useCustomMD = value
    if (!value) {
      this.customMD = ""
    }
  }

  setOcrEndpoint(value: string): void {
    this.ocrEndpoint = value
  }

  setOcrEnabled(value: boolean): void {
    this.ocrEnabled = value
  }

  resetOcrEndpoint(): void {
    this.ocrEndpoint = DEFAULT_OCR_ENDPOINT
  }

  private syncEndpoint(endpoint: string): void {
    const current: string = endpoint.trim()
    if (current.length === 0 || current === DS_ENDPOINT) {
      this.useCustomEP = false
      this.customEP = ""
      return
    }
    this.useCustomEP = true
    this.customEP = current
  }

  private syncModel(model: string): void {
    const current: string = model.trim()
    if (current.length === 0 || current === DEFAULT_MODEL) {
      this.mdlIdx = 0
      this.useCustomMD = false
      this.customMD = ""
      return
    }
    if (current === "deepseek-v4-pro") {
      this.mdlIdx = 1
      this.useCustomMD = false
      this.customMD = ""
      return
    }
    this.mdlIdx = 0
    this.useCustomMD = true
    this.customMD = current
  }

  private resolveEndpoint(): string {
    return this.useCustomEP && this.customEP.length > 0 ? this.customEP : DS_ENDPOINT
  }

  private resolveModel(): string {
    if (this.useCustomMD && this.customMD.length > 0) {
      return this.customMD
    }
    return this.mdlIdx === 1 ? "deepseek-v4-pro" : DEFAULT_MODEL
  }
}
