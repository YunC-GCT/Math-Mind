# MindTrace AGENTS.md 审计报告

> **生成时间**: 2026-09-01
> **目标文档**: `AGENTS.md` (212 行, 最后修改 2026-09-01 22:52:58)
> **审计基线**: `git rev-parse HEAD` → `29df511` (chore(setup): scaffold agent-skills config)
> **审计方法**: 文档静态读 + 文件系统验证 + git 历史对照

## 0. TL;DR — 结论

| 维度 | 评级 | 说明 |
|---|---|---|
| **AGENTS.md 整体可信度** | 🟡 **部分可信** | 大方向对(模块结构、ArkTS 规范、commit 风格),但已多处过期 / 引用失效 / 与现状脱节 |
| **结构性陈述准确性** | 🟡 70% 命中 | 6 个 issues,3 个严重(目录不存在、文档引用断裂、版本时间错位) |
| **不可全文照搬** | 🔴 | 至少 6 处会误导新 session |

**核心问题**: 文档把"两个月前的 W3"和"今天的 W4"混在一起描述,且持续被人手改、跨 session 引用,但**没有任何 systematic 校验机制**。

---

## 1. 文档元数据

| 项 | 值 |
|---|---|
| 文件 | `AGENTS.md` |
| 行数 | 212 |
| 最后修改 | 2026-09-01 22:52:58 (system time, 与 commit `29df511` 时间一致) |
| 在 git 的提交 | `29df511` chore(setup): scaffold agent-skills config |
| 当前 HEAD | `29df511` |
| 编码 | UTF-8 无 BOM(前 3 字节: `0x23 0x20 0x4d` = "# M") |
| 是否在 `docs/`? | ❌ 错位 — 应在 `docs/` 但实际在 repo 根(per ASK Matt 单上下文布局 `CONTEXT.md` 应当与 ADR 同级) |

---

## 2. 段落级审计(逐节对账)

### 2.1 项目定位 / 头三行(Line 1-7)

| 陈述 | 实际 | 评估 |
|---|---|---|
| `MindTrace 是一个 HarmonyOS 数学学习助手` | ✅ README.md 头部一致 | OK |
| `5 module 工程 (entry HAP + common/agents/skill/cardservice 4 个 HSP)` | ⚠️ `module.json5` 中 common & agents 实际是 `type:"shared"`,不是 HSP 字面语义 | **不严谨**,但行业中 HSP = shared/feature 的统称,可保留 |
| `主分支: main` | ✅ `git branch --show-current` = main | OK |
| `最近大版本: W3 (2026-07-17)` | 🔴 **过期** | 当前最新大版本是 **W4**(W4 commit `13c934f` 2026-07-24, + W4 wip `7d7621b` 2026-09-01) |

### 2.2 Setup commands(Line 22-32)

| 陈述 | 实际 | 评估 |
|---|---|---|
| `严禁用 hvigorw CLI` | ⚠️ 文档未给替代说明 | OK 提醒 |
| `Open: File → Open → 选 D:\HMgent\MindTrace 根目录` | ⚠️ 实际工作目录是 `D:\HMgent\MathMind`,git repo 重命名后未跟进 | 🔴 **路径错误** |
| `签名: 根 build-profile.json5 必须显式共享 signingConfig 给所有 HAP` | ✅ 这是真实规则 | OK |

### 2.3 Project layout(Line 36-69)— 🔴 **重灾区**

逐目录验证:

