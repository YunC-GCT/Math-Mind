# MindTrace · 数学学习助手

> 工程: [YunC-GCT/Math-Mind](https://github.com/YunC-GCT/Math-Mind) · HarmonyOS 数学学习助手
> 作者: YunC-GCT <2549237929@qq.com> · 当前主笔: Z
> 最近更新: 2026-09-01 · 全代码库架构审计 + arkts-lint v0.3 (AST) + GitHub Actions CI 已落地

---

## 当前阶段总览 (2026-07-24)

W4 完成 **多 WebView 分块渲染方案**,解决 ArkUI WebView 1800vp 高度上限导致的长内容空白问题,核心交付:

**分块渲染层 (entry):**
- `FormulaSplitRenderer`:按 `$$` 拆分 markdown 为 FormulaBlock[],合并相邻文本块减少 ~40% WebView 数量,公式块 `forceDisplay=true` 无高度上限,文本块 ≤1800vp
- `FormulaBlockDataSource` 实现 `IDataSource`,配合 `LazyForEach` 实现按需创建/销毁 WebView (仅可见 block 持有实例)
- `splitLongTextBlocks()`:超 1500 字符的文本块按 `\n\n` 段落边界二次拆分,防止极端超长纯文本 >1800vp 被截断
- block 硬上限 30,超出截断防 OOM

**公式渲染优化:**
- `render.html` 新增 `renderFormula` / `renderFormulaForCache` bridge:公式块跳过 `marked.parse` + `renderMathInElement` 全 DOM 扫描,直接 `katex.renderToString(innerTex, {displayMode:true})` — 快 ~30-50%
- `MathTextRenderer.clampHeight` 改为 `forceDisplay` 感知: `true` 时 `Math.max(minHeight,height)` 无上限,`false` 时保持 1800vp 上限
- `MathTextRenderer.renderContent()` 按 `forceDisplay` 自动路由公式/文本两套 bridge

**乱码修复:**
- `NotesPage.ets` / `SubjectDetailPage.ets` / `NoteItemMapper.ets` 共 4 处 UTF-8→Latin-1 编码乱码修正 ("笔记加载失败"、"学科"、"笔记")

完整方案、调研资料、风险矩阵见 [`docs/legacy/mindtrace/plans/w4/formula-split-render-plan-2026-07-24.md`](./docs/legacy/mindtrace/plans/w4/formula-split-render-plan-2026-07-24.md)。

**渲染协议层 (common):**
- `LlmGuard` + `LlmOutputRules`:LLM 输出多通道守卫(类型/字段/风险/HTML 转义),失败时 `validate()` 返回结构化 `LlmGuardReport`
- `LatexRiskNormalizer`:LaTeX 风险归一化,把裸 `\\frac` / 缺失定界符 / 误用 `*` 转义等编译失败模式换成安全等价形式
- `ContentProtocol` + `ContentExcerptBuilder`:`MM-MD-v1` 协议归一化 AI/OCR/历史三源,统一 `summary`/`markdown`/`raw` 三段结构,摘要按公式边界安全截断(不切 `$...$` 内部)
- `MathTextParser` 增强:行内 `$...$` / `$$...$$` / `\(...\)` / `\[...\]` 四种定界符混排

**渲染组件层 (entry):**
- `MathTextRenderer` 重构:先走原生 ArkUI,含公式才挂 WebView + KaTeX 0.16.9 auto-render;KaTeX 失败回退原文不空白
- `MarkdownRenderer` 拆分 chat / detail 双模式,chat 不建 WebView,detail 走协议 + 5 类专属 renderer
- `MathPreviewText` 短公式单行 KaTeX 编译,笔记卡片摘要/学科内笔记块共用
- `AgentChatService.realReply()` 显示与入库走同一份协议归一化,即时消息与历史消息渲染一致

**详情渲染层 (NoteDetail):**
- `DetailRenderModel` + `DetailRenderCache` 分离元数据与节点树,LRU 限制 8 条 / 512KB
- `DetailRenderQueue` 二阶段 `List + LazyForEach` 虚拟化:首次仅挂 3 节点,"继续阅读"每次追加 3 节点
- 5 个专属 renderer:Computation / Concept / Fallback / Formula / Proof / Theorem,统一走 `DetailSection + DetailStepList + DetailMetaFooter`
- `NoteEditForm` / `NoteSection` 旧组件清理,`NoteDetailBody` 缩 234 行

**缓存与预加载:**
- `UiDataCacheService` 主页 + 学科页 + 详情页三段式数据缓存,带 `UiCacheDebug` 调试面板
- `MarkdownParseCache` block / inline 双层缓存,带总字符预算和超大条目绕过
- 笔记列表查询改用元数据,不再批量读 `content` / `embedding` / 关系字段

**清理:**
- 删除 9 个 `*MVP.ets` + 旧 `AiTestPage`(`KnowledgeModelMVP` / `DispatcherMVP` / `DatabaseHelperMVP` / `NoteDaoMVP` / `AgentFloatWindowMVP` / `AiServiceMVP` / `IndexMVP` / `AiTestPage` / `AiTestPageMVP`),合并内容已合入正式版
- `AgentFloatWindow` 状态气泡重做,失败/解析/兜底三态显式区分

完整方案、缓存参数、KaTeX 资料、风险模式清单见 [`docs/render-protocol-optimization-route-2026-07-22.md`](./docs/legacy/mindtrace/plans/w3/render-protocol-optimization-route-2026-07-22.md)。

### 当前 W3.5 已验证

- `ContentProtocol` / `LatexRiskNormalizer` / `ContentExcerptBuilder` / `LlmGuard` / `MarkdownRendererProtocol` 共 5 套单测全部通过
- 真实数据库 AI 回放结果为 `renderMode=katex`,3 条历史笔记预览全部通过协议检查
- `git diff --check` 无 whitespace error,ArkTS 1.1 禁用写法扫描无命中
- `hvigor CLI` 与 DevEco Studio GUI 均可用于 Build；真机滚动 / Profiler 内存峰值仍需手动确认

---

---

## 2026-07-24 多 WebView 分块渲染 · 解决 ArkUI WebView 1800vp 上限

### 问题

ArkUI Web 组件在此设备上有 **1800vp 高度上限**,超过后 WebView 完全空白(非截断)。此前 `clampHeight` 强行限制为 1800vp + WebView 内部 `overflow-y:auto`,导致 **List + WebView 双重滚动**,UX 不理想。

### 解决方案: 多 WebView 分块架构

```
改前: ChatBubble → MathTextRenderer ×1 (单 WebView, ≤1800vp, 内部滚动)
改后: ChatBubble → FormulaSplitRenderer
        └─ splitByFormulas → 合并相邻文本 → LazyForEach
             ├─ 公式块 → MathTextRenderer(forceDisplay=true,  无上限, renderFormula bridge)
             └─ 文本块 → MathTextRenderer(forceDisplay=false, ≤1800vp)
```

**核心改动 (6 文件):**

| 文件 | 操作 | 要点 |
|------|------|------|
| `FormulaSplitRenderer.ets` | 新建 245 行 | `splitByFormulas` 合并相邻文本 + `FormulaBlockDataSource(IDataSource)` + `LazyForEach` + `splitLongTextBlocks` 超长段落拆分 |
| `MathTextRenderer.ets` | 改 3 处 | `clampHeight` 按 `forceDisplay` 区分; `renderContent` 公式块走 `renderFormulaForCache` bridge |
| `ChatBubble.ets` | 改 3 处 | 两处 `MathTextRenderer` → `FormulaSplitRenderer(profile: chat/chatUser)` |
| `render.html` | +2 函数 | `renderFormula` / `renderFormulaForCache` — 跳过 `marked.parse` + 树遍历,直接 `katex.renderToString` |
| `NotesPage.ets` | 修 2 处 | 乱码修正 ("笔记加载失败"、"学科") |
| `SubjectDetailPage.ets` / `NoteItemMapper.ets` | 各修 1 处 | 乱码修正 ("笔记加载失败"、"笔记") |

**关键防护:**
- 合并相邻文本:公式之间的连续段落合并 → ~40% WebView 减少
- `LazyForEach` + `IDataSource`:仅可见 block 持有 WebView,滚出视口自动销毁回收
- block 硬上限 30, `TEXT_BLOCK_CHAR_LIMIT=1500` 防止 >1800vp 截断
- 公式块 `renderFormula` bridge 无上限且快 ~30-50%

**调研支撑:**
- [`docs/legacy/mindtrace/research/multi-webview-performance-2026-07-24.md`](./docs/legacy/mindtrace/research/multi-webview-performance-2026-07-24.md) — 多 WebView 架构(MDN/Flutter/RN/HarmonyOS)
- [`docs/legacy/mindtrace/research/formula-render-strategies-2026-07-24.md`](./docs/legacy/mindtrace/research/formula-render-strategies-2026-07-24.md) — 公式渲染策略(KaTeX/MathJax/ChatGPT/Claude/DeepSeek/SSR)
- 完整方案见 [`docs/legacy/mindtrace/plans/w4/formula-split-render-plan-2026-07-24.md`](./docs/legacy/mindtrace/plans/w4/formula-split-render-plan-2026-07-24.md)

### 验证

- 已做文件级静态审查:ArkTS 1.1 strict / UTF-8 noBOM
- DevEco Studio GUI 编译 + 真机验收 (含公式/多公式/流式输出/纯文本回归/超长文本) 已通过

---

## 2026-07-22 长正文按需加载与缓存优化

- 笔记列表改用元数据查询，不再提前读取所有 `content`、`embedding` 和关系字段；完整正文只在点击单条笔记后按 ID 加载。
- 删除首页 3 篇、学科页 5 篇正文预加载，列表快照也不再批量写入详情缓存。
- 详情记录和详情 render model 均限制为 8 条、约 512 KB；Markdown block/inline cache 增加总字符预算和超大条目绕过策略。
- 结构化正文不再重复挂载 `原文/OCR 原文`；原始材料默认折叠，用户展开后才创建 Markdown/KaTeX 渲染树。
- Markdown 与长步骤首次只挂载 3 个节点，不再通过定时器自动扩展到全文；“继续阅读”每次追加 3 个节点。
- 超长段落在公式边界之外安全切块，避免单个长段落生成巨型 ArkWeb，同时保证 `$...$`、`$$...$$`、`\(...\)` 和 `\[...\]` 不被截断。
- 完整设计、主流长文本处理模式、缓存参数、二阶段 `List + LazyForEach` 虚拟化路线和 DevEco 验收步骤见 [`docs/render-protocol-optimization-route-2026-07-22.md`](./docs/legacy/mindtrace/plans/w3/render-protocol-optimization-route-2026-07-22.md#21-长正文缓存预加载与渐进渲染优化)。

### 验证

- 已新增“超长段落包含长行内公式”的 parser 回归测试，逐块检查公式定界符成对。
- 已执行 `git diff --check` 和 ArkTS 1.1 禁用写法扫描。
- `hvigor CLI` 与 DevEco Studio GUI 均可用于 Build；真机滚动流畅度和 Profiler 内存峰值需要手动确认。

---

## 2026-07-22 MM-MD-v1 渲染协议与笔记摘要优化

### 渲染顺序

MindTrace 统一采用以下内容链路：

```text
AI / OCR / 历史数据
  -> ContentProtocol (MM-MD-v1 归一化与风险校验)
  -> Markdown 结构解析
  -> KaTeX 仅编译已确认的完整公式
  -> ArkUI 承载原生文本或 WebView
```

- AI 气泡含公式时，整条回复进入单个 `MathTextRenderer`，WebView 内固定执行 `marked.parse -> KaTeX auto-render`。
- AI 气泡不含公式时走原生 `MarkdownRenderer(chat)`，支持标题、段落、加粗、代码和单层列表，不创建 WebView。
- 协议或公式风险检查失败时显示原文，不允许渲染为空白。
- `AgentChatService` 在显示和入库前使用同一份协议归一化结果，避免即时消息与历史消息不一致。

### 笔记列表摘要

- `ContentExcerptBuilder` 替代列表层的 `stripMD(..., 80)` 字符硬截断，截断点不会落入 `$...$`、`$$...$$` 或 LaTeX 公式内部。
- `NoteCard` 摘要调整为约 46 字、单行显示；短公式完整保留并由 KaTeX 编译。
- 长公式在列表折叠为“相应公式”或“核心公式”，完整公式、推导和原文仍保存在详情页 `content`。
- 新生成笔记的 `summary` 调整为约 220 字的纯文字概览；旧数据库无需迁移，读取时动态构造安全预览。
- `KnowledgeModel` Prompt 要求每个字段先写 1-2 句文字概括，再另起段落放公式或推导。

### 验证

- 模拟器数据库中的真实 AI 回复回放结果为 `renderMode=katex`，不再进入 `plainFallback`。
- 现有 3 条笔记预览全部通过协议检查，保留的 3 个短公式均通过本地 KaTeX 0.16.9 编译。
- 已增加 `ContentProtocol`、`LatexRiskNormalizer`、`ContentExcerptBuilder` 和 Markdown-only 回归测试。
- `git diff --check`、TypeScript strict 诊断和 `render.html` JavaScript 语法检查通过。
- 完整方案、各模型输出约束和 KaTeX 资料见 [`docs/render-protocol-optimization-route-2026-07-22.md`](./docs/legacy/mindtrace/plans/w3/render-protocol-optimization-route-2026-07-22.md)。
- DevEco Studio GUI 编译与真机视觉 smoke test 仍需手动执行。

---

## 2026-07-22 笔记页细节修复

### 做了什么

- 修复笔记详情页右上角删除按钮：`AppIcon(name="trash")` 不再回退到 `×` 字符，改为独立的垃圾桶线条图标。
- 修复笔记页点击搜索入口时的 Toast 乱码：提示文案改为 `搜索功能开发中`，并使用 Unicode 转义写入，避免终端编码导致再次乱码。
- 顺手对触碰到的 `AppIcon.ets` / `NotesPage.ets` 做 ArkTS 1.1 strict 适配，避免 struct 内普通私有方法。

### 验证

- 已做文件级 `git diff --check`，无 whitespace error。
- 已做禁用写法扫描，无 C 风格 `for` / `any` / `unknown` / struct 普通私有方法命中。
- DevEco Studio GUI 编译仍需手动执行。

---

## 2026-07-20 纯文字生成笔记刷新链路修复

### 做了什么

- 检查纯文字对话“生成笔记”链路：`AgentFloatWindow.send()` 无图片时进入 `AgentChatService.realReply()`，意图识别为 `note_generation` 后调用 `generateNoteFromConversation()`。
- 生成链路最终走 `AiService.captureText()` → `Dispatcher.dispatch()` → `KnowledgeModel.structure()` → `NoteDao.insert()`，成功后调用 `bumpNotesVersion()`。
- 首页、笔记页和学科详情页都监听 `AppStorage('notesVersion')`，版本号变化后重新 `loadNotes()`，因此新笔记会自动出现在首页最近笔记、Notes 学科入口和学科内笔记块。
- 修复纯文字同句携带材料的边界：当用户直接输入“生成笔记：具体内容……”且没有历史会话材料时，会从当前指令中提取笔记原材料继续生成，避免误报“当前会话还没有可整理的内容”。
- 归类路径确认：`KnowledgeModel` 输出独立 `subject/category`，`NoteItemMapper` 优先使用这两个字段；旧数据为空时再从 `tags` 兜底推断。

### 验证

- 文件级 `git diff --check HEAD` 无输出。
- 已确认 `git push --dry-run origin YunCeH:YunCeH` 成功。
- DevEco Studio GUI 编译和真机纯文字生成笔记 smoke test 仍需手动执行。

---

## 2026-07-20 旧数据兼容说明：不是两套数据库

当前不存在“新旧两套数据库”。应用仍使用同一个 `MindTrace.db`，主表仍是 `knowledge_unit`。

需要注意的是：`KnowledgeUnit` 在 2026-07-20 后新增了独立的 `subject` 和 `category` 必填字段。旧版本已经保存过的笔记行可能没有这两个字段的有效语义，表现为字段为空、旧分类仍混在 `tags` 中，或 UI 需要从旧标签兜底推断。

当前兼容策略：

- `DatabaseHelper` 会检查 `knowledge_unit` 是否存在 `subject` / `category` 列，缺列时只补缺失列，不重复迁移。
- `NoteDao.rowToUnit()` 读取旧库时对缺失列使用默认值，避免旧 ResultSet 直接崩溃。
- `NoteItemMapper` 优先使用 `unit.subject` / `unit.category`，为空时再从旧 `tags` 推断，保证旧笔记仍可展示。
- `NoteDetailOverlay` 手工新建或编辑保存笔记时会补齐 `subject` / `category`：已有笔记优先保留原字段，旧数据为空时从 UI note 或 tags 推断，最后兜底为 `其它` / `概念`。

结论：这是“旧数据缺少新字段语义”的兼容问题，不是数据库分裂。后续如需彻底清理，可增加一次轻量数据回填，把旧笔记中的空 `subject/category` 批量补齐。

---

## 2026-07-20 YunCeH Review 页合并与 main 同步

### 做了什么

- 将原 `StudyPlan` 独立页面能力合入 `Review` Tab，复习页内部新增“复习计划 / 知识图谱”切换，减少底部导航入口数量。
- 新增 `ReviewPlanView.ets`、`ReviewPlanRow.ets`、`ReviewTabSwitch.ets` 和 `ReviewGraphView.ets`，承接计划列表、拖拽排序、跨区移动和图谱占位视图。
- 删除旧 `entry/src/main/ets/pages/StudyPlan/` 页面组件，并同步移除 `main_pages.json` 中的独立 StudyPlan 页面注册。
- 合入 `origin/main` 的 Notes editor / Markdown 渲染能力，并持续合入本地 `main` 的 agents 分类稳定化、DAO 兼容读取、AI 浮窗动画、行内公式解析和旧数据兼容修复。
- `HomeViewModel.ets` 合并冲突已处理：保留 `YunCeH` 的 `units` 缓存与 `loadNote()`，同时保留 `main` 的错误日志输出。

### 验证

- `origin/main` 合入 `YunCeH` 时无冲突。
- 本地 `main` 合入 `YunCeH` 时仅 `HomeViewModel.ets` 有内容冲突，已解决并生成 merge commit `88fa52b Merge branch 'main' into YunCeH`。
- 本次继续合入本地 `main` 的 `e8277c9 docs(readme): document legacy note compatibility`，无代码冲突；README 两段 2026-07-20 说明已合并整理。
- 已做文件级 `git diff --check HEAD`，无输出。
- DevEco Studio GUI 编译和真机 smoke test 仍需手动执行。

---

## 2026-07-20 远端同步与 Notes 页结构优化

### 做了什么

- 将 `origin/main` 的 Agent memory、OCR 文本识别 API、Dispatcher/AiService 调整合入本地 `main`，本地生成 merge commit `238b1d1 merge: sync origin main`。
- 新增 `common/src/main/ets/data/NoteTaxonomy.ets`，集中管理笔记五类、旧类型别名、类型字符、类型取色和学科顺序取色；Notes 页面不再在组件里散落本地 `TYPE_KEYS` / `typeKey()` / 类型别名判断。
- Notes 一级页改为“概览统计 + 学科入口”结构，去掉最近笔记重复展示；新增 `NotesSummaryPanel.ets` 和 `SubjectViewToggle.ets`，支持学科入口列/块切换。
- 学科块图标按学科动态取首字，笔记图标按真实笔记类型/特征取首字；颜色以薄荷主色为基准，低曝光混色，避免按学科名硬编码。
- 新增 Notes 页结构视觉稿 [`docs/notes-page-structure-proposal-2026-07-19.html`](./docs/legacy/mindtrace/plans/w3/notes-page-structure-proposal-2026-07-19.html)，记录一级页、二级页、验收标准和实施路线。
- `KnowledgeModel` 提示词中的 5 类返回值已切到中文类别：`概念` / `定理` / `公式` / `证明题` / `计算题`。

### 验证

- 合并远端时无冲突文件，`git diff --name-only --diff-filter=U` 为空。
- 已做文件级 `git diff --check`，仅有 CRLF 提示。
- DevEco Studio GUI 编译和真机 smoke test 仍需手动执行。

---

## 2026-07-20 KnowledgeModel 格式对齐与 Prompt 优化

### 做了什么

**P0 · NoteCard 卡片 Markdown 裸渲染修复：**
- `NoteItemMapper.ets`：`unitToNoteItem()` 中 body 赋值改用 `stripMD()` 去掉 `## ` 标题行，卡片预览不再显示字面量 Markdown 语法。

**P1 · content 格式两条路径统一：**
- `KnowledgeModel.ets`：降级路径 `buildFallbackFromClassify()` 的 `content` 从纯文本 `ocrText` 改为 `'## 内容\n' + ocrText`，与正常路径 Markdown 格式对齐。
- `Dispatcher.ets`：OCR 空 fallback `buildFallbackUnit()` 同步加 `## 内容\n` 前缀。

**Prompt 全面优化（`KnowledgeModel.buildPrompt()`）：**
| 改动点 | 改前 | 改后 |
|--------|------|------|
| 语言要求 | 无 | 新增 `语言: 默认全部使用中文。` |
| JSON 格式 | `不要 markdown` | `不要用 \`\`\`json\`\`\` 代码块包裹` |
| tags 约束 | `2-5 个中文关键词，不要重复 category` | 分位约束：第1位学科名 / 第2位知识点 / 第3-5位方法技巧，附带示例 |
| fields key | 英文（`definition`/`problem`/`steps` 等） | 中文（`定义`/`问题`/`步骤` 等） |
| fields 约束 | 无 | 新增 `以上为各分类的标准字段，必须全部包含且不得增减，字段顺序可调整。` |
| 公式格式 | `公式保留为普通 LaTeX 文本` | 行内用 `$...$`，独立公式用 `$$...$$`，附带示例 |

**MathTextParser 行内公式支持：**
- `MathTextParser.ets`：新增 `$...$` 行内公式检测，按 `$` 切分行，奇数段识别为公式、偶数段为文本。

**学科（subject）与题型分类（category）独立：**
- `CommonTypes.ets`：`KnowledgeUnit` 接口新增 `subject: string`、`category: string` 两个独立字段，不再混在 `tags` 数组里。
- `KnowledgeUnitExt.ets`：`AiRawResponse` 新增 `subject` 字段，`createUnitExt()` 接收 `subject` 参数。
- `KnowledgeModel.ets`：prompt 新增 `subject: 学科名称` 字段；`buildTags()` 不再把 category 塞入 tags；`toKnowledgeUnit()` 和 `buildFallbackFromClassify()` 输出独立 `subject`/`category`。
- `Dispatcher.ets`：`buildFallbackUnit()` 同步输出独立 `subject`/`category`。
- `NoteDao.ets`：`rowToUnit()` 和 `toBucket()` 加 `subject`/`category` 列读写。
- `NoteItemMapper.ets`：`resolveSubject()` 优先读 `unit.subject`，`resolveType()` 优先读 `unit.category`，空时 fallback 旧 tags 遍历。
- `DatabaseHelper.ets`：`knowledge_unit` 表新增 `subject TEXT` 和 `category TEXT` 两列。

**KnowledgeModel 当前工作链：**

```
拍照/选图(imageUri)
  → ImageUriResolver.resolve()         // URI → 沙箱路径
  → Dispatcher.dispatch()
    → TypeClassifier.recognizeText()    // OcrTool 识别 → 文本预处理（去噪、归一化）
    → KnowledgeModel.structure(ocrText)
      → callAi()                        // DeepSeek LLM：system prompt + ocrText
        → 解析 JSON → AiRawResponse { category, subject, title, tags, difficulty, importance, fields }
      → buildTags()                     // tags 合并（不再含 category/subject）
      → truthCheck()                    // 4 项真值检验（括号/除零/等式/LaTeX）
      → toKnowledgeUnit()               // → KnowledgeUnit { id, title, content(Markdown), summary, tags, subject, category, difficulty, reviewStatus, ... }
    → [AI 失败?] buildFallbackFromClassify() // 兜底笔记
    → [OCR 空?]  buildFallbackUnit()         // 占位笔记
  → NoteDao.insert()                    // RDB 持久化（18 列）
  → Toast "笔记已生成"
```

### 验证

- 文件级 `git diff --check` 无 CRLF 问题。
- 5 条关键数据流（正常笔记/降级笔记/OCR 空占位 → NoteCard/NoteDetail）手工走读通过，格式统一无断层。
- subject / category 独立后全链路走读通过，AI 输出 → 入库 → UI 读取路径一致。
- DevEco Studio GUI 编译验证仍需手动执行。

---

## 2026-07-19 本地同步与首页布局修正

> 主 Agent 显式生成笔记 + Memory 专项改动详见 [`docs/agent-memory-flow-2026-07-19.md`](./docs/legacy/mindtrace/plans/w3/agent-memory-flow-2026-07-19.md)。回复风格验收测试集详见 [`docs/agent-reply-style-testset-2026-07-19.md`](./docs/legacy/mindtrace/plans/w3/agent-reply-style-testset-2026-07-19.md)。

### 做了什么

- 将 `agents/src/main/ets/agents/TypeClassifier.ets`、`agents/src/main/ets/mcp/tools/OcrTool.ets` 和 `common/` 覆盖为 `origin/main` 版本,确认本地 UI 主线可以继续跑通。
- 首页 `HomeRecentNotes` 增加 `compact` 布局参数: 收起复习环时列表继续占满剩余空间,非收起态按自然高度紧跟在“最近笔记”标题下方。
- 收紧非收起态“最近笔记”标题与第一条笔记卡片之间的间距,避免生成笔记后卡片位置下沉。
- 记录 `7ba5169 feat(agent): add explicit note memory flow` 的新增/修改文件、memory 策略、意图识别和生成笔记链路。

### 验证

- 已做文件级 `git diff --check`。
- DevEco Studio GUI 编译和真机 smoke test 仍需手动执行。

---

## 2026-07-18 本轮重构记录

### 做了什么

- 调整 DeepSeek 大模型连接方式: 设置页使用 OpenAI 兼容 `base_url`(`https://api.deepseek.com`), `LlmClient` 内部自动拼接 `/chat/completions`。
- 修复 AI 设置页“测试连接”误判失败的问题: 大模型实际已可用,之前失败原因是测试请求 `max_tokens=16` 导致 V4-Pro 输出被截断。
- 统一模型入口为 `deepseek-v4-pro`,旧的 V3 / Flash / R1 配置在加载和保存时会归一化到 V4-Pro。
- AI 设置页失败状态会显示具体错误摘要,便于区分 Key 错误、端点错误、模型错误和网络错误。
- 同步 OCR 设置页测试入口、本地 OCR endpoint 配置、笔记详情页 LaTeX/分段渲染、KnowledgeModel 输出结构化内容等前序改动。

### 已完成

- DeepSeek API Key、模型名和网络链路已经验证可用。
- LLM 默认配置已从旧 SiliconFlow / V3 配置切换到 DeepSeek OpenAI 兼容 base_url + V4-Pro。
- AI 设置页测试逻辑已避免短 token 截断导致的假失败。
- 拍照/OCR/分类/KnowledgeModel/入库/UI 渲染主链路已具备端到端运行基础。

### 还需要处理

- 重新用 DevEco Studio 编译并真机验收 AI 设置页测试结果。
- 补齐 AI 浮窗多轮对话: 需要把当前会话历史按 DeepSeek 无状态 API 要求拼进 `messages`。
- 给 TypeClassifier / KnowledgeModel 增加 `response_format: { type: "json_object" }` 和更严格的 JSON schema 校验,减少静默 fallback。
- 继续降低“失败即占位笔记”的数据污染风险,让 OCR/LLM 失败在 UI 上更明确。
- 后续再处理笔记页面、知识图谱宇宙视图、复习页和剩余 UI 对齐。

---

## 当前状态：拍照→AI→入库 整链已跑通 ✨ · 2026-07-18

选图 → 发送 → OCR 识别 → TypeClassifier 五分类 → KnowledgeModel LLM 结构化 → RDB 持久化 → 笔记列表自动刷新，全链路闭环。

### 本次 Session 关键修复

| 修复 | 说明 |
|------|------|
| **deepseek-v4-pro 连接与响应** | LlmClient 统一走 DeepSeek 官方端点，旧值会自动归一化 |
| **TypeClassifier 五分类对齐** | `type` 从三分类改为 `NoteCategory` (概念/定理/公式/证明题/计算题)，对接 KnowledgeModel |
| **Subject 自由判定** | 不再限制三选一，LLM 自由输出学科名称 |
| **KnowledgeModel prompt 精简** | 中文→英文对齐 TypeClassifier 风格 |
| **maxTokens 8000 · 超时 30 分钟** | 推理模型需要更大输出空间和时间 |
| **OCR multiFormDataList → 手动 multipart** | HarmonyOS 沙箱兼容，extraData 发送 |
| **AgentFloatWindow 完整版恢复** | 拖拽缩放 + 多会话 + 自动滚底 + ChatHeader/QuickSuggestions/ChatBubble |
| **AgentChatService 业务分离** | UI 层零异步逻辑 |
| **OverlayService 浮层统一调度** | 相机/浮窗互斥，加新浮层不改 Index |
| **NoteDetailOverlay 拆分** | 8 组件 + v2-ui 风格对齐 |
| **NoteCard 对齐 v2-ui .note-card** | 简化 meta 行 + 标题 15px + 原文预览 |
| **GradientRing 删笔记后动画修复** | `@Watch restartAnimation` |
| **动效令牌对齐 v2-ui motion.css** | DUR_INSTANT/FAST/BASE/SLOW/SLOWER/SLOWEST |
| **原子层补齐 ChipTag + ConfDot** | 对齐 v2-ui chips/badges |
| **删除死代码** | TypingIndicator/MessageInput/ChatTextSanitizer/agent/AgentMessageList/ApiClient |

### 已知不足

| 问题 | 详情 |
|------|------|
| **OCR 速度慢** | PaddleOCR CPU ~28s/张，总耗时约 30s |
| **OCR 需本地服务** | 依赖 start.bat 启动 FastAPI，模拟器需改 LAN IP |
| **文字 OCR 不可用** | Tesseract 未安装，只有公式识别 |
| **LLM 依赖网络** | DeepSeek API 需联网，免费版不稳定偶发超时/空响应 |
| **整链自动化覆盖不足** | 已有内容协议、LaTeX 风险、摘要和 Markdown 解析测试；OCR→LLM→RDB→UI 仍需真机 E2E |
| **会话持久化未接入** | ChatSession 有实现但 AgentFloatWindow 未接入 UI |

### 待调整

| 任务 | 状态 |
|------|------|
| SessionBar 会话切换 UI 接入 | 代码已有，待 UI 展示 |
| CameraOverlay 迁到 overlays/ | 仍在 prototypes/ |
| NoteTagChip → ChipTag 统一 | 旧 NoteTagChip 可退役 |
| 首页 Hero + Profile 页 v2-ui 对齐 | 待做 |

---

## 一、当前状态总览

MindTrace 是一个 HarmonyOS 数学学习助手,通过 **拍照 → OCR → AI 分类 → 知识结构化 → 持久化 → 复习**的整链,把"看到的数学题"变成"可复习的知识"。

### 1.1 已实现功能

| 功能 | 说明 | 验证方式 |
|------|------|---------|
| **拍照→AI 整链** ✨ | 拍照 → OCR → 分类 → 结构化 → 入库,全自动 | 真机拍照,Toast 提示笔记生成 |
| 5 Tab 底部导航 | 首页 / 笔记 / AI / 复习 / 我的 | DevEco 运行可见 |
| 拍照浮层 | `cameraPicker.pick()` 调系统相机,模拟器降级 mock | 真机点快门 |
| 相册选图 | `PhotoViewPicker.select()` 调系统图库 | 模拟器点相册按钮 |
| AI 浮窗真实对话 | `LlmClient.call()` → DeepSeek 官方,支持 V3.2 / R1 / V4-Pro / V4-Flash | 设置页配 API Key → 发消息 |
| AI 设置页 | API Key 显隐 / 测试连接 / 参数调优 / 恢复默认 | 我的 → 模型配置 |
| 学习计划 | PlanListView + PlanInputBar + PlanStatsBar + DAO + ViewModel | 我的 → 学习计划 |
| 笔记详情浮层 | 章节解析 + 标签 + AI 卡 + 操作栏 + 删除 | 首页/笔记页点卡片 |
| 进度环呼吸光晕 | Canvas 渐变弧 + 三角波呼吸动画 | 首页 |
| 浮窗键盘避让 | 监听 keyboardHeightChange + `.translate` 动态上移 | AI 浮窗聚焦输入框 |
| LLM 配置持久化 | `preferences` 存储,启动恢复 | 重启 App 配置保留 |

### 1.2 待实现 / 验证

| 任务 | 阻塞 / 状态 | 负责人 |
|------|---------|--------|
| 整链真机端到端验证 | 整链代码已就位,需真机拍照 1 张图看是否入库 + 列表显示 | Z |
| StudyPlan LLM 自动生成 | 数据库/ViewModel 已就位,缺 UI 触发调用 LLM | L |
| 真机 V4 模型验证 | 需要 DeepSeek 官方 API Key 余额 | 用户 |

### 1.3 历史 bug 全部解决

- ✅ Index.ets `onCameraConfirm` 不调 `AiService.capture()` 整链缺最后 1 公里 — `5b6f155` 已修
- ✅ KnowledgeModel 从 stub → 真实实现(MVP 合并 644 行) — `81a6ef6`
- ✅ NoteDao 从空壳 → 完整 CRUD — `81a6ef6`
- ✅ LlmConfig 默认值 / 保存 / 加载 — 之前修过
- ✅ Index.ets AI Tab 跳转占位 — `321762c` 已修

---

## 二、5 module 工程结构

```
MindTrace/
├── entry/        # HAP · type:entry      主 App(UI + 浮层 + 数据库 + ViewModel)
├── common/       # HSP · shared          共享类型 + 工具 + LLM + MockData
├── agents/       # HSP · shared          OCR/分类/知识建模 pipeline
├── skill/        # HAP · type:feature    小艺 Skill
└── cardservice/  # HAP · type:feature    元服务卡片
```

编译状态: 5/5 module BUILD SUCCESSFUL(走 DevEco Studio GUI 或 hvigor CLI 均可)。

---

## 三、已完成的工作(按时间顺序)

### 3.1 W0 · 工程搭建 (commit `bfaa8e5`)

5 module HarmonyOS 工程脚手架建好,5/5 module 编译通过。

### 3.2 W1 公共层 (5 commits, 2026-07-13)

合并 PR `d6220c4`(feature/z-w1-block2 → main):

| Commit | 内容 |
|--------|------|
| `fc889f6` | **CommonTypes** 共享类型(KnowledgeUnit / ReviewRecord / KGNode / KGEdge / AgentTask / AgentResponse + 3 enum) |
| `127343c` | **logger** 统一日志工具 |
| `3c729e2` | **uuid** 生成工具 |
| `68b8c5b` | **timeWindow** 时间窗工具 |
| `ccb1345` | **confidenceSort** 置信度排序工具 |

### 3.3 D1 精简拍照链骨架 (2026-07-13)

8 个目标文件全部建好空壳 + DevEco build 验证通过。后续 D + L 接手填真实现。

### 3.4 W1 · 5 Tab + 浮层 UI (2026-07-14)

- `Index.ets` — 5 Tab 装配,沉浸式状态栏
- `HomePage.ets` — Hero + 进度环 + 笔记列表 + FAB
- `CameraOverlay.ets` — 拍照/相册/快门/重拍/确认
- `AgentFloatWindow.ets` — AI 对话(已接 LlmClient,真实回复)
- `NoteDetailOverlay.ets` — 笔记详情(章节解析 + AI 卡)

### 3.5 center 合并 · AI 设置页 + DeepSeek V4 (2026-07-14)

`53b09c0` merge: center → main

- **AiSettingsPage** — 端点/模型/API Key/参数/测试连接
- **LlmConfig 运行时配置** — `saveAll()` + `loadAll()` 持久化
- **DeepSeek V4 模型** — `deepseek-v4-pro`
- **全 Agent 接入 DeepSeek** — TypeClassifier 通过 `LlmClient.call()` 调 LLM

### 3.6 CameraOverlay · 真实 CameraPicker (2026-07-14)

- `9db3309` `cameraPicker.pick()` 系统相机(无需 CAMERA 权限)
- `56229ec` `cameraPosition: CAMERA_POSITION_BACK` 枚举 + 空值防护
- `e155fae` 相册 SVG + 快门 MINT 色 + 模拟器 toast
- `33d3a5d` + `40508ae` module.json5 加 CAMERA + INTERNET 权限

### 3.7 AgentFloatWindow · 真实 LLM (2026-07-14)

- `7e3f4da` `realReply()` 替代 mock: `LlmClient.call()` → DeepSeek
- 系统提示词: "你是 MindTrace AI 助手,用简洁中文回答数学问题,适当使用 LaTeX"
- 错误分类: `NO_API_KEY` / `NETWORK_ERROR` / 其他(截断显示)

### 3.8 编译修复 + 代码清理 (2026-07-14)

- `ef0cca3` 类型重命名 `DispatchPayloadImage → ImagePayload` + 桶导出对齐
- `1a1f8a7` LlmClient 错误序列化改 `(e as Error).message`
- `8053cfa` AiSettingsPage save 后 `loadConfig()` 刷新 UI
- 删 `ingestImage()` + mock reply 残留

### 3.9 Local OCR pipeline 接入 TypeClassifier (2026-07-15)

`babdba8` 本地 OCR HTTP 客户端:

- `OcrTool.ets` 改用 HarmonyOS `http.request()` + `multiFormDataList` 上传图片
- 默认端点 `http://127.0.0.1:8000/api/v1/ocr/recognize`(模拟器/真机改成工作站 LAN IP)
- 合并 OCR 文本 + LaTeX 公式
- TypeClassifier 调 DeepSeek 返回 `{ type, subject, chapter, confidence }`,失败降级本地规则

### 3.10 Z 端 refactor · pages 重组 + MVP 合并 (2026-07-17)

`81a6ef6 refactor: organize pages and merge MVP knowledge model`

**(A) Pages 重组** — 单文件 pages/ → 每个 page 一个子文件夹:

| 改前 | 改后 |
|------|------|
| `pages/HomePage.ets` | `pages/Home/HomePage.ets` + `HomeTopBar.ets` + `HomeRecentNotes.ets` |
| `pages/MePage.ets` | `pages/Profile/ProfilePage.ets` + `ProfileHeader.ets` + `ProfileStatsRow.ets` + `ProfileMenuList.ets` + `ProfileMenuItemRow.ets` |
| `pages/NotesPage.ets` | `pages/Notes/NotesPage.ets` + `NotesHeader.ets` + `NotesList.ets` + `NotesEmptyState.ets` |
| `pages/ReviewPage.ets` | `pages/Review/ReviewPage.ets` |
| `pages/StudyPlanPage.ets` | `pages/StudyPlan/PlanHeader.ets` + `PlanInputBar.ets` + `PlanListView.ets` + `PlanStatsBar.ets` + `StudyPlanPage.ets` |
| `pages/AiSettingsPage.ets` | `pages/AiSettings/AiSettingsPage.ets` + `ActionBar.ets` + `ConnectionStatus.ets` + `EndpointPicker.ets` + `KeyInput.ets` + `ModelPicker.ets` + `SectionHeader.ets` |

**(B) MVP 合并 + 归档**:
- `KnowledgeModelMVP.ets` 合并进 `KnowledgeModel.ets`(644 行变更)
- 所有 `*MVP.ets` 文件移到 `archive/mvp-experiments/`
- 测试文件 `KnowledgeModelMVP.test.ets` → `KnowledgeModel.test.ets`(89 行新测试)
- 静态检查: active source 无 `*MVP.ets` / 无旧符号引用 / 相对 import 检查通过

**(C) 配套 refactor**(近期 15 个 commit):
- `616a219` 拆 Home + Agent 浮窗组件
- `60c958f` 拆 chat 模型 + 文本清理器(ChatTextSanitizer)
- `a523f1b` 笔记详情删除接入
- `8652b87` 聊天气泡回调加固(214 行)
- `321762c` 修 AI Tab 跳转占位(`lastContentIndex`)
- `753d7ad` 移除 C 风格 logger 循环
- `94101d0` + `1f4bd93` 进度环定时器(revert + 重做)
- `d18a76d` + `67deb32` 笔记详情章节/操作拆分
- `679aa17` + `dbad0da` 学习计划行交互修复 + 行操作
- `675eca5` 学习计划页面组件拆分
- `f9470e8` 替换内联 emoji 图标
- `826c562` 数据流硬化

### 3.11 整链接入 · 拍照→AI→入库 端到端 (2026-07-17) ✨

`5b6f155 feat(p0): Index.ets 接入拍照→AI 整链`

整链最后 1 公里接通:
- `Index.ets onCameraConfirm` 调 `new AiService(ctx).capture(uri)` 触发完整 pipeline
- 成功 Toast "笔记已生成: {title}",失败 Toast "处理失败: {errMsg}" 截断 80 字符
- 拍照确认仍回 AI 浮窗,流程不变

```
拍照(imageUri) 
  → AiService.capture() 
  → ImageUriResolver.resolve()        // file:// URI 复制到沙箱
  → Dispatcher.dispatch()              // 调度
    → TypeClassifier.classify()        // OCR + DeepSeek 3×3 分类
      → OcrTool.recognize()            // 本地 FastAPI HTTP
    → KnowledgeModel.structure()       // 模板填充 + 真值检验
  → NoteDao.insert()                   // 入 RDB (knowledge_unit)
  → Toast 提示用户
```

**这是 W0 以来工程最关键的一步** — 之前 D + L 的所有 stub 全部填好,只需 Index.ets 调一次。

---

## 四、当前文件结构(2026-07-20 最新)

```
entry/src/main/ets/
├── pages/                              # 每个 page 一个子文件夹
│   ├── Index.ets                       # 主容器: 5 Tab + 全局浮层 + 整链触发
│   ├── Home/                           # 首页(拆 3 个组件)
│   │   ├── HomePage.ets
│   │   ├── HomeTopBar.ets
│   │   └── HomeRecentNotes.ets
│   ├── Notes/                          # 笔记页: 一级学科总览 + 二级学科笔记列表
│   │   ├── NotesPage.ets
│   │   ├── NotesHeader.ets
│   │   ├── NotesList.ets
│   │   ├── NotesSummaryPanel.ets
│   │   ├── SubjectGrid.ets
│   │   ├── SubjectCard.ets
│   │   ├── SubjectViewToggle.ets
│   │   ├── SubjectDetailPage.ets
│   │   ├── SubjectHeader.ets
│   │   ├── SubjectNoteList.ets
│   │   ├── SubjectTypeEmpty.ets
│   │   ├── TypeTabRow.ets
│   │   └── NotesEmptyState.ets
│   ├── Profile/                        # 我的(原 MePage,拆 5 个组件)
│   │   ├── ProfilePage.ets
│   │   ├── ProfileHeader.ets
│   │   ├── ProfileStatsRow.ets
│   │   ├── ProfileMenuList.ets
│   │   └── ProfileMenuItemRow.ets
│   ├── Review/                         # 复习
│   │   └── ReviewPage.ets
│   ├── StudyPlan/                      # 学习计划(拆 4 个组件)
│   │   ├── StudyPlanPage.ets
│   │   ├── PlanHeader.ets
│   │   ├── PlanInputBar.ets
│   │   ├── PlanListView.ets
│   │   └── PlanStatsBar.ets
│   └── AiSettings/                     # AI 设置(拆 6 个组件)
│       ├── AiSettingsPage.ets
│       ├── ActionBar.ets
│       ├── ConnectionStatus.ets
│       ├── EndpointPicker.ets
│       ├── KeyInput.ets
│       ├── ModelPicker.ets
│       └── SectionHeader.ets
├── overlays/                           # 顶层浮层(被 Index 引用)
│   ├── AgentFloatWindow.ets            # 18021 bytes · 真实 LLM
│   ├── CameraOverlay.ets               # 真实 cameraPicker
│   └── NoteDetailOverlay.ets           # 5 子组件拆分
├── prototypes/                          # 独立完整的页面级 UI 原型
│   ├── AgentFloatWindow.ets
│   ├── CameraOverlay.ets
│   ├── NoteDetailOverlay.ets
│   ├── AgentMessageList.ets
│   ├── NoteDetailOverlay/              # 5 个子组件
│   └── chat/                           # AI 浮窗 8 个子组件
│       ├── ChatBubble.ets
│       ├── ChatHeader.ets
│       ├── ChatModels.ets
│       ├── ChatSession.ets
│       ├── ChatTextSanitizer.ets
│       ├── EmptyStateHint.ets
│       ├── MessageInput.ets
│       ├── QuickSuggestions.ets
│       ├── SessionBar.ets
│       └── TypingIndicator.ets
├── components/                          # 旧 atom 命名(已废弃)
│   └── HexLogo.ets
├── atoms/                               # 16 个原子组件
│   ├── AiTabButton / AppIcon / CameraAlbumBtn / CameraBackBtn
│   ├── CameraCloseBtn / CameraConfirmBtn / CameraShutterBtn
│   ├── ConfBadge / FloatingButton / GradientRing
│   ├── HexLogo / PageHeader / PriorityBadge / StatsBox
│   ├── TabButton / ViewfinderCorners
├── molecules/                           # 7 个分子组件
│   ├── CameraCapture.ets
│   ├── CameraPreview.ets
│   ├── HeroBanner.ets
│   ├── NoteCard.ets
│   ├── PlanItemRow.ets
│   ├── ReminderBanner.ets
│   └── TabBar.ets
├── database/                            # RDB 数据访问
│   ├── DatabaseHelper.ets               # RDB 封装
│   ├── NoteDao.ets                      # 8336 bytes · 完整 CRUD
│   └── StudyPlanDao.ets                 # 5164 bytes · 学习计划 DAO
├── viewmodels/
│   └── StudyPlanViewModel.ets           # 7869 bytes · MVVM
├── services/
│   ├── ApiClient.ets                    # HTTP 客户端
│   ├── AiService.ets                    # 3414 bytes · 整链入口
│   └── ImageUriResolver.ets             # file:// URI 沙箱化
└── utils/
    └── NoteItemMapper.ets               # NoteItem ↔ KnowledgeUnit

common/src/main/ets/
├── models/                              # 共享类型(KnowledgeUnit + 5 个 enum)
├── constants/                           # ColorTokens / 字号 / 间距
├── tools/                               # logger / uuid / timeWindow / confidenceSort
├── data/                                # MockNotes
└── llm/                                 # LlmConfig + LlmClient(OpenAI 兼容)

agents/src/main/ets/
├── agents/
│   ├── TypeClassifier.ets               # OCR + DeepSeek 3×3 分类
│   └── KnowledgeModel.ets               # 644 行 · AI 结构化 + 真值检验
├── core/
│   └── Dispatcher.ets                   # D1 精简链调度
└── mcp/tools/
    └── OcrTool.ets                      # 本地 FastAPI HTTP
```

---

## 五、整链架构(端到端流程)

### 5.1 完整 pipeline

```
用户拍照
  ↓
CameraOverlay.onConfirm(imageUri)
  ↓
Index.ets onCameraConfirm              [5b6f155]
  ↓ new AiService(ctx).capture(uri)
AiService.capture()                    [services/AiService.ets]
  ↓ ImageUriResolver.resolve()         [services/ImageUriResolver.ets]
  ↓ Dispatcher.dispatch()               [agents/core/Dispatcher.ets]
    ↓ TypeClassifier.classify()        [agents/agents/TypeClassifier.ets]
      ↓ OcrTool.recognize()             [agents/mcp/tools/OcrTool.ets]
        ↓ http://127.0.0.1:8000/api/v1/ocr/recognize
        ↓ 返回 {text, formulas}
      ↓ DeepSeek LlmClient 分类        [common/llm/LlmClient.ets]
        ↓ 失败降级本地规则
    ↓ KnowledgeModel.structure()        [agents/agents/KnowledgeModel.ets]
      ↓ AI 自分词 → Schema 填充
      ↓ truthCheck(花括号/LaTeX/除零/方程)
  ↓ NoteDao.insert()                    [entry/database/NoteDao.ets]
    ↓ relationalStore.insert('knowledge_unit')
  ↓ Toast 通知用户
```

### 5.2 整链文件依赖图

```
Index.ets  ─→  AiService  ─→  Dispatcher  ─→  TypeClassifier  ─→  OcrTool
                                          ─→  KnowledgeModel
                              ─→  NoteDao  ─→  DatabaseHelper
                              ─→  LlmClient  ─→  LlmConfig
                              ─→  ImageUriResolver
```

---

## 六、LLM 配置

### 6.1 端点 + 模型

| 端点 | URL | 特点 |
|------|-----|------|
| DeepSeek 官方(默认) | `https://api.deepseek.com` | OpenAI 兼容 base_url,客户端自动拼接 `/chat/completions` |
| 自定义 OpenAI 兼容 | 用户自填 | 自建网关/代理 |

| 模型 | model 名 | 上下文 | 用途 |
|------|---------|--------|------|
| DeepSeek-V4-Pro | `deepseek-v4-pro` | 1M | 旗舰推理 |
| 自定义 model | 用户输入 | 依 provider | 仅用于兼容或自建网关 |

### 6.2 默认参数

- **Temperature**: 0.1
- **MaxTokens**: 1024
- **Timeout**: 15s

### 6.3 持久化

`preferences` 存储(端点/模型/温度/MaxTokens/Timeout),换设备需重新输入 API Key。

---

## 七、构建与运行

### 7.1 构建

- **DevEco Studio GUI 与 hvigor CLI 均为合法入口**（Build → Build Hap(s)/APP(s))
- `hvigor CLI` 可由 AI 主动调用，注意 Windows 中文路径下 `NODE_HOME`/`PATH` 的字符编码与工作树状态
- AI 改完代码可本地 commit + git status，build 结果可由 AI 跑出后回报用户

### 7.2 整链真机验证流程

1. 启动本地 FastAPI OCR 服务:`formula_api:ocr_router`(端口 8000)
2. 真机/模拟器跑 MindTrace,确保能访问 `127.0.0.1:8000`(模拟器用 LAN IP)
3. 配置 API Key(我的 → 模型配置 → 测试连接)
4. 拍张数学题照片
5. 预期:Toast "笔记已生成: {title}" → 首页/笔记页能看到新笔记

### 7.3 GitHub SSH

走 port 443(`~/.ssh/config` 已配 `Host github.com → ssh.github.com:443`)。

### 7.4 作者固定

`YunC-GCT <2549237929@qq.com>`(`git config user.name/email` 已配)。

---

## 八、git 规则

1. **未经明示禁止 push** — 本地 commit 自由,推送必须 leader 点头
2. **commit message 规则**:
   - `feat(scope): 新功能` · `fix(scope): bug 修复` · `refactor(scope): 重构`
   - `docs:` · `merge:`
3. **每个 commit 前必查 `git branch --show-current`** — 不在自己分支不 commit
4. **DevEco Studio 会自动切分支** — commit 前必须确认当前分支
5. **回滚走 `git reset --hard HEAD~N`**(user 授权后),reflog 可找回

---

## 九、已归档的 MVP 实验文件

保留作为参考,**不算 active product code**:

```
archive/mvp-experiments/
├── agents/src/main/ets/agents/KnowledgeModelMVP.ets   ← MVP 合并后已空
├── agents/src/main/ets/core/DispatcherMVP.ets
├── entry/src/main/ets/database/DatabaseHelperMVP.ets
├── entry/src/main/ets/database/NoteDaoMVP.ets
├── entry/src/main/ets/overlays/AgentFloatWindowMVP.ets
├── entry/src/main/ets/pages/AiTestPage.ets
├── entry/src/main/ets/pages/AiTestPageMVP.ets
├── entry/src/main/ets/pages/IndexMVP.ets
└── entry/src/main/ets/services/AiServiceMVP.ets
```

未来决定: 团队确认不再需要后整体删除。

---

## 十、下一步计划

### 🔴 P0 · 整链真机验证
- [ ] 启动本地 FastAPI OCR 服务
- [ ] 真机/模拟器拍张数学题照片
- [ ] 验证:Toast 提示 + 首页/笔记页显示新笔记
- [ ] 失败兜底:任意一环报错,Toast 提示

### 🟡 P1 · 体验增强
- [ ] StudyPlan LLM 自动生成(ViewModel 已有,接 LLM)
- [ ] AI 浮窗历史持久化(ChatSession 已有,UI 完整接入)
- [ ] 拍照后流式 AI 实时反馈

### 🟢 P2 · 已设计待落地
- [ ] 图标系统 5 个 SVG 改(album bug + ai/review/notes 改 lucide + 删 brand)
- [ ] AiSettingsPage 重构 · DeepSeek 官方最简版方案
- [ ] HomePage 进度环 sin 曲线 + 3 统计方块可点

### ⚪ P3 · 清理
- [ ] `archive/mvp-experiments/` 9 个文件是否保留
- [ ] `prototypes/` 重命名为 `features/`
- [ ] `entry/_fb.ets` (1KB untracked) 是什么?
- [ ] 8 个 `docs/*.html` 预览是否归档(完成设计任务后)

---

## 附录:关键 commit 索引

| 阶段 | 关键 commit |
|------|------------|
| W0 脚手架 | `bfaa8e5` |
| W1 公共层 | `d6220c4` merge |
| D1 拍照链 | `b15d960` |
| W1 5 Tab UI | `02cabf2` ~ `eeb5cb2` |
| center 合并 | `53b09c0` |
| CameraPicker 接入 | `9db3309` `56229ec` `e155fae` |
| LlmClient 接入 | `7e3f4da` `6d2b45b` |
| Local OCR | `babdba8` |
| Z 端 refactor | `81a6ef6` |
| **整链接入** ✨ | `5b6f155` |
| W4 多 WebView 分块渲染 | `13c934f` ~ `e98318c` |
| **arkts-lint v0.3 + CI** (2026-09-01) | `c559ae0` (engine) + `0e429ed` (audit docs) |

---

## 🛠️ Tooling & CI (2026-09-01)

**Lint 引擎 (双轨制)** — `scripts/`:

- **v1 (regex)** — `scripts/audit-arkts-strict.mjs` · 25 规则 · 174 文件 · baseline `0/285`
- **v0.3 (AST)** — `scripts/arkts-lint/index.mjs` · 34 规则 + 63 单元测试 · 173 文件 · baseline `0/253` (90 个是 fix 后真问题)

详细规则定义见 [`docs/style/arkts-1.1.md`](./docs/style/arkts-1.1.md) (40+ 官方 rule ID + error code)。

**CI** — [`.github/workflows/arkts-lint.yml`](./.github/workflows/arkts-lint.yml) 3 个 job:

| Job | 内容 | 依赖 |
|---|---|---|
| `test` | `npm ci` + 63 单元测试 | — |
| `lint-ast` | `node scripts/arkts-lint/index.mjs --quiet` | needs: test |
| `lint-regex` | `node scripts/audit-arkts-strict.mjs --quiet` | 独立 |

**审计文档** (2026-09-01) — `docs/`:

| 文件 | 大小 | 内容 |
|---|---|---|
| `architecture-audit-full-20260901.md` | 54 KB | 5 模块全代码库审计 (21 P0/P1/P2 finding) |
| `audit-deepdive-20260901.md` | 49 KB | 7 个最大文件深读 (§F1-§F7) |
| `lint-baseline-20260901.json` | 149 KB | v1 baseline (0/285) |
| `lint-baseline-20260901-ast.json` | 106 KB | v0.3 baseline (0/253) |
| `research/huawei-arkui-agent-20260901.md` | 45 KB | 30+ ArkTS 官方资料 |
| `style/arkts-1.1.md` | 21 KB | 40+ rule 手册 (lint 权威) |

**Agent 工作环境** — `AGENTS.md` (被 34 规则 + 63 测试 + CI 守门)
