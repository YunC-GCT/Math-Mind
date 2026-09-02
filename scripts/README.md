# scripts/ — MindTrace Lint Job

> **目的**: 静态扫描全代码库的 `.ets` 文件, 把违反 ArkTS 1.1 strict 规则 + MindTrace 项目偏好的代码标出来, 让 CI 在合入前 fail。
>
> **权威规则定义**: [`docs/style/arkts-1.1.md`](../docs/style/arkts-1.1.md) — 40+ 条官方 rule ID + error code
>
> **审计依据**: [`docs/architecture-audit-full-20260901.md`](../docs/architecture-audit-full-20260901.md) §4.17 / §4.18 / §4.19
>
> **关联**: Phase 4 ticket #15

## 两套实现

| 实现 | 入口 | 引擎 | 状态 |
|---|---|---|---|
| **v1 (regex)** | `node scripts/audit-arkts-strict.mjs` | 正则 | ✅ 稳定, 25 规则, 174 文件 baseline 0 errors / 285 warnings (≈80% 误报) |
| **v2 (AST)** | `node scripts/arkts-lint/index.mjs` | `@typescript-eslint/parser` | 🟡 PoC, 1 规则, 88% 文件可解析 |

详见 [`scripts/arkts-lint/README.md`](./arkts-lint/README.md) (待 v2 成熟后建).

---

## 快速开始

```bash
# 默认扫 process.cwd() 下所有 .ets 文件 (含 entry/common/agents/skill/cardservice)
node scripts/audit-arkts-strict.mjs

# 仅打印汇总, 不打印每条违规
node scripts/audit-arkts-strict.mjs --quiet

# 输出 JSON (供 CI 解析)
node scripts/audit-arkts-strict.mjs --json > lint-result.json

# 把 baseline 写到 docs/lint-baseline-20260901.json (含全部违规详情)
node scripts/audit-arkts-strict.mjs '--baseline=docs/lint-baseline-20260901.json'

# 扫指定根
node scripts/audit-arkts-strict.mjs --root=entry
```

退出码:
- `0` = 无 **error** 级违规 (CI ✅)
- `1` = 至少一条 **error** 级违规 (CI ❌)

**warn** 级违规不阻断 build, 但建议修。

---

## 严重度分级

| 级别 | 来源 | 行为 |
|---|---|---|
| **error** | ArkTS 1.1 strict 官方规则 | 触发退出码 1, CI 失败 |
| **warn** | MindTrace 项目偏好 / 难以纯正则检测的规则 | 仅报告, 不阻断 |

示例:
- `arkts-no-any-unknown` (error) — 用 `any`/`unknown` 触发编译错误
- `ArkUI-1 struct-no-regular-methods` (warn) — 项目偏好, ArkTS 官方允许

---

## 当前规则集 (v1, 25 条)

### 官方 strict-mode (error, 20)

按 `docs/style/arkts-1.1.md` 6 大组分类:

**类型系统 (5)**: `arkts-no-any-unknown`, `arkts-as-casts`, `arkts-no-is`, `arkts-no-intersection-types`, `arkts-no-mapped-types`
**控制流 (3)**: `arkts-no-for-in`, `arkts-no-with`, `arkts-no-delete`
**变量声明 (4)**: `arkts-no-var`, `arkts-no-private-identifiers`, `arkts-no-symbol`, `arkts-no-types-in-catch`
**类与对象 (5)**: `arkts-no-func-expressions`, `arkts-no-class-literals`, `arkts-no-jsx`, `arkts-no-generators`, `arkts-implements-only-iface`
**模块与函数 (3)**: `arkts-no-nested-funcs`, `arkts-limited-throw`, `arkts-no-destruct-assignment` / `no-destruct-decls` / `no-destruct-params`

### 项目偏好 (warn, 5)

- `ArkUI-1 struct-no-regular-methods` — struct 内禁用普通方法 (项目偏好)
- `ArkUI-2 no-get-accessor` — struct 内禁 get accessor (项目偏好)
- `arkts-no-props-by-index` — `obj['key']` 动态属性访问 (项目偏好, 但 JSON 解析场景下不可避免)
- `arkts-no-comma-outside-loops` — **当前禁用**, 正则难处理嵌套括号 (见 §已知限制)
- `arkts-no-method-reassignment` — **当前禁用**, 字段赋值与"方法重赋值"难区分

