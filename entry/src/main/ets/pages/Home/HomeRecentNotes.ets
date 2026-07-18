// ============================================================================
//  pages/Home/HomeRecentNotes.ets — 最近笔记列表
//  ----------------------------------------------------------------------------
//  职责: 显示"最近笔记"标题 + 笔记数 + 滚动列表。
//
//  布局:
//    ["最近笔记" 标题 + "X 条" 计数]
//    [Scroll 列表,内含 N 个 NoteCard(分隔线模式)]
//
//  依赖:
//    shared: NoteCard
//    common 令牌: TEXT / TEXT_3 / S_2 / S_3 / S_5 / F_XS / F_BASE / W_SEMIBOLD
//
//  Props:
//    notes: NoteItem[] (从 HomePage 注入)
//    onSelect: 笔记卡片点击回调
//  ============================================================================

import { TEXT, TEXT_3, S_1, S_2, S_3, S_5, F_XS, F_BASE, W_SEMIBOLD, NoteItem } from "common"
import { NoteCard } from "../../shared/components/NoteCard"

@Component
export struct HomeRecentNotes {
  // 笔记数据(从 HomePage 注入)
  @Prop notes: NoteItem[] = []

  // 笔记点击回调
  onSelect: (note: NoteItem) => void = (_note: NoteItem): void => {}
  onSwipeUp: () => void = (): void => {}

  build() {
    Column() {
      // 标题行
      Row() {
        Text("最近笔记")
          .fontSize(F_BASE)
          .fontWeight(W_SEMIBOLD)
          .fontColor(TEXT)
        Blank()
        // 笔记数计数
        Text(this.notes.length + " 条")
          .fontSize(F_XS)
          .fontColor(TEXT_3)
      }
      .width("100%")
      .padding({ left: S_5, right: S_5, top: S_1, bottom: S_2 })
      .gesture(
        PanGesture({ direction: PanDirection.Vertical })
          .onActionEnd((event: GestureEvent): void => {
            if (event.offsetY < -18) {
              this.onSwipeUp()
            }
          })
      )

      // 滚动列表
      Scroll() {
        Column() {
          ForEach(this.notes,
            (note: NoteItem, index: number): void => {
              NoteCard({
                note: note,
                // 最后一条不画分隔线
                isLast: index === this.notes.length - 1,
                onTap: (): void => { this.onSelect(note) },
              })
            },
            // ForEach keyGenerator 必填
            (note: NoteItem): string => note.id.toString()
          )
          // FAB 留白
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
