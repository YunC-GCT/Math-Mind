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

## Windows / DevEco 已知问题 (sandbox 适配)

### MSYS `ssh.exe` 崩溃 → 用系统 OpenSSH

**症状**: 在本仓库 (Windows 中文路径 + Git for Windows) 里 `git push` / `git fetch` 报:

```
0 [main] ssh (XXXX) D:\Git\usr\bin\ssh.exe: *** fatal error - couldn't create signal pipe, Win32 error 5
fatal: Could not read from remote repository.
```

**原因**: MSYS 包装的 `ssh.exe` (`D:\Git\usr\bin\ssh.exe`) 在本 sandbox 偶发崩溃,直接连 GitHub SSH (port 443 / 22) 失败。

**修复** (一次性, 写到本地 `.git/config`, 不入 git):

```bash
git config --local core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"
```

> 系统自带 OpenSSH (`System32\OpenSSH\ssh.exe`) 不走 MSYS 包装, 不撞 env.exe crash。验证方式: `ssh -T git@github.com` 应返回 `Hi YunC-GCT! You've successfully authenticated, but GitHub does not provide shell access.`

**注意**: `.git/config` 不在 git 里 — 每个新 clone 都要重新设一次。如果想要全机器持久, 写到 `~/.gitconfig` 而不是 `--local`。

### MSYS `git commit` 崩溃 → 用 `commit-tree` 绕路

**症状**: `git commit -m "..."` 报同样 `couldn't create signal pipe`, 但 `git add` / `git write-tree` / `git status` 都正常。

**原因**: git 内部 commit 路径 (经 env wrapper) 触发同一 MSYS bug。`git push` 修好之后 commit 也大概率修好 (因为都走 ssh 后端); 如果 push 修好后 commit 还崩, 用下面的绕路。

**绕路** (3 步, 不用 `git commit`):

```bash
# 1. 写 commit message 文件 (用 .NET 避免 PowerShell Out-File 加 BOM)
$bytes = [System.Text.Encoding]::UTF8.GetBytes('docs: your title' + "`n`n" + 'body')
[System.IO.File]::WriteAllBytes('.git/MSG_TMP', $bytes)

# 2. 提交 (引用当前 HEAD 作 parent)
$tree = git write-tree
$parent = git rev-parse HEAD
$commit = git commit-tree $tree -p $parent -F .git/MSG_TMP
git update-ref HEAD $commit
Remove-Item .git/MSG_TMP
```

`commit-tree` 不走 env wrapper, 100% 可靠。Commit message / author / author-date 全部正常。

## 完整 session 起手检查清单

新 session 接到 MindTrace, 第一件事按顺序:

```bash
git branch --show-current        # 必须 != main (红线 6)
git status                       # 看遗留修改
git config --get core.sshCommand # 没值的话跑上面那个 git config --local 命令
node scripts/naming-lint/index.mjs   # 0 violations expected
node scripts/link-check/index.mjs    # 0 broken links expected
```

跑完上面 5 行,环境就绪。