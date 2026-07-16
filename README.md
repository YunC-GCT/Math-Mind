# MathMind · 当前状态

> 工程: YunC-GCT/Math-Mind · 5 module HarmonyOS 数学学习助手  
> 创建/维护: Z(由 Mavis 代笔) · 最近更新: 2026-07-15

---

## 当前状态总览

### 已实现 ✅

| 功能 | 说明 | 验证方式 |
|------|------|---------|
| 首页 5 Tab 导航 | 首页/笔记/AI/复习/我的 | DevEco 运行可见 |
| CameraOverlay 拍照 | `cameraPicker.pick()` 华为系统相机，模拟器降级 mock | 真机点快门拉起系统相机 |
| CameraOverlay 相册 | `PhotoViewPicker.select()` 系统图库 | 模拟器点 🖼 按钮 |
| AgentFloatWindow 真实 AI | `LlmClient.call()` → DeepSeek，支持 V3/V4 | 设置页配 API Key → 发消息 |
| AI 设置页 | 端点切换/模型选择/API Key/参数调优/测试连接 | 我的 → 设置 |
| Dispatcher 调度 | `dispatch()` 串联 TypeClassifier→KnowledgeModel | 代码完整但未端到端调通 |
| NoteDetailOverlay | 笔记详情浮层，Markdown 解析 | 首页点笔记卡片 |

### 待实现 ❌

| 功能 | 阻塞原因 | 负责人 |
|------|---------|--------|
| Capture-to-AI chain | OCR/classification side is connected; `AgentFloatWindow` still needs to call `AiService.capture()` when sending images | Mavis |
| 知识建模+入库 | `KnowledgeModel.ets` stub（有 `structure()` 但未调 DB） | L |
| 笔记数据库 | `NoteDao.ets` 空壳 | L |
| HTTP 客户端 | `ApiClient.ets` 已实现（未使用） | Mavis |

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
- `610c9d2` docs: README 全面改写 (W0 阶段说明 + W1 进度 + 接手指南)
- `d6220c4` merge: feature/z-w1-block2 → main

### 1.3 GitHub Web 标题修订

- `31eaa04` Update project title in README to include '源码' — 作者 YunCeH
- `88fbb99` Update project title in README.md — 作者 shi

### 1.4 D1 精简拍照链骨架 + 编译验证 (2026-07-13 17:48)

**做了什么**: 8 个目标文件全部建好空壳 + DevEco build 验证通过。

**8 个文件当前位置**:

| 文件 | 责任 | 当前内容 |
|------|------|---------|
| `entry/database/NoteDao.ets` | L | ❌ 空壳 — TODO(A1) |
| `entry/services/ApiClient.ets` | Mavis | ✅ 已实现 — HTTP request() + JWT + 401 重试 |
| `entry/services/AiService.ets` | Mavis | DONE - `capture()` builds image payload -> Dispatcher and calls NoteDao insert |
| `entry/overlays/CameraOverlay.ets` | Mavis | ✅ 完整 — CameraPicker/PhotoViewPicker + UI |
| `agents/core/Dispatcher.ets` | Mavis | ✅ 完整 — dispatch() 调度链 TypeClassifier→KnowledgeModel |
| `agents/agents/TypeClassifier.ets` | D | DONE - image/file uses OcrTool, text goes straight to classifier, LLM failures use rule fallback |
| `agents/agents/KnowledgeModel.ets` | L | ⚠️ stub — structure() 返 mock KnowledgeUnit |
| `agents/mcp/tools/OcrTool.ets` | D | DONE - calls local FastAPI `/api/v1/ocr/recognize`, merges text + LaTeX formulas |

D-side OCR/classification shells have been replaced by the real local OCR pipeline; L-side KnowledgeModel/NoteDao still need quality and persistence work.

**新目录**(按 DIRECTORY_MAP 精简链布局):
- `agents/src/main/ets/agents/`
- `agents/src/main/ets/core/`
- `agents/src/main/ets/mcp/tools/`
- `entry/src/main/ets/database/`
- `entry/src/main/ets/overlays/`
- `entry/src/main/ets/services/`

