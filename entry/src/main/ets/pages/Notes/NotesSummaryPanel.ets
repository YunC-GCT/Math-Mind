/**
 * NotesSummaryPanel.ets — 笔记页一级概览块
 *
 * 路径: pages/Notes/NotesSummaryPanel.ets
 * 职责: 在 Notes 一级页用低高度面板展示笔记总数、学科数、本周新增和学科分布。
 * 依赖: common 视觉令牌、NotesViewModel.SubjectGroup
 *
 * 数据流:
 *   NotesViewModel.subjectGroups / notes / weeklyNewCount
 *     → NotesSummaryPanel
 *       → 一级页紧凑总览
 *
 * ArkTS 1.1 strict 适配:
 *   - 无 any/unknown
 *   - 无 C 风格 for
 *   - struct 内只使用 @Builder
 */

import {
  BG_CARD, BORDER, GLASS_8, TEXT, TEXT_2, TEXT_3,
  S_1, S_2, S_3, S_4,
  R_LG,
  F_XS, F_MD,
  W_BOLD, W_SEMIBOLD,
  borderToneColor,
} from "common"
import { SubjectGroup } from "../../viewmodels/NotesViewModel"

class SummaryMetric {
  label: string
  value: string

  constructor(label: string, value: string) {
    this.label = label
    this.value = value
  }
}

function topSubjectGroups(groups: SubjectGroup[]): SubjectGroup[] {
  const result: SubjectGroup[] = []
  let index: number = 0
  while (index < groups.length && result.length < 4) {
    if (groups[index].count > 0) {
      result.push(groups[index])
    }
    index++
  }
  return result
}

function metrics(totalCount: number, subjectCount: number, weeklyNewCount: number): SummaryMetric[] {
  return [
    new SummaryMetric("全部笔记", totalCount.toString()),
    new SummaryMetric("学科分组", subjectCount.toString()),
    new SummaryMetric("本周新增", weeklyNewCount.toString()),
  ]
}

@Component
export struct NotesSummaryPanel {
  @Prop totalCount: number = 0
  @Prop subjectCount: number = 0
  @Prop weeklyNewCount: number = 0
  @Prop groups: SubjectGroup[] = []

  build() {
    Column() {
      Row() {
        ForEach(metrics(this.totalCount, this.subjectCount, this.weeklyNewCount),
          (item: SummaryMetric, index: number): void => {
            if (index > 0) {
              Row()
                .width(1)
                .height(28)
                .backgroundColor(GLASS_8)
            }
            this.MetricCell(item)
          },
          (item: SummaryMetric): string => item.label
        )
      }
      .width("100%")
      .height(44)
      .alignItems(VerticalAlign.Center)

      if (topSubjectGroups(this.groups).length > 0) {
        Row() {
          ForEach(topSubjectGroups(this.groups),
            (group: SubjectGroup): void => {
              Row()
                .height(5)
                .borderRadius(3)
                .backgroundColor(borderToneColor(group.color))
                .layoutWeight(group.count)
            },
            (group: SubjectGroup): string => group.subject + "_bar"
          )
        }
        .width("100%")
        .height(5)
        .margin({ top: S_2 })
        .alignItems(VerticalAlign.Center)

        Flex({
          direction: FlexDirection.Row,
          wrap: FlexWrap.Wrap,
          justifyContent: FlexAlign.Start,
          alignItems: ItemAlign.Center,
        }) {
          ForEach(topSubjectGroups(this.groups),
            (group: SubjectGroup): void => {
              Row() {
                Circle({ width: 6, height: 6 })
                  .fill(borderToneColor(group.color))
                  .stroke(borderToneColor(group.color))
                  .strokeWidth(1)
                  .margin({ right: S_1 })
                Text(group.subject + " " + group.count.toString())
                  .fontSize(F_XS)
                  .fontColor(TEXT_3)
                  .maxLines(1)
              }
              .height(16)
              .margin({ right: S_3, top: S_1 })
              .alignItems(VerticalAlign.Center)
            },
            (group: SubjectGroup): string => group.subject + "_legend"
          )
        }
        .width("100%")
        .margin({ top: S_1 })
      } else {
        Text("暂无学科分布")
          .fontSize(F_XS)
          .fontColor(TEXT_3)
          .margin({ top: S_2 })
      }
    }
    .width("100%")
    .padding({ left: S_4, right: S_4, top: S_3, bottom: S_3 })
    .backgroundColor(BG_CARD)
    .border({ width: 0.5, color: BORDER })
    .borderRadius(R_LG)
  }

  @Builder
  MetricCell(item: SummaryMetric) {
    Column() {
      Text(item.value)
        .fontSize(F_MD + 2)
        .fontWeight(W_BOLD)
        .fontColor(TEXT)
        .maxLines(1)
      Text(item.label)
        .fontSize(F_XS)
        .fontWeight(W_SEMIBOLD)
        .fontColor(TEXT_2)
        .maxLines(1)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height(44)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
