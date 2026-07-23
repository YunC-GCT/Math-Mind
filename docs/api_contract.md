# MindTrace 主 Agent 业务 API 契约 (W1 块 3)

> 主 Agent 业务 4 个核心类 + 共享类型的接口契约
> 创建: Mavis (2026-07-14 00:57) — 给 D / L 真实现时参考
> 状态: 骨架 (Dispatcher) 已 build 通过,真实现替换 mock body 即可

---

## 一、整链数据流

```
UI (拍图 + 文字 / 选图 / 选文件 / 手输文本)
  ↓ imageUri + userText (or text / fileUri + mimeType)
AiService.capture(...) / captureFromFile(...) / textQuery(...)
  ↓ 构造 DispatchPayload
new Dispatcher().dispatch({
  source: 'app',
  payload: { kind: 'image' | 'text' | 'file', ... }  // discriminated union
})
  ├─ L1 跳过(MVP 单一意图)
  ├─ Step 1: new TypeClassifier().classify(req.payload) → ClassificationResult
  │   └─ 内部按 payload.kind switch: image/file 走 OCR,text 直进 LLM
  └─ Step 2: new KnowledgeModel().structure(ocrText, type, subject, chapter) → KnowledgeUnit
        └─ 内部: NoteDao.insert(unit) → rowId → 回填 unit.id
  ↓
{ success: true, route: 'D1', data: KnowledgeUnit, durationMs }
  ↓
UI HomePage 渲染笔记卡
```

---

## 二、核心类接口

### 2.1 `Dispatcher` (A4 · Z 责任 · **已实现**)

**路径:** `agents/src/main/ets/core/Dispatcher.ets`
**导出:** `agents/src/main/ets/Index.ets` (AGENTS_VERSION v0.0.3)

```typescript
import { Dispatcher, type DispatchPayload } from 'agents';

const dispatcher = new Dispatcher();
const result: DispatchResult = await dispatcher.dispatch({
  source: 'app',         // 'app' | 'skill' | 'card'
  payload: { kind: 'image', imageUri: 'file://...', userText: '整理成笔记' },
});
```

**返回:** `DispatchResult`

**责任:**
- 接收 `DispatchRequest`(payload 是 `DispatchPayload` discriminated union)
- 调 `TypeClassifier.classify(req.payload)`(图片/文本/文件内部 switch)
- 从 `ClassificationResult.ocrText` 拿文本(空时 fallback 到 `payload.text` if kind='text')
- 调 `KnowledgeModel.structure(ocrText, type, subject, chapter)`
- 失败 catch 返 errorMessage(不抛异常)

**不做的事:**
- ❌ L1 关键词匹配
- ❌ L2 DeepSeek 语义兜底
- ❌ 6 路分发(只 D1)
- ❌ 4 级降级
- ❌ MCP Client 调用

---

### 2.2 `TypeClassifier` (B2 · **D 责任** · 当前 stub 接 DispatchPayload)

**路径:** `agents/src/main/ets/agents/TypeClassifier.ets`

```typescript
import { TypeClassifier, ClassificationResult, type DispatchPayload } from 'agents';

const classifier = new TypeClassifier();
const result: ClassificationResult = await classifier.classify(payload: DispatchPayload);
```

**输入:** `payload: DispatchPayload` — discriminated union(image / text / file)
**输出:** `ClassificationResult`

**D 真实现时要做:**
1. 按 `payload.kind` 分流:
   - `'image'` 或 `'file' (image/*)` → 调 ML Kit OCR(`@ohos.ai.mlnlp.textRecognition`) → rawText
   - `'text'` 或 `'file' (text/plain)` → 直接用 `payload.text` / 读文件
   - 其他 mime → 返 `errorMessage: '暂不支持的 MIME: ...'`
2. cleanText(rawText) → 清洗(去空格 / LaTeX 符号)
3. 构造 LLM prompt:
   - system 模板(3×3 分类规则)
   - user 内容:`OCR/text 内容: <text>` + `用户补充: <userText>`(若有)
4. 调 LlmClient.call(messages) → SiliconFlow DeepSeek-V3
   - temperature 0.1, max_tokens 12000, timeout 120000ms
5. 解析 JSON → `ClassificationResult`
6. **必须填 `ocrText` 字段** (Dispatcher 用)

**当前 stub:** 按 `payload.kind` 拼 mock ocrText,返固定 `{type:'计算', subject:'高等代数', chapter:'行列式', confidence:0.85, ocrText:'mock OCR text from ...'}`
**替换方法:** 整个 method body 删,写真实现

---

### 2.3 `KnowledgeModel` (C · **L 责任** · 当前 stub)

**路径:** `agents/src/main/ets/agents/KnowledgeModel.ets`

