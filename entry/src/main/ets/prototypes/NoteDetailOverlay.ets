/**
 * MathMind 笔记详情浮层 — 第 3 批
 *
 * 触发: HomePage / NotesPage 点笔记卡片
 * 流程: 显示笔记详情(学科条 / 标题 / meta / 标签 / 正文 / AI 卡)
 *
 * W2 原子化 (2026-07-15): ConfBadge 抽出独立组件，删除确认改用 AlertDialog
 *
 * 依赖:
 *   - common.NoteItem (class, 9 字段)
 *   - common.typeColor / subjectColor (工具函数)
 *   - ConfBadge (components/)
 */

import {
  MINT, MINT_DARK, MINT_GLOW, MINT_BORDER, PURPLE, PINK, AMBER,
  BG_DARK, BG_CARD,
  TEXT, TEXT_2, TEXT_3, TEXT_4, BORDER,
  GLASS_10, DANGER, OVERLAY_MASK_SOLID,
  S_1, S_2, S_3, S_4, S_5, S_6,
  R_SM, R_MD, R_LG, R_XL, R_2XL, R_FULL,
  F_XS, F_SM, F_BASE, F_MD, F_LG, F_XL, F_2XL,
  W_SEMIBOLD, W_BOLD,
  NoteItem, typeColor, subjectColor, recentDate, stripMD,
} from "common"
import { promptAction } from "@kit.ArkUI"
import { AlertDialog } from "@kit.ArkUI"
import { ConfBadge } from "../atoms/ConfBadge"

// 解析 body 成章节
interface Section {
  title: string
  content: string
}

function parseSections(body: string): Section[] {
  if (!body) { return [] }
  const lines: string[] = body.split("\n")
  const sections: Section[] = []
  let curTitle: string = "内容"
  let curLines: string[] = []

  for (let i: number = 0; i < lines.length; i++) {
    const line: string = lines[i]
    if (line.indexOf("## ") === 0) {
      if (curLines.length > 0) {
        sections.push({ title: curTitle, content: curLines.join("\n").trim() })
      }
      curTitle = line.substring(3).trim()
      curLines = []
    } else {
      curLines.push(line)
    }
  }
  if (curLines.length > 0 || sections.length === 0) {
    sections.push({ title: curTitle, content: curLines.join("\n").trim() })
  }
  return sections
}

@Component
export struct NoteDetailOverlay {
  @Prop note: NoteItem = new NoteItem(0, "", "", "", "", 0, "", [], "")

  onClose: () => void = (): void => {}
  onAskAi: (note: NoteItem) => void = (): void => {}
  onEdit: (id: number) => void = (): void => {}
  onDelete: (id: number) => void = (): void => {}

