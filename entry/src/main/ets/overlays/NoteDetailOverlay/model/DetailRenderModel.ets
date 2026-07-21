/**
 * DetailRenderModel.ets — 笔记详情选择性渲染模型
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/model/DetailRenderModel.ets
 * 职责: 将 KnowledgeUnit / NoteItem 转成详情页六类 renderer 可直接消费的只读模型。
 * 依赖: common 笔记模型、分类工具。
 *
 * 数据流:
 *   KnowledgeUnit / NoteItem → buildDetailRenderModel → renderer
 *
 * ArkTS 1.1 strict 适配:
 *   - 不使用 any / unknown
 *   - 用 for...of / while，不使用 C 风格 for
 */

import {
  DifficultyLevel,
  KnowledgeUnit,
  NoteItem,
  ReviewStatus,
  normalizeNoteType,
} from 'common'

export interface DetailSectionData {
  key: string
  title: string
  normalizedTitle: string
  content: string
}

export interface DetailRenderModel {
  category: string
  subject: string
  summary: string
  body: string
  sections: DetailSectionData[]
  tags: string[]
  prerequisites: string[]
  related: string[]
  sourceLabel: string
  reviewLine: string
  difficultyText: string
  statusText: string
}

const SOURCE_CAMERA: string = 'camera_capture'

export function emptyDetailRenderModel(): DetailRenderModel {
  return {
    category: '其它',
    subject: '',
    summary: '',
    body: '',
    sections: [],
    tags: [],
    prerequisites: [],
    related: [],
    sourceLabel: '',
    reviewLine: '',
    difficultyText: '',
    statusText: '',
  }
}

export function buildDetailRenderModel(note: NoteItem, unit: KnowledgeUnit | null, units: KnowledgeUnit[]): DetailRenderModel {
  const category: string = resolveCategory(note, unit)
  const body: string = resolveBody(note, unit)
  const summary: string = unit !== null ? unit.summary.trim() : note.body.trim()
  return {
    category: category,
    subject: resolveSubject(note, unit),
    summary: summary,
    body: body,
    sections: parseDetailSections(body),
    tags: filterTags(resolveTags(note, unit), category),
    prerequisites: resolveKnowledgeRefs(unit !== null ? unit.prerequisites : [], units),
    related: resolveKnowledgeRefs(unit !== null ? unit.related : [], units),
    sourceLabel: resolveSource(note, unit),
    reviewLine: resolveReviewLine(unit),
    difficultyText: unit !== null ? difficultyText(unit.difficulty) : '',
    statusText: unit !== null ? reviewStatusText(unit.reviewStatus) : '',
  }
}

export function findSection(model: DetailRenderModel, names: string[]): DetailSectionData | null {
  for (const name of names) {
    const normalized: string = normalizeSectionTitle(name)
    for (const section of model.sections) {
      if (section.normalizedTitle === normalized) {
        return section
      }
    }
  }
  return null
}

export function sectionText(model: DetailRenderModel, names: string[]): string {
  const section: DetailSectionData | null = findSection(model, names)
  return section !== null ? section.content : ''
}

export function fallbackMainText(model: DetailRenderModel): string {
  if (model.body.length > 0) {
    return model.body
  }
  return model.summary
}

export function hasDetailMeta(model: DetailRenderModel): boolean {
  return model.tags.length > 0
    || model.prerequisites.length > 0
    || model.related.length > 0
    || model.sourceLabel.length > 0
    || model.reviewLine.length > 0
}

export function splitReadableLines(content: string): string[] {
  const result: string[] = []
  const lines: string[] = content.replace(/\r\n/g, '\n').replace(/\r/g, '\n').split('\n')
  for (const line of lines) {
    const cleaned: string = cleanListPrefix(line.trim())
    if (cleaned.length > 0) {
      result.push(cleaned)
    }
  }
  if (result.length === 0 && content.trim().length > 0) {
    result.push(content.trim())
  }
  return result
}

export function firstAvailableSectionText(model: DetailRenderModel, groups: string[][]): string {
  for (const group of groups) {
    const text: string = sectionText(model, group)
    if (text.length > 0) {
      return text
    }
  }
  return ''
}

export function hasAnySectionText(model: DetailRenderModel, groups: string[][]): boolean {
  return firstAvailableSectionText(model, groups).length > 0
}

