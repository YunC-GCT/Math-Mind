// ============================================================================
//  pages/Notes/NotesPage.ets — 笔记列表页装配层
//  ----------------------------------------------------------------------------
//  职责: 拼装"全部笔记"列表的所有视觉组件,管理笔记数据加载 + 详情浮层状态。
//
//  数据流:
//    aboutToAppear → loadNotes() (从 RDB 读 KnowledgeUnit)
//                 → unitsToNoteItems() 转 NoteItem
//    空列表 → NotesEmptyState
//    非空   → NotesList
//    笔记卡片点击 → 弹 NoteDetailOverlay
//    浮层 onDelete → deleteNote() → 重新 loadNotes() 刷新
//
//  依赖:
//    pages:    NotesHeader / NotesList / NotesEmptyState
//    prototypes: NoteDetailOverlay
//    database: NoteDao + DatabaseHelper
//    utils:    NoteItemMapper
//  ============================================================================

import { BG_DARK, NoteItem, KnowledgeUnit, DatabaseHelper } from "common"
import { promptAction } from "@kit.ArkUI"
import { NoteDetailOverlay } from "../../overlays/NoteDetailOverlay/NoteDetailOverlay"
import { NoteDao } from "../../database/NoteDao"
import { unitsToNoteItems } from "../../utils/NoteItemMapper"
import { NotesHeader } from "./NotesHeader"
import { NotesList } from "./NotesList"
import { NotesEmptyState } from "./NotesEmptyState"

@Component
export struct NotesPage {
  // 状态栏高度(沉浸式占位用)
  @StorageProp("statusBarHeight") sbh: number = 0

  // 当前选中的笔记(弹详情浮层用)
  @State selectedNote: NoteItem | null = null

  // 笔记列表数据
  @State notes: NoteItem[] = []

  // @Watch 回调必须在被监听属性之前以常规方法定义（ArkTS strict 铁律）
  onNotesVersionChange(): void {
    console.info('[NotesPage] notesVersion changed, reloading list');
    this.loadNotes();
  }

  // 全局笔记版本号(AgentFloatWindow 保存笔记后 +1, 触发自动刷新)
  @StorageProp('notesVersion') @Watch('onNotesVersionChange') notesVersion: number = 0

  // 关闭详情浮层
  private closeDetail = (): void => { this.selectedNote = null }

  // "AI 解答" 回调(W2 计划:切到 AI Tab + 带 note 上下文)
  private askAi = (_note: NoteItem): void => { this.selectedNote = null }

  // 删除笔记(浮层触发)
  private deleteNote = async (id: string): Promise<void> => {
    try {
      const store = await DatabaseHelper.init(getContext(this))
      await new NoteDao(store).deleteById(id)
      this.selectedNote = null
      await this.loadNotes()
      // 通知 HomePage 也刷新
      const v: number = AppStorage.get<number>('notesVersion') ?? 0;
      AppStorage.setOrCreate('notesVersion', v + 1);
      try { promptAction.showToast({ message: "笔记已删除", duration: 1200 }) } catch (_e) {}
    } catch (e) {
      try { promptAction.showToast({ message: "笔记删除失败", duration: 1500 }) } catch (_e) {}
    }
  }

  aboutToAppear(): void {
    // 确保 AppStorage 中有初始值
    if (AppStorage.get<number>('notesVersion') === undefined) {
      AppStorage.setOrCreate('notesVersion', 0);
    }
    this.loadNotes()
  }

  // 加载所有笔记
  private loadNotes = async (): Promise<void> => {
    try {
      const store = await DatabaseHelper.init(getContext(this))
      const units: KnowledgeUnit[] = await new NoteDao(store).queryAll()
      this.notes = unitsToNoteItems(units)
    } catch (e) {
      // 降级: 数据库未初始化时显示空列表
      this.notes = []
      try { promptAction.showToast({ message: "笔记加载失败", duration: 1500 }) } catch (_e) {}
    }
  }

  build() {
    Stack() {
      Column() {
        // 顶栏(状态栏避让 + "全部笔记" + 计数)
        NotesHeader({ statusBarHeight: this.sbh, count: this.notes.length })

        // 列表区:空/非空二选一
        if (this.notes.length === 0) {
          NotesEmptyState()
        } else {
          NotesList({
            notes: this.notes,
            onSelect: (note: NoteItem): void => { this.selectedNote = note },
          })
        }
      }
      .width("100%")
      .height("100%")
      .backgroundColor(BG_DARK)

      // 笔记详情浮层(选中有笔记时显示)
      if (this.selectedNote !== null) {
        NoteDetailOverlay({
          note: this.selectedNote,
          onClose: this.closeDetail,
          onDelete: this.deleteNote,
        })
      }
    }
    .width("100%")
    .height("100%")
    .backgroundColor(BG_DARK)
  }
}
