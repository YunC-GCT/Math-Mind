/**
 * overlays/NoteDetailOverlay/NoteDetailOverlay.ets — 笔记详情浮层装配层
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/NoteDetailOverlay.ets
 * 职责: 全屏笔记详情浮层 · 参考 AiSettingsPage 顶栏模式
 *
 * 顶栏模式: [状态栏占位] [✕关闭 ··· 学科·类型 ··· 占位] [分隔线]
 */

import {
  BG_DARK, TEXT, BORDER,
  F_MD, S_3,
  W_SEMIBOLD,
  OVERLAY_MASK_SOLID,
  NoteItem,
} from 'common';
import { promptAction } from '@kit.ArkUI';
import { NoteCloseButton } from './NoteCloseButton';
import { ChipTag } from '../../atoms/ChipTag';
import { NoteDetailMeta } from './NoteDetailMeta';
import { NoteDetailBody } from './NoteDetailBody';
import { NoteActionBar } from './NoteActionBar';

@Component
export struct NoteDetailOverlay {
  @Prop note: NoteItem = new NoteItem(0, '', '', '', '', 0, '', [], '');
  @StorageProp('statusBarHeight') sbh: number = 0;
  onClose: () => void = (): void => {};
  onAskAi: (note: NoteItem) => void = (_note: NoteItem): void => {};
  onEdit: (id: number) => void = (_id: number): void => {};
  onDelete: (id: string) => void = (_id: string): void => {};

  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(OVERLAY_MASK_SOLID)
        .onClick((): void => this.onClose());

      Column() {
        // 状态栏占位 (参考 AiSettingsPage)
        Row().width('100%').height(this.sbh).backgroundColor(BG_DARK);

        // 顶栏: ✕关闭 ··· title居中 ··· 占位 (参考 PageHeader)
        Row() {
          NoteCloseButton({ onClose: (): void => this.onClose() });
          Blank();
          Text(this.note.subject + ' · ' + this.note.type)
            .fontSize(F_MD).fontWeight(W_SEMIBOLD).fontColor(TEXT);
          Blank();
          Row().width(32);
        }
        .width('100%').height(48)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center);

        Row().width('100%').height(0.5).backgroundColor(BORDER);

        Scroll() {
          Column() {
            NoteDetailMeta({ note: this.note });
            NoteDetailBody({ note: this.note });
          }.width('100%');
        }
        .layoutWeight(1).width('100%')
        .scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring);

        NoteActionBar({
          onDelete: (): void => this.confirmDelete(),
          onEdit: (): void => this.mockEdit(),
          onShare: (): void => this.mockShare(),
        });
      }
      .width('100%').height('100%').backgroundColor(BG_DARK);
    }
    .width('100%').height('100%');
  }

  private mockEdit = (): void => {
    promptAction.showToast({ message: '编辑功能 W2 上线', duration: 1500 });
    this.onEdit(this.note.id);
  };
  private mockShare = (): void => {
    promptAction.showToast({ message: '已复制笔记到剪贴板', duration: 1500 });
  };
  private confirmDelete = (): void => {
    this.onDelete(this.note.rawId.length > 0 ? this.note.rawId : this.note.id.toString());
  };
}
