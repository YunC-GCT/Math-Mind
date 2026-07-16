// ============================================================================
//  pages/MePage.ets 閳?娑擃亙姹夋稉顓炵妇妞や絻顥婇柊宥呯湴
//  ----------------------------------------------------------------------------
//  閼卞矁鐭? 缂傛牗甯?ProfileHeader + StatsBox + MenuItemRow閿涘瞼顓搁悶鍡欑埠鐠佲剝鏆熼幑顔衡偓?//  閺佺増宓佸ù? @State notes/avg 閳?StatsBox @Prop閿涘矁褰嶉崡鏇氱皑娴?閳?toast/router閵?//  娓氭繆绂?
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
    // TODO: 娴?RDB 閸旂姾娴囬惇鐔风杽缂佺喕顓搁弫鐗堝祦
  }

  private todayNew(): number { return 3 }

  private toast(msg: string): void {
    promptAction.showToast({ message: msg, duration: 2000, bottom: "50%" })
  }

  build() {
    Scroll() {
      Column() {
        // 閻樿埖鈧焦鐖?        Row().width("100%").height(this.sbh).backgroundColor(BG_DARK)

        // 婢舵潙鍎氶崠?        ProfileHeader()

        // 缂佺喕顓哥悰?        Row() {
          StatsBox({ value: this.notes + "", label: "缁楁棁顔? })
          StatsBox({ value: this.avg + "%", label: "閹哄本褰欓悳? })
          StatsBox({ value: this.todayNew() + "", label: "娴犲﹥妫╅弬鏉款杻" })
        }
        .width("100%")
        .padding({ left: S_4, right: S_4, bottom: S_4 })
        .justifyContent(FlexAlign.SpaceEvenly)

        // 閼挎粌宕?        Column() {
          MenuItemRow({ icon: "棣冩惖", label: "閹存垹娈戞径宥勭瘎鐠佲€冲灊", onTap: (): void => this.toast("婢跺秳绡勭拋鈥冲灊瀵偓閸欐垳鑵?) })
          MenuItemRow({ icon: "棣冩憙", label: "闁挎瑩顣介張?, onTap: (): void => this.toast("闁挎瑩顣介張顒€绱戦崣鎴滆厬") })
          MenuItemRow({ icon: "鐚?, label: "閹存垹娈戦弨鎯版", onTap: (): void => this.toast("閺€鎯版閸旂喕鍏樺鈧崣鎴滆厬") })
          MenuItemRow({ icon: "棣冾樆", label: "濡€崇€?, onTap: (): void => { router.pushUrl({ url: "pages/AiSettings/AiSettingsPage" }) } })
          MenuItemRow({ icon: "棣冩瘑", label: "閸掑洦宕茬拹锕€褰?, onTap: (): void => this.toast("閸掑洦宕茬拹锕€褰垮鈧崣鎴滆厬") })
        }
        .width("100%")
        .backgroundColor(BG_CARD)
        .borderRadius(R_LG)
        .margin({ left: S_4, right: S_4, top: S_2 })

        // 闁偓閸戣櫣娅ヨぐ?        Button("闁偓閸戣櫣娅ヨぐ?)
          .fontSize(F_SM)
          .fontColor(DANGER)
          .width("100%").height(S_6 * 2 - S_1)
          .backgroundColor(GLASS_8)
          .borderRadius(R_FULL)
          .margin({ left: S_4, right: S_4, top: S_6, bottom: S_6 * 2 - S_2 })
          .onClick((): void => this.toast("闁偓閸戣櫣娅ヨぐ鏇炲閼宠棄绱戦崣鎴滆厬"))

        Blank().height(80)
      }
      .width("100%")
    }
    .width("100%").height("100%")
    .backgroundColor(BG_DARK)
    .scrollBar(BarState.Off)
  }
}