---

## Baseline (2026-09-01)

`docs/lint-baseline-20260901.json` 是首次运行的快照:

| 指标 | 值 |
|---|---|
| 扫描文件 | 174 `.ets` |
| **Errors** | **0** ✅ |
| Warnings | 285 |
| Top 警告 | `ArkUI-1 struct-no-regular-methods` × 216 (确认 audit §4.9/§4.10) |
| Top 警告 | `arkts-no-props-by-index` × 69 (JSON 解析场景,audit §4.21 关联) |

**含义**: 当前 CI 可直接接入 (0 errors)。**215 个 ArkUI-1 警告** 是已知技术债, 与 audit §4.9 (ReviewGraphView 1880 LOC god file) + §4.10 (KnowledgeGalaxyViewModel 789 LOC god class) 一致 — 这些方法都该重构成箭头函数字段。

---

## 接入 CI (示例)

```yaml
# .github/workflows/ci.yml (示意)
- name: ArkTS 1.1 strict lint
  run: node scripts/audit-arkts-strict.mjs --quiet
  # exit 1 → job 红 → 必须修
```

```json5
// hvigor/build-profile.json5 (示意, HarmonyOS 原生集成)
{
  "tasks": {
    "lint:arkts": {
      "exec": "node scripts/audit-arkts-strict.mjs --quiet",
      "inputs": ["./entry/src/main/ets/**/*.ets", "./common/src/main/ets/**/*.ets"],
      "outputs": []
    }
  }
}
```

---

## 已知限制 (v1)

**v1 是基于正则的扫描, 不是 AST 解析**。已知局限:

1. **`.ets` 文件 UTF-8 noBOM**: UTF-16 BOM 会让正则误判文件起点 — 已在 `README/AGENTS.md` 提醒 Write 工具创建
2. **字符串字面量内的关键字**: `"any"` 字符串里的 `any` 会被误报 — 已知 false positive, 待 v2 加字符串感知
3. **嵌套括号**: `arkts-no-comma-outside-loops` 难处理 `.scale({ x: 1, y: 2 })` 这种 obj literal — 当前禁用
4. **方法 vs 字段**: `arkts-no-method-reassignment` 无法区分 `this.dao = new XDao()` (字段) 和 `this.handler = () => {}` (方法) — 当前禁用
5. **`struct` vs `class`**: ArkUI-1 规则无法区分 `@Component struct { } }` 和 `class { } }`, 所以会误报 plain class 的方法 — 已知限制
6. **Unicode / 中文字符串**: 中文在正则边界判断中可能误判

