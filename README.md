# MathMind · 工程 README

> **W0 末 5/5 module BUILD SUCCESSFUL · W1 块 2 进行中**
> 创建/维护: Z(由 Mavis 代笔) · 2026-07-04

---

## 一、项目是什么

**MathMind** = "数学心灵"· HarmonyOS 端的高中数学智能学习助手,三大入口:
- **主 App**(entry HAP) — 复习 / 提问 / KG 浏览 / 历史 / 设置
- **小艺 Skill**(skill HAP) — 7 类意图(快速复习 / 问答 / 添加 / 卡片 / 闪卡 / 语音 / 提醒)
- **元服务卡片**(cardservice HAP) — 4 类(今日待复习 / 连续打卡 / 新知识点 / 进度总览)

品牌定位:**Agent-first 数学学习伴侣**(间隔重复 + 知识图谱 + RAG 问答)

---

## 二、W0 阶段做了什么

W0(2026-07-03 ~ 2026-07-04)是"地基阶段",把 5 module 工程搭起来并 BUILD SUCCESSFUL。

### 2.1 5 module 架构

```
MathMind/
├── entry/         # HAP · type:entry      主 App 入口 + 5 个页面
├── common/        # HSP · shared          共享类型 + 工具(无 UI)
├── agents/        # HSP · shared          核心业务 Agent(Dispatcher / Review / KG / Query)
├── skill/         # HAP · type:feature    小艺 Skill 入口(SkillAbility)
└── cardservice/   # HAP · type:feature    元服务卡片(CardEntryAbility + FormAbility)
```

- **HAP**(HarmonyOS Ability Package)= 可独立安装运行的 .app
- **HSP**(HarmonyOS Shared Package)= 共享代码库,不能独立运行,被 HAP 引用

### 2.2 工程配置

每个 module 都有自己的:
- `build-profile.json5`(模块编译配置 / targets / 依赖)
- `hvigorfile.ts`(构建任务:HAP 用 `hapTasks` / HSP 用 `hspTasks` / 根用 `appTasks`)
- `module.json5`(运行时配置:ability / extensionAbility / deviceTypes 等)
- `obfuscation-rules.txt`(即使 enable false 也必须存在)

根 `build-profile.json5` 通过 `buildOptionSet[].arkOptions.obfuscation.ruleOptions.files` 引用各 module 的混淆规则文件。

### 2.3 W0 末编译结果

```
> hvigor BUILD SUCCESSFUL in 12s
✅ 5/5 module 全过
  - common   → HSP (1 s 832 ms CompileArkTS)
  - agents   → HSP (6 s 343 ms)
  - entry    → HAP (6 s 640 ms)
  - skill    → HAP (6 s 391 ms)
  - cardservice → HAP (6 s 130 ms)
entry 模拟器显示: "Hello from common v1! | v0.0.1"
```

### 2.4 cardservice form widget 兜底方案

W0 期间尝试在 cardservice 写 form widget 业务,反复撞 `hvigor-ohos-plugin validateFormSrc` 报错(form widget src 在 type:feature 模块下无法解析,8+ 种 src 路径试过全失败)。

**W0 兜底**:cardservice 暂时删 `extensionAbilities` + `pages`,加 `mainElement = FormAbility`,form widget 业务留 W1 详细研究。

---

## 三、W0 踩过的坑(以后别再踩)

### 3.1 ArkTS 严格语法

- ❌ 不能用 `any` / `unknown`(DevEco 严格禁止)
- ✅ 用 `Object` 或显式 interface
- ✅ `Want` 必须显式类型 + `import Want from '@ohos.app.ability.Want'`
- ✅ `AbilityConstant` 是命名导出 `from '@kit.AbilityKit'`
- ✅ `UIAbility` 是默认导出 `from '@ohos.app.ability.UIAbility'`

### 3.2 HSP 与 HAP 差异

| 限制 | 说明 |
|------|------|
| HSP `oh-package.json5` 不能加 `main` 字段 | 想 export 必须 `export *` 在 `Index.ets` |
| HSP `module.json5` 只能 6 字段 | `name / type / description / deviceTypes / deliveryWithInstall / installationFree` |
| HSP 跨 module import 必须完整路径 | 不能 `from 'common/Index'`,只能 `from 'common/src/main/ets/Index'` |
| 一个应用只能 1 个 `type:entry` 模块 | 其他 HAP 必须 `type:feature` |

### 3.3 build 必备文件

- `obfuscation-rules.txt`:即使 `enable false` 也要存在,空文件 + 注释即可
- 每个 module 自己的 `build-profile.json5` + `hvigorfile.ts`:根配置不够
- atomic service(`type:feature` + `installationFree:true`)必填 `mainElement`

### 3.4 signing & obfuscation

- signingConfig 暂空:模拟器接受 unsigned,真机部署时再配
- obfuscation 暂关:模拟器不需要混淆

---

## 四、当前状态

