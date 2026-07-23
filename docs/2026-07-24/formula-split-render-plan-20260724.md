# MathMind 分块渲染方案 — 多 WebView 架构

> 日期: 2026-07-24
> 状态: 待实施 (已补充网上调研, 详见 §11)
> 目标: `$$公式$$` 独立渲染 + 文本分段渲染, 解决 ArkUI WebView 高度上限导致的空白问题

---

## 1. 背景

### 已确认的事实

| 发现 | 证据 |
|------|------|
| ArkUI WebView 在此设备上有高度上限 | cap=1800 可见, cap=3000 空白, cap=6000 空白 |
| 渲染管线完全正常 | renderForCache OK, applyCached OK, heights 正确 |
| bridge 未超限 | 无 REJECTED, 130KB HTML 桥接成功 |
| 超过上限时 WebView 完全不可见 | 非截断, 是彻底空白 |

### 当前临时方案

- `clampHeight` 上限 1800vp
- `render.html` body `overflow-y: auto` (WebView 内部滚动)
- `verticalScrollBarAccess(true)`
- **缺点**: List + WebView 双重滚动, UX 不理想

---

## 2. 目标架构

```
改前:  ChatBubble
         └─ MathTextRenderer ×1  (一个 WebView 渲染全部内容)
              └─ clampHeight ≤ 1800 → 溢出需内部滚动

改后:  ChatBubble
         └─ FormulaSplitRenderer (新组件)
              ├─ splitByFormulas(markdown) → Block[]
              └─ ForEach Block:
                   ├─ 公式块 → MathTextRenderer(forceDisplay=true, 无上限)
                   └─ 文本块 → MathTextRenderer(profile='chat', ≤1800)
              → Column 垂直排列
              → List 统一自然滚动 (无嵌套)
```

### 核心原则

1. **`$$...$$` 公式块 = 原子渲染单元** — 独立 WebView, `forceDisplay=true`
2. **文本块按公式分隔** — 夹在公式之间的文本各自独立 WebView
3. **行内 `$...$` 随所属文本块** — 不单独拆分
4. **List 统一滚动** — 所有 WebView 拼接成 Column, 外部 List 一次滚到底

---

## 3. 涉及文件

| 文件 | 操作 | 说明 |
|------|------|------|
| `entry/.../chat/ChatBubble.ets` | 修改 | `containsFormulaSyntax` 为 true 时调用 `FormulaSplitRenderer` |
| `entry/.../components/FormulaSplitRenderer.ets` | **新建** | 核心: 分块算法 + ForEach 渲染 |
| `entry/.../components/MathTextRenderer.ets` | 修改 | 公式块路径 (`forceDisplay=true`) `clampHeight` 仅保下限 |
| `entry/.../rawfile/render.html` | 不改 | 无变更 |

---

## 4. 分块算法

### 输入/输出

```
输入: "段落A\n\n$$x^2+y^2=z^2$$\n\n段落B\n\n$$\int_0^\infty e^{-x}dx$$\n\n段落C"

输出: [
  { type: 'text',    content: '段落A' },
  { type: 'formula', content: '$$\nx^2+y^2=z^2\n$$' },
  { type: 'text',    content: '段落B' },
  { type: 'formula', content: '$$\n\int_0^\infty e^{-x}dx\n$$' },
  { type: 'text',    content: '段落C' },
]
```

### 实现

```typescript
// FormulaSplitRenderer.ets

interface FormulaBlock {
  type: 'text' | 'formula'
  content: string
}

function splitByFormulas(markdown: string): FormulaBlock[] {
  const parts: string[] = markdown.split('$$')
  const blocks: FormulaBlock[] = []

  for (let i = 0; i < parts.length; i++) {
    const trimmed: string = parts[i].trim()
    if (trimmed.length === 0) {
      continue
    }
    if (i % 2 === 0) {
      // 偶数索引 = 文本块 (夹在 $$ 之间)
      blocks.push({ type: 'text', content: trimmed })
    } else {
      // 奇数索引 = 公式块, 重新包裹 $$ 定界符
      blocks.push({ type: 'formula', content: '$$\n' + trimmed + '\n$$' })
    }
  }

  return blocks
}
```

