// ============================================================================
//  pages/HomePage.ets — 首页装配层
//  ----------------------------------------------------------------------------
//  职责: 编排子组件，无内联 UI。管理 notes 数据状态并向下传递。
//  数据流: @State notes → @Prop 分发给 HeroBanner / ReminderBanner / NoteCard。
//  依赖:
//    atoms:     HexLogo, FloatingButton
//    molecules: HeroBanner, ReminderBanner, NoteCard
//    prototypes: NoteDetailOverlay
//  ============================================================================

import {
  MINT, MINT_LIGHT, PURPLE_LIGHT, PINK_LIGHT,
  BG_DARK, TEXT, TEXT_3,
  S_2, S_3, S_4, S_5,
  F_XS, F_BASE, F_MD,
  W_MEDIUM, W_SEMIBOLD,
  HEADER_H,
  NoteItem, NOTES,
} from "common"
import { promptAction } from "@kit.ArkUI"
import { HexLogo } from "../atoms/HexLogo"
import { FloatingButton } from "../atoms/FloatingButton"
import { HeroBanner } from "../molecules/HeroBanner"
import { ReminderBanner } from "../molecules/ReminderBanner"
import { NoteCard } from "../molecules/NoteCard"
import { NoteDetailOverlay } from "../prototypes/NoteDetailOverlay"

// ---- 纯工具函数 ----

function greet(): string {
  const h: number = new Date().getHours()
  if (h < 6) { return "凌晨好" }
  if (h < 11) { return "上午好" }
  if (h < 13) { return "中午好" }
  if (h < 18) { return "下午好" }
  return "晚上好"
}

function dateStr(): string {
  const d: Date = new Date()
  const w: string[] = ["日", "一", "二", "三", "四", "五", "六"]
  return d.getFullYear() + "年" + (d.getMonth() + 1) + "月" + d.getDate() + "日 · 周" + w[d.getDay()]
}

@Component
export struct HomePage {
  @StorageProp("statusBarHeight") sbh: number = 0
  @State notes: NoteItem[] = NOTES
  @State greeting: string = ""
  @State dateText: string = ""
  @State avg: number = 75
  @State today: number = 0
  @State selectedNote: NoteItem | null = null

  onGoCamera: () => void = (): void => {}
  onGoReview: () => void = (): void => {}

  aboutToAppear(): void {
    this.greeting = greet()
    this.dateText = dateStr()
    this.avg = this.notes.length > 0
      ? Math.round(this.notes.reduce((a: number, n: NoteItem): number => a + n.conf, 0) / this.notes.length * 100)
      : 75
    const now: Date = new Date()
    const ts: string = now.getFullYear() + "-" +
      String(now.getMonth() + 1).padStart(2, "0") + "-" +
      String(now.getDate()).padStart(2, "0")
    this.today = this.notes.filter((n: NoteItem): boolean => n.date === ts).length
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 状态栏
        Row().width("100%").height(this.sbh).backgroundColor(BG_DARK)

        // Header
        Row() {
          HexLogo()
          Text("MathMind")
            .fontFamily("HarmonyOS Sans Condensed")
            .fontSize(F_MD + 2).fontWeight(W_MEDIUM).fontColor(TEXT)
            .margin({ left: S_2 })
        }
        .width("100%").height(HEADER_H)
        .padding({ left: S_4, right: S_4 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor(BG_DARK)

        // Hero
        HeroBanner({
          greeting: this.greeting,
          dateText: this.dateText,
          avg: this.avg,
          notesCount: this.notes.length,
          todayCount: this.today,
          onGoReview: (): void => { this.onGoReview() },
        })

        // 提醒横幅
        if (this.notes.length < 3) {
          ReminderBanner({ notesCount: this.notes.length })
        }

        // 笔记标题
        Row() {
          Text("最近笔记")
            .fontSize(F_BASE).fontWeight(W_SEMIBOLD).fontColor(TEXT)
          Blank()
          Text(this.notes.length + " 条")
            .fontSize(F_XS).fontColor(TEXT_3)
        }
        .width("100%")
        .padding({ left: S_5, right: S_5, top: S_4, bottom: S_2 })

        // 笔记列表
        Scroll() {
          Column() {
            ForEach(this.notes,
              (note: NoteItem, i: number): void => {
                NoteCard({
                  note: note,
                  isLast: i === this.notes.length - 1,
                  onTap: (): void => { this.selectedNote = note },
                })
              },
              (note: NoteItem): string => note.id.toString()
            )
            Blank().height(48)
          }
          .width("100%")
          .padding({ left: S_5, right: S_5, top: S_3, bottom: S_5 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width("100%").height("100%")
      .backgroundColor(BG_DARK)

      // FAB
      FloatingButton({
        onTap: (): void => {
          promptAction.showToast({ message: "用户自定义笔记开发中", duration: 1500 })
        },
      })

      // NoteDetailOverlay
      if (this.selectedNote !== null) {
        NoteDetailOverlay({
          note: this.selectedNote!,
          onClose: (): void => { this.selectedNote = null },
        })
      }
    }
    .width("100%").height("100%").backgroundColor(BG_DARK)
  }
}
