// ============================================================================
//  pages/Notes/NotesPage.ets - notes page shell
// ============================================================================

import { BG_DARK } from "common"
import { promptAction, router } from "@kit.ArkUI"
import { NotesHeader } from "./NotesHeader"
import { NotesEmptyState } from "./NotesEmptyState"
import { SubjectGrid } from "./SubjectGrid"
import { NotesViewModel } from "../../viewmodels/NotesViewModel"

@Component
export struct NotesPage {
  @StorageProp("statusBarHeight") sbh: number = 0
  @StorageProp("notesVersion") @Watch("onNotesVersionChange") notesVersion: number = 0
  @State vm: NotesViewModel = new NotesViewModel()

  aboutToAppear(): void {
    if (AppStorage.get<number>("notesVersion") === undefined) {
      AppStorage.setOrCreate("notesVersion", 0)
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

  private openSubject = (subject: string): void => {
    router.pushUrl({
      url: "pages/Notes/SubjectDetailPage",
      params: { subject: subject },
    })
  }

  build() {
    Column() {
      NotesHeader({
        statusBarHeight: this.sbh,
        subjectCount: this.vm.subjectGroups.length,
        totalCount: this.vm.notes.length,
      })

      if (this.vm.notes.length === 0) {
        NotesEmptyState()
      } else {
        SubjectGrid({
          groups: this.vm.subjectGroups,
          onSelect: this.openSubject,
        })
      }
    }
    .width("100%")
    .height("100%")
    .backgroundColor(BG_DARK)
  }
}
