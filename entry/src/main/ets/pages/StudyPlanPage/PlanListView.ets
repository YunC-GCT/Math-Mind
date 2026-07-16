import { BORDER, StudyPlanItem } from "common"
import { StudyPlanViewModel } from "../../viewmodels/StudyPlanViewModel"
import { PlanItemRow } from "../../molecules/PlanItemRow"

@Component
export struct PlanListView {
  @ObjectLink vm: StudyPlanViewModel

  build() {
    List() {
      ForEach(this.vm.items,
        (item: StudyPlanItem, _idx: number): void => {
          ListItem() {
            PlanItemRow({
              title: item.title,
              isDone: item.isDone,
              priority: item.priority,
              linkedNoteId: item.linkedNoteId,
              onToggle: (): void => { this.vm.toggleItem(item) },
              onEdit: (): void => { this.vm.beginEdit(item) },
              onPin: (): void => { this.vm.pinItem(item) },
              onDelete: (): void => { this.vm.deleteItem(item) },
            })
          }
        },
        (item: StudyPlanItem): string => item.id
      )
    }
    .layoutWeight(1)
    .divider({ strokeWidth: 0.5, color: BORDER })
  }
}
