import { TEXT, TEXT_3, S_2, S_3, S_5, F_XS, F_BASE, W_SEMIBOLD, NoteItem } from "common"
import { NoteCard } from "../../molecules/NoteCard"

@Component
export struct HomeRecentNotes {
  @Prop notes: NoteItem[] = []
  onSelect: (note: NoteItem) => void = (_note: NoteItem): void => {}

  build() {
    Column() {
      Row() {
        Text("最近笔记")
          .fontSize(F_BASE)
          .fontWeight(W_SEMIBOLD)
          .fontColor(TEXT)
        Blank()
        Text(this.notes.length + " 条")
          .fontSize(F_XS)
          .fontColor(TEXT_3)
      }
      .width("100%")
      .padding({ left: S_5, right: S_5, top: S_3, bottom: S_2 })

      Scroll() {
        Column() {
          ForEach(this.notes,
            (note: NoteItem, index: number): void => {
              NoteCard({
                note: note,
                isLast: index === this.notes.length - 1,
                onTap: (): void => { this.onSelect(note) },
              })
            },
            (note: NoteItem): string => note.id.toString()
          )
          Blank().height(48)
        }
        .width("100%")
        .padding({ left: S_5, right: S_5, top: S_3, bottom: S_5 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .layoutWeight(1)
    .width("100%")
  }
}
