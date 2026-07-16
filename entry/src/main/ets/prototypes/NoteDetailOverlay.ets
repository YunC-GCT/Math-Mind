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
  BG_DARK,
  TEXT, TEXT_2, TEXT_3, TEXT_4, BORDER,
  GLASS_10, OVERLAY_MASK_SOLID,
  S_1, S_2, S_5, S_6,
  R_FULL,
  F_XS, F_2XL,
  W_SEMIBOLD, W_BOLD,
  NoteItem, typeColor, subjectColor, recentDate,
} from "common"
import { promptAction } from "@kit.ArkUI"
import { ConfBadge } from "../atoms/ConfBadge"
import { AppIcon } from "../atoms/AppIcon"
import { NoteAiCard } from "./NoteDetailOverlay/NoteAiCard"
import { NoteActionBar } from "./NoteDetailOverlay/NoteActionBar"
import { Section, NoteSectionView } from "./NoteDetailOverlay/NoteSection"
import { NoteTagChip } from "./NoteDetailOverlay/NoteTagChip"
import { NoteCloseButton } from "./NoteDetailOverlay/NoteCloseButton"

// 解析 body 成章节
function parseSections(body: string): Section[] {
  if (!body) { return [] }
  const lines: string[] = body.split("\n")
  const sections: Section[] = []
  let curTitle: string = "内容"
  let curLines: string[] = []

  for (const line of lines) {
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
  onAskAi: (note: NoteItem) => void = (_note: NoteItem): void => {}
  onEdit: (id: number) => void = (_id: number): void => {}
  onDelete: (id: string) => void = (_id: string): void => {}

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

          NoteCloseButton({ onClose: (): void => this.onClose() })
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
                AppIcon({ name: "notes", iconSize: 12, color: TEXT_2, strokeWidth: 1.6 })
                  .margin({ right: S_1 })
                Text(this.note.chapter)
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
                    NoteTagChip({ tag: tag })
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
                  NoteSectionView({ title: sec.title, content: sec.content })
                },
                (sec: Section): string => sec.title + "_" + sec.content.length.toString()
              )
            }
            .width("100%")
            .padding({ left: 20, right: 20, bottom: 16 })

            // AI 卡
            NoteAiCard({ onTap: (): void => this.handleAskAi() })

            Blank().height(80)
          }
          .width("100%")
        }
        .layoutWeight(1)
        .width("100%")
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)

        // 底部操作栏
        NoteActionBar({
          onDelete: (): void => this.confirmDelete(),
          onEdit: (): void => this.mockEdit(),
          onShare: (): void => this.mockShare(),
        })
      }
      .width("100%").height("100%")
      .backgroundColor(BG_DARK)
    }
    .width("100%").height("100%")
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
    this.onDelete(this.note.rawId.length > 0 ? this.note.rawId : this.note.id.toString())
    this.onClose()
  }
}
