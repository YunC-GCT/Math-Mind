# 手动 smoke test 矩阵 (提交前必走)

每次提交 / 手动测试时, 走完以下 8 步确保核心流程不退化:

| # | 步骤 | 期望 |
|---|---|---|
| 1 | 5 Tab 切换 | 流畅 (Home / Notes / AI / Review / Profile) |
| 2 | 首页 Hero 卡片 | 正常渲染 |
| 3 | 进度环呼吸光晕 | 动画流畅 |
| 4 | AI 浮窗开/关 + 输入对话 | 浮窗无卡顿 |
| 5 | **W4 SSE 流式回复** (`AgentChatService.realReplyStream`) | **W4 新增,务必测** — 看到 token 逐字流入 |
| 6 | 笔记详情浮层打开/关闭 | 浮层无残留 |
| 7 | 复习 Tab 跳 StudyPlan | 路由正常 |
| 8 | 知识星系 (`KnowledgeGalaxy`) | 用户**不应看到** "示例:*" 假学科 (audit §4.20 + ticket #16) |

## 验证基础设施

| 任务 | 命令 |
|---|---|
| OCR 服务 (本地) | `python -m uvicorn ocr.app:app --port 8000` |
| 单元测试 (Node) | `npm --prefix scripts/arkts-lint test` (70 tests) |
| Lint 扫描 (v0.3 AST) | `node scripts/arkts-lint/index.mjs --quiet` |
| Build / Run | **DevEco GUI 或 hvigor CLI** |

## 静态编译

DevEco Studio → `Build` → `Build Hap(s)/APP(s)` 或 hvigor CLI：`hvigor assembleHap` / `hvigor packageHap`

## 真机调试

`Run` → `Run 'entry'` (需要 HarmonyOS 真机或远程模拟器)

## 单元测试 (Hypium, 在 entry/build-profile.json5 配了 ohosTest)

当前覆盖极少 (`agents/src/test/` 仅 2 文件)

**计划**: Phase 4 ticket #13 加 12 个最小测试 (StructureService / TruthCheckService / PromptBuilder, 见 ADR-0007)

## E2E 验证

拍照 → AI 整链需要 FastAPI OCR 服务 (`OcrTool.recognize()` 调本地 HTTP, 默认 `localhost:8000`)