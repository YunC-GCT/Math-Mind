# MathMind · 当前状态

> 工程: YunC-GCT/Math-Mind · 5 module HarmonyOS 数学学习助手  
> 创建/维护: Z(由 Mavis 代笔) · 最近更新: 2026-07-13 22:00

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
│   ├── CameraOverlay.ets       # 拍照浮层 (全屏)
│   ├── AiChatOverlay.ets       # AI 对话浮层 (卡片式)
│   └── NoteDetailOverlay.ets   # 笔记详情浮层 (全屏)
├── components/
│   └── notes/
│       └── notesData.ets       # 共享笔记数据 (NOTES_MOCK + 选中状态)
├── database/
│   └── NoteDao.ets             # 数据库 DAO (空壳, 待实现)
├── services/
│   ├── ApiClient.ets           # HTTP 客户端 (空壳, 待实现)
│   └── AiService.ets           # AI 服务 (空壳, 待实现)
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

- `agents/src/main/ets/mcp/tools/OcrTool.ets` (B1) — ML Kit OCR
- `agents/src/main/ets/agents/TypeClassifier.ets` (B2) — 3×3 分类

### 2.3 角色 C · 写笔记 (2 文件) — L

- `entry/src/main/ets/database/NoteDao.ets` (A1) — RDB 数据访问
- `agents/src/main/ets/agents/KnowledgeModel.ets` (C) — 模板 + 真值 + 入库

### 2.4 LLM 配置

- Provider: **SiliconFlow / DeepSeek-V3** (`deepseek-ai/DeepSeek-V3`)
- 端点: `https://api.siliconflow.cn/v1/chat/completions`
- Temperature: **0.1** · MaxTokens: **256** · Timeout: **5s**

### 2.5 3×3 分类体系 + 3 模板

- 学科: 高等代数 / 数学分析 / 解析几何
- 类型: 概念 / 计算 / 证明
- 模板: `concept_v1` (定义/性质/相关概念) / `computation_v1` (题目/解法/答案) / `proof_v1` (命题/证明/要点)

---

## 三、构建与运行

- **build 走 DevEco Studio GUI** (Build → Build Hap(s)/APP(s)),不走命令行 hvigorw (中文路径乱码)
- **SSH 走 port 443** (`~/.ssh/config` 已配 Host github.com → ssh.github.com:443)
- **作者固定** `YunC-GCT <2549237929@qq.com>` (`git config user.name/email` 已配)

---

## 四、git 规则

1. **未经明示禁止 push** — 本地 commit 自由,推送必须 leader 点头
2. commit message 规则: `feat(module):` / `fix(module):` / `docs:` / `merge:`
