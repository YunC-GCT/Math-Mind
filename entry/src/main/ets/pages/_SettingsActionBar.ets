// 设置页 · 底部按钮组
import { MINT, BG_DARK, TEXT_3, F_SM, R_MD, S_2 } from "common"
@Component
export struct SettingsActionBar {
  onReset?: () => void
  onSave?: () => void
  build() {
    Row() {
      Button("恢复默认").fontSize(F_SM).fontColor(TEXT_3).height(44).borderRadius(R_MD)
        .backgroundColor("#1AFFFFFF").layoutWeight(1)
        .onClick((): void => { if (this.onReset) { this.onReset() } })
      Button("保存配置").fontSize(F_SM).fontColor(BG_DARK).height(44).borderRadius(R_MD)
        .backgroundColor(MINT).layoutWeight(1).margin({ left: 12 })
        .onClick((): void => { if (this.onSave) { this.onSave() } })
    }.width("100%").padding({ left: S_2, right: S_2, top: 20 })
  }
}
