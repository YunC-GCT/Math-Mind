// ============================================================================
//  overlays/NoteDetailOverlay/NoteDetailMeta.ets - compact note meta row
// ============================================================================

import {
  TEXT_3, TEXT_4, BORDER,
  S_1, S_2, S_4,
  F_XS,
  NoteItem,
  KnowledgeUnit,
  DifficultyLevel,
  ReviewStatus,
  recentDate,
} from 'common'
import { ChipTag } from './ChipTag'

@Component
export struct NoteDetailMeta {
  @Prop note: NoteItem = new NoteItem(0, '', '', '', '', 0, '', [], '')
  @Prop unit: KnowledgeUnit | null = null

  build() {
    Column() {
      Row() {
        if (this.primaryLabel().length > 0) {
          ChipTag({ label: this.primaryLabel(), variant: 'chip' })
        }
        if (this.secondaryLabel().length > 0) {
          ChipTag({ label: this.secondaryLabel(), variant: 'tag' }).margin({ left: S_2 })
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

      if (this.metaLine().length > 0) {
        Text(this.metaLine())
          .fontSize(F_XS)
          .fontColor(TEXT_4)
          .margin({ top: S_2 })
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: S_1, bottom: S_4 })
    .border({ width: { bottom: 0.5 }, color: BORDER, style: BorderStyle.Solid })
  }

  private primaryLabel(): string {
    if (this.unit !== null && this.unit.tags.length > 0 && this.unit.tags[0].trim().length > 0) {
      return this.unit.tags[0].trim()
    }
    return this.note.subject.trim()
  }

  private secondaryLabel(): string {
    if (this.unit !== null && this.unit.tags.length > 1 && this.unit.tags[1].trim().length > 0) {
      return this.unit.tags[1].trim()
    }
    return this.note.type.trim()
  }

  private dateText(): string {
    if (this.unit !== null) {
      return this.unit.updatedAt > 0 ? this.formatDate(this.unit.updatedAt) : this.formatDate(this.unit.createdAt)
    }
    return recentDate(this.note.date)
  }

  private metaLine(): string {
    const parts: string[] = []
    if (this.unit === null) {
      if (this.note.chapter.trim().length > 0) {
        parts.push(this.note.chapter.trim())
      }
      return parts.join(' · ')
    }
    if (this.unit.source.trim().length > 0) {
      parts.push(this.unit.source.trim())
    }
    parts.push(this.statusText(this.unit.reviewStatus))
    parts.push(this.difficultyText(this.unit.difficulty))
    if (this.unit.nextReviewAt > 0) {
      parts.push('Next ' + this.formatDate(this.unit.nextReviewAt))
    }
    return parts.join(' · ')
  }

  private formatDate(ts: number): string {
    const d: Date = new Date(ts > 0 ? ts : Date.now())
    const m: string = d.getMonth() + 1 < 10 ? '0' + (d.getMonth() + 1).toString() : (d.getMonth() + 1).toString()
    const day: string = d.getDate() < 10 ? '0' + d.getDate().toString() : d.getDate().toString()
    return d.getFullYear().toString() + '-' + m + '-' + day
  }

  private statusText(status: ReviewStatus): string {
    if (status === ReviewStatus.LEARNING) { return 'Learning' }
    if (status === ReviewStatus.REVIEW) { return 'Review' }
    if (status === ReviewStatus.GRADUATED) { return 'Mastered' }
    if (status === ReviewStatus.LAPSED) { return 'Lapsed' }
    return 'New'
  }

  private difficultyText(level: DifficultyLevel): string {
    if (level === DifficultyLevel.EASY) { return 'Level 1' }
    if (level === DifficultyLevel.MEDIUM) { return 'Level 2' }
    if (level === DifficultyLevel.HARD) { return 'Level 3' }
    return 'Level 4'
  }
}