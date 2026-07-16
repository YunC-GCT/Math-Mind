// ============================================================================
//  components/PlanItemRow.ets — 学习计划单行原子组件
//  ----------------------------------------------------------------------------
//  职责: 渲染一条学习计划项（完成状态图标 + 标题 + 关联笔记 + 优先级标签）。
//  与 ViewModel 解耦: 通过 onToggle / onDelete 回调通知父组件。
//
//  ArkTS 1.1 strict: @Prop 仅接收原始类型（string/boolean/number），避免 class 浅拷贝导致 UI 不更新。
//  ============================================================================

import { MINT, TEXT, TEXT_3, S_5, F_MD, F_XS } from "common"
import { PriorityBadge } from "../atoms/PriorityBadge"

@Component
export struct PlanItemRow {
  @Prop title: string = ""
  @Prop isDone: boolean = false
  @Prop priority: number = 2
  @Prop linkedNoteId: string = ""
  onToggle?: () => void

  build() {
    Row({ space: 12 }) {
      // ---- 完成状态图标 ----
      Text(this.isDone ? "●" : "○")
        .fontSize(22)
        .fontColor(this.isDone ? MINT : TEXT_3)
        .onClick((): void => {
          if (this.onToggle) {
            this.onToggle()
          }
        })

      // ---- 标题 + 关联笔记 ----
      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(F_MD)
          .fontColor(this.isDone ? TEXT_3 : TEXT)
          .decoration(this.isDone
            ? { type: TextDecorationType.LineThrough, color: TEXT_3 }
            : { type: TextDecorationType.None })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.linkedNoteId.length > 0) {
          Text("📎 关联笔记: " + this.linkedNoteId)
            .fontSize(F_XS)
            .fontColor(TEXT_3)
            .maxLines(1)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // ---- 优先级标签 ----
      PriorityBadge({ priority: this.priority })
    }
    .width("100%")
    .padding({ top: 14, bottom: 14, left: S_5, right: S_5 })

  }
}
