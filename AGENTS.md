# MindTrace — AGENTS.md

> **HarmonyOS 数学学习助手** — 拍照 / OCR / AI 分类 / 知识结构化 / 持久化 / 复习 全链应用
> 5 module 工程 (`entry` HAP + `common` / `agents` / `skill` / `cardservice` 4 HSP)
> 主分支: `main` · 最新大版本: **W4 (2026-07-24 起)** · 最后审计: 2026-09-01

---

## 项目定位

MindTrace 是一个 HarmonyOS 数学学习助手,核心能力:

1. **拍照/选图** → 相机/相册取图
2. **OCR** → 本地 FastAPI HTTP 服务识别数学公式/题目
3. **AI 分类** → 题型识别 (概念/定理/公式/证明题/计算题, 5 类)
4. **知识结构化** → `KnowledgeModel` 拆分知识点/章节/标签/掌握度
5. **持久化** → RDB `knowledge_unit` 表
6. **复习** → 间隔重复 (NEW/LEARNING/REVIEW/GRADUATED/LAPSED 状态机)

最近更新详见 [README.md](./README.md) + [`docs/architecture-audit-full-20260901.md`](./docs/architecture-audit-full-20260901.md) (架构审计)。

---

## Setup commands (DevEco Studio)

**严禁用 hvigorw CLI** (Windows 中文路径下 NODE_HOME/PATH 乱码,已实测)。唯一推荐 DevEco GUI:

- **Open**: `File` → `Open` → 选 **`D:\HMgent\MathMind`** 根目录 (注意:不是 `MindTrace`)
- **Build**: `Build` → `Build Hap(s)/APP(s)`
- **Run**: `Run` → `Run 'entry'`
- **Sync**: `File` → `Sync and Refresh Project`
- **签名**: 根 `build-profile.json5` 必须显式共享 `signingConfig` 给所有 HAP

---

## Architecture (deep module 设计)

4 层架构,目标是把 UI / 业务服务 / AI 智能体 / 数据 各层之间的 seam 显式化:

| Layer | 主要位置 | 责任 |
|---|---|---|
| UI | `entry/pages/`, `entry/overlays/` | 渲染 + 用户输入 |
| View Model | `entry/viewmodels/` | UI state + 用户意图 |
| Business Service | `entry/services/` | 业务编排, **不持有 UI 引用** |
| AI Agent | `agents/` | Dispatcher + 子 Agent (TypeClassifier / KnowledgeModel) |
| Data + Infra | `common/` | 类型 + LLM/Render/OCR 单例 + DB |

**关键 seams** (跨模块契约):
- `entry/services/AiService.capture` → `agents/Dispatcher.dispatch`
- `agents/KnowledgeModel.structure` → `common/LlmGuard` → `common/LlmClient.call`
- `common/ContentProtocol` ← 全部 Markdown 处理走规约校验

深度设计 (deep module / seam / adapter / depth) 见 [`docs/architecture-audit-full-20260901.md`](./docs/architecture-audit-full-20260901.md) §5 与 `docs/audit-deepdive-20260901.md` §F1-§F7。架构决策 (ADR) 计划在 [`docs/adr/`](./docs/) (Phase 2 创建)。

---

## Project layout (实际结构)

