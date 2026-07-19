# MathMind · 数学学习助手

> 工程: [YunC-GCT/Math-Mind](https://github.com/YunC-GCT/Math-Mind) · HarmonyOS 数学学习助手
> 作者: YunC-GCT <2549237929@qq.com> · 当前主笔: Z
> 最近更新: 2026-07-19

---

## 2026-07-19 本地同步与首页布局修正

> 主 Agent 显式生成笔记 + Memory 专项改动详见 [`docs/agent-memory-flow-20260719.md`](./docs/agent-memory-flow-20260719.md)。

### 做了什么

- 将 `agents/src/main/ets/agents/TypeClassifier.ets`、`agents/src/main/ets/mcp/tools/OcrTool.ets` 和 `common/` 覆盖为 `origin/main` 版本,确认本地 UI 主线可以继续跑通。
- 首页 `HomeRecentNotes` 增加 `compact` 布局参数: 收起复习环时列表继续占满剩余空间,非收起态按自然高度紧跟在“最近笔记”标题下方。
- 收紧非收起态“最近笔记”标题与第一条笔记卡片之间的间距,避免生成笔记后卡片位置下沉。
- 记录 `7ba5169 feat(agent): add explicit note memory flow` 的新增/修改文件、memory 策略、意图识别和生成笔记链路。

### 验证

- 已做文件级 `git diff --check`。
- DevEco Studio GUI 编译和真机 smoke test 仍需手动执行。

---

## 2026-07-18 本轮重构记录

### 做了什么

- 调整 DeepSeek 大模型连接方式: 设置页使用 OpenAI 兼容 `base_url`(`https://api.deepseek.com`), `LlmClient` 内部自动拼接 `/chat/completions`。
- 修复 AI 设置页“测试连接”误判失败的问题: 大模型实际已可用,之前失败原因是测试请求 `max_tokens=16` 导致 V4-Pro 输出被截断。
- 统一模型入口为 `deepseek-v4-pro`,旧的 V3 / Flash / R1 配置在加载和保存时会归一化到 V4-Pro。
- AI 设置页失败状态会显示具体错误摘要,便于区分 Key 错误、端点错误、模型错误和网络错误。
- 同步 OCR 设置页测试入口、本地 OCR endpoint 配置、笔记详情页 LaTeX/分段渲染、KnowledgeModel 输出结构化内容等前序改动。

### 已完成

- DeepSeek API Key、模型名和网络链路已经验证可用。
- LLM 默认配置已从旧 SiliconFlow / V3 配置切换到 DeepSeek OpenAI 兼容 base_url + V4-Pro。
- AI 设置页测试逻辑已避免短 token 截断导致的假失败。
- 拍照/OCR/分类/KnowledgeModel/入库/UI 渲染主链路已具备端到端运行基础。

### 还需要处理

- 重新用 DevEco Studio 编译并真机验收 AI 设置页测试结果。
- 补齐 AI 浮窗多轮对话: 需要把当前会话历史按 DeepSeek 无状态 API 要求拼进 `messages`。
- 给 TypeClassifier / KnowledgeModel 增加 `response_format: { type: "json_object" }` 和更严格的 JSON schema 校验,减少静默 fallback。
- 继续降低“失败即占位笔记”的数据污染风险,让 OCR/LLM 失败在 UI 上更明确。
- 后续再处理笔记页面、知识图谱宇宙视图、复习页和剩余 UI 对齐。

---

## 当前状态：拍照→AI→入库 整链已跑通 ✨ · 2026-07-18

选图 → 发送 → OCR 识别 → TypeClassifier 五分类 → KnowledgeModel LLM 结构化 → RDB 持久化 → 笔记列表自动刷新，全链路闭环。

### 本次 Session 关键修复

| 修复 | 说明 |
|------|------|
| **deepseek-v4-pro 连接与响应** | LlmClient 统一走 DeepSeek 官方端点，旧值会自动归一化 |
| **TypeClassifier 五分类对齐** | `type` 从三分类改为 `NoteCategory` (概念/定理/公式/证明题/计算题)，对接 KnowledgeModel |
| **Subject 自由判定** | 不再限制三选一，LLM 自由输出学科名称 |
| **KnowledgeModel prompt 精简** | 中文→英文对齐 TypeClassifier 风格 |
| **maxTokens 8000 · 超时 30 分钟** | 推理模型需要更大输出空间和时间 |
| **OCR multiFormDataList → 手动 multipart** | HarmonyOS 沙箱兼容，extraData 发送 |
| **AgentFloatWindow 完整版恢复** | 拖拽缩放 + 多会话 + 自动滚底 + ChatHeader/QuickSuggestions/ChatBubble |
| **AgentChatService 业务分离** | UI 层零异步逻辑 |
| **OverlayService 浮层统一调度** | 相机/浮窗互斥，加新浮层不改 Index |
| **NoteDetailOverlay 拆分** | 8 组件 + v2-ui 风格对齐 |
| **NoteCard 对齐 v2-ui .note-card** | 简化 meta 行 + 标题 15px + 原文预览 |
| **GradientRing 删笔记后动画修复** | `@Watch restartAnimation` |
| **动效令牌对齐 v2-ui motion.css** | DUR_INSTANT/FAST/BASE/SLOW/SLOWER/SLOWEST |
| **原子层补齐 ChipTag + ConfDot** | 对齐 v2-ui chips/badges |
| **删除死代码** | TypingIndicator/MessageInput/ChatTextSanitizer/agent/AgentMessageList/ApiClient |

### 已知不足

| 问题 | 详情 |
|------|------|
| **OCR 速度慢** | PaddleOCR CPU ~28s/张，总耗时约 30s |
| **OCR 需本地服务** | 依赖 start.bat 启动 FastAPI，模拟器需改 LAN IP |
| **文字 OCR 不可用** | Tesseract 未安装，只有公式识别 |
| **LLM 依赖网络** | DeepSeek API 需联网，免费版不稳定偶发超时/空响应 |
| **无单元测试** | 整链无自动化验证 |
| **会话持久化未接入** | ChatSession 有实现但 AgentFloatWindow 未接入 UI |

### 待调整

| 任务 | 状态 |
|------|------|
| SessionBar 会话切换 UI 接入 | 代码已有，待 UI 展示 |
| CameraOverlay 迁到 overlays/ | 仍在 prototypes/ |
| NoteTagChip → ChipTag 统一 | 旧 NoteTagChip 可退役 |
| 首页 Hero + Profile 页 v2-ui 对齐 | 待做 |

---

## 一、当前状态总览

MathMind 是一个 HarmonyOS 数学学习助手,通过 **拍照 → OCR → AI 分类 → 知识结构化 → 持久化 → 复习**的整链,把"看到的数学题"变成"可复习的知识"。

### 1.1 已实现功能

| 功能 | 说明 | 验证方式 |
|------|------|---------|
| **拍照→AI 整链** ✨ | 拍照 → OCR → 分类 → 结构化 → 入库,全自动 | 真机拍照,Toast 提示笔记生成 |
| 5 Tab 底部导航 | 首页 / 笔记 / AI / 复习 / 我的 | DevEco 运行可见 |
| 拍照浮层 | `cameraPicker.pick()` 调系统相机,模拟器降级 mock | 真机点快门 |
| 相册选图 | `PhotoViewPicker.select()` 调系统图库 | 模拟器点相册按钮 |
| AI 浮窗真实对话 | `LlmClient.call()` → DeepSeek 官方,支持 V3.2 / R1 / V4-Pro / V4-Flash | 设置页配 API Key → 发消息 |
| AI 设置页 | API Key 显隐 / 测试连接 / 参数调优 / 恢复默认 | 我的 → 模型配置 |
| 学习计划 | PlanListView + PlanInputBar + PlanStatsBar + DAO + ViewModel | 我的 → 学习计划 |
| 笔记详情浮层 | 章节解析 + 标签 + AI 卡 + 操作栏 + 删除 | 首页/笔记页点卡片 |
| 进度环呼吸光晕 | Canvas 渐变弧 + 三角波呼吸动画 | 首页 |
| 浮窗键盘避让 | 监听 keyboardHeightChange + `.translate` 动态上移 | AI 浮窗聚焦输入框 |
| LLM 配置持久化 | `preferences` 存储,启动恢复 | 重启 App 配置保留 |

### 1.2 待实现 / 验证

| 任务 | 阻塞 / 状态 | 负责人 |
|------|---------|--------|
| 整链真机端到端验证 | 整链代码已就位,需真机拍照 1 张图看是否入库 + 列表显示 | Z |
| StudyPlan LLM 自动生成 | 数据库/ViewModel 已就位,缺 UI 触发调用 LLM | L |
| 真机 V4 模型验证 | 需要 DeepSeek 官方 API Key 余额 | 用户 |

### 1.3 历史 bug 全部解决

- ✅ Index.ets `onCameraConfirm` 不调 `AiService.capture()` 整链缺最后 1 公里 — `5b6f155` 已修
- ✅ KnowledgeModel 从 stub → 真实实现(MVP 合并 644 行) — `81a6ef6`
- ✅ NoteDao 从空壳 → 完整 CRUD — `81a6ef6`
- ✅ LlmConfig 默认值 / 保存 / 加载 — 之前修过
- ✅ Index.ets AI Tab 跳转占位 — `321762c` 已修

---

## 二、5 module 工程结构

```
MathMind/
├── entry/        # HAP · type:entry      主 App(UI + 浮层 + 数据库 + ViewModel)
├── common/       # HSP · shared          共享类型 + 工具 + LLM + MockData
├── agents/       # HSP · shared          OCR/分类/知识建模 pipeline
├── skill/        # HAP · type:feature    小艺 Skill
└── cardservice/  # HAP · type:feature    元服务卡片
```

编译状态: 5/5 module BUILD SUCCESSFUL(走 DevEco Studio GUI,不走命令行 hvigorw)。

---

## 三、已完成的工作(按时间顺序)

### 3.1 W0 · 工程搭建 (commit `bfaa8e5`)

5 module HarmonyOS 工程脚手架建好,5/5 module 编译通过。

### 3.2 W1 公共层 (5 commits, 2026-07-13)

合并 PR `d6220c4`(feature/z-w1-block2 → main):

| Commit | 内容 |
|--------|------|
| `fc889f6` | **CommonTypes** 共享类型(KnowledgeUnit / ReviewRecord / KGNode / KGEdge / AgentTask / AgentResponse + 3 enum) |
| `127343c` | **logger** 统一日志工具 |
| `3c729e2` | **uuid** 生成工具 |
| `68b8c5b` | **timeWindow** 时间窗工具 |
| `ccb1345` | **confidenceSort** 置信度排序工具 |

### 3.3 D1 精简拍照链骨架 (2026-07-13)

8 个目标文件全部建好空壳 + DevEco build 验证通过。后续 D + L 接手填真实现。

### 3.4 W1 · 5 Tab + 浮层 UI (2026-07-14)

- `Index.ets` — 5 Tab 装配,沉浸式状态栏
- `HomePage.ets` — Hero + 进度环 + 笔记列表 + FAB
- `CameraOverlay.ets` — 拍照/相册/快门/重拍/确认
- `AgentFloatWindow.ets` — AI 对话(已接 LlmClient,真实回复)
- `NoteDetailOverlay.ets` — 笔记详情(章节解析 + AI 卡)

### 3.5 center 合并 · AI 设置页 + DeepSeek V4 (2026-07-14)

`53b09c0` merge: center → main

- **AiSettingsPage** — 端点/模型/API Key/参数/测试连接
- **LlmConfig 运行时配置** — `saveAll()` + `loadAll()` 持久化
- **DeepSeek V4 模型** — `deepseek-v4-pro`
- **全 Agent 接入 DeepSeek** — TypeClassifier 通过 `LlmClient.call()` 调 LLM

### 3.6 CameraOverlay · 真实 CameraPicker (2026-07-14)

- `9db3309` `cameraPicker.pick()` 系统相机(无需 CAMERA 权限)
- `56229ec` `cameraPosition: CAMERA_POSITION_BACK` 枚举 + 空值防护
- `e155fae` 相册 SVG + 快门 MINT 色 + 模拟器 toast
- `33d3a5d` + `40508ae` module.json5 加 CAMERA + INTERNET 权限

### 3.7 AgentFloatWindow · 真实 LLM (2026-07-14)

- `7e3f4da` `realReply()` 替代 mock: `LlmClient.call()` → DeepSeek
- 系统提示词: "你是 MathMind AI 助手,用简洁中文回答数学问题,适当使用 LaTeX"
- 错误分类: `NO_API_KEY` / `NETWORK_ERROR` / 其他(截断显示)

### 3.8 编译修复 + 代码清理 (2026-07-14)

- `ef0cca3` 类型重命名 `DispatchPayloadImage → ImagePayload` + 桶导出对齐
- `1a1f8a7` LlmClient 错误序列化改 `(e as Error).message`
- `8053cfa` AiSettingsPage save 后 `loadConfig()` 刷新 UI
- 删 `ingestImage()` + mock reply 残留

### 3.9 Local OCR pipeline 接入 TypeClassifier (2026-07-15)

`babdba8` 本地 OCR HTTP 客户端:

- `OcrTool.ets` 改用 HarmonyOS `http.request()` + `multiFormDataList` 上传图片
- 默认端点 `http://127.0.0.1:8000/api/v1/ocr/recognize`(模拟器/真机改成工作站 LAN IP)
- 合并 OCR 文本 + LaTeX 公式
- TypeClassifier 调 DeepSeek 返回 `{ type, subject, chapter, confidence }`,失败降级本地规则

### 3.10 Z 端 refactor · pages 重组 + MVP 合并 (2026-07-17)

`81a6ef6 refactor: organize pages and merge MVP knowledge model`

**(A) Pages 重组** — 单文件 pages/ → 每个 page 一个子文件夹:

| 改前 | 改后 |
|------|------|
| `pages/HomePage.ets` | `pages/Home/HomePage.ets` + `HomeTopBar.ets` + `HomeRecentNotes.ets` |
| `pages/MePage.ets` | `pages/Profile/ProfilePage.ets` + `ProfileHeader.ets` + `ProfileStatsRow.ets` + `ProfileMenuList.ets` + `ProfileMenuItemRow.ets` |
| `pages/NotesPage.ets` | `pages/Notes/NotesPage.ets` + `NotesHeader.ets` + `NotesList.ets` + `NotesEmptyState.ets` |
| `pages/ReviewPage.ets` | `pages/Review/ReviewPage.ets` |
| `pages/StudyPlanPage.ets` | `pages/StudyPlan/PlanHeader.ets` + `PlanInputBar.ets` + `PlanListView.ets` + `PlanStatsBar.ets` + `StudyPlanPage.ets` |
| `pages/AiSettingsPage.ets` | `pages/AiSettings/AiSettingsPage.ets` + `ActionBar.ets` + `ConnectionStatus.ets` + `EndpointPicker.ets` + `KeyInput.ets` + `ModelPicker.ets` + `SectionHeader.ets` |

**(B) MVP 合并 + 归档**:
- `KnowledgeModelMVP.ets` 合并进 `KnowledgeModel.ets`(644 行变更)
- 所有 `*MVP.ets` 文件移到 `archive/mvp-experiments/`
- 测试文件 `KnowledgeModelMVP.test.ets` → `KnowledgeModel.test.ets`(89 行新测试)
- 静态检查: active source 无 `*MVP.ets` / 无旧符号引用 / 相对 import 检查通过

**(C) 配套 refactor**(近期 15 个 commit):
- `616a219` 拆 Home + Agent 浮窗组件
- `60c958f` 拆 chat 模型 + 文本清理器(ChatTextSanitizer)
- `a523f1b` 笔记详情删除接入
- `8652b87` 聊天气泡回调加固(214 行)
- `321762c` 修 AI Tab 跳转占位(`lastContentIndex`)
- `753d7ad` 移除 C 风格 logger 循环
- `94101d0` + `1f4bd93` 进度环定时器(revert + 重做)
- `d18a76d` + `67deb32` 笔记详情章节/操作拆分
- `679aa17` + `dbad0da` 学习计划行交互修复 + 行操作
- `675eca5` 学习计划页面组件拆分
- `f9470e8` 替换内联 emoji 图标
- `826c562` 数据流硬化

### 3.11 整链接入 · 拍照→AI→入库 端到端 (2026-07-17) ✨

`5b6f155 feat(p0): Index.ets 接入拍照→AI 整链`

整链最后 1 公里接通:
- `Index.ets onCameraConfirm` 调 `new AiService(ctx).capture(uri)` 触发完整 pipeline
- 成功 Toast "笔记已生成: {title}",失败 Toast "处理失败: {errMsg}" 截断 80 字符
- 拍照确认仍回 AI 浮窗,流程不变

```
拍照(imageUri) 
  → AiService.capture() 
  → ImageUriResolver.resolve()        // file:// URI 复制到沙箱
  → Dispatcher.dispatch()              // 调度
    → TypeClassifier.classify()        // OCR + DeepSeek 3×3 分类
      → OcrTool.recognize()            // 本地 FastAPI HTTP
    → KnowledgeModel.structure()       // 模板填充 + 真值检验
  → NoteDao.insert()                   // 入 RDB (knowledge_unit)
  → Toast 提示用户
```

**这是 W0 以来工程最关键的一步** — 之前 D + L 的所有 stub 全部填好,只需 Index.ets 调一次。

---

## 四、当前文件结构(2026-07-17 最新)

```
entry/src/main/ets/
├── pages/                              # 每个 page 一个子文件夹
│   ├── Index.ets                       # 主容器: 5 Tab + 全局浮层 + 整链触发
│   ├── Home/                           # 首页(拆 3 个组件)
│   │   ├── HomePage.ets
│   │   ├── HomeTopBar.ets
│   │   └── HomeRecentNotes.ets
│   ├── Notes/                          # 笔记列表(拆 4 个组件)
│   │   ├── NotesPage.ets
│   │   ├── NotesHeader.ets
│   │   ├── NotesList.ets
│   │   └── NotesEmptyState.ets
│   ├── Profile/                        # 我的(原 MePage,拆 5 个组件)
│   │   ├── ProfilePage.ets
│   │   ├── ProfileHeader.ets
│   │   ├── ProfileStatsRow.ets
│   │   ├── ProfileMenuList.ets
│   │   └── ProfileMenuItemRow.ets
│   ├── Review/                         # 复习
│   │   └── ReviewPage.ets
│   ├── StudyPlan/                      # 学习计划(拆 4 个组件)
│   │   ├── StudyPlanPage.ets
│   │   ├── PlanHeader.ets
│   │   ├── PlanInputBar.ets
│   │   ├── PlanListView.ets
│   │   └── PlanStatsBar.ets
│   └── AiSettings/                     # AI 设置(拆 6 个组件)
│       ├── AiSettingsPage.ets
│       ├── ActionBar.ets
│       ├── ConnectionStatus.ets
│       ├── EndpointPicker.ets
│       ├── KeyInput.ets
│       ├── ModelPicker.ets
│       └── SectionHeader.ets
├── overlays/                           # 顶层浮层(被 Index 引用)
│   ├── AgentFloatWindow.ets            # 18021 bytes · 真实 LLM
│   ├── CameraOverlay.ets               # 真实 cameraPicker
│   └── NoteDetailOverlay.ets           # 5 子组件拆分
├── prototypes/                          # 独立完整的页面级 UI 原型
│   ├── AgentFloatWindow.ets
│   ├── CameraOverlay.ets
│   ├── NoteDetailOverlay.ets
│   ├── AgentMessageList.ets
│   ├── NoteDetailOverlay/              # 5 个子组件
│   └── chat/                           # AI 浮窗 8 个子组件
│       ├── ChatBubble.ets
│       ├── ChatHeader.ets
│       ├── ChatModels.ets
│       ├── ChatSession.ets
│       ├── ChatTextSanitizer.ets
│       ├── EmptyStateHint.ets
│       ├── MessageInput.ets
│       ├── QuickSuggestions.ets
│       ├── SessionBar.ets
│       └── TypingIndicator.ets
├── components/                          # 旧 atom 命名(已废弃)
│   └── HexLogo.ets
├── atoms/                               # 16 个原子组件
│   ├── AiTabButton / AppIcon / CameraAlbumBtn / CameraBackBtn
│   ├── CameraCloseBtn / CameraConfirmBtn / CameraShutterBtn
│   ├── ConfBadge / FloatingButton / GradientRing
│   ├── HexLogo / PageHeader / PriorityBadge / StatsBox
│   ├── TabButton / ViewfinderCorners
├── molecules/                           # 7 个分子组件
│   ├── CameraCapture.ets
│   ├── CameraPreview.ets
│   ├── HeroBanner.ets
│   ├── NoteCard.ets
│   ├── PlanItemRow.ets
│   ├── ReminderBanner.ets
│   └── TabBar.ets
├── database/                            # RDB 数据访问
│   ├── DatabaseHelper.ets               # RDB 封装
│   ├── NoteDao.ets                      # 8336 bytes · 完整 CRUD
│   └── StudyPlanDao.ets                 # 5164 bytes · 学习计划 DAO
├── viewmodels/
│   └── StudyPlanViewModel.ets           # 7869 bytes · MVVM
├── services/
│   ├── ApiClient.ets                    # HTTP 客户端
│   ├── AiService.ets                    # 3414 bytes · 整链入口
│   └── ImageUriResolver.ets             # file:// URI 沙箱化
└── utils/
    └── NoteItemMapper.ets               # NoteItem ↔ KnowledgeUnit

common/src/main/ets/
├── models/                              # 共享类型(KnowledgeUnit + 5 个 enum)
├── constants/                           # ColorTokens / 字号 / 间距
├── tools/                               # logger / uuid / timeWindow / confidenceSort
├── data/                                # MockNotes
└── llm/                                 # LlmConfig + LlmClient(OpenAI 兼容)

agents/src/main/ets/
├── agents/
│   ├── TypeClassifier.ets               # OCR + DeepSeek 3×3 分类
│   └── KnowledgeModel.ets               # 644 行 · AI 结构化 + 真值检验
├── core/
│   └── Dispatcher.ets                   # D1 精简链调度
└── mcp/tools/
    └── OcrTool.ets                      # 本地 FastAPI HTTP
```

---

## 五、整链架构(端到端流程)

### 5.1 完整 pipeline

```
用户拍照
  ↓
CameraOverlay.onConfirm(imageUri)
  ↓
Index.ets onCameraConfirm              [5b6f155]
  ↓ new AiService(ctx).capture(uri)
AiService.capture()                    [services/AiService.ets]
  ↓ ImageUriResolver.resolve()         [services/ImageUriResolver.ets]
  ↓ Dispatcher.dispatch()               [agents/core/Dispatcher.ets]
    ↓ TypeClassifier.classify()        [agents/agents/TypeClassifier.ets]
      ↓ OcrTool.recognize()             [agents/mcp/tools/OcrTool.ets]
        ↓ http://127.0.0.1:8000/api/v1/ocr/recognize
        ↓ 返回 {text, formulas}
      ↓ DeepSeek LlmClient 分类        [common/llm/LlmClient.ets]
        ↓ 失败降级本地规则
    ↓ KnowledgeModel.structure()        [agents/agents/KnowledgeModel.ets]
      ↓ AI 自分词 → Schema 填充
      ↓ truthCheck(花括号/LaTeX/除零/方程)
  ↓ NoteDao.insert()                    [entry/database/NoteDao.ets]
    ↓ relationalStore.insert('knowledge_unit')
  ↓ Toast 通知用户
```

### 5.2 整链文件依赖图

```
Index.ets  ─→  AiService  ─→  Dispatcher  ─→  TypeClassifier  ─→  OcrTool
                                          ─→  KnowledgeModel
                              ─→  NoteDao  ─→  DatabaseHelper
                              ─→  LlmClient  ─→  LlmConfig
                              ─→  ImageUriResolver
```

---

## 六、LLM 配置

### 6.1 端点 + 模型

| 端点 | URL | 特点 |
|------|-----|------|
| DeepSeek 官方(默认) | `https://api.deepseek.com` | OpenAI 兼容 base_url,客户端自动拼接 `/chat/completions` |
| 自定义 OpenAI 兼容 | 用户自填 | 自建网关/代理 |

| 模型 | model 名 | 上下文 | 用途 |
|------|---------|--------|------|
| DeepSeek-V4-Pro | `deepseek-v4-pro` | 1M | 旗舰推理 |
| 自定义 model | 用户输入 | 依 provider | 仅用于兼容或自建网关 |

### 6.2 默认参数

- **Temperature**: 0.1
- **MaxTokens**: 1024
- **Timeout**: 15s

### 6.3 持久化

`preferences` 存储(端点/模型/温度/MaxTokens/Timeout),换设备需重新输入 API Key。

---

## 七、构建与运行

### 7.1 构建

- **必须走 DevEco Studio GUI**(Build → Build Hap(s)/APP(s))
- **不走命令行 `hvigorw`**: 中文路径乱码 + git 工作树状态干扰
- AI 改完代码只做本地 commit + git status,build 结果等用户报回

### 7.2 整链真机验证流程

1. 启动本地 FastAPI OCR 服务:`formula_api:ocr_router`(端口 8000)
2. 真机/模拟器跑 MathMind,确保能访问 `127.0.0.1:8000`(模拟器用 LAN IP)
3. 配置 API Key(我的 → 模型配置 → 测试连接)
4. 拍张数学题照片
5. 预期:Toast "笔记已生成: {title}" → 首页/笔记页能看到新笔记

### 7.3 GitHub SSH

走 port 443(`~/.ssh/config` 已配 `Host github.com → ssh.github.com:443`)。

### 7.4 作者固定

`YunC-GCT <2549237929@qq.com>`(`git config user.name/email` 已配)。

---

## 八、git 规则

1. **未经明示禁止 push** — 本地 commit 自由,推送必须 leader 点头
2. **commit message 规则**:
   - `feat(scope): 新功能` · `fix(scope): bug 修复` · `refactor(scope): 重构`
   - `docs:` · `merge:`
3. **每个 commit 前必查 `git branch --show-current`** — 不在自己分支不 commit
4. **DevEco Studio 会自动切分支** — commit 前必须确认当前分支
5. **回滚走 `git reset --hard HEAD~N`**(user 授权后),reflog 可找回

---

## 九、已归档的 MVP 实验文件

保留作为参考,**不算 active product code**:

```
archive/mvp-experiments/
├── agents/src/main/ets/agents/KnowledgeModelMVP.ets   ← MVP 合并后已空
├── agents/src/main/ets/core/DispatcherMVP.ets
├── entry/src/main/ets/database/DatabaseHelperMVP.ets
├── entry/src/main/ets/database/NoteDaoMVP.ets
├── entry/src/main/ets/overlays/AgentFloatWindowMVP.ets
├── entry/src/main/ets/pages/AiTestPage.ets
├── entry/src/main/ets/pages/AiTestPageMVP.ets
├── entry/src/main/ets/pages/IndexMVP.ets
└── entry/src/main/ets/services/AiServiceMVP.ets
```

未来决定: 团队确认不再需要后整体删除。

---

## 十、下一步计划

### 🔴 P0 · 整链真机验证
- [ ] 启动本地 FastAPI OCR 服务
- [ ] 真机/模拟器拍张数学题照片
- [ ] 验证:Toast 提示 + 首页/笔记页显示新笔记
- [ ] 失败兜底:任意一环报错,Toast 提示

### 🟡 P1 · 体验增强
- [ ] StudyPlan LLM 自动生成(ViewModel 已有,接 LLM)
- [ ] AI 浮窗历史持久化(ChatSession 已有,UI 完整接入)
- [ ] 拍照后流式 AI 实时反馈

### 🟢 P2 · 已设计待落地
- [ ] 图标系统 5 个 SVG 改(album bug + ai/review/notes 改 lucide + 删 brand)
- [ ] AiSettingsPage 重构 · DeepSeek 官方最简版方案
- [ ] HomePage 进度环 sin 曲线 + 3 统计方块可点

### ⚪ P3 · 清理
- [ ] `archive/mvp-experiments/` 9 个文件是否保留
- [ ] `prototypes/` 重命名为 `features/`
- [ ] `entry/_fb.ets` (1KB untracked) 是什么?
- [ ] 8 个 `docs/*.html` 预览是否归档(完成设计任务后)

---

## 附录:关键 commit 索引

| 阶段 | 关键 commit |
|------|------------|
| W0 脚手架 | `bfaa8e5` |
| W1 公共层 | `d6220c4` merge |
| D1 拍照链 | `b15d960` |
| W1 5 Tab UI | `02cabf2` ~ `eeb5cb2` |
| center 合并 | `53b09c0` |
| CameraPicker 接入 | `9db3309` `56229ec` `e155fae` |
| LlmClient 接入 | `7e3f4da` `6d2b45b` |
| Local OCR | `babdba8` |
| Z 端 refactor | `81a6ef6` |
| **整链接入** ✨ | `5b6f155` |
