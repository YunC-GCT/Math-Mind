# AI 浮窗对话流式输出 — 实施方案（基于 DeepSeek API）

> **日期**: 2026-07-24  
> **状态**: 提案  
> **模型**: DeepSeek V4 Pro (`deepseek-v4-pro`)  
> **API 文档**: https://api-docs.deepseek.com/zh-cn/

---

## 一、Goal（目标）

**让 AI 浮窗对话实现 DeepSeek 原生的 SSE 流式输出**，用户输入后能看到 AI 回复逐 token 实时渲染（类似 ChatGPT），消除当前 5~60 秒的空白等待。同时支持 DeepSeek 思考模式（Thinking Mode），可选择展示/隐藏模型的思维链过程。

### 验收成果

1. **用户输入后 500ms 内看到首个 token** 出现在聊天气泡中（当前需等待完整响应，5~60 秒）
2. **AI 回复逐 token 流式追加** 到聊天列表最后一条消息，文本持续增长，不再是一次性替换
3. **思考模式可选** — 若用户在 AI 设置中开启"展示思考过程"，流式输出中先展示 `reasoning_content`（灰色/折叠样式），再展示正式 `content`
4. **流式中断可恢复** — 网络断开或用户切会话时，已展示的部分内容保留在聊天记录中，不清空
5. **Markdown 实时渲染** — 流式输出中 Markdown 语法（公式、代码块、表格）在完整块到达时即时渲染
6. **非流式回退** — 若流式请求失败，自动降级到原有的阻塞式调用，用户无感知

---

## 二、DeepSeek API 流式协议分析

### 2.1 请求差异

| 参数 | 非流式（当前） | 流式（目标） |
|------|--------------|------------|
| `stream` | `false` | `true` |
| `thinking` | `{"type": "enabled"}` | `{"type": "enabled"}` |
| `reasoning_effort` | `"high"` | `"high"` |
| Content-Type 响应 | `application/json` | `text/event-stream` |

> **注意**: DeepSeek 思考模式下 **不支持** `temperature`、`top_p`、`presence_penalty`、`frequency_penalty` 参数。设置不报错但不生效。

### 2.2 流式响应格式（SSE）

每个 chunk 是标准 SSE 事件：

```
data: {"id":"xxx","choices":[{"index":0,"delta":{"content":"","role":"assistant"},"finish_reason":null}],...}\n\n
data: {"id":"xxx","choices":[{"index":0,"delta":{"content":"Hello"},"finish_reason":null}],...}\n\n
data: {"id":"xxx","choices":[{"index":0,"delta":{"content":"!"},"finish_reason":null}],...}\n\n
...
data: {"id":"xxx","choices":[{"index":0,"delta":{"content":""},"finish_reason":"stop"}],"usage":{...}}\n\n
data: [DONE]\n\n
```

### 2.3 思考模式流式响应（关键差异）

当 `thinking: {type: "enabled"}` 时，流式 chunk 中的 `delta` 字段会**先发 `reasoning_content`，再发 `content`**：

```
# 阶段1：思维链（reasoning_content）
data: {"choices":[{"delta":{"reasoning_content":"我们来分析","role":"assistant"}}],...}
data: {"choices":[{"delta":{"reasoning_content":"这道题的"},"role":"assistant"}}],...}
...
# 阶段2：正式回答（content）
data: {"choices":[{"delta":{"content":"根据分析","role":"assistant"}}],...}
data: {"choices":[{"delta":{"content":"，答案是..."},"role":"assistant"}}],...}
```

**处理规则**：同一个 chunk 中 `reasoning_content` 和 `content` 不会同时非空。先处理所有 `reasoning_content` chunk，再处理所有 `content` chunk。

### 2.4 多轮对话中的 reasoning_content 回传

> **重要**: 两个 user 消息之间，若模型**未进行工具调用**，中间 assistant 的 `reasoning_content` **无需**参与上下文拼接，传入也会被 API 忽略。**但若进行了工具调用**，则必须完整回传 `reasoning_content`。

当前 MathMind 的 AI 浮窗对话**不使用工具调用**，因此可以简化处理：`reasoning_content` 仅用于 UI 展示，不存入上下文。

---

## 三、现状差距分析

### 3.1 当前调用链（全阻塞）