**编译验证**: `hvigor BUILD SUCCESSFUL in 24 s 709 ms`
- common HSP / agents HSP / entry HAP / skill HAP / cardservice HAP **5/5 全过**

---

### 1.5 S_1 · 首页 UI + 底部导航 (commit `02cabf2` ~ `eeb5cb2`)

**当前文件结构**:

```
entry/src/main/ets/
├── pages/
│   ├── Index.ets               # 主容器: 5 Tab 底部导航 + 全局浮层管理
│   ├── HomePage.ets            # 首页: Hero 问候 + 进度环 + 最近笔记 + FAB
│   ├── NotesPage.ets           # 笔记列表页
│   ├── ReviewPage.ets          # 复习页
│   └── MePage.ets              # 我的页
├── overlays/
│   ├── CameraOverlay.ets       # 拍照浮层 (CameraPicker + 系统相册)
│   ├── AgentFloatWindow.ets    # AI 对话浮窗 (LlmClient→DeepSeek 真实回复)
│   └── NoteDetailOverlay.ets   # 笔记详情浮层 (全屏)
├── components/
│   ├── HexLogo.ets             # 6 边形 Logo SVG
│   └── notes/
│       └── notesData.ets       # 共享笔记数据 (NOTES_MOCK + 选中状态)
├── database/
│   └── NoteDao.ets             # 数据库 DAO (空壳, 待实现)
├── services/
│   ├── ApiClient.ets           # HTTP 客户端 (✅ 已实现)
    `-- AiService.ets           # AI service (capture is wired to Dispatcher; UI image send still needs to call it)
├── entryability/
│   └── EntryAbility.ets        # 应用入口
└── entrybackupability/
    └── EntryBackupAbility.ets  # 备份入口
```

**Index.ets — 5 Tab 底部导航**:
- `首页` / `笔记` / `AI` / `复习` / `我的`
- AI Tab 为中央渐变凸起圆 (mint→purple gradient + 发光阴影)
- 对照 Web MVP `.tabbar` CSS: `height:74px` `backdrop-filter:blur(24px)` `border-top`
- 沉浸式状态栏 (窗口延伸到 status bar 区域)

**HomePage — 首页**:
- Header: 日期 + 问候语 ("下午好 ☀️")
- Hero 卡片: 连续天数 + 学习统计 (🔥/📝/⏱)
- 学习进度: Canvas 绘制的多色进度环 (mint/purple/amber 分别对应高代/数分/解析几何)
- 最近笔记列表: 可滚动, 每项显示标题 + 学科类型 chip + 日期
- 点击笔记项 → 弹 NoteDetailOverlay
- 右下 FAB [+] 按钮 → 弹 CameraOverlay

**NotesPage — 笔记列表**:
- 顶栏搜索框 + 筛选 chips (全部/高代/分析/几何)
- 卡片列表: 标题 + 学科·类型 + 置信度徽章 + 日期
- 点击卡片 → 弹 NoteDetailOverlay

**ReviewPage / MePage**:
- 基础布局就位, 待后续填充内容

---

### 1.6 S_3 · 3 个浮层 (commit `b15d960`)

#### 📷 CameraOverlay — 拍照浮层

| 功能 | 状态 |
|------|------|
| 全屏弹层 + #CC000000 遮罩 | ✅ |
| Drag bar (#4B5563) + [✕] 关闭 + "拍照记题" 标题 | ✅ |
| 📷 相机预览 (纯黑底 + 72sp emoji + 提示文字) | ✅ |
| 4 角 L 形取景框 (mint 色, 24vp) | ✅ |
| 快门按钮 76×76 双圈 / 相册按钮 56×56 圆 | ✅ |
| 状态机: camera ↔ preview | ✅ |
| preview: "已拍摄"/"从相册选择" + mock uri | ✅ |
| 重拍 → 回 camera / [✓ 使用此图] → confirm | ✅ |
| 确认后 → 跳 AI Tab + 弹 AiChatOverlay + 带 pendingImageUri | ✅ |

#### 💬 AiChatOverlay — AI 对话浮层

| 功能 | 状态 |
|------|------|
| 卡片式浮窗 (非全屏, 距底部 96vp, 圆角 20vp, purple 边框) | ✅ |
| Drag bar + "✦ MathMind AI" + "在线·DeepSeek" subtitle | ✅ |
| [+] 新对话 / [✕] 关闭按钮 | ✅ |
| 4 快捷 prompt (📷拍照/📝总结/✏️出题/🔄复习) | ✅ |
| AI 欢迎消息 (greeting) | ✅ |
| AI 气泡 (左灰底 purple 浅底) / 用户气泡 (右 mint 渐变) | ✅ |
| 消息列表 (max-height 240vp, 可滚动) | ✅ |
| 底部输入框 + 发送按钮 (空时灰/有内容 mint) | ✅ |
| 空发送 → toast "说点什么吧 ✨" | ✅ |
| Mock AI 关键词回复 (总结/出题/复习) | ✅ |
| 拍照回流: CameraOverlay 确认后 → 自动发图 + pending"正在分析..." | ✅ |
| [+] 新对话 → 清空消息流, 回 greeting | ✅ |

> ⚠️ **Note**: AiChatOverlay 当前是卡片式浮窗 (left:12, right:12, bottom:96vp),  
> 不是全屏页面跳转。对照 Web MVP `.ai-overlay` CSS:  
> `position:absolute; left:12px; right:12px; bottom:96px; max-height:420px;`  
> 需要确认是否符合设计要求。

#### 📄 NoteDetailOverlay — 笔记详情浮层

| 功能 | 状态 |
|------|------|
| 全屏弹层 + drag bar + 学科·类型 chip + [✕] 关闭 | ✅ |
| 标题 24sp 粗体 + 日期·章节 meta + 置信度徽章 | ✅ |
| 置信度圆点颜色: mint (≥85%) / amber (≥60%) / red (<60%) | ✅ |
| 标签 #tag chips (mint 浅底) | ✅ |
| `##` Markdown 章节解析渲染 (定义/性质/解法 等) | ✅ |
| AI 解答卡 → toast "正在呼叫 AI..." | ✅ |
| 底部操作栏: [删除] / [编辑] / [分享] + toast 反馈 | ✅ |
| 点 ✕ / 点遮罩 → 关闭 | ✅ |
| 接入 HomePage + NotesPage 双重触发 | ✅ |

