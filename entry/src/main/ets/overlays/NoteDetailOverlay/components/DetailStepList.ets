/**
 * DetailStepList.ets — 详情页步骤/过程列表
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/components/DetailStepList.ets
 * 职责: 将证明过程、计算步骤等内容渲染为编号阅读路径。
 * 依赖: common tokens, MarkdownRenderer
 *
 * 数据流:
 *   renderer splitReadableLines(content) → DetailStepList → MarkdownRenderer
 *
 * ArkTS 1.1 strict 适配:
 *   - ForEach 使用稳定 key
 *   - struct 内无普通方法
 */

import {
  MINT, TEXT_2, BORDER,
  S_2, S_3,
  R_FULL,
  F_SM,
  W_BOLD,
} from 'common'
import { MarkdownRenderer } from '../../../shared/components/MarkdownRenderer'

const DETAIL_STEP_INITIAL_COUNT: number = 3
const DETAIL_STEP_BATCH_SIZE: number = 3
const DETAIL_STEP_BATCH_RENDER_DELAY_MS: number = 48

@Component
export struct DetailStepList {
  @Prop @Watch('onItemsChanged') items: string[] = []
  @Prop accentColor: ResourceColor = MINT
  @State visibleItemCount: number = DETAIL_STEP_INITIAL_COUNT
  private renderSeq: number = 0

  aboutToAppear(): void {
    this.resetVisibleItems()
  }

  aboutToDisappear(): void {
    this.renderSeq += 1
  }

  onItemsChanged(): void {
    this.resetVisibleItems()
  }

  build() {
    Column() {
      ForEach(this.visibleItems(),
        (item: string, index: number): void => {
          Row() {
            Text((index + 1).toString())
              .fontSize(F_SM)
              .fontWeight(W_BOLD)
              .fontColor(this.accentColor)
              .width(24)
              .height(24)
              .textAlign(TextAlign.Center)
              .borderRadius(R_FULL)
              .backgroundColor('#0DFFFFFF')
              .border({ width: 0.5, color: BORDER })
              .margin({ right: S_2 })

            Column() {
              MarkdownRenderer({ text: item, progressive: true })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .margin({ bottom: S_3 })
        },
        (item: string, index: number): string => index.toString() + '_' + item
      )

      if (this.items.length > this.visibleItemCount) {
        Blank().height(S_2)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  private resetVisibleItems = (): void => {
    this.renderSeq += 1
    const seq: number = this.renderSeq
    if (this.items.length <= DETAIL_STEP_INITIAL_COUNT) {
      this.visibleItemCount = this.items.length
      return
    }
    this.visibleItemCount = DETAIL_STEP_INITIAL_COUNT
    this.scheduleNextItemBatch(seq)
  }

  private scheduleNextItemBatch = (seq: number): void => {
    setTimeout((): void => {
      if (seq !== this.renderSeq) {
        return
      }
      const nextCount: number = Math.min(this.items.length, this.visibleItemCount + DETAIL_STEP_BATCH_SIZE)
      this.visibleItemCount = nextCount
      if (nextCount < this.items.length) {
        this.scheduleNextItemBatch(seq)
      }
    }, DETAIL_STEP_BATCH_RENDER_DELAY_MS)
  }

  private visibleItems = (): string[] => {
    if (this.items.length <= this.visibleItemCount) {
      return this.items
    }
    return this.items.slice(0, this.visibleItemCount)
  }
}
