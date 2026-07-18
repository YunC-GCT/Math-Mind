// ============================================================================
//  pages/Home/HomePage.ets - home page shell
// ============================================================================

import { BG_DARK, DUR_SLOW, NoteItem } from "common"
import { promptAction } from "@kit.ArkUI"
import { FloatingButton } from "./FloatingButton"
import { HeroBanner } from "./HeroBanner"
import { HomeCollapsedReview } from "./HomeCollapsedReview"
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
  @State reviewRingCollapsed: boolean = false
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

  private collapseReviewRing(): void {
    if (this.reviewRingCollapsed) {
      return
    }
    animateTo({ duration: DUR_SLOW, curve: Curve.FastOutSlowIn }, (): void => {
      this.reviewRingCollapsed = true
    })
  }

  private expandReviewRing(): void {
    if (!this.reviewRingCollapsed) {
      return
    }
    animateTo({ duration: DUR_SLOW, curve: Curve.FastOutSlowIn }, (): void => {
      this.reviewRingCollapsed = false
    })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        HomeTopBar({ statusBarHeight: this.sbh })
        if (this.reviewRingCollapsed) {
          HomeCollapsedReview({
            avg: this.vm.avg,
            notesCount: this.vm.notes.length,
            todayCount: this.vm.today,
            dateText: this.vm.dateText,
            onGoReview: (): void => { this.onGoReview() },
          })
          .gesture(
            PanGesture({ direction: PanDirection.Vertical })
              .onActionEnd((event: GestureEvent): void => {
                if (event.offsetY > 24) {
                  this.expandReviewRing()
                }
              })
          )
        } else {
          HeroBanner({
            greeting: this.vm.greeting,
            dateText: this.vm.dateText,
            avg: this.vm.avg,
            notesCount: this.vm.notes.length,
            todayCount: this.vm.today,
            onGoReview: (): void => { this.onGoReview() },
          })
          .gesture(
            PanGesture({ direction: PanDirection.Vertical })
              .onActionEnd((event: GestureEvent): void => {
                if (event.offsetY < -18) {
                  this.collapseReviewRing()
                }
              })
          )
        }

        if (!this.reviewRingCollapsed && this.vm.notes.length < 3) {
          ReminderBanner({ notesCount: this.vm.notes.length })
            .gesture(
              PanGesture({ direction: PanDirection.Vertical })
                .onActionEnd((event: GestureEvent): void => {
                  if (event.offsetY < -18) {
                    this.collapseReviewRing()
                  }
                })
            )
        }

        HomeRecentNotes({
          notes: this.vm.notes,
          onSwipeUp: (): void => { this.collapseReviewRing() },
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