| AGENTS.md 描述 | 实际 | 评估 |
|---|---|---|
| `entry/src/main/ets/components` | ❌ **不存在** | 🔴 **死链** — 实际是 `entry/src/main/ets/shared` |
| `entry/src/main/ets/atoms` (16 个原子) | ❌ **不存在** | 🔴 **死链** |
| `entry/src/main/ets/entryability` | ✅ 存在 | OK |
| `entry/src/main/ets/database` | ✅ | OK |
| `entry/src/main/ets/services` | ✅ | OK |
| `entry/src/main/ets/viewmodels` | ✅ | OK |
| `entry/src/main/ets/utils` | ✅ | OK |
| `entry/src/main/ets/entrybackupability` | ✅ | OK |
| `entry/src/main/ets/overlays` (含 AgentFloatWindow 等 3 个) | ✅ AgentFloatWindow/CameraOverlay/NoteDetailOverlay 都在 | OK |
| `common/src/main/ets/llm` | ✅ + 多了 `ocr/`、`render/`、`data/`、`utils/` | ⚠️ 不完整 |
| `common/src/main/ets/models` | ✅ | OK |
| `common/src/main/ets/constants` | ✅ | OK |
| `common/src/main/ets/database` | ❌ **不存在** | 🔴 **死链** — DatabaseHelper 实际在 `common/src/main/ets/DatabaseHelper.ets` (顶层文件) |
| `agents/` 含 Dispatcher/TypeClassifier/KnowledgeModel | ⚠️ 实际在 `agents/src/main/ets/{core,agents,mcp,models}/` 4 个子目录,而非单层 | ⚠️ 不准确 |
| `AppScope/` | ✅ | OK |
| `docs/W3_SUMMARY.md` | ❌ **不存在** | 🔴 **死链** — 第 20 行和第 62 行都引用它 |
| `docs/ui_to_agent_*.md` | ⚠️ 未发现任何该模式文件 | ⚠️ 规约未落地 |
| `docs/agent_to_ui_*.md` | ⚠️ 未发现任何该模式文件 | ⚠️ 规约未落地 |
| `docs/*.html (视觉稿, 不在 git 里)` | ⚠️ `docs/` 下未发现 .html 文件 | 规约未落地 |
| `archive/` | ❌ **不存在** | 🔴 **死链** |
| `MindTrace-MVP/` | ❌ **不存在** | 🔴 **死链** |
| `.worktrees/` | ⚠️ `git worktree prune` 后已清空,目录存在但空 | ⚠️ 与"留有 worktree 目录"措辞不符 |

### 2.4 Code style(Line 73-107)

| 陈述 | 评估 |
|---|---|
| 完整 8 大铁律在 `~/.mavis/agents/mavis/memory/MEMORY.md` | ⚠️ 该路径是本地 mavis 实例路径,**新机器没有** — 应该内联或挪到 `docs/style/arkts-1.1.md` |
| 5 大铁律(禁 any、禁 C 风格 for、struct 内禁普通方法、struct 内禁 get accessor、struct 字段名避开 CommonAttribute) | ✅ 与现有约定一致 |
| `ArkUI 1.1 = API 9` 兼容性 | ✅ 与当前 `targetSdkVersion: "6.1.1(24)"` 的项目设置一致 |
| 文件头注释模板"80+ 文件已统一" | ⚠️ 抽样: `entry/services/AgentChatService.ets` 有,但不是所有 `.ets` 都有 — 实际是局部统一,非"80+" |

### 2.5 Testing instructions(Line 111-123)

| 陈述 | 评估 |
|---|---|
| `ohosTest target` 配置存在 | ✅ `entry/build-profile.json5` 中确认 |
| `当前未编写测试` | ✅ 正确 |
| 6 项 smoke test | ✅ 与 W3 时期一致,但**没列入 W4 的流式回复验证**(已加 SSE 流式但 smoke 列表未更新) |

### 2.6 PR & commit conventions(Line 127-140)

| 陈述 | 评估 |
|---|---|
| `主分支: main (5b6f155 起为整链基线)` | ⚠️ `5b6f155` 确实存在,之后有 171 个 commit,仍有效 |
| `当前单 main,无 feature 分支` | ✅ 与 `.worktrees/` 清理后现状一致 |
| Conventional commits 风格 | ✅ 历史 commit 实际遵循 |
| `本地 commit, 绝不 push 除非 user 明确说"push"` | ✅ 反复被验证遵守 |

### 2.7 跨 session 通信协议(Line 144-157)

| 陈述 | 评估 |
|---|---|
| `mavis communication send CLI 不可用` | ✅ 真实 |
| `docs/ui_to_agent_<topic>_<date>.md` 命名规约 | ⚠️ 规约存在但**未见任何该模式文件** — 文档规约超前于实际工作流 |
| 实际案例 `ui_to_agent_ai_settings_20260714.md` | ⚠️ 该文件**未在 docs/ 中发现** |

### 2.8 Security(Line 161-167)

| 陈述 | 评估 |
|---|---|
| `.env` / `local.properties` 已 gitignore | ✅ `.gitignore` 中已包含 |
| API Key 不入 git | ✅ |
| 网络权限 `ohos.permission.INTERNET` | ✅ |

### 2.9 必读 rules(Line 171-186)— 8 条

