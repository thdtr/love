#!/usr/bin/env bash
# PreToolUse on git commit. Blocks the commit when gitleaks finds a secret
# in the staged changes. Does nothing without gitleaks.

set -uo pipefail

command -v gitleaks >/dev/null 2>&1 || exit 0
if ! command -v jq >/dev/null 2>&1; then
  echo "love: jq not found, secret scan skipped" >&2
  exit 0
fi

input="$(cat)"
cwd="$(jq -r '.cwd // empty' <<<"$input")"
cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"

commit_re='(^|[;&|[:space:](])git[[:space:]]([^;&|]*[[:space:]])?commit([[:space:];&|)]|$)'
[[ "$cmd" =~ $commit_re ]] || exit 0

root="$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0

if ! out="$(gitleaks git --pre-commit --staged --redact --no-banner 2>&1)"; then
  {
    echo "Commit blocked. gitleaks found what looks like a secret in the staged changes. Move it to an environment variable and commit again."
    tail -n 30 <<<"$out"
  } >&2
  exit 2
fi
exit 0
