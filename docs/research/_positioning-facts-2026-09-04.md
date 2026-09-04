# MindTrace 项目定位 · 一手事实底料 (2026-09-04)

> 仅作底料,非最终报告。每条带路径引用,无主观评价。
> 采集口径:仅使用 Read / Glob / Grep / Bash 只读命令。未跑 build / lint / hvigorw / git push。

---

## §A 项目身份

| 字段 | 值 | 引用路径 |
|---|---|---|
| 仓库根目录 | `D:\HMgent\MathMind` (注意大小写,不是 `MindTrace`) | `D:\HMgent\MathMind\AGENTS.md` §"绝对路径" |
| 项目对外名 (英文) | MindTrace · 数学学习助手 | `D:\HMgent\MathMind\README.md` L1 |
| 应用显示名 (zh) | MindTrace | `D:\HMgent\MathMind\AppScope\resources\base\element\string.json` L5 (`"value": "MindTrace"`) |
| bundleName | `com.example.mathmind` | `D:\HMgent\MathMind\AppScope\app.json5` L3 |
| versionCode / versionName | `1000000` / `1.0.0` | `D:\HMgent\MathMind\AppScope\app.json5` L4-L6 |
| 比赛名 | 鸿蒙高校创新赛 · 复赛 (HarmonyOS Hackathon) | `D:\HMgent\MathMind\AGENTS.md` 第 2 行 |
| GitHub 仓库 | `YunC-GCT/Math-Mind` (`git@github.com:YunC-GCT/Math-Mind.git`) | `D:\HMgent\MathMind\README.md` L3; `git remote -v` 输出 |
| 主分支 / 当前分支 | 主分支 `main` (remote HEAD); 当前工作分支 `YunCeH` | `git symbolic-ref refs/remotes/origin/HEAD`; `git branch --show-current` |
| HEAD SHA | `596349350a8187535bd9920900d28b50b1f6b60f` | `git rev-parse HEAD` |
| 工作树状态 | clean (仅 `.zcode/` 为 untracked,无 staged/unstaged) | `git status` 输出 |
| 远程 tags | 无 (`git tag -l` 为空) | `git tag -l` |
| 最近 30 commit 分布 | `docs(style):` ×4, `docs(agents):` ×3, `chore(lint):` ×3, `docs(research):` ×2, `docs(onboarding):` ×2, `docs(index):` ×2, 其他各 1 (共 19 类) | 解析 `git log --oneline -30 --pretty=format:"%s"` (commit `5963493` → `c0e06bf` 区间) |
| 最近 30 commit 首条主题 | `fix(ci): add `permissions: contents: read` to both workflows` | `git log --oneline -1` → `5963493` |
| 工作流 CI 文件 | `.github/workflows/` 已配置 (arkts-lint.yml / naming-lint.yml 等) | `D:\HMgent\MathMind\.github\workflows\` (per onboarding.md L120-L123) |
| 同期 W 版本 | W3 / W3.5 / W4 (W4 自 2026-07-24 起,审计 2026-09-01) | `D:\HMgent\MathMind\AGENTS.md` 顶部; `D:\HMgent\MathMind\README.md` L9 (`## 当前阶段总览 (2026-07-24)`) |

---

## §B 技术画像

### B.1 SDK 与构建目标

| 字段 | 值 | 引用 |
|---|---|---|
| modelVersion (oh-package) | `6.1.1` | `D:\HMgent\MathMind\oh-package.json5` L2 |
| targetSdkVersion | `6.1.1(24)` | `D:\HMgent\MathMind\build-profile.json5` L7 |
| compatibleSdkVersion | `6.1.1(24)` | `D:\HMgent\MathMind\build-profile.json5` L8 |
| runtimeOS | `HarmonyOS` | `D:\HMgent\MathMind\build-profile.json5` L9 |
| strictMode | `caseSensitiveCheck: true`, `useNormalizedOHMUrl: true` | `D:\HMgent\MathMind\build-profile.json5` L10-L13 |
| buildModeSet | `debug`, `release` | `D:\HMgent\MathMind\build-profile.json5` L19-L25 |
| root devDependencies | `@ohos/hypium 1.0.25`, `@ohos/hamock 1.0.0` | `D:\HMgent\MathMind\oh-package.json5` L5-L8 |
| 5 modules 列表 | `entry`, `common`, `agents`, `skill`, `cardservice` | `D:\HMgent\MathMind\build-profile.json5` L27-L77; `D:\HMgent\MathMind\oh-package.json5` L9-L15 |

### B.2 5 module `oh-package.json5` 关键字段

| module | type (per AGENTS) | `name` | `version` | `main` | `dependencies` |
|---|---|---|---|---|---|
| entry | HAP (type:entry) | `entry` | `1.0.0` | `""` (空) | `common` (file:../common), `agents` (file:../agents) |
| common | HSP (shared) | `common` | `1.0.0` | `./src/main/ets/Index.ets` | (无) |
| agents | HSP (shared) | `agents` | `1.0.0` | `./src/main/ets/Index.ets` | `common` (file:../common) |
| skill | HSP (shared) | `skill` | `1.0.0` | (未设) | `common`, `agents` |
| cardservice | HSP (shared) | `cardservice` | `1.0.0` | (未设) | `common`, `agents` |

> 引用:
> - `D:\HMgent\MathMind\entry\oh-package.json5`
> - `D:\HMgent\MathMind\common\oh-package.json5`
> - `D:\HMgent\MathMind\agents\oh-package.json5`
> - `D:\HMgent\MathMind\skill\oh-package.json5`
> - `D:\HMgent\MathMind\cardservice\oh-package.json5`
>
> 注: 审计 §1.2 提及 `module.json5` 中 type 字段是 `"shared"` 而非字面 `"hsp"` (来源 `docs\legacy\mindtrace\architecture\audit-full-2026-09-01.md` L50)

### B.3 Lint / CI 工具栈