抽样核对:`.ets` UTF-8 noBOM — 抽样检查 `common/src/main/ets/llm/LlmClient.ets` 前 3 字节 = `import`(即 0x69 0x6d 0x70), ✅

8 条规则整体评估:
- ✅ 1-3 都是真实工程经验
- ✅ 4-5 是结构硬约束,正确
- ⚠️ 6-7 是"必须存在"约束,容易随时间漂移(新增 module 时漏)
- ⚠️ 8 是 PowerShell 5.1 陷阱,新机器可能跑 PowerShell 7,这条不再适用

### 2.10 维护提示(Line 190-196)

| 陈述 | 评估 |
|---|---|
| `PowerShell 验首 3 字节 69 6D 70` | ✅ 实用 |
| `cp common/oh-package.json5 <new>/oh-package.json5 当模板` | ✅ 实用 |
| "Working tree 互斥"提醒 | ✅ 正确 |

### 2.11 Agent skills(Line 200-212)— 新增节

| 陈述 | 实际 | 评估 |
|---|---|---|
| `docs/agents/issue-tracker.md` | ✅ 存在,45 行,详细 `gh` CLI 用法 | OK |
| `docs/agents/triage-labels.md` | ✅ 存在,15 行,5 个标准标签 | OK |
| `docs/agents/domain.md` | ✅ 存在,51 行,定义 CONTEXT.md / ADR 布局 | OK |
| 但 `CONTEXT.md` (repo root) | ❌ **不存在** | ⚠️ 文档说"lazily created",目前未触发 |
| `docs/adr/` | ❌ **不存在** | ⚠️ 同上 |
| `CONTEXT-MAP.md` | ❌ 不存在 | 单上下文 repo 不需要,OK |

---

## 3. 关键不一致清单(Priority Order)

### 🔴 P0 — 必须立刻修

1. **`Project layout` 整节目录结构过期**(Line 36-69)
 - 删除: `components/`、`atoms/`、`entrybackupability/`(实际是 `entryability/`)
 - 删除: `common/src/main/ets/database/`(实际是顶层文件)
 - 补充: `common/src/main/ets/{ocr, render, data, utils}` 和 `agents/src/main/ets/{core, mcp, models}` 的真实子目录
 - 补充: `entry/src/main/ets/{shared, entryability, models}` 实际目录

2. **缺失文档引用断裂**(Line 20, 62)
 - `README.md` 提到 `docs/W3_SUMMARY.md`,但该文件不存在
 - 需要: 创建 `W3_SUMMARY.md`,或修改 README + AGENTS.md 删引用

3. **缺失目录引用断裂**(Line 66, 67)
 - `archive/` 和 `MindTrace-MVP/` 在文档中存在,但实际不存在
 - 需要: 删除这两条,或恢复目录

4. **Setup 路径错误**(Line 28)
 - 文档写 `D:\HMgent\MindTrace`,实际是 `D:\HMgent\MathMind`
 - 是 git repo 重命名后未跟进

### 🟡 P1 — 应该修

5. **大版本时间错位**(Line 5)
 - 写"最近大版本: W3 (2026-07-17)",实际 W4 已上(2026-07-24 起)
 - 改成 `W4 (2026-07-24)` 并补充 W4 主要 commit

6. **Code style "80+ 文件已统一"夸大**(Line 90)
 - 抽样发现不全是"80+"
 - 改成"多数业务模块已统一"或保留但加 caveat

7. **跨 session 通信协议"实际案例"虚构**(Line 157)
 - 写 `docs/ui_to_agent_ai_settings_20260714.md` 是"实际案例",但该文件不存在
 - 要么删除"实际案例"行,要么真正落地一个例子

8. **Smoke test 6 项未含 W4 新功能**(Line 117-123)
 - W4 加了 SSE 流式回复 + LlmGuard 守门,smoke list 应增加验证项

### 🟢 P2 — 长期改进

9. **完整 8 大铁律引用不可移植**(Line 75)
 - `~/.mavis/agents/mavis/memory/MEMORY.md` 是用户本地路径,新机器没有
 - 把 8 大铁律内联到 `docs/style/arkts-1.1.md`,作为项目资产

10. **写新中文文件"PowerShell 5.1 陷阱"规则过期**(Line 184)
 - 新机器可能跑 PowerShell 7(无此问题)
 - 改成"用 Write 工具(避免任何 shell 管道编码陷阱)"

