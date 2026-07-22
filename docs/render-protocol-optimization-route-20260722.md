# MathMind AI / LaTeX / Markdown / ArkUI 渲染共同协议优化路线

> 日期: 2026-07-22
> 分支: main
> 目标: 统一 AI 生成、LaTeX 公式、Markdown 解析、ArkUI/Web 渲染之间的内容协议，减少公式编译失败和渲染兜底混乱。

---

## 1. 背景与核心问题

MathMind 当前链路大致是:

```text
OCR / 手输文本
  -> TypeClassifier 识别分类
  -> KnowledgeModel 让 AI 生成结构化字段
  -> contentFromFields 拼成 Markdown 文本
  -> MarkdownParser 拆块
  -> MarkdownRenderer 用 ArkUI 渲染普通 Markdown
  -> MathTextRenderer + WebView + KaTeX 渲染公式
  -> LatexRiskNormalizer 做公式风险归一和兜底
```

公式经常编译失败，根因通常不是 KaTeX 单点问题，而是四方协议没有收束:

- AI 会输出裸 LaTeX, 例如 `\int x^n dx = ...`, 没有 `$...$` 或 `$$...$$`。
- AI 会把块级公式塞进中文句子里，Markdown 和 KaTeX 都难以稳定判断边界。
- AI 会在 `$$...$$` 内再写 `$...$`, 形成嵌套美元符。
- Markdown 会把 `*`、`_`、`#` 等符号当格式语法，而公式本来想让 KaTeX 处理。
- ArkUI 原生 `Text` 不能渲染数学公式，WebView 能渲染但成本更高，失败时必须退回纯文本。
- 当前 `MarkdownParser`、`MathTextParser`、`LatexRiskNormalizer` 都各自判断公式边界，规则不完全一致。

优化目标不是让 AI 写得更自由，而是反过来:

> AI 只生成受控内容；协议负责约束；归一化负责机械修复；渲染器只消费稳定格式；兜底只兜错误，不兜协议设计。

---

## 2. 总原则

### 2.1 单一事实源

整个工程只承认一种可存储的笔记正文协议:

```text
MathMind Note Markdown v1
```

简称 `MM-MD-v1`。它不是完整 Markdown，而是项目内白名单子集。

AI、数据库、Markdown 解析器、LaTeX 归一化器、ArkUI 渲染器都以这个协议为准。任何输入来源可以不规范，但入库前必须归一成 `MM-MD-v1`。

### 2.2 AI 不能直接控制页面结构

AI 可以生成:

- 标题候选
- 分类
- 标签
- 字段数组 `fields`
- 字段正文 `field.value`
- 必要的公式文本

AI 不应该生成:

- 顶层页面标题结构
- 原始 HTML
- 任意 Markdown 扩展
- 任意 ArkUI 样式含义
- 表格、图片、链接等当前渲染器不稳定支持的格式
- 复杂到本地无法校验的 LaTeX 宏

页面结构由 `KnowledgeModel.contentFromFields()` 或后续统一 `RenderDocumentBuilder` 构造。

### 2.3 兜底分层

兜底要有明确边界:

| 层级 | 负责对象 | 允许做什么 | 不允许做什么 |
|---|---|---|---|
| AI Prompt | 生成约束 | 说明协议、给正反例 | 假设 AI 一定遵守 |
| LlmGuard | JSON 外壳 | 校验字段类型、重试 | 解释数学内容 |
| ContentNormalizer | 文本协议 | 机械归一、修补边界 | 发明缺失公式 |
| LatexRiskNormalizer | 公式风险 | 修补可判定小问题 | 强行渲染高风险公式 |
| MarkdownParser | 块解析 | 容错拆块 | 抛异常阻断页面 |
| Renderer | 显示 | WebView 渲染或纯文本回退 | 空白失败 |

---

## 3. MM-MD-v1 协议

### 3.1 支持的块级语法

只支持以下块:

| 类型 | 写法 | 说明 |
|---|---|---|
| 标题 | `#` / `##` / `###` | AI 字段值里不推荐写标题，标题由上层拼接 |
| 段落 | 普通文本 | 可包含行内公式 |
| 无序列表 | `- item` | 只支持一层 |
| 有序列表 | `1. item` | 只支持一层 |
| 引用 | `> text` | 可用于注意点 |
| 代码块 | 三个反引号 | 代码块内不解析公式 |
| 分割线 | `---` | 少用 |
| 公式块 | 独立 `$$` fence | 重要公式、长公式、多行推导 |

暂不纳入 AI 生成协议:

- 表格
- 原始 HTML
- 图片
- 链接跳转
- 任务列表
- 多级嵌套列表
- 脚注
- Mermaid / 图表

这些能力以后可以加，但必须先扩展协议、解析器和兜底测试。

### 3.2 支持的行内语法

| 类型 | 写法 | 说明 |
|---|---|---|
| 加粗 | `**text**` | 只用于短强调 |
| 行内代码 | `` `code` `` | 不解析公式 |
| 行内公式 | `$...$` | 短公式，必须融入句子 |

不支持在同一段里混用复杂嵌套格式，例如:

```markdown
**当 $x \to 0$ 时 `code` 也成立**
```

这种内容应拆成普通文本或更简单的段落。

---

## 4. 数学公式协议

### 4.1 唯一推荐定界符

AI 生成和入库正文只推荐两种定界符:

| 类型 | 定界符 | 是否推荐 |
|---|---|---|
| 行内公式 | `$...$` | 推荐 |
| 独立公式块 | 独立行 `$$` / `$$` | 推荐 |
| 行内公式 | `\(...\)` | 只兼容输入，不作为 AI 输出 |
| 独立公式 | `\[...\]` | 只兼容输入，不作为 AI 输出 |
| 裸 LaTeX | `\frac{...}{...}` | 禁止直接入库 |

规范公式块必须写成:

```markdown
这里先说明公式用途。

$$
\int x^n\,dx = \frac{x^{n+1}}{n+1} + C \quad (n \neq -1)
$$

这里解释条件和结论。
```

不推荐写成:

```markdown
这里先说明 $$\int x^n dx = ...$$ 然后继续说。
```

### 4.2 什么时候用行内公式

满足以下条件时，用行内公式 `$...$`:

- 公式是句子的一部分。
- 公式较短，建议不超过 40 个字符。
- 只表达变量、条件、简单关系或短结论。
- 不需要用户横向查看、复制或逐步对齐。
- 不包含多行、不包含 `\\` 换行。

典型例子:

```markdown
当 $a > 0$ 时，二次函数开口向上。

极限中的自变量满足 $x \to 0$。

积分公式要求 $n \neq -1$。

导数为 $f'(x)=2x+1$。
```

行内公式适合融入文字，读者不应该因为它而中断阅读。

### 4.3 什么时候用独立公式块

满足任一条件时，用独立公式块:

- 公式是本段核心结论。
- 公式长度超过 40 个字符。
- 包含 `\frac`、`\sum`、`\int`、`\lim`、`\sqrt`、`\prod` 等复杂结构。
- 包含分段、矩阵、方程组、对齐推导。
- 需要展示多步等式变形。
- 公式包含多个条件或约束。
- 用户需要单独检查公式是否正确。

典型例子:

```markdown
幂函数积分公式为:

$$
\int x^n\,dx = \frac{x^{n+1}}{n+1} + C \quad (n \neq -1)
$$
```

多步推导用 `aligned`, 不要用裸 `align`:

```markdown
配方过程为:

$$
\begin{aligned}
ax^2 + bx + c
&= a\left(x^2 + \frac{b}{a}x\right) + c \\
&= a\left(x + \frac{b}{2a}\right)^2 + c - \frac{b^2}{4a}
\end{aligned}
$$
```

### 4.4 块级公式不要融入句子

错误:

```markdown
由 $$a^2+b^2=c^2$$ 可知三角形是直角三角形。
```

正确:

```markdown
由勾股定理可得:

$$
a^2 + b^2 = c^2
$$

因此该三角形是直角三角形。
```

如果必须放在句子中，就改成行内公式:

```markdown
由 $a^2+b^2=c^2$ 可知三角形是直角三角形。
```

### 4.5 公式块内部禁止再写行内公式

错误:

```markdown
$$
\int x^n\,dx = \frac{x^{n+1}}{n+1}+C \quad ($n \neq -1$)
$$
```

正确:

```markdown
$$
\int x^n\,dx = \frac{x^{n+1}}{n+1}+C \quad (n \neq -1)
$$
```

规则:

- `$$...$$` 内部不允许出现 `$`。
- `$$...$$` 内的条件也属于同一个数学环境。
- 中文解释不要写进公式块，除非使用 `\text{}` 且内容很短。

### 4.6 标题里禁止公式

错误:

```markdown
## 求 $\int x^n dx$
```

正确:

```markdown
## 幂函数积分

要求计算:

$$
\int x^n\,dx
$$
```

原因:

- 标题由 ArkUI 原生 `Text` 渲染，公式会被当普通文本。
- 标题参与列表、搜索、缓存 key, 不适合放复杂符号。
- 标题失败会影响整个笔记可扫读性。

### 4.7 列表项中的公式规则

列表项只允许短行内公式:

```markdown
- 当 $a>0$ 时开口向上。
- 顶点横坐标是 $-\frac{b}{2a}$。
```

如果公式很长，列表项只写说明，公式块放在列表外:

```markdown
- 使用求根公式求解。

$$
x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}
$$
```

