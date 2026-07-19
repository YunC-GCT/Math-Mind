// ============================================================================
//  pages/Notes/SubjectGrid.ets - two-column subject grid
// ============================================================================

import { S_2, S_4 } from "common"
import { SubjectGroup } from "../../viewmodels/NotesViewModel"
import { SubjectCard } from "./SubjectCard"

@Component
export struct SubjectGrid {
  @Prop groups: SubjectGroup[] = []
  onSelect: (subject: string) => void = (_subject: string): void => {}

  build() {
    Scroll() {
      Column() {
        Grid() {
          ForEach(this.groups,
            (group: SubjectGroup): void => {
              GridItem() {
                SubjectCard({
                  subject: group.subject,
                  color: group.color,
                  count: group.count,
                  previewTitles: group.previewTitles,
                  onTap: (): void => this.onSelect(group.subject),
                })
              }
            },
            (group: SubjectGroup): string => group.subject
          )
        }
        .width("100%")
        .columnsTemplate("1fr 1fr")
        .columnsGap(S_2)
        .rowsGap(S_2)
      }
      .width("100%")
      .constraintSize({ minHeight: "100%" })
      .padding({ left: S_4, right: S_4, bottom: 96 })
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
    }
    .layoutWeight(1)
    .width("100%")
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
