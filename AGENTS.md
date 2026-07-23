# AGENTS.md

> HarmonyOS 数学学习助手 — 拍照 / OCR / AI 分类 / 知识结构化 / 持久化 / 复习 全链应用
> 5 module 工程 (entry HAP + common/agents/skill/cardservice 4 个 HSP)
> 主分支: `main` · 最近大版本: W3 (2026-07-17)

---

## 项目定位

MindTrace 是一个 HarmonyOS 数学学习助手,核心能力:

1. **拍照/选图** → 相机/相册取图
2. **OCR** → 本地 FastAPI HTTP 服务识别数学公式/题目
3. **AI 分类** → 题型识别 (定义/定理/例题/习题/错题)
4. **知识结构化** → `KnowledgeModel` 拆分知识点/章节/标签/掌握度
5. **持久化** → RDB `knowledge_unit` 表
6. **复习** → 间隔重复 (LEARNING/REVIEW/GRADUATED/LAPSED 状态机)

最近更新详见 [README.md](./README.md) + [docs/W3_SUMMARY.md](./docs/W3_SUMMARY.md)。

---

## Setup commands (DevEco Studio)

**严禁用 hvigorw CLI** (NODE_HOME/PATH 中文路径乱码撞墙,已实测)
- **唯一推荐**: DevEco Studio GUI
  - Open: File → Open → 选 `D:\HMgent\MindTrace` 根目录
  - Build: Build → Build Hap(s)/APP(s)
  - Run: Run → Run 'entry'
- sync: File → Sync and Refresh Project
- 签名: 根 `build-profile.json5` 必须显式共享 `signingConfig` 给所有 HAP (memory 已有规则)

---

## Project layout (5 module)

```
MindTrace/
├── entry/                 # HAP - 主应用 (UI + 业务 + 拍照 + DB)
│   └── src/main/ets/
│       ├── pages/         # 5 Tab 页面 (Home/Notes/AI/Review/Profile)
│       ├── components/    # 通用组件 (HexLogo / GradientRing)
│       ├── overlays/      # 浮层 (CameraOverlay / AgentFloatWindow / NoteDetailOverlay)
│       ├── services/      # AiService / ImageUriResolver / ApiClient
│       ├── database/      # NoteDao / StudyPlanDao / DatabaseHelper
│       ├── viewmodels/    # StudyPlanViewModel (@Observed)
│       ├── atoms/         # 极小组件 (16 个, 全部 UI 原子)
│       ├── utils/         # NoteItemMapper
│       └── entrybackupability/  # 数据备份/恢复 Ability
├── common/                # HSP - 共享类型 + LLM 客户端
│   └── src/main/ets/
│       ├── llm/           # LlmConfig / LlmClient (OpenAI 兼容 HTTP)
│       ├── models/        # KnowledgeUnit / StudyPlanItem / NoteItem
│       ├── constants/     # ColorTokens / 主题色
│       └── database/      # DatabaseHelper 单例
├── agents/                # HSP - AI 业务 (Dispatcher / TypeClassifier / KnowledgeModel)
├── skill/                 # HSP - 技能卡片 (Feature Ability)
├── cardservice/           # HSP - 卡片服务 (FormExtensionAbility)
├── AppScope/              # 应用元数据 + 资源
├── docs/                  # 设计草稿 + 跨 session 通信 + 总结
│   ├── W3_SUMMARY.md      # W3 完整工作总结
│   ├── ui_to_agent_*.md   # UI session → 主 agent
│   ├── agent_to_ui_*.md   # 主 agent → UI session
│   └── *.html             # 视觉稿 (visual page, 不在 git 里)
├── archive/               # 历史版本备份 (不进 git)
├── MindTrace-MVP/          # MVP 早期版本
└── .worktrees/            # git worktree 目录
```

---

## Code style (ArkTS 1.1 strict)

**这套铁律是工程硬性要求,不是建议**。完整 8 大铁律见 `~/.mavis/agents/mavis/memory/MEMORY.md` 的 "ArkUI 装饰器 cheat sheet"。

核心铁律 (踩坑 Top 5):

1. **禁 `any`/`unknown`**: 显式类型 + `(e as Error).message ?? String(e)` 错误兜底
2. **禁 C 风格 `for`**: `for (let i; i<10; i++)` ❌ → `for...of` / `forEach` / `while` ✅
3. **struct 内禁普通方法**: 全部用箭头函数字段 / `@Builder` / `@Watch` (唯一例外)
4. **struct 内禁 `get` accessor**: `@State` + `aboutToAppear` 算
5. **struct 字段名避开 CommonAttribute 方法**: `rotate`/`translate`/`scale`/`opacity`/`backgroundColor` ❌ → `rotDeg`/`transY` ✅

**API 兼容** (ArkUI 1.1 = API 9):
- `.stateStyles()` / `.blur()` ❌ 是 API 11+
- `.translate({x, y})` ✅ 响应 @State (`.offset()` ❌ 不响应)
- `Image.rotate({angle})` 接受对象,不是 number

**文件头注释模板** (W3 后新规, 80+ 文件已统一):
```ts
/**
 * {FileName}.ets — {职责一句话}
 *
 * 路径: {相对 entry/src/main/ets/ 的路径}
 * 职责: {具体业务职责}
 * 依赖: {依赖模块/kit}
 *
 * 数据流:
 *   {上游} → {本文件关键函数} → {下游}
 *
 * {其他设计要点}
 *
 * ArkTS 1.1 strict 适配:
 *   - {踩坑点 + 修复}
 */
```

