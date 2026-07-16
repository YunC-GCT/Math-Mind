import { KnowledgeUnit, NoteItem, ReviewStatus } from "common"

function stableNumericId(id: string): number {
  let hash: number = 0
  let idx: number = 0
  while (idx < id.length) {
    hash = (hash * 31 + id.charCodeAt(idx)) % 2147483647
    idx++
  }
  return hash
}

function pad2(value: number): string {
  return value < 10 ? "0" + value.toString() : value.toString()
}

function dateText(ts: number): string {
  const d: Date = new Date(ts > 0 ? ts : Date.now())
  return d.getFullYear().toString() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate())
}

function confidence(unit: KnowledgeUnit): number {
  if (unit.reviewStatus === ReviewStatus.GRADUATED) { return 0.95 }
  if (unit.reviewStatus === ReviewStatus.REVIEW) { return 0.86 }
  if (unit.reviewStatus === ReviewStatus.LEARNING) { return 0.72 }
  if (unit.reviewStatus === ReviewStatus.LAPSED) { return 0.45 }
  return 0.64
}

export function unitToNoteItem(unit: KnowledgeUnit): NoteItem {
  const rawId: string = unit.id.length > 0 ? unit.id : unit.title + unit.createdAt.toString()
  const subject: string = unit.tags.length > 0 ? unit.tags[0] : "数学"
  const type: string = unit.tags.length > 1 ? unit.tags[1] : "笔记"
  const chapter: string = unit.source.length > 0 ? unit.source : subject
  const body: string = unit.content.length > 0 ? unit.content : unit.summary

  return new NoteItem(
    stableNumericId(rawId),
    unit.title,
    type,
    subject,
    chapter,
    confidence(unit),
    body,
    unit.tags,
    dateText(unit.createdAt),
  )
}

export function unitsToNoteItems(units: KnowledgeUnit[]): NoteItem[] {
  const notes: NoteItem[] = []
  for (const unit of units) {
    notes.push(unitToNoteItem(unit))
  }
  return notes
}
