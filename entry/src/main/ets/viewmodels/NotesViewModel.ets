// ============================================================================
//  viewmodels/NotesViewModel.ets - notes list data logic
// ============================================================================

import { DatabaseHelper, KnowledgeUnit, NoteItem, subjectColor } from "common"
import { NoteDao } from "../database/NoteDao"
import { unitsToNoteItems } from "../utils/NoteItemMapper"

export class SubjectGroup {
  subject: string = ""
  color: string = ""
  count: number = 0
  notes: NoteItem[] = []
  previewTitles: string[] = []

  constructor(subject: string, color: string, count: number, notes: NoteItem[], previewTitles: string[]) {
    this.subject = subject
    this.color = color
    this.count = count
    this.notes = notes
    this.previewTitles = previewTitles
  }
}

@Observed
export class NotesViewModel {
  notes: NoteItem[] = []
  units: KnowledgeUnit[] = []
  subjectGroups: SubjectGroup[] = []
  weeklyNewCount: number = 0

  async loadNotes(context: Context): Promise<boolean> {
    try {
      const store = await DatabaseHelper.init(context)
      const units: KnowledgeUnit[] = await new NoteDao(store).queryAll()
      this.units = units
      this.notes = unitsToNoteItems(units)
      this.subjectGroups = this.groupBySubject(this.notes)
      this.weeklyNewCount = this.countRecentNotes(this.notes, 7)
      return true
    } catch (_e) {
      this.units = []
      this.notes = []
      this.subjectGroups = []
      this.weeklyNewCount = 0
      return false
    }
  }

  async loadNote(context: Context, id: string): Promise<KnowledgeUnit | null> {
    if (id.length === 0) {
      return null
    }
    try {
      const store = await DatabaseHelper.init(context)
      return await new NoteDao(store).queryById(id)
    } catch (_e) {
      return null
    }
  }

  async deleteNote(context: Context, id: string): Promise<boolean> {
    try {
      const store = await DatabaseHelper.init(context)
      await new NoteDao(store).deleteById(id)
      return await this.loadNotes(context)
    } catch (_e) {
      return false
    }
  }

  groupBySubject(notes: NoteItem[]): SubjectGroup[] {
    const subjectNames: string[] = []
    const subjectNotes: NoteItem[][] = []

    for (const note of notes) {
      const subject: string = this.resolveSubject(note)
      let idx: number = subjectNames.indexOf(subject)
      if (idx < 0) {
        subjectNames.push(subject)
        subjectNotes.push([])
        idx = subjectNames.length - 1
      }
      subjectNotes[idx].push(note)
    }

    const groups: SubjectGroup[] = []
    let subjectIndex: number = 0
    while (subjectIndex < subjectNames.length) {
      const sortedNotes: NoteItem[] = this.sortByDateDesc(subjectNotes[subjectIndex])
      const previewTitles: string[] = []
      const previewCount: number = Math.min(3, sortedNotes.length)
      let previewIndex: number = 0
      while (previewIndex < previewCount) {
        previewTitles.push(sortedNotes[previewIndex].title)
        previewIndex++
      }
      groups.push(new SubjectGroup(
        subjectNames[subjectIndex],
        subjectColor(subjectNames[subjectIndex], subjectIndex),
        sortedNotes.length,
        sortedNotes,
        previewTitles,
      ))
      subjectIndex++
    }

    return this.sortGroups(groups)
  }

  notesForSubject(subject: string): NoteItem[] {
    for (const group of this.subjectGroups) {
      if (group.subject === subject) {
        return group.notes
      }
    }
    return []
  }

  private resolveSubject(note: NoteItem): string {
    const subject: string = note.subject.trim()
    return subject.length > 0 ? subject : "未分类"
  }

  private sortByDateDesc(notes: NoteItem[]): NoteItem[] {
    const sorted: NoteItem[] = notes.slice(0)
    sorted.sort((a: NoteItem, b: NoteItem): number => {
      return new Date(b.date).getTime() - new Date(a.date).getTime()
    })
    return sorted
  }

  private sortGroups(groups: SubjectGroup[]): SubjectGroup[] {
    const sorted: SubjectGroup[] = groups.slice(0)
    sorted.sort((a: SubjectGroup, b: SubjectGroup): number => b.count - a.count)
    return sorted
  }

  private countRecentNotes(notes: NoteItem[], days: number): number {
    const now: number = Date.now()
    const windowMs: number = days * 86400000
    let count: number = 0
    for (const note of notes) {
      const ts: number = new Date(note.date).getTime()
      if (ts === ts && now - ts >= 0 && now - ts <= windowMs) {
        count++
      }
    }
    return count
  }
}
