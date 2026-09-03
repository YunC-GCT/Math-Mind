# .ets 文件头注释模板 (W3 后新规)

≥ 80 个 `.ets` 文件已统一使用本模板。Phase 4 ticket #6 统一剩余文件。

## 模板

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

## 强制字段

| 字段 | 用途 | 示例 |
|---|---|---|
| `{FileName}.ets` | 文件名 | `LlmConfig.ets` |
| `{职责一句话}` | 一句话核心 | `LLM 配置管理(单例 + preferences 持久化)` |
| `路径` | 相对路径 | `common/src/main/ets/llm/LlmConfig.ets` |
| `职责` | 具体业务 | (init / persist / read methods) |
| `依赖` | import 模块 | `@kit.ArkData`, `./LlmTypes` |
| `数据流` | 上游/下游 | `init() → normalizeEndpoint() → setEndpoint()` |

## 可选字段

- `数据流` — 复杂业务流时强烈推荐 (≥ 200 LOC)
- `ArkTS 1.1 strict 适配` — 记录踩坑点 (e.g. "用 `as` 替代 `<T>x` 强转")
- `{其他设计要点}` — 任何觉得重要的非代码事实

## 创建新文件

- 用 `write` 工具创建 (避免 PowerShell 5.1/7 的中文编码陷阱)
- 编辑已有文件用 `edit` 工具
- 创建后 PowerShell 验首 3 字节 `69 6D 70` (= "imp" = "import" 无 BOM):
  ```powershell
  [System.IO.File]::ReadAllBytes('path/to/file.ets')[0..2] | %{ "0x{0:X2}" -f $_ }
  ```