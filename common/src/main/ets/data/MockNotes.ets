/**
 * MathMind 共享数据模型 — 对照 app.js NOTES + noteCardHTML()
 */

import { MINT, PURPLE, PINK, AMBER } from '../constants/ColorTokens';

// ========== 笔记数据模型 ==========
export class NoteItem {
  id: number = 0;
  title: string = '';
  type: string = '';
  subject: string = '';
  chapter: string = '';
  conf: number = 0;
  body: string = '';
  tags: string[] = [];
  date: string = '';

  constructor(
    id: number, title: string, type: string, subject: string,
    chapter: string, conf: number, body: string, tags: string[], date: string,
  ) {
    this.id = id;
    this.title = title;
    this.type = type;
    this.subject = subject;
    this.chapter = chapter;
    this.conf = conf;
    this.body = body;
    this.tags = tags;
    this.date = date;
  }
}

// ========== 5 条 Mock 笔记（对照 app.js NOTES） ==========
export const NOTES: NoteItem[] = [
  new NoteItem(1, '拉格朗日中值定理', '概念', '数学分析', '微分中值定理', 0.92,
    '## 定义\n若函数 f(x) 在闭区间 [a,b] 连续,开区间 (a,b) 可导,则存在 ξ∈(a,b) 使得 f′(ξ) = (f(b)-f(a))/(b-a)。',
    ['中值定理', '导数'], '2026-07-05'),
  new NoteItem(2, '矩阵行列式计算', '计算', '高等代数', '行列式', 0.88,
    '## 题目\n求 n 阶行列式 |A|，其中 a_{ij}=max(i,j)。\n\n## 解法\n利用行变换化为上三角形式。\n\n## 答案\n|A| = n·(-1)^{n-1}',
    ['行列式', '矩阵'], '2026-07-04'),
  new NoteItem(3, '极限 ε-δ 定义', '概念', '数学分析', '极限', 0.85,
    '## 定义\n对任意 ε>0,存在 δ>0,使得当 0<|x-a|<δ 时,|f(x)-L|<ε。\n\n## 性质\n唯一性、局部有界性、保号性。',
    ['极限', '定义'], '2026-07-03'),
  new NoteItem(4, '直线参数方程', '计算', '解析几何', '空间直线', 0.78,
    '## 方程\n空间直线的参数式：\n(x,y,z) = (x₀,y₀,z₀) + t(l,m,n)\n## 说明\n方向向量 (l,m,n) 决定了直线的取向。',
    ['空间直线', '参数方程'], '2026-07-02'),
  new NoteItem(5, '线性相关与无关', '证明', '高等代数', '向量组', 0.82,
    '## 定义\n若存在不全为零的常数 c₁,c₂,…,cₙ，使得 Σcᵢvᵢ=0，则向量组线性相关。\n\n## 推论\n极大无关组 + 线性表示。',
    ['向量组', '线性相关'], '2026-07-01'),
];

// ========== 辅助函数（对照 app.js） ==========

/** 截取 body 纯文本摘要 */
export function stripMD(body: string, n: number = 60): string {
  const c = body.replace(/^## .+$/gm, '').trim();
  return c.length > n ? c.slice(0, n) + '…' : c;
}

/** 近期日期格式化 */
export function recentDate(dateStr: string): string {
  if (!dateStr) {
    return '';
  }
  const d = new Date(dateStr);
  const now = new Date();
  const diff = Math.floor((now.getTime() - d.getTime()) / 86400000);
  if (diff === 0) {
    return '今天';
  }
  if (diff === 1) {
    return '昨天';
  }
  if (diff < 7) {
    return `${diff}天前`;
  }
  const m = d.getMonth() + 1;
  const day = d.getDate();
  return `${m}/${day}`;
}

/** 获取类型首字（对照 JS ts()） */
export function typeChar(t: string): string {
  return (t || '笔').charAt(0);
}

/** 获取类型颜色（对照 CSS + ColorTokens TYPE_COLORS） */
export function typeColor(t: string): string {
  return ({
    '概念': MINT,
    '计算': PURPLE,
    '证明': AMBER,
    '笔记': MINT,
  } as Record<string, string>)[t] || '#FFA8A8B0';
}

/** 获取学科颜色（对照 CSS + ColorTokens SUBJECT_COLORS） */
export function subjectColor(s: string): string {
  return ({
    '高等代数': PURPLE,
    '数学分析': PINK,
    '解析几何': AMBER,
    '空间解析几何': AMBER,
  } as Record<string, string>)[s] || '#FFA8A8B0';
}