```
用户输入 → AgentFloatWindow.send()
  → AgentChatService.realReply()
    → LlmClient.call(messages)           ← stream: false 硬编码
      → http.request() 阻塞等待完整响应
    → cbs.addAiMsg(fullContent)           ← 一次性追加完整消息
  → @State messages 数组替换
  → ChatBubble 渲染完整 Markdown
```

### 3.2 各层差距

| 层级 | 文件 | 当前状态 | 需要改造 |
|------|------|---------|---------|
| **类型层** | `common/.../llm/LlmTypes.ets` | 只有 `LlmResponse`（完整响应） | 新增 `LlmStreamChunk`、`LlmStreamDelta` |
| **网络层** | `common/.../llm/LlmClient.ets` | 只有 `call()` 阻塞方法 | 新增 `callStream()` SSE 解析方法 |
| **服务层** | `entry/.../services/AgentChatService.ets` | `realReply()` 等待完整回复 | 新增 `realReplyStream()`，扩展 Callbacks |
| **回调接口** | `AgentChatCallbacks` | 只有 `addAiMsg(content)` | 新增 `addAiMsgEmpty()`、`appendAiMsg()`、`finishAiMsg()` |
| **数据模型** | `ChatModels.ets` | `ChatMsg` 无流式标记 | 新增 `streaming: boolean` 字段 |
| **UI 浮窗** | `AgentFloatWindow.ets` | 数组整体替换 | 支持最后一条消息增量更新 |
| **气泡渲染** | `ChatBubble.ets` | `progressive: false` 硬编码 | 流式消息走增量渲染路径 |
| **Markdown渲染** | `MarkdownRenderer.ets` | 全量解析 | 增量追加时按块边界智能重解析 |

---

## 四、实施计划

### Phase 1: 类型层 + 网络层（SSE 解析核心）— 预估 2d

#### 4.1.1 `LlmTypes.ets` — 新增流式类型

```typescript
// SSE 流式响应类型（兼容 DeepSeek + OpenAI 格式）
export interface LlmStreamDelta {
  role?: 'assistant'
  content?: string
  reasoning_content?: string
}

export interface LlmStreamChoice {
  index: number
  delta: LlmStreamDelta
  finish_reason: string | null
}

export interface LlmStreamChunk {
  id: string
  object: string           // "chat.completion.chunk"
  created: number
  model: string
  choices: LlmStreamChoice[]
  usage?: LlmResponseUsage  // 仅最后一个 chunk 有
}

// 流式回调：delta 为本次增量文本（可能是 reasoning_content 或 content）
export type LlmStreamCallback = (delta: string, kind: 'reasoning' | 'content') => void

// 扩展 LlmCallOptions
export interface LlmCallOptions {
  temperature?: number
  maxTokens?: number
  model?: string
  timeoutMs?: number
  responseFormat?: { type: 'json_object' }
  // 新增：启用思考模式流式输出
  enableThinking?: boolean
}
```

#### 4.1.2 `LlmClient.ets` — 新增 `callStream()` 方法

```typescript
/**
 * 流式调用 DeepSeek Chat API
 * 
 * SSE 解析策略（HarmonyOS @kit.NetworkKit）：
 *   - 使用 http.createHttp().request() 发起 POST
 *   - 监听 on('dataReceiveProgress', ...) 事件逐块接收数据
 *   - 维护行缓冲区：TCP 分包可能导致一个 SSE event 跨多个 data 回调
 *   - 按 '\n\n' 分割完整 events
 *   - 每行以 "data: " 开头则解析 JSON chunk
 *   - 遇到 "data: [DONE]" 结束
 *   - JSON parse 失败则跳过（可能是跨包截断）
 * 
 * @param messages  对话消息列表
 * @param onDelta   每次收到新 token 时的回调
 * @param opts      可选参数（含 enableThinking）
 */
public async callStream(
  messages: ChatMessage[],
  onDelta: (delta: string, kind: 'reasoning' | 'content') => void,
  opts?: LlmCallOptions
): Promise<void>
```

**SSE 解析核心逻辑（伪代码）**：

