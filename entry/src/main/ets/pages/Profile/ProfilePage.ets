// ============================================================================
//  pages/Profile/ProfilePage.ets — 我的页装配层
//  ----------------------------------------------------------------------------
//  职责: 拼装"我的"页所有视觉组件,管理数据统计 + 退出登录交互。
//
//  数据流:
//    aboutToAppear → loadStats() (从 RDB 读 KnowledgeUnit → 算 notes/avg/today)
//    退出登录按钮 → toast 提示(W2 计划接入)
//
//  统计计算:
//    notes:  RDB 总数
//    today:  createdAt 在今天 0 点到 24 点之间的笔记数
//    avg:    按 reviewStatus 加权(GRADUATED=95 / REVIEW=86 / LEARNING=72 /
//            LAPSED=45 / 其他=64),求平均后取整
//
//  依赖:
//    pages:    ProfileHeader / ProfileStatsRow / ProfileMenuList
//    database: NoteDao + DatabaseHelper
//  ============================================================================

import {
  BG_DARK,
  S_1, S_4, S_6,
  R_FULL,
  F_SM,
  GLASS_8,
  DANGER,
  KnowledgeUnit,
  ReviewStatus,
  DatabaseHelper,
} from "common"
import { promptAction } from "@kit.ArkUI"
import { ProfileHeader } from "./ProfileHeader"
import { ProfileStatsRow } from "./ProfileStatsRow"
import { ProfileMenuList } from "./ProfileMenuList"
import { NoteDao } from "../../database/NoteDao"

@Component
export struct ProfilePage {
  // 状态栏高度(沉浸式占位)
  @StorageProp("statusBarHeight") sbh: number = 0

  // 统计 3 项
  @State notes: number = 0
  @State avg: number = 0
  @State today: number = 0

  aboutToAppear(): void {
    this.loadStats()
  }

  // Toast 工具(失败安全)
  private toast(msg: string): void {
    try {
      promptAction.showToast({ message: msg, duration: 2000, bottom: "50%" })
    } catch (e) { /* toast 失败忽略 */ }
  }

  // 加载统计
  private loadStats = async (): Promise<void> => {
    try {
      const store = await DatabaseHelper.init(getContext(this))
      const units: KnowledgeUnit[] = await new NoteDao(store).queryAll()
      this.notes = units.length
      this.today = this.countToday(units)
      this.avg = this.calcAvg(units)
    } catch (e) {
      // 降级: 数据库未初始化时全 0
      this.notes = 0
      this.avg = 0
      this.today = 0
      this.toast("统计加载失败")
    }
  }

  // 计算今日新增笔记数
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

  // 按 reviewStatus 加权算掌握率
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
        // 状态栏占位
        Row()
          .width("100%")
          .height(this.sbh)
          .backgroundColor(BG_DARK)

        // 头像区
        ProfileHeader()

        // 统计方块行
        ProfileStatsRow({ notes: this.notes, avg: this.avg, today: this.today })

        // 5 菜单
        ProfileMenuList({ onToast: (message: string): void => this.toast(message) })

        // 退出登录按钮(W2 计划接入)
        Button("退出登录")
          .fontSize(F_SM)
          .fontColor(DANGER)
          .width("100%")
          .height(S_6 * 2 - S_1)
          .backgroundColor(GLASS_8)
          .borderRadius(R_FULL)
          .margin({ left: S_4, right: S_4, top: S_6, bottom: S_6 * 2 - S_1 })
          .onClick((): void => this.toast("退出登录功能开发中"))

        // FAB 底部留白
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
