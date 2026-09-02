# docs/ — MindTrace 项目文档索引

> 最后整理:2026-09-01 · 范围:全部 43 个文档按**性质**(不是按日期)归类

---

## 目录结构

```
docs/
├── README.md                    ← 你在这里
│
├── architecture/                # 架构审计 + 静态数据
│   ├── audit-2026-09-01.{md,html}      ← 初次审计
│   ├── audit-full-2026-09-01.{md,html} ← 全量审计(主参考)
│   ├── deep-dive-2026-09-01.md         ← 关键文件深读
│   └── lint-baseline(-ast)-2026-09-01.json  ← ArkTS lint 基线
│
├── api/                         # API 契约
│   └── contract.md              ← OpenAI 兼容 / OCR / 内部模块接口
│
├── agents/                      # 工程 skills 配置(setup-matt-pocock-skills)
│   ├── domain.md                ← CONTEXT.md / ADR 消费规则
│   ├── issue-tracker.md         ← GitHub Issues + gh CLI 约定
│   └── triage-labels.md         ← 5 个标准 triage 标签
│
├── research/                    # 外部调研笔记
│   ├── huawei-arkui-agent-2026-09-01.md
│   ├── harmonyos-http-streaming-2026-07-24.md
│   ├── formula-render-strategies-2026-07-24.md
│   └── multi-webview-performance-2026-07-24.md
│
├── style/                       # 风格手册
│   └── arkts-1.1.md             ← ArkTS 1.1 strict 40+ 规则表(rule ID + error code)
│
├── plans/                       # 设计方案 / 重构 plan(W3/W4 era 整理)
│   ├── w3/                      ← 2026-07-17 ~ 2026-07-22 共 22 文件
│   │   ├── summary.md           ← W3 总览(原 docs/2026-07-17/W3_SUMMARY.md)
│   │   ├── frontend-architecture-2026-07-17.md
│   │   ├── arch-review-2026-07-17.html
│   │   ├── agent-*.md           (×3)
│   │   ├── notes-page-structure-proposal-2026-07-19.html
│   │   ├── review-page-plan-graph-proposal-2026-07-19.html
│   │   ├── dataflow-knowledge-structures-2026-07-20.html
│   │   ├── db-resultset-column-missing-analysis-2026-07-20.html
│   │   ├── latex-*-2026-07-20.html (×3)
│   │   ├── math-formula-ui-rendering-integrated-plan-2026-07-20.html
│   │   ├── notes-editor-markdown-2026-07-20.md
│   │   ├── rich-math-rendering-redesign-2026-07-20.html
│   │   ├── typeclassifier-knowledgemodel-contract-2026-07-20.html
│   │   ├── ui-preload-cache-optimization-2026-07-21.{md,html}
│   │   ├── chapter-field-refactor-2026-07-22.md
│   │   └── render-protocol-optimization-route-2026-07-22.md
│   └── w4/                      ← 2026-07-23 起共 4 文件
│       ├── chat-long-content-fix-plan-2026-07-23.md
│       ├── chat-render-chain-2026-07-23.html
│       ├── formula-split-render-plan-2026-07-24.md
│       └── ai-float-chat-streaming-plan-2026-07-24.md
│
└── competition/                 # 比赛交付物(2026-07-26)
    ├── ocr-setup.md             ← Math_Mind 比赛 OCR 启动说明
    └── references-2026-07-26.md ← 比赛参考资料清单(KaTeX / marked / DeepSeek 等)
```

---

## 命名约定

- **日期后缀**:保留在文件名里(`-2026-07-24`),不是目录层级,避免嵌套过深
- **W3 / W4 era**:按大版本归目录(`plans/w3/`、`plans/w4/`),目录层级承载"这是什么时期"
- **`.html` 文件**:设计稿/视觉稿,**在 git 里**(虽旧 AGENTS.md 描述"不在 git 里"——实际已被 commit,本 README 不动它们)

---

## 各目录的消费者

| 目录 | 谁会读 |
|------|--------|
| `architecture/` | 任何 agent 接手 MindTrace 第一份参考 |
| `api/` | 调 LLM / OCR / 内部模块时查契约 |
| `agents/` | `setup-matt-pocock-skills` / `to-tickets` / `triage` / `domain-modeling` 等 skill |
| `research/` | 做新设计前,确认别人调研过没有 |
| `style/` | 写 ArkTS 代码前查 rule ID + error code;lint job 也读 |
| `plans/` | 按需查历史方案 |
| `competition/` | 提交比赛时用 |

---

## 待办 / 已知遗留

- **`docs/2026-07-20/`、`docs/2026-07-21/` 两个目录残留**:包含 5 个被 Windows 锁定的孤儿 .html 文件。`git rm --cached` 已成功,但 `.NET Delete` / `Remove-Item` / `cmd move` 全部"Access is denied"。git 树已干净(5 个 rename 都识别),但磁盘上还有副本。**需手工清理**(可能是 DevEco Studio 或索引器持有句柄)。建议在 DevEco Studio 关闭后手动 `rm` 这 5 个文件并删除两个空目录。
- **`docs/adr/` 未创建**:AGENTS.md 标记为 Phase 2 创建,等 `domain-modeling` skill 真正决策时再开
- **AGENTS.md 自身**:用户已确认"先余着,后面再处理"