# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  gwt - Git Worktree Manager for AI Coding Assistants                      ║
# ║  Worktrees stored in: ~/.gwt-worktrees/{repo}/{branch}                    ║
# ║  Supports: Claude Code, Crush (OpenCode), Aider, Cursor, and custom CLIs  ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

# Config file locations (in order of priority)
GWT_CONFIG_PATHS=(
  "./.gwt.conf"
  "$HOME/.config/gwt/config"
  "$HOME/.gwt.conf"
)

# Default provider (can be overridden via config or GWT_PROVIDER env var)
: ${GWT_PROVIDER:=claude}

# Provider registry: command, safe_flags, dangerous_flags, display_name
# Format: provider_name=("command" "safe_flags" "dangerous_flags" "display_name")
typeset -A GWT_PROVIDERS
GWT_PROVIDERS=(
  [claude]="claude|--allowedTools|--dangerously-skip-permissions|Claude Code"
  [opencode]="opencode|||OpenCode"
  [aider]="aider|||Aider"
  [cursor]="cursor|||Cursor"
)

# Claude-specific allowed tools for safe mode
GWT_ALLOWED_TOOLS=(
  "Read" "Edit" "Write" "Grep" "Glob"
  "Bash(git:*)" "Bash(npm:*)" "Bash(ls:*)" "Bash(cat:*)"
)

# Load user config if exists
_gwt_load_config() {
  local config_file
  for config_file in "${GWT_CONFIG_PATHS[@]}"; do
    [[ -f "$config_file" ]] && {
      source "$config_file"
      return 0
    }
  done
  return 1
}

# Check if provider was explicitly configured
_gwt_provider_configured() {
  # Check if config file exists and contains GWT_PROVIDER
  local config_file
  for config_file in "${GWT_CONFIG_PATHS[@]}"; do
    [[ -f "$config_file" ]] && grep -q "^GWT_PROVIDER=" "$config_file" 2>/dev/null && return 0
  done
  # Check if env var was set before sourcing
  [[ -n "${GWT_PROVIDER_SET:-}" ]] && return 0
  return 1
}

