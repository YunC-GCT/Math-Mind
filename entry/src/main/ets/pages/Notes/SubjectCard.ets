// ============================================================================
//  pages/Notes/SubjectCard.ets - subject card on notes page
// ============================================================================

import { BG_CARD, BORDER, TEXT, TEXT_3, TEXT_4, GLASS_8, S_1, S_2, S_3, S_4, R_LG, F_XS, F_MD, W_SEMIBOLD } from "common"

@Component
export struct SubjectCard {
  @Prop subject: string = ""
  @Prop color: string = ""
  @Prop count: number = 0
  @Prop previewTitles: string[] = []
  onTap: () => void = (): void => {}

  build() {
    Column() {
      Row() {
        Stack() {
          Circle({ width: 38, height: 38 })
            .fill(this.toneBg())
          Text(this.subjectMark())
            .fontSize(F_MD - 1)
            .fontWeight(W_SEMIBOLD)
            .fontColor(this.color)
        }
        .width(38)
        .height(38)
        .alignContent(Alignment.Center)
        .margin({ right: S_3 })

        Column() {
          Text(this.subject)
            .fontSize(F_MD - 1)
            .fontWeight(W_SEMIBOLD)
            .fontColor(TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width("100%")

          Text(this.count.toString() + " 条笔记")
            .fontSize(F_XS)
            .fontColor(TEXT_3)
            .margin({ top: S_1 })
            .width("100%")
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)

      Column() {
        ForEach(this.previewTitles,
          (title: string): void => {
            Row() {
              Circle({ width: 3, height: 3 })
                .fill(this.color)
                .margin({ right: 6 })
                .flexShrink(0)

              Text(title)
                .fontSize(F_XS)
                .fontColor(TEXT_4)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .width("100%")
            .height(18)
            .alignItems(VerticalAlign.Center)
          },
          (title: string): string => title
        )
      }
      .width("100%")
      .height(58)
      .margin({ top: S_3 })
      .padding({ left: 2, right: 2 })
      .alignItems(HorizontalAlign.Start)
    }
    .width("100%")
    .height(142)
    .padding({ left: S_4, right: S_4, top: S_3, bottom: S_3 })
    .backgroundColor(BG_CARD)
    .border({ width: 0.5, color: this.borderTone() })
    .borderRadius(R_LG)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
    .onClick((): void => this.onTap())
  }

  private subjectMark(): string {
    if (this.subject === "高等代数") { return "代" }
    if (this.subject === "数学分析") { return "析" }
    if (this.subject === "解析几何" || this.subject === "空间解析几何") { return "几" }
    if (this.subject === "概率统计" || this.subject.indexOf("概率") >= 0 || this.subject.indexOf("统计") >= 0) { return "概" }
    if (this.subject === "未分类") { return "未" }
    return this.subject.length > 0 ? this.subject.substring(0, 1) : "记"
  }

  private toneBg(): string {
    if (this.subject === "高等代数") { return "#249775FA" }
    if (this.subject === "数学分析") { return "#1AFF6B9D" }
    if (this.subject === "解析几何" || this.subject === "空间解析几何") { return "#24F0C674" }
    if (this.subject === "未分类") { return GLASS_8 }
    return this.color.length > 0 ? "#145BE3B0" : GLASS_8
  }

  private borderTone(): string {
    if (this.subject === "未分类" || this.color.length === 0) {
      return BORDER
    }
    return this.color
  }
}