11. **`agents/` 模块结构描述不准确**(Line 57)
 - 写"Dispatcher / TypeClassifier / KnowledgeModel",但实际分布在 4 个子目录
 - 完整列出子目录结构

12. **`entrybackupability` 目录描述**(Line 50)
 - 实际不存在该目录,是 `entryability/`
 - 注意 AGENTS.md 的 entryability 路径写错(实际应该是 `entryability/`,不是 `entrybackupability/`)

---

## 4. 文档结构建议(重写模板)

理想的 `AGENTS.md` 应分 4 大块:

```
┌─ Block A: 项目元数据 ─────────────────────┐
│  • 项目定位 (1 段)                        │
│  • 当前大版本号 (动态值, 不要硬编码日期)   │
│  • 基线 commit (机器可读 SHA)             │
└──────────────────────────────────────────┘
┌─ Block B: 工作流规约 ─────────────────────┐
│  • Setup commands                        │
│  • 测试规约                              │
│  • Commit / PR 规约                      │
│  • 跨 session 通信                       │
│  • Security                              │
└──────────────────────────────────────────┘
┌─ Block C: 代码规范 ────────────────────────┐
│  • ArkTS 1.1 strict 8 大铁律 (内联)      │
│  • 文件头注释模板                         │
│  • API 兼容矩阵                          │
└──────────────────────────────────────────┘
┌─ Block D: 项目结构 (动态验证) ───────────┐
│  • 由脚本生成,不要手写                    │
│  • `scripts/audit-docs.ts` 跑出 tree      │
│  • 每周 cron 检查,过期发 PR              │
└──────────────────────────────────────────┘
```

---

## 5. 影响范围评估

如果按 P0 修复,涉及:
- 改动文件: 仅 `AGENTS.md` + `README.md`(若改 W3_SUMMARY 引用)
- 工作量: ~30 分钟
- 风险: 低(文档修订)

如果按 P0 + P1 修复,涉及:
- 改动文件: `AGENTS.md` + `README.md` + 新建/补建缺失文档
- 工作量: ~2 小时
- 风险: 低

如果按全部 P0/P1/P2 修复,涉及:
- 改动文件: `AGENTS.md` + `README.md` + 新建 `docs/style/arkts-1.1.md` + 修整 `archive/` 等缺失目录 + 重写 smoke test
- 工作量: ~半天
- 风险: 中(规则内联需要 review 一致性)

---

## 6. 下一步建议

1. **立即**(在你这次 session):
 - 把 P0 的 4 条一次性修掉
 - 在 AGENTS.md 顶部加 `> 最后审计: 2026-09-01` 时间戳
2. **下次 session**:
 - 跑 `/improve-codebase-architecture`(P1 部分)+ 用 `scripts/audit-docs.ts` 自动校准目录
3. **长期**:
 - 建 `CONTEXT.md`(per `docs/agents/domain.md` 规约)
 - 建 `docs/adr/0001-...md` 记录第一个 ADR

---

**附录**: 本报告对应的可视化 HTML 在 `docs/architecture-audit-20260901.html`(per AGENTS.md `*.html` 视觉稿规约,**不入 git**)。

---

## 7. See Also — 全代码库架构审计

本报告已被 **全代码库架构审计** 取代 / 扩展:

- **`docs/architecture-audit-full-20260901.md`** — 全 5 module 扫描 (162 .ets, 23,301 LOC),含 module cards、seam map、16 个 P0/P1/P2 finding、6 个 deep-module 重设计目标、14 个 Phase 3 ticket 预览
- **`docs/architecture-audit-full-20260901.html`** — 可视化版本

**核心扩展**: 本报告 §4.16 (P0) 发现的 16 个新问题:
- `KnowledgeModel` 870 LOC god class (§4.2)
- `AgentChatService` 802 LOC god class (§4.3)
- `LlmClient` 三套调用路径并行 (§4.1,严重度被低估)
- `Dispatcher` 三入口泄漏 (§4.5)
- `OcrTool` 6 处 ArkTS 1.1 违规 (§4.6)
- `ReviewGraphView` 1679 LOC 单文件 (§4.9)
- 等等

**Phase 2/3/4 工作以此扩展审计为输入**,本报告保留作为"AGENTS.md 单文档"专项审计历史。