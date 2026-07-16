// ============================================================================
//  pages/HomePage.ets 鈥?棣栭〉瑁呴厤灞?//  ----------------------------------------------------------------------------
//  鑱岃矗: 缂栨帓瀛愮粍浠讹紝鏃犲唴鑱?UI銆傜鐞?notes 鏁版嵁鐘舵€佸苟鍚戜笅浼犻€掋€?//  鏁版嵁娴? @State notes 鈫?@Prop 鍒嗗彂缁?HeroBanner / ReminderBanner / NoteCard銆?//  渚濊禆:
//    atoms:     HexLogo, FloatingButton
//    molecules: HeroBanner, ReminderBanner, NoteCard
//    prototypes: NoteDetailOverlay
//  ============================================================================

import {
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

// ---- 绾伐鍏峰嚱鏁?----

function greet(): string {
  const h: number = new Date().getHours()
  if (h < 6) { return "鍑屾櫒濂? }
  if (h < 11) { return "涓婂崍濂? }
  if (h < 13) { return "涓崍濂? }
  if (h < 18) { return "涓嬪崍濂? }
  return "鏅氫笂濂?
}

function dateStr(): string {
  const d: Date = new Date()
  const w: string[] = ["鏃?, "涓€", "浜?, "涓?, "鍥?, "浜?, "鍏?]
  return d.getFullYear() + "骞? + (d.getMonth() + 1) + "鏈? + d.getDate() + "鏃?路 鍛? + w[d.getDay()]
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
        // 鐘舵€佹爮
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

        // 鎻愰啋妯箙
        if (this.notes.length < 3) {
          ReminderBanner({ notesCount: this.notes.length })
        }

        // 绗旇鏍囬
        Row() {
          Text("鏈€杩戠瑪璁?)
            .fontSize(F_BASE).fontWeight(W_SEMIBOLD).fontColor(TEXT)
          Blank()
          Text(this.notes.length + " 鏉?)
            .fontSize(F_XS).fontColor(TEXT_3)
        }
        .width("100%")
        .padding({ left: S_5, right: S_5, top: S_4, bottom: S_2 })

        // 绗旇鍒楄〃
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
          promptAction.showToast({ message: "鐢ㄦ埛鑷畾涔夌瑪璁板紑鍙戜腑", duration: 1500 })
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
