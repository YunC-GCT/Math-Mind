import { NoteItem } from "common"
import { NoteCard } from "../../molecules/NoteCard"

@Component
export struct NotesList {
  @Prop notes: NoteItem[] = []
  onSelect: (note: NoteItem) => void = (_note: NoteItem): void => {}

  build() {
    List() {
      ForEach(this.notes,
        (note: NoteItem, idx: number): void => {
          ListItem() {
            NoteCard({
              note: note,
              isLast: idx === this.notes.length - 1,
              onTap: (): void => { this.onSelect(note) },
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
}