// ============================================================================
//  components/StatsBox.ets — 统计方块原子组件
//  ----------------------------------------------------------------------------
//  职责: 展示单个统计数据（数值 + 标签），用于 Hero 区统计行。
//  来源: 从 HomePage.ets SBox @Builder 抽取。
//  ============================================================================

import { TEXT, TEXT_3, BORDER, F_XS, F_MD } from "common"

@Component
export struct StatsBox {
  @Prop value: string = ""
  @Prop label: string = ""

  build() {
    Column() {
      Text(this.value)
        .fontSize(F_MD + 1)
        .fontWeight(700)
        .fontColor(TEXT)
      Text(this.label)
        .fontSize(F_XS)
        .fontColor(TEXT_3)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .padding({ top: 10, bottom: 10 })
    .borderRadius(12)
    .backgroundColor("#08FFFFFF")
    .border({ width: 1, color: BORDER })
    .alignItems(HorizontalAlign.Center)
  }
}