#### 🔗 接入汇总

| 接入点 | 状态 |
|--------|------|
| HomePage FAB → CameraOverlay | ✅ |
| HomePage 笔记卡片 → NoteDetailOverlay | ✅ |
| NotesPage 卡片 → NoteDetailOverlay | ✅ |
| AI Tab → AiChatOverlay (不占位) | ✅ |
| 拍照确认 → 跳 AI Tab + 弹 AiChatOverlay + 图片气泡 | ✅ |
| Index.ets 集中管理 showCamera / showAI / pendingImageUri | ✅ |

---

### 1.9 center 分支合并 · AI 设置页 + DeepSeek V4 (2026-07-14)

- `53b09c0` merge: center→main — 精简拍照链 D1 + AI 模型配置 + 全 Agent 接入 DeepSeek
- **AiSettingsPage**（我的 → 设置）: 端点预设（硅基流动 / DeepSeek 官方）、模型选择（V3/R1/V4-Flash/V4-Pro）、API Key 显隐切换、参数调优（Temperature/MaxTokens/Timeout）、一键测试连接
- **LlmConfig 运行时配置**: `saveAll()` 持久化端点+模型+参数，`loadAll()` 启动时恢复
- **DeepSeek V4 模型**: `deepseek-v4-flash`（快速便宜）、`deepseek-v4-pro`（推理更强），端点自适应切换 `api.deepseek.com/chat/completions`
- **全 Agent 接入 DeepSeek**: TypeClassifier 等 Agent 统一通过 `LlmClient.call()` 调 LLM

### 1.10 CameraOverlay · 接入真实 CameraPicker (2026-07-14)

