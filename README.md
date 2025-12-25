# gwt-claude

Run multiple Claude Code sessions on different branches. No conflicts.

![DEMO](https://github.com/slowestmonkey/gwt-claude/blob/db0afca89bfc2b4acb0eb5a7187cc9c4673fa5af/docs/demo.gif?raw=true)

**Before (every time):**
`cd project && git stash && git checkout fix && claude` — stash conflicts, context lost

**After (once):**
`gwt-create bugfix-y` — parallel session, isolated

## 🐙 Why

Claude Code is tied to your working directory. Want to build a feature while fixing a bug? You're stuck switching branches and losing context.

`gwt-claude` wraps git worktrees to give each task its own directory + Claude session. You also get:

- Auto-launches Claude in each worktree
- Copies `.env` from main repo
- Prompts `npm install` when needed
- Safe mode (`-s`) for read/edit/git only
- Tab completion for branch names
- One command to remove worktree + branches

## 🦊 Requirements

- zsh
- [Claude Code](https://code.claude.com/docs)
- macOS or Linux

## 🦚 Install

```bash
git clone https://github.com/slowestmonkey/gwt-claude.git ~/.gwt-claude
echo 'source ~/.gwt-claude/gwt.zsh' >> ~/.zshrc
source ~/.zshrc
```

> Each worktree is a full checkout — plan for disk space accordingly.

## 🦩 Commands

```bash
gwt-create <name>           # Create worktree + open Claude
gwt-create -l <name>        # Create from current branch
gwt-create -b dev <name>    # Create from specific branch
gwt-list                    # List worktrees with status
gwt-switch <branch>         # Jump to worktree + open Claude
gwt-remove <branch>         # Remove worktree + delete branch
gwt-remove -k <branch>      # Remove worktree, keep branch
gwt-remove -f <branch>      # Force remove
```

All commands: `-h` for help, tab completion supported.
