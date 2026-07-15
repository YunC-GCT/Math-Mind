// MathMind - 笔记共享数据(类型 / mock / 工具函数)
// 用途: HomePage + NotesPage + 后续 MePage 等共用
// 放在 entry 下面,因为是 UI 用的,不入 common HSP

import {
  MINT,
  TYPE_COLORS, TYPE_DEFAULT,
  SUBJECT_COLORS, SUBJECT_DEFAULT
} from 'common/src/main/ets/constants/ColorTokens';

// ==================== NoteView 接口 ====================
export interface NoteView {
  id: number;
  title: string;
  type: string;
  subject: string;
  chapter: string;
  conf: number;
  body: string;
  tags: string[];
  date: string;
}

// ==================== Mock 数据(对照 app.js NOTES)===================
export const MOCK_NOTES: NoteView[] = [
  { id: 1, title: '拉格朗日中值定理', type: '概念', subject: '数学分析', chapter: '微分中值定理', conf: 0.92, body: '## 定义\n若函数 f(x) 在闭区间 [a,b] 连续,开区间 (a,b) 可导,则存在 ξ∈(a,b) 使得 f′(ξ) = (f(b)-f(a))/(b-a)。', tags: ['中值定理', '导数'], date: '2026-07-05' },
  { id: 2, title: '矩阵行列式计算', type: '计算', subject: '高等代数', chapter: '行列式', conf: 0.88, body: '## 题目\n求 n 阶行列式 |A|,其中 a_{ij}=max(i,j)。\n\n## 解法\n利用行变换化为上三角形式。\n\n## 答案\n|A| = n·(-1)^{n-1}', tags: ['行列式', '矩阵'], date: '2026-07-04' },
  { id: 3, title: '极限 ε-δ 定义', type: '概念', subject: '数学分析', chapter: '极限', conf: 0.85, body: '## 定义\n对任意 ε>0,存在 δ>0,使得当 0<|x-a|<δ 时,|f(x)-L|<ε。\n\n## 性质\n唯一性、局部有界性、保号性。', tags: ['极限', '定义'], date: '2026-07-03' },
  { id: 4, title: '空间直线方程', type: '计算', subject: '解析几何', chapter: '直线与平面', conf: 0.78, body: '## 题目\n求过点(1,2,3)且平行于向量(2,-1,4)的直线方程。\n\n## 解法\n参数方程:x=1+2t, y=2-t, z=3+4t。', tags: ['直线', '参数方程'], date: '2026-07-02' },
  { id: 5, title: '证明向量组线性无关', type: '证明', subject: '高等代数', chapter: '线性空间', conf: 0.82, body: '## 命题\n设 α₁,α₂,α₃ 线性无关,证明 α₁+α₂, α₂+α₃, α₃+α₁ 也线性无关。\n\n## 证明\n设 k₁(α₁+α₂)+k₂(α₂+α₃)+k₃(α₃+α₁)=0,整理系数求解。', tags: ['线性无关', '向量组'], date: '2026-07-01' }
];

// ==================== 工具函数(模块顶层,ArkTS 严格语法禁 struct 内方法)====================

export function getTypeColor(type: string): string {
  return TYPE_COLORS[type] || TYPE_DEFAULT;
}

export function getSubjectColor(subject: string): string {
  return SUBJECT_COLORS[subject] || SUBJECT_DEFAULT;
}

export function getConfColor(conf: number): string {
  if (conf >= 0.8) return MINT;
  if (conf >= 0.5) return '#F0C674';
  return '#FF6B6B';
}

export function getConfText(conf: number): string {
  return (conf * 100).toFixed(0) + '%';
}

// 摘要:去掉 ## 标题行(无 regex,无 C 风格 for),截 60 字
export function getBodyPreview(body: string): string {
  if (!body) return '';
  const lines: string[] = body.split('\n');
  const kept: string[] = [];
  for (const line of lines) {
    if (line.indexOf('## ') !== 0) {
      kept.push(line);
    }
  }
  const stripped = kept.join(' ').trim();
  if (stripped.length <= 60) return stripped;
  return stripped.substring(0, 60) + '…';
}