- `9db3309` CameraOverlay 接入 `cameraPicker.pick()` 华为系统相机（无需 CAMERA 权限）
- `56229ec` cameraPosition 用 `camera.CameraPosition.CAMERA_POSITION_BACK` 枚举 + result 空值防护
- `e155fae` 相册按钮换 SVG 图标 `ic_album.svg` + 快门改 MINT 品牌色 + 模拟器 toast 提示
- `33d3a5d` + `40508ae` module.json5 加 CAMERA + INTERNET 权限声明，修复合并冲突导致 CAMERA 权限丢失
- **降级策略**: 模拟器无相机 → catch 降级 mock uri + toast "模拟器不支持相机"
- **Known limit**: `AiService.capture()` can call Dispatcher now, but `AgentFloatWindow` still sends images through the plain LLM chat path. It should call `AiService.capture(imageUri, userText)` when an image is present.

### 1.11 AgentFloatWindow · 接入 LlmClient 真实 AI 对话 (2026-07-14)

- `7e3f4da` `realReply()` 替代 `mockReply()`: `LlmClient.call()` 调 DeepSeek → AI 气泡显示真实回复
- 系统提示词: "你是 MathMind AI 助手，用简洁中文回答数学问题，适当使用 LaTeX"
- 错误分类: `NO_API_KEY` → "请先配置 API Key" / `NETWORK_ERROR` → "网络连接失败" / 其他 → 截断显示
- 图片预览从输入框左侧移到上方独立行（48×48 缩略图 + "已选图片" + ✕ 取消）
- 发送文案 "📷 已发送图片" → "分享了一张照片"
- `6d2b45b` 修复 TextInput 丢 `.layoutWeight(1)` 导致相机/发送按钮被挤出

### 1.12 编译修复 + 代码清理 (2026-07-14)

- **类型重命名**: center 合并后 `DispatchPayloadImage→ImagePayload` 等，`ef0cca3` 桶导出对齐
- **LlmClient**: `1a1f8a7` 错误序列化 `JSON.stringify(e)` → `(e as Error).message`
- **LlmConfig init 竞态**: `1a1f8a7` `EntryAbility` 补 `.catch()` 错误处理
- **AiSettingsPage**: `8053cfa` save 后 `loadConfig()` 自动刷新 UI
- **死代码清理**: 删 `ingestImage()` / `send()`/`sendQuick()` 中的 mock reply 残留

---

### 1.13 Local OCR pipeline integrated into TypeClassifier (2026-07-15)

- `babdba8` changed `OcrTool.ets` from an empty shell into a local OCR HTTP client using HarmonyOS `http.request()` + `multiFormDataList` to upload image files.
- Default OCR endpoint is `http://127.0.0.1:8000/api/v1/ocr/recognize`; for emulator/device testing, change it to the workstation LAN IP. If starting `formula_api:ocr_router` directly, the path is `/recognize`.
- `TypeClassifier.ets` no longer uses mock OCR text: `image` and `file(image/*)` payloads call `OcrTool`, then merge OCR text and LaTeX formulas into `ocrText`.
- Classification uses the shared `LlmClient` first and asks for `{ type, subject, chapter, confidence }` JSON; missing API key, network errors, and parse failures fall back to local keyword rules.
- `Dispatcher` flow stays unchanged: `TypeClassifier.classify()` produces real `ocrText`, then `KnowledgeModel.structure()` consumes it.
- `agents/Index.ets` now exports `OcrTool` and `OcrRecognitionResult` for reuse and tests.
- Verified: `formula_api.py`, `ocr_text_tool.py`, and `formula_tool.py` compile from source; SDK declarations confirm `multiFormDataList/filePath/remoteFileName`; full ArkTS build was not run because `hvigor/ohpm` is not available in this shell.
- Remaining UI wiring: when `AgentFloatWindow` sends an image, call `new AiService().capture(imagePreview, inputText)` instead of the plain LLM chat path.

---

## 二、待实现 — D1 精简拍照链 (后端链)

> 目标: 拍照 → OCR → DeepSeek 3×3 分类 → 3 模板 → 真值检验 → 入库 → 显示  
> 整链时序见 `docs/D1_CAPTURE_CHAIN_PLAN.md` · 详细分工见 `docs/TONIGHT_TASKS.md`

### 2.0 3 角色分工总览

