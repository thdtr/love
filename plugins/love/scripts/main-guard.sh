#!/usr/bin/env bash
# PreToolUse on git commit. On the default branch, blocks a commit that
# includes code. Code is whatever `$LOVE_GATE --code` lists. Docs and data
# can go straight to main.

set -uo pipefail

[[ -n "${LOVE_GATE:-}" ]] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
cwd="$(jq -r '.cwd // empty' <<<"$input")"
cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"

commit_re='(^|[;&|[:space:](])git[[:space:]]([^;&|]*[[:space:]])?commit([[:space:];&|)]|$)'
[[ "$cmd" =~ $commit_re ]] || exit 0

root="$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0

branch="$(git symbolic-ref --short -q HEAD)" || exit 0
default="$(git symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null)"
default="${default#origin/}"
if [[ -z "$default" ]]; then
  default=main
  git show-ref -q --verify refs/heads/main || { git show-ref -q --verify refs/heads/master && default=master; }
fi
[[ "$branch" == "$default" ]] || exit 0

# Finishing a merge of another branch is allowed.
git_dir="$(git rev-parse --absolute-git-dir)"
[[ -f "$git_dir/MERGE_HEAD" || -f "$git_dir/SQUASH_MSG" ]] && exit 0

mapfile -t files < <(git diff --cached --name-only)
# git commit -a also takes modified tracked files.
if [[ "$cmd" =~ (^|[[:space:]])(-[[:alnum:]]*a[[:alnum:]]*|--all)([[:space:]]|$) ]]; then
  mapfile -t -O "${#files[@]}" files < <(git diff --name-only)
fi
((${#files[@]})) || exit 0

code="$(LOVE_CHANGED="${files[*]}" bash -c "$LOVE_GATE --code" 2>/dev/null)" || exit 0
[[ -n "$code" ]] || exit 0

{
  echo "Commit blocked. You're on $branch and these files are code:"
  echo "$code"
  echo "Create a branch first (git switch -c fix/<slug> or feat/<slug>) and commit there."
} >&2
exit 2
