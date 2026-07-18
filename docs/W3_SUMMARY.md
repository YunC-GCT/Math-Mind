# W3 (2026-07-14 ~ 2026-07-17) 工作总结

> 范围: UI polish W1/W2/W3 收尾 + 拍照→AI 整链接入 + 80 文件头注释普查修复
> 主笔: Mavis (Mavis Code session `mvs_906b071517694dc68ec773f926f1b311`)
> 协作 session: 1 个 Z session 负责 `common/` + `agents/` 后端模块（通过文件协议 + user 中转）

---

## 一、最终成果

### 1.1 Git 历史（10 个 commit，全部独立可回滚）

```
397fb23 docs: README 完整重写 (W3)
a0ded62 docs(entry): 补全 5 个工具/服务层文件头注释 + NoteItemMapper while→for...of strict 适配
ac000a2 docs(entry): AgentFloatWindow 紧凑版重写 + 顶部乱码修复 + 全中文注释
875ba5a docs(entry): NoteDetailOverlay 装配层 + 5 个子组件补全中文注释
05b7f90 docs(entry): prototypes/chat 9 + agent 1 补全中文文件头注释
b5f505e docs(entry): Review 1 + StudyPlan 4 补全中文文件头注释
e4170b7 docs(entry): Notes 4 + Profile 5 个组件补全中文文件头注释
7f9ebfb docs(entry): 9 个文件补全中文文件头注释 + 清 BOM
6e96b61 fix(agents): oh-package.json5 补 main 字段 + strict 适配
5b6f155 feat(p0): Index.ets 接入拍照→AI 整链
```

### 1.2 关键里程碑

| 阶段 | 内容 | 验证 |
|------|------|------|
| **W1 batch 1/2/3** | HomePage / 5 Tab / ColorTokens / NotesPage / ReviewPage / MePage / CameraOverlay / AiChatOverlay / NoteDetailOverlay | DevEco 真机 |
| **W2 #1** | Hero 问候+日期左对齐 + MathMind 字体换 HarmonyOS Sans Condensed | `9727307` |
| **W2 #2** | 进度环点击跳复习 Tab | `1e76919` |
| **W2 #3** | 进度环动态加载 + 整体光晕呼吸（三角波） | `a9c5a4d` |
| **W2 #4** | 修今日新增 undefined + 进度环圆形光晕 | `3519bea` |
| **W2 5-6** | sin 曲线呼吸 + 3 统计方块可点 → **回滚** | `git reset --hard HEAD~2`（user 授权）|
| **W3 整链** | Index.ets 接入拍照→AI 全流程 | `5b6f155` |
| **W3 build 修** | agents/oh-package.json5 补 main 字段（触发 "Cannot find module" 根因）| `6e96b61` |
| **W3 文档** | 80 文件普查 → 5 批 commit 修复 45 个文件 + 顶部 BOM + 中文头注释 | `7f9ebfb` ~ `a0ded62` |
| **W3 README** | 14952 bytes / 10 节，反映整链后最新状态 | `397fb23` |

---

## 二、整链架构（端到端）

```
拍照/选图
  ↓ CameraOverlay.onConfirm(uri)
Index.ets onCameraConfirm  [5b6f155]
  ↓ new AiService(ctx).capture(uri)
AiService.capture()  [entry/services/AiService.ets]
  ↓ ImageUriResolver.resolve()
file:// URI 复制到 cacheDir/mathmind_capture/{timestamp}_{rand}{ext}
  ↓ Dispatcher.dispatch()  [agents/core/Dispatcher.ets]
  ↓ TypeClassifier.classify()  [agents/agents/TypeClassifier.ets]
  ↓ OcrTool.recognize()  [本地 FastAPI HTTP OCR，用户部署]
  ↓ KnowledgeModel.structure()  [agents/agents/KnowledgeModel.ets, 644 行真实实现]
  ↓ NoteDao.insert()  [entry/database/NoteDao.ets]
knowledge_unit 表
  ↓ Toast "笔记已生成: {title}" / 失败 Toast
```

