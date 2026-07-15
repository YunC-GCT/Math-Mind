// ============================================================================
//  components/NoteCard.ets — 笔记卡片原子组件
//  ----------------------------------------------------------------------------
//  职责: 渲染一条笔记摘要（渐变图标 + 学科/类型/日期 meta + 标题 + 摘要）。
//  消除: HomePage.NCard 与 NotesPage.NoteCard 的重复代码。
//  来源: 合并自 HomePage + NotesPage，统一设计 Token 字号。
//  ============================================================================

import {
  MINT,
  BORDER,
  TEXT,
  TEXT_3,
  TEXT_4,
  R_MD,
  F_XS,
  F_SM,
  F_BASE,
  F_MD,
  NoteItem,
  stripMD,
  recentDate,
  typeChar,
  typeColor,
  subjectColor,
} from "common"

// ---- 置信度色板 (本地常量) ----
const CONF_HIGH: string = MINT
const CONF_MID: string = "#FFFBBF24"
const CONF_LOW: string = "#FFFF6B6B"

function confColor(c: number): string {
  if (c > 0.8) {
    return CONF_HIGH
  }
  if (c > 0.5) {
    return CONF_MID
  }
  return CONF_LOW
}

@Component
export struct NoteCard {
  @Prop note: NoteItem = new NoteItem(0, "", "", "", "", 0, "", [], "")
  @Prop isLast: boolean = false
  onClick?: () => void

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
          .fontWeight(700)
          .fontColor("#FF0A0C10")
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
            .fontWeight(500)
          Text(" · ")
            .fontSize(F_XS)
            .fontColor(TEXT_4)
          Text(this.note.type)
            .fontSize(F_XS)
            .fontColor(typeColor(this.note.type))
            .fontWeight(500)
          Text(" · ")
            .fontSize(F_XS)
            .fontColor(TEXT_4)
          Text(recentDate(this.note.date))
            .fontSize(F_XS)
            .fontColor(TEXT_3)

          Blank()

          Text(Math.round(this.note.conf * 100) + "%")
            .fontSize(F_XS)
            .fontWeight(600)
            .fontColor(confColor(this.note.conf))
        }
        .width("100%")

        // 标题
        Text(this.note.title)
          .fontSize(F_SM)
          .fontWeight(600)
          .fontColor(TEXT)
          .margin({ top: 4 })
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
          .lineHeight(16)
          .width("100%")
      }
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width("100%")
    .alignItems(VerticalAlign.Top)
    .padding({ top: 14, bottom: 14 })
    .border({
      width: { bottom: this.isLast ? 0 : 1 },
      color: BORDER,
    })
    .onClick((): void => {
      if (this.onClick) {
        this.onClick()
      }
    })
  }
}