### 为什么按 `$$` 切分不会切到公式中间

- `split('$$')` 以 `$$` 为分隔符
- `$$...$$` 之间的内容是奇数索引 → 整个公式的**内容**被完整保留
- 重新包裹 `$$\n...\n$$` 恢复为合法 KaTeX display 公式
- 行内 `$...$` 不受影响 (单 `$` 不参与切分)

### 边界情况

| 情况 | 处理 |
|------|------|
| 文本以 `$$` 开头 | `parts[0]` 为空 → `trim().length===0` → 跳过 |
| 文本以 `$$` 结尾 | `parts[last]` 为空 → 跳过 |
| 连续 `$$...$$ $$...$$` | 中间出现空文本块 → 跳过 |
| 无公式的纯文本 | `parts.length===1` → 单个文本块 |
| `\[...\]` 公式 | 当前先不处理, 后续扩展 |

---

## 5. 公式块渲染配置

```typescript
// 公式块: forceDisplay=true 绕过 ContentProtocol, 直接 KaTeX 渲染
// minHeight 自适应公式实际尺寸
// 不加 1800 上限 → 单个公式不会超过限制

MathTextRenderer({
  text: block.content,           // "$$\nx^2+y^2=z^2\n$$"
  profile: 'chat',
  forceDisplay: true,            // 关键: 跳过 normalizeForRender 的 ContentProtocol 处理
  minHeight: 42,
  textColor: TEXT_2,
  formulaColor: TEXT_2,
  formulaBackground: 'rgba(255,255,255,0.06)',
  formulaBorder: 'rgba(255,255,255,0.12)',
  fontSize: F_SM,
  lineHeight: 20,
  formulaFontSize: F_SM,
  formulaLineHeight: 20,
})
```

### MathTextRenderer 改动

```typescript
// clampHeight 根据 forceDisplay 区分行为
private clampHeight = (height: number): number => {
  if (this.forceDisplay) {
    // 公式块: 仅保下限, 不设上限 (单个公式远超 1800 的概率 ≈ 0)
    return Math.max(this.minHeight, height)
  }
  // 文本块: 上限 1800, 超过时 overflow-y:auto 内部滚动
  return Math.min(1800, Math.max(this.minHeight, height))
}
```

---

## 6. 文本块渲染配置

```typescript
// 文本块: 保留 $...$ 行内公式, markdown 格式
// forceDisplay=false → 走完整 ContentProtocol + LatexRiskNormalizer 管线

MathTextRenderer({
  text: block.content,           // "段落A\n\n段落B"
  profile: 'chat',
  forceDisplay: false,
  minHeight: 42,
  textColor: TEXT_2,
  formulaColor: TEXT_2,
  formulaBackground: 'rgba(255,255,255,0.06)',
  formulaBorder: 'rgba(255,255,255,0.12)',
  fontSize: F_SM,
  lineHeight: 20,
  formulaFontSize: F_SM,
  formulaLineHeight: 20,
})
```

---

## 7. ChatBubble 改动

```typescript
// 改前: 直接创建 MathTextRenderer
if (this.containsFormulaSyntax(this.msg.content)) {
  MathTextRenderer({ text: this.msg.content, profile: 'chat', ... })
}

// 改后: 委托给 FormulaSplitRenderer
if (this.containsFormulaSyntax(this.msg.content)) {
  FormulaSplitRenderer({ text: this.msg.content })
}
```

---

## 8. 渲染效果示意

