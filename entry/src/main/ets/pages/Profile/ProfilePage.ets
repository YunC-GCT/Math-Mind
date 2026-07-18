// ============================================================================
//  pages/Profile/ProfilePage.ets - profile page shell
// ============================================================================

import {
  BG_DARK,
  S_1, S_4, S_6,
  R_FULL,
  F_SM,
  GLASS_8,
  DANGER,
} from "common"
import { promptAction } from "@kit.ArkUI"
import { ProfileHeader } from "./ProfileHeader"
import { ProfileStatsRow } from "./ProfileStatsRow"
import { ProfileMenuList } from "./ProfileMenuList"
import { ProfileViewModel } from "../../viewmodels/ProfileViewModel"

@Component
export struct ProfilePage {
  @StorageProp("statusBarHeight") sbh: number = 0
  @State vm: ProfileViewModel = new ProfileViewModel()

  aboutToAppear(): void {
    this.vm.loadStats(getContext(this)).then((ok: boolean): void => {
      if (!ok) {
        this.toast("统计加载失败")
      }
    })
  }

  private toast(msg: string): void {
    try {
      promptAction.showToast({ message: msg, duration: 2000, bottom: "50%" })
    } catch (_e) {}
  }

  build() {
    Scroll() {
      Column() {
        Row()
          .width("100%")
          .height(this.sbh)
          .backgroundColor(BG_DARK)

        ProfileHeader()
        ProfileStatsRow({ notes: this.vm.notes, avg: this.vm.avg, today: this.vm.today })
        ProfileMenuList({ onToast: (message: string): void => this.toast(message) })

        Button("退出登录")
          .fontSize(F_SM)
          .fontColor(DANGER)
          .width("100%")
          .height(S_6 * 2 - S_1)
          .backgroundColor(GLASS_8)
          .borderRadius(R_FULL)
          .margin({ left: S_4, right: S_4, top: S_6, bottom: S_6 * 2 - S_1 })
          .onClick((): void => this.toast("退出登录功能开发中"))

        Blank().height(80)
      }
      .width("100%")
    }
    .width("100%")
    .height("100%")
    .backgroundColor(BG_DARK)
    .scrollBar(BarState.Off)
  }
}