| 字段 | 值 | 引用 |
|---|---|---|
| Code-linter 配置 | `code-linter.json5` (885 B) | `D:\HMgent\MathMind\code-linter.json5` |
| arkts-lint 版本 | `0.3.0` | `D:\HMgent\MathMind\scripts\arkts-lint\package.json` L3 |
| arkts-lint 依赖 | `@typescript-eslint/parser ^8.18.0`, `typescript ^5.7.4` | `D:\HMgent\MathMind\scripts\arkts-lint\package.json` L18-L21 |
| 引擎 | Node ≥ 20 (ESM, `type: module`) | `D:\HMgent\MathMind\scripts\arkts-lint\package.json` L22-L24 |
| 测试脚本 | `node --test tests/{parser,registry,rules-official,knowledge-galaxy-fixture-flag,llm-config-throw}.test.mjs` | `D:\HMgent\MathMind\scripts\arkts-lint\package.json` L10 |
| 辅助脚本 | naming-lint, link-check | `D:\HMgent\MathMind\scripts\naming-lint\`, `D:\HMgent\MathMind\scripts\link-check\` |
| 启动 OCR 服务 | `python -m uvicorn ocr.app:app --port 8000` | `D:\HMgent\MathMind\start_ocr_server.bat` |

---

## §C 业务核心(显著文件, LOC ≥ 300)

> 命令: `find <dir> -name '*.ets' | xargs wc -l` (实测,排除 build/ / oh_modules/ / node_modules/)
> LOC 阈值: ≥ 300 视为"显著文件"

### C.1 `agents/src/main/ets/agents/` (AI 子 Agent)

| 路径 | LOC | 角色 |
|---|---|---|
| `D:\HMgent\MathMind\agents\src\main\ets\agents\KnowledgeModel.ets` | **929** | 🔴 god class;prompt 构建 + AI JSON 调用 + 字段归一化 + truth check(4 项)+ LaTeX 修复 + fallback 构造 + 单元 ID 生成 + classification hint 解析 (审计 §4.2 列为 P0) |
| `D:\HMgent\MathMind\agents\src\main\ets\agents\TypeClassifier.ets` | **363** | 🟡 多职责混杂 (审计 §4.3 关联) |
| 目录合计 | 1292 (2 文件) | |

### C.2 `common/src/main/ets/llm/` (LLM 调用层)

| 路径 | LOC | 角色 |
|---|---|---|
| `D:\HMgent\MathMind\common\src\main\ets\llm\LlmClient.ets` | **505** | 🔴 3 套并行调用路径 (`call` / `callStream` / `callSseTokens`); 审计 §4.1 P0 |
| `D:\HMgent\MathMind\common\src\main\ets\llm\LlmConfig.ets` | 248 | 🟡 配置单例; 静默覆盖用户配置 (审计 §4.4 P1) |
| `D:\HMgent\MathMind\common\src\main\ets\llm\LlmGuard.ets` | 128 | JSON 校验守卫 |
| `D:\HMgent\MathMind\common\src\main\ets\llm\LlmTypes.ets` | 126 | LLM 类型定义 |
| `D:\HMgent\MathMind\common\src\main\ets\llm\LlmOutputRules.ets` | 26 | 输出规则 |
| 目录合计 | 1033 (5 文件) | |

### C.3 `entry/src/main/ets/pages/` (UI 页面)

| 路径 | LOC | 角色 |
|---|---|---|
| `D:\HMgent\MathMind\entry\src\main\ets\pages\Review\ReviewGraphView.ets` | **1880** | 🔴 最大 UI 文件; 图谱 + 动画 + 数据 + UI shell 混在一起 (审计 §4.9 P1) |
| `D:\HMgent\MathMind\entry\src\main\ets\pages\Review\ReviewPage.ets` | 285 | 复习主页 |
| `D:\HMgent\MathMind\entry\src\main\ets\pages\Review\ReviewPlanView.ets` | 278 | 复习计划视图 |
| `D:\HMgent\MathMind\entry\src\main\ets\pages\Review\ReviewPlanRow.ets` | 233 | 复习计划行 |
| `D:\HMgent\MathMind\entry\src\main\ets\pages\Home\HomePage.ets` | 210 | 首页 |
| `D:\HMgent\MathMind\entry\src\main\ets\pages\AiSettings\AiSettingsPage.ets` | 205 | AI 设置主页 |
| `D:\HMgent\MathMind\entry\src\main\ets\pages\Notes\SubjectDetailPage.ets` | 201 | 学科详情页 |
| `D:\HMgent\MathMind\entry\src\main\ets\pages\Notes\SubjectCard.ets` | 193 | 学科卡片 |
| `D:\HMgent\MathMind\entry\src\main\ets\pages\AiSettings\OcrConfigSection.ets` | 168 | OCR 配置区 |
| `D:\HMgent\MathMind\entry\src\main\ets\pages\Notes\NotesSummaryPanel.ets` | 166 | 笔记摘要面板 |
| `D:\HMgent\MathMind\entry\src\main\ets\pages\Profile\ProfilePage.ets` | 141 | 个人页 |
| `D:\HMgent\MathMind\entry\src\main\ets\pages\Home\HeroBanner.ets` | 136 | 首页 hero banner |
| `D:\HMgent\MathMind\entry\src\main\ets\pages\Home\HomeCollapsedReview.ets` | 133 | 首页复习折叠块 |
| `D:\HMgent\MathMind\entry\src\main\ets\pages\Notes\NotesPage.ets` | 122 | 笔记主页 |
| `D:\HMgent\MathMind\entry\src\main\ets\pages\Home\GradientRing.ets` | 114 | 渐变环 |
| `D:\HMgent\MathMind\entry\src\main\ets\pages\Notes\SubjectNoteList.ets` | 109 | 学科内笔记块 |
| 其余 26 个文件 | 各 ≤ 106 LOC,详见实测 | 含 MainTabs / Profile / Home / Notes / AiSettings 子组件 |
| 目录合计 | 6342 (42 文件) | |

> 唯一显著文件 (≥ 300 LOC): **`ReviewGraphView.ets` (1880)**; 其余均在 300 以下,但 `HomePage` / `AiSettingsPage` / `SubjectDetailPage` 等 7 个文件落在 200-300 区间,作为"中等显著文件"。

---

## §D 工程核心(arkts-lint)

### D.1 文件清单 (排除 `node_modules/`)

> 命令: `find scripts/arkts-lint -type f \( -name "*.mjs" -o -name "*.md" \) -not -path "*/node_modules/*"`

#### `scripts/arkts-lint/` 根

| 路径 | 用途 |
|---|---|
| `D:\HMgent\MathMind\scripts\arkts-lint\README.md` | 引擎 README (214 行,自陈 34 规则 / 63 测试 / 0 错误) |
| `D:\HMgent\MathMind\scripts\arkts-lint\index.mjs` | CLI 入口 (210 行,含 `--quiet` / `--check-rules` / `--json` / `--baseline`) |
| `D:\HMgent\MathMind\scripts\arkts-lint\package.json` | 包定义 (version 0.3.0, ESM) |
| `D:\HMgent\MathMind\scripts\arkts-lint\.gitignore` | 排除 node_modules |

#### `scripts/arkts-lint/parser/`

| 路径 |
|---|
| `D:\HMgent\MathMind\scripts\arkts-lint\parser\index.mjs` |

#### `scripts/arkts-lint/ast-utils/`

| 路径 |
|---|
| `D:\HMgent\MathMind\scripts\arkts-lint\ast-utils\has-decorator.mjs` |
| `D:\HMgent\MathMind\scripts\arkts-lint\ast-utils\walk.mjs` |

#### `scripts/arkts-lint/rules/` (含子目录)

| 路径 | 用途 |
|---|---|
| `D:\HMgent\MathMind\scripts\arkts-lint\rules\_template.mjs` | 规则文件模板 |
| `D:\HMgent\MathMind\scripts\arkts-lint\rules\registry.mjs` | 加载 + 校验 + id 唯一性 |

#### `scripts/arkts-lint/rules/official/` (32 个官方 strict-mode 规则文件)

`arkts-as-casts`, `arkts-implements-only-iface`, `arkts-limited-throw`, `arkts-no-any-unknown`, `arkts-no-call-signatures`, `arkts-no-class-literals`, `arkts-no-conditional-types`, `arkts-no-ctor-prop-decls`, `arkts-no-delete`, `arkts-no-destruct-assignment`, `arkts-no-destruct-decls`, `arkts-no-destruct-params`, `arkts-no-for-in`, `arkts-no-func-expressions`, `arkts-no-generators`, `arkts-no-indexed-signatures`, `arkts-no-intersection-types`, `arkts-no-is`, `arkts-no-jsx`, `arkts-no-mapped-types`, `arkts-no-nested-funcs`, `arkts-no-polymorphic-unops`, `arkts-no-private-identifiers`, `arkts-no-props-by-index`, `arkts-no-standalone-this`, `arkts-no-structural-typing`, `arkts-no-symbol`, `arkts-no-type-query`, `arkts-no-types-in-catch`, `arkts-no-typing-with-this`, `arkts-no-var`, `arkts-no-with` (32 个)

#### `scripts/arkts-lint/rules/project/` (项目偏好 2 规则)

| 路径 |
|---|
| `D:\HMgent\MathMind\scripts\arkts-lint\rules\project\no-get-accessor.mjs` |
| `D:\HMgent\MathMind\scripts\arkts-lint\rules\project\struct-no-regular-methods.mjs` |

#### `scripts/arkts-lint/tests/` (5 单元测试 + 1 辅助运行器)

| 路径 | LOC |
|---|---|
| `D:\HMgent\MathMind\scripts\arkts-lint\tests\parser.test.mjs` | 92 |
| `D:\HMgent\MathMind\scripts\arkts-lint\tests\registry.test.mjs` | 70 |
| `D:\HMgent\MathMind\scripts\arkts-lint\tests\rules-official.test.mjs` | 298 |
| `D:\HMgent\MathMind\scripts\arkts-lint\tests\knowledge-galaxy-fixture-flag.test.mjs` | 97 |
| `D:\HMgent\MathMind\scripts\arkts-lint\tests\llm-config-throw.test.mjs` | 176 |
| `D:\HMgent\MathMind\scripts\arkts-lint\tests\run-rule.mjs` | 76 (辅助) |
| 测试合计 (含辅助) | 809 |

### D.2 README 自陈关键数字

> 来源 `D:\HMgent\MathMind\scripts\arkts-lint\README.md` L3, L34-L46

| 指标 | v1 (regex) | arkts-lint (AST) | 备注 |
|---|---|---|---|
| 规则数 | 25 | **34** (+9) | L37-L38 |
| 可执行规则 | 23 (2 禁用) | **34** | L39 |
| 单元测试 | 0 | **63/63 pass** | L40 |
| 扫描文件数 | 174 | 173 (排除 fixtures) | L41 |
| 真实 errors | 0 | **0** (CI ✅) | L42 |
| Warnings | 285 (≈80% 误报) | **253** (高质量) | L43 |
| Parse errors | n/a | **91** (新增发现) | L44 |
| `--check-rules` | ✅ | ✅ | L45 |
| CI 退出码 | 0 | 0 | L46 |
| 状态 | 🟢 Day 3 完成 (2026-09-01) | — | L3 |
| 与审计关联 | Phase 4 ticket #15 | — | L5 |
| 已知限制 (Day 3 待办) | 91 parse-error 文件 (~12%),15 官方规则未实现 (需 type-checker),v1 禁用 2 规则未复活 | — | L159-L168 |

> 注: README 中 L67 出现重复行 (`| CI 退出码 | 0 | 0 | |` 出现两次),L59 vs L40 数字略有冲突 (测试数 63 vs 实际 5 个 test 文件), 以 L40 "63/63 pass" 为准。

---

## §E 文档层清单(文件路径 + 字节数 + 一句话用途)

> 命令: `stat -c "%s %n" ...` 实测; `git ls-files` 已确认全部进 git。

### E.1 顶层 doc (`D:\HMgent\MathMind\` 根)

| 路径 | 字节 | 一句话用途 |
|---|---|---|
| `D:\HMgent\MathMind\AGENTS.md` | 8 821 | Agent 工作守则 + 项目硬规则 + 改 / 读指针 |
| `D:\HMgent\MathMind\CONTEXT.md` | 7 289 | 项目专属词汇表 (19 个术语,4 种 "agent" 消歧) |
| `D:\HMgent\MathMind\README.md` | 48 117 | 对外主页 / W4 总结 / 调研资料 / 验证记录 |

### E.2 `docs/adr/` (Architecture Decision Records)

| 路径 | 字节 | 一句话用途 |
|---|---|---|
| `D:\HMgent\MathMind\docs\adr\0001-layer-boundaries-in-5-module-arkts-app.md` | 2 181 | 5 module 边界 (entry / common / agents / skill / cardservice) |
| `D:\HMgent\MathMind\docs\adr\0002-agent-terminology-disambiguation.md` | 1 975 | "agent" 一词四义消歧 |
| `D:\HMgent\MathMind\docs\adr\0003-dispatcher-single-entry-design.md` | 2 189 | Dispatcher 单入口设计 |
| `D:\HMgent\MathMind\docs\adr\0004-llm-call-layer-consolidation.md` | 2 280 | LLM 调用层整合 (call + callStream + callSseTokens 收敛) |
| `D:\HMgent\MathMind\docs\adr\0005-mcp-to-tools-rename.md` | 1 687 | `mcp/` 目录 → `tools/` 重命名 |
| `D:\HMgent\MathMind\docs\adr\0006-knowledge-model-decomposition-plan.md` | 2 520 | KnowledgeModel god class 拆分计划 |
| `D:\HMgent\MathMind\docs\adr\0007-test-baseline-12-unit-tests.md` | 2 913 | Phase 4 测试基线 12 个单测 |
| `D:\HMgent\MathMind\docs\adr\index.md` | 4 377 | ADR 索引 + 写作指南 |
| **小计** | **20 122** (8 文件) | |

### E.3 `docs/specs/` (实施 spec, 按 ADR 写)

| 路径 | 字节 | 一句话用途 |
|---|---|---|
| `D:\HMgent\MathMind\docs\specs\003-knowledge-model-decomposition.md` | 6 625 | 003 号 ticket 实施 (拆 KnowledgeModel) |
| `D:\HMgent\MathMind\docs\specs\004-dispatcher-single-entry.md` | 4 461 | 004 号 (Dispatcher 单入口) |
| `D:\HMgent\MathMind\docs\specs\005-llm-client-consolidation.md` | 6 708 | 005 号 (LlmClient 整合) |
| `D:\HMgent\MathMind\docs\specs\007-agent-chat-service-decomposition.md` | 6 873 | 007 号 (AgentChatService 拆分) |
| `D:\HMgent\MathMind\docs\specs\009-llm-config-throw-on-silent-override.md` | 4 505 | 009 号 (LlmConfig 静默覆盖改 throw) |
| `D:\HMgent\MathMind\docs\specs\010-mcp-to-tools-rename.md` | 3 323 | 010 号 (mcp→tools 重命名) |
| `D:\HMgent\MathMind\docs\specs\index.md` | 4 037 | Spec 索引 + TDD 流程 |
| **小计** | **36 532** (7 文件) | |

### E.4 `docs/agents/` (Agent 工作流文档)

| 路径 | 字节 | 一句话用途 |
|---|---|---|
| `D:\HMgent\MathMind\docs\agents\agent-glossary.md` | 7 339 | agent 术语 + agent-glossary 拆分记录 |
| `D:\HMgent\MathMind\docs\agents\api-version.md` | 2 343 | API 版本兼容 + lint job 说明 |
| `D:\HMgent\MathMind\docs\agents\ci-failure-workflow.md` | 4 327 | CI 失败排查工作流 |
| `D:\HMgent\MathMind\docs\agents\domain.md` | 2 094 | 项目域文档规约 |
| `D:\HMgent\MathMind\docs\agents\file-header-template.md` | 1 515 | .ets 文件头模板 |
| `D:\HMgent\MathMind\docs\agents\git-conventions.md` | 4 305 | git commit / branch / merge 规约 |
| `D:\HMgent\MathMind\docs\agents\handoff-langgraph-migration.md` | 7 895 | LangGraph 迁移交接报告 |
| `D:\HMgent\MathMind\docs\agents\issue-tracker.md` | 3 789 | GitHub issue 工作流 (YunC-GCT/Math-Mind) |
| `D:\HMgent\MathMind\docs\agents\naming-exceptions.md` | 2 718 | 命名例外清单 |
| `D:\HMgent\MathMind\docs\agents\security.md` | 1 040 | secrets / 签名规则 |
| `D:\HMgent\MathMind\docs\agents\smoke-test.md` | 1 583 | 8 步手动 smoke test 矩阵 |
| `D:\HMgent\MathMind\docs\agents\triage-labels.md` | 1 058 | 5 标签 (needs-triage / needs-info / ready-for-agent / ready-for-human / wontfix) |
| **agents 子目录小计** | **40 006** (12 文件) | |
| `D:\HMgent\MathMind\docs\agents\patterns\add-new-adr.md` | 4 758 | "如何新增 ADR" 模式 |
| `D:\HMgent\MathMind\docs\agents\patterns\index.md` | 2 999 | patterns 索引 |
| `D:\HMgent\MathMind\docs\agents\patterns\investigate.md` | 5 802 | "如何排查 bug" 模式 |
| `D:\HMgent\MathMind\docs\agents\patterns\refactor-x.md` | 5 188 | "如何做 X 重构" 模式 |
| **patterns 子目录小计** | **18 747** (4 文件) | |
| **docs/agents 总计** | **58 753** (16 文件) | |

### E.5 `docs/legacy/mindtrace/architecture/` (审计历史,2026-09-01 frozen)

| 路径 | 字节 | 一句话用途 |
|---|---|---|
| `D:\HMgent\MathMind\docs\legacy\mindtrace\architecture\audit-2026-09-01.md` | 14 139 | AGENTS.md 单文档早期审计 (子集) |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\architecture\audit-full-2026-09-01.md` | 55 264 | 全代码库架构审计主报告 (21 finding,本报告 §F 摘其 1/3/4/6/7) |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\architecture\deep-dive-2026-09-01.md` | 48 916 | 7 个最大文件逐文件深度分析 (50+ finding) |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\architecture\audit-2026-09-01.html` | 23 008 | audit 的 HTML 渲染 |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\architecture\audit-full-2026-09-01.html` | 44 313 | full audit 的 HTML 渲染 |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\architecture\lint-baseline-2026-09-01.json` | 149 077 | v1 lint baseline (regex) |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\architecture\lint-baseline-ast-2026-09-01.json` | 105 649 | arkts-lint v0.3 baseline (AST) |
| **小计** | **440 366** (7 文件) | |

### E.6 `docs/legacy/mindtrace/` (其他子目录,frozen)

#### `api/`

| 路径 | 字节 | 一句话用途 |
|---|---|---|
| `D:\HMgent\MathMind\docs\legacy\mindtrace\api\contract.md` | 15 682 | API 契约 |

#### `competition/`

| 路径 | 字节 | 一句话用途 |
|---|---|---|
| `D:\HMgent\MathMind\docs\legacy\mindtrace\competition\ocr-setup.md` | 3 308 | OCR 服务启动指引 |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\competition\references-2026-07-26.md` | 4 852 | 比赛相关参考资料 |