```
MindTrace/
├── entry/                       # HAP — 主应用 (UI + 业务 + 拍照 + DB)
│   └── src/main/ets/
│       ├── pages/               # 5 Tab (Home/Notes/AI/Review/Profile) + 子页面
│       ├── overlays/            # CameraOverlay / AgentFloatWindow / NoteDetailOverlay
│       ├── shared/              # 渲染器 (MathTextRenderer / MarkdownRenderer / FormulaSplitRenderer)
│       ├── services/            # AiService / AgentChatService / AgentMemoryService / ImageUriResolver / OverlayService / UiDataCacheService
│       ├── viewmodels/          # @Observed 视图模型 (KnowledgeGalaxyViewModel / StudyPlanViewModel / ...)
│       ├── database/            # DAO (NoteDao / StudyPlanDao / ChatMessageDao / AgentMemoryDao)
│       ├── models/              # entry 层 model
│       ├── entryability/        # EntryAbility
│       ├── entrybackupability/  # 数据备份/恢复 Ability
│       └── utils/               # NoteItemMapper / MarkdownParser / ...
├── common/                      # HSP — 共享类型 + LLM + 渲染协议
│   └── src/main/ets/
│       ├── llm/                 # LlmConfig / LlmClient / LlmGuard / LlmOutputRules / LlmTypes
│       ├── render/              # ContentProtocol (MM-MD-v1) / ContentExcerptBuilder
│       ├── ocr/                 # OcrConfig (端点单例)
│       ├── data/                # MockNotes / NoteTaxonomy (UI 开发期)
│       ├── models/              # KnowledgeUnit / StudyPlanItem / CaptureChain / CommonTypes
│       ├── constants/           # ColorTokens (主题色)
│       ├── utils/               # logger / uuid / FileUriUtils / LatexRiskNormalizer
│       └── DatabaseHelper.ets   # RDB 单例 (顶层文件, 不在子目录)
├── agents/                      # HSP — AI 业务
│   └── src/main/ets/
│       ├── core/                # Dispatcher.ets (主 Agent 调度中枢)
│       ├── agents/              # TypeClassifier.ets / KnowledgeModel.ets
│       ├── mcp/tools/           # OcrTool.ets (HTTP OCR, **非真 MCP**, 见 audit §4.8)
│       └── models/              # KnowledgeCategory / KnowledgeUnitExt / NoteDaoInterface / TruthCheckResult
├── skill/                       # HSP — 技能卡片 (FeatureAbility, 14 LOC)
├── cardservice/                 # HSP — 卡片服务 (FormExtensionAbility, 58 LOC)
├── AppScope/                    # 应用元数据 + 资源
├── docs/                        # 设计 + 跨 session 通信 + 总结
│   ├── architecture-audit-*     # 架构审计报告 (HTML 不入 git)
│   ├── audit-deepdive-*         # 最大文件深读
│   ├── research/                # 外部调研笔记
│   └── agents/                  # 工作流规约 (issue tracker / domain / triage labels)
├── build/                       # 构建输出 (git ignored)
├── hvigor/                      # hvigor 缓存 (git ignored)
└── oh_modules/                  # 依赖 (git ignored)
```

**已废弃的旧描述** (之前文档里有,实际不存在,不要新建):
- ~~`components/`~~ ~~`atoms/`~~ ~~`archive/`~~ ~~`MindTrace-MVP/`~~ — 不存在
- ~~`common/src/main/ets/database/`~~ — DatabaseHelper 在顶层
- ~~`docs/W3_SUMMARY.md`~~ — 不存在 (旧 README 引用,见 audit §2.3)
- ~~`docs/ui_to_agent_*.md` / `agent_to_ui_*.md`~~ — 命名规约存在但**没有实际使用过** (Phase 2/3 决定保留或废弃)

---

## Code style — ArkTS 1.1 strict

> **重要更正**: 之前 AGENTS.md 写的 "禁 C 风格 `for`" 是错的。官方 ArkTS 1.1 strict 实际**只禁 `for..in`** (rule `arkts-no-for-in`, error 10605080),C-style `for (let i; i<n; i++)` **官方允许**。本节按官方规则重写。

### 强制规则 (官方 strict-mode)

按性质分组。**完整 40+ 规则表 (含 rule ID + error code + 代码示例 + 验证命令)** 见 [`docs/style/arkts-1.1.md`](./docs/style/arkts-1.1.md) (2026-09-01 从子代理调研笔记 §3.2 抽出,可被任意 agent / lint job 直接加载)。

