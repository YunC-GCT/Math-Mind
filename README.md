# MathMind · 当前状态

> 工程: YunC-GCT/Math-Mind · 5 module HarmonyOS 数学学习助手  
> 创建/维护: Z(由 Mavis 代笔) · 最近更新: 2026-07-13 17:53

---

## 一、完成的工作

### 1.1 W0 末 · 5 module 工程搭起来 (commit `bfaa8e5`)

```
MathMind/
├── entry/       # HAP · type:entry    主 App
├── common/      # HSP · shared        共享类型 + 工具
├── agents/      # HSP · shared        核心业务 Agent
├── skill/       # HAP · type:feature  小艺 Skill
└── cardservice/ # HAP · type:feature  元服务卡片
```

编译: 5/5 module BUILD SUCCESSFUL · entry 显示 "Hello from common v1! | v0.0.1"

### 1.2 W1 块 2 · common 共享层 + 工具 (5 commits)

- `fc889f6` feat(z-w1-file1): **CommonTypes** 共享类型 (KnowledgeUnit / ReviewRecord / KGNode / KGEdge / AgentTask / AgentResponse / ApiError + 3 enum)
- `127343c` feat(z-w1-file2): **logger** 统一日志
- `3c729e2` feat(z-w1-file3): **uuid** 生成
- `68b8c5b` feat(z-w1-file4): **timeWindow** 时间窗工具
- `ccb1345` feat(z-w1-file5): **confidenceSort** 置信度排序
- `610c9d2` docs: README 全面改写 (W0 阶段说明 + W1 进度 + 接手指南) — *此 README 即将被本文件覆盖*
- `d6220c4` merge: feature/z-w1-block2 → main (含 31eaa04/88fbb99 两条 GitHub web README 标题修订)

### 1.3 GitHub Web 标题修订

- `31eaa04` Update project title in README to include '源码' — 作者 YunCeH
- `88fbb99` Update project title in README.md — 作者 shi

### 1.4 D1 精简拍照链骨架 + 编译验证 (2026-07-13 17:48)

**做了什么**: 8 个目标文件全部建好空壳 + DevEco build 验证通过。

**8 个文件当前位置**(全部都是空类,只有 TODO 注释,没有任何实际功能):

| 文件 | 责任 | 当前内容 |
|------|------|---------|
| `entry/database/NoteDao.ets` | L | 空 `export class NoteDao {}` + TODO(A1) 注释 |
| `entry/services/ApiClient.ets` | 你+Mavis | 空 `export class ApiClient {}` + TODO(A2) 注释 |
| `entry/services/AiService.ets` | 你+Mavis | 空 `export class AiService {}` + TODO(E1) 注释 |
| `entry/overlays/CameraOverlay.ets` | 你+Mavis | 空 `export class CameraOverlay {}` + TODO(E2) 注释 |
| `agents/core/Dispatcher.ets` | 你+Mavis | 空 `export class Dispatcher {}` + TODO(D) 注释 |
| `agents/agents/TypeClassifier.ets` | D | 空 `export class TypeClassifier {}` + TODO(B2) 注释 |
| `agents/agents/KnowledgeModel.ets` | L | 空 `export class KnowledgeModel {}` + TODO(C) 注释 |
| `agents/mcp/tools/OcrTool.ets` | D | 空 `export class OcrTool {}` + TODO(B1) 注释 |

每个空壳顶部都有完整的接口约定注释(入参/返回/责任/依赖/验证方式),等责任人填实现。

**新目录**(按 DIRECTORY_MAP 精简链布局):
- `agents/src/main/ets/agents/`
- `agents/src/main/ets/core/`
- `agents/src/main/ets/mcp/tools/`
- `entry/src/main/ets/database/`
- `entry/src/main/ets/overlays/`
- `entry/src/main/ets/services/`

**编译验证**: `hvigor BUILD SUCCESSFUL in 24 s 709 ms`
- common HSP / agents HSP / entry HAP / skill HAP / cardservice HAP **5/5 全过**
- 唯一 WARN: signingConfigs 未配(模拟器 unsigned OK,按之前规矩暂不配)