#### `plans/w3/`

| 路径 | 字节 | 一句话用途 |
|---|---|---|
| `D:\HMgent\MathMind\docs\legacy\mindtrace\plans\w3\agent-memory-flow-2026-07-19.md` | 10 112 | Agent 记忆流 |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\plans\w3\agent-reply-style-testset-2026-07-19.md` | 6 245 | Agent 回复风格测试集 |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\plans\w3\chapter-field-refactor-2026-07-22.md` | 7 667 | chapter 字段重构 |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\plans\w3\dead-code-archive-2026-07-19.md` | 2 462 | 死代码归档 |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\plans\w3\frontend-architecture-2026-07-17.md` | 9 635 | 前端架构 (W3) |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\plans\w3\notes-editor-markdown-2026-07-20.md` | 4 229 | 笔记编辑器 markdown |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\plans\w3\render-protocol-optimization-route-2026-07-22.md` | 73 774 | 渲染协议优化路线 |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\plans\w3\summary.md` | 9 843 | W3 总结 |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\plans\w3\ui-preload-cache-optimization-2026-07-21.md` | 6 777 | UI 预加载缓存优化 |
| **w3 小计** | **130 744** (9 文件) | (含 5 个 .html,本表仅 .md) |

#### `plans/w4/`

| 路径 | 字节 | 一句话用途 |
|---|---|---|
| `D:\HMgent\MathMind\docs\legacy\mindtrace\plans\w4\ai-float-chat-streaming-plan-2026-07-24.md` | 18 608 | AI 浮窗对话流式方案 |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\plans\w4\chat-long-content-fix-plan-2026-07-23.md` | 8 484 | 长对话内容修复 |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\plans\w4\formula-split-render-plan-2026-07-24.md` | 20 958 | 公式分块渲染方案 (核心交付) |
| **w4 小计** | **48 050** (3 文件) | (含 1 个 .html) |

