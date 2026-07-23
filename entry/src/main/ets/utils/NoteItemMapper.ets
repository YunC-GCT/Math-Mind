/**
 * NoteItemMapper.ets 鈥?KnowledgeUnit 鈫?NoteItem 瑙嗗浘灞傝浆鎹?
 *
 * 璺�緞: entry/src/main/ets/utils/NoteItemMapper.ets
 * 鑱岃矗: 鎶?common 妯″潡鐨?KnowledgeUnit (鎸佷箙鍖?涓氬姟妯″瀷) 杞�崲鎴?UI 鐢ㄧ殑
 *       NoteItem 瑙嗗浘妯″瀷锛屼緵 NotesPage / NotesList 娓叉煋銆?
 * 渚濊禆: common (KnowledgeUnit / NoteItem / ReviewStatus 绫诲瀷)
 *
 * 鏁版嵁娴?
 *   KnowledgeUnit (DB/AI 浜у嚭)
 *     鈫?unitToNoteItem(unit)
 *       鈫?stableNumericId(unit.id)         // 瀛楃�涓?ID 鈫?32 浣嶆暣鏁?(UI 鍒楄〃 key 鐢?
 *       鈫?confidence(unit.reviewStatus)     // ReviewStatus 鈫?0-1 鎺屾彙搴?
 *       鈫?dateText(unit.createdAt)         // 鏃堕棿鎴?鈫?yyyy-MM-dd
 *     鈫?NoteItem (UI 鐩存帴娓叉煋)
 *
 * ReviewStatus 鈫?鎺屾彙搴︽槧灏?
 *   GRADUATED 0.95 | REVIEW 0.86 | LEARNING 0.72 | LAPSED 0.45 | 榛樿� 0.64
 *
 * ArkTS 1.1 strict 閫傞厤:
 *   - stableNumericId 鐢?for...of 鏇夸唬 while + 鎵嬪姩 idx 閫掑�
 *   - JSON.parse 寮鸿浆 as string[] 鍚庨€愰」 typeof 妫€鏌ュ厹搴?
 *   - 鏃?any / unknown锛岄敊璇�粺涓€ (e as Error).message
 */
import {
  ContentExcerptBuilder,
  isKnownNoteType,
  KnowledgeUnit,
  normalizeNoteType,
  NoteItem,
  ReviewStatus,
} from "common"

const CAMERA_SOURCE: string = "camera_capture"
const NOTE_CARD_PREVIEW_LIMIT: number = 46
const CONTENT_EXCERPT_BUILDER: ContentExcerptBuilder = new ContentExcerptBuilder()
const MANUAL_SOURCE: string = "manual"
const FILE_IMPORT_SOURCE: string = "file_import"

function isSourceTag(tag: string): boolean {
  return tag === CAMERA_SOURCE || tag === MANUAL_SOURCE || tag === FILE_IMPORT_SOURCE
}

function resolveType(tags: string[]): string {
  for (const tag of tags) {
    const type: string = normalizeNoteType(tag)
    if (isKnownNoteType(type)) {
      return type
    }
  }
  return firstReturnedFeature(tags)
}

function resolveSubject(tags: string[]): string {
  for (const tag of tags) {
    const t: string = tag.trim()
    if (isReturnedSubjectFeature(t)) {
      return t
    }
  }
  return ""
}

function isReturnedSubjectFeature(tag: string): boolean {
  if (tag.length === 0 || isKnownNoteType(tag) || isSourceTag(tag)) {
    return false
  }
  return true
}

function firstReturnedFeature(tags: string[]): string {
  for (const tag of tags) {
    const t: string = tag.trim()
    if (t.length > 0 && !isSourceTag(t)) {
      return normalizeNoteType(t)
    }
  }
  return "笔记"
}

function stableNumericId(id: string): number {
  let hash: number = 0
  for (const ch of id) {
    hash = (hash * 31 + ch.charCodeAt(0)) % 2147483647
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
  const subject: string = unit.subject.trim().length > 0 ? unit.subject.trim() : resolveSubject(unit.tags)
  const type: string = unit.category.length > 0 ? unit.category : resolveType(unit.tags)
  const chapter: string = unit.chapter.length > 0 ? unit.chapter : subject
  const previewSource: string = unit.summary.trim().length > 0 ? unit.summary : unit.content
  const body: string = CONTENT_EXCERPT_BUILDER.buildListPreview(previewSource, NOTE_CARD_PREVIEW_LIMIT)

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
    rawId,
  )
}

export function unitsToNoteItems(units: KnowledgeUnit[]): NoteItem[] {
  const notes: NoteItem[] = []
  for (const unit of units) {
    notes.push(unitToNoteItem(unit))
  }
  return notes
}
