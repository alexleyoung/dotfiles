#!/bin/bash

# list and open recent nvim files using fzf
# copied from https://www.youtube.com/watch?v=CbMbGV9GT8I&t=197s

list_oldfiles() {
  local oldfiles=($(nvim -u NONE --headless +'lua io.write(table.concat(vim.v.oldfiles, "\n") .. "\n")' +qa))

  local valid_files=()
  for file in "${oldfiles[@]}"; do
    if [[ -f "$file" ]]; then
      valid_files+=("$file")
    fi
  done

  local files=($(printf "%s\n" "${valid_files[@]}" | \
    grep -v '\[.*' | \
    fzf --multi \
    --preview 'bat -n --color=always --line-range=:500 {} 2>/dev/null || echo "Error previewing file"' \
    --height=70% \
    --layout=default))

  [[ ${#files[@]} -gt 0 ]] && nvim "${files[@]}"
}

list_oldfiles "$@"
