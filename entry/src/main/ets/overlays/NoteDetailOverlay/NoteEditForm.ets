// ============================================================================
//  overlays/NoteDetailOverlay/NoteEditForm.ets - note create/edit form
// ============================================================================

import {
  BG_CARD,
  BORDER,
  TEXT,
  TEXT_2,
  TEXT_3,
  F_SM,
  F_BASE,
  W_SEMIBOLD,
  R_MD,
  S_2,
  S_3,
  S_5,
} from 'common'

@Component
export struct NoteEditForm {
  @Prop titleText: string = ''
  @Prop summaryText: string = ''
  @Prop contentText: string = ''
  @Prop tagsText: string = ''
  onTitleChange: (value: string) => void = (_value: string): void => {}
  onSummaryChange: (value: string) => void = (_value: string): void => {}
  onContentChange: (value: string) => void = (_value: string): void => {}
  onTagsChange: (value: string) => void = (_value: string): void => {}

  build() {
    Column() {
      this.FieldLabel('标题')
      TextInput({ text: this.titleText, placeholder: '必填' })
        .height(44)
        .fontSize(F_BASE)
        .fontColor(TEXT)
        .placeholderColor(TEXT_3)
        .backgroundColor(BG_CARD)
        .borderRadius(R_MD)
        .border({ width: 1, color: BORDER })
        .padding({ left: 12, right: 12 })
        .onChange((value: string): void => { this.onTitleChange(value) })

      this.FieldLabel('摘要')
      TextArea({ text: this.summaryText, placeholder: '写下这条笔记的核心结论' })
        .height(92)
        .fontSize(F_SM)
        .fontColor(TEXT)
        .placeholderColor(TEXT_3)
        .backgroundColor(BG_CARD)
        .borderRadius(R_MD)
        .border({ width: 1, color: BORDER })
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string): void => { this.onSummaryChange(value) })

      this.FieldLabel('正文')
      TextArea({ text: this.contentText, placeholder: '支持 Markdown 和公式内容' })
        .height(220)
        .fontSize(F_SM)
        .fontColor(TEXT)
        .placeholderColor(TEXT_3)
        .backgroundColor(BG_CARD)
        .borderRadius(R_MD)
        .border({ width: 1, color: BORDER })
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string): void => { this.onContentChange(value) })

      this.FieldLabel('标签')
      TextArea({ text: this.tagsText, placeholder: '用逗号、空格或换行分隔' })
        .height(82)
        .fontSize(F_SM)
        .fontColor(TEXT)
        .placeholderColor(TEXT_3)
        .backgroundColor(BG_CARD)
        .borderRadius(R_MD)
        .border({ width: 1, color: BORDER })
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .onChange((value: string): void => { this.onTagsChange(value) })

      Blank().height(88)
    }
    .width('100%')
    .padding({ left: S_5, right: S_5, top: S_3, bottom: S_2 })
  }

  @Builder
  FieldLabel(label: string) {
    Text(label)
      .fontSize(F_SM)
      .fontWeight(W_SEMIBOLD)
      .fontColor(TEXT_2)
      .width('100%')
      .margin({ top: S_3, bottom: S_2 })
  }
}
