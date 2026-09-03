# 跨 session 通信协议

`mavis communication send` CLI 不可用, 改用文件协议 + user 中转。

## 文件命名

| 方向 | 命名 | 路径 |
|---|---|---|
| UI session → 主 agent | `docs/ui_to_agent_<topic>_<date>.md` | 当前 worktree 的 `docs/` |
| 主 agent → UI session | `docs/agent_to_ui_<topic>_<date>.md` | UI session worktree 的 `docs/` |

## 约束

- **单 worktree 多 session**: 同 `.git/`, **working tree 互斥** (一个 session 改时另一个别动)
- **多 worktree**: 各自 working tree 独立, 但共享 HEAD, 需注意分支同步
- **通过 user 转告**, 不直接推给对方 (避免冲突)

## 现状

⚠️ 规约存在但目前**没有实际使用过** (`docs/` 下没找到该模式文件) — Phase 2/3 决定保留或废弃。

如果使用, 确保:
1. 写文件前先 read 现有文件, 不整段 overwrite
2. 文件名格式: `<from>_<to>_<topic>_<YYYY-MM-DD>.md`
3. 正文开头写明 "From: <session>, To: <session>, Date: ..."

## 其他 session 通信方式

- **Git branch** (主推荐): 用 YunCeH / 其他分支共享 commit
- **User 转达** (次推荐): 直接告诉 user, user 转告目标 session