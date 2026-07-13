# MathMind · 当前状态

> 工程: YunC-GCT/Math-Mind · 5 module HarmonyOS 数学学习助手  
> 创建/维护: Z(由 Mavis 代笔) · 最近更新: 2026-07-13

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
- `610c9d2` docs: README 全面改写 (W0 阶段说明 + W1 进度 + 接手指南) — *此 README 即将被本文件覆盖*
- `d6220c4` merge: feature/z-w1-block2 → main (含 31eaa04/88fbb99 两条 GitHub web README 标题修订)

### 1.3 GitHub Web 标题修订

- `31eaa04` Update project title in README to include '源码' — 作者 YunCeH
- `88fbb99` Update project title in README.md — 作者 shi

---

## 二、需要实现的工作 — 7/13 今晚 D1 精简拍照链

> 目标: 拍照 → OCR → DeepSeek 3×3 分类 → 3 模板 → 真值检验 → 入库 → 显示  
> 整链时序见 `docs/D1_CAPTURE_CHAIN_PLAN.md`  
> 详细分工见 `docs/TONIGHT_TASKS.md`

### 2.1 8 文件分工 (按 TONIGHT_TASKS 编号 · 3 人独立开发模式)

| 编号 | 文件 | 责任 | 内容 | 状态 |
|------|------|------|------|------|
| **A1** | `entry/src/main/ets/database/NoteDao.ets` | **L** | RDB `insert(unit)` + `queryById(id)` | 🟡 空壳待填 |
| **A2** | `entry/src/main/ets/services/ApiClient.ets` | **你 + Mavis** | HTTP `request()` + JWT 注入 + 401 重试 | 🟡 空壳待填 |
| **B1** | `agents/src/main/ets/mcp/tools/OcrTool.ets` | **D** | `recognize(imageBase64)` → ML Kit OCR | 🟡 空壳待填 |
| **B2** | `agents/src/main/ets/agents/TypeClassifier.ets` | **D** | `classify(input)` → OCR + DeepSeek 3×3 分类 | 🟡 空壳待填 |
| **C** | `agents/src/main/ets/agents/KnowledgeModel.ets` | **L** | 3 模板 + 真值检验 + `NoteDao.insert` | 🟡 空壳待填 |
| **D** | `agents/src/main/ets/core/Dispatcher.ets` | **你 + Mavis** | L1 关键词 "记/拍/这题" → routeDispatch D1 分支 | 🟡 空壳待填 |
| **E1** | `entry/src/main/ets/services/AiService.ets` | **你 + Mavis** | `capture(imageUri)` → base64 → POST dispatch | 🟡 空壳待填 |
| **E2** | `entry/src/main/ets/overlays/CameraOverlay.ets` | **你 + Mavis** | 相机预览 + 快门 + 相册 → imageUri | 🟡 空壳待填 |

#### 3 人工作量

| 人 | 文件数 | 编号 |
|----|--------|------|
| **你 + Mavis** | 4 | A2 + D + E1 + E2 |
| **D** | 2 | B1 + B2 |
| **L** | 2 | A1 + C |

### 2.2 关键约束 (摘自 D1_CAPTURE_CHAIN_PLAN.md)

**LLM 配置**:
- 默认 Provider: **SiliconFlow / DeepSeek-V3** (`deepseek-ai/DeepSeek-V3`)
- 端点: `https://api.siliconflow.cn/v1/chat/completions`
- Temperature: **0.1** · MaxTokens: **256** · Timeout: **5s**
- 降级链: DeepSeek → 小艺Kit → Mock

**3×3 分类体系**:
- 学科: 高等代数 / 数学分析 / 解析几何
- 类型: 概念 / 计算 / 证明

**3 模板** (KnowledgeModel 用):
- `concept_v1` (定义/性质/相关概念)
- `computation_v1` (题目/解法/答案)
- `proof_v1` (命题/证明/要点)

**真值检验** (KnowledgeModel.truthCheck):
- 括号配对 ( ) [ ] { }
- 除零检测 /0 ÷0
- 恒等式校验 sin²x+cos²x=1 / e^(iπ)+1=0
- 矛盾等式 (1=2, 0=1) → error
- LaTeX 语法 $ $ { } 配对
- 结果 `truthFlag: 'valid' | 'warning' | 'error'`,UI 只对 error 标红

### 2.3 依赖顺序 (3 人组内串行 / 组间可并行)

```
你 + Mavis (4 文件)        D (2 文件)              L (2 文件)
─────────────────         ──────────              ──────────
A2 (ApiClient)  ──┐
                  ├── D (Dispatcher) ──┐
                  │                     ├── E1 (AiService)  ← 集成时
                  │                     │   E2 (CameraOverlay) ← 调用 AiService
                  │
                  │       B1 (OcrTool) ──┐
                  │                       ├── B2 (TypeClassifier)
                  │                       │
                  │                       A1 (NoteDao) ──┐
                  │                                       ├── C (KnowledgeModel)
                  │                                       │
                  └──────────────────────────────────────┘
                              ↓ 集成时再串起来
                  C 被 D 调用 · D 被 E1 调用 · E1 被 E2 调用
```

**3 组内部串行 / 3 组间并行**：
- **你 + Mavis**: 先 A2 (HTTP) → 后 D (路由) → 最后 E1+E2 (UI)
- **D**: 先 B1 (OCR) → 后 B2 (分类)
- **L**: 先 A1 (DB) → 后 C (建模)
- **集成**: 3 组完成后，由你 merge 3 个 feature branch 到 main

### 2.4 整链接口契约

```
POST /agents/dispatch
  请求: { source: "app", payload: "<base64图片>", imageUri: "file://..." }
  响应: { success, route: "D1", data: KnowledgeUnit, durationMs }
```

---

## 三、构建与运行

- **build 走 DevEco Studio GUI** (Build → Build Hap(s)/APP(s)),不走命令行 hvigorw (中文路径乱码)
- **SSH 走 port 443** (`~/.ssh/config` 已配 Host github.com → ssh.github.com:443)
- **作者固定** `YunC-GCT <2549237929@qq.com>` (`git config user.name/email` 已配)

---

## 四、git 规则

1. **未经明示禁止 push** — 本地 commit 自由,推送必须 leader 点头
2. **删除走 mavis-trash / 回收站** — 不直接 `Remove-Item -Recurse -Force`
3. **失败 2 次停下报告** — 不无限重试,贴报错最后 5 行
4. **改完即 commit** — 单文件单 commit,feat/fix/docs 前缀
5. **每块结束推一次** — 拿到 leader 点头再 push,不全攒到最后

---

## 五、相关文档 (在 `D:\HMgent\MathMind方案\`)

- `D1_CAPTURE_CHAIN_PLAN.md` — 精简拍照链整链设计
- `DIRECTORY_MAP.md` — 四层目录 (模板/精简/完整/MVP)
- `TONIGHT_TASKS.md` — 7/13 今晚任务分工与时间线
- `AGENT_ARCH_v3.1.md` — Agent 架构
- `API_SPEC.md` — 23 API 端点
- `TWO_AXIS_CLASSIFICATION.md` — 两轴分类说明
- `LOCAL_VS_API_STRATEGY.md` — 本地 vs 云端策略
