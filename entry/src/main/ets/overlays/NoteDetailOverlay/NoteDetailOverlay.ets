// ============================================================================
//  overlays/NoteDetailOverlay/NoteDetailOverlay.ets - note detail/editor overlay
// ============================================================================

import {
  BG_DARK, BG_CARD, TEXT, DANGER, MINT, TEXT_2, TEXT_3, BORDER,
  F_SM, F_MD,
  W_SEMIBOLD, W_BOLD,
  R_MD,
  S_3, S_4,
  OVERLAY_MASK_SOLID,
  NoteItem,
  KnowledgeUnit,
  DifficultyLevel,
  ReviewStatus,
  uuid,
  DatabaseHelper,
} from 'common'
import { promptAction } from '@kit.ArkUI'
import { NoteDao } from '../../database/NoteDao'
import { NoteCloseButton } from './NoteCloseButton'
import { NoteDetailMeta } from './NoteDetailMeta'
import { NoteDetailBody } from './NoteDetailBody'
import { NoteActionBar } from './NoteActionBar'
import { NoteIconButton } from './NoteIconButton'
import { NoteEditForm } from './NoteEditForm'

@Component
export struct NoteDetailOverlay {
  @Prop note: NoteItem = new NoteItem(0, '', '', '', '', 0, '', [], '')
  @Prop unit: KnowledgeUnit | null = null
  @Prop units: KnowledgeUnit[] = []
  @Prop isCreating: boolean = false
  @StorageProp('statusBarHeight') sbh: number = 0
  @State localUnit: KnowledgeUnit | null = null
  @State isEditing: boolean = false
  @State titleText: string = ''
  @State summaryText: string = ''
  @State contentText: string = ''
  @State tagsText: string = ''
  @State initialTitleText: string = ''
  @State initialSummaryText: string = ''
  @State initialContentText: string = ''
  @State initialTagsText: string = ''
  @State saving: boolean = false
  @State showDiscardConfirm: boolean = false
  onClose: () => void = (): void => {}
  onEdit: (id: number) => void = (_id: number): void => {}
  onDelete: (id: string) => void = (_id: string): void => {}
  onSaved: (unit: KnowledgeUnit) => void = (_unit: KnowledgeUnit): void => {}

  aboutToAppear(): void {
    if (this.isCreating) {
      this.isEditing = true
      this.loadForm(null)
    }
  }

  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(OVERLAY_MASK_SOLID)
        .onClick((): void => this.closeOrCancel())

