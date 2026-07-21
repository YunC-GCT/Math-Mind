# MathMind UI 预加载与缓存优化方案 — 需求文档

> 版本: v1.0
> 日期: 2026-07-21
> 状态: 设计中
> 来源: `docs/ui-preload-cache-optimization-20260721.html`（视觉稿）

---

## 1. 背景与目标

在不改变现有 5 Tab 结构、不引入服务端依赖的前提下，减少页面切换、笔记详情打开和公式渲染时的重复查库与重复解析。

### 1.1 核心策略

| 维度 | 说明 |
|------|------|
| **首要优化** | 笔记详情目前按点击后查库，渲染模型和 Markdown 解析未缓存。 |
| **现有优势** | `MathTextRenderer` 已有内存 LRU + TTL 缓存，可继续复用。 |
| **刷新信号** | 已有全局 `notesVersion`，可作为缓存失效入口。 |
| **不要做** | 避免为了预加载长期驻留后台任务，保持轻量。 |

---

## 2. 当前状态

| 区域 | 当前做法 | 问题 |
|------|----------|------|
| 首页 / 笔记页 / 学科页 | `aboutToAppear` 或 `notesVersion` 变化后 `queryAll()` | 多页面各自全量查库，切 Tab 后容易重复构建同一批列表数据。 |
| 笔记详情 | 点击后 `queryById()`，完整正文加载到 Overlay | 可见加载态明显；最近笔记、学科内下一条没有预热。 |
| Markdown | 每次 build 内直接 `parseMarkdown()` / `parseMarkdownInline()` | 长正文滚动或状态刷新时重复解析。 |
| 公式渲染 | `MATH_RENDER_CACHE` 缓存 HTML + 高度 | 已有基础，但缓存只在实际渲染后形成，没有详情打开前的轻预热。 |
| 列表 | `ForEach` 渲染 | 数量上来后没有虚拟列表或窗口化策略。 |

---

## 3. 目标架构

```
RDB → UiDataCache → PreloadQueue → RenderCache → UI
```

| 层 | 职责 |
|----|------|
| **RDB** | 唯一事实源，仍由 `NoteDao` / `StudyPlanDao` 负责读写。 |
| **UiDataCache** | 进程内缓存：笔记列表、详情、学科聚合、复习计划。 |
| **PreloadQueue** | 低优先级串行任务：首屏后预热 Notes、Review、最近详情。 |
| **RenderCache** | 缓存详情渲染模型、Markdown block、inline segment、公式 HTML。 |
| **UI** | 页面只订阅 snapshot；命中缓存时同步显示，后台补新。 |

---

## 4. 缓存分层

数据类型: `数据缓存` `派生模型缓存` `渲染缓存` `失效总线`

| 缓存 | Key | 失效策略 |
|------|-----|----------|
| 笔记列表 snapshot | `notesVersion` | 新增、编辑、删除、AI 生成后 bump。 |
| 笔记详情 | `unit.id + updatedAt + version` | 该笔记保存后单条失效。 |
| 学科分组 | `notesVersion` | 跟随列表失效。 |
| 详情渲染模型 | `unit.id + updatedAt + category` | 正文或类型变更后失效。 |
| Markdown block | `contentHash(text)` | LRU + 10 分钟 TTL。 |
| 公式 HTML | 沿用现有 `profile\|forceDisplay\|hash` | 沿用 64 条、600000 chars、10 分钟 TTL。 |

---

## 5. 预加载触发

| 时机 | 动作 | 优先级 |
|------|------|--------|
| 首页首屏完成后 | 预热笔记列表、学科分组、复习计划。 | **P0** |
| 首页 recent notes 渲染后 | 预取最近 3 条 `KnowledgeUnit` 详情。 | **P0** |
| 进入 Notes Tab 前后 | 如果列表缓存命中直接显示，否则后台刷新。 | **P0** |
| 进入学科详情页后 | 预取当前学科前 5 条详情。 | **P1** |
| 打开笔记详情后 | 预解析详情模型和 Markdown block。 | **P1** |
| 空闲 300-600ms | 处理队列下一项，避免阻塞首屏。 | **P1** |

