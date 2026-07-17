# MathMind 架构说明

> 最后更新：2026-07-16
> 维护者：全体成员

## 当前使用的管线

项目只有一条 **MVP 管线**在运行。旧管线（KnowledgeModel — 3 分类版）已全部删除，本地仓库中不再存在。

```
用户输入 (图片/文本)
  → TypeClassifier          (OCR 文字提取, 由其他成员维护)
  → KnowledgeModelMVP       (AI 自分词 5 类 + 结构化 + 真值检验 + 入库)
  → ContextLink             (上下文关联, 当前为 Stub)
  → KnowledgeUnitExt        (返回给 UI 渲染)
```

> **UI 开发者注意**：当前 App 启动加载的是 `IndexMVP.ets`（不是 Index.ets），
> 浮窗使用 `AgentFloatWindowMVP.ets`（不是 AgentFloatWindow.ets），
> 服务层使用 `AiServiceMVP.ets`。所有旧版本文件已被删除。
>
> **OCR 开发者注意**：TypeClassifier 仍在使用，但 MVP 管线只取它的 `ocrText`（文字提取能力），
> 它的分类输出（type/subject/chapter）未被消费。KnowledgeModelMVP 内部自己做 AI 自分词。

> **TypeClassifier 注意**：此类由另一位成员维护，当前仍会调用 LLM 返回分类信息，
> 但结果未被 MVP 管线使用。后续可考虑精简为纯 OCR 提取或重命名（需由维护者推进）。

### 5 个最小分类

- `概念` — 数学定义、名词解释
- `定理` — 已被证明的真命题
- `公式` — 数学表达式
- `证明题` — 需证明的命题 + 证明过程
- `计算题` — 需数值计算或求解的问题

## 模块结构

### `agents/` — 共享能力集 (HSP)

| 目录 | 用途 |
|------|------|
| `agents/` | 核心 Agent：KnowledgeModelMVP, TypeClassifier, ContextLink, OcrTool |
| `core/` | 调度中枢：DispatcherMVP |
| `models/` | 类型定义：KnowledgeUnitExt, KnowledgeCategory, NoteDaoInterface, TruthCheckResult, KnowledgeLinkTypes |
| `mcp/tools/` | MCP 工具：OcrTool |
| `src/test/` | 单元测试：KnowledgeModelMVP.test.ets |

**入口**: `agents/src/main/ets/Index.ets` — 导出 MVP 管线全部公开类型。

### `entry/` — 应用主模块

| 目录 | 用途 |
|------|------|
| `entryability/` | 应用入口 (EntryAbility)，加载 IndexMVP |
| `pages/` | 页面组件：IndexMVP (主容器), HomePage, NotesPage, ReviewPage, MePage, AiSettingsPage |
| `overlays/` | 浮层组件：AgentFloatWindowMVP, CameraOverlay, NoteDetailOverlay |
| `services/` | 服务层：AiServiceMVP, ApiClient, ImageUriResolver |
| `database/` | 数据访问：DatabaseHelperMVP, NoteDaoMVP |
| `components/` | 通用组件 |

## 当前生效的文件清单

以下是当前项目中 **正在使用** 的核心管线文件（共 12 个），其他团队成员的开发应基于这些文件：

| 模块 | 类别 | 文件 |
|------|------|------|
| agents | 调度中枢 | `agents/core/DispatcherMVP.ets` |
| agents | 知识建模 | `agents/agents/KnowledgeModelMVP.ets` |
| agents | 文字提取 | `agents/agents/TypeClassifier.ets` |
| agents | 上下文关联 | `agents/agents/ContextLink.ets` |
| agents | OCR | `agents/mcp/tools/OcrTool.ets` |
| agents | 模块入口 | `agents/src/main/ets/Index.ets` |
| entry | 应用入口 | `entry/src/main/ets/entryability/EntryAbility.ets` |
| entry | 首页容器 | `entry/src/main/ets/pages/IndexMVP.ets` |
| entry | 服务层 | `entry/src/main/ets/services/AiServiceMVP.ets` |
| entry | 浮窗 | `entry/src/main/ets/overlays/AgentFloatWindowMVP.ets` |
| entry | 数据库初始化 | `entry/src/main/ets/database/DatabaseHelperMVP.ets` |
| entry | 数据访问 | `entry/src/main/ets/database/NoteDaoMVP.ets` |

