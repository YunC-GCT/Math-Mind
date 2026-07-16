/**
 * MathMind 笔记列表页
 * W3 UI 优化 (2026-07-15): 标题栏视觉提升、全量令牌化
 */

import {
  MINT, BG_DARK, BORDER, TEXT, TEXT_2, TEXT_3, TEXT_4,
  S_4, S_5, S_6,
  R_MD, R_LG,
  F_XS, F_SM, F_BASE, F_MD,
  W_MEDIUM, W_SEMIBOLD,
  NoteItem, KnowledgeUnit, DatabaseHelper,
} from "common"
import { promptAction } from "@kit.ArkUI"
import { NoteDetailOverlay } from "../prototypes/NoteDetailOverlay"
import { NoteCard } from "../molecules/NoteCard"
import { NoteDao } from "../database/NoteDao"
import { unitsToNoteItems } from "../utils/NoteItemMapper"

@Component
export struct NotesPage {
  @StorageProp('statusBarHeight') sbh: number = 0
  @State selectedNote: NoteItem | null = null
  @State notes: NoteItem[] = []

  private closeDetail = (): void => { this.selectedNote = null }
  private askAi = (_note: NoteItem): void => { this.selectedNote = null }
  private deleteNote = async (id: string): Promise<void> => {
    try {
      const store = await DatabaseHelper.init(getContext(this))
      await new NoteDao(store).deleteById(id)
      this.selectedNote = null
      await this.loadNotes()
      try { promptAction.showToast({ message: "笔记已删除", duration: 1200 }) } catch (_e) {}
    } catch (e) {
      try { promptAction.showToast({ message: "笔记删除失败", duration: 1500 }) } catch (_e) {}
    }
  }

  aboutToAppear(): void {
    this.loadNotes()
  }

  private loadNotes = async (): Promise<void> => {
    try {
      const store = await DatabaseHelper.init(getContext(this))
      const units: KnowledgeUnit[] = await new NoteDao(store).queryAll()
      this.notes = unitsToNoteItems(units)
    } catch (e) {
      this.notes = []
      try { promptAction.showToast({ message: "笔记加载失败", duration: 1500 }) } catch (_e) {}
    }
  }

  build() {
    Stack() {
      Column() {
        Row().width('100%').height(this.sbh).backgroundColor(BG_DARK)
        // ---- 标题栏 ----
        Row() {
          Text("全部笔记")
            .fontSize(F_MD).fontWeight(W_SEMIBOLD).fontColor(TEXT)
          Blank()
          Text(this.notes.length + " 条")
            .fontSize(F_XS).fontColor(TEXT_3)
        }
        .width("100%")
        .padding({ left: S_5, right: S_5, top: S_4, bottom: S_4 })

        // ---- 笔记列表 ----
        List() {
          ForEach(this.notes,
            (note: NoteItem, idx: number): void => {
              ListItem() {
                NoteCard({
                  note: note,
                  isLast: idx === this.notes.length - 1,
                  onTap: (): void => { this.selectedNote = note },
                })
              }
            },
            (note: NoteItem): string => note.id.toString()
          )
          ListItem() {
            Column() { Blank().height(80) }
          }
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width("100%").height("100%")
      .backgroundColor(BG_DARK)

      if (this.selectedNote !== null) {
        NoteDetailOverlay({
          note: this.selectedNote,
          onClose: this.closeDetail,
          onAskAi: this.askAi,
          onDelete: this.deleteNote,
        })
      }
    }
    .width("100%").height("100%")
    .backgroundColor(BG_DARK)
  }
}
