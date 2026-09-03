# API 版本兼容 & ArkTS strict 适配

## 当前版本

- `compileSdkVersion` / `compatibleSdkVersion` = **9** (ArkUI 1.1)
- ⚠️ **API 9 下 ArkTS strict 规则只警告不报错** — 升级到 ≥10 才进入"标准模式"

## ArkTS 1.1 strict 完整规则

**40+ 规则表 (含 rule ID + error code + 代码示例 + 验证命令)** 见 [`docs/style/arkts-1.1.md`](../style/arkts-1.1.md) (2026-09-01 从子代理调研笔记 §3.2 抽出)。

主要分组 | 关键规则 | Error code |
|---|---|---|
| 类型系统 | `any` / `unknown` 禁; 结构 / mapped / conditional / intersection 禁; `<T>x` 禁 (用 `as`); catch 不能 typed | 10605xxx |
| 控制流 | `for..in` 禁; 解构赋值/声明/参数 禁; `var`/`#private`/`function` 表达式/`with`/`delete`/`class` 表达式/嵌套函数/generator 禁 | 10605xxx |
| 对象与类 | `obj['key']` 动态属性禁; 类只能 `implements interface`; `this` 类型禁 | 10605xxx |
| ArkUI 项目偏好 (严格于官方) | struct 内禁普通方法 (用箭头函数字段 / `@Builder`); struct 内禁 `get` accessor; struct 字段名避开 CommonAttribute 方法名 | project-pref |

## Lint job 现状 (强制执行)

| Lint 引擎 | 规则数 | Baseline | 详细 |
|---|---|---|---|
| v1 (regex) | 25 规则 | 0 errors / 285 warnings | [`scripts/audit-arkts-strict.mjs`](../../scripts/audit-arkts-strict.mjs) |
| v0.3 AST (推荐) | **34 规则 + 63 单元测试** | 0 errors / **253 warnings** (90 个是 fix 后的真问题,对应 audit §4.9/§4.10 god-class) | [`scripts/arkts-lint/`](../../scripts/arkts-lint/) + CI |

CI 已接入: [`.github/workflows/arkts-lint.yml`](../../.github/workflows/arkts-lint.yml)

## API 11+ 才有的特性 (当前**不能用**)

| 特性 | API | 备注 |
|---|---|---|
| `.stateStyles()` 基础态 | API 7 ✓ | 可用 |
| `.stateStyles()` `selected` 子态 | API 10+ ⚠ | 不能用 |
| `.blur()` / `visualEffect` / `backgroundFilter` | API 12+ ⚠ | 不能用 |
| `@kit.ArkTS.JSON` 模块 | API 12+ ⚠ | 用 built-in `JSON` |
| `@ComponentV2` / `@Local` / `@Param` / `@ObservedV2` / `@Trace` | API 12+ ⚠ | 用 V1 装饰器 |

## API 用法注意

- `Image.rotate({ angle })` 接**对象** (`{angle: number}`),不是 number
- ArkUI 1.1 默认响应 `@State`,`.translate()` 与 `.offset()` 都可用,但 `.translate()` 参与 transformation chain