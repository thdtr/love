#!/usr/bin/env bash
# Quick gate. PreToolUse on git commit (blocks with exit 2) and Stop
# (sends the failure back as additionalContext).
# Runs $LOVE_GATE with LOVE_CHANGED set to the changed files, and checks
# the size of the docs agents read.

set -uo pipefail

[[ -n "${LOVE_GATE:-}" ]] || exit 0
if ! command -v jq >/dev/null 2>&1; then
  echo "love: jq not found, quick gate skipped" >&2
  exit 0
fi

input="$(cat)"
event="$(jq -r '.hook_event_name // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"
stop_active="$(jq -r '.stop_hook_active // false' <<<"$input")"
last_msg="$(jq -r '.last_assistant_message // empty' <<<"$input")"

# The "if" filter is best effort, so check for a real commit.
if [[ "$event" == PreToolUse ]]; then
  cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"
  commit_re='(^|[;&|[:space:](])git[[:space:]]([^;&|]*[[:space:]])?commit([[:space:];&|)]|$)'
  [[ "$cmd" =~ $commit_re ]] || exit 0
fi

# A turn that ends with a question for the user is left alone.
trimmed="${last_msg%"${last_msg##*[![:space:]]}"}"
[[ "$event" == Stop && "$trimmed" == *"?" ]] && exit 0

root="$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0

mapfile -t changed < <(
  git -c core.quotepath=off status --porcelain -uall 2>/dev/null |
    sed -E 's/^.{3}//; s/.* -> //' | sort -u
)
((${#changed[@]})) || exit 0
existing=()
for f in "${changed[@]}"; do [[ -f "$f" ]] && existing+=("$f"); done

git_dir="$(git rev-parse --absolute-git-dir)"
ok_file="$git_dir/love-gate-ok"
fail_file="$git_dir/love-gate-fail"
hash="$(
  {
    printf '%s\n' "${changed[@]}"
    ((${#existing[@]})) && cat -- "${existing[@]}"
    printf '%s' "$LOVE_GATE"
  } 2>/dev/null | git hash-object --stdin
)"

[[ "$hash" == "$(cat "$ok_file" 2>/dev/null)" ]] && exit 0
# Same failure as the last block: let the turn end instead of looping.
[[ "$stop_active" == true && "$hash" == "$(cat "$fail_file" 2>/dev/null)" ]] && exit 0

limit_for() {
  case "$1" in
    AGENTS.md) echo 60 ;;
    docs/PROJECT.md) echo 80 ;;
    docs/specs/*.md) echo 120 ;;
    *) echo 0 ;;
  esac
}

msg=""
for f in "${existing[@]}"; do
  max="$(limit_for "$f")"
  ((max)) || continue
  lines="$(wc -l <"$f")"
  ((lines > max)) && msg+="$f has $lines lines, the limit is $max."$'\n'
done
if [[ -n "$msg" ]]; then
  msg+="Cut what the code, the tests or git history already say. Don't move the text to another file."
else
  if out="$(LOVE_CHANGED="${existing[*]:-}" bash -c "$LOVE_GATE" 2>&1)"; then
    echo "$hash" >"$ok_file"
    rm -f "$fail_file"
    exit 0
  fi
  msg="Quick gate failed. Fix the cause. Don't weaken tests or silence errors."$'\n'"$(tail -n 60 <<<"$out")"
fi

echo "$hash" >"$fail_file"
if [[ "$event" == Stop ]]; then
  jq -n --arg c "$msg" '{hookSpecificOutput: {hookEventName: "Stop", additionalContext: $c}}'
  exit 0
fi
echo "$msg" >&2
exit 2
