/**
 * MathMind 首页
 * W3 UI 优化 (2026-07-15): Hero 视觉层次提升、全量令牌化、间距统一
 */

import {
  MINT, MINT_DARK, MINT_LIGHT, PURPLE, PURPLE_LIGHT, PINK,
  BG_DARK, BORDER, TEXT, TEXT_2, TEXT_3,
  S_1, S_2, S_4, S_5, S_6,
  R_MD, R_2XL,
  F_XS, F_SM, F_BASE, F_MD, F_XL, F_2XL,
  W_MEDIUM, W_SEMIBOLD, W_BOLD,
  SHADOW_FAB,
} from "common"
import { promptAction } from "@kit.ArkUI"
import { NoteItem, NOTES } from "common"
import { NoteDetailOverlay } from "../prototypes/NoteDetailOverlay"
import { NoteCard } from "../molecules/NoteCard"
import { GradientRing } from "../atoms/GradientRing"
import { StatsBox } from "../atoms/StatsBox"
import { HexLogo } from "../atoms/HexLogo"

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
        // ---- 状态栏 ----
        Row().width("100%").height(this.sbh).backgroundColor(BG_DARK)

        // ---- Header ----
        Row() {
          HexLogo()
          Text("MathMind")
            .fontFamily("HarmonyOS Sans Condensed")
            .fontSize(F_MD + 2)
            .fontWeight(W_MEDIUM)
            .fontColor(TEXT)
            .margin({ left: S_2 })
        }
        .width("100%").height(60)
        .padding({ left: S_4, right: S_4 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor(BG_DARK)

        // ---- Hero 区 ----
        Column() {
          // 问候行：绿点 + 更大字号 + 更粗字重
          Row() {
            Circle({ width: 8, height: 8 }).fill(MINT)
            Text(this.g + ", Mini")
              .fontSize(F_2XL).fontWeight(W_BOLD)
              .fontColor(TEXT)
              .margin({ left: S_2 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width("100%")
          .alignItems(VerticalAlign.Center)

          // 日期：稍大字号
          Text(this.d)
            .fontSize(F_BASE).fontColor(TEXT_3)
            .width("100%")
            .margin({ top: S_2 })

          // 进度环：居中 + 更大圈
          Stack() {
            GradientRing({ pct: this.avg })
            Column() {
              Text(this.avg + "%")
                .fontSize(F_2XL).fontWeight(W_BOLD).fontColor(TEXT)
              Text("去复习 >")
                .fontSize(F_SM).fontColor(MINT).fontWeight(W_SEMIBOLD)
                .margin({ top: S_1 })
            }.alignItems(HorizontalAlign.Center)
          }
          .width(120).height(120)
          .alignSelf(ItemAlign.Center)
          .margin({ top: S_6 })
          .onClick((): void => this.onGoReview())

          // 统计方块：间距加大
          Row() {
            StatsBox({ value: this.notes.length + "", label: "笔记" })
            StatsBox({ value: this.avg + "%", label: "掌握率" })
            StatsBox({ value: this.today + "", label: "今日新增" })
          }
          .width("100%").justifyContent(FlexAlign.SpaceEvenly).margin({ top: S_5 })
        }
        .width("100%")
        .padding({ left: S_5, right: S_5, top: S_5, bottom: S_6 })
        .borderRadius({ bottomLeft: R_2XL, bottomRight: R_2XL })
        // 令牌化渐变：MINT_LIGHT→PURPLE_LIGHT→PINK 透明度阶梯
        .linearGradient({
          angle: 180,
          colors: [
            [MINT_LIGHT, 0],
            [PURPLE_LIGHT, 0.5],
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
          .padding({ left: S_4, right: S_4, top: S_3, bottom: S_3 })
          .margin({ left: S_4, right: S_4, top: S_2 })
          .borderRadius(R_MD)
          .linearGradient({
            angle: 135,
            colors: [[MINT_LIGHT, 0], [PURPLE_LIGHT, 1]],
          })
          .border({ width: 1, color: MINT_LIGHT })
        }

        // ---- 最近笔记标题 ----
        Row() {
          Text("最近笔记")
            .fontSize(F_BASE).fontWeight(W_SEMIBOLD).fontColor(TEXT)
          Blank()
          Text(this.notes.length + " 条")
            .fontSize(F_XS).fontColor(TEXT_3)
        }
        .width("100%")
        .padding({ left: S_5, right: S_5, top: S_4, bottom: S_2 })

        // ---- 笔记列表 ----
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

      // ---- FAB (使用 SHADOW_FAB 预设) ----
      Stack() {
        Text("+")
          .fontSize(22)
          .fontColor(BG_DARK)
          .fontWeight(FontWeight.Bold)
      }
      .width(54).height(54)
      .borderRadius(27)
      .linearGradient({ angle: 180, colors: [[MINT, 0], [MINT_DARK, 1]] })
      .shadow(SHADOW_FAB)
      .margin({ right: S_5, bottom: S_4 })
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