# Interactive provider selection
_gwt_select_provider() {
  local available=() provider info cmd name
  
  # Build list of available (installed) providers (in preferred order)
  for provider in claude opencode aider cursor; do
    info="${GWT_PROVIDERS[$provider]}"
    cmd="${info%%|*}"
    name="${info##*|}"
    command -v "$cmd" &>/dev/null && available+=("$provider:$name")
  done
  
  [[ ${#available[@]} -eq 0 ]] && {
    echo "Error: No AI coding assistants found. Install one of: claude, crush, opencode, aider, cursor" >&2
    return 1
  }
  
  # If only one available, use it
  [[ ${#available[@]} -eq 1 ]] && {
    GWT_PROVIDER="${available[1]%%:*}"
    echo "Auto-selected provider: ${available[1]#*:} (only one installed)"
    return 0
  }
  
  # Interactive selection
  echo "\033[1mSelect your AI coding assistant:\033[0m\n"
  local i=1
  for item in "${available[@]}"; do
    local p="${item%%:*}"
    local n="${item#*:}"
    echo "  $i) $n ($p)"
    ((i++))
  done
  echo ""
  
  local choice
  while true; do
    echo -n "Enter choice [1-${#available[@]}]: "
    read -r choice
    [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#available[@]} )) && break
    echo "Invalid choice. Try again."
  done
  
  GWT_PROVIDER="${available[$choice]%%:*}"
  local selected_name="${available[$choice]#*:}"
  echo ""
  echo "Selected: $selected_name"
  
  # Offer to save
  echo -n "Save to config (~/.config/gwt/config)? [Y/n]: "
  read -r save_choice
  [[ ! "$save_choice" =~ ^[Nn]$ ]] && {
    mkdir -p "$HOME/.config/gwt"
    echo "GWT_PROVIDER=$GWT_PROVIDER" > "$HOME/.config/gwt/config"
    echo "Saved! You won't be asked again."
  }
  echo ""
}

# Initialize: load config, then prompt if needed
_gwt_load_config 2>/dev/null
[[ -n "$GWT_PROVIDER" ]] && GWT_PROVIDER_SET=1

# ─────────────────────────────────────────────────────────────────────────────
# Private Helpers
# ─────────────────────────────────────────────────────────────────────────────

# Get provider info: returns "command|safe_flags|dangerous_flags|display_name"
_gwt_get_provider() {
  local provider="${1:-$GWT_PROVIDER}"
  echo "${GWT_PROVIDERS[$provider]:-}"
}

# Check if provider is available (command exists)
_gwt_provider_available() {
  local provider="${1:-$GWT_PROVIDER}"
  local info=$(_gwt_get_provider "$provider")
  [[ -z "$info" ]] && return 1
  local cmd="${info%%|*}"
  command -v "$cmd" &>/dev/null
}

# List available providers
_gwt_list_providers() {
  echo "Available providers:"
  local provider info cmd name available
  for provider in ${(k)GWT_PROVIDERS}; do
    info="${GWT_PROVIDERS[$provider]}"
    cmd="${info%%|*}"
    name="${info##*|}"
    if command -v "$cmd" &>/dev/null; then
      available="\033[32m✓\033[0m"
    else
      available="\033[31m✗\033[0m"
    fi
    [[ "$provider" == "$GWT_PROVIDER" ]] && name="$name (active)"
    echo "  $available $provider - $name ($cmd)"
  done
}

# Launch the configured provider
_gwt_launch_provider() {
  local mode=$1
  
  # Interactive selection if not configured
  if ! _gwt_provider_configured; then
    _gwt_select_provider || return 1
  fi
  
  local provider="${GWT_PROVIDER}"
  local info=$(_gwt_get_provider "$provider")
  
  # Check if provider exists in registry
  if [[ -z "$info" ]]; then
    echo "Error: Unknown provider '$provider'" >&2
    echo "Set GWT_PROVIDER or add provider to config. Available:" >&2
    _gwt_list_providers >&2
    return 1
  fi
  
  # Parse provider info: command|safe_flags|dangerous_flags|display_name
  local cmd safe_flags dangerous_flags display_name
  cmd="${info%%|*}"
  info="${info#*|}"
  safe_flags="${info%%|*}"
  info="${info#*|}"
  dangerous_flags="${info%%|*}"
  display_name="${info#*|}"
  
  # Check if command exists
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' not found. Install $display_name first." >&2
    echo ""
    echo -n "Select a different provider? [Y/n]: "
    read -r choice
    [[ "$choice" =~ ^[Nn]$ ]] && return 1
    _gwt_select_provider || return 1
    _gwt_launch_provider $mode
    return $?
  fi
  
  echo "Opening $display_name..."
  
  local exit_code=0
  case "$mode" in
    dangerous)
      if [[ -n "$dangerous_flags" ]]; then
        $cmd $dangerous_flags || exit_code=$?
      else
        echo "Warning: $display_name doesn't support dangerous mode, using default" >&2
        $cmd || exit_code=$?
      fi
      ;;
    safe)
      if [[ -n "$safe_flags" ]]; then
        # Claude-specific: safe mode uses --allowedTools with tool list
        if [[ "$provider" == "claude" ]]; then
          $cmd $safe_flags "${GWT_ALLOWED_TOOLS[@]}" || exit_code=$?
        else
          $cmd $safe_flags || exit_code=$?
        fi
      else
        echo "Warning: $display_name doesn't support safe mode, using default" >&2
        $cmd || exit_code=$?
      fi
      ;;
    *)
      $cmd || exit_code=$?
      ;;
  esac
  
  # Handle failed launch
  if [[ $exit_code -ne 0 ]]; then
    echo ""
    echo "Error: $display_name failed to start (exit code: $exit_code)" >&2
    echo -n "Select a different provider? [Y/n]: "
    read -r choice
    [[ "$choice" =~ ^[Nn]$ ]] && return $exit_code
    _gwt_select_provider || return 1
    _gwt_launch_provider $mode
    return $?
  fi
}

_gwt_require_repo() {
  git rev-parse --is-inside-work-tree &>/dev/null || {
    echo "Error: Not inside a git repository" >&2
    return 1
  }
}

_gwt_main_repo()      { git worktree list --porcelain | head -1 | sed 's/^worktree //'; }
_gwt_default_branch() { git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"; }

_gwt_worktree_path() {
  local branch_name="$1"
  local repo_name=$(basename "$(_gwt_main_repo)")
  echo "$HOME/.gwt-worktrees/${repo_name}/${branch_name//\//-}"
}

_gwt_find_path() {
  local search="$1"
  local exact="" partial=()
  local wt_path="" wt_branch=""

  while IFS= read -r line; do
    [[ "$line" == worktree* ]] && wt_path="${line#worktree }"
    [[ "$line" == branch* ]] && {
      wt_branch="${line#branch refs/heads/}"
      [[ "$wt_branch" == "$search" ]] && exact="$wt_path"
      [[ "$wt_branch" == *"$search"* && -z "$exact" ]] && partial+=("$wt_path")
    }
  done <<< "$(git worktree list --porcelain)"

  [[ -n "$exact" ]] && { echo "$exact"; return 0; }

  case ${#partial[@]} in
    0) echo "Error: No worktree matches '$search'" >&2; return 1 ;;
    1) echo "${partial[1]}" ;;
    *) echo "Error: Multiple matches for '$search':" >&2
       printf '  %s\n' "${partial[@]}" >&2
       return 1 ;;
  esac
}

_gwt_is_protected() {
  local branch="$1" default=$(_gwt_default_branch)
  [[ "$branch" == "$default" || "$branch" == "main" || "$branch" == "master" ]]
}

_gwt_help() {
  cat <<'EOF'
gwt - Git worktree manager for AI coding assistants

COMMANDS
  gwt-create [-l|-b <branch>] [-d|-s] <name>   Create worktree + open AI assistant
  gwt-list                                     List worktrees with status
  gwt-switch [-d|-s] <branch>                  Switch to worktree + open AI assistant
  gwt-remove [-f] [-k] <branch>                Remove worktree and branch
  gwt-providers [name]                         List providers or set active provider

OPTIONS
  -l, --local        Create from current branch (default: main/master)
  -b <branch>        Create from specific branch
  -f, --force        Skip confirmation, remove dirty worktrees
  -k, --keep-branch  Keep the branch when removing worktree
  -h, --help         Show this help

PERMISSION MODES (provider-dependent)
  (default)          Normal mode (prompts for each tool)
  -s, --safe         Restricted tools (Claude: Read, Edit, Write, Grep, Glob, git, npm, ls, cat)
  -d, --dangerous    Skip ALL permission prompts

SUPPORTED PROVIDERS
  claude             Claude Code (default)
  opencode           OpenCode
  aider              Aider
  cursor             Cursor

CONFIGURATION
  First run:         Interactive prompt to select & save provider
  Set provider:      export GWT_PROVIDER=crush
  Config files:      ./.gwt.conf, ~/.config/gwt/config, ~/.gwt.conf

STORAGE
  ~/.gwt-worktrees/{repo}/{branch}
EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Public Commands
# ─────────────────────────────────────────────────────────────────────────────

gwt-create() {
  _gwt_require_repo || return 1

  # Parse arguments
  local base="" name="" local_branch=false mode="default"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)      _gwt_help; return 0 ;;
      -l|--local)     local_branch=true; shift ;;
      -d|--dangerous) mode="dangerous"; shift ;;
      -s|--safe)      mode="safe"; shift ;;
      -b)             base="$2"; shift 2 ;;
      -*)             echo "Error: Unknown option '$1'" >&2; return 1 ;;
      *)              name="$1"; shift ;;
    esac
  done

  [[ -z "$name" ]] && { echo "Usage: gwt-create [-l | -b <branch>] <name>" >&2; return 1; }

  # Determine base branch
  if $local_branch; then
    base=$(git branch --show-current)
  elif [[ -z "$base" ]]; then
    base=$(_gwt_default_branch)
  fi

  # Check if already checked out
  git worktree list | grep -q "\[$name\]" && {
    echo "Error: Branch '$name' already checked out in another worktree" >&2
    return 1
  }

  local wt_path=$(_gwt_worktree_path "$name")
  mkdir -p "$(dirname "$wt_path")"

  # Reuse existing worktree
  if [[ -d "$wt_path" ]]; then
    echo "Worktree exists: $wt_path"
    cd "$wt_path"
    _gwt_launch_provider $mode
    return 0
  fi

  # Create worktree
  echo "Creating: $wt_path (from $base)"
  if git show-ref --verify --quiet "refs/heads/$name"; then
    git worktree add "$wt_path" "$name"
  else
    git worktree add -b "$name" "$wt_path" "$base"
  fi || { echo "Error: Failed to create worktree" >&2; return 1; }

  cd "$wt_path"

  # Optional: install dependencies
  [[ -f "package.json" ]] && {
    echo "Found package.json. Install dependencies? [y/N]"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]] && npm install
  }

  # Optional: copy .env files
  local main_repo=$(_gwt_main_repo)
  local env_files=("${(@f)$(find "$main_repo" -name ".env" -type f 2>/dev/null)}")
  [[ ${#env_files[@]} -gt 0 && -n "${env_files[1]}" ]] && {
    echo "Found ${#env_files[@]} .env file(s) in main repo. Copy to worktree? [y/N]"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]] && {
      for env_file in "${env_files[@]}"; do
        local rel_path="${env_file#$main_repo/}"
        local target_dir="$(dirname "$rel_path")"
        [[ "$target_dir" != "." ]] && mkdir -p "$target_dir"
        cp "$env_file" "$rel_path"
      done
      echo "Copied ${#env_files[@]} .env file(s)"
    }
  }

  _gwt_launch_provider $mode
}

