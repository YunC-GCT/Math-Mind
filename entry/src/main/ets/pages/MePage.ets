// ============================================================================
//  pages/MePage.ets 鈥?涓汉涓績椤佃閰嶅眰
//  ----------------------------------------------------------------------------
//  鑱岃矗: 缂栨帓 ProfileHeader + StatsBox + MenuItemRow锛岀鐞嗙粺璁℃暟鎹€?//  鏁版嵁娴? @State notes/avg 鈫?StatsBox @Prop锛岃彍鍗曚簨浠?鈫?toast/router銆?//  渚濊禆:
//    molecules: ProfileHeader
//    atoms:     StatsBox, MenuItemRow
//  ============================================================================

import {
  BG_DARK, BG_CARD,
  S_2, S_4, S_6,
  R_LG, R_FULL,
  F_SM,
  GLASS_8,
  DANGER,
} from "common"
import { promptAction, router } from "@kit.ArkUI"
import { ProfileHeader } from "../molecules/ProfileHeader"
import { StatsBox } from "../atoms/StatsBox"
import { MenuItemRow } from "../atoms/MenuItemRow"

@Component
export struct MePage {
  @StorageProp("statusBarHeight") sbh: number = 0
  @State notes: number = 12
  @State avg: number = 78

  aboutToAppear(): void {
    // TODO: 浠?RDB 鍔犺浇鐪熷疄缁熻鏁版嵁
  }

  private todayNew(): number { return 3 }

  private toast(msg: string): void {
    promptAction.showToast({ message: msg, duration: 2000, bottom: "50%" })
  }

  build() {
    Scroll() {
      Column() {
        // 鐘舵€佹爮
        Row().width("100%").height(this.sbh).backgroundColor(BG_DARK)

        // 澶村儚鍖?        ProfileHeader()

        // 缁熻琛?        Row() {
          StatsBox({ value: this.notes + "", label: "绗旇" })
          StatsBox({ value: this.avg + "%", label: "鎺屾彙鐜? })
          StatsBox({ value: this.todayNew() + "", label: "浠婃棩鏂板" })
        }
        .width("100%")
        .padding({ left: S_4, right: S_4, bottom: S_4 })
        .justifyContent(FlexAlign.SpaceEvenly)

        // 鑿滃崟
        Column() {
          MenuItemRow({ icon: "馃搵", label: "鎴戠殑澶嶄範璁″垝", onTap: (): void => this.toast("澶嶄範璁″垝寮€鍙戜腑") })
          MenuItemRow({ icon: "馃摃", label: "閿欓鏈?, onTap: (): void => this.toast("閿欓鏈紑鍙戜腑") })
          MenuItemRow({ icon: "猸?, label: "鎴戠殑鏀惰棌", onTap: (): void => this.toast("鏀惰棌鍔熻兘寮€鍙戜腑") })
          MenuItemRow({ icon: "馃", label: "妯″瀷", onTap: (): void => { router.pushUrl({ url: "pages/AiSettings/AiSettingsPage" }) } })
          MenuItemRow({ icon: "馃毆", label: "鍒囨崲璐﹀彿", onTap: (): void => this.toast("鍒囨崲璐﹀彿寮€鍙戜腑") })
        }
        .width("100%")
        .backgroundColor(BG_CARD)
        .borderRadius(R_LG)
        .margin({ left: S_4, right: S_4, top: S_2 })

        // 閫€鍑虹櫥褰?        Button("閫€鍑虹櫥褰?)
          .fontSize(F_SM)
          .fontColor(DANGER)
          .width("100%").height(S_6 * 2 - S_1)
          .backgroundColor(GLASS_8)
          .borderRadius(R_FULL)
          .margin({ left: S_4, right: S_4, top: S_6, bottom: S_6 * 2 - S_2 })
          .onClick((): void => this.toast("閫€鍑虹櫥褰曞姛鑳藉紑鍙戜腑"))

        Blank().height(80)
      }
      .width("100%")
    }
    .width("100%").height("100%")
    .backgroundColor(BG_DARK)
    .scrollBar(BarState.Off)
  }
}