#### `research/`

| 路径 | 字节 | 一句话用途 |
|---|---|---|
| `D:\HMgent\MathMind\docs\legacy\mindtrace\research\formula-render-strategies-2026-07-24.md` | 28 567 | 公式渲染策略调研 |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\research\harmonyos-http-streaming-2026-07-24.md` | 13 169 | HarmonyOS HTTP 流式调研 |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\research\huawei-arkui-agent-20260901.md` | 44 646 | 华为 ArkUI Agent 调研 (398 行,30 URL) |
| `D:\HMgent\MathMind\docs\legacy\mindtrace\research\multi-webview-performance-2026-07-24.md` | 21 650 | 多 WebView 性能调研 |
| **research 小计** | **108 032** (4 文件) | |

### E.7 `docs/research/` (active, 2026-09)

| 路径 | 字节 | 一句话用途 |
|---|---|---|
| `D:\HMgent\MathMind\docs\research\agent-framework-comparison-2026-09-02.md` | 9 642 | Agent 框架对比 (LangGraph 等) |
| `D:\HMgent\MathMind\docs\research\langgraph-migration-2026-09-02.md` | 15 560 | LangGraph 迁移方案 |
| **小计** | **25 202** (2 文件 .md; 含 2 个 .html 兄弟) | |

### E.8 `docs/style/` (编码规范)

