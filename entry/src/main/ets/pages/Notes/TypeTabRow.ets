// ============================================================================
//  pages/Notes/TypeTabRow.ets - note type filter tabs
// ============================================================================

import { BORDER, MINT, MINT_LIGHT, TEXT_3, S_2, F_XS, R_FULL, NoteItem } from "common"

const TYPE_KEYS: string[] = ["all", "概念", "定理", "公式", "证明题", "计算题"]

@Component
export struct TypeTabRow {
  @Prop activeType: string = "all"
  @Prop notes: NoteItem[] = []
  onSelect: (type: string) => void = (_type: string): void => {}

  build() {
    Scroll() {
      Row({ space: 6 }) {
        ForEach(TYPE_KEYS,
          (type: string): void => {
            Text(this.tabText(type))
              .fontSize(F_XS)
              .fontColor(this.activeType === type ? MINT : TEXT_3)
              .padding({ left: 12, right: 12, top: 5, bottom: 5 })
              .borderRadius(R_FULL)
              .backgroundColor(this.activeType === type ? MINT_LIGHT : Color.Transparent)
              .border({ width: 0.5, color: this.activeType === type ? MINT : BORDER })
              .onClick((): void => this.onSelect(type))
          },
          (type: string): string => type
        )
      }
      .padding({ left: 14, right: 14, top: S_2, bottom: S_2 + 2 })
    }
    .width("100%")
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  private tabText(type: string): string {
    const count: number = this.countOf(type)
    if (count > 0) {
      return this.labelOf(type) + " · " + count.toString()
    }
    return this.labelOf(type)
  }

  private countOf(type: string): number {
    if (type === "all") {
      return this.notes.length
    }
    let count: number = 0
    for (const note of this.notes) {
      if (this.typeKey(note.type) === type) {
        count++
      }
    }
    return count
  }

  private labelOf(type: string): string {
    return type === "all" ? "全部" : type
  }

  private typeKey(type: string): string {
    if (type === "计算") { return "计算题" }
    if (type === "证明") { return "证明题" }
    return type
  }
}
