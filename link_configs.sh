#!/bin/bash

# ── Symlink config/* ───────────────────────────────────────────
SOURCE_DIR="$HOME/dotfiles/config"
TARGET_DIR="$HOME/.config"

for path in "$SOURCE_DIR"/*/; do
  [ -d "$path" ] || continue
  folder=$(basename "$path")
  ln -sfn "$path" "$TARGET_DIR/$folder"
done

# ── Symlink shell config ───────────────────────────────────────
SHELL_DOTFILES="$HOME/dotfiles/shell"
ln -sfn "$SHELL_DOTFILES/zshenv" "$HOME/.zshenv"
ln -sfn "$SHELL_DOTFILES/zshrc" "$HOME/.zshrc"