gwt-list() {
  [[ "$1" == "-h" || "$1" == "--help" ]] && { _gwt_help; return 0; }
  _gwt_require_repo || return 1

  local cwd=$(pwd)
  echo "\033[1mGit Worktrees:\033[0m\n"

  local wt_path="" wt_branch="" head_line="" branch_line=""
  while IFS= read -r line; do
    if [[ "$line" == worktree* ]]; then
      wt_path="${line#worktree }"
      read -r head_line
      read -r branch_line
      wt_branch=$([[ "$branch_line" == branch* ]] && echo "${branch_line#branch refs/heads/}" || echo "(detached)")

      # Build status
      local indicator="" status_text=""
      [[ "$cwd" == "$wt_path"* ]] && indicator="→ "

      # Dirty/clean
      if [[ -n "$(git -C "$wt_path" status --porcelain 2>/dev/null)" ]]; then
        status_text="\033[33m●\033[0m dirty"
      else
        status_text="\033[32m●\033[0m clean"
      fi

      # Ahead/behind
      if git -C "$wt_path" rev-parse --abbrev-ref '@{upstream}' &>/dev/null; then
        local ahead=$(git -C "$wt_path" rev-list --count '@{upstream}..HEAD' 2>/dev/null)
        local behind=$(git -C "$wt_path" rev-list --count 'HEAD..@{upstream}' 2>/dev/null)
        [[ "$ahead" -gt 0 ]] && status_text="$status_text ↑$ahead"
        [[ "$behind" -gt 0 ]] && status_text="$status_text ↓$behind"
      fi

      # Output
      if [[ -n "$indicator" ]]; then
        echo "  \033[32m$indicator$wt_branch\033[0m  $status_text"
      else
        echo "  \033[34m$wt_branch\033[0m  $status_text"
      fi
      echo "    $wt_path\n"
    fi
  done <<< "$(git worktree list --porcelain)"
}

