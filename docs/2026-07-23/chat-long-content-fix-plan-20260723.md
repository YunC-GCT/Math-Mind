# MindTrace 浮窗长 AI 回复截断 — 修复实施计划

> 日期: 2026-07-23
> 作者: Mavis
> 状态: 待实施
> 关联问题: AI 回复太长时对话窗口空白 / 内容被截断
> Working tree 基线: `HEAD` = `6755a62` (origin/main 同步)

---

## 背景

用户在 AI 浮窗发送长 prompt 后,AI 回复超过 ~4000vp 时,对话气泡出现"空白区域"或内容被截断。

### 根因(从代码静态分析还原)

| # | 根因 | 位置 |
|---|------|------|
| 1 | `MathTextRenderer.clampHeight` 用 `Math.min(maxHeight, ...)`,把 webHeight 上限锁死在 `maxHeight` | `shared/components/MathTextRenderer.ets:377` |
| 2 | `ChatBubble.ets` 调 `MathTextRenderer` 时传 `maxHeight: 4000`,长内容超过 4000vp 全部裁切 | `overlays/AgentFloatWindow/chat/ChatBubble.ets:44, 90` |
| 3 | `MathTextRenderer.estimateHeight` 估算偏小(每个 KaTeX display 公式只算 34vp,实际 50-80vp) | `shared/components/MathTextRenderer.ets:451` |
| 4 | `render.html` `#content` `overflow: hidden`,内容溢出无滚动兜底 | `resources/rawfile/render.html` |
| 5 | `MATH_RENDER_CACHE` 缓存了修复前的旧 height(TTL 10 min),修复后缓存命中仍返回 4000vp,**等于没修** | `shared/components/MathTextRenderer.ets:113` |
| 6 | `MathTextRenderer.@Prop maxHeight: number = 1800` 还在声明,但 `clampHeight` 已不再使用,**API 契约 vs 实现不一致** | `shared/components/MathTextRenderer.ets:191` |
| 7 | `MarkdownRenderer.ets` 仍给 `MathTextRenderer` 传 `maxHeight: this.profile === 'chat' ? 4000 : 1800`(2 处),死 prop 残留 | `shared/components/MarkdownRenderer.ets:124, 240` |
| 8 | `NoteDao.NOTE_METADATA_COLUMNS` 缺 `'chapter'`,`queryAllMetadata` 路径读不到 chapter,持久化闭环不完整 | `database/NoteDao.ets:15-19` |
| 9 | `estimateHeight` 的 `1.4` 系数是裸字面量,项目同类调参常量都是具名 `const` | `shared/components/MathTextRenderer.ets:454` |

### 修复目标(spec)

- 长 AI 回复完整显示,不滚动、不截断
- estimate → actual 之间 webHeight 跳变小
- 不引入 WebView 内部嵌套滚动
- API 契约与实现一致
- 缓存旧值不阻挡修复生效

---

## 实施步骤(按优先级)

### 🔴 P0-1 · `MATH_RENDER_CACHE` 加版本号 `v2`(关键)

**问题:** 修复前缓存了被截到 4000vp 的 height,修复后 10 min 内缓存命中仍返回旧 height,**等于没修**。

**改 `entry/src/main/ets/shared/components/MathTextRenderer.ets`:**

**步骤 A:** 在文件顶部常量区加版本号
```typescript
const MATH_RENDER_CACHE_KEY_VERSION: string = 'v2'
```

**步骤 B:** 改 `cacheKey` 方法(第 350 行附近)
```typescript
private cacheKey = (markdown: string): string => {
  return this.profile + '|' + MATH_RENDER_CACHE_KEY_VERSION + '|' + (this.forceDisplay ? '1' : '0') + '|' + contentHash(markdown)
}
```

**验证:**
- `grep MATH_RENDER_CACHE_KEY_VERSION MathTextRenderer.ets` 确认版本号生效
- 真机测试:升级后用户已有的 10 min 内长 AI 回复气泡立即显示完整内容(旧 cacheKey 不命中,触发新 cacheKey 重渲染)

---

### 🔴 P0-2 · 删 `MathTextRenderer.@Prop maxHeight` 死字段

**问题:** `clampHeight` 删了 `Math.min(this.maxHeight, ...)`,但 @Prop `maxHeight: number = 1800` 仍在声明,API 契约违约。

**改 `entry/src/main/ets/shared/components/MathTextRenderer.ets:191`:**

**步骤:** 删一行
```typescript
// 删
@Prop maxHeight: number = 1800
```

**验证:**
- 全文 grep `maxHeight` 确认 `MathTextRenderer.ets` 内无残留
- DevEco Studio build 通过(无 dead prop 警告)

---

### 🟡 P1-1 · `MarkdownRenderer.ets` 删 `maxHeight` 传参(2 处)

**问题:** 配合 P0-2 删 @Prop 后,`MarkdownRenderer.ets:124, 240` 仍在传未声明的 prop,会编译警告或运行时忽略。

**改 `entry/src/main/ets/shared/components/MarkdownRenderer.ets:124` 和 `:240`:**

**步骤:** 删两行
```typescript
maxHeight: this.profile === 'chat' ? 4000 : 1800,
```

**验证:**
- 全文 grep `maxHeight` 确认全栈无残留
- DevEco Studio build 通过

---

### 🟡 P1-2 · `1.4` 提为具名常量 `DISPLAY_FORMULA_BUFFER_RATIO`

