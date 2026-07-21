/**
 * DetailRenderQueue.ets — 笔记详情正文渲染队列
 *
 * 路径: entry/src/main/ets/overlays/NoteDetailOverlay/components/DetailRenderQueue.ets
 * 职责: 将详情页 Markdown/公式正文挂载拆成低间隔串行任务，先显示结构，再逐块释放内容。
 * 依赖: ArkTS setTimeout
 *
 * 数据流:
 *   DetailSection / DetailStepsSection / DetailMetaFooter → enqueueDetailRender → callback 设置 contentReady
 *
 * ArkTS 1.1 strict 适配:
 *   - 使用显式类型
 *   - 无 C 风格 for
 */

export const DETAIL_RENDER_PRIORITY_NORMAL: number = 10
export const DETAIL_RENDER_PRIORITY_META: number = 30

const DETAIL_RENDER_QUEUE_FRAME_DELAY_MS: number = 16
const DETAIL_RENDER_QUEUE_FAST_DELAY_MS: number = 0
const DETAIL_RENDER_QUEUE_FRAME_BUDGET_MS: number = 8
const DETAIL_RENDER_QUEUE_PRESSURE_COUNT: number = 6
const DETAIL_RENDER_QUEUE_MAX_PENDING: number = 80

class DetailRenderJob {
  key: string = ''
  priority: number = DETAIL_RENDER_PRIORITY_NORMAL
  seq: number = 0
  run: () => void = (): void => {}

  constructor(key: string, priority: number, seq: number, run: () => void) {
    this.key = key
    this.priority = priority
    this.seq = seq
    this.run = run
  }
}

const detailRenderJobs: DetailRenderJob[] = []
let detailRenderSeq: number = 0
let detailRenderTimerActive: boolean = false
let detailRenderQueueEpoch: number = 0

export function enqueueDetailRender(key: string, priority: number, run: () => void): void {
  detailRenderSeq += 1
  detailRenderJobs.push(new DetailRenderJob(key, priority, detailRenderSeq, run))
  trimPendingJobs()
  scheduleNextDetailRender()
}

export function resetDetailRenderQueue(): void {
  detailRenderJobs.splice(0, detailRenderJobs.length)
  detailRenderTimerActive = false
  detailRenderQueueEpoch += 1
}

function trimPendingJobs(): void {
  while (detailRenderJobs.length > DETAIL_RENDER_QUEUE_MAX_PENDING) {
    removeLowestPriorityJob()
  }
}

function removeLowestPriorityJob(): void {
  if (detailRenderJobs.length === 0) {
    return
  }
  let removeIndex: number = 0
  let index: number = 1
  while (index < detailRenderJobs.length) {
    const current: DetailRenderJob = detailRenderJobs[index]
    const candidate: DetailRenderJob = detailRenderJobs[removeIndex]
    if (current.priority > candidate.priority
      || (current.priority === candidate.priority && current.seq > candidate.seq)) {
      removeIndex = index
    }
    index += 1
  }
  detailRenderJobs.splice(removeIndex, 1)
}

function scheduleNextDetailRender(): void {
  if (detailRenderTimerActive || detailRenderJobs.length === 0) {
    return
  }
  const epoch: number = detailRenderQueueEpoch
  detailRenderTimerActive = true
  setTimeout((): void => {
    if (epoch !== detailRenderQueueEpoch) {
      return
    }
    detailRenderTimerActive = false
    flushDetailRenderJobs()
    scheduleNextDetailRender()
  }, nextDetailRenderDelay())
}

function flushDetailRenderJobs(): void {
  const startedAt: number = Date.now()
  let renderedCount: number = 0
  while (detailRenderJobs.length > 0 && shouldContinueFlush(startedAt, renderedCount)) {
    const job: DetailRenderJob | null = takeNextJob()
    if (job !== null) {
      job.run()
      renderedCount += 1
    }
  }
}

function shouldContinueFlush(startedAt: number, renderedCount: number): boolean {
  if (renderedCount === 0) {
    return true
  }
  if (detailRenderJobs.length >= DETAIL_RENDER_QUEUE_PRESSURE_COUNT) {
    return Date.now() - startedAt < DETAIL_RENDER_QUEUE_FRAME_BUDGET_MS
  }
  return false
}

function nextDetailRenderDelay(): number {
  if (detailRenderJobs.length >= DETAIL_RENDER_QUEUE_PRESSURE_COUNT) {
    return DETAIL_RENDER_QUEUE_FAST_DELAY_MS
  }
  return DETAIL_RENDER_QUEUE_FRAME_DELAY_MS
}

function takeNextJob(): DetailRenderJob | null {
  if (detailRenderJobs.length === 0) {
    return null
  }
  let bestIndex: number = 0
  let index: number = 1
  while (index < detailRenderJobs.length) {
    const current: DetailRenderJob = detailRenderJobs[index]
    const best: DetailRenderJob = detailRenderJobs[bestIndex]
    if (current.priority < best.priority
      || (current.priority === best.priority && current.seq < best.seq)) {
      bestIndex = index
    }
    index += 1
  }
  const job: DetailRenderJob = detailRenderJobs[bestIndex]
  detailRenderJobs.splice(bestIndex, 1)
  return job
}
