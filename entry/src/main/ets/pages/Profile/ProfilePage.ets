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
      this.toast("\u7edf\u8ba1\u52a0\u8f7d\u5931\u8d25")
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
        Row().width("100%").height(this.sbh).backgroundColor(BG_DARK)
        ProfileHeader()
        ProfileStatsRow({ notes: this.notes, avg: this.avg, today: this.today })
        ProfileMenuList({ onToast: (message: string): void => this.toast(message) })

        Button("\u9000\u51fa\u767b\u5f55")
          .fontSize(F_SM)
          .fontColor(DANGER)
          .width("100%").height(S_6 * 2 - S_1)
          .backgroundColor(GLASS_8)
          .borderRadius(R_FULL)
          .margin({ left: S_4, right: S_4, top: S_6, bottom: S_6 * 2 - S_1 })
          .onClick((): void => this.toast("\u9000\u51fa\u767b\u5f55\u529f\u80fd\u5f00\u53d1\u4e2d"))

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