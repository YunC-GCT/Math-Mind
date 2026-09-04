# Research index

> **Scope**: 调研产物索引(一手底料 + 项目定位 + 架构体检)。
> **Convention**: `YYYY-MM-DD-<topic-slug>.md` (kebab-case),HTML 镜像同 slug。
> **Source-of-truth**: 本目录文件均为 research 一次性产物,落定后不再修改;新版本开新文件并把旧的挪 `docs/legacy/`。

## Active

| File | Date | Topic | Status |
|---|---|---|---|
| [`agent-framework-comparison-2026-09-02.md`](./agent-framework-comparison-2026-09-02.md) (.html) | 2026-09-02 | MindTrace 是否使用 LangGraph 等价框架?结论:不用,自建 Dispatcher + sub-agent 同步链 | active |
| [`langgraph-migration-2026-09-02.md`](./langgraph-migration-2026-09-02.md) (.html) | 2026-09-02 | MindTrace → LangGraph 迁移可行性调研 | active |
| [`2026-09-04-project-positioning.md`](./2026-09-04-project-positioning.md) | 2026-09-04 | 项目定位(摘要 + 详细双节),团队对齐与评委 pitch 用 | active |
| [`_positioning-facts-2026-09-04.md`](./_positioning-facts-2026-09-04.md) | 2026-09-04 | 定位报告的一手事实底料(692 行,引用 80+ 源文件),下划线前缀 = 临时原料,不入正式索引 | raw / internal |

## Cross-reference

- 架构体检报告(HTML,不在 git 仓): `C:\Users\YunCeH\AppData\Local\Temp\architecture-review-20260904-131757Z.html` — `improve-codebase-architecture` skill 产物,落 OS temp 而非仓内(per skill 约定)
- 关联审计: [`../legacy/mindtrace/architecture/audit-full-2026-09-01.md`](../legacy/mindtrace/architecture/audit-full-2026-09-01.md)
- ADR / Spec: [`../adr/`](../adr/) / [`../specs/`](../specs/)

## Naming convention

| 类别 | 规则 |
|---|---|
| 调研文档 | `YYYY-MM-DD-<topic-slug>.md` |
| 临时原料 | `_YYYY-MM-DD-<topic-slug>.md`(下划线前缀,不入正式索引) |
| HTML 镜像 | 同 slug `.html`,与 md 并列 |
| 归档 | 移入 `docs/legacy/research/` 后保留日期与 slug |

## Maintenance

- 新增调研:复制 `docs/template/research-*.md` 模板,文件名按 `YYYY-MM-DD-<slug>.md` 命名
- 索引追加:在本表 Active 段加一行,标注日期 / 主题 / 状态
- 归档:旧调研从 Active 移到 Legacy 段,文件本身保留
