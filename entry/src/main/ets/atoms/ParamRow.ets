// ============================================================================
//  atoms/ParamRow.ets — 参数行原子
//  来源: AiSettingsPage NumberRow @Builder
// ============================================================================

import { TEXT, TEXT_2, TEXT_4, F_XS, F_SM, R_MD, GLASS_8 } from "common"

@Component
export struct ParamRow {
  @Prop label: string = ""
  @Prop value: string = ""
  @Prop hint: string = ""
  onChange: (v: string) => void = (_v: string): void => {}

  build() {
    Row() {
      Column() {
        Text(this.label).fontSize(F_SM).fontColor(TEXT_2)
        Text(this.hint).fontSize(10).fontColor(TEXT_4).margin({ top: 2 })
      }.alignItems(HorizontalAlign.Start)
      Blank()
      TextInput({ text: this.value, placeholder: this.hint })
        .type(InputType.Number).width(90).height(44)
        .fontSize(F_SM).fontColor(TEXT).placeholderColor(TEXT_4)
        .backgroundColor(GLASS_8).borderRadius(R_MD).textAlign(TextAlign.Center)
        .onChange(this.onChange)
    }
    .width("100%").padding({ left: 16, right: 16, top: 10, bottom: 10 })
  }
}