```typescript
import { KnowledgeModel, KnowledgeUnit } from 'agents' | 'common';

const model = new KnowledgeModel();
const unit: KnowledgeUnit = await model.structure(
  ocrText: string,
  type: '概念' | '计算' | '证明',
  subject: '高等代数' | '数学分析' | '解析几何',
  chapter: string,  // 允许空字符串
);
```

**输入:** 4 个参数(按 `DISPATCHER_TONIGHT.md` 第 4 参数版)
**输出:** `KnowledgeUnit`(18 字段全填)

**L 真实现时要做:**
1. 根据 `type` 选模板 (3 选 1):
   - `概念` → `concept_v1`: `## 定义 / ## 性质 / ## 相关概念`
   - `计算` → `computation_v1`: `## 题目 / ## 解法 / ## 答案`
   - `证明` → `proof_v1`: `## 命题 / ## 证明 / ## 要点`
2. `title` 取首句摘要(≤30 字),前缀 `【概念】` / `【计算】` / `【证明】`
3. 构造 KnowledgeUnit(18 字段全填)
4. `truthCheck(ocrText)` → `TruthCheckResult`
   - 括号配对 / 除零 / 恒等式 / 矛盾等式 / LaTeX 语法
5. `NoteDao.insert(unit)` → rowId → 回填 `unit.id`
6. 返回 unit(带 id)

**当前 stub:** 返 mock KnowledgeUnit(18 字段全填 mock 数据)
**替换方法:** 整个 method body 删,写真实现

---

### 2.4 `NoteDao` (A1 · **L 责任** · 当前空 class)

**路径:** `entry/src/main/ets/database/NoteDao.ets`

```typescript
import { NoteDao, KnowledgeUnit } from '...';  // 从 entry/ 相对路径

const dao = new NoteDao();
const rowId: number = dao.insert(unit: KnowledgeUnit);
const got: KnowledgeUnit | null = dao.queryById(id: string);
```

**L 真实现时要做:**
- 用鸿蒙 RDB(`@ohos.data.relationalStore`)
- 建表 SQL 在 `common/DatabaseHelper.ets`(后续补)
- `insert` 返 rowId(`number`),回填 `unit.id`
- `queryById` 按主键查 KnowledgeUnit 或 null

**当前空 class:** `export class NoteDao {}`
**替换方法:** 加 `insert()` + `queryById()` 两个 method

---

## 三、共享类型定义

### 3.1 `KnowledgeUnit` (18 字段)

**路径:** `common/src/main/ets/models/CommonTypes.ets`
**已暴露:** `common/Index.ets` line 26

```typescript
export interface KnowledgeUnit {
  id: string;            // 主键 (UUID 或 mock-now)
  title: string;
  content: string;
  summary: string;
  tags: string[];
  difficulty: DifficultyLevel;  // enum 1-4
  source: string;        // 原始 uri 或 'mock://...'
  createdAt: number;     // 时间戳
  updatedAt: number;
  reviewStatus: ReviewStatus;   // 'new' | 'learning' | ...
  nextReviewAt: number;
  intervalDays: number;
  easeFactor: number;     // SM-2, 默认 2.5
  repetitions: number;    // 默认 0
  prerequisites: string[];
  related: string[];
  embedding: number[];
  userId: string;         // 默认 'mock-user' 或真 user
  version: number;        // 乐观锁, 默认 1
}
```

### 3.2 `ClassificationResult` (5 字段)

**路径:** `common/src/main/ets/models/CaptureChain.ets`
**已暴露:** `common/Index.ets` line 44

```typescript
export interface ClassificationResult {
  type: '概念' | '计算' | '证明';
  subject: '高等代数' | '数学分析' | '解析几何';
  chapter?: string;       // 可选
  confidence: number;     // 0.0-1.0
  ocrText?: string;       // D 必须填,Dispatcher 用作 KnowledgeModel.structure 第一参
}
```

### 3.3 `DispatchRequest` / `DispatchResult` / `DispatchPayload`

**路径:** `common/src/main/ets/models/CaptureChain.ets`

```typescript
// 2026-07-14 升级:从 string 升级为 discriminated union,按 kind 显式分流
export type DispatchPayload =
  | { kind: 'image'; imageUri: string; userText?: string }
  | { kind: 'text'; text: string }
  | { kind: 'file'; fileUri: string; mimeType: string; userText?: string };

export interface DispatchRequest {
  source: 'app' | 'skill' | 'card';
  payload: DispatchPayload;  // 2026-07-14:从 string 升级
}

export interface DispatchResult {
  success: boolean;
  route: 'D1';            // 当前固定
  data?: KnowledgeUnit | Record<string, Object>;  // MVP 允许 Record 兼容 stub
  errorMessage?: string;
  durationMs: number;
}
```

**DispatchPayload 路由表:**

