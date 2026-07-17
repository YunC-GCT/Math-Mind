# MathMind 前端设计架构 · 2026-07-17

> 当前状态：AgentFloatWindow 完整版已恢复 · NoteDetailOverlay 对齐 v2-ui · 动效令牌对齐

---

## 一、目录总览

```
entry/src/main/ets/
├── overlays/              # 全局浮层 (2 套)
├── pages/                 # 5 Tab 页面 (27 文件)
├── atoms/                 # 原子组件 (18 个)
├── molecules/             # 分子组件 (7 个)
├── services/              # 业务服务 (4 个)
├── database/              # RDB 数据层
├── utils/                 # 工具
├── prototypes/            # 设计参考 + 共享类型
└── entryability/          # Ability
```

---

## 二、Overlays/ 全局浮层

### AgentFloatWindow (AI 对话浮窗) · 完整版

| 文件 | 大小 | 职责 |
|------|------|------|
| `AgentFloatWindow.ets` | 8.6 KB | 装配层 · 状态管理 · 拖拽缩放 · 多会话 |
| `AgentMessageList.ets` | 1.6 KB | 消息列表 (Scroll + ChatBubble + TypingIndicator) |
| `AgentInputBar.ets` | 2.0 KB | 底部输入栏 (TextInput + 拍照 + 发送) |
| `ImagePreviewBar.ets` | 1.2 KB | 图片预览行 |

**功能特性**：
- 🖐 拖拽手柄缩放浮窗高度 (30%↔90% `PanGesture`)
- 💬 多会话切换 (SessionBar + ChatSessionManager + preferences 持久化)
- ⬇ 新消息自动滚底 (Scroller + @Watch scrollEdge)
- 🔁 AI 消息回放 (retryFromAiMessage)
- 📷 拍照整链 (captureReply → OCR → 入库)
- 🧠 深度思考开关 (ChatHeader)

**依赖**：`ChatHeader` / `SessionBar` / `QuickSuggestions` / `ChatSession` (prototypes/chat/) · `AgentChatService` (services/)

---

### NoteDetailOverlay (笔记详情浮窗)

| 文件 | 大小 | 职责 |
|------|------|------|
| `NoteDetailOverlay.ets` | 3.0 KB | 装配层 · AiSettingsPage 模式顶栏 |
| `NoteDetailMeta.ets` | 1.4 KB | meta 行 (章节/日期/置信度点 · v2-ui dmeta 风格) |
| `NoteDetailBody.ets` | 2.0 KB | 正文区 (标题 + ChipTag + 章节) |
| `NoteActionBar.ets` | 2.3 KB | 底栏 (删除/编辑/分享) |
| `NoteCloseButton.ets` | 1.2 KB | 关闭按钮 |
| `NoteSection.ets` | 1.7 KB | 章节渲染 (loose line-height) |
| `NoteAiCard.ets` | 2.4 KB | AI 解答卡 (已从 UI 移除，文件保留) |
| `NoteTagChip.ets` | 1.1 KB | 标签 chip (旧，建议迁到 atoms/ChipTag) |
| `NoteDetailHeader.ets` | 1.2 KB | 旧顶栏 (已不被引用) |

**顶栏模式** (对齐 AiSettingsPage PageHeader)：
```
[状态栏占位 sbh]  [✕关闭 ··· 学科·类型居中 ··· 占位]  [分隔线]
```

**Props**：`note: NoteItem`, `onClose`, `onAskAi`, `onEdit`, `onDelete`

---

## 三、Pages/ 5 个 Tab 页面

### Index.ets (主入口) · 3.7 KB
- **职责**：5 Tab 导航 + 全局浮层调度
- **子组件**：TabBar · HomePage · NotesPage · ReviewPage · ProfilePage · CameraOverlay · AgentFloatWindow
- **服务**：`OverlayService` (AppStorage `activeOverlay` 管理 camera/float 互斥)

### HomePage · 7.2 KB
- **子组件**：HomeTopBar · HeroBanner · ReminderBanner · FloatingButton · HomeRecentNotes (NoteCard) · NoteDetailOverlay
- **数据**：NoteDao + unitsToNoteItems
- **Props**：`onGoCamera`, `onGoReview`

### NotesPage · 4.5 KB
- **子组件**：NotesHeader · NotesList (NoteCard) · NotesEmptyState · NoteDetailOverlay
- **数据**：NoteDao + unitsToNoteItems

### ReviewPage · 3.0 KB
- **子组件**：StudyPlan 跳转 (router.pushUrl)

### ProfilePage · 4.4 KB
- **子组件**：ProfileHeader · ProfileStatsRow · ProfileMenuList

### AiSettingsPage · 6.4 KB (子路由)
- **子组件**：PageHeader · ConnectionStatus · SectionHeader · ActionBar · EndpointPicker · ModelPicker · KeyInput · OcrConfigSection
- **服务**：LlmConfig · OcrConfig

### StudyPlanPage · 2.5 KB (子路由)
- **子组件**：PlanHeader · PlanStatsBar · PlanListView (PlanItemRow) · PlanInputBar
- **服务**：StudyPlanViewModel

---

## 四、组件层级

### Atoms/ (18 个 · 纯展示零逻辑)

| 组件 | 用途 |
|------|------|
| ChipTag 🆕 | 5 变体芯片 (chip/chipActive/form/formSelected/tag) |
| ConfDot 🆕 | 置信度点 (≥80%绿/≥50%橙/<50%红) |
| ConfBadge | 置信度徽章 |
| HexLogo | 6 边形品牌 Logo (动效令牌 DUR_SLOWEST) |
| GradientRing | 进度环 (Canvas 渐变弧) |
| PageHeader | 返回+标题居中 (AiSettingsPage 模式) |
| AppIcon | SVG 图标 |
| TabButton / AiTabButton | Tab 按钮 |
| FloatingButton | FAB |
| StatsBox | 统计方块 |
| PriorityBadge | 优先级徽章 |
| CameraXxxBtn (5 个) | 相机按钮组 |
| ViewfinderCorners | 取景框角标 |