gwt-switch() {
  _gwt_require_repo || return 1

  # Parse arguments
  local wt_branch="" mode="default"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)      _gwt_help; return 0 ;;
      -d|--dangerous) mode="dangerous"; shift ;;
      -s|--safe)      mode="safe"; shift ;;
      -*)             echo "Error: Unknown option '$1'" >&2; return 1 ;;
      *)              wt_branch="$1"; shift ;;
    esac
  done

  [[ -z "$wt_branch" ]] && { echo "Usage: gwt-switch <branch>" >&2; gwt-list; return 1; }

  local wt_path
  wt_path=$(_gwt_find_path "$wt_branch") || return 1
  cd "$wt_path"
  echo "Switched to: $wt_path"
  _gwt_launch_provider $mode
}

gwt-remove() {
  _gwt_require_repo || return 1

  # Parse arguments
  local force=false keep_branch=false wt_branch=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)        _gwt_help; return 0 ;;
      -f|--force)       force=true; shift ;;
      -k|--keep-branch) keep_branch=true; shift ;;
      -*)               echo "Error: Unknown option '$1'" >&2; return 1 ;;
      *)                wt_branch="$1"; shift ;;
    esac
  done

  [[ -z "$wt_branch" ]] && { echo "Usage: gwt-remove [-f] [-k] <branch>" >&2; gwt-list; return 1; }

  # Safety: protect main branches
  _gwt_is_protected "$wt_branch" && {
    echo "Error: Cannot remove protected branch '$wt_branch'" >&2
    return 1
  }

  local wt_path
  wt_path=$(_gwt_find_path "$wt_branch") || return 1
  local main=$(_gwt_main_repo)

  # Safety checks
  [[ "$wt_path" == "$main" ]] && { echo "Error: Cannot remove main repository" >&2; return 1; }
  [[ "$(pwd)" == "$wt_path"* ]] && { echo "Error: Cannot remove current worktree. Switch first." >&2; return 1; }

  # Get actual branch name
  local branch_to_delete=""
  while IFS= read -r line; do
    [[ "$line" == worktree* ]] && local wt="${line#worktree }"
    [[ "$line" == branch* ]] && {
      local br="${line#branch refs/heads/}"
      [[ "$wt" == "$wt_path" ]] && branch_to_delete="$br"
    }
  done <<< "$(git worktree list --porcelain)"

  # Dirty check
  [[ -n $(git -C "$wt_path" status --porcelain 2>/dev/null) ]] && ! $force && {
    echo "Warning: Uncommitted changes. Use -f to force." >&2
    return 1
  }

  # Confirm
  ! $force && {
    echo "Remove $wt_path? [y/N]"
    read -r response
    [[ ! "$response" =~ ^[Yy]$ ]] && { echo "Cancelled"; return 0; }
  }

  # Remove worktree
  git worktree remove --force "$wt_path" || { echo "Error: Failed to remove" >&2; return 1; }
  echo "Removed: $wt_path"
  git worktree prune

  # Delete branch
  if ! $keep_branch && [[ -n "$branch_to_delete" ]] && ! _gwt_is_protected "$branch_to_delete"; then
    git branch -D "$branch_to_delete" 2>/dev/null && echo "Deleted local branch: $branch_to_delete"

    # Offer to delete remote
    git fetch --prune origin 2>/dev/null
    if git show-ref --verify --quiet "refs/remotes/origin/$branch_to_delete"; then
      echo "Remote branch 'origin/$branch_to_delete' exists. Delete it? [y/N]"
      read -r response
      [[ "$response" =~ ^[Yy]$ ]] && {
        git push origin --delete "$branch_to_delete" 2>/dev/null && \
          echo "Deleted remote branch: origin/$branch_to_delete" || \
          echo "Warning: Failed to delete remote branch" >&2
      }
    fi
  fi
}

