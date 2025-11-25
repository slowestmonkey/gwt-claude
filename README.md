# gwt-claude

Git worktree manager for parallel Claude Code (cli) sessions
```
Claude Code = 👍
Git worktree = 👍
Claude Code + Git worktree = 👍²
```

## Why?

Run multiple Claude Code (cli) sessions on different branches simultaneously. Each session gets its own directory, so no git conflicts or context switching.

```bash
# Start working on a feature
gwt-create auth-refactor

# Meanwhile, in another terminal, start a different task
gwt-create fix-billing-bug

# Two Claude sessions, two branches, zero conflicts

# Later, pick up where you left off
gwt-switch auth-refactor
```

## Prerequisites

- **zsh** - Shell (default on macOS)
- **git** - Version control
- **claude** - [Claude Code CLI](https://claude.ai/claude-code)

## Install

```bash
# Clone to any location
git clone https://github.com/slowestmonkey/gwt-claude.git ~/.gwt-claude

# Add to ~/.zshrc
echo 'source ~/.gwt-claude/gwt.zsh' >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

## Commands

```bash
gwt-create <name>           # Create from main + open Claude Code
gwt-create <name> -l        # Create from current branch (-l = local)
gwt-create <name> -b dev    # Create from specific branch
gwt-list                    # List all worktrees
gwt-switch <name>           # Switch to worktree
gwt-remove <name>           # Remove worktree (with confirmation)
gwt-remove -f <name>        # Force remove
```

All commands support `-h` / `--help`.

## Storage

Worktrees are stored in: `~/.claude-worktrees/{repo}/{name}`