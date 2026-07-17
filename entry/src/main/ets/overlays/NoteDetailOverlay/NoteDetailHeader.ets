/**
 * NoteDetailHeader.ets — 笔记详情浮层顶栏
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/NoteDetailHeader.ets
 * 职责: 学科 · 类型 chip 居中 + 左侧关闭按钮 + 底部分隔线
 * 参考: v2-ui .overlay-head (flex 居中 + 对称留白 + border-bottom)
 * 依赖: common, NoteCloseButton
 */

import {
  TEXT_3, TEXT_4, BORDER,
  NoteItem, typeColor, subjectColor,
} from 'common';
import { NoteCloseButton } from './NoteCloseButton';
import { ChipTag } from '../../atoms/ChipTag';

@Component
export struct NoteDetailHeader {
  @Prop note: NoteItem = new NoteItem(0, '', '', '', '', 0, '', [], '');
  @StorageProp('statusBarHeight') sbh: number = 0;
  onClose: () => void = (): void => {};

  build() {
    Row() {
      NoteCloseButton({ onClose: (): void => this.onClose() });
      Blank();
      ChipTag({ label: this.note.subject + ' · ' + this.note.type, variant: 'chip' });
      Blank();
      Row().width(24).height(24);
    }
    .width('100%').height(48)
    .padding({ left: 16, right: 16, top: this.sbh })
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 0.5 }, color: BORDER });
  }
}