### 2.1 失败兜底
- 失败截断 80 字符显示在 Toast
- try-catch 全包，错误日志 `console.error('[AiService.capture] ' + (e as Error).message)`
- OCR 服务未启动时：AI 仍能 mock 出 KnowledgeUnit，导入数据库

---

## 三、踩坑 Top 5（必须给后续 session 看的）

### 3.1 `agents/oh-package.json5` 必须有 `main` 字段
**症状**: DevEco build 报 `Cannot find module 'agents' at xxx/Agents.ets:N:M`
**根因**: HSP 模块的 `oh-package.json5` 缺 `main` 字段
**修复**: 加 `"main": "./src/main/ets/Index.ets"`
**易混淆点**:
- 不是 `ohpm install` 没跑（dependencies 都在）
- 不是 build cache 旧（`entry/oh_modules/xxx/build/...` 看着怪但实际是 Junction 链接）
- 不是 `entry/oh_modules/xxx` 缺源码（oh_modules 是 Junction 链接到源目录）
**预防**: 新建 HSP 模块时先 `cp common/oh-package.json5 xxx/oh-package.json5` 当模板

### 3.2 UTF-16 LE BOM 误报 18 字节错位
**症状**: hvigorw 编译报"第 N 行 18 字节错位"或"Unexpected token"
**根因**: PowerShell `Get-Content | Set-Content` 默认 GBK/CP936，写出 UTF-16 LE BOM (`FF FE`)
**修复**: 用 Read/Write/Edit 工具直接操作文件（UTF-8 noBOM）
**预防**: 改 .ets 文件禁止走 PowerShell 管道，必须用 Read/Write/Edit 工具

### 3.3 `.stateStyles` / `.blur()` 是 API 11+ 不兼容
**症状**: build 报"property stateStyles is not supported in API 9"
**修复**:
- `.stateStyles` → 用 `@State pressed: boolean` + `onTouch((e: TouchEvent) => { if (e.type === TouchType.Down) { ... } })` 模拟
- `.blur()` → 用 `.shadow({ radius: 32, color: rgba })` + `.borderRadius` + `.clip(true)` 模拟 glow

### 3.4 `.offset()` 不响应 @State，`.translate()` 响应
**症状**: 进度环拖动 / 浮窗位置 / 键盘避让 .offset() 静态不变
**根因**: ArkUI 1.1 `.offset()` 是静态定位（只用于一次性布局），`.translate()` 才会被纳入动画/状态驱动
**修复**: 全工程静态用 `.offset`，动态（绑定 @State 变量驱动 UI 重绘）必须用 `.translate`

### 3.5 `Image.fillColor()` 覆盖 SVG fill="none"
**症状**: 6 边形 Logo 应该是空心线条，结果变成实心色块
**根因**: ArkUI 1.1 `.fillColor()` 会覆盖 SVG 内部 `fill="none"`，强制填充
**修复**: 删 `.fillColor()`，让 SVG 内部 `fill` 生效

---

## 四、ArkTS 1.1 strict 8 大铁律（实战汇总）

| # | 限制 | 正确做法 | 错误示例 |
|---|------|---------|---------|
| 1 | 禁 `any`/`unknown` | 显式类型 + `(e as Error).message ?? String(e)` | `const x: any = ...` |
| 2 | 禁 C 风格 `for (let i; i<10; i++)` | `for...of` / `forEach` / `while` | `for (let i = 0; i < n; i++)` |
| 3 | struct 内禁普通方法 | 箭头函数字段 / `@Builder` / `@Watch`（唯一例外）| `foo() { return 1 }` |
| 4 | struct 内禁 `get` accessor | `@State` + `aboutToAppear` 算 | `get avg() { return ... }` |
| 5 | 禁 `const` in `build()` | 提到模块顶层 `const` | `const x = ...` in build() |
| 6 | `if` 必须显式 boolean | `if (arr.length > 0)` 不写 `if (arr)` | `if (msg)` |
| 7 | object literal 禁做 type | 拆 `interface` 再 union | `type X = {a: string} \| {b: number}` |
| 8 | struct 字段名避开 CommonAttribute 方法 | 用 `rotDeg`/`transY` | 字段名 `rotate`/`translate` |

