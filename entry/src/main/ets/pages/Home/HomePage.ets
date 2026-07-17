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

function greet(): string {
  const hour: number = new Date().getHours()
  if (hour < 6) { return "凌晨好" }
  if (hour < 11) { return "上午好" }
  if (hour < 13) { return "中午好" }
  if (hour < 18) { return "下午好" }
  return "晚上好"
}

function pad2(value: number): string {
  return value < 10 ? "0" + value.toString() : value.toString()
}

function dateStr(): string {
  const date: Date = new Date()
  const weekDays: string[] = ["日", "一", "二", "三", "四", "五", "六"]
  return date.getFullYear().toString() + "年" +
    pad2(date.getMonth() + 1) + "月" +
    pad2(date.getDate()) + "日 · 周" +
    weekDays[date.getDay()]
}

function todayKey(): string {
  const now: Date = new Date()
  return now.getFullYear().toString() + "-" + pad2(now.getMonth() + 1) + "-" + pad2(now.getDate())
}

@Component
export struct HomePage {
  @StorageProp("statusBarHeight") sbh: number = 0
  @State notes: NoteItem[] = []
  @State greeting: string = ""
  @State dateText: string = ""
  @State avg: number = 0
  @State today: number = 0
  @State selectedNote: NoteItem | null = null

  onGoCamera: () => void = (): void => {}
  onGoReview: () => void = (): void => {}

  aboutToAppear(): void {
    this.greeting = greet()
    this.dateText = dateStr()
    this.loadNotes()
  }

  private loadNotes = async (): Promise<void> => {
    try {
      const store = await DatabaseHelper.init(getContext(this))
      const units: KnowledgeUnit[] = await new NoteDao(store).queryAll()
      this.notes = unitsToNoteItems(units)
      this.refreshStats()
    } catch (e) {
      this.notes = []
      this.refreshStats()
      try { promptAction.showToast({ message: "笔记加载失败", duration: 1500 }) } catch (_e) {}
    }
  }

  private refreshStats(): void {
    this.avg = this.notes.length > 0
      ? Math.round(this.notes.reduce((total: number, note: NoteItem): number => total + note.conf, 0) / this.notes.length * 100)
      : 0
    const today: string = todayKey()
    this.today = this.notes.filter((note: NoteItem): boolean => note.date === today).length
  }

  private deleteNote = async (id: string): Promise<void> => {
    try {
      const store = await DatabaseHelper.init(getContext(this))
      await new NoteDao(store).deleteById(id)
      this.selectedNote = null
      await this.loadNotes()
      try { promptAction.showToast({ message: "笔记已删除", duration: 1200 }) } catch (_e) {}
    } catch (e) {
      try { promptAction.showToast({ message: "笔记删除失败", duration: 1500 }) } catch (_e) {}
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        HomeTopBar({ statusBarHeight: this.sbh })

        HeroBanner({
          greeting: this.greeting,
          dateText: this.dateText,
          avg: this.avg,
          notesCount: this.notes.length,
          todayCount: this.today,
          onGoReview: (): void => { this.onGoReview() },
        })

        if (this.notes.length < 3) {
          ReminderBanner({ notesCount: this.notes.length })
        }

        HomeRecentNotes({
          notes: this.notes,
          onSelect: (note: NoteItem): void => { this.selectedNote = note },
        })
      }
      .width("100%")
      .height("100%")
      .backgroundColor(BG_DARK)

      FloatingButton({
        onTap: (): void => {
          try { promptAction.showToast({ message: "用户自定义笔记开发中", duration: 1500 }) } catch (_e) {}
        },
      })

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
