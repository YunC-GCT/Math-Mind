// ============================================================================
//  pages/Notes/SubjectNoteList.ets - compact notes list inside subject detail
// ============================================================================

import { BG_CARD, BORDER, TEXT_2, TEXT_4, S_4, F_XS, F_SM, R_LG, NoteItem, recentDate, typeColor } from "common"

@Component
export struct SubjectNoteList {
  @Prop notes: NoteItem[] = []
  onSelect: (note: NoteItem) => void = (_note: NoteItem): void => {}

  build() {
    Column() {
      ForEach(this.notes,
        (note: NoteItem, index: number): void => {
          Row() {
            Circle({ width: 6, height: 6 })
              .fill(typeColor(note.type))
              .margin({ right: 10 })
              .flexShrink(0)

            Text(note.title)
              .fontSize(F_SM)
              .fontColor(TEXT_2)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            Text(recentDate(note.date))
              .fontSize(F_XS)
              .fontColor(TEXT_4)
              .margin({ left: 10 })
              .flexShrink(0)
          }
          .width("100%")
          .padding({ left: S_4, right: S_4, top: 12, bottom: 12 })
          .border({ width: { bottom: index === this.notes.length - 1 ? 0 : 0.5 }, color: BORDER })
          .onClick((): void => this.onSelect(note))
        },
        (note: NoteItem): string => note.id.toString()
      )
    }
    .width("100%")
    .backgroundColor(BG_CARD)
    .borderRadius(R_LG)
  }
}