### 4.1 隐藏铁律：`new ClassName()` 也要显式类型
**踩坑**: `AiService.ets:61` 写了 `const dispatcher = new Dispatcher()` 编译不过
**正确**: `const dispatcher: Dispatcher = new Dispatcher()`
**根因**: ArkTS 1.1 strict 不依赖类型推断，连 new 出来的实例都要显式标
**普通 TypeScript 没这限制，是 strict 模式特有检查**

---

## 五、跨系统对比（一句话定位 ArkUI）

| 维度 | ArkUI | SwiftUI | Compose | Flutter | React |
|------|-------|---------|---------|---------|-------|
| 状态 | `@State` | `@State` | `remember{mutableStateOf}` | `StatefulWidget` | `useState` |
| 双向 | `@Link` | `@Binding` | 双向 state + lambda | `ValueNotifier` | `useState + onChange` |
| 跨层 | `@Provide`/`@Consume` | `@EnvironmentObject` | `CompositionLocal` | `InheritedWidget` | `useContext` |
| 布局 | `Column`/`Row`/`Stack` | `VStack`/`HStack`/`ZStack` | `Column`/`Row`/`Box` | `Column`/`Row`/`Stack` | `<div>`/`<Flex>` |
| 弹性 | `Blank()` | `Spacer()` | `Spacer` | `Spacer` | `flex: 1` |
| 距离 ArkUI | — | 最近 | 同代 | 最远 | 较远 |

**核心结论**: ArkUI ≈ SwiftUI（装饰器 + 链式 modifier），跟 Compose 同代，跟 React/JSX/Flutter 距离最远。

---

## 六、未完成 / 留给后续

### 6.1 真机端到端验证
- 当前所有 UI / build 走 DevEco Studio 静态编译
- **拍照→AI 整链需要真机 + FastAPI OCR 服务启动**
- OCR 服务未启时：AI mock 出 KnowledgeUnit 仍能入库，但 tag 字段是占位值

### 6.2 untracked 草稿清理
- `docs/ai_settings_*_preview.html` (5 个) — AI 设置页方案探索 visual page
- `docs/design_progress_ring_animation.html` / `docs/design_ui_polish_w3.html` — UI 设计草稿
- `docs/icon_optimization_preview.html` — 图标优化草稿
- `docs/arkui_syntax_comparison.md` — 4 框架语法对比笔记
- `docs/commit_msg.txt` — 某次 commit 草稿
- `entry/_fb.ets` (1KB) — 不知道是啥，**建议先读再决定**

### 6.3 主 agent 咨询未回复
- `docs/ui_to_agent_ai_settings_20260714.md` — UI 端提的 4 个问题（API Key 设计 / Mock 数据策略 / 模型选择 / 错误兜底）
- 等主 agent session 通过 `docs/agent_to_ui_*.md` 回复

---

## 七、给后续 session 的接力建议

1. **接手第一步**: `git log --oneline -15` + `git status`，确认在 main 分支且 working tree 干净
2. **跨 session 通信**: 走 `docs/ui_to_agent_*.md` + `docs/agent_to_ui_*.md` + user 中转（`mavis communication send` CLI 不可用）
3. **Build 验证**: 一律走 DevEco Studio GUI，hvigorw CLI 中文路径乱码撞墙（已实测）
4. **改 .ets 文件**: Read/Write/Edit 工具，不要走 PowerShell 管道
5. **新文件头注释模板**:
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
6. **新 HSP 模块必加 `main` 字段**（oh-package.json5），从 `common/oh-package.json5` 拷模板

---

## 八、致谢

- **张云程** (YunC-GCT): 需求方 + 测试 + 真机验证 + 跨 session 通信中转 + 多次授权 `git reset --hard`
- **Mavis Code + Mavis**: agent 框架 + 跨 session memory + 工具能力
- **DevEco Studio**: 静态编译验证（真机调试入口）

— 完
