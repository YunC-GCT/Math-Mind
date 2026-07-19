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
