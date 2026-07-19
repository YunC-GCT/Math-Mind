/**
 * SubjectNoteList.ets — 学科详情页笔记列表
 *
 * 路径: pages/Notes/SubjectNoteList.ets
 * 职责: 在学科详情页展示筛选后的笔记列表，并复用全局 NoteCard 样式。
 * 依赖: common.NoteItem、shared/components/NoteCard
 *
 * 数据流:
 *   SubjectDetailPage.filteredNotes()
 *     → SubjectNoteList
 *       → NoteCard
 *       → onSelect(note)
 *
 * ArkTS 1.1 strict 适配:
 *   - 无 any/unknown
 *   - 无 C 风格 for
 *   - struct 内无普通方法
 */

import { BG_CARD, BORDER, R_LG, S_4, NoteItem } from "common"
import { NoteCard } from "../../shared/components/NoteCard"

@Component
export struct SubjectNoteList {
  @Prop notes: NoteItem[] = []
  onSelect: (note: NoteItem) => void = (_note: NoteItem): void => {}

  build() {
    Column() {
      ForEach(this.notes,
        (note: NoteItem, index: number): void => {
          NoteCard({
            note: note,
            isLast: index === this.notes.length - 1,
            onTap: (): void => this.onSelect(note),
          })
        },
        (note: NoteItem): string => note.id.toString()
      )
    }
    .width("100%")
    .padding({ left: S_4, right: S_4 })
    .backgroundColor(BG_CARD)
    .border({ width: 0.5, color: BORDER })
    .borderRadius(R_LG)
  }
}
