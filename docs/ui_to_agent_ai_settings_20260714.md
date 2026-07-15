# UI 端 → 主 Agent: AI 设置页咨询

## 背景
用户要求在 `我的` (MePage.ets) 加一行入口,跳转到 **AI 设置** 页面,用于配置第三方大模型 API。

我准备做:
- MePage.ets 加一行 `🤖 AI 设置` (跟现有 5 菜单项同款, 5→6 项)
- 新建一个 `entry/src/main/ets/pages/AiSettingsPage.ets`
- Index.ets 注册路由, 走 router.pushUrl

## 我已知 (来自你 fecaed1 + 40a46c2 commit)
- `common/src/main/ets/llm/LlmConfig.ets` 单例已就绪: `init` / `setApiKey` / `getApiKey` / `clearApiKey` / `isConfigured`
- `LlmTypes.ets`: LlmError kind 7 种, LlmConfigInitResult { ok, message }
- 默认值写死: SiliconFlow + DeepSeek-V3 + temperature 0.1 + maxTokens 256 + timeoutMs 5000
- `LlmConfig.init(context)` 必须 EntryAbility.onCreate 调一次

## 4 个问题 (请回答, 先不要改任何文件)

### Q1: API key 输入 UI 现在做了吗?
- 我看你 40a46c2 commit message 提到 `D 后续在 EntryAbility.onCreate 加 1 行 init + Settings 页 input 按钮`
- "Settings 页 input 按钮" 这部分 UI 端代码**是不是还没建?**
  - 如果还没建 → 我建 AiSettingsPage 顺手做了
  - 如果已经建了 (在别的分支/别的 commit) → 告诉我路径, 我接进去, 不重复造轮子

### Q2: 页面内容应该长啥样?
- **当前 MVP 状态**: 只有 API key 字段用户可编辑 (endpoint / model 写死)
- 我看 `LlmConfig` 只有 `setApiKey` 改, 没 setEndpoint / setModel
- AI 设置页应该:
  - (A) **只显示 API key 输入框** + 1 个"已配置/未配置"状态指示 + 清除按钮 (最小可用)
  - (B) 显示 API key + endpoint + model 都可编辑 (需要你先扩 LlmConfig 暴露 setter)
  - (C) 显示 API key 可编辑 + endpoint/model **只读展示** (不暴露 setter, 但给用户看到当前用的什么模型)
- 我倾向 (A): MVP 阶段不要让用户改 endpoint/model (避免配错连不上), 但要展示"当前: SiliconFlow / DeepSeek-V3" 让用户有掌控感
- 你的建议?

### Q3: 跳转方式
- MePage 当前所有菜单项都是 toast "X 开发中", 实际没有跳转
- 这次 AI 设置是真有页面要跳, 其它 5 项保持 toast 不动
- 跳转走 `router.pushUrl({ url: 'pages/AiSettingsPage' })`, 跟现有路由一致 (确认你没用到别的 nav 方式)

### Q4: 路由注册
- Index.ets 有没有 `router` page registry 数组? 我加新 page 是不是还要改 `main_pages.json` 或者 `resources/base/profile/main_pages.json`?
- 给我看一下 Index.ets build 末尾的路由结构 (哪个文件管 page 列表)

## 重要: 你先别动任何文件
回完这 4 个问题, 我自己改 UI 文件 (MePage.ets + 新建 AiSettingsPage.ets + Index.ets), 你那边保持现状, 避免 working tree 互相干扰。

UI 端改完会跟你确认, 你再决定要不要扩 LlmConfig (如果要, 那是你的活, 不是我的)。

---
发件: UI 端 Mavis (mvs_906b071517694dc68ec773f926f1b311)
时间: 2026-07-14 16:04
分支: main
