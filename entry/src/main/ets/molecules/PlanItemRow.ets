// ============================================================================
//  components/PlanItemRow.ets — 学习计划单行原子组件
//  ----------------------------------------------------------------------------
//  职责: 渲染一条学习计划项（完成状态图标 + 标题 + 关联笔记 + 优先级标签）。
//  与 ViewModel 解耦: 通过 onToggle 回调通知父组件。
//
//  ArkTS 1.1 strict: @Prop 仅接收原始类型（string/boolean/number），避免 class 浅拷贝导致 UI 不更新。
//  ============================================================================

import { MINT, BG_DARK, BG_CARD, TEXT, TEXT_3, DANGER, WARNING, S_1, S_3, S_5, F_MD, F_XS, R_MD } from "common"
import { PriorityBadge } from "../atoms/PriorityBadge"
import { AppIcon } from "../atoms/AppIcon"

@Component
export struct PlanItemRow {
  @Prop title: string = ""
  @Prop isDone: boolean = false
  @Prop priority: number = 2
  @Prop linkedNoteId: string = ""
  @State revealOffset: number = 0
  private dragStartX: number = 0
  onToggle?: () => void
  onEdit?: () => void
  onPin?: () => void
  onDelete?: () => void

  build() {
    Stack({ alignContent: Alignment.End }) {
      Row() {
        this.ActionButton("修改", TEXT_3, (): void => {
          this.revealOffset = 0
          if (this.onEdit) { this.onEdit() }
        })
        this.ActionButton("置顶", WARNING, (): void => {
          this.revealOffset = 0
          if (this.onPin) { this.onPin() }
        })
        this.ActionButton("删除", DANGER, (): void => {
          this.revealOffset = 0
          if (this.onDelete) { this.onDelete() }
        })
      }
      .height(64)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(BG_DARK)

      Row({ space: S_3 }) {
        // ---- 完成状态图标 ----
        Checkbox()
          .select(this.isDone)
          .selectedColor(MINT)
          .onChange((_checked: boolean): void => {
            if (this.onToggle) { this.onToggle() }
          })

        // ---- 标题 + 关联笔记 ----
        Column({ space: S_1 / 2 }) {
          Text(this.title)
            .fontSize(F_MD)
            .fontColor(this.isDone ? TEXT_3 : TEXT)
            .decoration(this.isDone
              ? { type: TextDecorationType.LineThrough, color: TEXT_3 }
              : { type: TextDecorationType.None })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.linkedNoteId.length > 0) {
            Row({ space: S_1 }) {
              AppIcon({ name: "paperclip", iconSize: F_XS + 2, color: TEXT_3, strokeWidth: 1.4 })
              Text("关联笔记: " + this.linkedNoteId)
                .fontSize(F_XS)
                .fontColor(TEXT_3)
                .maxLines(1)
            }
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // ---- 优先级标签 ----
        PriorityBadge({ priority: this.priority })
      }
      .width("100%")
      .padding({ top: S_3 + 2, bottom: S_3 + 2, left: S_5, right: S_5 })
      .backgroundColor(BG_DARK)
      .height(64)
      .translate({ x: this.revealOffset })
      .gesture(
        PanGesture({ direction: PanDirection.Horizontal })
          .onActionStart((): void => {
            this.dragStartX = this.revealOffset
          })
          .onActionUpdate((event: GestureEvent): void => {
            const next: number = this.dragStartX + event.offsetX
            this.revealOffset = Math.max(-168, Math.min(0, next))
          })
          .onActionEnd((): void => {
            this.revealOffset = this.revealOffset < -72 ? -168 : 0
          })
      )
    }
    .width("100%")
  }

  @Builder
  ActionButton(label: string, color: ResourceColor, action: () => void) {
    Text(label)
      .fontSize(F_XS)
      .fontColor(color)
      .width(56)
      .height(44)
      .textAlign(TextAlign.Center)
      .backgroundColor(BG_CARD)
      .borderRadius(R_MD)
      .margin({ left: 4 })
      .onClick((): void => action())
  }
}