```
┌─ List (自然滚动) ─────────────────────┐
│                                        │
│  ┌─ WebView #1 (文本块 1) ──────────┐ │
│  │  AI 的回复文本段落...              │ │
│  │  $x^2$ 行内公式正常渲染            │ │
│  │  高度: 800vp                       │ │
│  └────────────────────────────────────┘ │
│                                        │
│  ┌─ WebView #2 (公式块) ─────────────┐ │
│  │  $$ x^2 + y^2 = z^2 $$            │ │ ← 独立 WebView
│  │  高度: 120vp                       │ │    forceDisplay=true
│  └────────────────────────────────────┘ │
│                                        │
│  ┌─ WebView #3 (文本块 2) ──────────┐ │
│  │  更多文本...                       │ │
│  │  高度: 1500vp                      │ │
│  └────────────────────────────────────┘ │
│                                        │
│  ┌─ WebView #4 (公式块) ─────────────┐ │
│  │  $$ \int_0^\infty e^{-x}dx $$     │ │ ← 独立 WebView
│  │  高度: 180vp                       │ │
│  └────────────────────────────────────┘ │
│                                        │
│  ┌─ WebView #5 (文本块 3) ──────────┐ │
│  │  结尾文本...                       │ │
│  │  高度: 300vp                       │ │
│  └────────────────────────────────────┘ │
│                                        │
└────────────────────────────────────────┘
```

---

## 9. 实施步骤

### Step 1: 新建 `FormulaSplitRenderer.ets`

- 路径: `entry/src/main/ets/shared/components/FormulaSplitRenderer.ets`
- 内容:
  - `FormulaBlock` 接口
  - `splitByFormulas()` 函数
  - `@Component FormulaSplitRenderer` 
    - `@Prop text: string`
    - 私有 `blocks: FormulaBlock[]` (在 `aboutToAppear` 中切分)
    - `build()`: Column + ForEach 渲染 MathTextRenderer

### Step 2: 修改 `MathTextRenderer.ets`

- `clampHeight` 加 `forceDisplay` 判断:
  - `forceDisplay=true` → `Math.max(minHeight, height)` (无上限)
  - `forceDisplay=false` → `Math.min(1800, Math.max(minHeight, height))` (有上限)

### Step 3: 修改 `ChatBubble.ets`

- import `FormulaSplitRenderer`
- 将 `MathTextRenderer({...})` 替换为 `FormulaSplitRenderer({ text: this.msg.content })`
- 公式相关 props 移到 `FormulaSplitRenderer` 内部硬编码或通过 `@Prop` 传递

### Step 4: Build + 验证

- 长消息: 公式独立可见, 文本独立可见, List 统一滚动
- 短消息: 行为不变
- 无公式消息: 走 MarkdownRenderer, 不变

---

## 10. 风险与缓解

| 风险 | 缓解 |
|------|------|
| 多个 WebView 同时加载 → 资源竞争 | 每个 WebView 高度小 (≤1800vp), 分担压力 |
| `forceDisplay=true` 的公式块被 `normalizeForRender` 误判为 `plainFallback` | `forceDisplay=true` 时 `normalizeForRender` 走 `normalizeDisplayFormula` 分支, 不会降级 |
| 空文本块导致空白 WebView | `splitByFormulas` 过滤空块 |
| 公式块的缓存 key 冲突 | cacheKey 已含 `forceDisplay` 标志 (`'1'`), 公式块和文本块不会冲突 |
| 行内 `$...$` 在文本块中渲染 | 正常, MathTextRenderer 支持行内公式 |
| `\[...\]` 未被拆分 | 首版先支持 `$$`, `\[...\]` 后续扩展 |

---

## 11. 调研补充 (2026-07-24 网上调研)

> 调研来源:
> - `docs/research-multi-webview-performance-20260724.md` — 多 WebView 架构性能 (MDN / Flutter / RN / HarmonyOS 官方文档)
> - `docs/research-formula-render-strategies-20260724.md` — 公式渲染策略 (KaTeX / MathJax / ChatGPT / Claude / DeepSeek)

以下是对原方案的**关键补充和改进建议**，按优先级排列。

---

### 11.1 🔴 CRITICAL: WebView 内存爆炸风险 — 必须加池化

**问题：** 原方案对每个 text/formula block 创建一个独立 WebView，没有限制数量。

