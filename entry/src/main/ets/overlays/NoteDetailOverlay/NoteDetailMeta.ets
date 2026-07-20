// ============================================================================
// overlays/NoteDetailOverlay/NoteDetailMeta.ets - note detail header
// ============================================================================

import {
  BG_CARD, TEXT, TEXT_2, TEXT_3, BORDER, MINT,
  S_1, S_2, S_3, S_4, S_5,
  R_MD, R_LG,
  F_XS, F_SM, F_XL,
  W_MEDIUM, W_SEMIBOLD, W_BOLD,
  NoteItem,
  KnowledgeUnit,
  DifficultyLevel,
  ReviewStatus,
  recentDate,
  typeColor,
  typeGlassColor,
  glassSurfaceColor,
} from 'common'

@Component
export struct NoteDetailMeta {
  @Prop note: NoteItem = new NoteItem(0, '', '', '', '', 0, '', [], '')
  @Prop unit: KnowledgeUnit | null = null

  build() {
    Column() {
      Row() {
        if (this.categoryText().length > 0) {
          Text(this.categoryText())
            .fontSize(F_XS)
            .fontWeight(W_BOLD)
            .fontColor(typeColor(this.categoryText()))
            .padding({ left: S_3, right: S_3, top: 4, bottom: 4 })
            .borderRadius(R_MD)
            .backgroundColor(typeGlassColor(this.categoryText()))
        }

        if (this.subjectText().length > 0) {
          Text(this.subjectText())
            .fontSize(F_XS)
            .fontWeight(W_MEDIUM)
            .fontColor(TEXT_2)
            .padding({ left: S_3, right: S_3, top: 4, bottom: 4 })
            .borderRadius(R_MD)
            .backgroundColor('#10FFFFFF')
            .margin({ left: S_2 })
        }

        Blank()

        if (this.dateText().length > 0) {
          Text(this.dateText())
            .fontSize(F_XS)
            .fontColor(TEXT_3)
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.titleText())
        .fontSize(F_XL)
        .fontWeight(W_BOLD)
        .fontColor(TEXT)
        .lineHeight(28)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: S_4 })

      if (this.subtitleText().length > 0) {
        Text(this.subtitleText())
          .fontSize(F_SM)
          .fontColor(TEXT_3)
          .lineHeight(20)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: S_2 })
      }

      Row() {
        this.MetricCell('Confidence', this.confidenceText(), MINT)
        Blank().width(S_2)
        this.MetricCell('Review', this.statusTextValue(), typeColor(this.categoryText()))
        Blank().width(S_2)
        this.MetricCell('Level', this.difficultyTextValue(), TEXT_2)
      }
      .width('100%')
      .margin({ top: S_4 })
    }
    .width('100%')
    .padding({ left: S_5, right: S_5, top: S_4, bottom: S_5 })
    .backgroundColor(BG_CARD)
    .linearGradient({
      angle: 145,
      colors: [
        [glassSurfaceColor(typeColor(this.categoryText())), 0],
        [BG_CARD, 0.42],
        ['#00000000', 1],
      ],
    })
    .border({ width: { bottom: 0.5 }, color: BORDER, style: BorderStyle.Solid })
  }

  @Builder
  MetricCell(label: string, value: string, color: ResourceColor) {
    Column() {
      Text(label)
        .fontSize(F_XS)
        .fontColor(TEXT_3)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(value)
        .fontSize(F_SM)
        .fontWeight(W_SEMIBOLD)
        .fontColor(color)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: S_1 })
    }
    .layoutWeight(1)
    .padding({ left: S_3, right: S_3, top: S_2, bottom: S_2 })
    .borderRadius(R_LG)
    .backgroundColor('#0AFFFFFF')
    .border({ width: 0.5, color: BORDER })
  }

  private dateText = (): string => {
    if (this.unit !== null) {
      return this.unit.updatedAt > 0 ? this.formatDate(this.unit.updatedAt) : this.formatDate(this.unit.createdAt)
    }
    return recentDate(this.note.date)
  }

  private titleText = (): string => {
    if (this.unit !== null && this.unit.title.trim().length > 0) {
      return this.unit.title.trim()
    }
    if (this.note.title.trim().length > 0) {
      return this.note.title.trim()
    }
    return 'Untitled note'
  }

  private subtitleText = (): string => {
    let raw: string = ''
    if (this.unit !== null && this.unit.summary.trim().length > 0) {
      raw = this.unit.summary.trim()
    } else if (this.note.chapter.trim().length > 0) {
      raw = this.note.chapter.trim()
    }
    return this.compactOverview(raw)
  }

  private compactOverview = (raw: string): string => {
    let text: string = raw
      .replace(/\r\n/g, ' ')
      .replace(/\r/g, ' ')
      .replace(/\n/g, ' ')
      .replace(/#{1,6}\s*/g, '')
      .replace(/\*\*/g, '')
      .replace(/\*/g, '')
      .replace(/`/g, '')
      .replace(/\$\$/g, ' ')
      .replace(/\$/g, '')
      .replace(/\\\[/g, ' ')
      .replace(/\\\]/g, ' ')
      .replace(/\\\(/g, ' ')
      .replace(/\\\)/g, ' ')
      .replace(/\\text\{([^{}]*)\}/g, '$1')
      .replace(/\\operatorname\{([^{}]*)\}/g, '$1')
      .replace(/\\(?:bar|hat|tilde|vec)\{([^{}]*)\}/g, '$1')
      .replace(/\\(?:varphi|varepsilon|epsilon|theta|mu|sigma|alpha|beta|lambda|pi|Phi|Omega|Delta)\b/g, '')
      .replace(/\\[a-zA-Z]+(?:\s*\{[^{}]*\})?/g, ' ')
      .replace(/[{}_^]/g, ' ')
      .replace(/\\/g, ' ')
      .replace(/\s+/g, ' ')
      .trim()
    text = this.trimOverviewPrefix(text)
    const limit: number = 58
    if (text.length > limit) {
      return text.substring(0, limit).trim() + '...'
    }
    return text
  }

  private trimOverviewPrefix = (text: string): string => {
    const prefixes: string[] = ['摘要:', '摘要：', '内容:', '内容：', '定义:', '定义：', '题目:', '题目：']
    for (const prefix of prefixes) {
      if (text.indexOf(prefix) === 0) {
        return text.substring(prefix.length).trim()
      }
    }
    return text
  }

  private subjectText = (): string => {
    if (this.unit !== null && this.unit.subject.trim().length > 0) {
      return this.unit.subject.trim()
    }
    return this.note.subject.trim()
  }

  private categoryText = (): string => {
    if (this.unit !== null && this.unit.category.trim().length > 0) {
      return this.unit.category.trim()
    }
    return this.note.type.trim()
  }

  private confidenceText = (): string => {
    const raw: number = this.note.conf > 0 ? this.note.conf : 0
    return Math.round(raw * 100).toString() + '%'
  }

  private statusTextValue = (): string => {
    if (this.unit === null) {
      return 'New'
    }
    return this.statusText(this.unit.reviewStatus)
  }

  private difficultyTextValue = (): string => {
    if (this.unit === null) {
      return '--'
    }
    return this.difficultyText(this.unit.difficulty)
  }

  private formatDate = (ts: number): string => {
    const d: Date = new Date(ts > 0 ? ts : Date.now())
    const m: string = d.getMonth() + 1 < 10 ? '0' + (d.getMonth() + 1).toString() : (d.getMonth() + 1).toString()
    const day: string = d.getDate() < 10 ? '0' + d.getDate().toString() : d.getDate().toString()
    return d.getFullYear().toString() + '-' + m + '-' + day
  }

  private statusText = (status: ReviewStatus): string => {
    if (status === ReviewStatus.LEARNING) { return 'Learning' }
    if (status === ReviewStatus.REVIEW) { return 'Review' }
    if (status === ReviewStatus.GRADUATED) { return 'Mastered' }
    if (status === ReviewStatus.LAPSED) { return 'Lapsed' }
    return 'New'
  }

  private difficultyText = (level: DifficultyLevel): string => {
    if (level === DifficultyLevel.EASY) { return 'Easy' }
    if (level === DifficultyLevel.MEDIUM) { return 'Medium' }
    if (level === DifficultyLevel.HARD) { return 'Hard' }
    return 'Expert'
  }
}
