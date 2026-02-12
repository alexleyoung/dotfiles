#!/bin/bash

# link.sh - symlink app configs to ~/.config
# Run from the directory containing config folders

set -euo pipefail

for dir in */; do
    [ -d "$dir" ] || continue  # ensure it's a directory
    basename=$(basename "$dir")
    target="$HOME/.config/$basename"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "Warning: $target exists and is not a symlink, skipping"
        continue
    fi

    ln -sfn "$(pwd)/$dir" "$target"
    echo "Linked: $dir -> $target"
done