**没做什么**:
- ❌ 8 个文件都**没有任何业务实现**(只是 `export class {}`)
- ❌ 没写 NoteDao.insert / ApiClient.request / Dispatcher.routeDispatch 等实际方法
- ❌ 没接 LLM / OCR / RDB / HTTP
- ❌ 没改 UI(EntryAbility / Index.ets 跟 W0 一样,显示 "Hello from common v1! | v0.0.1")
- ❌ 没 push 到 GitHub(本地 3 个 commit 待推)

---

## 二、需要实现的工作 — 7/13 今晚 D1 精简拍照链

> 目标: 拍照 → OCR → DeepSeek 3×3 分类 → 3 模板 → 真值检验 → 入库 → 显示  
> 整链时序见 `docs/D1_CAPTURE_CHAIN_PLAN.md` · 详细分工见 `docs/TONIGHT_TASKS.md`

### 2.0 3 角色分工总览

| 角色 | 文件数 | 编号 | 关键交付 |
|------|--------|------|---------|
| **主+UI** | 4 | A2 + D + E1 + E2 | 拍照按钮 → 出笔记卡 · 整链可跑通 |
| **分类** | 2 | B1 + B2 | 拍图 → 返回 {3×3 分类, confidence>0.7} |
| **写笔记** | 2 | A1 + C | 文本+分类 → KnowledgeUnit 入库 · 真值检验标红 |

3 人各自开 `feature/xxx` branch,各 clone 仓库独立开发,完事 push 给 leader 集成。

---

### 2.1 角色 A · 主+UI (4 文件) — 你 + Mavis

**接手文件**:
1. `entry/src/main/ets/services/ApiClient.ets` (A2)
2. `agents/src/main/ets/core/Dispatcher.ets` (D)
3. `entry/src/main/ets/services/AiService.ets` (E1)
4. `entry/src/main/ets/overlays/CameraOverlay.ets` (E2)

**预期要达到什么**:

#### A2 ApiClient — HTTP 客户端
实现 `request(method, path, options): Promise<ApiResponse>`
- 注入 JWT (`Authorization: Bearer ...`)
- 401 时尝试 1 次 token 刷新后重试
- **验收**: `curl https://<后端>/health` 返回 200(用 ApiClient.request 调一次后端 health 端点)

#### D Dispatcher — 主 Agent 调度
实现 `routeDispatch(req: DispatchRequest): Promise<DispatchResult>`
- L1 关键词匹配: `text ∈ {'记','拍','这题','笔记','题'}?` → 命中 D1
- D1 分支: `TypeClassifier.classify(...)` → `KnowledgeModel.structure(...)` → 返回 KnowledgeUnit
- **验收**: `POST /agents/dispatch` 传 base64 → 返回 `{ success:true, route:'D1', data: KnowledgeUnit, durationMs }`

#### E1 AiService — 拍照调用 Dispatcher
实现 `capture(imageUri: string): Promise<KnowledgeUnit>`
- imageUri → 读文件 → base64
- `ApiClient.request('POST', '/agents/dispatch', { body: { source:'app', payload: base64, imageUri } })`
- 解析响应,返回 KnowledgeUnit
- **验收**: 日志打 `note.id`(可先用硬编码 base64 自测,不等 E2 相机)

#### E2 CameraOverlay — 相机/相册 UI 组件
实现 `@Component struct CameraOverlay` (UI 浮层)
- 触发: 用户点首页 FAB [+] 弹出
- 功能: 相机预览 + 快门按钮 + 相册按钮
- 拍/选完: imageUri → `AiService.capture(imageUri)` → 拿 KnowledgeUnit → 关 overlay → 通知 HomePage 刷新
- **验收**: 点快门 → 拍照 → 日志见 `note.id` → HomePage 列表头出现新笔记卡

**完成定义 (DoD)**:
- ✅ 4 个文件都有真实实现(非空壳)
- ✅ DevEco build 通过
- ✅ 端到端: 点 FAB [+] → 拍照 → 笔记卡显示(拍"求极限 lim(x→0) sinx/x"应得【计算】卡)

---

### 2.2 角色 B · 分类 (2 文件) — D

**接手文件**:
1. `agents/src/main/ets/mcp/tools/OcrTool.ets` (B1)
2. `agents/src/main/ets/agents/TypeClassifier.ets` (B2)

**预期要达到什么**:

