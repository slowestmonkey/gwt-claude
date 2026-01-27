# gwt

Run multiple AI coding sessions on different branches. No conflicts.

![DEMO](https://github.com/slowestmonkey/gwt-claude/blob/db0afca89bfc2b4acb0eb5a7187cc9c4673fa5af/docs/demo.gif?raw=true)

**Before (every time):**
`cd project && git stash && git checkout fix && opencode` — stash conflicts, context lost

**After (once):**
`gwt-create bugfix-y` — parallel session, isolated

## 🐙 Why

AI coding assistants are tied to your working directory. Want to build a feature while fixing a bug? You're stuck switching branches and losing context.

`gwt` wraps git worktrees to give each task its own directory + AI session. You also get:

- Auto-launches your AI assistant in each worktree
- Copies `.env` from main repo
- Prompts `npm install` when needed
- Safe mode (`-s`) for read/edit/git only
- Tab completion for branch names
- One command to remove worktree + branches

## 🦊 Requirements

- zsh
- [OpenCode](https://github.com/anomalyco/opencode), [Claude Code](https://claude.ai/code), or another AI assistant
- macOS or Linux

## 🦚 Install

```bash
git clone https://github.com/slowestmonkey/gwt-claude.git ~/.gwt-claude
echo 'source ~/.gwt-claude/gwt.zsh' >> ~/.zshrc
source ~/.zshrc
```

> Each worktree is a full checkout — plan for disk space accordingly.

## 🦜 First Run

On first use, `gwt` detects installed AI assistants and prompts you to choose:

```
Select your AI coding assistant:

  1) Claude Code (claude)
  2) OpenCode (opencode)

Enter choice [1-2]: 2

Selected: OpenCode
Save to config (~/.config/gwt/config)? [Y/n]: y
Saved! You won't be asked again.
```

## 🦩 Commands

```bash
gwt-create <name>           # Create worktree + open AI assistant
gwt-create -l <name>        # Create from current branch
gwt-create -b dev <name>    # Create from specific branch
gwt-list                    # List worktrees with status
gwt-switch <branch>         # Jump to worktree + open AI assistant
gwt-remove <branch>         # Remove worktree + delete branch
gwt-remove -k <branch>      # Remove worktree, keep branch
gwt-remove -f <branch>      # Force remove
gwt-providers               # List providers + interactive selection
gwt-providers opencode      # Set provider directly
```

All commands: `-h` for help, tab completion supported.

## 🦎 Supported Providers

| Provider | Command | Safe Mode | Dangerous Mode |
|----------|---------|-----------|----------------|
| Claude Code | `claude` | `-s` | `-d` |
| OpenCode | `opencode` | - | - |
| Aider | `aider` | - | - |
| Cursor | `cursor` | - | - |

## 🐠 Configuration

```bash
# Via environment variable
export GWT_PROVIDER=opencode

# Or via config file (~/.config/gwt/config)
GWT_PROVIDER=opencode
```

### Adding Custom Providers

```bash
# Format: GWT_PROVIDERS[name]="command|safe_flags|dangerous_flags|display_name"
GWT_PROVIDERS[my-ai]="my-ai-cli|--restricted|--no-confirm|My AI Tool"
```

See `gwt.conf.example` for a full configuration reference.
