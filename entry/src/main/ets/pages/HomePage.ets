/**
 * MathMind 首页
 * 严格对照 iOS Web MVP: styles.css Hero/.note-card/.fab/progress-ring
 *                      + app.js updateHome() / noteCardHTML()
 *
 * W2 原子化 (2026-07-15): GradientRing / StatsBox / NoteCard 抽取独立组件
 */

import {
  MINT,
  MINT_DARK,
  PURPLE,
  BG_DARK,
  BORDER,
  TEXT,
  TEXT_2,
  TEXT_3,
  S_1,
  S_2,
  R_MD,
  R_2XL,
  F_XS,
  F_SM,
  F_BASE,
  F_MD,
  F_XL,
} from "common"
import { promptAction } from "@kit.ArkUI"
import { NoteItem, NOTES } from "common"
import { NoteDetailOverlay } from "../prototypes/NoteDetailOverlay"
import { NoteCard } from "../molecules/NoteCard"
import { GradientRing } from "../atoms/GradientRing"
import { StatsBox } from "../atoms/StatsBox"
import { HexLogo } from "../atoms/HexLogo"

// ---- 本地工具函数 ----
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

// ========== 首页主组件 ==========
@Component
export struct HomePage {
  @StorageProp("statusBarHeight") sbh: number = 0
  @State notes: NoteItem[] = NOTES
  @State g: string = ""
  @State d: string = ""
  @State avg: number = 75
  @State today: number = 0
  @State selectedNote: NoteItem | null = null

  closeDetail = (): void => { this.selectedNote = null }
  onGoCamera: () => void = (): void => {}
  onGoReview: () => void = (): void => {}

  aboutToAppear(): void {
    this.g = greet()
    this.d = dateStr()
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
        // ---- 状态栏占位 ----
        Row().width("100%").height(this.sbh).backgroundColor(BG_DARK)

        // ---- Header 60vp ----
        Row() {
          HexLogo()
          Text("MathMind")
            .fontFamily("HarmonyOS Sans Condensed")
            .fontSize(18)
            .fontWeight(500)
            .fontColor(TEXT)
            .letterSpacing(0)
            .margin({ left: S_2 })
        }
        .width("100%").height(60)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor(BG_DARK)

        // ---- Hero 区 ----
        Column() {
          // 问候行
          Row() {
            Circle({ width: 6, height: 6 }).fill(MINT)
            Text(this.g + ", Mini")
              .fontSize(F_XL).fontWeight(600)
              .fontColor(TEXT)
              .margin({ left: 6 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width("100%")
          .alignItems(VerticalAlign.Center)

          Text(this.d)
            .fontSize(F_SM).fontColor(TEXT_3)
            .width("100%")
            .textAlign(TextAlign.Start)
            .margin({ top: 4 })

          // 进度环
          Stack() {
            GradientRing({ pct: this.avg })
            Column() {
              Text(this.avg + "%")
                .fontSize(26).fontWeight(700).fontColor(TEXT)
              Text("去复习 >")
                .fontSize(F_XS).fontColor(MINT).fontWeight(600)
                .margin({ top: 4 })
            }.alignItems(HorizontalAlign.Center)
          }
          .width(120).height(120)
          .alignSelf(ItemAlign.Center)
          .margin({ top: 16 })
          .onClick((): void => this.onGoReview())

          // 3 统计方块
          Row() {
            StatsBox({ value: this.notes.length + "", label: "笔记" })
            StatsBox({ value: this.avg + "%", label: "掌握率" })
            StatsBox({ value: this.today + "", label: "今日新增" })
          }
          .width("100%").justifyContent(FlexAlign.SpaceEvenly).margin({ top: 14 })
        }
        .width("100%")
        .padding({ left: 20, right: 20, top: 16, bottom: 20 })
        .borderRadius({ bottomLeft: R_2XL, bottomRight: R_2XL })
        .linearGradient({
          angle: 180,
          colors: [
            ["#2E5BE3B0", 0],
            ["#2E9775FA", 0.5],
            ["#1AFF6B9D", 1],
          ],
        })

        // ---- 提醒横幅 ----
        if (this.notes.length < 3) {
          Row() {
            Text(this.notes.length === 0
              ? "👋 欢迎使用 MathMind！试试 AI 对话或拍照，帮你整理知识笔记 >"
              : "⏰ 已有 " + this.notes.length + " 条笔记，继续用 AI 充实知识库 >")
              .fontSize(F_SM).fontColor(MINT).lineHeight(18)
          }
          .width("100%")
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .margin({ left: 16, right: 16, top: S_1 })
          .borderRadius(R_MD)
          .linearGradient({
            angle: 135,
            colors: [["#1F5BE3B0", 0], ["#0D9775FA", 1]],
          })
          .border({ width: 1, color: "#335BE3B0" })
        }

        // ---- 最近笔记标题 ----
        Text("最近笔记")
          .fontSize(F_BASE).fontWeight(600).fontColor(TEXT)
          .width("100%")
          .padding({ left: 20, right: 20, top: S_1, bottom: S_1 })
          .margin({ top: S_1 })

        // ---- 笔记列表 ----
        Scroll() {
          Column() {
            ForEach(this.notes,
              (note: NoteItem): string => note.id.toString(),
              (note: NoteItem, i: number): void => {
                NoteCard({
                  note: note,
                  isLast: i === this.notes.length - 1,
                  onClick: (): void => { this.selectedNote = note },
                })
              }
            )
            Blank().height(48)
          }
          .width("100%")
          .padding({ left: 20, right: 20, top: 14, bottom: 20 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width("100%").height("100%")
      .backgroundColor(BG_DARK)

      // ---- FAB ----
      Stack() {
        Text("+")
          .fontSize(22)
          .fontColor("#FF0A0C10")
          .fontWeight(FontWeight.Bold)
      }
      .width(54).height(54)
      .borderRadius(27)
      .linearGradient({ angle: 180, colors: [[MINT, 0], [MINT_DARK, 1]] })
      .shadow({ radius: 28, color: "#595BE3B0", offsetX: 0, offsetY: 8 })
      .margin({ right: 20, bottom: 16 })
      .onClick((): void => {
        promptAction.showToast({ message: "用户自定义笔记开发中", duration: 1500 })
      })

      // ---- NoteDetailOverlay ----
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
