// ============================================================================
//  pages/MePage.ets — 个人中心页装配层
//  ----------------------------------------------------------------------------
//  职责: 编排 ProfileHeader + StatsBox + MenuItemRow，管理统计数据。
//  数据流: @State notes/avg → StatsBox @Prop，菜单事件 → toast/router。
//  依赖:
//    molecules: ProfileHeader
//    atoms:     StatsBox, MenuItemRow
//  ============================================================================

import {
  BG_DARK, BG_CARD,
  S_1, S_2, S_4, S_6,
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
    // TODO: 濞?RDB 闁告梻濮惧ù鍥儑閻旈鏉界紓浣哄枙椤撴悂寮悧鍫濈ウ
  }

  private todayNew(): number { return 3 }

  private toast(msg: string): void {
    promptAction.showToast({ message: msg, duration: 2000, bottom: "50%" })
  }

  build() {
    Scroll() {
      Column() {
        // 闁绘鍩栭埀顑跨劍閻?        Row().width("100%").height(this.sbh).backgroundColor(BG_DARK)

        // 濠㈣埖娼欓崕姘跺礌?        ProfileHeader()

        // 缂備胶鍠曢鍝ユ偘?        Row() {
          StatsBox({ value: this.notes + "", label: "缂佹妫侀? })
          StatsBox({ value: this.avg + "%", label: "闁瑰搫鏈ぐ娆撴偝? })
          StatsBox({ value: this.todayNew() + "", label: "濞寸姴锕ュΛ鈺呭棘閺夋鏉? })
        }
        .width("100%")
        .padding({ left: S_4, right: S_4, bottom: S_4 })
        .justifyContent(FlexAlign.SpaceEvenly)

        // 闁兼寧绮屽畷?        Column() {
          MenuItemRow({ icon: "妫ｅ啯鎯?, label: "闁瑰瓨鍨瑰▓鎴炲緞瀹ュ嫮鐦庨悹浣测偓鍐茬亰", onTap: (): void => this.toast("濠㈣泛绉崇弧鍕媼閳ュ啿鐏婄€殿喒鍋撻柛娆愬灣閼?) })
          MenuItemRow({ icon: "妫ｅ啯鎲?, label: "闂佹寧鐟╅。浠嬪嫉?, onTap: (): void => this.toast("闂佹寧鐟╅。浠嬪嫉椤掆偓缁辨垿宕ｉ幋婊嗗幀") })
          MenuItemRow({ icon: "閻?, label: "闁瑰瓨鍨瑰▓鎴﹀绩閹増顥?, onTap: (): void => this.toast("闁衡偓閹増顥戦柛鏃傚枙閸忔ê顕ｉ埀顒勫矗閹存粏鍘?) })
          MenuItemRow({ icon: "妫ｅ喚妯?, label: "婵☆垪鈧磭鈧?, onTap: (): void => { router.pushUrl({ url: "pages/AiSettings/AiSettingsPage" }) } })
          MenuItemRow({ icon: "妫ｅ啯鐦?, label: "闁告帒娲﹀畷鑼嫻閿曗偓瑜?, onTap: (): void => this.toast("闁告帒娲﹀畷鑼嫻閿曗偓瑜板灝顕ｉ埀顒勫矗閹存粏鍘?) })
        }
        .width("100%")
        .backgroundColor(BG_CARD)
        .borderRadius(R_LG)
        .margin({ left: S_4, right: S_4, top: S_2 })

        // 闂侇偀鍋撻柛鎴ｆ濞呫儴銇?        Button("闂侇偀鍋撻柛鎴ｆ濞呫儴銇?)
          .fontSize(F_SM)
          .fontColor(DANGER)
          .width("100%").height(S_6 * 2 - S_1)
          .backgroundColor(GLASS_8)
          .borderRadius(R_FULL)
          .margin({ left: S_4, right: S_4, top: S_6, bottom: S_6 * 2 - S_2 })
          .onClick((): void => this.toast("闂侇偀鍋撻柛鎴ｆ濞呫儴銇愰弴鐐差潬闁煎疇妫勭槐鎴﹀矗閹存粏鍘?))

        Blank().height(80)
      }
      .width("100%")
    }
    .width("100%").height("100%")
    .backgroundColor(BG_DARK)
    .scrollBar(BarState.Off)
  }
}
