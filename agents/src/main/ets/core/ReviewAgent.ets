// MathMind - 复习 Agent
// SM-2 间隔重复算法 + 复习场景核心业务
// 创建: Z (W1 块 2 - 2026-07-04)

import {
  AgentTask,
  ConfidenceLevel,
  DifficultyLevel,
  KnowledgeUnit,
  ReviewRecord,
  ReviewStatus,
} from '../../common/src/main/ets/models/CommonTypes';
import { sortForReview, urgencyScore, confidenceToEaseDelta } from '../../common/src/main/ets/utils/confidenceSort';
import { getLogger } from '../../common/src/main/ets/utils/logger';
import { nextReviewReminder, todayWindow } from '../../common/src/main/ets/utils/timeWindow';
import { shortId, uuid } from '../../common/src/main/ets/utils/uuid';

const log = getLogger('ReviewAgent');

// SM-2 算法常量
const MIN_EASE = 1.3;
const INITIAL_EASE = 2.5;
const MS_PER_DAY = 24 * 60 * 60 * 1000;

export class ReviewAgent {
  // 内存仓库(W1 暂用 Map,W2 接 RDBService)
  private store: Map<string, KnowledgeUnit> = new Map();
  private records: ReviewRecord[] = [];

  async handle(task: AgentTask): Promise<Record<string, string>> {
    log.info(`ReviewAgent.handle intent=${task.type}`);
    switch (task.type) {
      case 'app_review':
        return this.handleGetReviewQueue(task);
      case 'skill_quick_review':
        return this.handleGetReviewQueue(task);
      case 'skill_flash':
        return this.handleGetReviewQueue(task);
      case 'card_today':
        return this.handleTodayCard(task);
      case 'skill_add':
        return this.handleAdd(task);
      case 'app_history':
        return this.handleHistory(task);
      case 'card_streak':
        return this.handleStreak(task);
      case 'card_progress':
        return this.handleProgress(task);
      default:
        throw new Error(`ReviewAgent does not handle intent: ${task.type}`);
    }
  }

  // ==================== SM-2 核心算法 ====================
  // 输入:当前单元 + 用户评分(0-4)
  // 输出:更新后的单元(下次复习时间 + 间隔 + ease)
  applySM2(unit: KnowledgeUnit, confidence: ConfidenceLevel): KnowledgeUnit {
    const q = confidence;
    const updated: KnowledgeUnit = { ...unit };

    if (q < ConfidenceLevel.NORMAL) {
      // < 3 重置:repetitions = 0, interval = 1
      updated.repetitions = 0;
      updated.intervalDays = 1;
      updated.reviewStatus = ReviewStatus.LEARNING;
    } else {
      updated.repetitions = unit.repetitions + 1;
      if (updated.repetitions === 1) {
        updated.intervalDays = 1;
      } else if (updated.repetitions === 2) {
        updated.intervalDays = 6;
      } else {
        updated.intervalDays = Math.ceil(unit.intervalDays * unit.easeFactor);
      }
      // 评分达到 3 次 PERFECT 后毕业
      if (updated.repetitions >= 5 && updated.intervalDays >= 30 && q >= ConfidenceLevel.EASY) {
        updated.reviewStatus = ReviewStatus.GRADUATED;
      } else {
        updated.reviewStatus = ReviewStatus.REVIEW;
      }
    }

    // 更新 ease factor
    const delta = confidenceToEaseDelta(q);
    let newEase = unit.easeFactor + delta;
    if (newEase < MIN_EASE) {
      newEase = MIN_EASE;
    }
    updated.easeFactor = newEase;

    // 下次复习时间
    updated.nextReviewAt = Date.now() + updated.intervalDays * MS_PER_DAY;
    updated.updatedAt = Date.now();
    updated.version = unit.version + 1;

    return updated;
  }

  // ==================== 业务方法 ====================
  private handleGetReviewQueue(task: AgentTask): Record<string, string> {
    const now = Date.now();
    const all = Array.from(this.store.values());
    const queue = sortForReview(all, now);

    // 默认取前 20 条
    const limitStr = task.payload['limit'];
    const limit = limitStr ? parseInt(limitStr) : 20;
    const top = queue.slice(0, limit);

    return {
      count: String(top.length),
      total: String(all.length),
      units: JSON.stringify(top),
    };
  }

