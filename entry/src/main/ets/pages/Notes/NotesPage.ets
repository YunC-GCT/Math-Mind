// ============================================================================
//  pages/Notes/NotesPage.ets - notes page shell
// ============================================================================

import { BG_DARK, NoteItem, KnowledgeUnit } from 'common'
import { promptAction } from '@kit.ArkUI'
import { NoteDetailOverlay } from '../../overlays/NoteDetailOverlay/NoteDetailOverlay'
import { NotesHeader } from './NotesHeader'
import { NotesList } from './NotesList'
import { NotesEmptyState } from './NotesEmptyState'
import { NotesViewModel } from '../../viewmodels/NotesViewModel'

@Component
export struct NotesPage {
  @StorageProp('statusBarHeight') sbh: number = 0
  @StorageProp('notesVersion') @Watch('onNotesVersionChange') notesVersion: number = 0
  @State vm: NotesViewModel = new NotesViewModel()
  @State selectedNote: NoteItem | null = null
  @State selectedUnit: KnowledgeUnit | null = null

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
        try { promptAction.showToast({ message: '笔记加载失败', duration: 1500 }) } catch (_e) {}
      }
    })
  }

  private openDetail = (note: NoteItem): void => {
    this.selectedNote = note
    this.selectedUnit = null
    this.vm.loadNote(getContext(this), note.rawId).then((unit: KnowledgeUnit | null): void => {
      if (this.selectedNote !== null && this.selectedNote.id === note.id) {
        this.selectedUnit = unit
      }
    })
  }

  private closeDetail = (): void => {
    this.selectedNote = null
    this.selectedUnit = null
  }

  private deleteNote = async (id: string): Promise<void> => {
    const ok: boolean = await this.vm.deleteNote(getContext(this), id)
    if (ok) {
      this.selectedNote = null
      this.selectedUnit = null
      const v: number = AppStorage.get<number>('notesVersion') ?? 0
      AppStorage.setOrCreate('notesVersion', v + 1)
      try { promptAction.showToast({ message: '笔记已删除', duration: 1200 }) } catch (_e) {}
    } else {
      try { promptAction.showToast({ message: '删除失败', duration: 1500 }) } catch (_e) {}
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
            onSelect: this.openDetail,
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(BG_DARK)

      if (this.selectedNote !== null) {
        NoteDetailOverlay({
          note: this.selectedNote,
          unit: this.selectedUnit,
          units: this.vm.units,
          onClose: this.closeDetail,
          onDelete: this.deleteNote,
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG_DARK)
  }
}