---

## 6. 各界面实施方案

| 界面 | 调整 | 效果 |
|------|------|------|
| **Home** | 改为读 `UiDataCache.getNotesSnapshot()`；首次未命中才查库；首屏后入队预热最近详情。 | 首页和 Notes 共用同一份列表数据。 |
| **Notes** | 从缓存读取 `notes` / `subjectGroups`；后台 refresh 后只在版本变化时替换引用。 | 切 Tab 不重复 `queryAll()`。 |
| **SubjectDetail** | 先用缓存分组进入；预取当前学科前 5 条详情；打开详情时优先读 detail cache。 | 列表到详情更少加载态。 |
| **NoteDetailOverlay** | 新增 `DetailRenderCache`，缓存 `buildDetailRenderModel()` 结果。 | 编辑保存外的重复打开不重建模型。 |
| **MarkdownRenderer** | 新增 `MarkdownBlockCache` 和 `MarkdownInlineCache`。 | 长正文切换/重绘时减少 CPU。 |
| **Review** | StudyPlan snapshot 缓存，`aboutToAppear` 命中即显示，`onPageShow` 后台 refresh。 | 保留当前回到页面刷新语义，降低白屏。 |
| **AgentFloatWindow** | 会话历史仍由 preferences 管理；只缓存当前活跃会话渲染用消息，不写入全局 UI 缓存。 | 避免浮窗状态污染笔记缓存。 |

---

## 7. 落地顺序

### P0-1 — 新增 UiDataCacheService
封装 notes snapshot、subject groups、note detail map、study plan snapshot；所有缓存只在进程内，不落盘。

### P0-2 — ViewModel 改造
改 Home / Notes / SubjectDetail / Review 的 ViewModel：先读缓存，再后台 refresh；写操作后通过现有 `notesVersion` 统一失效。

### P0-3 — 新增 PreloadQueue
串行执行、可去重、可取消；首页首屏后预热 Notes / Review / recent detail。

### P1-1 — 新增 DetailRenderCache
把 `buildDetailRenderModel()` 从 build 期重复计算移到可缓存函数。

### P1-2 — Markdown parser 加 LRU
给 Markdown parser 加 LRU；公式渲染沿用现有缓存，只补充缓存命中率日志。

### P2 — 列表窗口化
列表超过阈值后切到 `LazyForEach` 或窗口化渲染；先在 Notes 和 SubjectNoteList 试点。

---

## 8. 验收指标

| 指标 | 目标 |
|------|------|
| Home → Notes 切换 | 缓存命中时不触发重复全量查库。 |
| 最近 3 条笔记详情 | 预取后打开无"正在加载笔记内容"或停留小于 150ms。 |
| Markdown 解析 | 同一正文重复打开不重复 parse。 |
| 公式缓存 | 重复详情打开命中现有 `MATH_RENDER_CACHE`。 |
| 内存上限 | UI cache 默认不超过 100 条 detail / 2MB 文本派生数据。 |

---

## 9. 资料依据

> HarmonyOS Stage 模型支持同一进程内共享对象和状态，适合做进程内 UI cache；但后台行为受管控，所以不建议靠常驻后台做预加载。

- [Stage 模型开发概述](https://developer.huawei.com/consumer/cn/arkui/arkui-stage/)
- [onPageShow 时机建议](https://developer.huawei.com/consumer/cn/doc/harmonyos-faqs/faqs-arkui-190)
- [WebView 本地 HTML 与 JavaScript 交互](https://developer.huawei.com/consumer/en/codelab/HarmonyOS-WebView/)
- [AppGallery Connect 预加载服务](https://developer.huawei.com/consumer/cn/agc/preload-service)
- [ArkUI 渲染控制目录：ForEach / LazyForEach / Repeat](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-brace-style-stylistic)
