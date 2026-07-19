# 2026-07-19 主 Agent 显式生成笔记 + Memory 改动记录

> commit: `7ba5169 feat(agent): add explicit note memory flow`  
> 分支: `main`  
> 目标: 普通对话不自动创建笔记；图片/文本先进入识别与记忆；只有用户明确表达生成笔记意图时，才总结上下文并调用 KnowledgeModel 生成笔记。

## 一、改动背景

此前 `AgentChatService.realReply()` 中的普通文本对话会在回复后进入持久化路径，最终触发：

```text
AiService.captureText()
→ Dispatcher.dispatch()
→ TypeClassifier.classify()
→ KnowledgeModel.structure()
→ NoteDao.insert()
```

这导致用户每输入一段普通文字都可能创建一条笔记。新逻辑将“对话/识别”和“生成笔记”拆开。

## 二、本次新增文件

| 文件 | 作用 |
|------|------|
| `entry/src/main/ets/database/AgentMemoryDao.ets` | `agent_memory` 表 DAO，保存 pending note、session summary，并支持标记已使用 |
| `entry/src/main/ets/database/ChatMessageDao.ets` | `chat_message` 表 DAO，保存/查询当前会话的用户与 AI 消息 |
| `entry/src/main/ets/models/AgentMemoryModels.ets` | memory 相关类型：`ChatRole`、`AgentMemoryType`、`ChatMessageRecord`、`AgentMemoryRecord` |
| `entry/src/main/ets/services/AgentMemoryService.ets` | memory 业务服务：保存消息、保存 OCR 素材、生成上下文、滚动 summary |

## 三、本次修改文件

| 文件 | 具体修改 |
|------|----------|
| `agents/src/main/ets/core/Dispatcher.ets` | 新增 `analyze()`，只做 OCR/分类，不调用 `KnowledgeModel.structure()`，不生成笔记 |
| `common/src/main/ets/models/CaptureChain.ets` | 新增 `DispatchAnalysisResult`，作为只识别/分类链路的返回类型 |
| `common/src/main/ets/Index.ets` | 导出 `DispatchAnalysisResult` |
| `common/src/main/ets/DatabaseHelper.ets` | 数据库 schema 升到 `2`；新增 `chat_message`、`agent_memory` 表和索引 |
| `entry/src/main/ets/services/AiService.ets` | 新增 `analyzeImage()`，图片只识别/分类，不入库 |
| `entry/src/main/ets/services/AgentChatService.ets` | 核心重构：普通聊天不入库；文字意图识别；显式生成笔记；接入 memory；优化生成笔记前总结 prompt |
| `entry/src/main/ets/overlays/AgentFloatWindow/AgentFloatWindow.ets` | 回调新增 `getSessionId()` 和会话上下文读取，供 memory 按会话隔离 |

## 四、行为变化

### 4.1 图片输入

```text
图片/拍照
→ AiService.analyzeImage()
→ Dispatcher.analyze()
→ TypeClassifier.classify()
→ AgentMemoryService.saveOcrResult()
→ 聊天窗口展示识别内容
```

不会自动调用 `KnowledgeModel.structure()`，也不会自动写入 `knowledge_unit`。

### 4.2 普通文字输入

```text
文字输入
→ classifyTextIntent()
→ chat
→ LlmClient 普通回复
→ AgentMemoryService.saveMessage()
```

普通问答、讲解、计算、临时总结都只保存为聊天 memory，不创建笔记。

### 4.3 显式生成笔记

用户表达以下意图时进入生成笔记链路：

```text
生成笔记 / 整理成笔记 / 保存为笔记 / 生成知识点
记一下 / 记下来 / 帮我记下来 / 把这题记下来
把上面记下来 / 收进笔记 / 加入笔记 / 存到笔记 / 留作笔记
保存这个知识点 / 把这个知识点存起来
```

流程：

```text
生成笔记意图
→ AgentMemoryService.getContextForNoteGeneration(sessionId)
→ summarizeConversation()
→ AiService.captureText(summary)
→ Dispatcher.dispatch()
→ TypeClassifier.classify()
→ KnowledgeModel.structure()
→ NoteDao.insert()
→ markPendingMaterialUsed()
```

## 五、Memory 策略

### 5.1 表结构

新增表：

```text
chat_message
- id
- session_id
- role
- content
- created_at

agent_memory
- id
- session_id
- type
- content
- source
- used
- created_at
- updated_at
```

### 5.2 当前限制

| 项 | 当前值 |
|----|--------|
| 普通回复最近消息数 | `28` |
| 生成笔记最近消息数 | `100` |
| 普通回复上下文裁剪 | `12000` 字符 |
| 生成笔记上下文裁剪 | `32000` 字符 |
| session summary 输入上限 | `24000` 字符 |
| summary 首次触发 | 超过 `30` 条消息 |
| summary 滚动更新 | 最新 summary 后新增 `16` 条消息 |

## 六、Prompt 变化

### 6.1 生成笔记前总结

`AgentChatService.summarizeConversation()` 不再要求短摘要，而是要求输出 `KnowledgeModel.structure()` 可直接使用的完整笔记原材料：

```text
主题/标题候选
原题或原始材料
关键公式
推导/步骤
结论
易错点
用户补充
上下文来源
```

并明确：

```text
不要丢数学细节
不要只给一句总结
不要输出 markdown 代码块
不要编造对话中没有的信息
```

`maxTokens` 从 `4096` 提升到 `8192`。

### 6.2 意图识别

`classifyTextIntent()` 使用本地规则 + LLM fallback：

```text
note_generation
chat
```