> 其他页面文件（HomePage/NotesPage/ReviewPage/MePage/AiSettingsPage/CameraOverlay/NoteDetailOverlay）
> 以及 ApiClient/ImageUriResolver 不受本次变更影响，保持原样。

## 数据库

使用 HarmonyOS RDB (`relationalStore`)，数据库文件 `mathmind.db`。

**`notes` 表**（由 `DatabaseHelperMVP` 创建，`NoteDaoMVP` 操作）：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT PK | 知识单元唯一 ID |
| type | TEXT | 最小分类 (概念/定理/公式/证明题/计算题) |
| title | TEXT | 标题 |
| content | TEXT | OCR 原文 |
| tags | TEXT | JSON 字符串数组 |
| fields | TEXT | JSON 结构化字段数组 |
| truthFlag | INTEGER | 真值检验是否通过 |
| truthDetails | TEXT | 检验详情 JSON 数组 |
| difficulty | INTEGER | 难度 1~5 |
| importance | INTEGER | 重要性 1~5 |
| needsUserInput | TEXT | 需用户确认的字段名 JSON 数组 |
| createdAt | INTEGER | 创建时间戳 |
| updatedAt | INTEGER | 更新时间戳 |
| source | TEXT | 来源描述 |
| userId | TEXT | 用户 ID |
| **reviewStatus** | TEXT | 复习状态: `new` / `learning` / `reviewing` / `mastered` |
| **nextReviewAt** | INTEGER | 下次复习时间戳（默认创建后 24h） |
| **intervalDays** | INTEGER | 复习间隔天数（默认 1） |
| **easeFactor** | REAL | 简易因子（SM-2 算法，默认 2.5） |
| **repetitions** | INTEGER | 连续答对次数（默认 0） |

> 复习字段当前由 `NoteDaoMVP.insert()` 自动填充默认值，`update()` 不修改它们。
> 将来实现 `ReviewPage` 时，在 `NoteDaoMVP` 中增加 `queryByReviewSchedule()` 和 `updateReview()` 方法即可。

## 已删除的旧管线文件

以下文件属于旧管线（KnowledgeModel — 3分类版），已整体移除：

| 文件 | 替代 |
|------|------|
| `agents/agents/KnowledgeModel.ets` | `agents/agents/KnowledgeModelMVP.ets` |
| `agents/core/Dispatcher.ets` | `agents/core/DispatcherMVP.ets` |
| `entry/services/AiService.ets` | `entry/services/AiServiceMVP.ets` |
| `entry/database/NoteDao.ets` | `entry/database/NoteDaoMVP.ets` |
| `entry/database/DatabaseHelper.ets` | `entry/database/DatabaseHelperMVP.ets` (功能相同，日志前缀不同) |
| `entry/overlays/AgentFloatWindow.ets` | `entry/overlays/AgentFloatWindowMVP.ets` |
| `entry/pages/Index.ets` | `entry/pages/IndexMVP.ets` |
| `entry/pages/AiTestPage.ets` | 死代码，未注册到路由 |
| `entry/pages/AiTestPageMVP.ets` | 死代码，未注册到路由 |

> **注意**：旧 `common/DatabaseHelper` 创建 `knowledge_unit` 表（旧 KnowledgeUnit 专用），
> 已于 EntryAbility 中移除其初始化调用。MVP 管线使用 `DatabaseHelperMVP` 创建的 `notes` 表。
> 两条管线**不共用数据库表**，旧 `knowledge_unit` 表的数据不会被新管线访问。

## 开发指引

1. **加新功能**：修改 `KnowledgeModelMVP.ets` 或新增 Agent，不要回退到旧管线模式
2. **改分类**：修改 `KnowledgeCategory` 类型和 `buildPrompt` 里的分类指令
3. **加数据库字段**：改 `DatabaseHelperMVP.ets` 的建表 SQL + `NoteDaoMVP.ets` 的读写逻辑
4. **跑测试**：`agents/src/test/KnowledgeModelMVP.test.ets` 覆盖纯逻辑方法
5. **联系人**：Agent 架构问题找 L，UI 层问题找 Z/Mavis