#### B1 OcrTool — ML Kit OCR
实现 `recognize(imageBase64: string): Promise<string>`
- 调 HarmonyOS ML Kit Vision API (`@ohos.ai.mlnlp.textRecognition`)
- 输入 base64 → 解码为 PixelMap → 调 OCR → 返回文本
- **验收**: 传一张含数学公式的图 → 返回非空文本

#### B2 TypeClassifier — 3×3 分类
实现 `classify(input: { ocrText?, imageBase64? }): Promise<ClassificationResult>`
- 如传 imageBase64,先调 `OcrTool.recognize` 拿文本
- `cleanText` (TextUtils 清洗)
- 调 LLM (默认 SiliconFlow / DeepSeek-V3,端点 `api.siliconflow.cn`, Temperature 0.1, MaxTokens 256, Timeout 5s)
- 精简版 Prompt (3 学科 × 3 类型,见 D1_CAPTURE_CHAIN_PLAN.md 第四节)
- 解析 JSON → `ClassificationResult`
  ```typescript
  {
    type: '概念' | '计算' | '证明',
    subject: '高等代数' | '数学分析' | '解析几何',
    chapter?: string,
    confidence: number  // 0.0-1.0
  }
  ```
- **验收**: 传文字 `"求行列式 |A|"` → 返回 `{ type:'计算', subject:'高等代数', confidence: ≥ 0.7 }`

**完成定义 (DoD)**:
- ✅ 2 个文件都有真实实现
- ✅ DevEco build 通过
- ✅ 自测 9 个样例 (3 类 × 3 学科) 准确率 ≥ 80%
- ✅ 失败有降级: LLM 调不通时返回 `confidence: 0`,不抛异常

---

### 2.3 角色 C · 写笔记 (2 文件) — L

**接手文件**:
1. `entry/src/main/ets/database/NoteDao.ets` (A1)
2. `agents/src/main/ets/agents/KnowledgeModel.ets` (C)

**预期要达到什么**:

#### A1 NoteDao — RDB 数据访问
实现 `insert(unit: KnowledgeUnit): number` + `queryById(id: string): KnowledgeUnit | null`
- 用 `@ohos.data.relationalStore` (RdbStore)
- 表结构见 `common/src/main/ets/DatabaseHelper.ets`
- **验收**: `insert(unit)` → 返回 rowId → `queryById(rowId)` 查回同一对象

#### C KnowledgeModel — 模板 + 真值 + 入库
实现 `structure(ocrText, classification): Promise<KnowledgeUnit>`
- 根据 `classification.type` 选 3 模板之一:
  - `概念` → `concept_v1`: `## 定义 / ## 性质 / ## 相关概念`
  - `计算` → `computation_v1`: `## 题目 / ## 解法 / ## 答案`
  - `证明` → `proof_v1`: `## 命题 / ## 证明 / ## 要点`
- title: 首句摘要(≤30 字),前缀 `【概念】/【计算】/【证明】`
- 构造 KnowledgeUnit(含 id / tags / timestamps / truthFlag)
- `truthCheck(ocrText)` 返回 `TruthCheckResult`:
  - 括号配对 ( ) [ ] { }
  - 除零检测 `/0` `÷0` → error
  - 矛盾等式 `1=2` `0=1` → error
  - LaTeX `$` `{` `}` 配对
- `NoteDao.insert(unit)` → rowId → 回填 unit.id
- 返回完整 KnowledgeUnit
- **验收**: 传 OCR 文本 + 分类结果 → KnowledgeUnit → insert → queryById 查回

**完成定义 (DoD)**:
- ✅ 2 个文件都有真实实现
- ✅ DevEco build 通过
- ✅ 3 模板各跑通 1 个样例
- ✅ 真值检验: 至少 1 个 error 样例能被标红(例:`1=2` → truthFlag='error')

---

### 2.4 端到端验收 (集成后由 Mavis 跑)

```
1. 打开 App → 点首页 FAB [+] → 选拍照
2. 拍一张数学题 (如"求极限 lim(x→0) sinx/x")
3. 等待 2-3 秒
4. HomePage 笔记列表顶部出现新卡片:【计算】求极限 lim(x→0) sinx/x
5. 点卡片 → 看到模板正文 (## 题目 / ## 解法 / ## 答案)
```