  private handleTodayCard(task: AgentTask): Record<string, string> {
    const now = Date.now();
    const w = todayWindow(now);
    const all = Array.from(this.store.values());
    const dueToday = all.filter((u) => u.nextReviewAt >= w.startMs && u.nextReviewAt < w.endMs);
    const overdue = all.filter((u) => u.nextReviewAt < w.startMs);

    return {
      dueToday: String(dueToday.length),
      overdue: String(overdue.length),
      units: JSON.stringify([...overdue, ...dueToday].slice(0, 5)),
    };
  }

  private handleAdd(task: AgentTask): Record<string, string> {
    const title = task.payload['title'] ?? '';
    const content = task.payload['content'] ?? '';
    if (title.length === 0) {
      throw new Error('title is required');
    }
    const now = Date.now();
    const unit: KnowledgeUnit = {
      id: uuid(),
      title,
      content,
      summary: task.payload['summary'] ?? content.substring(0, 80),
      tags: task.payload['tags'] ? task.payload['tags'].split(',') : [],
      difficulty: parseInt(task.payload['difficulty'] ?? '2') as DifficultyLevel,
      source: task.payload['source'] ?? 'manual',
      createdAt: now,
      updatedAt: now,
      reviewStatus: ReviewStatus.NEW,
      nextReviewAt: nextReviewReminder(now),
      intervalDays: 1,
      easeFactor: INITIAL_EASE,
      repetitions: 0,
      prerequisites: [],
      related: [],
      embedding: [],
      userId: task.payload['userId'] ?? 'default',
      version: 1,
    };
    this.store.set(unit.id, unit);
    log.info(`add unit id=${unit.id} title=${title}`);
    return { id: unit.id };
  }

  private handleHistory(task: AgentTask): Record<string, string> {
    const limitStr = task.payload['limit'];
    const limit = limitStr ? parseInt(limitStr) : 50;
    const sorted = this.records.slice().sort((a, b) => b.reviewedAt - a.reviewedAt);
    return {
      count: String(Math.min(sorted.length, limit)),
      records: JSON.stringify(sorted.slice(0, limit)),
    };
  }

  private handleStreak(task: AgentTask): Record<string, string> {
    // 简化:统计最近连续有复习记录的天数
    const days = new Set<string>();
    for (const r of this.records) {
      const d = new Date(r.reviewedAt);
      days.add(`${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`);
    }
    let streak = 0;
    const now = new Date();
    for (let i = 0; i < 365; i++) {
      const d = new Date(now);
      d.setDate(d.getDate() - i);
      const key = `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
      if (days.has(key)) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return { streak: String(streak) };
  }

  private handleProgress(task: AgentTask): Record<string, string> {
    const all = Array.from(this.store.values());
    const total = all.length;
    const byStatus: Record<string, number> = {};
    for (const u of all) {
      byStatus[u.reviewStatus] = (byStatus[u.reviewStatus] ?? 0) + 1;
    }
    return {
      total: String(total),
      byStatus: JSON.stringify(byStatus),
    };
  }

  // 提交评分(供 UI 调用)
  submitReview(unitId: string, confidence: ConfidenceLevel, durationMs: number, note: string): KnowledgeUnit {
    const old = this.store.get(unitId);
    if (!old) {
      throw new Error(`unit not found: ${unitId}`);
    }
    const updated = this.applySM2(old, confidence);
    this.store.set(unitId, updated);

    const record: ReviewRecord = {
      id: shortId(),
      unitId,
      reviewedAt: Date.now(),
      confidence,
      durationMs,
      oldInterval: old.intervalDays,
      newInterval: updated.intervalDays,
      note,
    };
    this.records.push(record);

    log.info(`review unit=${unitId} conf=${confidence} → next=${updated.intervalDays}d ease=${updated.easeFactor.toFixed(2)}`);
    return updated;
  }

  // 调试用
  debugDump(): string {
    const all = Array.from(this.store.values());
    return JSON.stringify({
      count: all.length,
      top3: sortForReview(all, Date.now()).slice(0, 3).map((u) => ({
        title: u.title,
        score: urgencyScore(u, Date.now()),
        status: u.reviewStatus,
      })),
    });
  }
}