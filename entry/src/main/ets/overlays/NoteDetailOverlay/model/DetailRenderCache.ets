/**
 * DetailRenderCache.ets - cached detail render model builder
 *
 * Path: entry/src/main/ets/overlays/NoteDetailOverlay/model/DetailRenderCache.ets
 * Responsibility: Reuse structured detail render models for repeated note openings.
 * Dependencies: common note models, DetailRenderModel.
 *
 * Data flow:
 *   NoteDetailBody -> getDetailRenderModel -> buildDetailRenderModel on cache miss
 *
 * ArkTS 1.1 strict:
 *   - Explicit model types
 *   - Iteration uses while and for...of
 */

import { KnowledgeUnit, NoteItem } from "common"
import { DetailRenderModel, buildDetailRenderModel, emptyDetailRenderModel } from "./DetailRenderModel"
import { uiCacheLog } from "../../../utils/UiCacheDebug"

class DetailRenderEntry {
  id: string = ""
  key: string = ""
  model: DetailRenderModel = emptyDetailRenderModel()
  touched: number = 0

  constructor(id: string, key: string, model: DetailRenderModel, touched: number) {
    this.id = id
    this.key = key
    this.model = model
    this.touched = touched
  }
}

const DETAIL_RENDER_CACHE: DetailRenderEntry[] = []
const DETAIL_RENDER_CACHE_LIMIT: number = 100
let detailRenderClock: number = 0

function nextDetailRenderTick(): number {
  detailRenderClock += 1
  return detailRenderClock
}

export function getDetailRenderModel(note: NoteItem, unit: KnowledgeUnit | null, units: KnowledgeUnit[]): DetailRenderModel {
  const id: string = resolveId(note, unit)
  const key: string = buildRenderKey(id, note, unit, units)
  for (const entry of DETAIL_RENDER_CACHE) {
    if (entry.key === key) {
      entry.touched = nextDetailRenderTick()
      uiCacheLog("[UiDataCache] detailRender hit id=" + id)
      return entry.model
    }
  }
  uiCacheLog("[UiDataCache] detailRender miss id=" + id)
  const model: DetailRenderModel = buildDetailRenderModel(note, unit, units)
  removeDetailRenderById(id)
  DETAIL_RENDER_CACHE.push(new DetailRenderEntry(id, key, model, nextDetailRenderTick()))
  trimDetailRenderCache()
  return model
}

export function invalidateDetailRender(id: string): void {
  removeDetailRenderById(id)
}

function resolveId(note: NoteItem, unit: KnowledgeUnit | null): string {
  if (unit !== null && unit.id.length > 0) {
    return unit.id
  }
  if (note.rawId.length > 0) {
    return note.rawId
  }
  return note.id.toString()
}

function buildRenderKey(id: string, note: NoteItem, unit: KnowledgeUnit | null, units: KnowledgeUnit[]): string {
  const unitPart: string = unit !== null
    ? unit.updatedAt.toString() + "|" + unit.version.toString()
    : note.title + "|" + note.body.length.toString()
  return id + "|" + unitPart + "|" + unitsHash(units)
}

function unitsHash(units: KnowledgeUnit[]): string {
  let hash: number = 5381
  for (const unit of units) {
    hash = ((hash << 5) + hash + unit.id.length + unit.title.length + unit.version) | 0
  }
  const positive: number = hash < 0 ? -hash : hash
  return units.length.toString() + "_" + positive.toString()
}

function trimDetailRenderCache(): void {
  while (DETAIL_RENDER_CACHE.length > DETAIL_RENDER_CACHE_LIMIT) {
    removeOldestDetailRenderEntry()
  }
}

function removeOldestDetailRenderEntry(): void {
  if (DETAIL_RENDER_CACHE.length === 0) {
    return
  }
  let oldestIndex: number = 0
  let oldestTick: number = DETAIL_RENDER_CACHE[0].touched
  let index: number = 1
  while (index < DETAIL_RENDER_CACHE.length) {
    if (DETAIL_RENDER_CACHE[index].touched < oldestTick) {
      oldestTick = DETAIL_RENDER_CACHE[index].touched
      oldestIndex = index
    }
    index += 1
  }
  const removed: DetailRenderEntry = DETAIL_RENDER_CACHE[oldestIndex]
  DETAIL_RENDER_CACHE.splice(oldestIndex, 1)
  uiCacheLog("[UiDataCache] evict detailRender id=" + removed.id)
}

function removeDetailRenderById(id: string): void {
  let index: number = DETAIL_RENDER_CACHE.length - 1
  while (index >= 0) {
    if (DETAIL_RENDER_CACHE[index].id === id) {
      DETAIL_RENDER_CACHE.splice(index, 1)
    }
    index -= 1
  }
}
