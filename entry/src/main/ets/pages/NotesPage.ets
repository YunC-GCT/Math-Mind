/**
 * MathMind 笔记列表页
 * W3 UI 优化 (2026-07-15): 标题栏视觉提升、全量令牌化
 */

import {
  BG_DARK, TEXT, TEXT_3,
  S_4, S_5,
  F_XS, F_MD,
  W_SEMIBOLD,
  NoteItem, NOTES,
} from "common"
import { NoteDetailOverlay } from "../prototypes/NoteDetailOverlay"
import { NoteCard } from "../molecules/NoteCard"

@Component
export struct NotesPage {
  @StorageProp('statusBarHeight') sbh: number = 0
  @State selectedNote: NoteItem | null = null
  private notes: NoteItem[] = NOTES

  private closeDetail = (): void => { this.selectedNote = null }
  private askAi = (_note: NoteItem): void => { this.selectedNote = null }

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
        })
      }
    }
    .width("100%").height("100%")
    .backgroundColor(BG_DARK)
  }
}
