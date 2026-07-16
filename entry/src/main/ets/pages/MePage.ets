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
  MINT, BG_DARK, BG_CARD, TEXT_3,
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
    // TODO: 从 RDB 加载真实统计数据
  }

  private todayNew(): number { return 3 }

  private toast(msg: string): void {
    promptAction.showToast({ message: msg, duration: 2000, bottom: "50%" })
  }

  build() {
    Scroll() {
      Column() {
        // 状态栏
        Row().width("100%").height(this.sbh).backgroundColor(BG_DARK)

        // 头像区
        ProfileHeader()

        // 统计行
        Row() {
          StatsBox({ value: this.notes + "", label: "笔记" })
          StatsBox({ value: this.avg + "%", label: "掌握率" })
          StatsBox({ value: this.todayNew() + "", label: "今日新增" })
        }
        .width("100%")
        .padding({ left: S_4, right: S_4, bottom: S_4 })
        .justifyContent(FlexAlign.SpaceEvenly)

        // 菜单
        Column() {
          MenuItemRow({ icon: "📋", label: "我的复习计划", onTap: (): void => this.toast("复习计划开发中") })
          MenuItemRow({ icon: "📕", label: "错题本", onTap: (): void => this.toast("错题本开发中") })
          MenuItemRow({ icon: "⭐", label: "我的收藏", onTap: (): void => this.toast("收藏功能开发中") })
          MenuItemRow({ icon: "🤖", label: "模型", onTap: (): void => { router.pushUrl({ url: "pages/AiSettings/AiSettingsPage" }) } })
          MenuItemRow({ icon: "🚪", label: "切换账号", onTap: (): void => this.toast("切换账号开发中") })
        }
        .width("100%")
        .backgroundColor(BG_CARD)
        .borderRadius(R_LG)
        .margin({ left: S_4, right: S_4, top: S_2 })

        // 退出登录
        Button("退出登录")
          .fontSize(F_SM)
          .fontColor(DANGER)
          .width("100%").height(44)
          .backgroundColor(GLASS_8)
          .borderRadius(R_FULL)
          .margin({ left: S_4, right: S_4, top: S_6, bottom: S_6 * 2 - S_2 })
          .onClick((): void => this.toast("退出登录功能开发中"))

        Blank().height(80)
      }
      .width("100%")
    }
    .width("100%").height("100%")
    .backgroundColor(BG_DARK)
    .scrollBar(BarState.Off)
  }
}
