// MathMind - 时间窗判定工具
// 用于"今日待复习"、"已过期"、"未来 N 天"等场景
// 创建: Z (W1 块 2 - 2026-07-04)

const MS_PER_DAY = 24 * 60 * 60 * 1000;
const MS_PER_HOUR = 60 * 60 * 1000;

export interface TimeWindow {
  startMs: number;
  endMs: number;
}

// 当天 0 点
export function startOfDay(ts: number): number {
  const d = new Date(ts);
  d.setHours(0, 0, 0, 0);
  return d.getTime();
}

// 当天 24 点(次日 0 点)
export function endOfDay(ts: number): number {
  return startOfDay(ts) + MS_PER_DAY;
}

// 今天的时间窗
export function todayWindow(now: number): TimeWindow {
  return {
    startMs: startOfDay(now),
    endMs: endOfDay(now),
  };
}

// 未来 N 天的时间窗(含今天)
export function nextNDaysWindow(now: number, n: number): TimeWindow {
  return {
    startMs: startOfDay(now),
    endMs: startOfDay(now) + (n + 1) * MS_PER_DAY,
  };
}

// 是否在今天(用于"今日待复习"卡片)
export function isToday(ts: number, now: number): boolean {
  const w = todayWindow(now);
  return ts >= w.startMs && ts < w.endMs;
}

// 是否过期(review 时间 < now)
export function isOverdue(reviewAt: number, now: number): boolean {
  return reviewAt < now;
}

// 距离现在的天数(正数未来,负数过去)
export function daysFromNow(targetTs: number, now: number): number {
  const diff = targetTs - now;
  return Math.floor(diff / MS_PER_DAY);
}

// 友好时间显示("3 天后"/"今天"/"已过期 2 天")
export function friendlyDate(targetTs: number, now: number): string {
  if (isToday(targetTs, now)) {
    return '今天';
  }
  const days = daysFromNow(targetTs, now);
  if (days > 0) {
    return `${days} 天后`;
  }
  if (days === 0) {
    return '今天';
  }
  return `已过期 ${-days} 天`;
}

// 计算下一天 9 点的复习提醒时间
export function nextReviewReminder(now: number, hourOfDay: number = 9): number {
  const d = new Date(now);
  d.setHours(hourOfDay, 0, 0, 0);
  if (d.getTime() <= now) {
    d.setDate(d.getDate() + 1);
  }
  return d.getTime();
}