| 路径 | 字节 | 一句话用途 |
|---|---|---|
| `D:\HMgent\MathMind\docs\style\arkts-1.1.md` | 20 539 | ArkTS 1.1 strict 规则手册 (40+ 规则) |
| `D:\HMgent\MathMind\docs\style\naming-conventions.md` | 21 598 | 命名规约权威源 (v1.1, 14 节) |
| **小计** | **42 137** (2 文件) | |

### E.9 `docs/template/` (复制模板)

| 路径 | 字节 | 一句话用途 |
|---|---|---|
| `D:\HMgent\MathMind\docs\template\adr-template.md` | 1 004 | 新 ADR 模板 |
| `D:\HMgent\MathMind\docs\template\agent-workflow-template.md` | 1 187 | 新 agent workflow 模板 |
| `D:\HMgent\MathMind\docs\template\index.md` | 1 234 | 模板索引 |
| `D:\HMgent\MathMind\docs\template\research-template.md` | 1 063 | 新 research 模板 |
| `D:\HMgent\MathMind\docs\template\spec-template.md` | 1 535 | 新 spec 模板 |
| **小计** | **6 023** (5 文件) | |

### E.10 `docs/` 顶层 (除上述子目录)

| 路径 | 字节 | 一句话用途 |
|---|---|---|
| `D:\HMgent\MathMind\docs\index.md` | 5 807 | docs 目录导航 (按目的 / 受众 / 类型 cheat sheet) |
| `D:\HMgent\MathMind\docs\onboarding.md` | 5 972 | 5-min / 30-min 新人上手指南 |
| **小计** | **11 779** (2 文件) | |

---

## §F 审计结论

> 来源: `D:\HMgent\MathMind\docs\legacy\mindtrace\architecture\audit-full-2026-09-01.md`
> 审计基线: commit `29df511` on `main` (2026-09-01, 距现 HEAD `5963493` 落后 N commit)
> 审计范围: 162 .ets 文件 / 23 301 LOC

### F.1 §0 TL;DR 总评级 (per L14-L26)

| 维度 | 评级 | 说明 |
|---|---|---|
| **总体架构健康度** | 🟡 可工作但分层混乱 | 业务跑通,W4 加流式;2 个 700+ LOC god class,3 套并行 LLM 调用路径,跨层 import 缺乏规约 |
| **深度模块占比** | 🔴 约 25% | 6/24 核心类深模块;18/24 (含 KnowledgeModel / AgentChatService / ContentProtocol) 浅模块 / God class |
| **ArkTS 1.1 规范** | 🟡 规则表覆盖率 ~10% | 官方 40+ 规则,AGENTS.md / MEMORY 仅列 5 条 |
| **LLM 调用层** | 🔴 三套并行路径 | `call` + `callStream` + `callSseTokens`,行为各自独立 |
| **Agent 调度** | 🟡 多入口泄漏 | Dispatcher 暴露 `analyze` + `dispatch` |
| **UI / Service 分层** | 🔴 分层不清 | AgentChatService (802 LOC) 持 UI 回调 + prompt + JSON + 记忆 + 流式 |
| **MD 文档可信度** | 🟡 部分可信 | AGENTS.md 有 6 处与现状脱节 |

### F.2 §1 审计方法 (L30-L59)

- 数据来源: 全量扫描 5 module, 162 文件 / 23 301 LOC (排除 build / oh_modules / 配置)
- 模块分布 (per L42-L48):

| module | 类型 | 文件 | LOC | 层 |
|---|---|---|---|---|
| entry | HAP (type:entry) | 123 | 17 719 | UI + 业务编排 |
| common | HSP (shared) | 22 | 3 580 | 类型 + 基础设施 |
| agents | HSP (shared) | 9 | 1 930 | AI 业务 |
| skill | HSP (shared) | 2 | 14 | 卡片能力 |
| cardservice | HSP (shared) | 6 | 58 | 卡片服务 |

### F.3 §3 跨模块 Seam Map (L181-L230)

关键 seam 5 个:
1. `LlmClient` ↔ `LlmGuard` — JSON 校验 + 调用耦合
2. `Dispatcher.dispatch` ↔ `AiService.capture` — 业务编排接口
3. `KnowledgeModel.structure` ↔ `NoteDao.insert` — 业务数据落地
4. `OcrTool.recognize` ↔ `TypeClassifier.extractText` — OCR 输入路径
5. `LlmConfig` / `OcrConfig` 单例 ↔ `preferences` — 配置持久化

### F.4 §4 关键 finding 计数 (L234-L731)

| 优先级 | 数量 | finding 编号 |
|---|---|---|
| 🔴 P0 | 7 | §4.1, §4.2, §4.3, §4.16, §4.17, §4.20, (含 §4.10 P0 BUG 子项) |
| 🟡 P1 | 9 | §4.4, §4.5, §4.6, §4.7, §4.8, §4.9, §4.10, §4.11, §4.18, §4.19, §4.21 |
| 🟢 P2 | 4 | §4.12, §4.13, §4.14, §4.15 |
| 总计 | **21 finding** (审计自陈) | |

> 命令: `grep -cE "^### 4\." audit-full-2026-09-01.md` = 21 (审计 §4 系列小节总数)

具体清单:

