// ============================================================================
//  overlays/NoteDetailOverlay/NoteDetailOverlay.ets - note detail overlay shell
// ============================================================================

import {
  BG_DARK, TEXT, DANGER,
  F_MD,
  W_SEMIBOLD,
  OVERLAY_MASK_SOLID,
  NoteItem,
  KnowledgeUnit,
} from 'common'
import { promptAction } from '@kit.ArkUI'
import { NoteCloseButton } from './NoteCloseButton'
import { NoteDetailMeta } from './NoteDetailMeta'
import { NoteDetailBody } from './NoteDetailBody'
import { NoteActionBar } from './NoteActionBar'
import { NoteIconButton } from './NoteIconButton'

@Component
export struct NoteDetailOverlay {
  @Prop note: NoteItem = new NoteItem(0, '', '', '', '', 0, '', [], '')
  @Prop unit: KnowledgeUnit | null = null
  @Prop units: KnowledgeUnit[] = []
  @StorageProp('statusBarHeight') sbh: number = 0
  onClose: () => void = (): void => {}
  onEdit: (id: number) => void = (_id: number): void => {}
  onDelete: (id: string) => void = (_id: string): void => {}

  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(OVERLAY_MASK_SOLID)
        .onClick((): void => this.onClose())

      Column() {
        Row().width('100%').height(this.sbh).backgroundColor(BG_DARK)

        Row() {
          NoteCloseButton({ onClose: (): void => this.onClose() })

          Column() {
            Text(this.detailTitle())
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

          NoteIconButton({
            name: 'trash',
            color: DANGER,
            onTap: (): void => this.confirmDelete(),
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .alignItems(VerticalAlign.Center)

        NoteDetailMeta({ note: this.note, unit: this.unit })

        Scroll() {
          Column() {
            NoteDetailBody({ note: this.note, unit: this.unit, units: this.units })
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)

        NoteActionBar({
          onEdit: (): void => this.mockEdit(),
          onShare: (): void => this.mockShare(),
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(BG_DARK)
    }
    .width('100%')
    .height('100%')
  }

  private detailTitle(): string {
    if (this.unit !== null && this.unit.title.length > 0) {
      return this.unit.title
    }
    return this.note.title
  }

  private mockEdit = (): void => {
    promptAction.showToast({ message: '编辑功能开发中', duration: 1500 })
    this.onEdit(this.note.id)
  }

  private mockShare = (): void => {
    promptAction.showToast({ message: '分享功能开发中', duration: 1500 })
  }

  private confirmDelete = (): void => {
    this.onDelete(this.note.rawId.length > 0 ? this.note.rawId : this.note.id.toString())
  }
}