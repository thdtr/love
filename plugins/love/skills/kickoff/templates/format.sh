#!/usr/bin/env bash
# scripts/format.sh <file>   formats one file with its stack's formatter

set -uo pipefail
cd "$(dirname "$0")/.." || exit 0
file="${1#"$PWD"/}"

# directory|extensions|format command (gets the file relative to the directory)
stacks=(
  '<directory>|<ext,ext>|<format command>'
)

for line in "${stacks[@]}"; do
  IFS='|' read -r dir exts cmd <<<"$line"
  [[ "$dir" == . || "$file" == "$dir"/* ]] || continue
  [[ ",$exts," == *",${file##*.},"* ]] || continue
  rel="$file"
  [[ "$dir" == . ]] || rel="${file#"$dir"/}"
  (cd "$dir" && bash -c "$cmd \"\$1\"" _ "$rel") >/dev/null 2>&1
done
exit 0