调研数据：
- 每个 WebView 基础开销 **15–30 MB**（空 WebView 也要这么多）
- 一条含 10 个公式的消息 ≈ 20 个 WebView × 20 MB = **400 MB**
- 屏幕上同时显示 3 条消息 ≈ **1.2 GB** → **OOM 崩溃**
- HarmonyOS 实测：**5+ 个 WebView 同时可见**性能明显下降，可能引发 ANR

**改进：必须实施 WebView 池化**

```typescript
// FormulaSplitRenderer 内建池化逻辑

class WebViewSlot {
  id: number
  content: string        // 当前渲染内容
  height: number         // 测量高度
  inUse: boolean         // 是否正在被某个 Block 使用
  // 底层 MathTextRenderer 实例复用
}

class FormulaSplitViewModel {
  private slotPool: WebViewSlot[] = []
  private readonly MAX_POOL_SIZE = 5   // 同时活跃 WebView 上限
  private readonly MAX_TOTAL_BLOCKS = 30  // 单条消息最多 30 个 block

  // 超出上限时：合并相邻文本块
  // 超出 MAX_TOTAL_BLOCKS 时：截断 + "内容过长，请精简提问" 提示
}
```

**池化策略：**
| 参数 | 建议值 | 依据 |
|------|--------|------|
| 最大活跃 WebView | 5 | HarmonyOS 5+ WebView 有 ANR 风险 |
| 池预热数量 | 2–3 | 首屏渲染延迟可接受 |
| 单消息 block 上限 | 30 | 防止极端长公式消息 |
| 复用 reset 方式 | `loadData('')` → 重新 `loadData(html)` | 比销毁重建快 ~10× |

---

### 11.2 🔴 CRITICAL: 合并相邻文本块

**问题：** 原 `splitByFormulas` 每段夹在公式之间的文本都独立创建一个 WebView。

**例如：**
```
段落A

$$formula1$$

段落B

段落C

段落D

$$formula2$$
```

当前会产出 5 个 block：`[textA, formula1, textB, textC, textD, formula2]`，其中 `textB`, `textC`, `textD` 各占一个 WebView——浪费！

**改进：合并所有 `$$` 之间的连续文本段**

```typescript
function splitByFormulas(markdown: string): FormulaBlock[] {
  const parts: string[] = markdown.split('$$')
  const blocks: FormulaBlock[] = []
  let pendingTexts: string[] = []  // 积累连续文本

  for (let i = 0; i < parts.length; i++) {
    const trimmed: string = parts[i].trim()
    if (trimmed.length === 0) {
      continue
    }
    if (i % 2 === 0) {
      // 文本块 → 先积累，不立即产出
      pendingTexts.push(trimmed)
    } else {
      // 公式块 → 先 flush 积累的文本，再产出公式
      if (pendingTexts.length > 0) {
        blocks.push({ type: 'text', content: pendingTexts.join('\n\n') })
        pendingTexts = []
      }
      blocks.push({ type: 'formula', content: '$$\n' + trimmed + '\n$$' })
    }
  }
  // 尾部剩余文本
  if (pendingTexts.length > 0) {
    blocks.push({ type: 'text', content: pendingTexts.join('\n\n') })
  }

  // 安全上限：超过 MAX_TOTAL_BLOCKS 时截断
  if (blocks.length > MAX_TOTAL_BLOCKS) {
    blocks.splice(MAX_TOTAL_BLOCKS)
  }

  return blocks
}
```

**优化效果：** 上述例子从 5 个 block 降到 3 个，WebView 数量减少 40%。

---

### 11.3 🟡 嵌套滚动 — 必须禁用 WebView 内部滚动

原方案提到"List 统一自然滚动 (无嵌套)"但没有说明**如何确保无嵌套**。

每个 WebView 默认有自己的滚动容器。如果不显式禁用，用户手指在 WebView 上滑动时会被 WebView 拦截，List 不动。

**改进：所有 MathTextRenderer 在 FormulaSplitRenderer 上下文中必须：**