不要把公式块缩进列表项内。当前解析器不支持嵌套块级公式。

---

## 5. 常见编译失败与处理策略

| 失败类型 | 错误示例 | 原因 | 处理 |
|---|---|---|---|
| 裸公式 | `\frac{a}{b}` | 没有定界符 | 独立行公式自动包 `$$...$$`, 短符号包 `$...$` |
| 未闭合 `$` | `$x+1` | 行内公式边界破坏 | 回退纯文本，不自动猜闭合 |
| 嵌套 `$` | `$$ x=$a$ $$` | display 内嵌 inline | 删除内部 `$` 或回退 |
| 括号不配对 | `\frac{x+1}{` | KaTeX 无法解析 | 回退纯文本，不发明缺失内容 |
| `\left/\right` 不配对 | `\left( x+1` | 成对命令缺失 | 回退纯文本或提示确认 |
| Markdown 冲突 | `a_b` 出现在普通段落 | `_` 被误判格式或公式信号 | 数学表达式必须放入 `$...$` |
| 块公式塞入句子 | `若 $$...$$ 成立` | 块级语义破坏 | 拆成前后段落 |
| 代码块中公式 | 三反引号内写公式 | 代码块不渲染公式 | 保持代码原样，不解析 |
| 不支持宏 | `\newcommand` | KaTeX 安全和能力限制 | 禁止 AI 输出，回退纯文本 |
| 环境不支持 | `\begin{align}` | KaTeX/渲染配置可能不稳定 | 使用 `\begin{aligned}` 包在 `$$` 内 |

关键原则:

> 可以机械修复边界，不能创造数学内容。

可自动修:

- CRLF -> LF
- 裸复杂公式独立成块
- `\fract{` -> `\frac{`
- `\sqt{` -> `\sqrt{`
- `\begin{align*}` -> `\begin{aligned}`
- `, dx` / ` dx` -> `\,dx`
- display 内部多余 `$` 删除

不可自动修:

- 缺失分子/分母
- 缺失等式右边
- 未知变量含义
- 未闭合但无法判断位置的 `{`
- 不确定的 OCR 符号
- 数学结论本身

---

## 6. AI 输出规范

### 6.1 TypeClassifier

`TypeClassifier` 只返回分类 JSON, 不返回 Markdown:

```json
{
  "category": "计算题",
  "subject": "数学分析",
  "chapter": "不定积分",
  "confidence": 0.86
}
```

约束:

- `category` 必须是 `概念 / 定理 / 公式 / 证明题 / 计算题`。
- 不允许输出解释段落。
- 不允许输出 Markdown 代码块。
- 不负责修公式，只负责分类。

相关文件:

- `agents/src/main/ets/agents/TypeClassifier.ets`
- `common/src/main/ets/llm/LlmOutputRules.ets`

### 6.2 KnowledgeModel

`KnowledgeModel` 输出结构化 JSON:

```json
{
  "category": "公式",
  "subject": "数学分析",
  "title": "幂函数积分公式",
  "tags": ["不定积分", "幂函数", "积分公式"],
  "difficulty": 2,
  "importance": 4,
  "fields": [
    {
      "key": "expression",
      "label": "表达式",
      "value": "幂函数积分公式为:\n\n$$\n\\int x^n\\,dx = \\frac{x^{n+1}}{n+1} + C \\quad (n \\neq -1)\n$$"
    }
  ]
}
```

字段值 `field.value` 必须遵守:

- 不写 `#` / `##` 标题，外层会生成标题。
- 可以写普通段落、短列表、行内公式、独立公式块。
- 一个字段里公式块前后必须空行。
- 不写原始 HTML。
- 不写表格。
- 不写嵌套列表。
- 不写未验证的 LaTeX 宏。

相关文件:

- `agents/src/main/ets/agents/KnowledgeModel.ets`
- `agents/src/main/ets/models/KnowledgeUnitExt.ets`
- `common/src/main/ets/llm/LlmOutputRules.ets`

### 6.3 推荐追加到 Prompt 的规则

建议把当前 `LATEX_GENERATION_RULES` 扩充成中文强约束，核心内容如下:

```text
公式输出规则:
1. 短公式放入句子时使用 $...$。
2. 重要公式、长公式、多步推导必须使用独立 $$ 块，且 $$ 单独成行。
3. $$ 块前后必须有空行。
4. $$ 块内部禁止再出现 $。
5. 不要输出裸 LaTeX 命令行。
6. 标题、标签、字段 label 中禁止公式。
7. 列表项中只允许短行内公式；长公式放在列表外的独立 $$ 块。
8. 多行推导使用 \begin{aligned}...\end{aligned}, 不使用 align/align*。
9. 不确定的 OCR 符号保留原文并标注“待确认”，不要补造公式。
```

---

## 7. 归一化与验证路线

### 7.1 新增统一入口

建议新增一个统一协议入口，避免多个 parser 各自猜公式:

```text
common/src/main/ets/render/ContentProtocol.ets
```

职责:

- `normalizeNoteMarkdown(raw: string): NormalizedContent`
- `validateNoteMarkdown(raw: string): ContentValidationResult`
- `splitFormulaDelimitedText(raw: string): RenderBlock[]`
- `normalizeFormulaBoundary(raw: string): string`

建议类型:

```ts
export type RenderBlockKind = 'paragraph' | 'heading' | 'list' | 'quote' | 'code' | 'formula' | 'rule';

export interface RenderBlock {
  kind: RenderBlockKind;
  text: string;
  level: number;
  items: string[];
  ordered: boolean;
  lang: string;
  risk: string;
}

export interface ContentValidationResult {
  ok: boolean;
  normalizedText: string;
  issues: string[];
  fixes: string[];
  fallbackRequired: boolean;
}
```

注意 ArkTS 1.1 strict:

- 不用 `any` / `unknown`。
- 不用 C 风格 `for`。
- interface 显式声明对象结构。

### 7.2 入库前归一化

当前 `KnowledgeModel.contentFromFields()` 会拼 Markdown。建议调整为:

```text
AI fields
  -> normalize field.value
  -> validate MM-MD-v1
  -> contentFromFields 拼接 ## label
  -> 再整体 validate
  -> 入库
```

如果验证失败:

1. 可修复问题: 自动修复后入库。
2. 高风险公式: 公式保留为纯文本，不交给 KaTeX。
3. JSON 结构不合法: `LlmGuard` 带 issues 重试。
4. 重试仍失败: 生成“待整理原文”笔记，正文只存 OCR 原文，不伪造结构化公式。

### 7.3 渲染前只做轻量归一

渲染前不要再做大规模内容改写。原因:

- 入库内容应是稳定协议。
- 渲染器每次打开都会执行，重写成本高。
- 多处重写会导致同一条笔记在不同页面显示不一致。

渲染前只允许:

- CRLF -> LF
- 计算缓存 key
- 判断是否 WebView 渲染
- 公式失败时纯文本显示

---

## 8. Renderer 统一路线

### 8.1 当前组件分工

| 文件 | 当前职责 |
|---|---|
| `entry/src/main/ets/utils/MarkdownParser.ets` | 解析 Markdown 块 |
| `entry/src/main/ets/utils/MarkdownInlineParser.ets` | 解析加粗、行内代码 |
| `entry/src/main/ets/shared/components/MarkdownRenderer.ets` | ArkUI 原生渲染 Markdown |
| `common/src/main/ets/utils/LatexRiskNormalizer.ets` | LaTeX 风险归一 |
| `entry/src/main/ets/shared/components/MathTextRenderer.ets` | WebView + KaTeX 渲染公式 |
| `entry/src/main/resources/rawfile/render.html` | WebView 内 marked + KaTeX 渲染 |

问题是 `MarkdownRenderer.containsFormulaSyntax()`、`MarkdownParser.isFormulaFence()`、`MathTextRenderer.normalizeForRender()`、`render.html normalizeBareMath()` 都在判断公式。

### 8.2 目标分工

建议收束成:

```text
ContentProtocol
  -> 只负责协议、拆块、公式边界、风险标记

MarkdownRenderer / RichContentRenderer
  -> 只负责按 RenderBlock 渲染

MathTextRenderer
  -> 只负责一个公式块或一个含行内公式的段落

render.html
  -> 只负责 KaTeX/marked 展示，不再做复杂猜测
```

### 8.3 推荐渲染顺序

推荐顺序:

```text
Raw content
  -> ContentProtocol 归一化
  -> MarkdownParser 拆块
  -> 按 block.kind 分流
  -> ArkUI 原生渲染普通块
  -> MathTextRenderer 渲染数学块/数学段落
  -> WebView + KaTeX 编译公式
  -> 失败时 ArkUI Text 显示原始公式
```

也就是:

```text
协议归一优先
Markdown 拆结构第二
ArkUI 负责页面承载
KaTeX 只处理已经确认的数学内容
```

不要采用:

```text
Raw content -> KaTeX -> Markdown -> ArkUI
```

原因:

- KaTeX 不知道 Markdown 的代码块、引用、列表和标题边界。
- 如果先跑 KaTeX, 代码块里的 `\int` 也可能被误当公式。
- `$$` 是否是公式块，必须先由 Markdown/协议层根据“是否独立成行”判断。
- ArkUI 原生 `Text` 不能理解数学公式，但它最适合渲染普通文本、标题、列表和布局。
- WebView/KaTeX 成本高，应该只给确认为数学的块使用。

更精确的分流规则:

