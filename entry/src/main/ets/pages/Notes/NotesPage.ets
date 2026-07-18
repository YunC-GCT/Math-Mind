// ============================================================================
//  pages/Notes/NotesPage.ets - notes page shell
// ============================================================================

import { BG_DARK, NoteItem } from "common"
import { promptAction } from "@kit.ArkUI"
import { NoteDetailOverlay } from "../../overlays/NoteDetailOverlay/NoteDetailOverlay"
import { NotesHeader } from "./NotesHeader"
import { NotesList } from "./NotesList"
import { NotesEmptyState } from "./NotesEmptyState"
import { NotesViewModel } from "../../viewmodels/NotesViewModel"

@Component
export struct NotesPage {
  @StorageProp("statusBarHeight") sbh: number = 0
  @StorageProp('notesVersion') @Watch('onNotesVersionChange') notesVersion: number = 0
  @State vm: NotesViewModel = new NotesViewModel()
  @State selectedNote: NoteItem | null = null

  aboutToAppear(): void {
    if (AppStorage.get<number>('notesVersion') === undefined) {
      AppStorage.setOrCreate('notesVersion', 0)
    }
    this.reloadNotes()
  }

  onNotesVersionChange(): void {
    this.reloadNotes()
  }

  private reloadNotes(): void {
    this.vm.loadNotes(getContext(this)).then((ok: boolean): void => {
      if (!ok) {
        try { promptAction.showToast({ message: "笔记加载失败", duration: 1500 }) } catch (_e) {}
      }
    })
  }

  private closeDetail = (): void => { this.selectedNote = null }

  private deleteNote = async (id: string): Promise<void> => {
    const ok: boolean = await this.vm.deleteNote(getContext(this), id)
    if (ok) {
      this.selectedNote = null
      const v: number = AppStorage.get<number>('notesVersion') ?? 0
      AppStorage.setOrCreate('notesVersion', v + 1)
      try { promptAction.showToast({ message: "笔记已删除", duration: 1200 }) } catch (_e) {}
    } else {
      try { promptAction.showToast({ message: "笔记删除失败", duration: 1500 }) } catch (_e) {}
    }
  }

  build() {
    Stack() {
      Column() {
        NotesHeader({ statusBarHeight: this.sbh, count: this.vm.notes.length })

        if (this.vm.notes.length === 0) {
          NotesEmptyState()
        } else {
          NotesList({
            notes: this.vm.notes,
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
          onDelete: this.deleteNote,
        })
      }
    }
    .width("100%")
    .height("100%")
    .backgroundColor(BG_DARK)
  }
}
