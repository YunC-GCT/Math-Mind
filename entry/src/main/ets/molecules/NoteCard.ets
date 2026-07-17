// ============================================================================
//  molecules/NoteCard.ets — 笔记卡片 · 对齐 v2-ui .note-card
//  ----------------------------------------------------------------------------
//  布局: [渐变 icon 36×36] [meta: 类型(粗) · 日期  ··· 置信度]
//                          [标题 (15px semibold)]
//                          [正文预览 (2 行截断)]
//  ============================================================================

import {
  BG_DARK, S_1, S_3, BORDER, TEXT, TEXT_3, TEXT_4,
  R_MD, F_XS, F_SM, F_MD,
  W_MEDIUM, W_SEMIBOLD, W_BOLD,
  NOTE_ICON_SIZE, NoteItem, recentDate, typeChar, typeColor,
} from "common"

@Component
export struct NoteCard {
  @Prop note: NoteItem = new NoteItem(0, "", "", "", "", 0, "", [], "")
  @Prop isLast: boolean = false
  onTap?: () => void

  build() {
    Row() {
      // 左侧渐变图标 (v2-ui .note-icon)
      Stack() {
        Stack()
          .width(NOTE_ICON_SIZE).height(NOTE_ICON_SIZE).borderRadius(R_MD + 1)
          .linearGradient({
            angle: 135,
            colors: [[typeColor(this.note.type), 0], [typeColor(this.note.type), 1]],
          })
        Text(typeChar(this.note.type))
          .fontSize(F_MD + 2).fontWeight(W_BOLD).fontColor(BG_DARK)
      }
      .width(NOTE_ICON_SIZE).height(NOTE_ICON_SIZE).alignContent(Alignment.Center)

      // 右侧内容 (v2-ui .note-info)
      Column() {
        // Meta 行 (v2-ui .note-meta: type bold · date ··· conf)
        Row() {
          Text(this.note.type)
            .fontSize(F_XS).fontColor(typeColor(this.note.type)).fontWeight(W_BOLD)
          Text(' · ').fontSize(F_XS).fontColor(TEXT_4)
          Text(recentDate(this.note.date)).fontSize(F_XS).fontColor(TEXT_3)

          Blank()

          Text(Math.round(this.note.conf * 100).toString() + '%')
            .fontSize(F_XS).fontWeight(W_SEMIBOLD).fontColor(typeColor(this.note.type))
        }.width('100%')

        // 标题 (v2-ui .note-title: 15px semibold)
        Text(this.note.title)
          .fontSize(F_MD).fontWeight(W_SEMIBOLD).fontColor(TEXT)
          .margin({ top: S_1 }).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')

        // 正文预览 (v2-ui .note-body: 12.5px 2行截断)
        Text(this.note.body)
          .fontSize(F_SM).fontColor(TEXT_3)
          .margin({ top: 2 }).maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
      }
      .layoutWeight(1).margin({ left: S_3 })
    }
    .width('100%').alignItems(VerticalAlign.Top)
    .padding({ top: S_3, bottom: S_3 })
    .border({ width: { bottom: this.isLast ? 0 : 1 }, color: BORDER })
    .onClick((): void => { if (this.onTap) { this.onTap() } })
  }
}
