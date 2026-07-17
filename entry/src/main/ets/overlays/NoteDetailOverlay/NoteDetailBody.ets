/**
 * NoteDetailBody.ets — 笔记详情正文区
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/NoteDetailBody.ets
 * 职责: 标题 + 标签 chips + 章节列表 + AI 解答卡
 * 依赖: common, utils/NoteSectionParser, NoteTagChip, NoteSection, NoteAiCard
 */

import {
  TEXT, TEXT_2, TEXT_3, TEXT_4, BORDER,
  S_1, S_2, S_5,
  F_XS, F_2XL,
  W_BOLD,
  NoteItem,
} from 'common';
import { parseSections, Section } from '../../utils/NoteSectionParser';
import { NoteTagChip } from './NoteTagChip';
import { NoteSectionView } from './NoteSection';
import { NoteAiCard } from './NoteAiCard';

@Component
export struct NoteDetailBody {
  @Prop note: NoteItem = new NoteItem(0, '', '', '', '', 0, '', [], '');
  onAskAi: () => void = (): void => {};

  build() {
    Column() {
      // 标题
      Text(this.note.title)
        .fontSize(F_2XL)
        .fontWeight(W_BOLD)
        .fontColor(TEXT)
        .lineHeight(30)
        .width('100%')
        .padding({ left: S_5, right: S_5, top: S_2, bottom: S_1 });

      // 标签 chips
      if (this.note.tags && this.note.tags.length > 0) {
        Row() {
          ForEach(this.note.tags,
            (tag: string): void => {
              NoteTagChip({ tag: tag });
            },
            (tag: string): string => tag
          );
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 16 });
      }

      // 分隔线
      Row()
        .width('100%').height(1)
        .backgroundColor(BORDER)
        .margin({ left: 20, right: 20, bottom: 12 });

      // 正文按章节渲染
      Column() {
        ForEach(parseSections(this.note.body),
          (sec: Section): void => {
            NoteSectionView({ title: sec.title, content: sec.content });
          },
          (sec: Section): string => sec.title + '_' + sec.content.length.toString()
        );
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 16 });

      // AI 解答卡
      NoteAiCard({ onTap: (): void => this.onAskAi() });

      // 底部留白(给操作栏让位)
      Blank().height(80);
    }
    .width('100%');
  }
}