```
buffer = ""
httpRequest.on('dataReceiveProgress', (data: ArrayBuffer) => {
  buffer += decodeURIComponent(escape(arrayBufferToString(data)))
  
  while (buffer contains '\n\n') {
    event = extract until '\n\n'
    lines = event.split('\n')
    
    for line in lines:
      if line starts with 'data: ':
        dataStr = line.substring(6)
        if dataStr == '[DONE]':
          resolve()  // 流结束
          return
        try:
          chunk = JSON.parse(dataStr)
          delta = chunk.choices[0].delta
          if delta.reasoning_content:
            onDelta(delta.reasoning_content, 'reasoning')
          if delta.content:
            onDelta(delta.content, 'content')
          if chunk.choices[0].finish_reason:
            resolve()  // finish_reason 非空表示最后一个有效 chunk
        catch:
          // 不完整 JSON，放回 buffer 等待更多数据
          break
  }
})
```

**关键风险点**：
1. **HarmonyOS HTTP 流式 API 兼容性**：`http.createHttp().request()` 在 API 9/10 的流式行为需实测验证。若 `request2` 或 `requestInStream` 更合适，需调整。
2. **行缓冲**：TCP 分包导致不完整行，需在 buffer 中保留未完成的 `data:` 行。
3. **JSON parse 保护**：截断的 JSON 字符串 parse 会抛异常，不能让它终止 SSE 循环。

#### 4.1.3 非流式回退策略

```typescript
// AgentChatService 中的回退逻辑
try {
  await llmClient.callStream(messages, onDelta, opts)
} catch (e) {
  if (e instanceof LlmError && e.kind === 'STREAM_FAILED') {
    // 降级为非流式
    const fullContent = await llmClient.call(messages, opts)
    cbs.addAiMsg(fullContent)
  } else {
    throw e
  }
}
```

---

### Phase 2: 服务层改造 — 预估 1.5d

#### 4.2.1 扩展 `AgentChatCallbacks`

```typescript
interface AgentChatCallbacks {
  // ... 现有
  addAiMsg: (content: string) => void              // 保留兼容
  // 新增流式三件套
  addAiMsgEmpty: () => number                      // 创建空消息，返回 msgId
  appendAiMsg: (id: number, delta: string) => void // 追加一个 token
  finishAiMsg: (id: number) => void                // 标记流结束
}
```

#### 4.2.2 新增 `realReplyStream()`

```typescript
async realReplyStream(userContent: string): Promise<void> {
  // 1. Intent check（同原逻辑）
  // 2. Context load（同原逻辑）
  // 3. 保存 user 消息到 RDB

  // 4. 创建空 AI 消息（UI 立即可见）
  const msgId: number = this.cbs.addAiMsgEmpty()
  this.setStatusMeta({ step: 'reply_model_call', title: '生成回答', detail: '...' })

  // 5. 流式调用
  const client = new LlmClient()
  let accumulatedContent = ''
  let accumulatedReasoning = ''
  
  try {
    await client.callStream(
      this.buildReplyMessages(memoryContext, learnerProfileContext, userContent),
      (delta: string, kind: 'reasoning' | 'content') => {
        if (kind === 'reasoning') {
          accumulatedReasoning += delta
          // UI 可选择显示 reasoning_content
          this.cbs.appendAiMsg(msgId, delta)  // reasoning 也追加到消息
        } else {
          accumulatedContent += delta
          this.cbs.appendAiMsg(msgId, delta)
        }
      },
      { enableThinking: true, maxTokens: 4096, timeoutMs: 120000 }
    )
  } catch (e) {
    // 流式失败：保留已展示的部分内容 + 追加错误提示
    this.cbs.appendAiMsg(msgId, '\n\n⚠️ *AI 回复中断，请重试*')
  } finally {
    this.cbs.finishAiMsg(msgId)
    this.finishBusy()
  }

  // 6. 持久化完整内容到 RDB
  await this.safeSaveAssistantMessage(sessionId, accumulatedContent)
}
```

---

### Phase 3: UI 层改造 — 预估 2d

#### 4.3.1 `ChatModels.ets` — 扩展 ChatMsg

```typescript
interface ChatMsg {
  id: number
  role: 'user' | 'ai'
  content: string
  ts: number
  streaming: boolean      // 新增：是否正在流式生成中
  reasoning: string       // 新增：思维链内容（可选展示）
}
```

#### 4.3.2 `AgentFloatWindow.ets` — 新增流式回调

