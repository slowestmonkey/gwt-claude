#!/bin/sh
set -e

GWT_DIR="$HOME/.gwt"
ZSHRC="$HOME/.zshrc"

echo "Installing gwt..."

# Check for zsh
if ! command -v zsh >/dev/null 2>&1; then
  echo "Error: zsh is required but not installed."
  exit 1
fi

# Check for git
if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required but not installed."
  exit 1
fi

# Clone or update
if [ -d "$GWT_DIR" ]; then
  echo "Updating existing installation..."
  git -C "$GWT_DIR" pull --quiet
else
  echo "Cloning to $GWT_DIR..."
  git clone --quiet https://github.com/slowestmonkey/gwt.git "$GWT_DIR"
fi

# Add to .zshrc if not already present
if ! grep -q 'source.*\.gwt/gwt\.zsh' "$ZSHRC" 2>/dev/null; then
  echo "" >> "$ZSHRC"
  echo "# gwt - Git Worktree Manager" >> "$ZSHRC"
  echo "source \"\$HOME/.gwt/gwt.zsh\"" >> "$ZSHRC"
  echo "Added to $ZSHRC"
else
  echo "Already in $ZSHRC"
fi

echo ""
echo "Done! Restart your shell or run:"
echo "  source ~/.zshrc"
