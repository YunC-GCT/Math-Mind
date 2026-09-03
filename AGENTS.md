# MindTrace — AGENTS.md

> **鸿蒙高校创新赛 · 复赛项目** — HarmonyOS 数学学习助手 (拍照 / OCR / AI 分类 / 知识结构化 / 复习 全链)
> 5 module: `entry` (HAP) + `common` / `agents` / `skill` / `cardservice` (4 HSP)
> **DevEco Studio 唯一开发入口** (Windows 中文路径禁 hvigorw CLI)
> 主分支: `main` · 最新版本: W4 (2026-07-24 起) · 最后审计: 2026-09-01
> 项目根: **`D:\HMgent\MathMind`** (不是 `MindTrace`, 大小写敏感)

---

## 改什么 → 读哪 (必读指针)

| 改 / 触发什么 | 读哪 (按顺序) |
|---|---|
| 第一次接项目 / 写新代码前 | [`CONTEXT.md`](./CONTEXT.md) → [`docs/style/arkts-1.1.md`](./docs/style/arkts-1.1.md) |
| 改业务逻辑 / 改设计 | [`docs/adr/`](./docs/adr/) (先查 why) → [`docs/specs/`](./docs/specs/) (查 how) |
| 改 .ets 合规 / 风格 | [`docs/style/arkts-1.1.md`](./docs/style/arkts-1.1.md) (40+ 规则) |
| 写测试 / 加测试 | [`docs/specs/`](./docs/specs/) §"Test plan (TDD)" + `scripts/arkts-lint/tests/` 模板 |
| 改 .ets 文件头 / 模块结构 | [`docs/agents/file-header-template.md`](./docs/agents/file-header-template.md) |
| 改 git workflow / commit / branch | [`docs/agents/git-conventions.md`](./docs/agents/git-conventions.md) |
| 改 lint 规则 / lint 输出 | [`scripts/arkts-lint/`](./scripts/arkts-lint/) + [`docs/agents/api-version.md`](./docs/agents/api-version.md) §"Lint job" |
| 改 API 版本兼容 | [`docs/agents/api-version.md`](./docs/agents/api-version.md) |
| 改安全 / secrets / 签名 | [`docs/agents/security.md`](./docs/agents/security.md) |
| 准备 PR / smoke test | [`docs/agents/smoke-test.md`](./docs/agents/smoke-test.md) |
| 排查 build / 编码陷阱 | [`docs/agents/file-header-template.md`](./docs/agents/file-header-template.md) §"创建新文件" |
| 写 / 改 / 归档 doc | [`docs/agents/issue-tracker.md`](./docs/agents/issue-tracker.md) (issue 模板) + `docs/agents/domain.md` (workflow) |
| 写 issue / 改 spec | [`docs/agents/issue-tracker.md`](./docs/agents/issue-tracker.md) + [`docs/agents/triage-labels.md`](./docs/agents/triage-labels.md) |
| 排查 audit finding | [`docs/architecture/audit-full-2026-09-01.md`](./docs/architecture/audit-full-2026-09-01.md) |
| 整体目录结构 | `docs/architecture/audit-full-2026-09-01.md` §3 |

---

## 必守红线 (7 条, 不可逾越)

1. **不 push** — 未经 user 明确说 "push", 绝不 `git push`。"提交" = local commit
2. **不 build** — `Build Hap(s)/APP(s)` 由 user 跑; AI 做本地 commit + 验证测试, 不跑 build
3. **不 overwrite** — user 手动编辑过的 plan / file, **不整段覆盖**; 先 read 最新版, 优先 append
4. **绝对路径** — 根目录 = `D:\HMgent\MathMind` (不是 `D:\HMgent\MindTrace`)
5. **commit 规范** — conventional commits + 模块前缀 (`docs(frontend):` / `fix(agents):`); 详见 [`docs/agents/git-conventions.md`](./docs/agents/git-conventions.md)
6. **不进 `main`** — 所有改动 commit 到 `YunCeH`, user 手动 review + merge
7. **worktree 互斥** — 多 session 共享同一 worktree 时, 一个 session 改时另一个别动; 多 worktree 用 `YunCeH` 分支同步

---

## 比赛定位 & 演示流程

### 项目亮点 (展示给评委)

| 亮点 | 位置 | 说明 |
|---|---|---|
| **AI 智能分类 + 知识结构化** | `agents/src/main/ets/agents/` | 5 类题型识别 + KnowledgeUnit 拆解, 端到端 LLM pipeline |
| **LlmClient 流式响应 (W4 新)** | `common/src/main/ets/llm/LlmClient.ets` | 3 调用路径待合一, spec [`005`](./docs/specs/005-llm-client-consolidation.md) |
| **知识星系可视化** | `entry/src/main/ets/pages/KnowledgeGalaxy*` | 用户学情可视化 |
| **ArkTS 严格 lint 引擎** | `scripts/arkts-lint/` | 自研 AST 引擎, 34 规则 + 63 单元测试, **CI 已接入** |
| **审计 + ADR + Spec 完整设计层** | `docs/architecture/` + `docs/adr/` + `docs/specs/` | 7 ADR + 6 ticket spec, 设计透明度高 |

