/**
 * NoteDetailMeta.ets — 笔记详情 meta 信息行
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/NoteDetailMeta.ets
 * 职责: 章节 / 日期 / 置信度点 · 对齐 v2-ui .dmeta (虚线分隔 + tabular nums)
 * 依赖: common, local ConfDot, atoms/AppIcon
 */

import { TEXT_2, TEXT_3, TEXT_4, BORDER, S_1, S_3, S_4, F_XS, NoteItem, recentDate } from 'common';
import { ConfDot } from './ConfDot';
import { AppIcon } from '../../atoms/AppIcon';

@Component
export struct NoteDetailMeta {
  @Prop note: NoteItem = new NoteItem(0, '', '', '', '', 0, '', [], '');

  build() {
    Row() {
      if (this.note.chapter && this.note.chapter.length > 0) {
        AppIcon({ name: 'notes', iconSize: 12, color: TEXT_2, strokeWidth: 1.6 }).margin({ right: S_1 });
        Text(this.note.chapter).fontSize(F_XS).fontColor(TEXT_2);
        Text(' · ').fontSize(F_XS).fontColor(TEXT_4);
      }
      Text(recentDate(this.note.date)).fontSize(F_XS).fontColor(TEXT_3);

      ConfDot({ confidence: this.note.conf }).margin({ left: S_3 });

      Blank();

      // 置信度数字 (v2-ui .dmeta 风格)
      Text(Math.round(this.note.conf * 100).toString() + '%')
        .fontSize(F_XS).fontColor(TEXT_3);
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: S_1, bottom: S_4 })
    .border({ width: { bottom: 0.5 }, color: BORDER, style: BorderStyle.Dashed });
  }
}