### Molecules/ (7 个 · 复合组件)

| 组件 | 用途 |
|------|------|
| NoteCard 🔄 | 笔记卡片 (v2-ui .note-card 对齐) |
| TabBar | 5 Tab 底栏 (中间 AI 凸起) |
| HeroBanner | 首页 Hero (渐变圆环+统计) |
| CameraCapture | 相机拍照 |
| CameraPreview | 相机预览 |
| PlanItemRow | 学习计划行 |
| ReminderBanner | 提醒横幅 |

---

## 五、Service 层

| 服务 | 职责 |
|------|------|
| **OverlayService** | 全局浮层调度 · AppStorage 桥接 · 互斥管理 |
| **AgentChatService** | AI 对话业务 · captureReply / realReply / persistTextNote · 回调接口解耦 |
| **AiService** | 拍照→入库整链入口 · Dispatcher · ImageUriResolver · NoteDao |
| **ImageUriResolver** | 图片 file:// URI → 沙箱复制 |

---

## 六、Prototypes/ 状态

### 活跃 (被生产代码引用)

| 文件 | 引用者 | 用途 |
|------|--------|------|
| `CameraOverlay.ets` | Index.ets | 📷 全局相机浮层 |
| `chat/ChatHeader.ets` | AgentFloatWindow | 🧠 模型名/思考/新建 |
| `chat/QuickSuggestions.ets` | AgentFloatWindow | 💡 推荐快捷词 |
| `chat/SessionBar.ets` | AgentFloatWindow | 💬 多会话切换 |
| `chat/ChatSession.ets` | AgentFloatWindow | 💾 会话持久化 |
| `chat/ChatBubble.ets` | AgentMessageList | 💬 消息气泡 (已去 cleanMarkdown) |
| `chat/EmptyStateHint.ets` | AgentMessageList | 📭 空状态 |
| `chat/TypingIndicator.ets` | AgentMessageList | ⏳ 打字动画 |
| `chat/ChatModels.ets` | 多处 | 📐 ChatMsg/ChatSession 类型 |
| `chat/ChatTextSanitizer.ets` | ChatBubble | 🧹 文本清理 (仅 import，AI 气泡已停用) |

### 设计参考 (未被引用，预留优化)

| 文件 | 说明 |
|------|------|
| `chat/MessageInput.ets` | 输入栏参考 (已被 AgentInputBar 替代) |
| `chat/ChatHeader.ets` | 已接入 ✅ |
| `agent/AgentMessageList.ets` | 消息列表参考 (已被 overlays 版替代) |

---

## 七、数据流拓扑

```
┌─ 图片路径 ──────────────────────────────────────────────────┐
│ CameraOverlay → Index → AgentFloatWindow.pendingImageUri    │
│ → imagePreview → send → AgentChatService.captureReply       │
│ → AiService → ImageUriResolver → Dispatcher                 │
│   → TypeClassifier → OcrTool (HTTP OCR)                     │
│   → KnowledgeModel → LLM (或 fallback)                      │
│ → NoteDao.insert (RDB)                                      │
│ → AppStorage.notesVersion → HomePage/NotesPage 自动刷新      │
└─────────────────────────────────────────────────────────────┘

┌─ 文本路径 ──────────────────────────────────────┐
│ 输入 → send → AgentChatService.realReply         │
│ → LlmClient (DeepSeek)                           │
│ → persistTextNote → AiService.captureText → RDB  │
└──────────────────────────────────────────────────┘

浮层调度:
  OverlayService.open('camera') → AppStorage('activeOverlay') ← Index.ets @StorageLink
  OverlayService.open('float')  → 自动关 camera (互斥)
```

---

## 八、设计令牌体系

| 类别 | 键 | 值范围 |
|------|-----|--------|
| 颜色 | MINT/PURPLE/PINK/AMBER/DANGER/WARNING/SUCCESS | 主题 + 7 类型色 |
| 文字 | TEXT → TEXT_4 | 白 → 灰 |
| 间距 | S_1 → S_6 | 4→24 vp |
| 圆角 | R_SM → R_FULL | 4→999 vp |
| 字号 | F_XS → F_3XL | 11→30 fp |
| 字重 | W_NORMAL → W_BOLD | 400→700 |
| 阴影 | SHADOW_FAB / SHADOW_AI_BTN | 预设 |
| 动效 | DUR_INSTANT(80) → DUR_BREATH(3000) | ms |
| 尺寸 | SCREEN_W(377) / SCREEN_H(816) / HEADER_H(60) / TAB_BAR_H(74) | vp |

对齐 v2-ui motion.css: `DUR_INSTANT=80 / DUR_FAST=150 / DUR_BASE=250 / DUR_SLOW=400 / DUR_SLOWER=600 / DUR_SLOWEST=1200 / DUR_BREATH=3000`

---

## 九、文件统计

| 层 | 文件数 | 总大小 |
|----|--------|--------|
| overlays/ | 13 | ~30 KB |
| pages/ | 27 | ~70 KB |
| atoms/ | 18 | ~27 KB |
| molecules/ | 7 | ~19 KB |
| services/ | 4 | ~13 KB |
| prototypes/ (活跃) | 10 | ~26 KB |
| prototypes/ (设计参考) | 2 | ~7 KB |
| **总计** | **~70** | **~192 KB** |