---

## Testing instructions

- **静态编译**: DevEco Studio Build → Build Hap(s)/APP(s)
- **真机调试**: Run → Run 'entry' (需要 HarmonyOS 真机或远程模拟器)
- **单元测试**: `entry/build-profile.json5` 配了 `ohosTest` target,但当前未编写测试
- **E2E 验证**: 拍照→AI 整链需要 FastAPI OCR 服务 (`OcrTool.recognize()` 调本地 HTTP)
- **手动 smoke test** (提交前必走):
  1. 5 Tab 切换流畅
  2. 首页 Hero 卡片渲染
  3. 进度环呼吸光晕
  4. AI 浮窗开/关 + 输入对话
  5. 笔记详情浮层打开/关闭
  6. 复习 Tab 跳 StudyPlan

---

## PR & commit conventions

- **主分支**: `main` (5b6f155 起为整链基线)
- **分支模型**: 当前单 `main`,无 feature 分支 (但 `.worktrees/` 留有 worktree 目录)
- **Commit 风格**: conventional commits
  - `feat(p0):` / `feat(w3):` — 新功能
  - `fix(agents):` / `fix(build):` — 修复
  - `docs(entry):` / `docs:` — 文档/注释
  - `refactor:` / `style:` / `test:` / `chore:`
- **每 commit 前必查**:
  - `git branch --show-current` (DevEco 可能自动切分支)
  - `git status` (working tree 状态)
  - 本地 commit, **绝不 push** 除非 user 明确说"push"
- **回滚**: `git reset --hard HEAD~n` 需 user 明确授权 (reflog 可找回)

---

## 跨 session 通信协议 (重要!)

`mavis communication send` CLI 不可用 (Mavis 0.x),**必须走文件协议 + user 中转**:

| 方向 | 文件命名 | 路径 |
|------|---------|------|
| UI session → 主 agent | `docs/ui_to_agent_<topic>_<date>.md` | 当前 worktree 的 `docs/` |
| 主 agent → UI session | `docs/agent_to_ui_<topic>_<date>.md` | UI session worktree 的 `docs/` |

**关键约束**:
- 单 worktree 多 session: 同 `.git/`,**working tree 互斥** (一个 session 改时另一个别动)
- 多 worktree: 各自 working tree 独立,但共享 HEAD,需注意分支同步
- 通过 user 转告,不直接推给对方
- 实际案例: `docs/ui_to_agent_ai_settings_20260714.md` (UI 端提的 4 个 AI 设置页问题)

---

## Security

- **绝不 commit secrets**: `.env` / `local.properties` 已在 `.gitignore`
- **API Key**: 用户在 App 内"我的 → AI 模型配置"设置,持久化到 `preferences`,**不入 git**
- **OCR 服务地址**: 默认 `localhost`,部署到真机时改 IP
- **网络权限**: 已声明 `ohos.permission.INTERNET` (memory 已有规则)
- **签名**: 根 `build-profile.json5` 的 `signingConfigs` 必须显式共享给所有 HAP,否则不同 HAP 签名不一致

---

## 必读 rules (项目级硬约束)

下面这些是工程踩过的真实坑,新 session 接 MindTrace **必须先看**:

1. **HSP `oh-package.json5` 必备 `main` 字段**: 缺了 build 报 `Cannot find module 'xxx'`
   - 模板: `{"name": "xxx", "main": "./src/main/ets/Index.ets", ...}`
2. **`.ets` 文件 UTF-8 noBOM**: UTF-16 LE BOM 让 hvigorw 报"18 字节错位"伪错
   - 改文件用 Read/Write/Edit 工具,不走 PowerShell 管道
3. **每个 module 都需自己的 `build-profile.json5` + `hvigorfile.ts`**: 根的不够
4. **HSP `module.json5` 字段约束**: 禁 `pages`/`abilities`/`mainElement`/`extensionAbilities`/`skills`,可写 `name`/`type`/`description`/`deviceTypes`/`deliveryWithInstall`/`installationFree`
5. **HSP 跨 module import 必须完整路径**: `from 'common/src/main/ets/Index'` 不能 `from 'common/Index'`
6. **一个鸿蒙应用只能有一个 `type:entry` 模块**: 其他 HAP 用 `type:feature` (entry/skill/cardservice)
7. **obfuscation-rules.txt 必须存在**: 即使 `enable:false` 也要有文件
8. **写新中文文件用 Write 工具**: PowerShell 5.1 终端乱码陷阱,Edit 改文件 OK,写新文件必须用 Write

完整 rules 见 `~/.mavis/agents/mavis/memory/MEMORY.md` (按 "HarmonyOS" / "ArkTS" / "ArkUI" 关键词搜)。

---

## 维护提示

- **新 module 创建**: 必须 `cp common/oh-package.json5 <new>/oh-package.json5` 当模板 (有 main 字段)
- **新 .ets 文件**: 复制上面 "文件头注释模板" 写头注释
- **新 .ets 改完**: PowerShell 验首 3 字节 `69 6D 70` (= "imp" = "import" 无 BOM)
- **跨 session 通信**: 用上面 "跨 session 通信协议" 表格
- **Working tree 互斥**: 跟其他 session 在同一 worktree 时,只能 read,别动 write
