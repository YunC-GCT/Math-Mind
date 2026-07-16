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
  KnowledgeUnit,
  ReviewStatus,
  DatabaseHelper,
} from "common"
import { promptAction, router } from "@kit.ArkUI"
import { ProfileHeader } from "../molecules/ProfileHeader"
import { StatsBox } from "../atoms/StatsBox"
import { MenuItemRow } from "../atoms/MenuItemRow"
import { NoteDao } from "../database/NoteDao"

@Component
export struct MePage {
  @StorageProp("statusBarHeight") sbh: number = 0
  @State notes: number = 0
  @State avg: number = 0
  @State today: number = 0

  aboutToAppear(): void {
    this.loadStats()
  }

  private toast(msg: string): void {
    try { promptAction.showToast({ message: msg, duration: 2000, bottom: "50%" }) } catch (e) {}
  }

  private loadStats = async (): Promise<void> => {
    try {
      const store = await DatabaseHelper.init(getContext(this))
      const units: KnowledgeUnit[] = await new NoteDao(store).queryAll()
      this.notes = units.length
      this.today = this.countToday(units)
      this.avg = this.calcAvg(units)
    } catch (e) {
      this.notes = 0
      this.avg = 0
      this.today = 0
      this.toast("统计加载失败")
    }
  }

  private countToday(units: KnowledgeUnit[]): number {
    const now: Date = new Date()
    const start: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    const startMs: number = start.getTime()
    const endMs: number = startMs + 86400000
    let count: number = 0
    for (const unit of units) {
      if (unit.createdAt >= startMs && unit.createdAt < endMs) {
        count++
      }
    }
    return count
  }

  private calcAvg(units: KnowledgeUnit[]): number {
    if (units.length === 0) { return 0 }
    let total: number = 0
    for (const unit of units) {
      if (unit.reviewStatus === ReviewStatus.GRADUATED) { total += 95 }
      else if (unit.reviewStatus === ReviewStatus.REVIEW) { total += 86 }
      else if (unit.reviewStatus === ReviewStatus.LEARNING) { total += 72 }
      else if (unit.reviewStatus === ReviewStatus.LAPSED) { total += 45 }
      else { total += 64 }
    }
    return Math.round(total / units.length)
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
          StatsBox({ value: this.today + "", label: "今日新增" })
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
          .width("100%").height(S_6 * 2 - S_1)
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