**v2 计划** (Phase 4 ticket #15 后续):
- 接入 ArkTS 官方 parser (AST)
- 实现 strict-mode 全 40+ 条规则
- 区分 `struct` vs `class` (基于 `@Component` 装饰器)
- 处理嵌套括号 + 字符串字面量上下文
- 增量改进 (vs v1 全量重写)

---

## 维护 (详细流程)

> **核心原则**: 任何 agent 修改 lint 规则后,**必须保持 exit code 0** (baseline 不能再产生 error), 否则 CI 会被自己的 lint 工具卡住。

### 新增规则 (发现新应禁用的模式时)

```bash
# 1. 编辑 scripts/audit-arkts-strict.mjs, 在 RULES 数组加 entry
#    模板:
#    {
#      id: 'arkts-xxx-yyy',
#      code: '10605xxx',
#      severity: 'error',           // 或 'warn' (项目偏好)
#      title: '...',
#      pattern: /.../g,
#      exclude: line => /.../.test(line),  // 必须: 过滤 // 注释 + 字符串字面量
#      fixHint: '...',
#      enabled: true,              // 默认 true; false = 禁用但保留
#    }
#
# 2. (可选) 在 docs/style/arkts-1.1.md 加规则到对应组, 让人类读者也能找到
#
# 3. 跑验证
node scripts/audit-arkts-strict.mjs --check-rules   # 验证所有规则定义合法
node scripts/audit-arkts-strict.mjs --quiet         # 跑全量, 必须 exit 0
#
# 4. 如有 false positive, 调整 pattern 或 exclude, 重跑
#
# 5. 更新 baseline
node scripts/audit-arkts-strict.mjs '--baseline=docs/lint-baseline-20260901.json'
```

### 禁用规则 (false positive 太多)

```javascript
// 在 RULES 数组的对应 entry 加 `enabled: false`:
{
  id: 'arkts-no-method-reassignment',
  enabled: false,  // 2026-09-01: 11 误报 (this.dao = new XDao()), 待 AST 升级
  // ... 其余字段保留作文档
}
```

禁用而非删除 — 保留 entry 作为对未来 AST 版的提示。

### 修复 false-positive (单条规则)

```bash
# 1. 跑全量, 找到具体误报
node scripts/audit-arkts-strict.mjs | grep <rule-id>

# 2. 修改 RULES 数组中该规则的 pattern 或 exclude 函数
#    pattern 修改建议:
#    - 加 \b 词边界
#    - 加 (?<![...]) lookbehind 排除上下文
#    - 加 ^ 行首限制
#    exclude 修改建议:
#    - 加 /^\s*\/\// 行注释
#    - 加 /\.ets['"]/ 路径字符串
#    - 加 /["'].*[\b关键字\b].*["']/ 字符串字面量

# 3. 验证 (目标: 误报数减少, baseline 不变/变好)
node scripts/audit-arkts-strict.mjs --quiet
```

### 同步官方文档 (ArkTS 新版/新规则)

```bash
# 1. 看官方 https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-migration-background 有无新规则
#    (子代理调研笔记: docs/research/huawei-arkui-agent-20260901.md §3.2 当前有 42 条)

# 2. 如有更新, 在 docs/style/arkts-1.1.md 加新 rule ID + 在 scripts/audit-arkts-strict.mjs RULES 加 entry

# 3. 重新跑 baseline
node scripts/audit-arkts-strict.mjs '--baseline=docs/lint-baseline-<date>.json'

# 4. 提交 PR (含 docs/style + scripts + baseline + 解释的 commit message)
```

### 自检 (`--check-rules`)

```bash
node scripts/audit-arkts-strict.mjs --check-rules
# 验证所有 RULES entry:
# - pattern 是合法 RegExp
# - severity 是 'error' 或 'warn'
# - id 唯一
# - code 格式正确 (10605xxx 或 'project-pref')
# - fixHint 非空
# - exclude 是函数 (如果定义)
# 输出:
#   ✓ 25 rules valid
# 或:
#   ✗ 2 errors:
#     [arkts-xxx] id 已存在
#     [arkts-yyy] pattern 无效: SyntaxError
```

### 维护时容易踩的坑

1. **修改 pattern 后 exit code 不再是 0** — 检查新规则是否匹配了已有代码 (用 `--quiet` 跑全量看)
2. **删除 enabled:false 的 entry** — 保留! 注释清楚禁用原因, 留给 v2 AST 升级参考
3. **直接编辑 baseline JSON** — 不要! 永远用 `--baseline=...` 重生成
4. **pattern 加 /g flag 但 lastIndex 不重置** — `matchAll()` 已自动管理, 不需要手动 reset
5. **exclude 写得过于宽松** — 漏报; 过严 — 误报; 多测几种真实代码 line
6. **忘了同步 docs/style/arkts-1.1.md** — 人类读者 + 其他 agent 都看那里; lint 与文档必须一致

---

## 关联文档

- [`docs/style/arkts-1.1.md`](../docs/style/arkts-1.1.md) — 规则权威定义 (40+ 条全表)
- [`docs/architecture-audit-full-20260901.md`](../docs/architecture-audit-full-20260901.md) — 审计报告 (215 个 ArkUI-1 警告与 §4.9/§4.10 god class 对应)
- [`docs/audit-deepdive-20260901.md`](../docs/audit-deepdive-20260901.md) — 大文件深读 (§F1-§F7)
- [`AGENTS.md`](../AGENTS.md) — Code style 节已引用 lint
- Phase 4 ticket #15 (规划)