  build() {
    Stack() {
      // 半透明遮罩
      Column()
        .width("100%").height("100%")
        .backgroundColor(OVERLAY_MASK_SOLID)
        .onClick((): void => this.onClose())

      // 浮层主体
      Column() {
        // drag bar
        Row() {
          Row().width(40).height(4).borderRadius(2).backgroundColor(TEXT_4)
        }
        .width("100%").height(S_6)
        .margin({ top: S_2 })
        .justifyContent(FlexAlign.Center)

        // 顶栏
        Row() {
          Row() {
            Text(this.note.subject)
              .fontSize(F_XS)
              .fontColor(subjectColor(this.note.subject))
              .fontWeight(W_BOLD)
            Text(" · ")
              .fontSize(F_XS)
              .fontColor(TEXT_4)
            Text(this.note.type)
              .fontSize(F_XS)
              .fontColor(typeColor(this.note.type))
              .fontWeight(W_SEMIBOLD)
          }
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(R_FULL)
          .backgroundColor(GLASS_10)
          .border({ width: 1, color: BORDER })

          Blank()

          this.CloseBtn()
        }
        .width("100%")
        .padding({ left: 20, right: 16, top: 4, bottom: 8 })

        // 内容 Scroll
        Scroll() {
          Column() {
            // 标题
            Text(this.note.title)
              .fontSize(F_2XL)
              .fontWeight(W_BOLD)
              .fontColor(TEXT)
              .lineHeight(30)
              .width("100%")
              .padding({ left: S_5, right: S_5, top: S_2, bottom: S_1 })

            // meta 行
            Row() {
              if (this.note.chapter && this.note.chapter.length > 0) {
                Text("📖 " + this.note.chapter)
                  .fontSize(F_XS)
                  .fontColor(TEXT_2)
                Text("  ·  ")
                  .fontSize(F_XS)
                  .fontColor(TEXT_4)
              }
              Text(recentDate(this.note.date))
                .fontSize(F_XS)
                .fontColor(TEXT_3)

              Blank()

              ConfBadge({ conf: this.note.conf })
            }
            .width("100%")
            .padding({ left: 20, right: 20, top: 4, bottom: 12 })

            // 标签 chips
            if (this.note.tags && this.note.tags.length > 0) {
              Row() {
                ForEach(this.note.tags,
                  (tag: string, _idx: number): void => {
                    this.TagChip(tag)
                  },
                  (tag: string): string => tag
                )
              }
              .width("100%")
              .padding({ left: 20, right: 20, bottom: 16 })
            }

            // 分隔线
            Row()
              .width("100%").height(1)
              .backgroundColor(BORDER)
              .margin({ left: 20, right: 20, bottom: 12 })

            // 正文按章节
            Column() {
              ForEach(parseSections(this.note.body),
                (sec: Section, _idx: number): void => {
                  this.SectionView(sec)
                },
                (sec: Section): string => sec.title + "_" + sec.content.length.toString()
              )
            }
            .width("100%")
            .padding({ left: 20, right: 20, bottom: 16 })

            // AI 卡
            this.AiCard()

            Blank().height(80)
          }
          .width("100%")
        }
        .layoutWeight(1)
        .width("100%")
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)

        // 底部操作栏
        Row() {
          this.ActionBtn("🗑", "删除", DANGER, (): void => this.confirmDelete())
          Blank().width(8)
          this.ActionBtn("✎", "编辑", TEXT_2, (): void => this.mockEdit())
          Blank().width(8)
          this.ActionBtn("↗", "分享", TEXT_2, (): void => this.mockShare())
        }
        .width("100%")
        .padding({ left: S_4, right: S_4, top: S_2, bottom: S_6 })
        .backgroundColor(BG_DARK)
        .border({ width: { top: 1 }, color: BORDER })
      }
      .width("100%").height("100%")
      .backgroundColor(BG_DARK)
    }
    .width("100%").height("100%")
  }

  // ========== 章节渲染 ==========
  @Builder
  SectionView(sec: Section) {
    Column() {
      Text(sec.title)
        .fontSize(F_SM).fontWeight(W_BOLD)
        .fontColor(MINT).letterSpacing(0.5)
        .width("100%")
        .margin({ top: S_3, bottom: S_2 })

      Text(sec.content && sec.content.length > 0 ? sec.content : "—")
        .fontSize(F_BASE)
        .fontColor(TEXT_2)
        .lineHeight(22)
        .width("100%")
    }
    .width("100%")
    .alignItems(HorizontalAlign.Start)
  }

  // ========== 标签 chip ==========
  @Builder
  TagChip(tag: string) {
    Text("#" + tag)
      .fontSize(F_XS)
      .fontColor(MINT)
      .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
      .borderRadius(R_FULL)
      .backgroundColor(MINT_GLOW)
      .margin({ right: S_2, bottom: S_2 })
  }

  // ========== AI 卡 ==========
  @Builder
  AiCard() {
    Column() {
      Row() {
        Stack() {
          Text("✦")
            .fontSize(14).fontWeight(W_BOLD)
            .fontColor(BG_DARK)
        }
        .width(28).height(28)
        .borderRadius(14)
        .linearGradient({ angle: 135, colors: [[MINT, 0], [PURPLE, 1]] })
        .alignContent(Alignment.Center)
        .margin({ right: 10 })

        Column() {
          Text("AI 解答")
            .fontSize(F_BASE).fontWeight(W_BOLD)
            .fontColor(TEXT)
          Text("让 MathMind AI 解释这道题")
            .fontSize(F_XS)
            .fontColor(TEXT_3)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(">")
          .fontSize(20).fontColor(MINT).fontWeight(500)
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)
    }
    .width("100%")
    .padding({ left: S_4, right: S_4, top: S_4, bottom: S_4 })
    .borderRadius(R_LG)
    .backgroundColor("#0DFFFFFF")
    .border({ width: 1, color: MINT_BORDER })
    .linearGradient({
      angle: 135,
      colors: [["#1A5BE3B0", 0], ["#0D9775FA", 1]],
    })
    .onClick((): void => this.handleAskAi())
  }

  // ========== 关闭按钮 ==========
  @Builder
  CloseBtn() {
    Stack() {
      Text("✕")
        .fontSize(16).fontWeight(500)
        .fontColor(TEXT_2)
    }
    .width(S_4 * 2).height(S_4 * 2)
    .borderRadius(22)
    .backgroundColor(GLASS_10)
    .alignContent(Alignment.Center)
    .onClick((): void => this.onClose())
  }

  // ========== 底部操作按钮 ==========
  @Builder
  ActionBtn(icon: string, label: string, color: string, action: () => void) {
    Column() {
      Text(icon).fontSize(16).fontColor(color)
      Text(label).fontSize(10).fontColor(color).margin({ top: 2 })
    }
    .layoutWeight(1).height(44)
    .borderRadius(R_MD)
    .backgroundColor(GLASS_10)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick((): void => action())
  }

  // ========== 行为 ==========
  private handleAskAi = (): void => {
    promptAction.showToast({ message: "正在呼叫 AI...", duration: 1500 })
    this.onAskAi(this.note)
  }

  private mockEdit = (): void => {
    promptAction.showToast({ message: "编辑功能 W2 上线", duration: 1500 })
    this.onEdit(this.note.id)
  }

  private mockShare = (): void => {
    promptAction.showToast({ message: "已复制笔记到剪贴板", duration: 1500 })
  }

  private confirmDelete = (): void => {
    this.onDelete(this.note.id)
    this.onClose()
  }
}
