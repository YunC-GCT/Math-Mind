// ============================================================================
//  overlays/NoteDetailOverlay/NoteDetailBody.ets - selective note body
// ============================================================================

import {
  TEXT_3,
  S_2, S_3,
  F_SM,
  W_BOLD,
  NoteItem,
  KnowledgeUnit,
  DifficultyLevel,
  ReviewStatus,
} from 'common'
import { parseSections, Section } from '../../utils/NoteSectionParser'
import { ChipTag } from './ChipTag'
import { NoteSectionView } from './NoteSection'

@Component
export struct NoteDetailBody {
  @Prop note: NoteItem = new NoteItem(0, '', '', '', '', 0, '', [], '')
  @Prop unit: KnowledgeUnit | null = null
  @Prop units: KnowledgeUnit[] = []

  build() {
    Column() {
      if (this.summaryText().length > 0) {
        NoteSectionView({ title: '摘要', content: this.summaryText() })
      }

      if (this.bodyText().length > 0) {
        Column() {
          ForEach(parseSections(this.bodyText()),
            (sec: Section): void => {
              NoteSectionView({ title: sec.title, content: sec.content })
            },
            (sec: Section): string => sec.title + '_' + sec.content.length.toString()
          )
        }
        .width('100%')
        .padding({ bottom: 8 })
      } else if (this.summaryText().length === 0) {
        NoteSectionView({ title: '内容', content: '暂无正文' })
      }

      if (this.detailTags().length > 0) {
        Text('标签')
          .fontSize(F_SM)
          .fontWeight(W_BOLD)
          .fontColor(TEXT_3)
          .padding({ top: S_3, bottom: S_2 })

        Flex({
          direction: FlexDirection.Row,
          wrap: FlexWrap.Wrap,
          justifyContent: FlexAlign.Start,
          alignItems: ItemAlign.Center,
        }) {
          ForEach(this.detailTags(),
            (tag: string): void => {
              Row() {
                ChipTag({ label: tag, variant: 'tag' })
              }
              .margin({ right: S_2, bottom: S_2 })
            },
            (tag: string): string => tag
          )
        }
        .width('100%')
        .padding({ bottom: 8 })
      }

      if (this.prerequisites().length > 0) {
        Text('前置知识')
          .fontSize(F_SM)
          .fontWeight(W_BOLD)
          .fontColor(TEXT_3)
          .padding({ top: S_3, bottom: S_2 })

        Flex({
          direction: FlexDirection.Row,
          wrap: FlexWrap.Wrap,
          justifyContent: FlexAlign.Start,
          alignItems: ItemAlign.Center,
        }) {
          ForEach(this.prerequisites(),
            (label: string): void => {
              Row() {
                ChipTag({ label: label, variant: 'chip' })
              }
              .margin({ right: S_2, bottom: S_2 })
            },
            (label: string): string => 'pre_' + label
          )
        }
        .width('100%')
        .padding({ bottom: 8 })
      }

      if (this.related().length > 0) {
        Text('相关知识')
          .fontSize(F_SM)
          .fontWeight(W_BOLD)
          .fontColor(TEXT_3)
          .padding({ top: S_3, bottom: S_2 })

        Flex({
          direction: FlexDirection.Row,
          wrap: FlexWrap.Wrap,
          justifyContent: FlexAlign.Start,
          alignItems: ItemAlign.Center,
        }) {
          ForEach(this.related(),
            (label: string): void => {
              Row() {
                ChipTag({ label: label, variant: 'chip' })
              }
              .margin({ right: S_2, bottom: S_2 })
            },
            (label: string): string => 'rel_' + label
          )
        }
        .width('100%')
        .padding({ bottom: 8 })
      }

      if (this.sourceText().length > 0) {
        NoteSectionView({ title: '来源', content: this.sourceText() })
      }

      if (this.studyStateText().length > 0) {
        NoteSectionView({ title: '复习状态', content: this.studyStateText() })
      }

      Blank().height(80)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: S_3, bottom: S_2 })
  }

  private summaryText(): string {
    if (this.unit === null) {
      return ''
    }
    return this.unit.summary.trim()
  }

  private bodyText(): string {
    if (this.unit !== null) {
      return this.unit.content.trim()
    }
    return this.note.body.trim()
  }

  private detailTags(): string[] {
    if (this.unit !== null && this.unit.tags.length > 0) {
      return this.unit.tags.filter((tag: string): boolean => tag.trim().length > 0)
    }
    return this.note.tags.filter((tag: string): boolean => tag.trim().length > 0)
  }

  private prerequisites(): string[] {
    if (this.unit === null || this.unit.prerequisites.length === 0) {
      return []
    }
    return this.unit.prerequisites.map((id: string): string => this.lookupTitle(id))
  }

  private related(): string[] {
    if (this.unit === null || this.unit.related.length === 0) {
      return []
    }
    return this.unit.related.map((id: string): string => this.lookupTitle(id))
  }

  private sourceText(): string {
    if (this.unit !== null) {
      return this.unit.source.trim()
    }
    return this.note.chapter.trim()
  }

  private studyStateText(): string {
    if (this.unit === null) {
      return ''
    }
    const lines: string[] = []
    lines.push('状态: ' + this.reviewStatusText(this.unit.reviewStatus))
    lines.push('难度: ' + this.difficultyText(this.unit.difficulty))
    lines.push('间隔: ' + this.unit.intervalDays.toString() + ' 天')
    lines.push('复习次数: ' + this.unit.repetitions.toString())
    lines.push('易度: ' + this.unit.easeFactor.toFixed(1))
    if (this.unit.nextReviewAt > 0) {
      lines.push('下次复习: ' + this.formatDate(this.unit.nextReviewAt))
    }
    return lines.join('\n')
  }

  private lookupTitle(id: string): string {
    const found: KnowledgeUnit | undefined = this.units.find((unit: KnowledgeUnit): boolean => unit.id === id)
    return found !== undefined && found.title.length > 0 ? found.title : id
  }

  private reviewStatusText(status: ReviewStatus): string {
    if (status === ReviewStatus.LEARNING) { return '学习中' }
    if (status === ReviewStatus.REVIEW) { return '复习中' }
    if (status === ReviewStatus.GRADUATED) { return '已掌握' }
    if (status === ReviewStatus.LAPSED) { return '需重学' }
    return '新笔记'
  }

  private difficultyText(level: DifficultyLevel): string {
    if (level === DifficultyLevel.EASY) { return '简单' }
    if (level === DifficultyLevel.MEDIUM) { return '中等' }
    if (level === DifficultyLevel.HARD) { return '困难' }
    return '专家'
  }

  private formatDate(ts: number): string {
    const d: Date = new Date(ts > 0 ? ts : Date.now())
    const month: string = d.getMonth() + 1 < 10 ? '0' + (d.getMonth() + 1).toString() : (d.getMonth() + 1).toString()
    const day: string = d.getDate() < 10 ? '0' + d.getDate().toString() : d.getDate().toString()
    return d.getFullYear().toString() + '-' + month + '-' + day
  }
}
