// ============================================================================
//  pages/Home/HeroBanner.ets — 首页 Hero 横幅分子组件
//  ----------------------------------------------------------------------------
//  职责: 组装问候行 + 日期 + GradientRing 进度环 + 紧凑指标行。
//  来源: 从 HomePage.ets 提取，消除内联 50 行 UI。
//  数据流: 全部 @Prop 单向，回调 onGoReview 通知父组件。
//  接口:
//    @Prop  greeting   — 问候语 ("上午好")
//    @Prop  dateText   — 日期字符串
//    @Prop  avg        — 掌握率百分比 (0-100)
//    @Prop  notesCount — 笔记总数
//    @Prop  todayCount — 今日新增数
//    onGoReview         — 点击进度环回调
//  依赖: GradientRing (pages/Home)
//  ============================================================================

import {
  MINT, MINT_LIGHT, MINT_BORDER, PURPLE_LIGHT, PINK_LIGHT,
  TEXT, TEXT_2, TEXT_3, GLASS_14,
  S_1, S_2, S_3, S_4, S_5,
  R_LG, R_2XL,
  F_XS, F_SM, F_BASE, F_2XL,
  W_SEMIBOLD, W_BOLD,
  HERO_RING_SIZE, DOT_SIZE,
} from "common"
import { GradientRing } from "./GradientRing"

@Component
export struct HeroBanner {
  @Prop greeting: string = ""
  @Prop dateText: string = ""
  @Prop avg: number = 75
  @Prop notesCount: number = 0
  @Prop todayCount: number = 0
  @Prop heroHeight: number = 278
  @Prop ringTopMargin: number = S_3
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
      .alignSelf(ItemAlign.Center).margin({ top: this.ringTopMargin })
      .onClick((): void => { this.onGoReview() })

      // 紧凑指标行
      Row() {
        this.Metric(this.notesCount + "条", "累计")
        this.Separator()
        this.Metric(this.avg + "%", "掌握")
        this.Separator()
        this.Metric(this.todayCount + "条", "今日")
      }
      .width("100%")
      .height(38)
      .justifyContent(FlexAlign.SpaceEvenly)
      .alignItems(VerticalAlign.Center)
      .margin({ top: S_3 })
      .padding({ left: S_3, right: S_3 })
      .borderRadius(R_LG)
      .border({ width: 0.5, color: MINT_BORDER })
      .linearGradient({
        angle: 105,
        colors: [
          [MINT_LIGHT, 0],
          [GLASS_14, 0.5],
          [PURPLE_LIGHT, 1],
        ],
      })
      .shadow({ radius: 14, color: "#245BE3B0", offsetX: 0, offsetY: 4 })
    }
    .width("100%")
    .height(this.heroHeight)
    .padding({ left: S_5, right: S_5, top: S_4, bottom: S_4 })
    .borderRadius({ bottomLeft: R_2XL, bottomRight: R_2XL })
    .linearGradient({
      angle: 180,
      colors: [
        [MINT_LIGHT, 0],
        [PURPLE_LIGHT, 0.42],
        [PINK_LIGHT, 0.74],
        ["#000A0C10", 1],
      ],
    })
  }

  @Builder
  Metric(value: string, label: string) {
    Row() {
      Text(value)
        .fontSize(F_BASE)
        .fontWeight(W_BOLD)
        .fontColor(TEXT)
        .fontFamily("HarmonyOS Sans Condensed")
      Text(label)
        .fontSize(F_XS)
        .fontColor(TEXT_2)
        .margin({ left: S_1 })
    }
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  Separator() {
    Row()
      .width(1)
      .height(18)
      .backgroundColor(TEXT_3)
      .opacity(0.32)
  }
}
