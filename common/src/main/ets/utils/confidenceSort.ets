// MathMind - 置信度排序
// 按"复习紧迫度"对 KnowledgeUnit 列表排序:
//   - 已过期 / 今天复习 → 最先
//   - 间隔短 + 评分低 → 优先
//   - 毕业(GRADUATED)→ 最后或过滤
// 创建: Z (W1 块 2 - 2026-07-04)

import { ConfidenceLevel, DifficultyLevel, KnowledgeUnit, ReviewStatus } from '../models/CommonTypes';

export interface SortOptions {
  // true = 过滤掉 GRADUATED 的(复习场景)
  // false = 全部参与排序(如全库浏览)
  excludeGraduated: boolean;
  // 排序方向
  ascending: boolean;
}

// 复习紧迫度分数(越大越急)
export function urgencyScore(unit: KnowledgeUnit, now: number): number {
  let score = 0;

  // 已过期:权重最高(100 + 过期天数)
  const overdueMs = now - unit.nextReviewAt;
  if (overdueMs > 0) {
    score += 100 + Math.floor(overdueMs / (24 * 60 * 60 * 1000));
  }

  // 难度加权(越难越先)
  score += unit.difficulty * 5;

  // 状态加权
  switch (unit.reviewStatus) {
    case ReviewStatus.NEW:
      score += 20; // 新加入优先
      break;
    case ReviewStatus.LEARNING:
      score += 30; // 学习中优先
      break;
    case ReviewStatus.LAPSED:
      score += 50; // 遗忘最优先
      break;
    case ReviewStatus.REVIEW:
      score += 10;
      break;
    case ReviewStatus.GRADUATED:
      score -= 100; // 毕业降权
      break;
  }

  // 重复次数越少越优先(刚开始学的先复习)
  score += (10 - Math.min(unit.repetitions, 10));

  return score;
}

// 复习场景默认排序:排除已毕业,按紧迫度降序
export function sortForReview(units: KnowledgeUnit[], now: number, options?: Partial<SortOptions>): KnowledgeUnit[] {
  const opts: SortOptions = {
    excludeGraduated: options?.excludeGraduated ?? true,
    ascending: options?.ascending ?? false,
  };

  let arr = units.slice();
  if (opts.excludeGraduated) {
    arr = arr.filter((u) => u.reviewStatus !== ReviewStatus.GRADUATED);
  }
  arr.sort((a, b) => {
    const sa = urgencyScore(a, now);
    const sb = urgencyScore(b, now);
    return opts.ascending ? sa - sb : sb - sa;
  });
  return arr;
}

// 学习/浏览场景:全部,按更新时间倒序
export function sortForBrowse(units: KnowledgeUnit[], now: number): KnowledgeUnit[] {
  const arr = units.slice();
  arr.sort((a, b) => b.updatedAt - a.updatedAt);
  return arr;
}

// 评分转 SM-2 easeFactor 调整量
export function confidenceToEaseDelta(conf: ConfidenceLevel): number {
  switch (conf) {
    case ConfidenceLevel.FORGOT:
      return -0.20;
    case ConfidenceLevel.HARD:
      return -0.15;
    case ConfidenceLevel.NORMAL:
      return 0.00;
    case ConfidenceLevel.EASY:
      return 0.10;
    case ConfidenceLevel.PERFECT:
      return 0.15;
  }
}

// 难度转基础间隔(天)
export function difficultyToBaseInterval(d: DifficultyLevel): number {
  switch (d) {
    case DifficultyLevel.EASY:
      return 4;
    case DifficultyLevel.MEDIUM:
      return 2;
    case DifficultyLevel.HARD:
      return 1;
    case DifficultyLevel.EXPERT:
      return 1;
  }
}