// ============================================================================
//  pages/StudyPlan/PlanListView.ets — 学习计划列表
//  ----------------------------------------------------------------------------
//  职责: List 容器渲染所有计划项,每项是 PlanItemRow(分隔线模式)。
//
//  布局:
//    List(ListItem × N,每项 PlanItemRow)
//
//  事件转发(PlanItemRow → ViewModel):
//    onToggle: 切换完成状态
//    onEdit:   进入编辑模式
//    onPin:    置顶
//    onDelete: 删除
//
//  依赖:
//    pages:     PlanItemRow
//    viewmodels: StudyPlanViewModel
//    common:     BORDER
//
//  来源: 2026-07-17 pages 重组(从 StudyPlanPage 拆出)
//  ============================================================================

import { BORDER, StudyPlanItem } from "common"
import { StudyPlanViewModel } from "../../viewmodels/StudyPlanViewModel"
import { PlanItemRow } from "./PlanItemRow"

@Component
export struct PlanListView {
  // 页面 ViewModel(响应式订阅)
  @ObjectLink vm: StudyPlanViewModel

  build() {
    List() {
      // 计划列表
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
        // ForEach keyGenerator 必填
        (item: StudyPlanItem): string => item.id
      )
    }
    .layoutWeight(1)
    .divider({ strokeWidth: 0.5, color: BORDER })
  }
}
