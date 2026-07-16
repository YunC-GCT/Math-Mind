// 璁剧疆椤?路 妯″瀷閫夋嫨鍣?(DeepSeek V4 鏈€鏂?
import { BG_CARD, TEXT, TEXT_4, GLASS_8, R_MD, R_LG, F_XS, F_SM, W_SEMIBOLD, S_1, S_2, AI_SETTINGS_BTN_H } from "common"

export const DEFAULT_MODEL = "deepseek-v4-flash"

@Component
export struct ModelPicker {
  @Prop mdlIdx: number = 0
  @Prop useCustom: boolean = false
  @Prop customText: string = ""
  onSelect?: (idx: number) => void
  onCustomChange?: (v: string) => void
  onToggle?: (custom: boolean) => void

  build() {
    Column() {
      // V4-Flash (榛樿)
      Row() {
        Radio({ value: "md0", group: "md" }).checked(!this.useCustom && this.mdlIdx === 0)
          .onChange((v: boolean): void => { if (v && this.onSelect) { this.onSelect(0) } })
        Column() {
          Text("DeepSeek-V4-Flash").fontSize(F_SM).fontColor(TEXT).fontWeight(W_SEMIBOLD)
          Text("蹇€熻交閲?路 榛樿鎺ㄨ崘").fontSize(F_XS - 2).fontColor(TEXT_4).margin({ top: S_1 / 4 })
        }.alignItems(HorizontalAlign.Start).margin({ left: S_2 }).layoutWeight(1)
      }.width("100%").padding({ left: S_1, right: S_1, top: S_2 - 2, bottom: S_2 - 2 })

      // V4-Pro
      Row() {
        Radio({ value: "md1", group: "md" }).checked(!this.useCustom && this.mdlIdx === 1)
          .onChange((v: boolean): void => { if (v && this.onSelect) { this.onSelect(1) } })
        Column() {
          Text("DeepSeek-V4-Pro").fontSize(F_SM).fontColor(TEXT).fontWeight(W_SEMIBOLD)
          Text("鏃楄埌鎬ц兘 路 澶嶆潅鎺ㄧ悊").fontSize(F_XS - 2).fontColor(TEXT_4).margin({ top: S_1 / 4 })
        }.alignItems(HorizontalAlign.Start).margin({ left: S_2 }).layoutWeight(1)
      }.width("100%").padding({ left: S_1, right: S_1, top: S_2 - 2, bottom: S_2 - 2 })

      // 鑷畾涔?      Row() {
        Radio({ value: "md_c", group: "md" }).checked(this.useCustom)
          .onChange((v: boolean): void => { if (v && this.onToggle) { this.onToggle(true) } })
        TextInput({ text: this.customText, placeholder: "鑷畾涔夋ā鍨?ID..." }).layoutWeight(1).height(AI_SETTINGS_BTN_H)
          .fontSize(F_XS).fontColor(TEXT).placeholderColor(TEXT_4)
          .backgroundColor(GLASS_8).borderRadius(R_MD)
          .onChange((v: string): void => { if (this.onCustomChange) { this.onCustomChange(v) } })
      }.width("100%").padding({ left: S_1, right: S_2, top: S_2 - 2, bottom: S_3 - 2 })
    }.width("100%").borderRadius(R_LG).backgroundColor(BG_CARD).margin({ left: S_2, right: S_2 })
  }
}