**问题:** 项目里同类调参常量都是具名 `const`(同文件已有 7 个 `MATH_RENDER_*_MS` / `*_LIMIT` 常量),`1.4` 裸字面量不一致。

**改 `entry/src/main/ets/shared/components/MathTextRenderer.ets`:**

**步骤 A:** 在文件顶部常量区加
```typescript
const DISPLAY_FORMULA_BUFFER_RATIO: number = 1.4
```

**步骤 B:** 在 `estimateHeight` 里替换字面量(第 454 行附近)
```typescript
const estimated: number = (lineCount * baseLineHeight + formulaExtra + 18) * DISPLAY_FORMULA_BUFFER_RATIO
```

**验证:**
- 全文 grep `1.4` 确认无残留字面量
- 中文注释保留(说明 1.4 的来源:KaTeX display 公式行高 + padding 实际比纯文本行高更大)

---

### 🟢 P2-1 · `NOTE_METADATA_COLUMNS` 加 `'chapter'`

**问题:** `queryAllMetadata` 用 `NOTE_METADATA_COLUMNS` 数组 select 列,**没包含 `chapter`**。metadata 列表路径(学科页 / 首页 / NotesSummary)走 `rowToMetadataUnit` 时 chapter 永远读不到(返回 `''`)。chapter 持久化闭环不完整。

**改 `entry/src/main/ets/database/NoteDao.ets:15-19`:**

**步骤 A:** 加 `'chapter'` 列(放在 `category` 之后,跟 `rowToUnit` / `rowToMetadataUnit` / `toBucket` 字段顺序对齐)
```typescript
const NOTE_METADATA_COLUMNS: string[] = [
  'id', 'title', 'summary', 'tags', 'subject', 'category', 'chapter', 'difficulty', 'source',
  'created_at', 'updated_at', 'review_status', 'next_review_at', 'interval_days',
  'ease_factor', 'repetitions', 'user_id', 'version',
]
```

**验证:**
- 现有 `rowToUnit` (line 203) + `rowToMetadataUnit` (line 179) + `toBucket` (line 233) 3 处 chapter 都已对齐
- 跑 `queryAllMetadata` 确认 chapter 字段有值(DB schema 列已存在于 `6755a62`,只是 select 没拉)

---

## 改动总览

| 步骤 | 文件 | 改动量 |
|------|------|--------|
| P0-1 | `shared/components/MathTextRenderer.ets` | +1 常量,改 `cacheKey` |
| P0-2 | `shared/components/MathTextRenderer.ets` | -1 行(删 @Prop) |
| P1-1 | `shared/components/MarkdownRenderer.ets` | -2 行(删传参) |
| P1-2 | `shared/components/MathTextRenderer.ets` | +1 常量,改 `estimateHeight` 字面量 |
| P2-1 | `database/NoteDao.ets` | +1 列名 |

**总改动: 3 文件,+5 / -5 行**

---

## 风险与缓解

| 风险 | 缓解 |
|------|------|
| P0-1 cacheKey 改 version → 现有缓存全部失效,首次升级后所有 AI 气泡重新渲染 | 预期内,KaTeX 重渲染耗时几百 ms,不影响功能 |
| P0-2 删 @Prop maxHeight → 任何第三方传 maxHeight 都会编译警告 | 全文 grep 已确认无第三方调用 |
| P1-1 删 MarkdownRenderer 传参 → 公式路径走 MathTextRenderer 默认渲染 | 已确认 MathTextRenderer 行为正确 |
| P2-1 `queryAllMetadata` 加列 → 大数据量时查询稍慢 | chapter 是 TEXT,增量可忽略(<1ms) |

---

## Commit 建议

按优先级分 3 个 commit,保持原子性:

1. `fix(render): uncap math text height and bump render cache v2`
   - P0-1 + P0-2 + P1-1(同一类问题,删 maxHeight 上限 + 缓存失效 + 死 prop 清理)

2. `refactor(render): extract display formula buffer ratio`
   - P1-2(风格统一,提具名常量)

3. `fix(dao): include chapter in metadata select columns`
   - P2-1(用户保留的 chapter 补完)

按项目规则,本地 commit OK,push 必须 user 点头。

---

## 验证清单(真机 build 后)

| 场景 | 预期 |
|------|------|
| 短 AI 回复 (<280 字, 无公式) | 正常显示,无滚动 |
| 中等 (500-1000 字, 无公式) | 正常,可能看到微小跳变 (estimate → actual) |
| **长 AI 回复 (1500+ 字 + 多个 $$ 公式)** | **完整显示,无截断、无滚动** |
| 极端长 (5000+ 字) | 完整显示,气泡很高,List 内可滚 |
| 公式 KaTeX 渲染 | 不受影响 |
| 升级前已缓存的 10 min 内长内容 | 升级后立即看到完整内容(P0-1 缓存版本生效) |
| 学科页 / 首页 / NotesSummary 的 chapter 字段 | 不再恒为空(P2-1 生效) |

---

## 不在本次范围(后续 P3+)

- 嵌套 MathTextRenderer 时外层 List 滚动冲突(本次走"完全自适应不滚动"路线,已规避)
- KaTeX 行内公式(`$...$`)的估算系数(本次只覆盖 display 公式 `$$...$$`)
- estimate → actual 跳变动画过渡(当前直接跳,可后续加 animateTo 优化)
- `MathTextRenderer` 的 `forceDisplay` / `minHeight` / `profile` 字段重构(不在本次范围)
