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
  S_2, S_3,
  R_FULL,
  F_XS, F_SM,
  W_SEMIBOLD, W_BOLD,
  GLASS_10,
  NoteItem, typeColor, subjectColor,
} from 'common';
import { NoteCloseButton } from './NoteCloseButton';

@Component
export struct NoteDetailHeader {
  @Prop note: NoteItem = new NoteItem(0, '', '', '', '', 0, '', [], '');
  onClose: () => void = (): void => {};

  build() {
    Row() {
      // 左: 关闭按钮
      NoteCloseButton({ onClose: (): void => this.onClose() });

      Blank();

      // 中: 学科 · 类型 chip
      Row() {
        Text(this.note.subject)
          .fontSize(F_XS).fontColor(subjectColor(this.note.subject)).fontWeight(W_BOLD);
        Text(' · ')
          .fontSize(F_XS).fontColor(TEXT_4);
        Text(this.note.type)
          .fontSize(F_XS).fontColor(typeColor(this.note.type)).fontWeight(W_SEMIBOLD);
      }
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .borderRadius(R_FULL).backgroundColor(GLASS_10)
      .border({ width: 1, color: BORDER });

      Blank();

      // 右: 等宽占位 (对称)
      Row().width(24).height(24);
    }
    .width('100%').height(48)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 0.5 }, color: BORDER });
  }
}