**类型系统** (核心):
- `any` / `unknown` 禁 — `arkts-no-any-unknown` (10605008); 兜底用 `(e as Error).message ?? String(e)`
- 结构类型 / mapped / conditional / intersection 禁 — `arkts-no-structural-typing`(30) / `no-mapped-types`(83) / `no-conditional-types`(22) / `no-intersection-types`(19)
- 类型断言**只允许 `as`** — `arkts-as-casts` (10605053); `<T>x` 禁
- catch 不能 typed — `arkts-no-types-in-catch` (10605079)

**控制流**:
- **`for..in` 禁** — `arkts-no-for-in` (10605080); 用 `for...of` 或 `forEach`
- 解构赋值 / 声明 / 参数 禁 — `arkts-no-destruct-assignment`(69) / `no-destruct-decls`(74) / `no-destruct-params`(91); 用临时变量
- `var` / `#private` / `function` 表达式 / `with` / `delete` / `class` 表达式 / 嵌套函数 / generator 禁

**对象与类**:
- `obj['key']` 动态属性访问 禁 — `arkts-no-props-by-index` (10605029); 用 `Map` 或预定义字段
- 类只能 `implements interface`, 不能 `implements class` — `arkts-implements-only-iface` (10605051)
- `this` 类型禁 — `arkts-no-typing-with-this` (10605021); 用 `instanceof` + `as`

**ArkUI 项目级约束** (项目偏好**严格于**官方):
- struct 内**禁普通方法** — 全部用箭头函数字段 / `@Builder` / `@Watch`
- struct 内**禁 `get` accessor** — 用 `@State` + `aboutToAppear`
- struct 字段名**避开 CommonAttribute 方法名** (`rotate` / `translate` / `scale` / `opacity` / `backgroundColor` / `focusable` 等) → 用 `rotDeg` / `transY` / `scaleVal` / `opVal` / `bgCol` 等

### 项目偏好 (软约定)

- **`for...of` / `forEach` / `while` 优于 C-style `for`** (官方允许,项目偏好可读性)
- `.translate()` 优于 `.offset()` 用于响应式动画 (两者都响应 `@State`,但 `.translate()` 参与 transformation chain)
- 多文件改业务逻辑时,先读 `CONTEXT.md` 和 `docs/adr/` (Phase 2 创建后) 确认术语和决策

### API 版本注意

- 当前 `compileSdkVersion` / `compatibleSdkVersion` = **9** (ArkUI 1.1)
- ⚠️ **API 9 下 ArkTS strict 规则只警告不报错** — 升级到 ≥10 才进入"标准模式"
- 升级前: **lint job 已强制** ([`scripts/audit-arkts-strict.mjs`](./scripts/audit-arkts-strict.mjs) v1 + [`scripts/arkts-lint/`](./scripts/arkts-lint/) v0.3, AST 版; 共 34 条规则 + 63 单元测试; **CI 已接入** [`.github/workflows/arkts-lint.yml`](./.github/workflows/arkts-lint.yml))
- **API 11+ 才有的特性** (当前**不能用**):
  - `.stateStyles()` 基础态 API 7 ✓; 但 `selected` 子态 API 10+ ⚠️
  - `.blur()` / `visualEffect` / `backgroundFilter` API 12+ ⚠️
  - `@kit.ArkTS.JSON` 模块 API 12+ ⚠️ (当前用 built-in `JSON`)
  - `@ComponentV2` / `@Local` / `@Param` / `@ObservedV2` / `@Trace` V2 装饰器 API 12+ ⚠️
- `Image.rotate({ angle })` 接**对象** (`{angle: number}`),不是 number

### 文件头注释模板 (W3 后新规, ≥ 80 文件已统一)

```ts
/**
 * {FileName}.ets — {职责一句话}
 *
 * 路径: {相对 entry/src/main/ets/ 的路径}
 * 职责: {具体业务职责}
 * 依赖: {依赖模块/kit}
 *
 * 数据流:
 *   {上游} → {本文件关键函数} → {下游}
 *
 * {其他设计要点}
 *
 * ArkTS 1.1 strict 适配:
 *   - {踩坑点 + 修复}
 */
```