```typescript
// 每个 WebView 显式禁用内部滚动
Web({ ... })
  .scrollable(false)                     // 禁用内部滚动
  .nestedScroll({
    scrollForward: NestedScrollMode.PARENT_FIRST  // 触摸事件传递给父 List
  })
```

**重要：** 这意味着文本块的 1800vp 上限也必须放弃。如果文本块内容超过 1800vp 且 WebView 不可滚动，内容会被截断。→ 需要 **更细粒度的文本拆分** 或 **接受 1800vp 限制**（参见 11.7）。

---

### 11.4 🟡 串行化加载 — 避免 >5 个 WebView 同时初始化

HarmonyOS 社区反馈：5+ WebView 同时 `loadData` 会卡 UI 线程。

**改进：FormulaSplitRenderer 的 WebView 加载加入队列**

```typescript
private loadingQueue: number[] = []  // 待加载的 block 索引
private readonly MAX_CONCURRENT = 3   // 同时加载最多 3 个

// 初始化时：仅加载前 3 个可见 block
// 其余 block 用占位高度 (estimateHeight) + 延迟加载
// 用户滚动到附近时触发加载
```

---

### 11.5 🟡 KaTeX 字体每 WebView 重复加载

每个 WebView 是独立上下文，KaTeX WOFF2 字体 (~200KB) 在每个 WebView 中都要加载一次。20 个 WebView = 4MB 字体重复下载/解析。

**改进方案（调研建议）：**
1. **当前最优：** `render.html` 中 KaTeX CSS 用绝对路径引用 → HarmonyOS WebView 可能共享缓存 (需实测)
2. **备选：** 用 `<link rel="preload">` + `as="font"` + `crossorigin` 预加载字体到浏览器缓存
3. **未来：** 考虑 SSR 方案（见 11.8），服务端预渲染公式为纯 HTML/CSS，不再依赖客户端 KaTeX JS

---

### 11.6 🟢 `LazyForEach` 替代 `ForEach`

原方案用 `ForEach` 渲染 blocks。`ForEach` 是一次性创建所有子组件（即使不可见），对于多 WebView 场景会创建大量不可见的 WebView 实例。

**改进：**
```typescript
// 用 LazyForEach 替代 ForEach
// 仅在 block 进入可视区域时才创建对应的 MathTextRenderer
// 滚出可视区域时销毁 WebView，释放回池
LazyForEach(this.blockDataSource, (block: FormulaBlock, index: number) => {
  // ...
}, (block: FormulaBlock) => block.type + '_' + index.toString())
```

**注意：** ArkUI 中 `LazyForEach` 要求 data source 实现 `IDataSource` 接口，且 key 必须唯一稳定。这需要额外的 `BasicDataSource` 封装。

---

### 11.7 🟢 `renderToString` vs `renderMathInElement` 策略评估

调研发现当前 `render.html` 使用 `renderMathInElement`（树遍历模式），对于分块后的场景：

| 当前 (`renderMathInElement`) | 建议 (`renderToString`) |
|---|---|
| 对整个 DOM 做树遍历 | 按需对已知公式调用 |
| 每次渲染都重新扫描 | 只渲染传入的公式字符串 |
| 适合单 WebView 静态页面 | 适合已知公式位置的动态场景 |

**结论：** 对于公式块 (`forceDisplay=true`)，在 `render.html` 中添加一个新的 bridge 函数 `renderFormula(texString)` 直接调用 `katex.renderToString` 会更高效。**但这属于后续优化，首版可暂不改 `render.html`。**

---

### 11.8 🔵 中长期方向：SSR (服务端渲染公式)

调研发现所有主流 Chat 产品（ChatGPT/Claude/DeepSeek）都使用**单 DOM 树 + 内联公式**，没有任何产品使用多 WebView 拆分。多 WebView 是受限于 HarmonyOS 1800vp 上限的**临时方案**。

**推荐路线图：**