export function parseDetailSections(body: string): DetailSectionData[] {
  const normalizedBody: string = body.replace(/\r\n/g, '\n').replace(/\r/g, '\n').trim()
  if (normalizedBody.length === 0) {
    return []
  }
  const lines: string[] = normalizedBody.split('\n')
  const result: DetailSectionData[] = []
  let title: string = '内容'
  let linesInSection: string[] = []
  let sectionIndex: number = 0

  for (const line of lines) {
    const trimmed: string = line.trim()
    if (trimmed.indexOf('## ') === 0) {
      sectionIndex = pushSection(result, sectionIndex, title, linesInSection)
      title = trimmed.substring(3).trim()
      linesInSection = []
    } else {
      linesInSection.push(line)
    }
  }
  pushSection(result, sectionIndex, title, linesInSection)
  if (result.length === 0) {
    result.push(buildSection(0, '内容', normalizedBody))
  }
  return result
}

function pushSection(target: DetailSectionData[], sectionIndex: number, title: string, lines: string[]): number {
  const content: string = lines.join('\n').trim()
  if (content.length > 0) {
    target.push(buildSection(sectionIndex, title, content))
    return sectionIndex + 1
  }
  return sectionIndex
}

function buildSection(index: number, title: string, content: string): DetailSectionData {
  const normalizedTitle: string = normalizeSectionTitle(title)
  return {
    key: normalizedTitle + '_' + index.toString() + '_' + contentHash(content),
    title: title.trim().length > 0 ? title.trim() : '内容',
    normalizedTitle: normalizedTitle,
    content: content,
  }
}

function normalizeSectionTitle(title: string): string {
  const text: string = title.trim()
    .replace(/：/g, ':')
    .replace(/\s+/g, '')
    .toLowerCase()
  if (text === '核心公式' || text === '公式' || text === '表达式') { return 'expression' }
  if (text === '参数' || text === '变量' || text === '符号说明' || text === '参数说明') { return 'parameters' }
  if (text === '适用范围' || text === '条件' || text === '使用条件') { return 'range' }
  if (text === '推导' || text === '推导过程') { return 'derivation' }
  if (text === '备注' || text === '易错点' || text === '常见错误') { return 'notes' }
  if (text === '定义') { return 'definition' }
  if (text === '性质' || text === '特征') { return 'properties' }
  if (text === '示例' || text === '例子' || text === '反例') { return 'examples' }
  if (text === '相关概念') { return 'relatedconcepts' }
  if (text === '陈述' || text === '定理陈述') { return 'statement' }
  if (text === '结论') { return 'conclusion' }
  if (text === '证明思路' || text === '思路' || text === '关键思路') { return 'insight' }
  if (text === '应用') { return 'applications' }
  if (text === '命题') { return 'proposition' }
  if (text === '已知') { return 'given' }
  if (text === '证明过程' || text === '过程') { return 'proofprocess' }
  if (text === '问题' || text === '题目') { return 'problem' }
  if (text === '步骤' || text === '解题步骤') { return 'steps' }
  if (text === '答案' || text === '结果') { return 'answer' }
  if (text === '方法总结') { return 'methodsummary' }
  if (text === '原文' || text === 'ocr原文') { return 'original' }
  if (text.length === 0) { return 'content' }
  return text
}

function resolveBody(note: NoteItem, unit: KnowledgeUnit | null): string {
  if (unit !== null && unit.content.trim().length > 0) {
    return unit.content.trim()
  }
  return note.body.trim()
}

function cleanListPrefix(line: string): string {
  let text: string = line
  if (text.indexOf('- ') === 0 || text.indexOf('* ') === 0) {
    text = text.substring(2).trim()
  }
  let dotIndex: number = text.indexOf('. ')
  if (dotIndex > 0 && dotIndex <= 2) {
    const prefix: string = text.substring(0, dotIndex)
    const numeric: number = Number(prefix)
    if (!Number.isNaN(numeric)) {
      text = text.substring(dotIndex + 2).trim()
    }
  }
  dotIndex = text.indexOf('、')
  if (dotIndex > 0 && dotIndex <= 2) {
    const prefix: string = text.substring(0, dotIndex)
    const numeric: number = Number(prefix)
    if (!Number.isNaN(numeric)) {
      text = text.substring(dotIndex + 1).trim()
    }
  }
  return text
}

function resolveCategory(note: NoteItem, unit: KnowledgeUnit | null): string {
  const raw: string = unit !== null && unit.category.trim().length > 0 ? unit.category.trim() : note.type.trim()
  return normalizeDetailCategory(raw)
}