| Markdown block | 是否走 ArkUI | 是否走 KaTeX | 说明 |
|---|---:|---:|---|
| heading | 是 | 否 | 标题禁止公式 |
| paragraph 无 `$` / `\` 公式信号 | 是 | 否 | 原生 Text + Span |
| paragraph 含行内公式 | 外层 ArkUI | 是 | 整段交给 MathTextRenderer |
| list | 是 | 仅短行内公式 | 列表项长公式应拆到列表外 |
| quote | 是 | 仅短行内公式 | 同 paragraph |
| code | 是 | 否 | 代码块不解析公式 |
| formula | 外层 ArkUI | 是 | `MathTextRenderer(forceDisplay=true)` |
| rule | 是 | 否 | Divider |

因此实际组件关系应理解为:

```text
ArkUI MarkdownRenderer
  ├─ Text / Span / Column / Row / Divider
  └─ MathTextRenderer
       └─ WebView render.html
            └─ KaTeX
```

ArkUI 不是 KaTeX 的前置解析器，而是最终 UI 容器；Markdown 也不是视觉层，而是结构拆分层。KaTeX 的输入必须是已经被协议层确认的公式文本。

最终渲染入口建议统一为:

```text
RichContentRenderer(text, profile)
```

它内部:

- 纯文本段落走 ArkUI `Text`
- 普通 Markdown 行内格式走 ArkUI `Text + Span`
- 含行内公式段落走 `MathTextRenderer`
- 独立公式块走 `MathTextRenderer(forceDisplay=true)`
- 高风险公式走 ArkUI 纯文本 fallback

### 8.4 WebView 兜底

WebView 失败时不应该出现空白。最低兜底:

```text
如果 KaTeX 编译失败:
  1. 显示原始公式文本
  2. 保留换行
  3. 使用 monospace 或普通 Text
  4. 不阻断其他段落