```
短期 (本方案)           中期 (SSR)               长期 (平台修复)
────────────────────────────────────────────────────────────
多 WebView 分块     →   服务端预渲染 KaTeX    →   单 WebView + 
+ 池化 + 合并          公式为 HTML 字符串         virtual scrolling
                        + 客户端仅负责插入        + content-visibility
                        + 消除客户端 KaTeX JS     + IntersectionObserver
```

**SSR 的收益：**
- 每个 WebView 不再需要加载 katex.min.js (~250KB) → init 快 50-100ms
- 不再有字体重复加载问题（公式已渲染为纯 HTML + CSS class）
- 客户端 WebView 变为纯 HTML 注入，无 JS 执行 → 更稳定
- 与长期目标（单 WebView）更兼容

---

### 11.9 📊 更新后的风险矩阵

基于调研补充的风险，更新原 §10：

| 风险 | 严重度 | 原方案缓解 | 调研补充缓解 |
|------|--------|-----------|-------------|
| **WebView 内存爆炸 (OOM)** | 🔴 高 | ❌ 未提及 | ✅ WebView 池化 (max 5) + block 上限 (30) + 相邻文本合并 |
| **>5 WebView 同时加载 ANR** | 🔴 高 | ❌ 未提及 | ✅ 串行化加载队列 (max concurrent 3) |
| **嵌套滚动冲突** | 🟡 中 | "List 统一滚动" (无具体措施) | ✅ 每个 WebView `.scrollable(false)` + `.nestedScroll(PARENT_FIRST)` |
| **KaTeX 字体重复加载** | 🟡 中 | ❌ 未提及 | ✅ preload 字体 + 后续 SSR |
| **空文本块空白 WebView** | 🟢 低 | `splitByFormulas` 过滤空块 | ✅ 保留（已处理） |
| **缓存 key 冲突** | 🟢 低 | cacheKey 含 `forceDisplay` | ✅ 保留（已处理） |
| **`\[...\]` 未被拆分** | 🟢 低 | 首版不支持 | ⚠️ 调研确认 ChatGPT/DeepSeek 主流用 `$$`，`\[...\]` 优先级可降 |
| **单个文本块超 1800vp** | 🟡 中 | ❌ 未提及 (假设不超) | ⚠️ 极端情况（超长文本无公式）可能仍需内部滚动；建议监控 + 后续按段落拆分 |

---

### 11.10 📝 实施步骤更新

原 §9 四步更新为六步：

| Step | 内容 | 变化 |
|------|------|------|
| Step 1 | 新建 `FormulaSplitRenderer.ets` | **增加**: 池化逻辑 + 相邻文本合并 + `MAX_POOL_SIZE`/`MAX_TOTAL_BLOCKS` 常量 |
| Step 2 | 修改 `MathTextRenderer.ets` | **增加**: `clampHeight` 区分 `forceDisplay` + 新增 prop `disableScroll: boolean` |
| Step 3 | 修改 `ChatBubble.ets` | 不变 |
| Step 4 | **新增**: `render.html` 微调 | 可选: 添加 `renderFormula` bridge 函数 (后续优化) |
| Step 5 | **新增**: `LazyForEach` 替换 `ForEach` | 需要 `BasicDataSource` 封装 + 滚动时 WebView 回收 |
| Step 6 | Build + 验证 | **增加**: 内存监控 (DevEco Profiler) + 5+ 公式消息压力测试 |

---

### 11.11 参考资料

两份详细调研报告：

| 文件 | 内容 |
|------|------|
| `docs/research-multi-webview-performance-20260724.md` | 多 WebView 内存/池化/嵌套滚动/ArkUI 限制 全分析 |
| `docs/research-formula-render-strategies-20260724.md` | KaTeX vs MathJax / SSR / ChatGPT 方案 / CSS containment |

> **关键结论：** 多 WebView 分块是 HarmonyOS 1800vp 上限下的**务实临时方案**，但必须搭配**池化 + 合并 + 串行加载**才能安全落地。长期应追踪平台修复并回归单 WebView + virtual scrolling 的行业主流方案。
