/**
 * OcrConfigSection.ets — AI 设置页 OCR 端点配置
 *
 * 路径: entry/src/main/ets/pages/AiSettings/OcrConfigSection.ets
 * 职责: 让用户配置 OCR 服务端点 + 启用开关
 *       P0 修复: 之前 OcrTool endpoint 写死 127.0.0.1, 真机连不上
 * 依赖: common (OcrConfig)
 *
 * 数据流:
 *   用户输入 endpoint → onChange 回调 → AiSettingsPage handleSave → OcrConfig.setEndpoint
 *   OcrTool.recognize → OcrConfig.getInstance().getEndpoint() → 实时读
 */
import { OcrConfig } from 'common';
import { BG_CARD, TEXT, TEXT_4, R_MD, R_LG, F_XS, F_SM } from 'common';

@Component
export struct OcrConfigSection {
  // OCR 端点 URL
  @Prop endpoint: string = '';

  // 是否启用 OCR
  @Prop enabled: boolean = true;

  // 端点输入回调
  onEndpointChange?: (v: string) => void = (_v: string): void => {};

  // 启用开关回调
  onEnabledChange?: (v: boolean) => void = {};

  // 恢复默认回调
  onReset?: () => void = (): void => {};

  build() {
    Column() {
      // 启用开关
      Row() {
        Text('启用 OCR')
          .fontSize(F_SM)
          .fontColor(TEXT)
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.enabled })
          .onChange((v: boolean): void => {
            if (this.onEnabledChange) { this.onEnabledChange(v); }
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })

      // 端点输入
      Row() {
        Text('端点 URL')
          .fontSize(F_SM)
          .fontColor(TEXT)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })

      Row() {
        TextInput({ text: this.endpoint, placeholder: 'http://192.168.x.x:8000/api/v1/ocr/recognize' })
          .layoutWeight(1)
          .height(44)
          .fontSize(F_XS)
          .fontColor(TEXT)
          .placeholderColor(TEXT_4)
          .backgroundColor('#0AFFFFFF')
          .borderRadius(R_MD)
          .padding({ left: 8, right: 8 })
          .onChange((v: string): void => {
            if (this.onEndpointChange) { this.onEndpointChange(v); }
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 0, bottom: 8 })

      // 恢复默认
      Row() {
        Text('真机部署时, 把 127.0.0.1 改成本机或内网 IP')
          .fontSize(F_XS)
          .fontColor(TEXT_4)
          .layoutWeight(1)
        Text('恢复默认')
          .fontSize(F_XS)
          .fontColor(TEXT_4)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(R_MD)
          .backgroundColor('#0AFFFFFF')
          .onClick((): void => {
            if (this.onReset) { this.onReset(); }
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 4, bottom: 8 })
    }
    .width('100%')
    .borderRadius(R_LG)
    .backgroundColor(BG_CARD)
    .margin({ left: 8, right: 8 })
  }
}
