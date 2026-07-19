// ============================================================================
//  pages/Notes/SubjectTypeEmpty.ets - empty state for subject type filter
// ============================================================================

import { TEXT_3, TEXT_4, F_SM, F_XS, W_SEMIBOLD } from "common"

@Component
export struct SubjectTypeEmpty {
  @Prop activeType: string = "all"

  build() {
    Column() {
      Text(this.title())
        .fontSize(F_SM)
        .fontColor(TEXT_3)
        .fontWeight(W_SEMIBOLD)

      Text("切换类型或稍后添加新的原子笔记")
        .fontSize(F_XS)
        .fontColor(TEXT_4)
        .margin({ top: 6 })
    }
    .width("100%")
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private title(): string {
    if (this.activeType === "all") {
      return "暂无笔记"
    }
    return "暂无 " + this.activeType + " 类型的笔记"
  }
}
