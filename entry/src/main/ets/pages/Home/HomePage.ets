// ============================================================================
//  pages/Home/HomePage.ets - home page shell
// ============================================================================

import { BG_DARK, NoteItem } from "common"
import { promptAction } from "@kit.ArkUI"
import { FloatingButton } from "./FloatingButton"
import { HeroBanner } from "./HeroBanner"
import { ReminderBanner } from "./ReminderBanner"
import { NoteDetailOverlay } from "../../overlays/NoteDetailOverlay/NoteDetailOverlay"
import { HomeTopBar } from "./HomeTopBar"
import { HomeRecentNotes } from "./HomeRecentNotes"
import { HomeViewModel } from "../../viewmodels/HomeViewModel"

@Component
export struct HomePage {
  @StorageProp("statusBarHeight") sbh: number = 0
  @StorageProp('notesVersion') @Watch('onNotesVersionChange') notesVersion: number = 0
  @State vm: HomeViewModel = new HomeViewModel()
  @State selectedNote: NoteItem | null = null
  onGoCamera: () => void = (): void => {}
  onGoReview: () => void = (): void => {}

  aboutToAppear(): void {
    this.reloadHome()
  }

  onNotesVersionChange(): void {
    this.reloadHome()
  }

  private reloadHome(): void {
    this.vm.init(getContext(this)).then((ok: boolean): void => {
      if (!ok) {
        try { promptAction.showToast({ message: "笔记加载失败", duration: 1500 }) } catch (_e) {}
      }
    })
  }

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
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Row()
          .width("100%")
          .height(this.sbh)
          .backgroundColor(BG_DARK)

        HomeTopBar({ statusBarHeight: this.sbh })
        HeroBanner({
          greeting: this.vm.greeting,
          dateText: this.vm.dateText,
          avg: this.vm.avg,
          notesCount: this.vm.notes.length,
          todayCount: this.vm.today,
          onGoReview: (): void => { this.onGoReview() },
        })

        if (this.vm.notes.length < 3) {
          ReminderBanner({ notesCount: this.vm.notes.length })
        }

        HomeRecentNotes({
          notes: this.vm.notes,
          onSelect: (note: NoteItem): void => { this.selectedNote = note },
        })
      }
      .width("100%")
      .height("100%")
      .backgroundColor(BG_DARK)

      FloatingButton({
        onTap: (): void => {
          try { promptAction.showToast({ message: "用户自定义笔记开发中", duration: 1500 }) } catch (_e) {}
        },
      })

      if (this.selectedNote !== null) {
        NoteDetailOverlay({
          note: this.selectedNote!,
          onClose: (): void => { this.selectedNote = null },
          onDelete: this.deleteNote,
        })
      }
    }
    .width("100%")
    .height("100%")
    .backgroundColor(BG_DARK)
  }
}
