// ============================================================================
//  components/NoteCard.ets — 笔记卡片原子组件
//  ----------------------------------------------------------------------------
//  职责: 渲染一条笔记摘要（渐变图标 + 学科/类型/日期 meta + 标题 + 摘要）。
//  消除: HomePage.NCard 与 NotesPage.NoteCard 的重复代码。
//  来源: 合并自 HomePage + NotesPage，统一设计 Token 字号。
//  ============================================================================

import {
  BG_DARK,
  S_1, S_3,
  BORDER,
  TEXT,
  TEXT_3,
  TEXT_4,
  R_MD,
  F_XS,
  F_SM,
  F_MD,
  W_MEDIUM, W_SEMIBOLD, W_BOLD,
  LH_TIGHT,
  NoteItem,
  stripMD,
  recentDate,
  typeChar,
  typeColor,
  subjectColor,
} from "common"
import { confColor } from "../atoms/ConfBadge"

@Component
export struct NoteCard {
  @Prop note: NoteItem = new NoteItem(0, "", "", "", "", 0, "", [], "")
  @Prop isLast: boolean = false
  onTap?: () => void

  build() {
    Row() {
      // ---- 渐变图标 36×36 ----
      Stack() {
        Stack()
          .width(36).height(36)
          .borderRadius(R_MD + 1)
          .linearGradient({
            angle: 135,
            colors: [
              [typeColor(this.note.type), 0],
              [subjectColor(this.note.subject), 1],
            ],
          })

        Text(typeChar(this.note.type))
          .fontSize(F_MD + 2)
          .fontWeight(W_BOLD)
          .fontColor(BG_DARK)
      }
      .width(36).height(36)
      .alignContent(Alignment.Center)

      // ---- 右侧内容 ----
      Column() {
        // Meta 行：学科 · 类型 · 日期 · 置信度
        Row() {
          Text(this.note.subject)
            .fontSize(F_XS)
            .fontColor(subjectColor(this.note.subject))
            .fontWeight(W_MEDIUM)
          Text(" · ")
            .fontSize(F_XS)
            .fontColor(TEXT_4)
          Text(this.note.type)
            .fontSize(F_XS)
            .fontColor(typeColor(this.note.type))
            .fontWeight(W_MEDIUM)
          Text(" · ")
            .fontSize(F_XS)
            .fontColor(TEXT_4)
          Text(recentDate(this.note.date))
            .fontSize(F_XS)
            .fontColor(TEXT_3)

          Blank()

          Text(Math.round(this.note.conf * 100) + "%")
            .fontSize(F_XS)
            .fontWeight(W_SEMIBOLD)
            .fontColor(confColor(this.note.conf))
        }
        .width("100%")

        // 标题
        Text(this.note.title)
          .fontSize(F_SM)
          .fontWeight(W_SEMIBOLD)
          .fontColor(TEXT)
          .margin({ top: S_1 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width("100%")

        // 摘要（2 行截断）
        Text(stripMD(this.note.body, 80))
          .fontSize(F_XS)
          .fontColor(TEXT_3)
          .margin({ top: 2 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(LH_TIGHT)
          .width("100%")
      }
      .layoutWeight(1)
      .margin({ left: S_3 })
    }
    .width("100%")
    .alignItems(VerticalAlign.Top)
    .padding({ top: S_3, bottom: S_3 })
    .border({
      width: { bottom: this.isLast ? 0 : 1 },
      color: BORDER,
    })
    .onClick((): void => {
      if (this.onTap) {
        this.onTap()
      }
    })
  }
}