      Column() {
        Row().width('100%').height(this.sbh).backgroundColor(BG_DARK)

        Row() {
          NoteCloseButton({ onClose: (): void => this.closeOrCancel() })

          Column() {
            Text(this.headerTitle())
              .fontSize(F_MD)
              .fontWeight(W_SEMIBOLD)
              .fontColor(TEXT)
              .lineHeight(20)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
          }
          .layoutWeight(1)
          .margin({ left: 12, right: 12 })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Start)

          if (!this.isCreating && !this.isEditing) {
            NoteIconButton({
              name: 'trash',
              color: DANGER,
              onTap: (): void => this.confirmDelete(),
            })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .alignItems(VerticalAlign.Center)

        if (!this.isEditing) {
          NoteDetailMeta({ note: this.note, unit: this.effectiveUnit() })
        }

        Scroll() {
          Column() {
            if (this.isEditing) {
              NoteEditForm({
                titleText: this.titleText,
                summaryText: this.summaryText,
                contentText: this.contentText,
                tagsText: this.tagsText,
                onTitleChange: (value: string): void => { this.titleText = value },
                onSummaryChange: (value: string): void => { this.summaryText = value },
                onContentChange: (value: string): void => { this.contentText = value },
                onTagsChange: (value: string): void => { this.tagsText = value },
              })
            } else {
              NoteDetailBody({ note: this.note, unit: this.effectiveUnit(), units: this.units })
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)

        if (this.isEditing) {
          Row() {
            Blank()
            NoteIconButton({
              name: 'close',
              color: TEXT_2,
              isEnabled: !this.saving,
              onTap: (): void => this.cancelEdit(),
            })
            Blank().width(8)
            if (this.saving) {
              NoteIconButton({
                name: 'more',
                color: TEXT_3,
                isEnabled: false,
                onTap: (): void => {},
              })
            } else {
              NoteIconButton({
                name: 'check',
                color: MINT,
                isEnabled: true,
                onTap: (): void => {
                  this.saveEdit().then((): void => {}).catch((_e: Error): void => {})
                },
              })
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 24 })
          .backgroundColor(BG_DARK)
        } else {
          NoteActionBar({
            onEdit: (): void => this.startEdit(),
            onShare: (): void => this.mockShare(),
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(BG_DARK)

      if (this.showDiscardConfirm) {
        this.DiscardConfirm()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  DiscardConfirm() {
    Column() {
      Blank()
      Column() {
        Text('放弃修改？')
          .fontSize(F_MD)
          .fontWeight(W_BOLD)
          .fontColor(TEXT)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ bottom: S_3 })

        Text('当前编辑内容尚未保存。')
          .fontSize(F_SM)
          .fontColor(TEXT_2)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ bottom: S_4 })

        Row() {
          Text('继续编辑')
            .fontSize(F_SM)
            .fontWeight(W_SEMIBOLD)
            .fontColor(TEXT_2)
            .height(40)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .borderRadius(R_MD)
            .backgroundColor('#12FFFFFF')
            .onClick((): void => {
              this.showDiscardConfirm = false
            })

          Blank().width(10)

          Text('放弃')
            .fontSize(F_SM)
            .fontWeight(W_SEMIBOLD)
            .fontColor(BG_DARK)
            .height(40)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .borderRadius(R_MD)
            .backgroundColor(MINT)
            .onClick((): void => this.discardEdit())
        }
        .width('100%')
      }
      .width('78%')
      .padding({ left: S_4, right: S_4, top: S_4, bottom: S_4 })
      .borderRadius(R_MD + 4)
      .backgroundColor(BG_CARD)
      .border({ width: 1, color: BORDER })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(OVERLAY_MASK_SOLID)
    .onClick((): void => {
      this.showDiscardConfirm = false
    })
  }

  private effectiveUnit(): KnowledgeUnit | null {
    return this.localUnit !== null ? this.localUnit : this.unit
  }

  private headerTitle(): string {
    if (this.isCreating) {
      return 'New note'
    }
    if (this.isEditing) {
      return 'Edit note'
    }
    const current: KnowledgeUnit | null = this.effectiveUnit()
    if (current !== null && current.title.length > 0) {
      return current.title
    }
    return this.note.title
  }

  private startEdit = (): void => {
    const current: KnowledgeUnit | null = this.effectiveUnit()
    if (current === null) {
      promptAction.showToast({ message: 'Note is still loading', duration: 1200 })
      return
    }
    this.loadForm(current)
    this.isEditing = true
    this.onEdit(this.note.id)
  }

  private loadForm(unit: KnowledgeUnit | null): void {
    if (unit === null) {
      this.titleText = ''
      this.summaryText = ''
      this.contentText = ''
      this.tagsText = ''
      this.captureInitialSnapshot()
      return
    }
    this.titleText = unit.title
    this.summaryText = unit.summary
    this.contentText = unit.content
    this.tagsText = unit.tags.join(', ')
    this.captureInitialSnapshot()
  }

  private cancelEdit = (): void => {
    if (this.saving) {
      return
    }
    if (this.hasUnsavedChanges()) {
      this.showDiscardConfirm = true
      return
    }
    this.discardEdit()
  }

  private discardEdit(): void {
    this.showDiscardConfirm = false
    if (this.isCreating) {
      this.onClose()
      return
    }
    this.isEditing = false
    this.loadForm(this.effectiveUnit())
  }

  private closeOrCancel = (): void => {
    if (this.saving) {
      return
    }
    if (this.isEditing) {
      this.cancelEdit()
      return
    }
    this.onClose()
  }

  private saveEdit = async (): Promise<void> => {
    if (this.saving) {
      return
    }
    const title: string = this.titleText.trim()
    const summary: string = this.summaryText.trim()
    const content: string = this.contentText.trim()
    if (title.length === 0) {
      promptAction.showToast({ message: 'Title is required', duration: 1200 })
      return
    }
    if (summary.length === 0 && content.length === 0) {
      promptAction.showToast({ message: 'Summary or content is required', duration: 1500 })
      return
    }

    this.saving = true
    try {
      const store = await DatabaseHelper.init(getContext(this))
      const dao: NoteDao = new NoteDao(store)
      const now: number = Date.now()
      const saved: KnowledgeUnit = this.isCreating
        ? this.buildManualUnit(now, title, summary, content)
        : this.buildUpdatedUnit(now, title, summary, content)
      if (this.isCreating) {
        await dao.insert(saved)
      } else {
        await dao.update(saved)
      }
      this.localUnit = saved
      this.isEditing = false
      this.showDiscardConfirm = false
      this.loadForm(saved)
      this.bumpNotesVersion()
      this.onSaved(saved)
      promptAction.showToast({ message: this.isCreating ? 'Note created' : 'Note saved', duration: 1200 })
    } catch (e) {
      const message: string = (e as Error).message ?? String(e)
      promptAction.showToast({ message: 'Save failed: ' + message, duration: 1800 })
    }
    this.saving = false
  }

  private buildManualUnit(now: number, title: string, summary: string, content: string): KnowledgeUnit {
    return {
      id: uuid(),
      title: title,
      content: content,
      summary: summary,
      tags: this.parseTags(this.tagsText),
      difficulty: DifficultyLevel.MEDIUM,
      source: 'manual',
      createdAt: now,
      updatedAt: now,
      reviewStatus: ReviewStatus.NEW,
      nextReviewAt: now + 86400000,
      intervalDays: 1,
      easeFactor: 2.5,
      repetitions: 0,
      prerequisites: [],
      related: [],
      embedding: [],
      userId: '',
      version: 1,
    }
  }

  private buildUpdatedUnit(now: number, title: string, summary: string, content: string): KnowledgeUnit {
    const current: KnowledgeUnit | null = this.effectiveUnit()
    if (current === null) {
      throw new Error('Note is unavailable')
    }
    return {
      id: current.id,
      title: title,
      content: content,
      summary: summary,
      tags: this.parseTags(this.tagsText),
      difficulty: current.difficulty,
      source: current.source,
      createdAt: current.createdAt,
      updatedAt: now,
      reviewStatus: current.reviewStatus,
      nextReviewAt: current.nextReviewAt,
      intervalDays: current.intervalDays,
      easeFactor: current.easeFactor,
      repetitions: current.repetitions,
      prerequisites: current.prerequisites,
      related: current.related,
      embedding: current.embedding,
      userId: current.userId,
      version: current.version + 1,
    }
  }

  private parseTags(raw: string): string[] {
    const result: string[] = []
    const parts: string[] = raw
      .replace(/\r/g, '\n')
      .replace(/,/g, '\n')
      .replace(/\uFF0C/g, '\n')
      .replace(/\u3001/g, '\n')
      .replace(/;/g, '\n')
      .replace(/\uFF1B/g, '\n')
      .split(/\s+/)
    for (const part of parts) {
      const tag: string = part.trim()
      if (tag.length > 0 && result.indexOf(tag) < 0) {
        result.push(tag)
      }
    }
    return result
  }

  private captureInitialSnapshot(): void {
    this.initialTitleText = this.titleText
    this.initialSummaryText = this.summaryText
    this.initialContentText = this.contentText
    this.initialTagsText = this.tagsText
  }

  private hasUnsavedChanges(): boolean {
    return this.titleText !== this.initialTitleText
      || this.summaryText !== this.initialSummaryText
      || this.contentText !== this.initialContentText
      || this.tagsText !== this.initialTagsText
  }

  private bumpNotesVersion(): void {
    const v: number = AppStorage.get<number>('notesVersion') ?? 0
    AppStorage.setOrCreate('notesVersion', v + 1)
  }

  private mockShare = (): void => {
    promptAction.showToast({ message: 'Share is not available yet', duration: 1500 })
  }

  private confirmDelete = (): void => {
    this.onDelete(this.note.rawId.length > 0 ? this.note.rawId : this.note.id.toString())
  }
}