| § | 严重度 | finding |
|---|---|---|
| 4.1 | 🔴 P0 | LLM 三套调用路径并行 (LlmClient) |
| 4.2 | 🔴 P0 | KnowledgeModel God Class (870 LOC) |
| 4.3 | 🔴 P0 | AgentChatService God Class (802 LOC) |
| 4.4 | 🟡 P1 | LlmConfig / OcrConfig 静默覆盖 |
| 4.5 | 🟡 P1 | Dispatcher 双入口泄漏 |
| 4.6 | 🟡 P1 | OcrTool 6 处 C-style `for` (非 ArkTS 1.1 违规) |
| 4.7 | 🟡 P1 | ContentProtocol 单职责 580 LOC |
| 4.8 | 🟡 P1 | mcp/ 目录空壳 |
| 4.9 | 🟡 P1 | ReviewGraphView 1880 LOC |
| 4.10 | 🟡 P1 (含 P0 BUG) | KnowledgeGalaxyViewModel 789 LOC + 假 "示例:*" fixture 泄漏到生产 (P0 BUG) |
| 4.11 | 🟡 P1 | OcrTool UTF-8 手写编码 |
| 4.12 | 🟢 P2 | "agent" 术语重载 |
| 4.13 | 🟢 P2 | 文件头注释模板覆盖率不均 |
| 4.14 | 🟢 P2 | 缺少 CONTEXT.md / docs/adr/ (本审计时点) |
| 4.15 | 🟢 P2 | common/DatabaseHelper.ets 在顶层 |
| 4.16 | 🔴 P0 | AGENTS.md 路径错误 + 过期 |
| 4.17 | 🔴 P0 | AGENTS.md "禁 C 风格 for" 规则理解错误 |
| 4.18 | 🟡 P1 | ArkTS 1.1 strict 规则表覆盖率 ~10% |
| 4.19 | 🟡 P1 | compatibleSdkVersion < 10 导致 strict 仅警告 |
| 4.20 | 🔴 P0 | Production fixture data 泄漏到用户 (highest priority) |
| 4.21 | 🟡 P1 | extractJsonObject regex 在嵌套 JSON 截断 |

### F.5 §6 缺失项 (L874-L900)

- §6.1 文档 (审计时): `CONTEXT.md` 不存在,`docs/adr/` 不存在,`docs/W3_SUMMARY.md` 不存在,`docs/specs/` 不存在
  > 当前状态 (2026-09-04): 上述 4 项**全部已补齐** (本仓库 `CONTEXT.md` 7 289B,`docs/adr/` 8 文件,`docs/specs/` 7 文件; `W3_SUMMARY.md` 仍无,但 `docs/legacy/mindtrace/plans/w3/summary.md` 存在 9 843B)
- §6.2 测试 (审计时): `agents/src/test/` 仅 2 文件; `common/src/test/` 不存在; `entry/src/test/` 不存在
  > 当前状态 (2026-09-04): `common/src/test/` 已建 (5 文件), `entry/src/test/` 已建 (3 文件), `entry/src/ohosTest/ets/test/` 已建 (2 文件), `agents/src/test/` 仍 2 文件
- §6.3 跨 session 通信: `docs/ui_to_agent_*.md` 命名规约存在但无实际文件 (per 早期 audit §2.7)

### F.6 §7 Phase 3 Ticket 预览 (L904-L955)

> 审计时点 Phase 3 全部 6 个 spec 已写完,Phase 4 实施待开始。

**16 个 ticket 概览**:

| # | 标题 | 阻塞 | 工作量 | 对应 §4 |
|---|---|---|---|---|
| 1 | Rewrite AGENTS.md | — | S (1-2h) | §4.16 |
| 3 | Split KnowledgeModel | #1, ADR-0002 | L (4-6h) | §4.2 |
| 4 | Collapse Dispatcher seams | #3 | M (2-3h) | §4.5 |
| 5 | Consolidate LLM-call layer | #1, ADR-0003 | L (4-6h) | §4.1 |
| 6 | Standardize file headers | #1 | M (2-3h) | §4.13 |
| 7 | Refactor AgentChatService | #1, ADR-0002 | L (4-6h) | §4.3 |
| 8 | Add CONTEXT.md + ADR-0001~0004 | — | M (2-3h) | §4.14 |
| 9 | LlmConfig throw on silent override | #1 | S (1h) | §4.4 |
| 10 | Rename mcp/tools | — | XS (30min) | §4.8 |
| 11 | Refactor OcrTool.strToUtf8 | — | XS (30min) | §4.11 |
| 12 | Split ReviewGraphView | #1 | L (4-6h) | §4.9 |
| 13 | Add 5 tests for StructureService | #3 | M (2-3h) | §6.2 |
| 14 | Update smoke test matrix | #1 | S (1h) | (inherited) |
| **15** | Update AGENTS.md rule #2 + arkts-1.1.md + Lint job | #1 | M (2-3h) | §4.17-19 |
| **16** | **(P0 BUG) Fix fixture data leak to users** | — | S (1h) | §4.20 |
| 17 | Fix extractJsonObject regex | — | S (1-2h) | §4.21 |

> 总工作 ~30-45h。优先级重排: **#16 (P0 BUG) > #15 (规约) > #1 (文档) > #3 (god class) > #4-7,12 (架构) > #9-11 (小修) > #13-14,17 (测试/小修)**

### F.7 已修 vs 待修(审计后 2026-09-01 → 2026-09-04)

> 来源 `D:\HMgent\MathMind\AGENTS.md` §"状态"

**✅ 已修 (per AGENTS.md)**:
- **#15** ArkTS 铁律 (规约错误) — 已通过 `docs/style/arkts-1.1.md` (20 539B) 补全 + arkts-lint v0.3 接入 CI
- **#9** LlmConfig 静默覆盖 (TDD) — spec `009-llm-config-throw-on-silent-override.md` 已写 + arkts-lint 有 `tests/llm-config-throw.test.mjs` (176 行)
- **#16** fixture data 泄漏 (TDD) — arkts-lint 有 `tests/knowledge-galaxy-fixture-flag.test.mjs` (97 行)

**🟡 待修 (per AGENTS.md)**:
- **#1** doc expiry
- **#3 / #4 / #5 / #7** god class & 入口泄漏 (有 spec, 待实施)
- **#10** mcp/ → tools/ rename

---

## §G 测试分布

### G.1 `*.test.ets` (ArkTS 单元测试,按目录)

> 命令: `find . -name "*.test.ets" -not -path "*/build/*" -not -path "*/oh_modules/*" -not -path "*/node_modules/*"`