gwt-providers() {
  [[ "$1" == "-h" || "$1" == "--help" ]] && { _gwt_help; return 0; }
  
  # If provider name given, set it
  if [[ -n "$1" ]]; then
    local provider="$1"
    local info="${GWT_PROVIDERS[$provider]:-}"
    
    if [[ -z "$info" ]]; then
      echo "Error: Unknown provider '$provider'" >&2
      echo "Available: ${(k)GWT_PROVIDERS}" >&2
      return 1
    fi
    
    local cmd="${info%%|*}"
    local name="${info##*|}"
    
    if ! command -v "$cmd" &>/dev/null; then
      echo "Error: '$cmd' not found. Install $name first." >&2
      return 1
    fi
    
    # Save to config
    mkdir -p "$HOME/.config/gwt"
    echo "GWT_PROVIDER=$provider" > "$HOME/.config/gwt/config"
    export GWT_PROVIDER="$provider"
    echo "Provider set to: $name ($provider)"
    return 0
  fi
  
  # No argument - show interactive selection
  echo "\033[1mGWT Provider Configuration\033[0m\n"
  echo "Current provider: \033[32m$GWT_PROVIDER\033[0m\n"
  _gwt_list_providers
  echo ""
  
  echo -n "Select new provider? [y/N]: "
  read -r choice
  [[ "$choice" =~ ^[Yy]$ ]] && {
    _gwt_select_provider
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Zsh Completions
# ─────────────────────────────────────────────────────────────────────────────

_gwt_branches() {
  local branches=()
  while IFS= read -r line; do
    [[ "$line" == branch* ]] && branches+=("${line#branch refs/heads/}")
  done <<< "$(git worktree list --porcelain 2>/dev/null)"
  _describe 'branches' branches
}

_gwt_git_branches() {
  local branches=(${(f)"$(git branch -a --format='%(refname:short)' 2>/dev/null)"})
  _describe 'branches' branches
}

_gwt-create() {
  _arguments '-h[Help]' '--help[Help]' '-l[Local branch]' '--local[Local branch]' \
    '-d[Dangerous mode]' '--dangerous[Dangerous mode]' \
    '-s[Safe mode]' '--safe[Safe mode]' \
    '-b[Base branch]:branch:_gwt_git_branches' '1:name:'
}

_gwt-switch() {
  _arguments '-h[Help]' '--help[Help]' \
    '-d[Dangerous mode]' '--dangerous[Dangerous mode]' \
    '-s[Safe mode]' '--safe[Safe mode]' '1:branch:_gwt_branches'
}

_gwt-remove() {
  _arguments '-h[Help]' '--help[Help]' '-f[Force]' '--force[Force]' \
    '-k[Keep branch]' '--keep-branch[Keep branch]' '1:branch:_gwt_branches'
}

_gwt_provider_names() {
  local providers=(${(k)GWT_PROVIDERS})
  _describe 'providers' providers
}

# Register completions
[[ -n "$ZSH_VERSION" ]] && (( $+functions[compdef] )) && {
  compdef _gwt-create gwt-create 2>/dev/null
  compdef _gwt-switch gwt-switch 2>/dev/null
  compdef _gwt-remove gwt-remove 2>/dev/null
  compdef _gwt_provider_names gwt-providers 2>/dev/null
}
