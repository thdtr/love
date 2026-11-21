#!/usr/bin/env bash
# PreToolUse on gh pr merge. Blocks the merge while any check is pending
# or failing. A repository with no checks at all is let through.

set -uo pipefail

command -v gh >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
cwd="$(jq -r '.cwd // empty' <<<"$input")"
cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"

merge_re='(^|[;&|[:space:]])gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)'
[[ "$cmd" =~ $merge_re ]] || exit 0

cd "${cwd:-.}" 2>/dev/null || exit 0

# The PR is a number or URL after "merge". Without one, gh uses the
# current branch.
pr=""
read -ra words <<<"${cmd#*pr merge}"
for w in "${words[@]}"; do
  [[ "$w" =~ ^#?[0-9]+$ || "$w" =~ ^https:// ]] && { pr="${w#\#}"; break; }
  [[ "$w" =~ ^[\;\&\|] ]] && break
done

out="$(gh pr checks ${pr:+"$pr"} 2>&1)"
code=$?
((code == 0)) && exit 0
grep -qi 'no checks reported' <<<"$out" && exit 0

if ((code == 8)); then
  reason="Some checks are still running. Wait for them with gh pr checks --watch and merge after they pass."
else
  reason="Some checks failed. Read the log with gh run view --log-failed and fix it before merging."
fi
{
  echo "Merge blocked. $reason"
  tail -n 20 <<<"$out"
} >&2
exit 2
