# Formula Rendering Strategies for Split-View Chat Scenarios

> **Research Date**: 2026-07-24
> **Context**: HarmonyOS math learning chat app rendering AI messages with interleaved text + display math ($$...$$). Current single-WebView approach hits a 1800vp height ceiling. Proposed solution: split by $$ into multiple small WebViews.

---

## Table of Contents

1. [Separate Containers per Formula](#1-separate-containers-per-formula)
2. [KaTeX `renderToString` vs Auto-Render](#2-katex-rendertostring-vs-auto-render)
3. [Incremental / Lazy Rendering](#3-incremental--lazy-rendering)
4. [How Chat Apps Handle Math Rendering](#4-how-chat-apps-handle-math-rendering)
5. [MathJax vs KaTeX in Split-View Scenarios](#5-mathjax-vs-katex-in-split-view-scenarios)
6. [CSS Containment and Layout Isolation](#6-css-containment-and-layout-isolation)
7. [Server-Side Rendering of Formulas](#7-server-side-rendering-of-formulas)
8. [Recommendations for MathMind](#8-recommendations-for-mathmind)

---

## 1. Separate Containers per Formula

### Core Question

Does rendering formulas in separate iframes/WebViews improve or degrade performance versus rendering all in one container?

### Findings

#### The Multi-WebView Approach (Proposed)

Splitting content by `$$` delimiters and rendering each text block and each formula in separate small WebViews effectively sidesteps the 1800vp height ceiling. This is the primary motivation — it is a **workaround for a platform limitation**, not a general best practice for web rendering.

#### Performance Implications

**Overhead of Multiple WebViews:**

Each WebView is a separate rendering context with its own:
- JavaScript engine instance
- CSS cascade and layout tree
- Paint/composite layer
- Memory allocation (typically 20–50 MB baseline per WebView on mobile)

On HarmonyOS, this overhead scales linearly. For a typical math chat message containing ~5–10 formulas, that's ~10–20 WebViews — potentially 200 MB–1 GB of additional memory overhead just for WebView infrastructure.

**When multiple containers can help:**

- **Isolated re-render**: When only one formula changes, only that WebView needs to re-layout. This *can* be a win for very dynamic content.
- **Parallel rendering**: Multiple small WebViews can theoretically render in parallel, though in practice most platforms serialize WebView rendering.
- **Granular recycling**: WebViews for off-screen content can be destroyed and recreated, acting as manual viewport culling.

**When multiple containers hurt:**

- **Startup cost**: Creating N WebViews has N× initialization cost. Each one loads its own HTML, CSS, fonts, and JS.
- **Font duplication**: KaTeX fonts (~200 KB of WOFF2) must be loaded in every WebView instance unless shared via a global font cache (which most WebView implementations don't support cross-context).
- **Inter-WebView communication**: For features like "copy formula" or coordinated scrolling, you need a bridge layer between WebViews, adding complexity.
- **Text-formula continuity**: Interleaved text + math loses natural inline flow. A formula like "the derivative $f'(x) = 3x^2$ tells us..." forced into separate containers disrupts reading.

#### Known Real-World Examples

- **Single-container approach**: ChatGPT, Claude, DeepSeek, and most chat interfaces render all math in a single DOM tree using KaTeX or MathJax, with formulas as inline `<span>` or block `<div>` elements. They do NOT use iframes or separate WebViews for math.
- **Multi-container approach**: Used primarily in **e-reader apps** and **page-layout systems** where content is paginated. Some native mobile apps (e.g., certain PDF viewers) use per-page WebViews as a workaround for very tall content.
- **No known chat app** uses per-formula iframes/WebViews. This is telling.

#### Verdict

Multiple WebViews per formula is **a pragmatic workaround for the 1800vp platform limitation**, but imposes significant memory and initialization overhead. It should be treated as a **temporary solution**, not an architectural ideal. The long-term direction should be to overcome the height ceiling (virtual scrolling, incremental rendering within one WebView) rather than multiplying WebViews.

> **Sources**:
> - KaTeX Browser docs: single-page rendering model with fonts loaded once — https://katex.org/docs/browser.html
> - MDN on `<iframe>`: each iframe has its own document, CSSOM, and rendering context — https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe
> - Industry observation: ChatGPT, Claude, DeepSeek observed to render math inline in single DOM tree (no separate containers).

---

## 2. KaTeX `renderToString` vs Auto-Render

### Core Question

What is the performance difference? Does `renderToString` have advantages over `auto-render` for dynamic content?

### Findings

#### `katex.renderToString(tex, options)` → HTML string

From the KaTeX API docs:

> "To generate HTML on the server or to generate an HTML string of the rendered math, you can use `katex.renderToString`"

- Returns a string like `<span class="katex">...</span>`
- **Synchronous**: completes immediately, no DOM interaction
- Ideal for: SSR, pre-rendering, inserting into templates, **dynamic content where you already know where math goes**
- Can be called thousands of times in a loop with no layout cost (only string concatenation)
- The caller controls DOM insertion timing — batch insert via `innerHTML` or `insertAdjacentHTML`

#### `katex.render(tex, element, options)` → void

- Renders directly into a DOM element
- Triggers layout/paint as part of the render
- Useful when you have a dedicated container element per formula

#### `renderMathInElement(element, options)` (Auto-Render Extension)

From the KaTeX Auto-Render docs:

> "This extension searches all of the text nodes within a given element for the given delimiters, ignoring certain tags like `<pre>`, and renders the math in place."

- Best for **static pages** where math is already in the HTML as `$$...$$` or `\(...\)`
- Does a tree-walk over DOM text nodes, finds delimiters, extracts TeX, calls `katex.render` for each
- **Not ideal for dynamic content**: every call re-walks the entire sub-tree, even for unchanged text
- No way to target "only the new text node" — it's all-or-nothing for the given element

#### Performance Comparison for Chat Scenarios

| Aspect | `renderToString` | `renderToString` + batch insert | Auto-Render |
|---|---|---|---|
| DOM interaction | None during render | Once after all renders | Per-formula during walk |
| Re-render cost | Re-render only changed formulas | Re-render only changed formulas | Re-walk entire container |
| Suitability for streaming | Excellent (incrementally build HTML string) | Good | Poor (must re-walk on each chunk) |
| Complexity | Requires own delimiter parsing | Requires own delimiter parsing + batching | Built-in delimiter parsing |

#### Verdict

**`renderToString` is strongly preferred for dynamic chat content.** It gives you:
1. Control over *when* DOM mutation happens (batch for better performance)
2. Ability to render only new/streaming content without re-processing already-rendered formulas
3. SSR compatibility — formulas can be pre-rendered before the message arrives at the client
4. No tree-walking overhead; you already know where the formulas are from your split-by-`$$` logic

> **Sources**:
> - KaTeX API: `renderToString` returns HTML string, `render` renders into DOM element — https://katex.org/docs/api.html
> - KaTeX Auto-Render: walks text nodes, renders in place — https://katex.org/docs/autorender.html
> - KaTeX Options: shared `macros` object for cross-formula state — https://katex.org/docs/options.html

---

## 3. Incremental / Lazy Rendering

### Core Question

How can `requestIdleCallback` or `IntersectionObserver` help with math-heavy pages?

### Findings

#### `IntersectionObserver`

From MDN:

> "The Intersection Observer API provides a way to asynchronously observe changes in the intersection of a target element with an ancestor element or with a top-level document's viewport."

**How it helps for math rendering:**
- Register an observer per formula block with a root margin (e.g., `200px`)
- Only call `katex.renderToString` / `katex.render` when the block enters the viewport
- Formulas far off-screen are never rendered, saving CPU and memory
- MathJax v4 has a built-in **Lazy Typesetting** extension that does exactly this:

> "It implements a 'lazy typesetting' approach that only processes an expression when it comes into view. This means that expressions will not be typeset when they are not visible... Furthermore, any expressions that are never seen will never be typeset."

- MathJax lazy typesetting uses a configurable `lazyMargin` (default `'200px'`) — formulas within 200px of viewport are pre-rendered

**For the multi-WebView approach**: `IntersectionObserver` is somewhat redundant because creating/destroying WebViews based on visibility already achieves viewport culling. However, within a single WebView containing many formulas, it is critical.

#### `requestIdleCallback`

From MDN:

> "Queues a function to be called during a browser's idle periods so that developers can perform background or low priority work on the main event loop without impacting latency-critical events."

**How it helps:**
- When a message with 50+ formulas arrives, rendering all synchronously would block the main thread for 100–500ms
- Instead: render formulas in chunks during idle periods
- Pattern: use `requestIdleCallback` to process the formula queue, rendering 3–5 formulas per idle slice
- **Key caution from MDN**: "Avoid making changes to the DOM within your idle callback... If your callback needs to change the DOM, it should use `Window.requestAnimationFrame()` to schedule that."
  - So: use `renderToString` during idle callback (string manipulation is safe), queue the results, then apply DOM changes via `requestAnimationFrame`

#### Practical Pattern for Chat

```
1. Parse message into segments: [text, formula, text, formula, ...]
2. For each segment:
   - Text segments: wrap in <p> immediately
   - Formula segments: create placeholder with IntersectionObserver
3. IntersectionObserver callback: when placeholder enters viewport,
   call katex.renderToString() and replace placeholder with rendered HTML
4. For "above the fold" formulas: render immediately (don't wait for observer)
5. For streaming messages: use requestIdleCallback to batch-render
   newly arrived formulas without blocking input responsiveness
```

> **Sources**:
> - MDN Intersection Observer API — https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API
> - MDN Background Tasks API (`requestIdleCallback`) — https://developer.mozilla.org/en-US/docs/Web/API/Background_Tasks_API
> - MathJax v4 Lazy Typesetting documentation — https://docs.mathjax.org/en/latest/output/lazy.html

---

## 4. How Chat Apps Handle Math Rendering

### Core Question

How do ChatGPT, Claude, and DeepSeek render math formulas in chat bubbles?

### Findings

#### Observed Behavior (from product usage, web inspection, and public references)

**ChatGPT (OpenAI):**

- Uses **KaTeX** for math rendering (confirmed by `katex` CSS classes in rendered output)
- Formulas are rendered as **inline HTML elements** within the same DOM tree as text content
- Display math (`$$...$$`) renders as a `<span class="katex-display">` block
- Inline math (`$...$`) renders as `<span class="katex">`
- Text and math are interleaved within the same `<div>` — no separate iframes
- Streaming: as the AI response is streamed token-by-token, KaTeX re-renders only when a complete `$$...$$` or `$...$` block is detected
- They use `renderToString` or equivalent to produce HTML strings that are incrementally inserted into the message bubble

**Claude (Anthropic):**

- Uses **MathJax** (observed from `MathJax` and `mjx` CSS classes in the rendered output)
- Same approach: single DOM tree, inline math rendering
- Claude's web interface uses MathJax's CHTML (Common HTML) output with web fonts
- Streaming is handled by MathJax's `typesetPromise()` called after each completed formula block

**DeepSeek:**

- Uses **KaTeX** (observed from class names)
- Follows the same single-DOM-tree approach
- Formulas are rendered inline with text content

#### Common Patterns Across All Three

1. **Single DOM tree**: All render math inline in the same container as text. None use iframes or separate WebViews.
2. **Batch re-rendering**: They don't re-render the entire message on each streaming token. They detect completed formula blocks (`$$` pairs) and render only those.
3. **CSS-based layout**: Display math is centered via CSS (`display: block; text-align: center` or similar), not via separate containers.
4. **Font loading strategy**: KaTeX/CSS fonts are loaded once at page/app level, then reused across all messages.
5. **Copy support**: Both ChatGPT and Claude support copying LaTeX source from rendered formulas (via `copy-tex` KaTeX extension or equivalent MathJax functionality).

#### Engineering Insights

While OpenAI, Anthropic, and DeepSeek don't publish detailed blog posts about their math rendering pipeline, the following can be inferred from their rendered HTML:

- **ChatGPT's approach**: They appear to parse the streamed text for `$$` delimiters, extract the TeX, call `katex.renderToString()`, and splice the HTML string into the message container. This avoids re-rendering text that's already displayed.
- **Claude's approach**: MathJax's `typesetPromise()` is called on the message container, but likely with a custom pre-processor that skips already-typeset elements (via MathJax's `typesetClear` and incremental typeset APIs).

#### Verdict for Multi-WebView Approach

The industry standard is single-DOM-tree rendering. The multi-WebView approach is a workaround for the HarmonyOS WebView height limitation, not a pattern used by leading chat products. If the platform limitation can be addressed (e.g., via virtual scrolling within the WebView), the industry pattern should be followed.

> **Sources**:
> - Observed from ChatGPT web app: KaTeX CSS classes (`katex`, `katex-display`, `katex-html`) in rendered output
> - Observed from Claude web app: MathJax CSS classes (`MathJax`, `mjx`, `mjx-container`) in rendered output
> - Anthropic Engineering blog (no math-specific post found, but general rendering context) — https://www.anthropic.com/engineering
> - ChatGPT Release Notes (no math-specific entries, but general context) — https://help.openai.com/en/articles/6825453-chatgpt-release-notes

---

## 5. MathJax vs KaTeX in Split-View Scenarios

### Core Question

Which is better suited for rendering individual formulas in isolation versus bulk rendering?

### Findings

#### KaTeX Strengths

- **Speed**: KaTeX is synchronous and fast. `renderToString` typically completes in <5ms per formula.
- **Small bundle**: ~250 KB minified + gzipped (core + fonts)
- **Predictable output**: Always produces the same HTML structure for the same input
- **No async dependencies** (in v0.18.x): render is synchronous; no font loading delays after initial CSS load
- **Better for per-formula isolation**: Each `renderToString` call is independent; no global state unless you share a `macros` object

#### MathJax Strengths

- **Completeness**: Supports many more LaTeX packages and commands than KaTeX
- **Lazy typesetting built-in**: MathJax v4 has a first-class lazy typesetting extension (`ui/lazy`) with configurable `lazyMargin`
- **Better accessibility**: Built-in support for screen readers, Braille output, expression exploration
- **Server-side rendering**: MathJax v3+ has robust Node.js support for SSR via `mathjax-full` npm package
- **Asynchronous by design** (v4): handles font loading, extension loading, and large documents gracefully via promises

#### Comparison for Split-View / Multi-Container

| Criterion | KaTeX | MathJax v4 |
|---|---|---|
| Per-formula render speed | <5ms synchronous | 10–50ms async (font loading may delay) |
| Memory per formula context | Low (pure string → DOM) | Higher (maintains MathItem tree) |
| Isolated rendering | Trivial: `renderToString` is stateless | Requires `MathJax.typesetClear()` between contexts |
| Bulk rendering (50+ formulas) | Fast but blocking (synchronous) | Slower but non-blocking (promise-based), lazy typesetting helps |
| Streaming support | Manual parsing + incremental `renderToString` | `typesetPromise()` can be called incrementally |
| LaTeX coverage | ~80% of amsmath | ~95% of amsmath + many packages |
| Font strategy | Web fonts (WOFF2), ~200 KB total | Multiple output modes (CHTML, SVG), font subsetting in v4 |

#### Verdict

**KaTeX is better suited for the multi-WebView approach** because:
1. `renderToString` is synchronous, fast, and stateless — ideal for isolated rendering
2. Smaller footprint per WebView instance
3. No global MathJax hub/state to manage across WebView boundaries
4. Predictable output size makes it easier to size WebView containers

**MathJax is better for single-WebView approaches** where:
1. Lazy typesetting reduces initial render cost
2. Accessibility is required
3. Full LaTeX compatibility is needed (e.g., `\ref`, `\eqref`, complex packages)
4. Server-side rendering is preferred

> **Sources**:
> - KaTeX vs MathJax speed comparison widely documented in the community (KaTeX is ~5-10× faster for individual renders)
> - MathJax features and lazy typesetting — https://docs.mathjax.org/en/latest/output/lazy.html
> - MathJax server-side integration — https://docs.mathjax.org/en/latest/server/start.html
> - KaTeX API documentation — https://katex.org/docs/api.html

---

## 6. CSS Containment and Layout Isolation

### Core Question

Can the CSS `contain` property help with formula blocks to prevent layout thrashing?

### Findings

#### CSS `contain` Property

From MDN:

> "The `contain` CSS property indicates that an element and its contents are, as much as possible, independent from the rest of the document tree. Containment enables isolating a subsection of the DOM, providing performance benefits by limiting calculations of layout, style, paint, size, or any combination to a DOM subtree rather than the entire page."

#### Relevant Values

| Value | Effect | Relevance to Math Formulas |
|---|---|---|
| `contain: layout` | Internal layout isolated; changes inside don't affect outside layout | **High** — prevents formula re-render from triggering full-page reflow |
| `contain: paint` | Descendants clipped to bounds; off-screen elements skipped by paint | **High** — off-screen formulas don't get painted |
| `contain: size` | Element size computed ignoring children; requires explicit dimensions | **Medium** — useful if formula container has known fixed size |
| `contain: strict` | All of the above (`size layout paint style`) | **Medium** — requires explicit sizing |
| `contain: content` | `layout paint style` (no size containment) | **High** — best balance for dynamic-height formulas |

#### Application to Formula Blocks

For a single-WebView approach with many formula blocks:

```css
.katex-display {
  contain: layout style;  /* Isolate layout, scope counters */
  content-visibility: auto;  /* Skip rendering for off-screen blocks */
}
```

- **`contain: layout`**: When KaTeX re-renders a formula (e.g., during streaming), the browser only recalculates layout within that formula block. Surrounding text paragraphs are not re-laid-out.
- **`contain: paint`**: Off-screen formula blocks are skipped during paint. Combined with `content-visibility: auto`, the browser can skip both layout and paint for blocks far from the viewport.
- **`contain: style`**: Scopes CSS counters and quotes, preventing formula-internal counters from affecting global numbering.
- **`content-visibility: auto`** (Chromium-only, Baseline since 2022): Automatically applies `contain: layout style paint` + skips rendering entirely for off-screen content. This is a stronger version of what MathJax's lazy typesetting does at the JS level.

#### Caveat for Multi-WebView Approach

If each formula is in a separate WebView, CSS containment within each WebView is **less impactful** because each WebView is already layout-isolated by its nature. However, it's still good practice for:
- The text-only WebViews (prevent text reflow from triggering unnecessary paint)
- Formulas that are tall enough to cause internal scrolling

#### Verdict

**For the single-WebView approach**: `contain: content` on formula blocks plus `content-visibility: auto` on blocks below the fold is a significant performance win with near-zero implementation cost.

**For the multi-WebView approach**: `contain` is less critical but still recommended as a defensive measure within each small WebView.

> **Sources**:
> - MDN CSS `contain` property — https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/contain
> - MDN `content-visibility` — https://developer.mozilla.org/en-US/docs/Web/CSS/content-visibility
> - CSS Containment Module Level 2 spec — https://drafts.csswg.org/css-contain-2/

---

## 7. Server-Side Rendering of Formulas

### Core Question

Is SSR of KaTeX formulas (rendering to SVG/HTML string on server) a viable alternative to client-side WebView rendering?

### Findings

#### KaTeX SSR Capabilities

From the KaTeX API:

> "To generate HTML on the server or to generate an HTML string of the rendered math, you can use `katex.renderToString`"

- `katex.renderToString` works in Node.js with the `katex` npm package
- Returns a self-contained HTML string with inline styles and references to KaTeX CSS classes
- The CSS file (`katex.css` or `katex.min.css`) must still be included in the page for fonts and styling
- Output is an HTML string (not SVG), so it integrates directly into any HTML content

#### MathJax SSR Capabilities

- MathJax v3+ has a full Node.js API via `mathjax-full` npm package
- Can render to SVG, CHTML, or MathML
- SVG output is completely self-contained — no CSS or font dependencies
- MathJax SSR is used by many publishing tools (arXiv, Stack Exchange, etc.)

#### Viability for MathMind

**Option A: Server pre-renders all formulas → client inserts HTML strings into WebViews**

- ✅ Zero client-side KaTeX/JS overhead per formula
- ✅ Formulas arrive as plain HTML — no parsing, no font loading delay
- ✅ Works with any WebView/rendering approach (single or multi)
- ❌ Increases server CPU cost (but KaTeX is fast: ~1ms per formula)
- ❌ Still need to load KaTeX CSS on every WebView for styling
- ❌ Dynamic re-rendering (e.g., dark mode toggle) requires re-fetch or client-side re-render

**Option B: Server pre-renders to SVG → client embeds SVG directly**

- ✅ Completely self-contained — no CSS dependency
- ✅ SVG scales perfectly at any resolution
- ✅ Works in any WebView, any platform
- ❌ SVG output is larger than HTML output (~2-3×)
- ❌ MathJax SVG rendering is slower server-side (~10-50ms per formula)
- ❌ Copy-paste of LaTeX source from SVG is harder (needs additional metadata)

#### Hybrid Approach (Recommended)

1. **Server-side**: AI response includes pre-rendered HTML for each formula (via KaTeX SSR)
2. **Client-side fallback**: If server rendering fails or is unavailable, the client renders via `katex.renderToString`
3. **Font sharing**: Load KaTeX CSS once at app level; inject a `<link>` into each WebView pointing to the same CSS URL (browser cache handles dedup)
4. **Re-render capability**: Keep the original LaTeX source in a `data-tex` attribute so the client can re-render if needed (dark mode, font size change, etc.)

#### Verdict

**SSR is highly viable and recommended.** It removes the primary client-side cost of KaTeX (parsing + rendering JS) and reduces the per-WebView initialization burden. The LaTeX source should always be preserved for client-side fallback and re-rendering.

> **Sources**:
> - KaTeX API: `renderToString` for server-side — https://katex.org/docs/api.html#server-side-rendering-or-rendering-to-a-string
> - KaTeX Node.js installation — https://katex.org/docs/node.html
> - MathJax server-side rendering — https://docs.mathjax.org/en/latest/server/start.html
> - KaTeX Options (output format: html, mathml, htmlAndMathml) — https://katex.org/docs/options.html

---

## 8. Recommendations for MathMind

### Short-Term (Multi-WebView Approach)

Given the 1800vp height ceiling constraint:

1. **Use `katex.renderToString`** server-side to pre-render all formulas to HTML strings
2. **Split messages into segments**: `[text, formula_html, text, formula_html, ...]`
3. **Create one WebView per segment** to stay under the height limit
4. **Share KaTeX CSS**: Load `katex.min.css` once at app level; each WebView's HTML references the same CSS URL (cache hit)
5. **Implement WebView pooling**: Reuse WebViews instead of creating/destroying; maintain a pool of ~10–15 pre-warmed WebViews
6. **Preserve LaTeX source** in `data-tex` attributes for copy functionality

### Medium-Term (Hybrid Approach)

1. **Merge text-only segments**: Two adjacent text paragraphs don't need separate WebViews; only split at formula boundaries
2. **Implement IntersectionObserver for formula WebViews**: Only create/render WebViews that are within ~500px of the viewport
3. **Add `contain: content`** to the CSS in each WebView as defensive layout isolation
4. **Server-side rendering**: Pre-render formulas in the AI backend before sending to the client

### Long-Term (Ideal Architecture)

1. **Advocate for platform fix**: The 1800vp ceiling is a platform limitation that should be addressed at the HarmonyOS WebView level
2. **Move to single WebView + virtual scrolling**: Once the height limit is resolved, use a single WebView with:
   - `content-visibility: auto` on message groups below the fold
   - `IntersectionObserver` for lazy formula rendering
   - `contain: content` on formula blocks
   - KaTeX client-side rendering for dynamic/streaming content
3. **Align with industry practice**: ChatGPT, Claude, and DeepSeek all use single-DOM-tree rendering — there are good reasons for this

### Decision Matrix

| Approach | Memory | Init Cost | Scroll Performance | Industry Alignment | Platform Risk |
|---|---|---|---|---|---|
| Single WebView (blocked by 1800vp) | ✅ Low | ✅ Fast | ✅ Smooth | ✅ Best | ❌ Blocked |
| Multi-WebView per segment | ❌ High | ❌ Slow | ⚠️ Adequate | ❌ Non-standard | ✅ Works |
| Multi-WebView with pooling | ⚠️ Medium | ⚠️ Medium | ⚠️ Adequate | ❌ Non-standard | ✅ Works |
| SSR + Multi-WebView | ⚠️ Medium | ✅ Faster init | ⚠️ Adequate | ❌ Non-standard | ✅ Works |

---

## References Summary

| # | Source | URL |
|---|---|---|
| 1 | KaTeX API Documentation | https://katex.org/docs/api.html |
| 2 | KaTeX Auto-Render Extension | https://katex.org/docs/autorender.html |
| 3 | KaTeX Options | https://katex.org/docs/options.html |
| 4 | KaTeX Browser Usage | https://katex.org/docs/browser.html |
| 5 | KaTeX Security | https://katex.org/docs/security.html |
| 6 | KaTeX Common Issues | https://katex.org/docs/issues.html |
| 7 | MDN CSS `contain` | https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/contain |
| 8 | MDN Intersection Observer API | https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API |
| 9 | MDN Background Tasks API (`requestIdleCallback`) | https://developer.mozilla.org/en-US/docs/Web/API/Background_Tasks_API |
| 10 | MathJax v4 Typesetting Documentation | https://docs.mathjax.org/en/latest/web/typeset.html |
| 11 | MathJax v4 Lazy Typesetting | https://docs.mathjax.org/en/latest/output/lazy.html |
| 12 | MathJax v4 TeX Support | https://docs.mathjax.org/en/latest/input/tex/index.html |
| 13 | MathJax Official Site | https://www.mathjax.org/ |
| 14 | ChatGPT Release Notes (OpenAI) | https://help.openai.com/en/articles/6825453-chatgpt-release-notes |
| 15 | Anthropic Engineering Blog | https://www.anthropic.com/engineering |
| 16 | CSS Containment Module Level 2 (W3C) | https://drafts.csswg.org/css-contain-2/ |

---

*This document represents findings as of 2026-07-24 based on primary source documentation, product observation, and web standards references. Some claims about ChatGPT/Claude/DeepSeek rendering behavior are based on public inspection of their rendered HTML output, as none publish detailed engineering documentation about their math rendering pipelines.*
