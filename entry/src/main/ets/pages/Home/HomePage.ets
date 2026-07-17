// ============================================================================
//  pages/Home/HomePage.ets — 首页装配层
//  ----------------------------------------------------------------------------
//  职责: 拼装首页所有视觉组件,管理数据加载 + 笔记详情浮层状态。
//
//  数据流:
//    aboutToAppear → loadNotes() (从 RDB 读 KnowledgeUnit)
//                 → unitsToNoteItems() 转 NoteItem
//                 → refreshStats() 算 avg/today
//    笔记卡片点击 → 弹 NoteDetailOverlay
//    浮层 onDelete → deleteNote() → 重新 loadNotes() 刷新列表
//
//  依赖:
//    atoms:     FloatingButton
//    molecules: HeroBanner / ReminderBanner
//    pages:     HomeTopBar / HomeRecentNotes
//    prototypes: NoteDetailOverlay
//    database:  NoteDao + DatabaseHelper
//    utils:     NoteItemMapper
//
//  外部回调(由 Index.ets 注入):
//    onGoCamera(): 触发 CameraOverlay
//    onGoReview(): 切到复习 Tab
//  ============================================================================

import { BG_DARK, NoteItem, KnowledgeUnit, DatabaseHelper } from "common"
import { promptAction } from "@kit.ArkUI"
import { FloatingButton } from "../../atoms/FloatingButton"
import { HeroBanner } from "../../molecules/HeroBanner"
import { ReminderBanner } from "../../molecules/ReminderBanner"
import { NoteDetailOverlay } from "../../prototypes/NoteDetailOverlay"
import { NoteDao } from "../../database/NoteDao"
import { unitsToNoteItems } from "../../utils/NoteItemMapper"
import { HomeTopBar } from "./HomeTopBar"
import { HomeRecentNotes } from "./HomeRecentNotes"

// 根据当前小时返回问候语
function greet(): string {
  const hour: number = new Date().getHours()
  if (hour < 6) { return "凌晨好" }
  if (hour < 11) { return "上午好" }
  if (hour < 13) { return "中午好" }
  if (hour < 18) { return "下午好" }
  return "晚上好"
}

// 个位数补 0,用于日期格式 (YYYY-MM-DD)
function pad2(value: number): string {
  return value < 10 ? "0" + value.toString() : value.toString()
}

// 格式化日期字符串: "2026年07月15日 · 周三"
function dateStr(): string {
  const date: Date = new Date()
  const weekDays: string[] = ["日", "一", "二", "三", "四", "五", "六"]
  return date.getFullYear().toString() + "年" +
    pad2(date.getMonth() + 1) + "月" +
    pad2(date.getDate()) + "日 · 周" +
    weekDays[date.getDay()]
}

// 当天日期 key(YYYY-MM-DD),用于"今日新增"统计
function todayKey(): string {
  const now: Date = new Date()
  return now.getFullYear().toString() + "-" + pad2(now.getMonth() + 1) + "-" + pad2(now.getDate())
}

@Component
export struct HomePage {
  // 状态栏高度(由 AppStorage 注入)
  @StorageProp("statusBarHeight") sbh: number = 0

  // 笔记列表数据
  @State notes: NoteItem[] = []

  // @Watch 回调必须在被监听属性之前以常规方法定义（ArkTS strict 铁律）
  onNotesVersionChange(): void {
    console.info('[HomePage] notesVersion changed, reloading list');
    this.loadNotes();
  }

  // 全局笔记版本号(AgentFloatWindow 保存笔记后 +1, 触发自动刷新)
  @StorageProp('notesVersion') @Watch('onNotesVersionChange') notesVersion: number = 0

  // 问候语 + 日期
  @State greeting: string = ""
  @State dateText: string = ""

  // 统计
  @State avg: number = 0       // 平均置信度(%)
  @State today: number = 0      // 今日新增笔记数

  // 当前选中的笔记(弹详情浮层用)
  @State selectedNote: NoteItem | null = null

  // 外部回调(由 Index.ets 注入,默认空函数防未注入报错)
  onGoCamera: () => void = (): void => {}
  onGoReview: () => void = (): void => {}

  aboutToAppear(): void {
    this.greeting = greet()
    this.dateText = dateStr()
    // 确保 AppStorage 中有初始值
    if (AppStorage.get<number>('notesVersion') === undefined) {
      AppStorage.setOrCreate('notesVersion', 0);
    }
    this.loadNotes()
  }

  // 加载所有笔记 + 算统计
  private loadNotes = async (): Promise<void> => {
    try {
      const store = await DatabaseHelper.init(getContext(this))
      const units: KnowledgeUnit[] = await new NoteDao(store).queryAll()
      this.notes = unitsToNoteItems(units)
      this.refreshStats()
    } catch (e) {
      // 降级: 数据库没初始化时显示空列表
      this.notes = []
      this.refreshStats()
      try { promptAction.showToast({ message: "笔记加载失败", duration: 1500 }) } catch (_e) {}
    }
  }

  // 刷新 avg/today 统计
  private refreshStats(): void {
    // 平均置信度(整数 %)
    this.avg = this.notes.length > 0
      ? Math.round(this.notes.reduce((total: number, note: NoteItem): number => total + note.conf, 0) / this.notes.length * 100)
      : 0
    // 今日新增(date 字段 == 今天的 YYYY-MM-DD)
    const today: string = todayKey()
    this.today = this.notes.filter((note: NoteItem): boolean => note.date === today).length
  }

  // 删除笔记(浮层触发)
  private deleteNote = async (id: string): Promise<void> => {
    try {
      const store = await DatabaseHelper.init(getContext(this))
      await new NoteDao(store).deleteById(id)
      this.selectedNote = null
      await this.loadNotes()  // 重新加载,触发统计刷新
      try { promptAction.showToast({ message: "笔记已删除", duration: 1200 }) } catch (_e) {}
    } catch (e) {
      try { promptAction.showToast({ message: "笔记删除失败", duration: 1500 }) } catch (_e) {}
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 顶栏(状态栏避让 + MathMind Logo + 标题)
        HomeTopBar({ statusBarHeight: this.sbh })

        // Hero 区(问候 + 进度环 + 3 统计方块)
        HeroBanner({
          greeting: this.greeting,
          dateText: this.dateText,
          avg: this.avg,
          notesCount: this.notes.length,
          todayCount: this.today,
          onGoReview: (): void => { this.onGoReview() },
        })

        // 提醒横幅(笔记 < 3 条才显示)
        if (this.notes.length < 3) {
          ReminderBanner({ notesCount: this.notes.length })
        }

        // 最近笔记列表(分隔线模式)
        HomeRecentNotes({
          notes: this.notes,
          onSelect: (note: NoteItem): void => { this.selectedNote = note },
        })
      }
      .width("100%")
      .height("100%")
      .backgroundColor(BG_DARK)

      // 右下 FAB 按钮(用户自定义笔记入口,W2 计划接入)
      FloatingButton({
        onTap: (): void => {
          try { promptAction.showToast({ message: "用户自定义笔记开发中", duration: 1500 }) } catch (_e) {}
        },
      })

      // 笔记详情浮层(选中有笔记时显示)
      if (this.selectedNote !== null) {
        NoteDetailOverlay({
          note: this.selectedNote!,
          onClose: (): void => { this.selectedNote = null },
          onDelete: this.deleteNote,
        })
      }
    }
    .width("100%")
    .height("100%")
    .backgroundColor(BG_DARK)
  }
}
