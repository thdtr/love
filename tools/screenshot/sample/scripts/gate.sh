#!/usr/bin/env bash
# scripts/gate.sh            quick check of the stacks that LOVE_CHANGED touches
# scripts/gate.sh --all      full check of every stack
# scripts/gate.sh <stack>    full check of one stack
# scripts/gate.sh --code     lists the files in LOVE_CHANGED that belong to a stack
# scripts/gate.sh --eval     quality check

set -euo pipefail
cd "$(dirname "$0")/.."

# name|directory|extensions|quick check|full check
# The quick check gets LOVE_CHANGED with that stack's files, relative to its directory.
stacks=(
  'web|.|ts,tsx|pnpm exec tsc --noEmit --incremental && pnpm exec eslint --max-warnings=0 --no-warn-ignored $LOVE_CHANGED && pnpm exec vitest related --run --passWithNoTests $LOVE_CHANGED|pnpm lint && pnpm typecheck && pnpm test && pnpm build'
)
eval_check="pnpm exec playwright test e2e/critical"

target="${1:-}"

if [[ "$target" == --eval ]]; then
  [[ -n "$eval_check" ]] || { echo "No quality check set in scripts/gate.sh."; exit 0; }
  bash -c "$eval_check"
  exit
fi

ran=0
failed=0
for line in "${stacks[@]}"; do
  IFS='|' read -r name dir exts quick full <<<"$line"
  files=()
  for f in ${LOVE_CHANGED:-}; do
    [[ "$dir" == . || "$f" == "$dir"/* ]] || continue
    [[ ",$exts," == *",${f##*.},"* ]] || continue
    if [[ "$dir" == . ]]; then files+=("$f"); else files+=("${f#"$dir"/}"); fi
  done

  case "$target" in
    --code)
      for f in "${files[@]}"; do
        if [[ "$dir" == . ]]; then echo "$f"; else echo "$dir/$f"; fi
      done
      continue
      ;;
    "")
      ((${#files[@]})) || continue
      cmd="$quick"
      ;;
    --all | "$name") cmd="$full" ;;
    *) continue ;;
  esac

  ran=1
  echo "== $name"
  if ! (cd "$dir" && LOVE_CHANGED="${files[*]}" bash -c "$cmd"); then
    failed=1
  fi
done

if [[ -n "$target" && "$target" != --all && "$target" != --code && $ran == 0 ]]; then
  echo "Unknown stack $target" >&2
  exit 2
fi
exit "$failed"
