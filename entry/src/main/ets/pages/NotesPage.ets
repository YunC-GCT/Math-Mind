/**
 * MathMind 笔记列表页 — 对照 iOS Web MVP page-notes
 * 复用 HomePage note-card 视觉：渐变图标 + 彩色 meta + 标题 + 摘要
 * 对照 CSS .note-list / .note-card 分隔线模式
 *
 * W2 优化 (2026-07-15): Scroll+Column → List+ListItem（scenarios/01 推荐）、ForEach 补 key
 */import {
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
  NOTES,} from "common";
import { NoteDetailOverlay } from "../prototypes/NoteDetailOverlay";
import { NoteCard } from "../molecules/NoteCard";@Component
export struct NotesPage {
  @State selectedNote: NoteItem | null = null;  private notes: NoteItem[] = NOTES;  private closeDetail = (): void => {
    this.selectedNote = null;
  };  private askAi = (note: NoteItem): void => {
    this.selectedNote = null;
  };  build() {
    Stack() {
      Column() {
        // ===== 标题栏（固定顶部） =====
        Text("全部笔记 · " + this.notes.length + " 条")
          .fontSize(F_MD)
          .fontWeight(600)
          .fontColor(TEXT)
          .width("100%")
          .padding({ left: 20, right: 20, top: 14, bottom: 10 });        // ===== 笔记列表（List 替代 Scroll+Column，scenarios/01 推荐） =====
        List() {
          ForEach(this.notes,
            (note: NoteItem): string => note.id.toString(),
            (note: NoteItem, idx: number): void => {
              ListItem() {
                NoteCard({
                  note: note,
                  isLast: idx === this.notes.length - 1,
                  onClick: (): void => { this.selectedNote = note },
                })
              }
            }
          );          // FAB 留白
          ListItem() {
            Blank().height(80);
          }
        }
        .listStyle(ListStyle.None)
        .layoutWeight(1)
        .scrollBar(BarState.Off);
      }
      .width("100%")
      .height("100%")
      .backgroundColor(BG_DARK);      // ===== NoteDetailOverlay 浮层 =====
      if (this.selectedNote !== null) {
        NoteDetailOverlay({
          note: this.selectedNote,
          onClose: this.closeDetail,
          onAskAi: this.askAi,
        });
      }
    }
    .width("100%")
    .height("100%")
    .backgroundColor(BG_DARK);
  }}