### 演示路径 (5 分钟 walk-through)

1. 启动 OCR 服务 (`python -m uvicorn ocr.app:app --port 8000`)
2. DevEco Studio `Run → Run 'entry'` (真机/模拟器)
3. 主流程: 拍照 → OCR → AI 分类 → 知识结构化 → 持久化 → 复习浮窗对话 (SSE 流式)
4. 5 Tab 流畅 / 知识星系无 "示例:*" 假学科 (ticket #16 已修)
5. 源码: `agents/` (AI 业务) + `scripts/arkts-lint/` (工程亮点) + `docs/architecture/audit-full-2026-09-01.md` (21 个 finding 的架构审计)

### 状态 (per audit 2026-09-01)

✅ 已修: **#15** ArkTS 铁律 (规约错误) · **#9** LlmConfig 静默覆盖 (TDD) · **#16** fixture data 泄漏 (TDD)
🟡 待修: **#1** doc expiry · **#3** / #4 / #5 / #7 god class & 入口泄漏 (有 spec, 待实施) · **#10** mcp/ → tools/ rename

详细: [`docs/architecture/audit-full-2026-09-01.md`](./docs/architecture/audit-full-2026-09-01.md) §7 + [`docs/specs/`](./docs/specs/)

---

## 关键架构 (30 秒读懂)

| 层 | 位置 | 责任 |
|---|---|---|
| UI | `entry/pages/`, `entry/overlays/` | 渲染 + 用户输入 |
| View Model | `entry/viewmodels/` | UI state + 用户意图 |
| Business Service | `entry/services/` | 编排, **不持 UI 引用** |
| **AI Agent (亮点)** | `agents/` | `Dispatcher` (主) + `TypeClassifier` / `KnowledgeModel` (子) |
| Data + Infra | `common/` | `LlmClient` / `LlmGuard` / `ContentProtocol` / RDB 单例 |

**关键 seam**: `AiService.capture → Dispatcher.dispatch → KnowledgeModel.structure → LlmClient.call → LlmGuard`; 全部 Markdown 走 `ContentProtocol` (MM-MD-v1)

**5 module 拓扑**: 1 HAP (`entry`, `type:entry`) + 4 HSP (`common` / `agents` / `skill` / `cardservice`, `type:feature`); 跨 module import 必须完整路径

**已废弃 (不要新建)**: ~~`components/`~~ ~~`atoms/`~~ ~~`archive/`~~ ~~`MindTrace-MVP/`~~ ~~`common/src/main/ets/database/`~~ (顶层) ~~`docs/W3_SUMMARY.md`~~

---

## 常用命令 (Windows / DevEco Studio)

**严禁 hvigorw CLI** (Windows 中文路径下 NODE_HOME/PATH 乱码, 已实测)。

| 任务 | 命令 |
|---|---|
| Open 项目 | DevEco `File → Open → D:\HMgent\MathMind` (**不是** MindTrace) |
| Build / Run / Sync | DevEco GUI (`Build → Build Hap(s)/APP(s)`, `Run → Run 'entry'`) |
| 启动 OCR 服务 | `python -m uvicorn ocr.app:app --port 8000` |
| 跑 arkts-lint 测试 | `npm --prefix scripts/arkts-lint test` (70 测试) |
| 跑 v0.3 lint 扫描 | `node scripts/arkts-lint/index.mjs --quiet` |
| 创建新 module | `cp common/oh-package.json5 <new>/oh-package.json5` (必须含 `main` 字段) |
| 验 .ets 无 BOM | PowerShell: `[System.IO.File]::ReadAllBytes(path)[0..2]` (应为 `0x69 0x6D 0x70`) |

---

## Agent skills 索引

| Skill | 说明 | 详细 |
|---|---|---|
| **CONTEXT.md** | 项目专属词汇 (19 个术语, 4 种 "agent" 消歧) | [`CONTEXT.md`](./CONTEXT.md) |
| **ADR** | 架构决策记录 (7 个) | [`docs/adr/`](./docs/adr/) |
| **Ticket specs** | 依 ADR 写的实施 spec (6 个) | [`docs/specs/`](./docs/specs/) |
| **Issue tracker** | GitHub Issues on `YunC-GCT/Math-Mind`, via `gh` CLI | [`docs/agents/issue-tracker.md`](./docs/agents/issue-tracker.md) |
| **Triage labels** | 5 标签: `needs-triage` / `needs-info` / `ready-for-agent` / `ready-for-human` / `wontfix` | [`docs/agents/triage-labels.md`](./docs/agents/triage-labels.md) |
| **TDD / domain-modeling** | 按需调 skill, 不强制 | (内置 skill) |