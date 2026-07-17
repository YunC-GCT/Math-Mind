/**
 * NoteDetailHeader.ets — 笔记详情浮层顶栏
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/NoteDetailHeader.ets
 * 职责: 学科 · 类型 chip + 关闭按钮
 * 依赖: common (typeColor, subjectColor), NoteCloseButton
 */

import {
  TEXT_4, BORDER,
  S_2, S_6,
  R_FULL,
  F_XS,
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
    Column() {
      // drag bar
      Row() {
        Row()
          .width(40).height(4)
          .borderRadius(2)
          .backgroundColor(TEXT_4);
      }
      .width('100%').height(S_6)
      .margin({ top: S_2 })
      .justifyContent(FlexAlign.Center);

      // 顶栏: 学科·类型 chip + 关闭按钮
      Row() {
        Row() {
          Text(this.note.subject)
            .fontSize(F_XS)
            .fontColor(subjectColor(this.note.subject))
            .fontWeight(W_BOLD);
          Text(' · ')
            .fontSize(F_XS)
            .fontColor(TEXT_4);
          Text(this.note.type)
            .fontSize(F_XS)
            .fontColor(typeColor(this.note.type))
            .fontWeight(W_SEMIBOLD);
        }
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .borderRadius(R_FULL)
        .backgroundColor(GLASS_10)
        .border({ width: 1, color: BORDER });

        Blank();

        NoteCloseButton({ onClose: (): void => this.onClose() });
      }
      .width('100%')
      .padding({ left: 20, right: 16, top: 4, bottom: 8 });
    }
    .width('100%');
  }
}
