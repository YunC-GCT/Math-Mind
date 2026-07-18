import { BG_CARD, TEXT, TEXT_3, TEXT_4, R_MD, R_LG, F_XS, F_SM } from 'common'

@Component
export struct OcrConfigSection {
  @Prop endpoint: string = ''
  @Prop isEnabled: boolean = true
  @Prop statusText: string = ''
  @Prop testing: boolean = false

  onEndpointChange?: (v: string) => void = (_v: string): void => {}
  onEnabledChange?: (v: boolean) => void = (_v: boolean): void => {}
  onReset?: () => void = (): void => {}
  onTest?: () => void = (): void => {}

  build() {
    Column() {
      Row() {
        Text('启用 OCR')
          .fontSize(F_SM)
          .fontColor(TEXT)
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.isEnabled })
          .onChange((v: boolean): void => {
            if (this.onEnabledChange) {
              this.onEnabledChange(v)
            }
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })

      Row() {
        Text('服务地址')
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
            if (this.onEndpointChange) {
              this.onEndpointChange(v)
            }
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 0, bottom: 8 })

      Row() {
        Text(this.statusText.length > 0 ? this.statusText : '未测试')
          .fontSize(F_XS)
          .fontColor(TEXT_3)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Button(this.testing ? '...' : '测试连接')
          .fontSize(F_XS)
          .fontColor(TEXT)
          .height(34)
          .borderRadius(R_MD)
          .backgroundColor('#0AFFFFFF')
          .enabled(!this.testing)
          .onClick((): void => {
            if (this.onTest) {
              this.onTest()
            }
          })
        Text('恢复默认')
          .fontSize(F_XS)
          .fontColor(TEXT_4)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(R_MD)
          .backgroundColor('#0AFFFFFF')
          .onClick((): void => {
            if (this.onReset) {
              this.onReset()
            }
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 4, bottom: 8 })

      Row() {
        Text('真机填电脑局域网 IP，127.0.0.1 只适合本机或同机服务')
          .fontSize(F_XS)
          .fontColor(TEXT_4)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 0, bottom: 8 })
    }
    .width('100%')
    .borderRadius(R_LG)
    .backgroundColor(BG_CARD)
    .margin({ left: 8, right: 8 })
  }
}