新文件**必须**用这个模板 (见 audit §4.13,Phase 4 ticket #6 统一剩余文件)。

---

## Testing instructions

- **静态编译**: DevEco Studio → `Build` → `Build Hap(s)/APP(s)`
- **真机调试**: `Run` → `Run 'entry'` (需要 HarmonyOS 真机或远程模拟器)
- **单元测试**: `entry/build-profile.json5` 配了 `ohosTest` target,当前覆盖极少 (`agents/src/test/` 仅 2 文件)
  - **计划**: Phase 4 ticket #13 加 12 个最小测试 (StructureService / TruthCheckService / PromptBuilder)
- **E2E 验证**: 拍照→AI 整链需要 FastAPI OCR 服务 (`OcrTool.recognize()` 调本地 HTTP)

### 手动 smoke test (提交前必走)

1. 5 Tab 切换流畅
2. 首页 Hero 卡片渲染
3. 进度环呼吸光晕
4. AI 浮窗开/关 + 输入对话
5. **W4 SSE 流式回复** 验证 (`AgentChatService.realReplyStream`) — **W4 新增,务必测**
6. 笔记详情浮层打开/关闭
7. 复习 Tab 跳 StudyPlan
8. 知识星系 (KnowledgeGalaxy) — 验证用户没看到 "示例:*" 假学科 (audit §4.20 + ticket #16)

---

## PR & commit conventions

- **主分支**: `main` (基线 `5b6f155` 之后 171 commits,最新 HEAD `29df511`)
- **分支模型**: 当前单 `main`, 无 feature 分支 (`.worktrees/` 偶尔用)
- **Commit 风格**: conventional commits
  - `feat(p0):` / `feat(w4):` — 新功能
  - `fix(agents):` / `fix(build):` — 修复
  - `docs(entry):` / `docs:` — 文档/注释
  - `refactor:` / `style:` / `test:` / `chore:`
- **每 commit 前必查**:
  - `git branch --show-current` (DevEco 可能自动切分支)
  - `git status` (working tree 状态)
- **本地 commit, 绝不 push 除非 user 明确说"push"**
- **回滚**: `git reset --hard HEAD~n` 需 user 明确授权 (reflog 可找回)

---

## 跨 session 通信协议

文件协议 + user 中转 (`mavis communication send` CLI 不可用):

| 方向 | 文件命名 | 路径 |
|---|---|---|
| UI session → 主 agent | `docs/ui_to_agent_<topic>_<date>.md` | 当前 worktree 的 `docs/` |
| 主 agent → UI session | `docs/agent_to_ui_<topic>_<date>.md` | UI session worktree 的 `docs/` |

**关键约束**:
- 单 worktree 多 session: 同 `.git/`, **working tree 互斥** (一个 session 改时另一个别动)
- 多 worktree: 各自 working tree 独立, 但共享 HEAD, 需注意分支同步
- 通过 user 转告, 不直接推给对方

**注意**: 规约存在但目前**没有实际使用过** (`docs/` 下没找到该模式文件) — Phase 2/3 决定保留或废弃。

---

## Security

- **绝不 commit secrets**: `.env` / `local.properties` 已在 `.gitignore`
- **API Key**: 用户在 App 内 "我的 → AI 模型配置" 设置, 持久化到 preferences, **不入 git**
- **OCR 服务地址**: 默认 `localhost`, 部署到真机时改 IP
- **网络权限**: 已声明 `ohos.permission.INTERNET`
- **签名**: 根 `build-profile.json5` 的 `signingConfigs` 必须显式共享给所有 HAP, 否则不同 HAP 签名不一致
- ⚠️ **新增**: `LlmConfig.normalizeModel` / `normalizeEndpoint` 静默覆盖用户配置 (含 `siliconflow` / `v3` / `flash` / `r1` 等关键词) — **禁止再扩展**, 应改成抛 `LlmError` (Phase 4 ticket #9)

---

## 必读 rules (项目级硬约束)

下面这些是工程踩过的真实坑, 新 session 接 MindTrace **必须先看**:

1. **HSP `oh-package.json5` 必备 `main` 字段**: 缺了 build 报 `Cannot find module 'xxx'`
   - 模板: `{"name": "xxx", "main": "./src/main/ets/Index.ets", ...}`
2. **`.ets` 文件 UTF-8 noBOM**: UTF-16 LE BOM 让 hvigorw 报 "18 字节错位" 伪错
   - 改文件用 Read/Write/Edit 工具, 避免任何 shell 管道编码陷阱
3. **每个 module 都需自己的 `build-profile.json5` + `hvigorfile.ts`**: 根的不够
4. **HSP `module.json5` 字段约束**: 禁 `pages`/`abilities`/`mainElement`/`extensionAbilities`/`skills`, 可写 `name`/`type`/`description`/`deviceTypes`/`deliveryWithInstall`/`installationFree`
5. **HSP 跨 module import 必须完整路径**: `from 'common/src/main/ets/Index'` 不能 `from 'common/Index'`
6. **一个鸿蒙应用只能有一个 `type:entry` 模块**: 其他 HAP 用 `type:feature` (`entry`/`skill`/`cardservice`)
7. **obfuscation-rules.txt 必须存在**: 即使 `enable:false` 也要有文件
8. **新 .ets 文件必须用 Write 工具创建**: 避免 PowerShell 5.1/7 的中文编码陷阱;Edit 改文件 OK
9. **agent/mcp 目录是命名误导**: `agents/src/main/ets/mcp/tools/OcrTool.ets` 不是真 MCP 集成, 项目未运行 MCP server (audit §4.8) — 改名决策见 [`docs/adr/0005-mcp-to-tools-rename.md`](./docs/adr/0005-mcp-to-tools-rename.md)

**完整规则**: ArkTS 1.1 strict 40+ 条已在本节 "Code style" 列出, **完整手册已抽出到 [`docs/style/arkts-1.1.md`](./docs/style/arkts-1.1.md)** (可被其他 agent / 新 session 直接加载)。**Lint job 已接入 CI** — 两套 ([`.github/workflows/arkts-lint.yml`](./.github/workflows/arkts-lint.yml)):
- v1 (regex): [`scripts/audit-arkts-strict.mjs`](./scripts/audit-arkts-strict.mjs), 25 条规则, baseline: 0 errors / 285 warnings
- v0.3 AST (推荐): [`scripts/arkts-lint/`](./scripts/arkts-lint/), **34 条规则** + **63 单元测试**, baseline: 0 errors / **253 warnings** (90 个是 fix 后的真问题,对应 audit §4.9/§4.10 god-class)

---

## 维护提示

- **新 module 创建**: 必须 `cp common/oh-package.json5 <new>/oh-package.json5` 当模板 (有 main 字段)
- **新 .ets 文件**: 复制上面 "文件头注释模板" 写头注释
- **新 .ets 改完**: PowerShell 验首 3 字节 `69 6D 70` (= "imp" = "import" 无 BOM)
- **跨 session 通信**: 用上面 "跨 session 通信协议" 表格
- **Working tree 互斥**: 跟其他 session 在同一 worktree 时, 只能 read, 别动 write

---

## Agent skills

### Domain docs

单 context 布局 — 仓库根 [`CONTEXT.md`](./CONTEXT.md) (项目专属词汇表) + [`docs/adr/`](./docs/adr/) (架构决策记录,6 个)。**写代码前先读 CONTEXT.md**;**改动设计前先查 docs/adr/**。详见 [`docs/agents/domain.md`](./docs/agents/domain.md) (workflow 规约)。

### Issue tracker

GitHub Issues on `YunC-GCT/Math-Mind`, via `gh` CLI. 详见 [`docs/agents/issue-tracker.md`](./docs/agents/issue-tracker.md)。

### Triage labels

5 个标准标签: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. 详见 [`docs/agents/triage-labels.md`](./docs/agents/triage-labels.md)。

### Code review / TDD / domain-modeling skills

按需用 `code-review` / `tdd` / `domain-modeling` skills. 不强制。

---

## 已知 P0 问题 (审计 2026-09-01)

下列为审计发现的最优先问题, 修复优先级从高到低:

| Ticket | 严重度 | 问题 | 修复位置 |
|---|---|---|---|
| **#16** | 🔴 P0 BUG | Production fixture data 泄漏到用户 (`ENABLE_GALAXY_PREVIEW_UNITS = true`) | `KnowledgeGalaxyViewModel.ets` |
| **#15** | ✅ P0 规约错误 (已修) | AGENTS.md / MEMORY ArkTS 铁律基于错误理解 (C-style `for` 反向) | [`docs/style/arkts-1.1.md`](./docs/style/arkts-1.1.md) ✅ + [`scripts/audit-arkts-strict.mjs`](./scripts/audit-arkts-strict.mjs) v1 ✅ + [`scripts/arkts-lint/`](./scripts/arkts-lint/) v0.3 ✅ (34 规则, 63 tests) + **CI** [`.github/workflows/arkts-lint.yml`](./.github/workflows/arkts-lint.yml) ✅ |
| **#1** | 🔴 P0 文档过期 | 本文档剩余过期项 (本 PR 已修大部分) | — |
| **#3** | 🔴 P0 god class | `KnowledgeModel` 870 LOC 拆 3 个 service | `agents/` |
| **#4** | 🔴 P0 入口泄漏 | `Dispatcher.analyze`+`dispatch`+`routeDispatch` 合一 | `agents/core/Dispatcher.ets` (spec: [`docs/specs/004-dispatcher-single-entry.md`](./docs/specs/004-dispatcher-single-entry.md), ADR: 0003) |
| **#5** | 🔴 P0 LLM 三路径 | `call` + `callStream` + `callSseTokens` 合一 | `common/llm/LlmClient.ets` (spec: [`docs/specs/005-llm-client-consolidation.md`](./docs/specs/005-llm-client-consolidation.md), ADR: 0004) |
| **#7** | 🔴 P0 god class | `AgentChatService` 802 LOC 拆 3 个 service | `entry/services/` |

详见 [`docs/architecture-audit-full-20260901.md`](./docs/architecture-audit-full-20260901.md) §7 与 [子代理深读报告](./docs/audit-deepdive-20260901.md)。

---

**报告结束 (2026-09-01)**。本仓库关键文档:

- 入口: `AGENTS.md` (本文件)
- 术语: [`CONTEXT.md`](./CONTEXT.md) (项目专属词汇,agent 写代码前先读)
- 架构决策: [`docs/adr/`](./docs/adr/) (7 个 ADR,Phase 2 产出 + 1 增补 ADR-0007)
- Ticket specs: [`docs/specs/`](./docs/specs/) (依 ADR 写的实施 spec,Phase 3 进行中)
- 规则: [`docs/style/arkts-1.1.md`](./docs/style/arkts-1.1.md) (40+ ArkTS 1.1 strict 规则)
- 审计: [`docs/architecture-audit-full-20260901.md`](./docs/architecture-audit-full-20260901.md) + [`docs/audit-deepdive-20260901.md`](./docs/audit-deepdive-20260901.md)
- 工具链: `scripts/arkts-lint/` (AST 引擎 34 规则 + 63 测试) + `scripts/audit-arkts-strict.mjs` (regex 引擎 25 规则) + `.github/workflows/arkts-lint.yml` (CI)

Phase 3+ 工作:依 ADR 写 ticket spec,然后实施。**禁止直接改 `main`** — 只能在 `YunCeH` 上 push,user 手动 review + merge。