| 目录 | 文件数 | 路径 | LOC |
|---|---|---|---|
| `D:\HMgent\MathMind\agents\src\test\` | 2 | `KnowledgeModel.test.ets` | 88 |
| | | `List.test.ets` | 12 |
| `D:\HMgent\MathMind\common\src\test\` | 5 | `ContentExcerptBuilder.test.ets` | 70 |
| | | `ContentProtocol.test.ets` | 119 |
| | | `LatexRiskNormalizer.test.ets` | 54 |
| | | `List.test.ets` | 18 |
| | | `LlmGuard.test.ets` | 84 |
| `D:\HMgent\MathMind\entry\src\test\` | 3 | `List.test.ets` | 7 |
| | | `LocalUnit.test.ets` | 32 |
| | | `MarkdownRendererProtocol.test.ets` | 86 |
| `D:\HMgent\MathMind\entry\src\ohosTest\ets\test\` | 2 | `Ability.test.ets` | 34 |
| | | `List.test.ets` | 4 |
| **.test.ets 总计** | **12 文件** | | **608** |

### G.2 `*.test.mjs` (Node 测试,按工具)

| 目录 | 文件数 | 测试源 |
|---|---|---|
| `D:\HMgent\MathMind\scripts\arkts-lint\tests\` | 5 (含 1 辅助 run-rule.mjs) | `parser` / `registry` / `rules-official` / `knowledge-galaxy-fixture-flag` / `llm-config-throw` |
| `D:\HMgent\MathMind\scripts\link-check\tests\` | 1 | `link-parser` |
| `D:\HMgent\MathMind\scripts\naming-lint\tests\` | 2 | `config-loader` / `rule-checkers` |
| **.test.mjs 总计** | **8 文件** | |

### G.3 测试网自陈数字 (README / onboarding 自陈)

| 数字 | 值 | 出处 |
|---|---|---|
| arkts-lint 单测 | 63/63 pass | `D:\HMgent\MathMind\scripts\arkts-lint\README.md` L3, L40 |
| onboarding 自陈总测试 | "70 unit tests across the project" | `D:\HMgent\MathMind\docs\onboarding.md` L65 |
| arkts-lint tests 命令输出 | 67 tests | `D:\HMgent\MathMind\docs\onboarding.md` L66 |
| naming-lint tests | 23 tests (8 helpers + 15 config) | `D:\HMgent\MathMind\docs\onboarding.md` L67 |
| link-check tests | 18 tests | `D:\HMgent\MathMind\docs\onboarding.md` L68 |
| AGENTS.md | "63 单元测试, CI 已接入" | `D:\HMgent\MathMind\AGENTS.md` §"项目亮点" |

---

## §H 对外信号(本地三角验证)

### H.1 README 自陈 (前 200 行摘要)

> 来源 `D:\HMgent\MathMind\README.md` (48 117B)

- **L1 项目名**: MindTrace · 数学学习助手
- **L3 仓库**: `YunC-GCT/Math-Mind`
- **L4 作者**: YunC-GCT <2549237929@qq.com>,当前主笔 Z
- **L5 最近更新**: 2026-09-01 · 全代码库架构审计 + arkts-lint v0.3 (AST) + GitHub Actions CI 已落地
- **L9-L67 W4 总结**: 完成"多 WebView 分块渲染方案", 解决 ArkUI WebView 1800vp 高度上限
  - 新增 `FormulaSplitRenderer.ets` (245 行)
  - `MathTextRenderer` 重构 (clampHeight 改为 `forceDisplay` 感知)
  - `render.html` 新增 `renderFormula` / `renderFormulaForCache` bridge
  - 4 处 UTF-8 编码乱码修复 (NotesPage / SubjectDetailPage / NoteItemMapper)
- **L60-L63 W3.5 已验证**: ContentProtocol / LatexRiskNormalizer / ContentExcerptBuilder / LlmGuard / MarkdownRendererProtocol 共 5 套单测全部通过
- **L63 限制**: 按项目约束不跑 hvigorw,DevEco Studio GUI Build / 真机滚动 / Profiler 内存峰值需手动确认
- **L189-L194 业务链路**: `AgentFloatWindow.send()` → `AgentChatService.realReply()` → `AiService.captureText()` → `Dispatcher.dispatch()` → `KnowledgeModel.structure()` → `NoteDao.insert()` → `bumpNotesVersion()`

### H.2 onboarding.md 自陈 (5-min / 30-min 摘要)

> 来源 `D:\HMgent\MathMind\docs\onboarding.md`

- **L18 比赛定位**: "鸿蒙高校创新赛 semifinal (复赛)"
- **L20-L23 模块**: 5 module (1 HAP + 4 HSP); AI pipeline 拍照 → OCR → 分类 → 结构化 → 持久化; 自研 ArkTS lint 34 规则 / 63 测试; 架构 4 层 + 5 module
- **L36-L40 1 分钟 sanity check**: `pwd` 应 `D:\HMgent\MathMind`,`git status` 应 clean,`node scripts/naming-lint/index.mjs` 应 "OK: 0 violations",`node scripts/link-check/index.mjs` 应 "OK: 0 broken links"
- **L57-L60 30-min 代码阅读**: `Dispatcher.ets` (159 行), `LlmClient.ets`, `KnowledgeModel.ets` (929 行, god class), `scripts/arkts-lint/index.mjs`
- **L65-L68 测试命令**:
  - `node --test scripts/arkts-lint/tests/*.test.mjs` → 67 tests
  - `node --test scripts/naming-lint/tests/*.test.mjs` → 23 tests
  - `node --test scripts/link-check/tests/link-parser.test.mjs` → 18 tests
- **L120-L123 CI**: `.github/workflows/arkts-lint.yml` (3 jobs: test / lint-ast / lint-regex), `naming-lint.yml` (3 jobs)

### H.3 docs/index.md 自陈 (导航摘要)

> 来源 `D:\HMgent\MathMind\docs\index.md` (5 807B)

- **L15-L31 顶层布局**: docs/{index, onboarding, style, adr, specs, research, template, agents, legacy/mindtrace/{architecture, api, competition, plans/{w3,w4}, research}}
- **L49-L56 受众路径**: agent → AGENTS.md / CONTEXT.md / naming-conventions / agents-specs / naming-lint; human → 同样; **evaluator (judges) → AGENTS.md 定位 / 5 亮点 / 5 分钟 demo / 全审计 / ADR + spec**
- **L65-L70 评委路径**: 读 AGENTS.md 顶部 → "项目亮点" 表 (5 项) → 5 分钟 demo → 审计全文 → ADR + spec → onboarding.md

### H.4 最近 30 commit 主题分布 (本地三角)

> 解析 `git log --oneline -30 --pretty=format:"%s"` (commit `5963493` → `c0e06bf`)

| 前缀 | 次数 | 性质 |
|---|---|---|
| `docs(style):` | 4 | 命名规约 / arkts-1.1 / 路径表清理 |
| `docs(agents):` | 3 | agent-glossary / git-conventions / LangGraph handoff |
| `chore(lint):` | 3 | CI workflow / --json output / naming-lint |
| `docs(research):` | 2 | LangGraph 迁移 (md + html, 332 + 442 行) |
| `docs(onboarding):` | 2 | 5/30-min guide + 路径前缀清理 |
| `docs(index):` | 2 | 修复过期路径引用 |
| 其他 | 13 | (fix(ci), feat(link-check), chore(metadata/ci/.gitignore/repo), docs(template/specs/readme/patterns/legacy/context/adr)) |

**特征观察**:
- 近 30 commit 中 **28/30 是 `docs:*` 或 `chore(lint)`/`chore(ci)`/`chore(*)`** (无 `feat:` / `fix(业务):` / `refactor:`)
- 最近一次业务 commit 仍属 `docs(index)/docs(readme)` 范畴
- 2026-09-01 审计后主线已切到"设计层 + 工具链"路径,业务实施仍 pending (与审计 §7 "Phase 4 推荐实施顺序" 一致: #4 → #5 → #3 → #7 → #10 → #9)

---

## §I 数据源路径索引(本报告引用的所有文件)

### 项目身份 / 构建
- `D:\HMgent\MathMind\AGENTS.md`
- `D:\HMgent\MathMind\CONTEXT.md`
- `D:\HMgent\MathMind\README.md`
- `D:\HMgent\MathMind\AppScope\app.json5`
- `D:\HMgent\MathMind\AppScope\resources\base\element\string.json`
- `D:\HMgent\MathMind\build-profile.json5`
- `D:\HMgent\MathMind\oh-package.json5`
- `D:\HMgent\MathMind\entry\oh-package.json5`
- `D:\HMgent\MathMind\common\oh-package.json5`
- `D:\HMgent\MathMind\agents\oh-package.json5`
- `D:\HMgent\MathMind\skill\oh-package.json5`
- `D:\HMgent\MathMind\cardservice\oh-package.json5`
- `D:\HMgent\MathMind\code-linter.json5`
- `D:\HMgent\MathMind\start_ocr_server.bat`

### 业务核心 (agents / llm / pages)
- `D:\HMgent\MathMind\agents\src\main\ets\agents\KnowledgeModel.ets`
- `D:\HMgent\MathMind\agents\src\main\ets\agents\TypeClassifier.ets`
- `D:\HMgent\MathMind\common\src\main\ets\llm\LlmClient.ets`
- `D:\HMgent\MathMind\common\src\main\ets\llm\LlmConfig.ets`
- `D:\HMgent\MathMind\common\src\main\ets\llm\LlmGuard.ets`
- `D:\HMgent\MathMind\common\src\main\ets\llm\LlmTypes.ets`
- `D:\HMgent\MathMind\common\src\main\ets\llm\LlmOutputRules.ets`
- `D:\HMgent\MathMind\entry\src\main\ets\pages\**\*.ets` (42 文件)

### 工程核心 (arkts-lint)
- `D:\HMgent\MathMind\scripts\arkts-lint\README.md`
- `D:\HMgent\MathMind\scripts\arkts-lint\index.mjs`
- `D:\HMgent\MathMind\scripts\arkts-lint\package.json`
- `D:\HMgent\MathMind\scripts\arkts-lint\parser\index.mjs`
- `D:\HMgent\MathMind\scripts\arkts-lint\ast-utils\has-decorator.mjs`
- `D:\HMgent\MathMind\scripts\arkts-lint\ast-utils\walk.mjs`
- `D:\HMgent\MathMind\scripts\arkts-lint\rules\_template.mjs`
- `D:\HMgent\MathMind\scripts\arkts-lint\rules\registry.mjs`
- `D:\HMgent\MathMind\scripts\arkts-lint\rules\official\*.mjs` (32 文件)
- `D:\HMgent\MathMind\scripts\arkts-lint\rules\project\no-get-accessor.mjs`
- `D:\HMgent\MathMind\scripts\arkts-lint\rules\project\struct-no-regular-methods.mjs`
- `D:\HMgent\MathMind\scripts\arkts-lint\tests\*.mjs` (6 文件)

### 文档层
- `D:\HMgent\MathMind\docs\index.md`
- `D:\HMgent\MathMind\docs\onboarding.md`
- `D:\HMgent\MathMind\docs\adr\*.md` (8 文件)
- `D:\HMgent\MathMind\docs\specs\*.md` (7 文件)
- `D:\HMgent\MathMind\docs\agents\*.md` (12 文件)
- `D:\HMgent\MathMind\docs\agents\patterns\*.md` (4 文件)
- `D:\HMgent\MathMind\docs\style\arkts-1.1.md`
- `D:\HMgent\MathMind\docs\style\naming-conventions.md`
- `D:\HMgent\MathMind\docs\template\*.md` (5 文件)
- `D:\HMgent\MathMind\docs\research\*.md` (2 文件)
- `D:\HMgent\MathMind\docs\legacy\mindtrace\architecture\*.md` (3 .md + 2 .html + 2 .json baseline)
- `D:\HMgent\MathMind\docs\legacy\mindtrace\api\contract.md`
- `D:\HMgent\MathMind\docs\legacy\mindtrace\competition\*.md` (2 文件)
- `D:\HMgent\MathMind\docs\legacy\mindtrace\plans\w3\*.md` (9 .md + 6 .html)
- `D:\HMgent\MathMind\docs\legacy\mindtrace\plans\w4\*.md` (3 .md + 1 .html)
- `D:\HMgent\MathMind\docs\legacy\mindtrace\research\*.md` (4 文件)

### 审计
- `D:\HMgent\MathMind\docs\legacy\mindtrace\architecture\audit-full-2026-09-01.md` (主源, §0/1/2/3/4/6/7/8/9)
- `D:\HMgent\MathMind\docs\legacy\mindtrace\architecture\audit-2026-09-01.md` (早期子集)
- `D:\HMgent\MathMind\docs\legacy\mindtrace\architecture\deep-dive-2026-09-01.md` (7 大文件深析)

### 测试
- `D:\HMgent\MathMind\agents\src\test\*.test.ets` (2)
- `D:\HMgent\MathMind\common\src\test\*.test.ets` (5)
- `D:\HMgent\MathMind\entry\src\test\*.test.ets` (3)
- `D:\HMgent\MathMind\entry\src\ohosTest\ets\test\*.test.ets` (2)
- `D:\HMgent\MathMind\scripts\arkts-lint\tests\*.mjs` (6)
- `D:\HMgent\MathMind\scripts\link-check\tests\*.test.mjs` (1)
- `D:\HMgent\MathMind\scripts\naming-lint\tests\*.test.mjs` (2)

---

## §J 数据采集口径备注

1. LOC 命令: `find <dir> -type f -name '*.ets' | xargs wc -l` (Git Bash on Windows)
2. 字节数命令: `stat -c "%s %n" <paths>` (Git Bash, 仅 .md; .html / .json 不计入)
3. git 日志命令: `git log --oneline -30 --pretty=format:"%s"` (主题行,无 SHA/作者/日期)
4. HEAD / branch / remote 命令: `git rev-parse HEAD`, `git branch --show-current`, `git symbolic-ref refs/remotes/origin/HEAD`, `git remote -v`
5. 未跑 `npm test` / `node --test` 任何套件 (研究阶段不动测试)
6. 未读 `.html` (audit 全套 HTML 渲染) — 仅参考 .md 主报告
7. `.idea/` `.worktrees/` `.zcode/` `oh_modules/` `build/` `node_modules/` `.hvigor/` 等目录排除在所有 find/stat 命令外

---FACT-GATHERING-DONE---
