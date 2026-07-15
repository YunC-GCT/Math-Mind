/**
 * MathMind 笔记列表页 — 对照 iOS Web MVP page-notes
 * 复用 HomePage note-card 视觉：渐变图标 + 彩色 meta + 标题 + 摘要
 * 对照 CSS .note-list / .note-card 分隔线模式
 */

import {
  MINT,
  PURPLE,
  BG_DARK,
  BORDER,
  SUBJECT_COLORS,
  TYPE_COLORS,
  TEXT,
  TEXT_2,
  TEXT_3,
  TEXT_4,
  S_1,
  S_2,
  S_3,
  S_4,
  R_MD,
  R_LG,
  F_XS,
  F_SM,
  F_BASE,
  F_MD,
  NoteItem,
  NOTES,
  stripMD,
  recentDate,
  typeChar,
  typeColor,
  subjectColor,
} from 'common';
import { NoteDetailOverlay } from '../overlays/NoteDetailOverlay';

@Component
export struct NotesPage {
  @State selectedNote: NoteItem | null = null;

  private notes: NoteItem[] = NOTES;

  // 关闭浮层
  private closeDetail = (): void => {
    this.selectedNote = null;
  };

  // 浮层里点 AI 解答
  private askAi = (note: NoteItem): void => {
    this.selectedNote = null;
    // W2: 切到 AI Tab + 开 AgentFloatWindow 浮窗 + 带 note 上下文
  };

  build() {
    Stack() {
      Scroll() {
        Column() {
          // ===== 标题栏 =====
          Text(`全部笔记 · ${this.notes.length} 条`)
            .fontSize(F_MD)
            .fontWeight(600)
            .fontColor(TEXT)
            .width('100%')
            .padding({
              left: 20,
              right: 20,
              top: 14,
              bottom: 10,
            });

          // ===== 笔记列表（分隔线模式） =====
          ForEach(this.notes, (note: NoteItem, idx: number) => {
            this.NoteCard(note, idx === this.notes.length - 1);
          });

          // FAB 留白
          Blank().height(80);
        }
        .width('100%');
      }
      .width('100%')
      .height('100%')
      .scrollable(ScrollDirection.Vertical);

      // ===== NoteDetailOverlay 浮层 =====
      if (this.selectedNote !== null) {
        NoteDetailOverlay({
          note: this.selectedNote,
          onClose: this.closeDetail,
          onAskAi: this.askAi,
        });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG_DARK);
  }

  // ========== 笔记卡片（对照 CSS .note-card 分隔线模式） ==========
  @Builder
  NoteCard(note: NoteItem, isLast: boolean) {
    Row() {
      // --- 渐变图标（对照 CSS .note-icon 36×36） ---
      Stack() {
        Stack()
          .width(36)
          .height(36)
          .borderRadius(R_MD + 1)
          .linearGradient({
            angle: 135,
            colors: [
              [typeColor(note.type), 0],
              [subjectColor(note.subject), 1],
            ],
          });

        Text(typeChar(note.type))
          .fontSize(F_MD + 2)
          .fontWeight(700)
          .fontColor('#FF0A0C10');
      }
      .width(36)
      .height(36)
      .alignContent(Alignment.Center);

      // --- 右侧内容 ---
      Column() {
        // meta 行：学科 · 类型 · 日期 · 百分比
        Row() {
          Text(note.subject)
            .fontSize(F_XS)
            .fontColor(subjectColor(note.subject))
            .fontWeight(500);

          Text(' · ')
            .fontSize(F_XS)
            .fontColor(TEXT_4);

          Text(note.type)
            .fontSize(F_XS)
            .fontColor(typeColor(note.type))
            .fontWeight(500);

          Text(' · ')
            .fontSize(F_XS)
            .fontColor(TEXT_4);

          Text(recentDate(note.date))
            .fontSize(F_XS)
            .fontColor(TEXT_3);

          Blank();

          Text(`${Math.round(note.conf * 100)}%`)
            .fontSize(F_XS)
            .fontColor(note.conf > 0.8 ? MINT : note.conf > 0.5 ? '#FFFBBF24' : '#FFFF6B6B')
            .fontWeight(600);
        }
        .width('100%');

        // 标题
        Text(note.title)
          .fontSize(F_SM)
          .fontWeight(600)
          .fontColor(TEXT)
          .margin({ top: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%');

        // 摘要（2 行截断）
        Text(stripMD(note.body, 80))
          .fontSize(F_XS)
          .fontColor(TEXT_3)
          .margin({ top: 2 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(16)
          .width('100%');
      }
      .layoutWeight(1)
      .margin({ left: 12 });
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ left: 20, right: 20, top: 14, bottom: 14 })
    // 分隔线（最后一条无边线）
    .border({
      width: { bottom: isLast ? 0 : 1 },
      color: BORDER,
    })
    .onClick(() => {
      this.selectedNote = note;
    });
  }
}
