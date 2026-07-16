// 设置页 · 底部按钮组
import { MINT, BG_DARK, TEXT_3, GLASS_10, F_SM, R_MD, S_2, S_3, S_5, AI_SETTINGS_BTN_H } from "common"
@Component
export struct ActionBar {
  onReset?: () => void
  onSave?: () => void
  build() {
    Row() {
      Button("恢复默认").fontSize(F_SM).fontColor(TEXT_3).height(AI_SETTINGS_BTN_H).borderRadius(R_MD)
        .backgroundColor("GLASS_10").layoutWeight(1)
        .onClick((): void => { if (this.onReset) { this.onReset() } })
      Button("保存配置").fontSize(F_SM).fontColor(BG_DARK).height(AI_SETTINGS_BTN_H).borderRadius(R_MD)
        .backgroundColor(MINT).layoutWeight(1).margin({ left: S_3 })
        .onClick((): void => { if (this.onSave) { this.onSave() } })
    }.width("100%").padding({ left: S_2, right: S_2, top: S_5 })
  }
}
