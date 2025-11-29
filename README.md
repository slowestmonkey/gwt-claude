# gwt-claude

Run multiple Claude Code sessions on different branches. No conflicts.

**zsh only.**

## 🦑 Why

Claude Code lives in your working directory. Want to build a feature while fixing a bug? You're stuck switching branches, stashing, and confusing everyone.

Git worktrees let you check out multiple branches in separate folders. This tool wraps that and auto-launches Claude Code in each worktree.

## 🦩 Install

```bash
git clone https://github.com/slowestmonkey/gwt-claude.git ~/.gwt-claude
echo 'source ~/.gwt-claude/gwt.zsh' >> ~/.zshrc
source ~/.zshrc
```

Needs: zsh, git, [Claude Code](https://docs.anthropic.com/en/docs/claude-code)

## 🦚 Commands

```bash
gwt-create <name>           # Create worktree + open Claude
gwt-create -l <name>        # Create from current branch
gwt-create -b dev <name>    # Create from specific branch
gwt-list                    # List worktrees
gwt-switch <branch>         # Jump to worktree + open Claude
gwt-remove <branch>         # Remove worktree + delete branch
gwt-remove -k <branch>      # Remove worktree, keep branch
gwt-remove -f <branch>      # Force remove
```

All commands: `-h` for help, tab completion supported.