```typescript
addAiMsgEmpty: (): number => {
  const id = nowId()
  this.messages = [...this.messages, {
    id, role: 'ai', content: '', ts: Date.now(), streaming: true, reasoning: ''
  }]
  return id
},

appendAiMsg: (id: number, delta: string): void => {
  // 性能关键路径：每秒可能触发 20~60 次
  this.messages = this.messages.map(m =>
    m.id === id ? { ...m, content: m.content + delta } : m
  )
},

finishAiMsg: (id: number): void => {
  this.messages = this.messages.map(m =>
    m.id === id ? { ...m, streaming: false } : m
  )
},
```

**性能注意**：`messages.map()` 每次创建新数组，对于 < 100 条消息/会话应该 OK。若实测卡顿，改用 `@Observed` + `@ObjectLink` 基于类的 observable 来避免全数组重建。

#### 4.3.3 `ChatBubble.ets` — 流式消息渲染

对于流式中的 AI 消息（`msg.streaming === true`），使用一种**轻量级增量渲染**策略：

```typescript
if (this.msg.streaming) {
  // 流式模式：文本直接追加显示，不做完整的 Markdown 重解析
  // 避免每次 token 都触发全文 parse（性能灾难）
  Text(this.msg.content).fontSize(15).lineHeight(22)
  // 等流结束后再由 MarkdownRenderer 渲染完整内容
} else {
  // 非流式模式：完整 Markdown 渲染（保持不变）
  MarkdownRenderer({
    text: this.msg.content,
    progressive: false,
    profile: 'chat',
  })
}
```

**但更好的折中**：在流式中也做 Markdown 解析，但仅在**块边界**（遇到 `\n\n`、代码块闭合 ` ``` `、公式闭合 `$$`/`$`）时触发增量解析。这需要改造 `MarkdownRenderer` 或新增一个 `StreamingMarkdownView` 组件。

#### 4.3.4 `MarkdownRenderer.ets` — 增量解析能力（可选优化）

当前 `MarkdownRenderer` 是"全量解析 + 分页展示"，不适合流式场景。建议新增一个 **`MarkdownStreamView`** 组件：

```
MarkdownStreamView:
  - 接收 content: string（持续增长）
  - 维护已解析的 blocks 列表
  - 每次 content 变化时：
    - 尝试解析新增文本中的新 block
    - 如果最后一个 block 可能不完整（如公式未闭合），保留在缓冲区，不渲染
    - 将已确认完整的 blocks 追加到渲染列表
  - 利用 @Reusable 避免重复创建已渲染的 block 节点
