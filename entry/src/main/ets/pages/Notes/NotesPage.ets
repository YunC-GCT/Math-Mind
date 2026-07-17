/**
 * MathMind 笔记列表页
 * 页面目录: pages/Notes/
 */

import { BG_DARK, NoteItem, KnowledgeUnit, DatabaseHelper } from "common"
import { promptAction } from "@kit.ArkUI"
import { NoteDetailOverlay } from "../../prototypes/NoteDetailOverlay"
import { NoteDao } from "../../database/NoteDao"
import { unitsToNoteItems } from "../../utils/NoteItemMapper"
import { NotesHeader } from "./NotesHeader"
import { NotesList } from "./NotesList"
import { NotesEmptyState } from "./NotesEmptyState"

@Component
export struct NotesPage {
  @StorageProp("statusBarHeight") sbh: number = 0
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
        NotesHeader({ statusBarHeight: this.sbh, count: this.notes.length })

        if (this.notes.length === 0) {
          NotesEmptyState()
        } else {
          NotesList({
            notes: this.notes,
            onSelect: (note: NoteItem): void => { this.selectedNote = note },
          })
        }
      }
      .width("100%")
      .height("100%")
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
    .width("100%")
    .height("100%")
    .backgroundColor(BG_DARK)
  }
}