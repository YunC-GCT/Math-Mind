# Git conventions

## Branches

- **主分支**: `main` (基线 `5b6f155`, 最新 HEAD `29df511`)
- **当前模型**: 单 `main` 分支, 无 feature branch (`.worktrees/` 偶尔用)
- **AI 必须在 `YunCeH` 工作**, 不在 `main` 上 commit
- 详见 ADR-0001 (`docs/adr/0001-layer-boundaries-`) 与 `YuncH` 分支命名约定

## Commit 风格 — conventional commits

| 前缀 | 用途 | 示例 |
|---|---|---|
| `feat(p0):` / `feat(w4):` | 新功能 | `feat(w4): add SSE streaming reply to AgentChatService` |
| `fix(agents):` / `fix(build):` | 修复 | `fix(viewmodels): disable preview units to stop fixture leak` |
| `refactor(llm):` | 重构 (no behavior change) | `refactor(llm): collapse 3 call methods to call(opts)` |
| `docs(entry):` / `docs:` | 文档 | `docs(phase-3): add ticket #5 spec` |
| `test(llm):` | 测试 | `test(llm-config): RED test for ticket #9` |
| `chore(docs):` / `chore:` | 杂事 | `chore(docs): reorganize into architecture/api/...` |
| `style:` | 格式化 | `style: reformat dispatcher.ets` |

模块前缀 (`agents:` / `entry:` / `common:` / `build:`) 表示影响的 module。

## 每 commit 前必查

```bash
git branch --show-current    # 必须不是 main
git status                   # working tree 干净或仅预期修改
git log --oneline -3         # 最近 commit 风格一致
```

## 红线

- **不 push** — 未经 user 明确说 "push",绝不 `git push`
- **不进 main** — 所有改动 commit 到 `YunCeH`,user 手动 review + merge
- **不 reset --hard** — `git reset --hard HEAD~n` 需 user 明确授权 (reflog 可找回)

## 跨 worktree 约束

- 单 worktree 多 session: 同 `.git/`, **working tree 互斥** (一个 session 改时另一个别动)
- 多 worktree: 各自 working tree 独立, 但共享 HEAD, 需注意分支同步