| 角色 | 文件数 | 编号 | 关键交付 |
|------|--------|------|---------|
| **主+UI** | 4 | A2 + D + E1 + E2 | 拍照按钮 → 出笔记卡 · 整链可跑通 |
| **分类** | 2 | B1 + B2 | 拍图 → 返回 {3×3 分类, confidence>0.7} |
| **写笔记** | 2 | A1 + C | 文本+分类 → KnowledgeUnit 入库 · 真值检验标红 |

### 2.1 角色 A · 主+UI (4 文件) — 你 + Mavis

- `entry/src/main/ets/services/ApiClient.ets` (A2) — HTTP 客户端
- `agents/src/main/ets/core/Dispatcher.ets` (D) — 主 Agent 调度
- `entry/src/main/ets/services/AiService.ets` (E1) — 拍照调用 Dispatcher
- `entry/src/main/ets/overlays/CameraOverlay.ets` (E2) — **UI 已完成**, 待接 `AiService.capture()`

### 2.2 角色 B · 分类 (2 文件) — D

- `agents/src/main/ets/mcp/tools/OcrTool.ets` (B1) - local FastAPI OCR workstation client (text + LaTeX)
- `agents/src/main/ets/agents/TypeClassifier.ets` (B2) - OCR -> DeepSeek/rule-fallback 3x3 classification

### 2.3 角色 C · 写笔记 (2 文件) — L

- `entry/src/main/ets/database/NoteDao.ets` (A1) — RDB 数据访问
- `agents/src/main/ets/agents/KnowledgeModel.ets` (C) — 模板 + 真值 + 入库

### 2.4 LLM 配置

- **双端点**: SiliconFlow (`api.siliconflow.cn`) / DeepSeek 官方 (`api.deepseek.com`)，设置页一键切换
- **模型列表**: SiliconFlow → DeepSeek-V3 / R1；DeepSeek 官方 → V4-Flash / V4-Pro
- Temperature: **0.1** · MaxTokens: [redacted] · Timeout: **5s**
- **配置持久化**: `preferences` 存储，换设备需重新输入 API Key
### 2.5 3×3 分类体系 + 3 模板

- 学科: 高等代数 / 数学分析 / 解析几何
- 类型: 概念 / 计算 / 证明
- 模板: `concept_v1` (定义/性质/相关概念) / `computation_v1` (题目/解法/答案) / `proof_v1` (命题/证明/要点)

---

## 三、下一步待实现

### P0 — 拍照→AI 整链打通
| 任务 | 文件 | 负责 | 说明 |
|------|------|------|------|
| AiService.capture() | AiService.ets | Mavis | DONE - builds image DispatchPayload and calls Dispatcher |
| Image send wiring | AgentFloatWindow.ets | Mavis | Call `AiService.capture(imagePreview, inputText)` when an image is present |
| Classification | TypeClassifier.ets | D | DONE - OCR -> DeepSeek/rule-fallback 3x3 classification, stub replaced |
| 真值建模+入库 | KnowledgeModel.ets | L | 3模板+真值检验+NoteDao INSERT |
| 数据库 | NoteDao.ets | L | RDB INSERT + queryById |
| OCR | OcrTool.ets | D | DONE - local FastAPI OCR -> text + LaTeX |

### P1 — 体验增强
| 任务 | 说明 |
|------|------|
| AI 对话历史 | LlmClient.call() 传入最近 N 轮消息 |
| 真机 CameraPicker 验证 | 华为手机验证系统相机弹出+拍照+返回 |

---

## 四、构建与运行

- **build 走 DevEco Studio GUI** (Build → Build Hap(s)/APP(s)),不走命令行 hvigorw (中文路径乱码)
- **SSH 走 port 443** (`~/.ssh/config` 已配 Host github.com → ssh.github.com:443)
- **作者固定** `YunC-GCT <2549237929@qq.com>` (`git config user.name/email` 已配)

---

## 五、git 规则

1. **未经明示禁止 push** — 本地 commit 自由,推送必须 leader 点头
2. commit message 规则: `feat(module):` / `fix(module):` / `docs:` / `merge:`