```

> **Phase 3 的分岔点**：如果时间紧，先用纯文本显示流式内容，流结束后切回 Markdown 渲染。如果时间充裕，实现 `MarkdownStreamView` 获得最佳体验。

#### 4.3.5 思考内容展示（可选）

在 `ChatBubble` 中，当 `msg.reasoning` 非空时：

```typescript
if (this.msg.reasoning.length > 0) {
  Column() {
    Row() {
      Image($r('app.media.ic_brain')).width(16).height(16)
      Text('思考过程').fontSize(12).fontColor('#888')
      Image($r('app.media.ic_chevron_down')).width(12).height(12)
    }.onClick(() => this.showReasoning = !this.showReasoning)
    
    if (this.showReasoning) {
      Text(this.msg.reasoning)
        .fontSize(13)
        .fontColor('#999')
        .padding({ left: 12, top: 4, bottom: 8 })
        .fontStyle(FontStyle.Italic)
    }
  }
  .padding(8)
  .backgroundColor('#f5f5f5')
  .borderRadius(8)
  .margin({ bottom: 8 })
}
```

---

### Phase 4: 边界情况处理 — 预估 1d

| 场景 | 策略 |
|------|------|
| **网络中断** | `httpRequest.destroy()` 取消请求，保留已展示部分，追加 `⚠️ 回复中断` 提示 |
| **用户快速切会话** | 切换时取消当前流式请求（`abortController.abort()`），旧会话的 streaming 消息标记为 `finished` |
| **连续发送多条消息** | 前一条流式未完成时发送新消息 → 取消前一条，标记 finished，起新流 |
| **API 返回 400/429** | 同现有错误处理，不重试（流式重试会出重复内容） |
| **SSE 解析异常** | 单个 chunk parse 失败 → 跳过，继续尝试解析后续 chunk |
| **Markdown 截断** | 流式中的最后一个不完整块（如未闭合的代码块）不渲染，等流结束后再完整渲染 |

---

### Phase 5: 测试与验证 — 预估 1d

| 测试项 | 验证方法 |
|--------|---------|
| **首 token 延迟** | 日志记录 `callStream` 开始到第一个 `onDelta` 的时间，应 < 500ms |
| **流式文本完整性** | 对比 `accumulatedContent` 与 `content`（应 100% 一致） |
| **reasoning_content 展示** | 开启思考模式后，气泡中先出现灰色倾斜文本，再出现正式回答 |
| **网络中断** | 飞行模式 → 验证 `⚠️ 回复中断` 出现且不崩溃 |
| **快速切会话** | 发送消息后立即切其他会话 → 验证旧流被取消，新会话不受影响 |
| **非流式回退** | Mock `callStream` 抛异常 → 验证自动降级到 `call()` |
| **Markdown 渲染** | 发送 `$$E=mc^2$$` 等内容 → 验证公式/代码块在流结束后正确渲染 |
| **真机性能** | 流式期间 CPU 占用 < 30%，UI 无可见卡顿 |

---

## 五、涉及文件清单

| # | 文件 | 改造类型 | 预估行数变化 |
|---|------|---------|------------|
| 1 | `common/src/main/ets/llm/LlmTypes.ets` | 新增类型 | +40 |
| 2 | `common/src/main/ets/llm/LlmClient.ets` | 新增 `callStream()` | +120 |
| 3 | `common/src/main/ets/llm/LlmConfig.ets` | 新增 `enableThinking` 配置项 | +20 |
| 4 | `entry/src/main/ets/services/AgentChatService.ets` | 新增 `realReplyStream()` + 扩展 Callbacks | +80 |
| 5 | `entry/src/main/ets/overlays/AgentFloatWindow/chat/ChatModels.ets` | `ChatMsg` 加字段 | +5 |
| 6 | `entry/src/main/ets/overlays/AgentFloatWindow/AgentFloatWindow.ets` | 新增流式回调实现 | +40 |
| 7 | `entry/src/main/ets/overlays/AgentFloatWindow/chat/ChatBubble.ets` | 流式渲染分支 | +30 |
| 8 | `entry/src/main/ets/overlays/AgentFloatWindow/chat/AgentMessageList.ets` | 流式自动滚动 | +10 |
| 9 | `entry/src/main/ets/shared/components/MarkdownRenderer.ets` | 增量解析（可选） | +100~150 |
| 10 | `entry/src/main/ets/pages/AiSettingsPage.ets` | 思考模式开关 UI | +30 |

---

## 六、风险与依赖

| 风险 | 等级 | 缓解措施 |
|------|------|---------|
| HarmonyOS `http` 模块 SSE 支持不稳定 | 🔴 高 | Phase 1 先写最小可行 SSE demo，在真机上验证 `dataReceiveProgress` 事件是否按预期触发 |
| `@State` 数组频繁更新导致卡顿 | 🟡 中 | 实测监控；如果卡顿，改用 `@Observed` 类 + `@ObjectLink` 精确更新单条消息 |
| 思考模式 multi-turn 上下文拼接 | 🟢 低 | 当前无 tool_calls，按文档规则 reasoning_content 无需回传 |
| DeepSeek 模型弃用 | 🟢 低 | `deepseek-chat`/`deepseek-reasoner` 将于 2026/07/24 弃用，但我们已使用 `deepseek-v4-pro`，不受影响 |

---

## 七、总结

DeepSeek V4 Pro 完整支持 SSE 流式输出 + 思考模式，API 与 OpenAI 格式完全兼容。当前 MathMind 代码库零流式代码，需要从网络层→服务层→UI 层做三层改造，预估总工时 **7.5 天**。

改造核心三件事：
1. **`LlmClient.callStream()`** — SSE 行缓冲解析 + `on('dataReceiveProgress')` 事件驱动
2. **`AgentChatService.realReplyStream()`** — 空消息占位 → 逐 token 追加 → finish 标记
3. **UI 增量渲染** — `ChatMsg.streaming` 标记 + 轻量级文本追加（或 `MarkdownStreamView` 按块边界解析）
