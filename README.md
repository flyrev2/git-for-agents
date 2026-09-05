# git-for-agents

A Git config that makes Git say as little as possible on success, for
tools that read every byte of output. Coding agents pay tokens for
`On branch main`, the detached-HEAD lecture, `(use "git add <file>..." to
update what will be committed)`, and every other hint Git prints for humans.
This file turns that off without touching errors, conflicts, or rejections.

One file, plain configuration, works with any Git since 2.32.

## Install

For agent processes only, leaving your own shell alone:

```sh
git clone https://github.com/flyrev2/git-for-agents ~/git-for-agents
export GIT_CONFIG_SYSTEM="$HOME/git-for-agents/gitconfig"
```

Put the `export` where your agent starts. For Claude Code, that is the
`env` block in `~/.claude/settings.json`:

```json
{ "env": { "GIT_CONFIG_SYSTEM": "/Users/you/git-for-agents/gitconfig" } }
```

Your global and repository config still apply and still win, because
the file is loaded at the lowest-priority system level. Note that it
replaces the real system config, which on macOS with Xcode Git may set
`credential.helper`. If pushes start asking for passwords, add that key
to your global config.

For everyone, agent or not:

```sh
git config --global include.path ~/git-for-agents/gitconfig
```

## What it saves

Output bytes, stdout and stderr combined, for a fixed workflow on stock
Git 2.50. Reproduce with `./measure.sh`. Tokens are roughly bytes divided by four.

| Command | Before (bytes) | After (bytes) | Saved |
|---|---:|---:|---:|
| `git init` | 126 | 125 | 0% |
| `git add` | 0 | 0 | 0% |
| `git commit` | 123 | 123 | 0% |
| `git remote` | 0 | 0 | 0% |
| `git push` | 164 | 163 | 0% |
| `git checkout-b` | 35 | 35 | 0% |
| `git status` | 268 | 9 | 96% |
| `git commit2` | 63 | 63 | 0% |
| `git switch` | 72 | 72 | 0% |
| `git commit3` | 57 | 57 | 0% |
| `git merge` | 79 | 34 | 56% |
| `git fetch` | 0 | 0 | 0% |
| `git push2` | 119 | 118 | 0% |
| `git tag` | 0 | 0 | 0% |
| `git stash` | 84 | 84 | 0% |
| `git stash-pop` | 378 | 75 | 80% |
| `git reset` | 46 | 46 | 0% |
| `git log` | 446 | 70 | 84% |
| `git branch-d` | 38 | 38 | 0% |
| `git pull` | 20 | 20 | 0% |
| `git checkout-sha` | 579 | 33 | 94% |
| `git switch-back` | 117 | 117 | 0% |
| `git push-new` | 288 | 288 | 0% |
| `git merge-conflict` | 129 | 129 | 0% |
| `git status-conflict` | 382 | 9 | 97% |
| `git merge-abort` | 0 | 0 | 0% |
| `git diff` | 114 | 106 | 7% |
| `git commit-nothing` | 366 | 152 | 58% |
| **Total** | **4093** | **1966** | **51%** |

The big wins are `status`, `log`, `stash pop`, and anything that
triggers advice. The remaining bytes are messages Git has no config
knob for, such as `Switched to branch` and commit summaries. Those need
`--quiet` per command, or the proposed `core.quiet` setting in
[this Git branch](https://github.com/flyrev2/git/tree/agent-quiet),
which this file already enables where it exists.

## What it does not do

- It never hides errors. `fatal:`, `error:`, and `CONFLICT` lines are untouched.
- It does not change behavior, only output. The one behavior change worth
  having, `push.autoSetupRemote`, is included but commented out.
- It does not replace `--porcelain` flags. When a command has a machine
  format, use it. This file covers the commands agents run without one.

## License

MIT
