// ============================================================================
//  SettingsActionBar.ets — 设置页底部按钮组原子
//  ----------------------------------------------------------------------------
//  用途: 设置页底部双按钮行（恢复默认 + 保存），等分宽度
//  UI:    [ 恢复默认 ]  [  保存配置  ]    ← 紫色/绿色双按钮
//  接口:
//    @Prop saveLabel   — 保存按钮文字（默认 "保存"）
//    @Prop resetLabel  — 恢复按钮文字（默认 "恢复默认"）
//    onSave            — 保存回调 → 父 handleSave()
//    onReset           — 恢复回调 → 父 handleReset()
//  依赖: common ColorTokens (MINT/PURPLE/PURPLE_LIGHT/BG_DARK/F_SM/R_MD)
//  复用: AiSettingsPage / 外观设置 / 任何设置页
// ============================================================================// ============================================================================
//  atoms/SettingsActionBar.ets — 设置页底部操作按钮组
//  复用: AiSettingsPage / 外观设置 / 其他设置页
// ============================================================================

import { MINT, PURPLE, PURPLE_LIGHT, BG_DARK, F_SM, R_MD } from "common"

@Component
export struct SettingsActionBar {
  @Prop saveLabel: string = "保存"
  @Prop resetLabel: string = "恢复默认"
  onSave?: () => void
  onReset?: () => void

  build() {
    Row() {
      Button(this.resetLabel).fontSize(F_SM).fontColor(PURPLE)
        .height(44).borderRadius(R_MD).backgroundColor(PURPLE_LIGHT)
        .layoutWeight(1)
        .onClick((): void => { if (this.onReset) { this.onReset() } })
      Button(this.saveLabel).fontSize(F_SM).fontColor(BG_DARK)
        .height(44).borderRadius(R_MD).backgroundColor(MINT)
        .layoutWeight(1).margin({ left: 12 })
        .onClick((): void => { if (this.onSave) { this.onSave() } })
    }
    .width("100%").padding({ left: 2, right: 2, top: 20 })
  }
}