```

独立公式块 fallback 可以长这样:

```text
\int x^n dx = ...
```

不要显示“公式渲染失败”这种占位文案替代公式本身。用户最需要的是看见原始内容。

---

## 9. 分阶段实施路线

### P0: 文档和协议冻结

目标:

- 确认 `MM-MD-v1` 白名单。
- 明确行内公式和独立公式判定。
- 明确 AI 不允许生成的格式。
- 明确兜底分层。

产出:

- 本文档。
- 后续 PR 中把关键规则同步到 `LlmOutputRules.ets` 注释或常量。

### P1: Prompt 与 LlmGuard 强化

目标:

- 扩充 `LATEX_GENERATION_RULES`。
- `KnowledgeModel.validateAiJson()` 额外检查 `field.value` 公式边界。
- 检查失败时通过 `buildGuardRetryMessage()` 让 AI 重试。

建议新增校验:

- `field.value` 中 `$$` 数量必须为偶数。
- `$$` 必须独立成行。
- `$$...$$` 内不得出现 `$`。
- 标题和 label 不得包含 `$`、`\frac`、`\sum` 等公式信号。
- 不允许原始 HTML。
- 不允许表格分隔符 `| --- |`。

### P2: ContentProtocol 统一归一化

目标:

- 新增 `ContentProtocol.ets`。
- `MarkdownParser` 和 `MathTextRenderer` 共享同一套公式边界判断。
- 入库前执行一次 normalize。

建议迁移顺序:

1. 把 `LatexRiskNormalizer` 的边界判断能力抽到协议层。
2. 保留 `LatexRiskNormalizer` 处理公式内部风险。
3. `MarkdownParser` 只接收已归一文本。
4. 删除 `render.html` 里过多的裸公式猜测，只留保险级兼容。

### P3: 测试用例补齐

目标:

- 公式失败不再靠人工发现。

建议测试集:

| 测试名 | 输入 | 期望 |
|---|---|---|
| inline_short_formula | `当 $a>0$ 时开口向上` | 段落含行内公式 |
| display_integral | 独立 `$$` 积分 | 公式块 |
| reject_display_inside_sentence | `若 $$x=1$$ 成立` | validation issue |
| reject_nested_dollar | `$$ x=$a$ $$` | validation issue |
| fallback_unclosed_brace | `$$\frac{x}{1$$` | plainFallback |
| keep_code_block | 代码块内 `\int` | 不解析公式 |
| reject_formula_in_heading | `## 求 $x$` | validation issue |
| list_inline_ok | `- 当 $x>0$ 时` | list item |
| list_display_reject | 列表项缩进公式块 | validation issue |

已有相关测试:

- `common/src/test/LatexRiskNormalizer.test.ets`

### P4: RichContentRenderer 收口

目标:

- 对外只暴露一个富文本渲染组件。
- Notes、Chat、Preview 都走同一协议，不再各自判断。

建议:

- `MarkdownRenderer` 改名或包一层为 `RichContentRenderer`。
- `profile` 决定字号、间距、最大高度。
- `RenderBlock.risk` 决定是否允许 KaTeX。
- 公式块固定横向滚动，避免撑爆 ArkUI 布局。

### P5: 可观测性

目标:

- 后续排查知道是哪一层兜底。

建议日志字段:

```text
render.protocol.version=MM-MD-v1
render.block.count=8
render.formula.inline=3
render.formula.display=2
render.latex.risk=fixable
render.fallback.count=1
render.fixes=wrap_display_delimiter,normalize_differential_dx
```

用户界面不一定要显示这些信息，但 console 和 debug 开关要能看到。

---

## 10. 最小验收标准

一轮优化完成后，至少满足:

- AI 裸输出 `\int x^n dx = ...` 时，入库前能转成公式块或纯文本 fallback。
- AI 输出 `$$ $x$ $$` 时，不会进入 KaTeX 编译崩溃路径。
- 块级公式不会出现在中文句子中。
- 标题、标签、字段 label 不含公式。
- 列表中短公式可渲染，长公式自动拆出列表或报 validation issue。
- KaTeX 失败时显示原始公式，不出现空白。
- 纯文本笔记不经过 WebView。
- 同一条笔记在详情页、预览、聊天引用中公式边界一致。

---

## 11. 推荐优先修改文件

第一批:

- `common/src/main/ets/llm/LlmOutputRules.ets`
- `agents/src/main/ets/agents/KnowledgeModel.ets`
- `common/src/main/ets/utils/LatexRiskNormalizer.ets`
- `common/src/test/LatexRiskNormalizer.test.ets`

第二批:

- `entry/src/main/ets/utils/MarkdownParser.ets`
- `entry/src/main/ets/utils/MarkdownInlineParser.ets`
- `entry/src/main/ets/shared/components/MarkdownRenderer.ets`
- `entry/src/main/ets/shared/components/MathTextRenderer.ets`

第三批:

- `entry/src/main/resources/rawfile/render.html`
- Notes / Chat / Preview 调用方

---

## 12. 给后续实现的直接规则

可以把下面规则当成工程硬约束:

1. 入库正文必须是 `MM-MD-v1`。
2. AI 字段值只能使用协议白名单 Markdown。
3. 短公式融入文字，用 `$...$`。
4. 长公式、核心公式、多步推导独立成块，用单独成行的 `$$`。
5. `$$` 内部禁止 `$`。
6. 公式块前后必须空行。
7. 标题、标签、字段 label 禁止公式。
8. 列表项只允许短行内公式。
9. 裸 LaTeX 不直接入库。
10. 不确定的 OCR 公式保留原文，不补造。
11. 可机械修复的边界自动修。
12. 高风险公式纯文本 fallback。
13. KaTeX 失败显示原始公式，不显示空白。
14. Markdown 解析失败时退回普通段落。
15. ArkUI 不直接理解数学语义，只消费协议解析结果。

---

## 13. 参考当前链路

当前已经存在的基础能力:

- `JSON_ONLY_RULES` 和 `LATEX_GENERATION_RULES` 已在 `common/src/main/ets/llm/LlmOutputRules.ets`。
- `LlmGuard.callJsonWithRetry()` 已能基于 validation issues 重试。
- `KnowledgeModel.validateAiJson()` 已校验 JSON 外壳。
- `LatexRiskNormalizer` 已有 `none / fixable / fallback` 风险级别。
- `MarkdownParser` 已能解析标题、段落、列表、引用、代码块、公式块。
- `MarkdownRenderer` 已能把含公式段落交给 `MathTextRenderer`。
- `MathTextRenderer` 已有 WebView 缓存、延迟渲染和 plain fallback。

下一步不是推翻，而是把这些能力接到同一协议入口，减少重复猜测。

---

## 14. 外部资料调研: 主流渲染器与 AI 应用怎么处理

> 调研时间: 2026-07-22
> 资料原则: 只采用官方文档 / 一手说明，不采用论坛猜测。

### 14.1 CommonMark: 先块结构，后行内结构

CommonMark 的解析策略明确把 Markdown 看成块树，先识别段落、标题、列表、引用、代码块等块结构，再解析块内部的行内结构。官方 spec 的 Appendix 也按 `Phase 1: block structure` 描述这一点。

对 MathMind 的结论:

- `Raw -> Markdown block -> inline/math` 的顺序是合理的。
- 不能先全局跑 KaTeX, 因为 KaTeX 不知道哪些内容属于代码块、标题或列表。
- 公式块必须先被协议层识别成一个独立 block, 再交给 KaTeX。

参考: [CommonMark Spec 0.31.2 - Phase 1: block structure](https://spec.commonmark.org/0.31.2/)

### 14.2 KaTeX: delimiter 顺序和 ignoredTags 是关键

KaTeX auto-render 会在给定 DOM 元素内递归搜索文本节点，再按 delimiter 渲染数学表达式。官方文档里默认忽略 `script / noscript / style / textarea / pre / code / option` 等标签；如果启用 `$...$`, 也强调 `$` 规则要放在 `$$` 后面，否则会把 `$$` 误识别成空的行内公式。

对 MathMind 的结论:

- 不能把整篇 Markdown 无差别交给 KaTeX auto-render。
- 即便在 WebView 内用 KaTeX, 也应该只把已确认的公式段落/公式块交进去。
- 如果保留 `render.html` 的 auto normalize, 它只能作为保险，不能作为主协议。
- 当前 `$$ -> display`、`$ -> inline` 的判断顺序必须固定为先 `$$`, 后 `$`。

参考: [KaTeX Auto-render Extension](https://katex.org/docs/autorender.html)

### 14.3 MathJax: 默认不启用 `$...$`, 因为美元符有歧义

MathJax 4 默认使用 `\(...\)` 作为行内数学，`\[...\]` 和 `$$...$$` 作为展示数学；官方说明默认不启用 `$...$`, 因为普通文本里的价格、金额等美元符容易被误当公式。MathJax 也提供 `\$` 或隔离 HTML span 的方式避免误匹配。

对 MathMind 的结论:

- 单美元 `$...$` 虽然简洁，但必须由协议层严格约束。
- MathMind 是数学学习 App, 公式密度高，可以继续把 `$...$` 作为入库标准，但要增加校验:
  - `$` 必须成对。
  - 普通价格、美元符必须转义或走纯文本。
  - `$$...$$` 内部禁止 `$`。
- 如果未来要兼容更多模型默认输出，可以允许输入 `\(...\)` / `\[...\]`, 但入库时统一归一成 `$...$` / `$$...$$` 或反过来统一成 MathJax 风格。关键是只能有一个入库标准。

参考: [MathJax TeX and LaTeX math delimiters](https://docs.mathjax.org/en/latest/input/tex/delimiters.html)

### 14.4 GitHub: Markdown 中支持数学，但提供冲突逃逸写法

GitHub 官方文档说明其 Markdown 数学渲染使用 MathJax。行内公式可以用 `$...$`, 也可以用 `$` 加反引号的写法来避免与 Markdown 语法冲突；块级公式可以用 `$$`，也可以用 `math` 代码块。

对 MathMind 的结论:

- GitHub 的做法说明“Markdown + MathJax/LaTeX”可行，但它不是让所有 Markdown 自由混排，而是给了明确的 delimiter 和冲突逃逸规则。
- MathMind 当前不建议引入 GitHub 的 `$` + 反引号语法，ArkUI parser 会更复杂。
- 可以在 P3 测试集里加入“公式内容与 Markdown 符号冲突”的用例，例如 `_`、`*`、反引号、美元符。
- `math` 代码块可作为未来扩展，但当前协议仍以 `$$` 公式块为唯一标准。

参考: [GitHub Docs - Writing mathematical expressions](https://docs.github.com/en/enterprise-cloud@latest/get-started/writing-on-github/working-with-advanced-formatting/writing-mathematical-expressions)

### 14.5 OpenAI / ChatGPT: Markdown + LaTeX, 但强调不要混复杂元素

OpenAI Model Spec 明确建议默认使用 Markdown with LaTeX extensions；数学表达式用 `\(...\)` 表示行内公式，用 `\[...\]` 表示展示公式，并要求展示公式的 delimiters 单独成行；同时提醒保持数学表达式短，不要把复杂 LaTeX 和多个 Markdown 元素混在一起。

OpenAI 结构化输出资料也说明，仅靠 prompting 和重试不足以保证系统可消费的格式；Structured Outputs 通过 JSON Schema 约束模型输出。但官方也提示，结构化输出不能防止 JSON 字段值内部的数学步骤出错，仍需要例子、拆分任务和校验。

对 MathMind 的结论:

- Prompt 里必须写“短公式/长公式/块公式/标题禁公式”的具体规则。
- 不要让 AI 直接输出最终页面 Markdown。更稳的是让 AI 输出 JSON fields, 本地再拼 Markdown。
- 对 `fields[].value` 仍要做二级校验，因为 JSON schema 只能保证字段形状，不能保证 LaTeX 内容正确。
- 复杂内容拆成两步: 先结构化字段，再本地协议归一和公式校验。

参考:

- [OpenAI Model Spec - Use Markdown with LaTeX extensions](https://model-spec.openai.com/2025-02-12.html)
- [OpenAI - Introducing Structured Outputs in the API](https://openai.com/index/introducing-structured-outputs-in-the-api/)

### 14.6 Anthropic / Claude: 默认会输出 LaTeX, 格式需要显式约束

Anthropic 的 Claude prompting 文档说明，Claude 新模型默认会在数学表达式、方程和技术解释中使用 LaTeX；如果应用想要纯文本，需要在 prompt 中明确禁止 LaTeX、MathJax 或 markup。Anthropic 也强调用明确输出格式、示例和 XML tag 帮模型理解复杂格式要求。

对 MathMind 的结论:

- 对 Claude、DeepSeek、GPT、Gemini 等模型都不能只写“请输出 Markdown”。必须写协议级规则和反例。
- 对 Claude 这类默认偏 LaTeX 的模型，要特别强调:
  - 不要裸 LaTeX。
  - display math 必须独立成块。
  - 字段 label / title 禁止公式。
- 可以在 prompt 里用 `<format_rules>`、`<examples>` 包住规则，减少模型把规则误当正文输出的概率。

参考: [Claude Platform Docs - Prompting best practices / LaTeX output](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

### 14.7 Gemini: 支持结构化输出，Canvas 把 LaTeX 当文档能力处理

Gemini API 官方文档支持按 JSON Schema 生成结构化输出，用于类型安全的数据抽取、分类和 agent workflow。Gemini Canvas 帮助文档也把 LaTeX 作为文档创建/导出能力处理，支持预览和导出 PDF；复制包含 LaTeX 的 Gemini 响应时，会保留未渲染的 LaTeX 代码。

对 MathMind 的结论:

- 结构化输出和可渲染文档应分层，不能把“AI 回复文本”直接等同于“可入库富文本”。
- 保留原始 LaTeX 源码很重要。渲染失败时显示原始公式，而不是空白或丢弃。
- MathMind 的 `rawText / normalizedText / fallbackText` 三份信息可以继续保留，后续最好落入明确类型。

参考:

- [Gemini API - Structured outputs](https://ai.google.dev/gemini-api/docs/structured-output)
- [Gemini Apps Help - Add LaTeX to a document](https://support.google.com/gemini/answer/16047321)

### 14.8 Microsoft Copilot / Adaptive Cards: 内容语义化，宿主控制 UI

Microsoft Adaptive Cards 的设计目标是用 JSON 描述 UI 内容，由宿主应用渲染成原生 UI；官方原则里明确强调 declarative、no code、自动适配宿主样式，并提出“内容作者拥有内容，宿主应用拥有外观”。

对 MathMind 的结论:

- 这是 AI 应用里非常值得借鉴的模式: AI 只给语义内容，不给最终 UI。
- `KnowledgeUnitExt.fields` 就应该类似 Adaptive Cards 的 content schema, ArkUI 才是 host renderer。
- MathMind 不应允许 AI 输出 ArkUI 样式、HTML、CSS 或任意 Markdown 扩展。
- 后续如果做更复杂卡片，不要把 Markdown 继续扩到无限大，而应新增 typed block, 例如 `FormulaBlock / StepBlock / ErrorPointBlock / TheoremBlock`。

参考: [Microsoft Adaptive Cards Overview](https://learn.microsoft.com/en-us/adaptive-cards/)

---

## 15. 对 MathMind 的最终取舍

结合上面的资料，MathMind 不建议复制某一个平台的语法，而应该固定自己的窄协议:

```text
AI JSON fields
  -> MM-MD-v1 白名单正文
  -> ContentProtocol 归一与校验
  -> Markdown block parser
  -> ArkUI native renderer
  -> KaTeX only for math blocks/math paragraphs
  -> plain text fallback with original formula
```

具体取舍:

| 问题 | 外部资料倾向 | MathMind 取舍 |
|---|---|---|
| 行内公式 delimiter | OpenAI/MathJax 偏 `\(...\)`, GitHub 支持 `$...$` | 保持 `$...$`, 但强校验；兼容输入 `\(...\)` |
| 块级公式 delimiter | OpenAI/MathJax 偏 `\[...\]`, GitHub/KaTeX 支持 `$$` | 保持独立行 `$$`, 兼容输入 `\[...\]` |
| 先 Markdown 还是先 KaTeX | CommonMark/KaTeX 都支持先结构边界 | 先 Markdown block, 后数学渲染 |
| AI 输出 | OpenAI/Gemini 强调 structured outputs | AI 输出 JSON fields, 本地拼正文 |
| UI 控制 | Adaptive Cards 强调 host owns look | ArkUI 控制 UI, AI 不控制样式 |
| 渲染失败 | MathJax/Gemini 都保留源码价值 | 显示原始公式，不空白 |
| 复杂格式 | Adaptive Cards “when in doubt, keep it out” | MM-MD-v1 白名单，不开放完整 Markdown |

### 15.1 推荐更新当前文档中的一条关键规则

原规则:

```text
AI 生成和入库正文只推荐两种定界符: $...$ 和 $$
```

建议细化为:

```text
入库标准只允许 $...$ 和独立行 $$...$$。
输入兼容 \(...\) 和 \[...\]。
AI prompt 可以明确要求 $...$ / $$...$$，因为当前 MathMind parser 已按这个方向实现。
如果未来切到 MathJax 风格，则必须全链一次性迁移，不要两套标准长期并存。
```

### 15.2 推荐新增测试优先级

最高优先级测试不是“KaTeX 能不能渲染复杂公式”，而是边界测试:

```text
1. 代码块内 \int 不渲染
2. 标题内 $x$ 被 validation 拒绝
3. 列表项内短 $x>0$ 允许
4. 列表项内独立 $$ 拒绝
5. 中文句子中 $$...$$ 拒绝
6. $$ 内部 $x$ 拒绝或修复
7. 裸 \frac 独立行归一为 $$
8. 未闭合 { 走 plain fallback
9. 普通美元金额不被当公式
10. KaTeX 抛错时原文可见
```

这些测试通过后，再追求更复杂的 LaTeX 能力。

---

## 16. 各大模型适配要点与技术栈

这一节直接面向后续实现 plan。核心思想:

```text
同一份 MathMind 内容协议
  + 每个模型一个 ProviderAdapter
  + 每个 Adapter 声明自己支持的结构化输出能力
  + 所有模型输出都进入同一套 ContentProtocol / LaTeX validator
```

不要把模型差异散落在 `KnowledgeModel.buildPrompt()` 里，否则后续加模型会失控。

### 16.1 能力分级

模型输出控制能力建议分 4 档:

| 档位 | 能力 | 可依赖程度 | MathMind 策略 |
|---|---|---:|---|
| A | JSON Schema / strict structured output | 高 | 首选，模型端约束字段结构 |
| B | Tool strict / function schema | 高 | 适合把结构化结果当 tool args |
| C | JSON object mode | 中 | 只保证 JSON 语法，不保证 schema |
| D | Prompt-only JSON | 低 | 必须强校验、重试、必要时 fallback |

注意:

- A/B 只能约束 JSON 外壳，不能保证 `field.value` 内部 LaTeX 一定可编译。
- C/D 必须本地校验字段、类型、枚举、公式边界。
- 不管哪一档，最终都要进入 `MM-MD-v1` 校验。

### 16.2 ProviderAdapter 类型

建议新增:

```text
common/src/main/ets/llm/ProviderCapabilities.ets
common/src/main/ets/llm/ProviderAdapter.ets
common/src/main/ets/llm/adapters/OpenAiCompatibleAdapter.ets
common/src/main/ets/llm/adapters/ClaudeAdapter.ets
common/src/main/ets/llm/adapters/GeminiAdapter.ets
```

能力声明建议:

```ts
export interface ProviderCapabilities {
  providerId: string;
  supportsJsonSchema: boolean;
  supportsJsonObject: boolean;
  supportsStrictToolUse: boolean;
  needsJsonKeyword: boolean;
  supportsThinkingToggle: boolean;
  preferThinkingDisabledForJson: boolean;
  rootJsonObjectOnly: boolean;
  canReturnEmptyJsonContent: boolean;
  jsonCanBeTruncatedByMaxTokens: boolean;
  preferredFormulaDelimiters: string;
}
```

ArkTS strict 注意:

- 不用 `Record<string, any>`。
- capabilities 用显式 interface。
- 每个 provider 用普通 class 常量返回，避免复杂对象字面量 union。

### 16.3 GPT / OpenAI 系列

资料要点:

- OpenAI API 支持 `json_schema` Structured Outputs；旧 `json_object` 只保证有效 JSON，不保证 schema。
- Function calling 里也可以通过 `strict: true` 约束 tool 参数。
- OpenAI Model Spec 推荐 Markdown + LaTeX extension, 常用 `\(...\)` 和 `\[...\]`，并要求展示公式 delimiter 单独成行。

MathMind 要注意:

- 如果走 OpenAI 原生 API，优先用 `response_format: { type: "json_schema", ... strict: true }`。
- 如果走 OpenAI-compatible 中转但不支持 `json_schema`, 降级到 `json_object`。
- Prompt 必须明确覆盖模型默认习惯: MathMind 入库标准使用 `$...$` 和独立行 `$$...$$`。
- `field.value` 仍要跑公式边界校验，Structured Outputs 不能保证数学公式可编译。

技术栈:

| 层 | 方案 |
|---|---|
| API | Responses API / Chat Completions, 优先 `json_schema` |
| Schema | `KnowledgeUnitDraftSchema` |
| 本地校验 | `LlmGuard.validateAiJson()` + `ContentProtocol.validateFieldValue()` |
| 重试 | validation issues -> `buildGuardRetryMessage()` |
| 渲染 | MM-MD-v1 -> Markdown block -> KaTeX |

推荐 Adapter:

```text
OpenAIAdapter
  supportsJsonSchema=true
  supportsJsonObject=true
  needsJsonKeyword=false for json_schema
  preferredFormulaDelimiters="override_to_mathmind_dollar"
```

参考:

- [OpenAI API response_format / Structured Outputs](https://platform.openai.com/docs/api-reference/chat/object)
- [OpenAI Model Spec](https://model-spec.openai.com/2025-02-12.html)

### 16.4 Claude / Anthropic 系列

资料要点:

- Claude Structured Outputs 提供 JSON outputs (`output_config.format`) 和 strict tool use (`strict: true`)。
- Anthropic 文档说明 structured outputs 通过 constrained sampling / grammar compilation 工作，首次 schema 会有额外编译延迟，且 schema 有复杂度限制。
- Claude prompt 对明确格式、示例、XML tag 边界比较敏感，复杂 prompt 可用 `<format_rules>`、`<examples>` 分隔。

MathMind 要注意:

- Claude 原生 API 不是 OpenAI Chat Completions 形状，不能强塞进 `OpenAiCompatibleAdapter`。
- 如果通过聚合平台走 OpenAI-compatible, 要探测它是否真的支持 Claude 的 structured outputs；很多中转只支持 prompt-only 或 json_object。
- Claude 很容易写出解释充分、格式丰富的内容，所以必须强调:
  - 只返回 JSON。
  - `field.value` 只用 MM-MD-v1 白名单。
  - 不写标题内公式。
  - 不写 HTML / 表格。
- 如果 prompt 很长，用 XML tag 把协议、例子、原文分开，减少把规则混入正文。

技术栈:

| 层 | 方案 |
|---|---|
| API | Anthropic Messages API |
| 结构化 | `output_config.format` JSON Schema；必要时 strict tool use |
| Prompt | `<output_contract>` / `<latex_rules>` / `<examples>` |
| Schema | 简化 optional 字段，避免 schema 太复杂 |
| 缓存 | schema 不频繁变化，避免 grammar cache 反复失效 |

推荐 Adapter:

```text
ClaudeAdapter
  supportsJsonSchema=true on native API
  supportsStrictToolUse=true
  needsJsonKeyword=false
  rootJsonObjectOnly=false
  preferredFormulaDelimiters="explicit_mathmind_override"
```

参考:

- [Claude Structured Outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs)
- [Claude prompt engineering best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

### 16.5 Gemini / Google 系列

资料要点:

- Gemini 支持按 JSON Schema 生成结构化输出。
- 官方 SDK 可用 Pydantic / Zod 定义 schema。
- REST/Interactions API 通过 `response_format` 指定 `mime_type: "application/json"` 和 `schema`。
- Gemini structured output 支持 JSON Schema 子集。

MathMind 要注意:

- Gemini 的 API 形状和 OpenAI 不同，原生接入要单独 Adapter。
- 如果使用 Gemini OpenAI compatibility, 仍要 feature probe, 不假设所有参数兼容。
- Gemini 多模态能力强，未来可以参与 OCR/图片理解，但当前 MathMind 已有 OCR 服务，先不要把 OCR 和结构化笔记生成混成一步。
- Gemini 输出字段顺序可能跟 schema 相关，适合固定 `fields` 顺序。

技术栈:

| 层 | 方案 |
|---|---|
| API | Gemini Interactions / generateContent |
| 结构化 | `response_format` + `application/json` + schema |
| Schema 工具 | Web 端可用 Zod；ArkTS 端手写 interface validator |
| 多模态 | 暂不接管 OCR，只作为未来可选 |
| 流式 | 结构化输出流式只做后台，不直接驱动 UI |

推荐 Adapter:

```text
GeminiAdapter
  supportsJsonSchema=true
  supportsJsonObject=true
  needsJsonKeyword=false when schema provided
  preferredFormulaDelimiters="explicit_mathmind_override"
```

参考: [Gemini structured outputs](https://ai.google.dev/gemini-api/docs/structured-output)

### 16.6 DeepSeek 系列

资料要点:

- DeepSeek 官方 JSON Output 使用 `response_format: {"type": "json_object"}`。
- 官方要求 system 或 user prompt 中包含 `json`，并给出期望 JSON 示例。
- 官方提醒合理设置 `max_tokens`, 避免 JSON 中途截断。
- 官方还提示 JSON Output 可能偶发返回空 content。

MathMind 要注意:

- DeepSeek 是当前 MathMind 常见 OpenAI-compatible 后端，适合保留为主路径。
- 它是 JSON object mode，不是 schema strict。字段缺失、字段类型错误、LaTeX 乱写仍可能出现。
- `LlmGuard.callJsonWithRetry()` 对 DeepSeek 是必须项，不是可选项。
- Prompt 必须包含英文或中文 `JSON` 关键词。
- 对空 content 要单独重试，不要直接生成 fallback 笔记。
- 对推理模型或 thinking mode, 如果服务商支持关闭 thinking, 结构化输出阶段优先关闭。

技术栈:

| 层 | 方案 |
|---|---|
| API | OpenAI-compatible Chat Completions |
| 结构化 | `response_format: {"type":"json_object"}` |
| Prompt | JSON 字样 + 完整 JSON 示例 + MM-MD-v1 规则 |
| 本地校验 | `validateAiJson()` 必须严格 |
| 异常 | empty content / truncated JSON / schema mismatch 三类重试 |

推荐 Adapter:

```text
DeepSeekAdapter
  supportsJsonSchema=false
  supportsJsonObject=true
  needsJsonKeyword=true
  supportsThinkingToggle=depends_on_provider
  preferThinkingDisabledForJson=true
  canReturnEmptyJsonContent=true
  jsonCanBeTruncatedByMaxTokens=true
```

参考: [DeepSeek JSON Output](https://api-docs.deepseek.com/guides/json_mode/)

### 16.7 Qwen / 通义千问 / DashScope

资料要点:

- 阿里云 Model Studio 文档说明 Qwen structured output 使用 `response_format: {"type":"json_object"}`，且 system/user 必须包含 `JSON`。
- 文档提示 thinking mode 下个别模型可能返回非严格 JSON；需要稳定 JSON 时可用两步修复。
- 文档建议生产环境仍做 JSON 有效性校验，可用 jsonschema/Ajv/Everit 等工具。
- Qwen Cloud API 也列出 `json_schema` 类型，但需要结合模型支持情况判断。

MathMind 要注意:

- Qwen 适合做中文数学笔记结构化，但 thinking mode 和 JSON 稳定性要分开评估。
- 如果调用 Qwen thinking 模型，建议两阶段:
  1. thinking 模型产出高质量解释草稿。
  2. 非 thinking / JSON 稳定模型把草稿转成 MathMind JSON。
- 如果服务端支持 `json_schema`, 优先试用；不支持则降级 JSON object。
- 对 Qwen2.5 math / coder 等特殊模型不要默认启用 JSON mode, 以实际文档和模型能力 probe 为准。

技术栈:

| 层 | 方案 |
|---|---|
| API | DashScope OpenAI compatible / Qwen Cloud |
| 结构化 | `json_schema` 可用则用；否则 `json_object` |
| Prompt | 必须包含 `JSON` 字样，给字段类型和示例 |
| 模型模式 | 结构化阶段优先 non-thinking |
| 兜底 | thinking 输出 -> JSON 修复模型 -> 本地校验 |

推荐 Adapter:

```text
QwenAdapter
  supportsJsonSchema=feature_probe
  supportsJsonObject=true
  needsJsonKeyword=true
  supportsThinkingToggle=true
  preferThinkingDisabledForJson=true
  jsonCanBeTruncatedByMaxTokens=true
```

参考:

- [Alibaba Cloud Model Studio - Qwen structured output](https://www.alibabacloud.com/help/en/model-studio/qwen-structured-output)
- [Qwen Cloud chat API response_format](https://docs.qwencloud.com/api-reference/chat/dashscope)

### 16.8 Kimi / Moonshot 系列

资料要点:

- Kimi JSON Mode 使用 `response_format: {"type":"json_object"}`。
- 官方建议在 prompt 中定义 JSON 格式、字段名、字段类型，并提供示例。
- Kimi JSON Mode 只生成 JSON Object，不要引导生成根数组。
- 如果 `finish_reason` 为 `length`, JSON 可能被截断。
- Kimi Partial Mode 不要和 `response_format=json_object` 混用。

MathMind 要注意:

- MathMind 的 AI 返回根对象，天然适合 Kimi JSON Object 限制。
- `fields` 可以是根对象里的数组，但根必须是 object。
- 不要用 assistant prefill / partial mode 去强行补 `{`, 容易和 JSON mode 冲突。
- 长笔记场景要估算 token, 防止 `fields[].value` 被截断。

技术栈:

| 层 | 方案 |
|---|---|
| API | Moonshot / Kimi OpenAI-compatible |
| 结构化 | `response_format: {"type":"json_object"}` |
| Prompt | 明确根对象 schema + 字段说明 + 示例 |
| 禁用 | JSON mode 下禁 Partial Mode |
| 错误 | `finish_reason=length` 直接重试增大 max_tokens |

推荐 Adapter:

```text
KimiAdapter
  supportsJsonSchema=false_or_feature_probe
  supportsJsonObject=true
  needsJsonKeyword=false_but_prompt_required
  rootJsonObjectOnly=true
  jsonCanBeTruncatedByMaxTokens=true
```

参考: [Kimi API JSON Mode](https://platform.kimi.ai/docs/guide/use-json-mode-feature-of-kimi-api)

### 16.9 GLM / 智谱系列

资料要点:

- 智谱文档提供结构化输出 JSON 模式，核心参数是 `response_format: {"type":"json_object"}`。
- 文档示例仍强调本地 `json.loads` 后用 JSON Schema 校验。
- GLM 文档中部分模型说明支持结构化输出。

MathMind 要注意:

- GLM 可按 JSON object 接入，不应假设 schema strict。
- 中文输出能力强，但字段 label 可能更自由，要强制字段 key/label 白名单。
- 本地 `normalizeNoteType()`、`normalizeFields()` 仍然必需。

技术栈:

| 层 | 方案 |
|---|---|
| API | Zhipu / GLM chat completions |
| 结构化 | JSON object |
| 本地校验 | 手写 ArkTS validator + JSON Schema 思路 |
| Prompt | 强制 category 枚举和 fields 全量字段 |

推荐 Adapter:

```text
GlmAdapter
  supportsJsonSchema=feature_probe
  supportsJsonObject=true
  needsJsonKeyword=false_but_recommended
  preferThinkingDisabledForJson=true
```

参考: [智谱 AI 结构化输出](https://docs.bigmodel.cn/cn/guide/capabilities/struct-output)

### 16.10 Hunyuan / 腾讯混元 TokenHub

资料要点:

- 腾讯 TokenHub `hy3` 文档显示兼容 OpenAI Chat Completions / Responses / Anthropic Messages 协议。
- 文档给出 `response_format: { type: "json_schema", json_schema: ... }` 的结构化输出示例。
- 腾讯 TokenHub 的 DeepSeek 调用指南中，JSON mode 示例使用 `response_format: {"type":"json_object"}`，并显式设置 `thinking: {"type":"disabled"}`。

MathMind 要注意:

- Hunyuan 自身适合走 `json_schema`。
- TokenHub 代理其他模型时，capability 要按模型而不是按平台判断。
- 如果是 DeepSeek via TokenHub, 走 DeepSeekAdapter + TokenHub transport，不走 HunyuanAdapter。

技术栈:

| 层 | 方案 |
|---|---|
| API | TokenHub OpenAI-compatible |
| Hunyuan | `json_schema` |
| DeepSeek via TokenHub | `json_object` + thinking disabled |
| Adapter | transport 和 model capability 拆开 |

推荐 Adapter:

```text
HunyuanAdapter
  supportsJsonSchema=true
  supportsJsonObject=true
  needsJsonKeyword=false for json_schema
  supportsThinkingToggle=when_model_exposes_it
```

参考:

- [Tencent TokenHub Hunyuan structured output](https://intl.cloud.tencent.com/zh/document/product/1300/80695)
- [Tencent TokenHub DeepSeek JSON mode](https://intl.cloud.tencent.com/zh/document/product/1300/80633)

### 16.11 Baidu Qianfan / 千帆

资料要点:

- 千帆文档说明 `response_format` 支持 `text / json_object / json_schema`。
- `json_schema` 只支持部分模型。
- `json_object` 只保证 JSON 对象语法，不能保证符合业务 schema。

MathMind 要注意:

- 接入千帆时应先读取模型列表/能力元数据，判断是否支持 `json_schema`。
- 千帆承载很多开源模型，不能按平台统一判断模型行为。
- DeepSeek / Qwen via Qianfan 要复用对应 model profile。

技术栈:

| 层 | 方案 |
|---|---|
| API | Qianfan OpenAI-compatible |
| 结构化 | `json_schema` 优先，否则 `json_object` |
| 能力探测 | 模型元数据或一次低成本 schema smoke call |
| 本地校验 | 必须 |

推荐 Adapter:

```text
QianfanAdapter
  supportsJsonSchema=feature_probe
  supportsJsonObject=true
  needsJsonKeyword=provider_or_model_dependent
```

参考: [Baidu Qianfan Structured Output](https://intl.cloud.baidu.com/en/doc/qianfan/s/6m8r1x5hz-intl-en)

### 16.12 xAI / Grok

资料要点:

- xAI 文档支持 `response_format` 的 `json_schema`、`json_object` 和 `text`。
- SDK 可把 Pydantic model 转成 JSON Schema。

MathMind 要注意:

- 当前不是 MathMind 主路径，但如果后续走 OpenAI-compatible, 可按 A 档 schema strict 接。
- Grok 风格可能更发散，依旧要用 MM-MD-v1 prompt 和本地公式校验。

技术栈:

| 层 | 方案 |
|---|---|
| API | xAI OpenAI-compatible |
| 结构化 | `json_schema` |
| 本地校验 | 仍保留 |

参考: [xAI Structured Outputs](https://docs.x.ai/developers/model-capabilities/text/structured-outputs)

---

## 17. 可执行实施 Plan

### Phase 1: 模型能力抽象

新增:

```text
common/src/main/ets/llm/ProviderCapabilities.ets
common/src/main/ets/llm/ProviderAdapter.ets
common/src/main/ets/llm/ModelProfile.ets
```

任务:

1. 给当前配置里的模型加 `providerId`。
2. 增加 `capabilitiesFor(modelId, baseUrl)`。
3. `LlmClient` 调用前根据 capabilities 注入 `response_format`。
4. 如果 provider 不支持结构化输出，明确降级到 prompt-only + strict local validation。

验收:/


- DeepSeek 路径能自动带 `json_object` 和 JSON prompt。
- OpenAI/Gemini/Claude/Hunyuan 支持 schema 时能走 schema path。
- 不支持 schema 时不会误发不兼容参数。

### Phase 2: 统一 JSON Schema / 本地 validator

新增:

```text
agents/src/main/ets/agents/KnowledgeDraftValidator.ets
common/src/main/ets/render/ContentProtocol.ets
```

任务:

1. 把 `KnowledgeModel.validateAiJson()` 拆成独立 validator。
2. 校验 `category / subject / title / tags / difficulty / importance / fields`。
3. 校验每个 `field.value` 是否符合 MM-MD-v1。
4. 输出 `issues` 和 `fixes`, 给 LlmGuard retry 使用。

验收:

- AI 输出合法 JSON 但公式块写错时会触发 retry。
- AI 输出标题含 `$...$` 会触发 retry。
- AI 输出表格/HTML 会触发 retry 或剥离。

### Phase 3: Prompt Contract Builder

新增:

```text
common/src/main/ets/llm/PromptContractBuilder.ets
```

任务:

1. 将 `JSON_ONLY_RULES`、`LATEX_GENERATION_RULES`、`MM_MD_V1_RULES` 拆成可组合规则。
2. 针对 Claude 使用 XML tag 版本。
3. 针对 DeepSeek/Qwen/Kimi 使用 JSON keyword + 示例版本。
4. 针对 schema strict 模型减少冗余，但保留 LaTeX 规则。

验收:

- 同一业务 schema, 不同模型 prompt 不再复制粘贴。
- Prompt 中始终有行内公式/块级公式正反例。

### Phase 4: 渲染协议入口

新增:

```text
common/src/main/ets/render/RenderBlock.ets
common/src/main/ets/render/MarkdownBlockParser.ets
common/src/main/ets/render/LatexBoundaryValidator.ets
```

任务:

1. `MarkdownParser` 迁移到 common 或共享协议层。
2. 公式边界判断只保留一份。
3. `MarkdownRenderer` 消费 `RenderBlock[]`。
4. `MathTextRenderer` 不再猜整篇 Markdown, 只处理已确认的数学段落/块。

验收:

- 代码块内 `\int` 不渲染。
- 句子中 `$$...$$` 被拒绝。
- 公式块出错不影响其他 block。

### Phase 5: 模型回归测试集

新增目录:

```text
docs/render-contract-fixtures/
```

建议文件:

```text
openai_good_formula.json
claude_verbose_markdown_bad.json
deepseek_empty_content_case.json
qwen_thinking_non_json_case.json
kimi_root_array_bad.json
glm_label_formula_bad.json
hunyuan_json_schema_good.json
```

任务:

1. 每个 fixture 保存 raw model output、expected normalized content、expected issues。
2. 每个 provider 至少 5 条失败样例。
3. 把 `LatexRiskNormalizer.test.ets` 扩展到 ContentProtocol。

验收:

- 每个模型至少覆盖: 裸公式、嵌套美元、标题公式、长公式在列表、JSON 缺字段。

---

## 18. KaTeX GitHub 资源包对 MathMind 的帮助

用户给出的仓库:

- [KaTeX/KaTeX GitHub](https://github.com/KaTeX/KaTeX)

结论:

> 有帮助，但它解决的是“数学公式渲染引擎与资源包治理”，不解决 AI 输出协议问题。AI 输出仍然必须先被 MM-MD-v1 约束和校验。

### 18.1 当前本地资源状态

当前本地目录:

```text
entry/src/main/resources/rawfile/katex/
```

现状:

| 项 | 当前值 |
|---|---|
| 本地 KaTeX 版本 | `0.16.9` |
| 当前最新 GitHub release | `v0.18.1` (2026-07-19) |
| 本地资源 | `katex.min.js`, `katex.min.css`, `auto-render.min.js`, `marked.min.js`, `fonts/` |
| 本地资源总大小 | 约 603 KB |
| 当前 render.html | 先 `marked.parse()`, 再 `renderMathInElement()` |

说明:

- GitHub README 显示 KaTeX 是无依赖、自包含、支持同步渲染的 Web TeX 渲染库。
- KaTeX 支持很多但不是全部 LaTeX。
- GitHub release 提供预构建 `katex.tar.gz` / `katex.zip`；不要下载自动生成的 Source code 当静态资源包，因为里面没有构建好的 dist 文件。
- CSS 和 `fonts/` 必须保持相对路径，否则公式字体会坏。

参考:

- [KaTeX GitHub README](https://github.com/KaTeX/KaTeX)
- [KaTeX Browser installation](https://katex.org/docs/browser)
- [KaTeX Supported Functions](https://katex.org/docs/supported.html)

### 18.2 对 render.html 的直接建议

目标 `render.html`:

```text
marked.parse(canonicalMarkdown)
  -> renderMathInElement(contentEl, delimiters...)
```

职责必须保持单一:

- `render.html` 只处理一个数学段落或一个公式块。
- 不保留 `normalizeBareMath()` 一类猜测逻辑，旧内容也先经过 ArkTS `ContentProtocol`。
- 主协议判断迁移到 ArkTS `ContentProtocol`。
- `renderMathInElement` 的 delimiter 顺序保持 `$$` 在 `$` 前面。
- `ignoredTags` 使用默认值或显式声明 `pre/code` 等，避免代码块公式误渲染。
- KaTeX `throwOnError:false` 可以保留，但 ArkUI 外层仍要显示原始公式 fallback。

建议显式配置:

```js
renderMathInElement(contentEl, {
  delimiters: [
    { left: '$$', right: '$$', display: true },
    { left: '\\[', right: '\\]', display: true },
    { left: '\\(', right: '\\)', display: false },
    { left: '$', right: '$', display: false }
  ],
  ignoredTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code', 'option'],
  throwOnError: false,
  strict: 'warn',
  trust: false,
  maxExpand: 1000
});
```

### 18.3 是否升级 KaTeX

建议不要顺手升级，单独开任务:

```text
task: chore(render): upgrade bundled KaTeX from 0.16.9 to 0.18.1
```

升级步骤:

1. 从 GitHub release 下载预构建 `katex.zip` / `katex.tar.gz`, 或从 `npm install katex@0.18.1` 的 `node_modules/katex/dist/` 复制。
2. 替换 `entry/src/main/resources/rawfile/katex/` 里的:
   - `katex.min.js`
   - `katex.min.css`
   - `auto-render.min.js`
   - `fonts/`
3. 保持 `fonts/` 与 CSS 的相对路径。
4. 记录版本到文档或资源目录 README。
5. 用公式 fixture 验证:
   - inline `$x>0$`
   - display `$$...$$`
   - `aligned`
   - `cases`
   - `matrix`
   - 中文 `\text{}` 或 CJK fallback
   - unsupported command fallback
6. DevEco 真机打开 Notes 详情，检查 WebView 不空白。

升级风险:

- CSS/font 相对路径变动导致字体丢失。
- KaTeX 支持/严格模式差异导致之前可显示的边缘公式变成错误。
- minified bundle 体积变化影响 rawfile 加载。
- `marked` 版本与 KaTeX 无关，不要混在同一个升级任务里。

### 18.4 KaTeX 支持范围要写进 AI 规则

根据 KaTeX supported functions, MathMind prompt 应避免让 AI 输出:

- 自定义宏 `\newcommand`
- 高风险 HTML 扩展 `\htmlId`, `\htmlClass`, `\htmlStyle`, `\includegraphics`
- 未验证包命令
- 复杂 LaTeX 文档环境
- 表格类 LaTeX 代替 Markdown 表格

推荐允许:

- 基础符号、上下标、分式、根号、积分、求和、极限。
- `matrix / pmatrix / bmatrix / cases`。
- `aligned` 多行推导。
- `\text{短中文说明}` 只限短文本。

### 18.5 KaTeX 在本项目中的定位

最终定位:

```text
KaTeX = formula compiler
marked = WebView 内部 Markdown-to-HTML helper
ArkUI = app UI host
ContentProtocol = actual source of truth
```

也就是说:

- KaTeX 不负责判断一段内容是不是公式。
- KaTeX 不负责修 AI 输出。
- KaTeX 不负责 Markdown 安全边界。
- KaTeX 只负责把已经确认安全的 TeX string 编译成 HTML。

这条边界必须写进后续实现任务，否则公式失败会继续在 AI prompt、Markdown parser、WebView 三层来回漂移。

---

## 19. 2026-07-22 首轮实施记录

本轮按本文协议完成了第一阶段代码落地，未升级 KaTeX 资源版本。

### 19.1 已完成

| 层级 | 文件 | 已落地行为 |
|---|---|---|
| 协议层 | `common/src/main/ets/render/ContentProtocol.ets` | MM-MD-v1 换行、定界符、公式块边界、已知拼写归一；公式、HTML、环境和危险宏校验 |
| 风险层 | `common/src/main/ets/utils/LatexRiskNormalizer.ets` | display 状态机；不再给 `$$` 内部公式二次套 fence；代码块不参与公式括号检查 |
| AI 层 | `common/src/main/ets/llm/LlmOutputRules.ets` | 统一行内/块级公式、标题、标签、列表、aligned 与不确定 OCR 规则 |
| AI 校验 | `agents/src/main/ets/agents/KnowledgeModel.ets` | 标题、标签、key、label 禁止公式；field.value 违反 MM-MD-v1 时进入 LlmGuard 重试 |
| 入库构造 | `KnowledgeModel.contentFromFields()` | 字段和合并正文入库前统一归一化 |
| Markdown | `entry/src/main/ets/utils/MarkdownParser.ets` | 先过 ContentProtocol；未闭合 display 在 EOF 按普通文本处理 |
| 兼容解析 | `entry/src/main/ets/utils/MathTextParser.ets` | 删除裸公式猜测；高风险内容整段文本兜底 |
| ArkUI 分流 | `MarkdownRenderer.ets`、`MathPreviewText.ets`、`ChatBubble.ets` | 全部使用同一个 `ContentProtocol.hasFormulaSyntax()` |
| 数学 UI | `entry/src/main/ets/shared/components/MathTextRenderer.ets` | 协议失败直接 ArkUI Text；WebView JS 失败回退原文；长对话上限放宽 |
| WebView | `entry/src/main/resources/rawfile/render.html` | 固定 `marked.parse -> renderMathInElement`；删除裸公式猜测；禁 trust；限制宏展开 |
| 聊天气泡 | `ChatBubble.ets`、`AgentChatService.ets` | 公式回复整条交给单个 marked + KaTeX WebView；纯 Markdown 走 ArkUI 原生渲染；显示和入库共用一次协议归一化 |

### 19.2 已修复的关键根因

1. `KnowledgeModel` Prompt 示例中的 `\frac`、`\pm`、`\sqrt` 已按 TypeScript 字符串规则正确转义，避免 Prompt 内出现控制字符或丢失反斜杠。
2. `LatexRiskNormalizer` 不再把规范公式块内部的 `\frac` 行再次包装成 `$$...$$`。
3. 未闭合 `$`、未闭合 `$$`、括号不平衡、`\left/\right` 不匹配、环境不匹配和危险宏不会进入 KaTeX。
4. 代码块中的 LaTeX 和花括号不会触发公式编译或整段降级。
5. `\leftarrow` 不会再被误认成 `\left` 命令；已规范的 `\,dx` 不会被重复插入反斜杠。
6. WebView 不再重复修改 ArkTS 已确认的 Markdown，避免 ArkTS 与 JavaScript 得到两份不同正文。
7. AI 在 JSON 中漏写双反斜杠造成的 form-feed、tab 等控制字符会被本地校验拦截并重试。
8. `LatexRiskNormalizer.wrapBareShortSymbols()` 原来会进入已经由 `$...$` 定界的公式，把 `$[\mu-\sigma,\mu+\sigma]$` 破坏成 `$[$\mu$-$\sigma$,$\mu$+$\sigma$]$`；现在只处理公式边界之外的兼容裸符号。
9. `ChatBubble` 原来只有“含公式走 `MathTextRenderer`、其余直接 `Text`”两条路径，所以 Markdown-only 回复的标题、列表、加粗和代码从未进入 Markdown 渲染器；现在无公式 AI 回复使用 chat profile 的 `MarkdownRenderer`。
10. 聊天回复原来直接显示并保存模型原文，导致即时 UI、历史记录和渲染器归一化结果可能不一致；现在 `AgentChatService.addAiMessage()` 在显示和入库前统一执行 MM-MD-v1 归一化，高风险内容仍保留原文兜底。

### 19.3 AI 气泡专项渲染决策

```text
assistant content
  -> AgentChatService / ContentProtocol normalize once
  -> save the same display content
  -> ChatBubble
       ├─ has formula -> one MathTextRenderer WebView
       │                  -> marked.parse
       │                  -> KaTeX auto-render
       └─ no formula  -> MarkdownRenderer(chat)
                          -> native ArkUI blocks/spans
```

这个分流同时满足两个目标:

- 含公式的整条回复只创建一个 WebView，避免列表中每个公式项各建一个 ArkWeb 实例。
- 不含公式的标题、段落、列表、加粗和行内代码由 ArkUI 原生组件渲染，不为每条历史消息支付 WebView 成本。

公式失败时不允许空白。协议或 LaTeX 风险检查判定为高风险时，`MathTextRenderer` 回退为原始文本；WebView JavaScript 调用失败时也切回原文。这个兜底会牺牲该条消息的富文本样式，但保留完整内容，后续可在 P2 阶段升级为“仅错误公式段回退”。

### 19.4 测试与验证状态

已新增或扩展纯逻辑用例:

- 短行内公式。
- 句中 display 自动拆块。
- 未闭合 inline/display 纯文本兜底。
- 代码块不解析公式。
- 危险宏兜底。
- display fence 不嵌套。
- `\,dx` 和 `\leftarrow` 不误修。
- JSON 反斜杠错误形成的控制字符。
- LaTeX 环境名称不匹配。
- 公式内原始 HTML。
- 真实正态分布回复，覆盖 `\mu`、`\sigma`、`\Phi`、`\operatorname`、展示公式和行内公式。
- Markdown-only 聊天回复，覆盖标题、加粗、行内代码、无序列表和有序列表。

已执行静态检查:

- `git diff --check` 无 whitespace error。
- 新文件为 UTF-8 no BOM。
- 本轮新增代码未引入 `any`、`unknown`、C 风格 `for`、API 11+ ArkUI 调用。
- DevEco 内置 TypeScript 对 `ContentProtocol`、`LatexRiskNormalizer` 的 strict 类型诊断通过。
- 协议状态机关键路径可执行断言通过。
- 本地 KaTeX 对分式、积分、aligned、cases、箭头、中文 `\text{}` 编译通过。
- marked 保留公式定界符，`render.html` JavaScript 语法检查通过。
- KaTeX CSS 引用的 20 个首选 `woff2` 字体全部存在；未打包的 `woff/ttf` 是 CSS 次级兼容源。
- 模拟器 `chat_message` 表中真实正态分布回复已回放，最终为 `protocol=fixable`、`latex=none`、`renderMode=katex`，不再进入 `plainFallback`。

按项目约束不使用 `hvigorw`。最终编译与 UI 验证由 DevEco Studio GUI 执行:

1. `File -> Sync and Refresh Project`。
2. `Build -> Build Hap(s)/APP(s)`。
3. 确认 `common`、`agents`、`entry` 的 `CompileArkTS` 均成功。
4. 真机打开含行内公式、长 display、aligned、错误公式和代码块的笔记。
5. 验证错误公式显示原文且不空白，长公式可横向滚动，其他段落不受影响。

---

## 20. 笔记列表摘要专项优化

### 20.1 已确认根因

旧链路在 `NoteItemMapper` 中直接执行 `stripMD(summary, 80)`。这个函数按字符位置硬截断，不理解 MM-MD-v1 边界，因此可能把 `$...$`、`$$...$$`、`\frac{...}` 或 `\left...\right` 截成半段。随后 `MathPreviewText` 收到的已经是损坏公式，只能回退为原始小字。

同时，每张 `NoteCard` 默认展示两行、最多 80 字。数学笔记通常在摘要开头就包含长公式，这会让列表重复展示详情内容，并为多个可见卡片创建长公式 WebView。

### 20.2 新策略

```text
KnowledgeUnit.summary/content
  -> ContentExcerptBuilder
       ├─ 普通文字: 语义边界截断
       ├─ 短 inline 公式: 完整保留 delimiter
       ├─ 长 inline 公式: 替换为“相应公式”
       ├─ 短 display 公式: 完整保留
       └─ 长 display 公式: 折叠为“核心公式”
  -> NoteCard: 46 字预算 + 单行
  -> MathPreviewText
       ├─ 无公式: ArkUI Text + ellipsis
       └─ 有完整短公式: preview WebView + KaTeX
```

关键约束:

- 绝不为了满足字符上限而切断公式。
- 列表用于扫描，不承担长公式阅读；完整公式只在详情页展示。
- `render.html` 的 preview profile 强制单行和 `text-overflow: ellipsis`。
- 未来生成笔记的 `summary` 约 220 字且为纯文字语义概览，完整公式、推导和原文只存入 `content`。
- 旧数据库无需迁移；读取时由 `ContentExcerptBuilder` 动态生成安全预览。

### 20.3 验证结果

- 模拟器 3 条现有笔记全部回放成功，没有协议 fallback。
- 列表预览中的 3 个短公式均通过本地 KaTeX 0.16.9 编译。
- 1 个超长正态分布密度公式被安全折叠，没有残缺 `\frac` 或未闭合 `$`。
- 新摘要构造结果不含公式源码，长度从旧上限 500 降到约 220。
- 新增测试覆盖长 inline、短 inline、短 display、长 display、纯文字摘要和幂等预览。