LLM 分类失败、无 API Key、结果异常时，默认 `chat`，避免误生成笔记。

### 6.3 Session Summary

`AgentMemoryService.summarizeSessionIfNeeded()` 改为滚动 summary，prompt 要求保留：

```text
题目/原始材料
关键公式
用户目标
OCR 材料
已讲解结论
待整理内容
未解决问题
```

## 七、验证

已在 rebase 到最新 `origin/main` 后运行：

```text
hvigor assembleApp
```

结果：

```text
BUILD SUCCESSFUL in 1 min 31 s 69 ms
```

仍存在既有 warning：签名/混淆配置、ArkTS `Function may throw exceptions`、部分 deprecated API。

## 八、2026-07-19 主 agent 输出长度调整

### 8.1 问题

主 agent 普通回复过短、风格死板，笔记详情中的摘要也容易只有一句话。排查后确认不是 LLM 输出 token 统一截断，而是代码中存在两处硬限制：

- `AgentChatService.buildReplyMessages()` 的系统提示词要求 `50字以内直接给答案`、`每步≤15字`、`不展开讨论`。
- `KnowledgeModel.summaryFromFields()` 和 fallback 笔记路径将笔记 `summary` 硬截断到 `100` 字。

### 8.2 本次改动

| 文件 | 改动 |
|------|------|
| `entry/src/main/ets/services/AgentChatService.ets` | 放宽普通聊天 prompt，改为按意图选择回答形态；解题、概念讲解、总结复盘、学习计划分别给不同结构；普通回复 `maxTokens` 从 `2048` 提升到 `4096`。 |
| `agents/src/main/ets/agents/KnowledgeModel.ets` | 将结构化笔记和 fallback 笔记的摘要上限从 `100` 字提升到 `500` 字，避免详情摘要只剩一句话。 |
| `common/src/main/ets/models/CommonTypes.ets` | 更新 `summary` 字段注释，移除 `<= 100 字` 的旧约束描述。 |

### 8.3 预期效果

- 简单问题仍可简短回答。
- 数学推导、讲解、复盘、总结类问题会保留必要步骤和关键公式。
- 主 agent 不会因为普通聊天 prompt 主动生成笔记。
- 笔记详情摘要能展示更完整的结构化概览；列表卡片仍可能因 UI 预览 `maxLines` 只显示前几行。

### 8.4 验证

已再次运行 `hvigor assembleApp`，结果 `BUILD SUCCESSFUL in 7 s 187 ms`。仍存在既有 warning：签名/混淆配置、ArkTS `Function may throw exceptions`、deprecated API。

### 8.5 回复风格测试集

新增 `docs/agent-reply-style-testset-20260719.md`，覆盖简单计算、数学推导、概念讲解、临时总结、明确生成笔记、信息不足、复盘、学习计划、长上下文追问、口语化保存意图等 10 个人工验收用例。

## 九、2026-07-19 用户画像与自适应回答

### 9.1 目标

主 agent 回复不再对所有用户固定使用“直观理解/核心定义/常见误区”等完整结构，而是按用户水平调整解释密度。

画像三档：

```text
beginner: 小白，少术语、多直观解释、步骤更细
novice: 初识者，保留关键思路和必要步骤，少量解释
advanced: 精通者，直接给结论、公式、推导要点和边界条件
```

无历史画像时默认使用 `advanced`，让主 agent 初始回答更偏简洁、公式和结论。

### 9.2 存储策略

复用 `agent_memory` 表，不新增 DB schema：

| 字段 | 用法 |
|------|------|
| `type` | 新增 `profile` |
| `source` | 固定为 `learner_profile` |
| `session_id` | 全局画像使用 `__global__`，会话画像使用当前 sessionId |
| `content` | 保存 `LearnerProfile` JSON |

`queryPendingNotes()`、`queryLatestSummary()`、`markPendingUsed()` 仍只过滤各自类型，不受 `profile` 影响。

### 9.3 更新策略

- `AgentMemoryService.getLearnerProfileContext(sessionId)` 读取全局画像和当前会话画像，生成短文本注入普通回复 prompt。
- `AgentMemoryService.updateLearnerProfileIfNeeded(sessionId)` 在每 6 条用户消息后尝试更新画像。
- 无 API Key、LLM 失败、JSON 解析失败、字段非法时跳过，只记录 warning，不阻断普通聊天。
- 画像证据只保存简短摘要，例如“多次要求基础解释和例子”。

### 9.4 Prompt 策略

`AgentChatService.buildReplyMessages()` 注入 Learner profile：

- `beginner` 可以使用直观解释、例子和关键易错点。
- `novice` 以思路、必要步骤和结论为主，只在概念题或用户困惑时补直观解释。
- `advanced` 默认压缩基础定义和比喻，直接给公式、推导主线、结论和边界条件。
- 当前用户明确要求“详细讲”“像小白一样讲”“直接给答案”“不要展开”时，本轮指令优先于画像。

### 9.5 验收补充

`docs/agent-reply-style-testset-20260719.md` 新增画像差异测试：

- 同一导数概念题在 `beginner`、`novice`、`advanced` 下回答粒度不同。
- `advanced` 用户说“像小白一样讲”时，本轮按小白讲。
- `beginner` 用户说“直接给答案，不要展开”时，本轮保持简短。
- 明确“帮我记一下”仍走生成笔记链路，不受画像逻辑影响。

### 9.6 构建验证

已运行 `hvigor assembleApp`，结果 `BUILD SUCCESSFUL in 13 s 873 ms`。仍存在既有 warning：签名/混淆配置、ArkTS `Function may throw exceptions`、deprecated API。