function resolveSubject(note: NoteItem, unit: KnowledgeUnit | null): string {
  if (unit !== null && unit.subject.trim().length > 0) {
    return unit.subject.trim()
  }
  return note.subject.trim()
}

function resolveTags(note: NoteItem, unit: KnowledgeUnit | null): string[] {
  if (unit !== null && unit.tags.length > 0) {
    return unit.tags
  }
  return note.tags
}

function filterTags(raw: string[], category: string): string[] {
  const result: string[] = []
  const normalizedCategory: string = normalizeDetailCategory(category)
  for (const item of raw) {
    const tag: string = item.trim()
    if (tag.length === 0 || tag === SOURCE_CAMERA) {
      continue
    }
    if (normalizeDetailCategory(tag) === normalizedCategory && normalizedCategory !== '其它') {
      continue
    }
    if (result.indexOf(tag) < 0) {
      result.push(tag)
    }
  }
  return result
}

function normalizeDetailCategory(raw: string): string {
  const value: string = normalizeNoteType(raw.trim())
  if (value === '概念' || raw.indexOf('概念') >= 0) { return '概念' }
  if (value === '定理' || raw.indexOf('定理') >= 0) { return '定理' }
  if (value === '公式' || raw.indexOf('公式') >= 0) { return '公式' }
  if (value === '证明题' || value === '证明' || raw.indexOf('证明') >= 0) { return '证明题' }
  if (value === '计算题' || value === '计算' || raw.indexOf('计算') >= 0) { return '计算题' }
  if (value === '其它' || value === '其他' || raw.indexOf('其它') >= 0 || raw.indexOf('其他') >= 0) { return '其它' }
  return '其它'
}

function resolveKnowledgeRefs(ids: string[], units: KnowledgeUnit[]): string[] {
  const result: string[] = []
  for (const id of ids) {
    const label: string = lookupTitle(id, units)
    if (label.length > 0 && result.indexOf(label) < 0) {
      result.push(label)
    }
  }
  return result
}

function lookupTitle(id: string, units: KnowledgeUnit[]): string {
  const trimmed: string = id.trim()
  if (trimmed.length === 0) {
    return ''
  }
  const found: KnowledgeUnit | undefined = units.find((unit: KnowledgeUnit): boolean => unit.id === trimmed)
  return found !== undefined && found.title.trim().length > 0 ? found.title.trim() : trimmed
}

function resolveSource(note: NoteItem, unit: KnowledgeUnit | null): string {
  const raw: string = unit !== null ? unit.source.trim() : note.chapter.trim()
  if (raw.length === 0 || raw === SOURCE_CAMERA) {
    return ''
  }
  return raw
}

function resolveReviewLine(unit: KnowledgeUnit | null): string {
  if (unit === null) {
    return ''
  }
  const parts: string[] = []
  parts.push(reviewStatusText(unit.reviewStatus))
  parts.push('间隔 ' + unit.intervalDays.toString() + ' 天')
  if (unit.repetitions > 0) {
    parts.push('已复习 ' + unit.repetitions.toString() + ' 次')
  }
  if (unit.nextReviewAt > 0) {
    parts.push('下次 ' + formatDate(unit.nextReviewAt))
  }
  return parts.join(' · ')
}

function reviewStatusText(status: ReviewStatus): string {
  if (status === ReviewStatus.LEARNING) { return '学习中' }
  if (status === ReviewStatus.REVIEW) { return '复习中' }
  if (status === ReviewStatus.GRADUATED) { return '已掌握' }
  if (status === ReviewStatus.LAPSED) { return '需重学' }
  return '新笔记'
}

function difficultyText(level: DifficultyLevel): string {
  if (level === DifficultyLevel.EASY) { return '简单' }
  if (level === DifficultyLevel.MEDIUM) { return '中等' }
  if (level === DifficultyLevel.HARD) { return '困难' }
  return '专家'
}

function formatDate(ts: number): string {
  const d: Date = new Date(ts > 0 ? ts : Date.now())
  const month: string = d.getMonth() + 1 < 10 ? '0' + (d.getMonth() + 1).toString() : (d.getMonth() + 1).toString()
  const day: string = d.getDate() < 10 ? '0' + d.getDate().toString() : d.getDate().toString()
  return d.getFullYear().toString() + '-' + month + '-' + day
}

function contentHash(text: string): string {
  let hash: number = 5381
  let index: number = 0
  while (index < text.length) {
    hash = ((hash << 5) + hash + text.charCodeAt(index)) | 0
    index += 1
  }
  const positive: number = hash < 0 ? -hash : hash
  return positive.toString()
}
