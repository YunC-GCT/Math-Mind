// ============================================================================
//  atoms/MenuItemRow.ets — 菜单行原子组件
//  ----------------------------------------------------------------------------
//  职责: 图标 + 标签 + 右箭头 的通用菜单行。纯展示，交互通过 onClick 回调。
//  来源: 从 MePage.ets MenuItem @Builder 抽取。
//  ============================================================================

import { TEXT_2, TEXT_4, BORDER, S_4, F_SM, F_MD } from "common"
import { AppIcon } from "./AppIcon"

@Component
export struct MenuItemRow {
  @Prop icon: string = "notes"
  @Prop label: string = ""
  onTap?: () => void

  build() {
    Row() {
      AppIcon({ name: this.icon, iconSize: 18, color: TEXT_4, strokeWidth: 1.8 })
        .width(22)
        .flexShrink(0)

      Text(this.label)
        .fontSize(F_SM)
        .fontColor(TEXT_2)
        .layoutWeight(1)
        .margin({ left: 12 })

      AppIcon({ name: "chevron-right", iconSize: F_MD + 1, color: TEXT_4, strokeWidth: 1.8 })
    }
    .width("100%")
    .padding({ left: 16, right: 16, top: S_4, bottom: S_4 })
    .border({ width: { bottom: 1 }, color: BORDER })
    .onClick((): void => {
      if (this.onTap) {
        this.onTap()
      }
    })
  }
}
