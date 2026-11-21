#!/usr/bin/env bash
# PostToolUse on Edit|Write. Formats the edited file with $LOVE_FORMAT.
# Silent: formatting never becomes feedback for the model.

set -uo pipefail

[[ -n "${LOVE_FORMAT:-}" ]] || exit 0
if ! command -v jq >/dev/null 2>&1; then
  echo "love: jq not found, formatting skipped" >&2
  exit 0
fi

file="$(jq -r '.tool_input.file_path // empty')"
[[ -n "$file" && -f "$file" ]] || exit 0
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$file")}" || exit 0

bash -c "$LOVE_FORMAT \"\$1\"" _ "$file" >/dev/null 2>&1 || true
exit 0