| kind | 用途 | UI 来源 | Dispatcher 行为 |
|------|------|---------|----------------|
| `image` | 拍照/相册 | `CameraOverlay` / `PhotoViewPicker` | ML Kit OCR → LLM 分类 |
| `text` | 纯文本 | 用户手输 / 复制粘贴 | 直接 LLM 分类(无 OCR) |
| `file` | 任意文件 | `DocumentViewPicker` | 按 mimeType 分:image/* 走 OCR;text/* 走纯文本;其他返错误(MVP) |

**Breaking change 提示(2026-07-14):**
- 旧版 `payload: string` + `imageUri: string` + `userText?: string` 三个顶层字段
- 新版合并成 `payload: DispatchPayload`,imageUri 移到 payload 内,userText 移到 payload 内(image / file 分支)
- 已 build 验过无 caller 在用(只有 Dispatcher 自己),可大胆升级

### 3.4 `TruthCheckResult` / `TruthFlag`

**路径:** `common/src/main/ets/models/CaptureChain.ets`

```typescript
export type TruthFlag =
  | '括号不配对' | '除零' | '恒等式' | '矛盾等式'
  | 'LaTeX语法错误' | 'OCR置信度低' | '无明确题目';

export interface TruthCheckResult {
  passed: boolean;
  flags: TruthFlag[];
  message?: string;
}
```

### 3.5 业务阈值

```typescript
export const CLASSIFY_CONFIDENCE_THRESHOLD: number = 0.7;
```

---

## 四、错误处理约定

| 场景 | 返回 |
|------|------|
| Dispatcher catch 任何异常 | `success: false, errorMessage: '拍照处理失败: ...'` |
| D classify 失败 | throw Error → Dispatcher catch |
| L structure 失败 | throw Error → Dispatcher catch |
| NoteDao.insert 失败 | throw Error → L 透传 → Dispatcher catch |
| confidence < 0.7 | D 决定是否返 errorMessage (MVP 不强制) |

**所有失败不抛到 UI,统一由 Dispatcher catch 返 `DispatchResult{success:false}`。**

---

## 五、调用方约定 (AiService)

**AiService.capture(imageUri)** 是 UI 调 Dispatcher 的薄 service 层(MVP 不在我责任,UI 端做):
- 读 imageUri → base64
- 调 `new Dispatcher().dispatch({source:'app', payload:base64, imageUri})`
- 成功:返 KnowledgeUnit
- 失败:throw Error(UI 显示 toast)

---

## 六、当前 mock 边界

| 类 | 当前状态 | D/L 接手时 |
|----|---------|-----------|
| `Dispatcher` | **真实现** (76 行) | 不动 |
| `TypeClassifier.classify` | **mock** (返固定 ClassificationResult) | 替换 method body 写真实现 |
| `KnowledgeModel.structure` | **mock** (返 18 字段 mock KnowledgeUnit) | 替换 method body 写真实现 + 内部调 NoteDao.insert |
| `NoteDao` | **空 class** | 加 `insert()` + `queryById()` method |

**整链 跑通(数据 mock) 已 build 验证。** 等 D/L 写真后数据变真,再 build 一次 + 跑端到端。

---

## 七、LLM 共享基础设施 (Z 2026-07-14 新增)

### 7.1 设计目标

- **统一入口**: 所有 agent(TypeClassifier / KnowledgeModel / 未来的 ReviewAgent 等)用同一个 `LlmClient`
- **API key 运行时录入**: UI 输入 → preferences 持久化,重启不丢
- **可换 provider**: 改 LlmConfig endpoint/model 即可,接口不变(OpenAI 兼容)
- **共享 LlmConfig 单例**: UI 设置 + Agent 读取走同一份

### 7.2 文件位置

```
common/src/main/ets/llm/
  LlmTypes.ets    # 类型:ChatMessage / LlmResponse / LlmError / LlmCallOptions
  LlmConfig.ets   # 单例,preferences 持久化 API key
  LlmClient.ets   # OpenAI 兼容 HTTP 客户端

common/src/main/ets/Index.ets
  # 公共导出:
  export { LlmConfig, LlmClient, LlmError } from '...';
  export type { ChatMessage, LlmCallOptions, LlmErrorKind } from '...';
```

### 7.3 `LlmConfig` 单例

```typescript
import { LlmConfig } from 'common';

// 1) App 启动时(D 责任:在 EntryAbility.onCreate 加一行)
await LlmConfig.getInstance().init(this.context);

// 2) UI 输入 API key(D 责任:Settings 页 input 按钮)
await LlmConfig.getInstance().setApiKey(userInput);

// 3) 任何 agent 读 key / 端点 / 模型
const key: string | null = await LlmConfig.getInstance().getApiKey();
const isSet: boolean = await LlmConfig.getInstance().isConfigured();
const endpoint: string = LlmConfig.getInstance().getEndpoint();
const model: string = LlmConfig.getInstance().getModel();
const temperature: number = LlmConfig.getInstance().getTemperature();
const maxTokens: number = LlmConfig.getInstance().getMaxTokens();
const timeoutMs: number = LlmConfig.getInstance().getTimeoutMs();
```

**MVP 默认值**(后续可改 runtime 配置):
- endpoint/base_url: `https://api.deepseek.com`
- model: `deepseek-v4-pro`
- temperature: `0.1`
- max_tokens: `12000`
- timeout: `120000ms`

**存储**: HarmonyOS preferences
- store name: `llm_config`
- key: `api_key`(string)

**D 必须加的 1 行**(`entry/src/main/ets/entryability/EntryAbility.ets` 的 `onCreate` 里):
```typescript
import { LlmConfig } from 'common';

// 在 hilog.info('testTag', ..., 'Ability onCreate') 之前加:
LlmConfig.getInstance().init(this.context).catch((e: Error) => {
  hilog.error(0x0000, 'testTag', 'LlmConfig init failed: %{public}s', JSON.stringify(e));
});
```

> 没 init() 就调 setApiKey / getApiKey → 抛 `LlmError(kind='NOT_INITIALIZED')`

### 7.4 `LlmClient` 调用

```typescript
import { LlmClient, LlmError, type ChatMessage } from 'common';

const client = new LlmClient();
try {
  const text: string = await client.call([
    { role: 'system', content: '你是数学分类器...' },
    { role: 'user', content: '求行列式 |A|' },
  ]);
  // 解析 text 为 JSON 或业务对象
} catch (e) {
  if (e instanceof LlmError) {
    switch (e.kind) {
      case 'NO_API_KEY':        // 提示用户去 Settings 配 key
      case 'NETWORK_ERROR':     // 网络问题,可重试
      case 'API_ERROR':         // 看 message(可能 401 key 错 / 429 限流)
      case 'PARSE_ERROR':       // 响应不是 JSON
      case 'EMPTY_RESPONSE':    // choices[0].content 为空
      case 'NOT_INITIALIZED':   // LlmConfig 没 init
      case 'TIMEOUT':           // 超时
    }
  }
}
```

**opts 覆盖默认**(可选):
```typescript
await client.call(messages, {
  temperature: 0.3,    // 不传则用 LlmConfig 默认
  maxTokens: 1024,
  model: 'deepseek-ai/DeepSeek-V2.5',
  timeoutMs: 10000,
});
```

### 7.5 集成到现有 agent 的方式

**D 改 TypeClassifier.classify 真实实现时**:
```typescript
import { LlmClient, LlmError, type ChatMessage } from 'common';

const client = new LlmClient();
const text: string = await client.call([
  { role: 'system', content: '你是分类器。返回 JSON {type, subject, chapter, confidence}。' },
  { role: 'user', content: cleanText },
]);
const parsed: ClassificationResult = JSON.parse(text) as ClassificationResult;
```

**L 改 KnowledgeModel.structure 真实实现时**:同 pattern

**未来 ReviewAgent / QueryAgent 等**:也是 `new LlmClient().call(messages)`

### 7.6 当前实现状态

| 类 | 状态 | 备注 |
|----|------|------|
| `LlmTypes.ets` | ✅ 完成 | 类型 + LlmError class |
| `LlmConfig.ets` | ✅ 完成 | 单例 + preferences,需要 D 在 EntryAbility.onCreate 调 init() |
| `LlmClient.ets` | ✅ 完成 | OpenAI 兼容,统一调用入口 |
| `LlmConfig.init()` 调用 | ❌ **D 责任** | EntryAbility.onCreate 加 1 行 |
| UI 输入 API key 入口 | ❌ **D 责任** | Settings 页加 input + save 按钮 |
| TypeClassifier 用 LlmClient | ❌ **D 责任** | 替换 stub body |
| KnowledgeModel 用 LlmClient | ❌ **L 责任** | 替换 stub body |

---

## 八、相关文档

- `D:\HMgent\MindTrace\docs\agent_to_ui_q1q4_reply.md` — 之前给 UI Mavis 的 Q1-Q4 回复(架构问答)
- `C:\Users\YunCeH\Desktop\后端\Math_Mind\docs\AGENT_COMMUNICATION.md` — 通信模式(同进程 import)
- `C:\Users\YunCeH\Desktop\后端\Math_Mind\docs\DISPATCHER_TONIGHT.md` — Dispatcher 精简版规范
- `C:\Users\YunCeH\Desktop\后端\Math_Mind\docs\D1_CAPTURE_CHAIN_PLAN.md` — D1 链精简版设计

---

*此文档为活文档,接口变化时同步更新*