任一步失败 → 回对应负责人修 → 修完再集成。

### 2.2 关键约束 (摘自 D1_CAPTURE_CHAIN_PLAN.md)

**LLM 配置**:
- 默认 Provider: **SiliconFlow / DeepSeek-V3** (`deepseek-ai/DeepSeek-V3`)
- 端点: `https://api.siliconflow.cn/v1/chat/completions`
- Temperature: **0.1** · MaxTokens: **256** · Timeout: **5s**
- 降级链: DeepSeek → 小艺Kit → Mock

**3×3 分类体系**:
- 学科: 高等代数 / 数学分析 / 解析几何
- 类型: 概念 / 计算 / 证明

**3 模板** (KnowledgeModel 用):
- `concept_v1` (定义/性质/相关概念)
- `computation_v1` (题目/解法/答案)
- `proof_v1` (命题/证明/要点)

**真值检验** (KnowledgeModel.truthCheck):
- 括号配对 ( ) [ ] { }
- 除零检测 /0 ÷0
- 恒等式校验 sin²x+cos²x=1 / e^(iπ)+1=0
- 矛盾等式 (1=2, 0=1) → error
- LaTeX 语法 $ $ { } 配对
- 结果 `truthFlag: 'valid' | 'warning' | 'error'`,UI 只对 error 标红

### 2.3 依赖顺序 (3 人组内串行 / 组间可并行)

```
你 + Mavis (4 文件)        D (2 文件)              L (2 文件)
─────────────────         ──────────              ──────────
A2 (ApiClient)  ──┐
                  ├── D (Dispatcher) ──┐
                  │                     ├── E1 (AiService)  ← 集成时
                  │                     │   E2 (CameraOverlay) ← 调用 AiService
                  │
                  │       B1 (OcrTool) ──┐
                  │                       ├── B2 (TypeClassifier)
                  │                       │
                  │                       A1 (NoteDao) ──┐
                  │                                       ├── C (KnowledgeModel)
                  │                                       │
                  └──────────────────────────────────────┘
                              ↓ 集成时再串起来
                  C 被 D 调用 · D 被 E1 调用 · E1 被 E2 调用
```

**3 组内部串行 / 3 组间并行**：
- **你 + Mavis**: 先 A2 (HTTP) → 后 D (路由) → 最后 E1+E2 (UI)
- **D**: 先 B1 (OCR) → 后 B2 (分类)
- **L**: 先 A1 (DB) → 后 C (建模)
- **集成**: 3 组完成后，由你 merge 3 个 feature branch 到 main

### 2.4 整链接口契约

```
POST /agents/dispatch
  请求: { source: "app", payload: "<base64图片>", imageUri: "file://..." }
  响应: { success, route: "D1", data: KnowledgeUnit, durationMs }
```

---

## 三、构建与运行

- **build 走 DevEco Studio GUI** (Build → Build Hap(s)/APP(s)),不走命令行 hvigorw (中文路径乱码)
- **SSH 走 port 443** (`~/.ssh/config` 已配 Host github.com → ssh.github.com:443)
- **作者固定** `YunC-GCT <2549237929@qq.com>` (`git config user.name/email` 已配)

---

## 四、git 规则

1. **未经明示禁止 push** — 本地 commit 自由,推送必须 leader 点头
2. **删除走 mavis-trash / 回收站** — 不直接 `Remove-Item -Recurse -Force`
3. **失败 2 次停下报告** — 不无限重试,贴报错最后 5 行
4. **改完即 commit** — 单文件单 commit,feat/fix/docs 前缀
5. **每块结束推一次** — 拿到 leader 点头再 push,不全攒到最后

---

## 五、相关文档 (在 `D:\HMgent\MathMind方案\`)

- `D1_CAPTURE_CHAIN_PLAN.md` — 精简拍照链整链设计
- `DIRECTORY_MAP.md` — 四层目录 (模板/精简/完整/MVP)
- `TONIGHT_TASKS.md` — 7/13 今晚任务分工与时间线
- `AGENT_ARCH_v3.1.md` — Agent 架构
- `API_SPEC.md` — 23 API 端点
- `TWO_AXIS_CLASSIFICATION.md` — 两轴分类说明
- `LOCAL_VS_API_STRATEGY.md` — 本地 vs 云端策略