```
分支: main (8d79a84 Revert W1 块 2)
  ├─ 1b2abf7 Initial commit
  ├─ bfaa8e5 feat: W0 末 hard-start - 5/5 module BUILD SUCCESSFUL
  ├─ 29511c3 W1 Z 块2: 9 文件 (在另一分支被 revert,见下)
  └─ 8d79a84 Revert "W1 Z 块2..."  ← 当前 main HEAD

并行分支: feature/z-w1-block2 (W1 块 2 重做中,1 文件 1 commit + build 验证)
  ├─ fc889f6 feat(z-w1-file1): CommonTypes 共享类型   ✅ build 通过
  ├─ 127343c feat(z-w1-file2): logger 统一日志         ✅ build 通过
  ├─ 3c729e2 feat(z-w1-file3): uuid 生成               ✅ build 通过
  ├─ 68b8c5b feat(z-w1-file4): timeWindow 时间窗工具    ✅ build 通过
  └─ ccb1345 feat(z-w1-file5): confidenceSort 置信度排序 ✅ 待 build
```

**W1 块 2 总共 11 文件**(common 6 + agents 5),目前完成 5/11。

---

## 五、接手指南(给新加入的开发者)

### 5.1 环境准备

1. **DevEco Studio**:`D:\HarmoNova\DevEco Studio\`(已装)
2. **Node.js**(DevEco 内置):`D:\HarmoNova\DevEco Studio\tools\node\node.exe`
3. **Git**:Windows 自带,SSH key 已配,走 port 443(`~/.ssh/config` 配置)

### 5.2 拉代码 + 跑 build

```powershell
# 1. clone
git clone git@github.com:YunC-GCT/Math-Mind.git D:\HMgent\MathMind

# 2. DevEco 打开
# File → Open → D:\HMgent\MathMind

# 3. 切换到 W1 工作分支
git checkout feature/z-w1-block2

# 4. build
# Build → Build Hap(s)/APP(s)  (或 Ctrl+F9)
# 期望: BUILD SUCCESSFUL in ~10s
```

### 5.3 看懂工程

| 目录 | 看什么 |
|------|--------|
| `entry/src/main/ets/pages/` | 主 App 5 页面(只写了占位 Index.ets) |
| `common/src/main/ets/models/` | 共享类型(KnowledgeUnit / ReviewRecord / ...) |
| `common/src/main/ets/utils/` | 工具(logger / uuid / timeWindow / confidenceSort) |
| `agents/src/main/ets/core/` | 核心 Agent(Dispatcher / ReviewAgent / KG / QueryPlanner) |
| `skill/src/main/ets/skillability/` | 小艺 Skill 入口 |
| `cardservice/src/main/ets/` | 元服务卡片(W1 待补 form widget) |

### 5.4 W1 剩余任务

**W1 块 2 剩余 6 文件**:
- File 6/11: `common/Index.ets` 更新 export
- File 7/11: `agents/core/ReviewAgent.ets` (SM-2 算法 + 复习业务)
- File 8/11: `agents/core/KnowledgeGraph.ets` (KG 节点 + 边)
- File 9/11: `agents/core/QueryPlanner.ets` (查询规划)
- File 10/11: `agents/core/Dispatcher.ets` (任务分发)
- File 11/11: `agents/Index.ets` 更新 export

**W1 块 3(下一批)**:agents/services 4 文件(APIClient / EmbeddingClient / KGService / RDBService)

**W2 块 4**:cardservice form widget 业务补充(等研究完 src 解析问题)

---

## 六、关键约束(团队规矩)

1. **未经明示禁止 push 到 GitHub** — 本地 commit 自由,push 必须 leader 点头
2. **删除优先 mavis-trash / 回收站** — 不直接 `Remove-Item -Recurse -Force`
3. **失败 2 次停下报告** — 不无限重试,贴报错最后 5 行
4. **SSH 走 443** — 本机封 port 22,`~/.ssh/config` 已配 `Host github.com → ssh.github.com:443`
5. **commit author 固定** — `YunC-GCT / 2549237929@qq.com`
6. **build 由 DevEco GUI 跑** — 不走命令行 hvigorw(中文路径乱码撞墙)

---

## 七、相关文档

- `D:\HMgent\MathMind方案\` — 完整方案仓(策划书 / INDEX / 任务清单 / 分块路线图 / 代码模板 / 后端设计 / 申请材料 / 资源汇总 / Git_AI_对话速查卡)
- `MathMind_策划书_v1/` — 4 个文档(产品形态 / 用户画像 / 技术架构 / 商业模式)
- `MathMind_INDEX_总目录.md` — 方案仓总目录
- `MathMind_任务清单_待勾选.md` — W0-W4 任务清单
- `MathMind_Git_AI_对话速查卡_v1.md` — Git 操作 + AI 协作速查卡

---

**最后更新**:2026-07-04 22:52 · commit `ccb1345` · 分支 `feature/z-w1-block2`
