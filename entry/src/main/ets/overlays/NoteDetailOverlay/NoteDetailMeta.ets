/**
 * NoteDetailMeta.ets — 笔记详情 meta 信息行
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/NoteDetailMeta.ets
 * 职责: 章节 / 日期 / 置信度徽章
 * 依赖: common (NoteItem, recentDate), atoms/ConfBadge, atoms/AppIcon
 */

import {
  TEXT_2, TEXT_3, TEXT_4,
  S_1, S_5,
  F_XS,
  NoteItem, recentDate,
} from 'common';
import { ConfBadge } from '../../atoms/ConfBadge';
import { AppIcon } from '../../atoms/AppIcon';

@Component
export struct NoteDetailMeta {
  @Prop note: NoteItem = new NoteItem(0, '', '', '', '', 0, '', [], '');

  build() {
    Row() {
      if (this.note.chapter && this.note.chapter.length > 0) {
        AppIcon({ name: 'notes', iconSize: 12, color: TEXT_2, strokeWidth: 1.6 })
          .margin({ right: S_1 });
        Text(this.note.chapter)
          .fontSize(F_XS)
          .fontColor(TEXT_2);
        Text('  ·  ')
          .fontSize(F_XS)
          .fontColor(TEXT_4);
      }
      Text(recentDate(this.note.date))
        .fontSize(F_XS)
        .fontColor(TEXT_3);

      Blank();

      ConfBadge({ conf: this.note.conf });
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 4, bottom: 12 });
  }
}
