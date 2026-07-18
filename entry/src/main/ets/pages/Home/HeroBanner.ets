// ============================================================================
//  pages/Home/HeroBanner.ets — 首页 Hero 横幅分子组件
//  ----------------------------------------------------------------------------
//  职责: 组装问候行 + 日期 + GradientRing 进度环 + StatsBox 统计方块。
//  来源: 从 HomePage.ets 提取，消除内联 50 行 UI。
//  数据流: 全部 @Prop 单向，回调 onGoReview 通知父组件。
//  接口:
//    @Prop  greeting   — 问候语 ("上午好")
//    @Prop  dateText   — 日期字符串
//    @Prop  avg        — 掌握率百分比 (0-100)
//    @Prop  notesCount — 笔记总数
//    @Prop  todayCount — 今日新增数
//    onGoReview         — 点击进度环回调
//  依赖: GradientRing (pages/Home), StatsBox (atoms)
//  ============================================================================

import {
  MINT, MINT_LIGHT, PURPLE_LIGHT, PINK_LIGHT,
  TEXT, TEXT_3,
  S_1, S_2, S_5, S_6,
  R_2XL,
  F_SM, F_BASE, F_2XL,
  W_SEMIBOLD, W_BOLD,
  HERO_RING_SIZE, DOT_SIZE,
} from "common"
import { GradientRing } from "./GradientRing"
import { StatsBox } from "../../shared/components/StatsBox"

@Component
export struct HeroBanner {
  @Prop greeting: string = ""
  @Prop dateText: string = ""
  @Prop avg: number = 75
  @Prop notesCount: number = 0
  @Prop todayCount: number = 0
  onGoReview: () => void = (): void => {}

  build() {
    Column() {
      // 问候行
      Row() {
        Circle({ width: DOT_SIZE, height: DOT_SIZE }).fill(MINT)
        Text(this.greeting + ", Mini")
          .fontSize(F_2XL).fontWeight(W_BOLD).fontColor(TEXT)
          .margin({ left: S_2 }).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width("100%").alignItems(VerticalAlign.Center)

      // 日期
      Text(this.dateText)
        .fontSize(F_BASE).fontColor(TEXT_3)
        .width("100%").margin({ top: S_2 })

      // 进度环
      Stack() {
        GradientRing({ pct: this.avg })
        Column() {
          Text(this.avg + "%")
            .fontSize(F_2XL).fontWeight(W_BOLD).fontColor(TEXT)
          Text("去复习 >")
            .fontSize(F_SM).fontColor(MINT).fontWeight(W_SEMIBOLD)
            .margin({ top: S_1 })
        }.alignItems(HorizontalAlign.Center)
      }
      .width(HERO_RING_SIZE).height(HERO_RING_SIZE)
      .alignSelf(ItemAlign.Center).margin({ top: S_6 })
      .onClick((): void => { this.onGoReview() })

      // 统计方块
      Row() {
        StatsBox({ value: this.notesCount + "", label: "笔记" })
        StatsBox({ value: this.avg + "%", label: "掌握率" })
        StatsBox({ value: this.todayCount + "", label: "今日新增" })
      }
      .width("100%").justifyContent(FlexAlign.SpaceEvenly).margin({ top: S_5 })
    }
    .width("100%")
    .padding({ left: S_5, right: S_5, top: S_5, bottom: S_6 })
    .borderRadius({ bottomLeft: R_2XL, bottomRight: R_2XL })
    .linearGradient({
      angle: 180,
      colors: [
        [MINT_LIGHT, 0],
        [PURPLE_LIGHT, 0.5],
        [PINK_LIGHT, 1],
      ],
    })
  }
}
