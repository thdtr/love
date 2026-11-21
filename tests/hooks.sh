#!/usr/bin/env bash
# Feeds each hook script the JSON Claude Code sends and checks the result.
#   bash tests/hooks.sh

set -uo pipefail

scripts="$(cd "$(dirname "$0")/../plugins/love/scripts" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
failures=0

pass() { echo "ok   $1"; }
fail() {
  echo "FAIL $1"
  echo "     $2"
  failures=$((failures + 1))
}
check() { # name, condition result, detail
  if [[ "$2" == 0 ]]; then pass "$1"; else fail "$1" "$3"; fi
}

new_repo() {
  repo="$tmp/repo-$RANDOM"
  git init -q -b main "$repo"
  git -C "$repo" config user.email t@example.com
  git -C "$repo" config user.name t
  git -C "$repo" config commit.gpgsign false
}

payload() { # event, last message, stop_hook_active, command
  jq -cn --arg e "$1" --arg cwd "$repo" --arg m "${2:-done}" --argjson s "${3:-false}" \
    --arg c "${4:-git commit -m x}" \
    '{hook_event_name: $e, cwd: $cwd, last_assistant_message: $m, stop_hook_active: $s, tool_input: {command: $c}}'
}

run() { # script, stdin. Sets code, out, err.
  out="$(printf '%s' "$2" | bash "$scripts/$1" 2>"$tmp/err")"
  code=$?
  err="$(<"$tmp/err")"
}

reset_gate() { rm -f "$repo/.git/love-gate-ok" "$repo/.git/love-gate-fail"; }

# gate.sh

new_repo
echo 'x = 1' >"$repo/app.py"

LOVE_GATE=false run gate.sh "$(payload PreToolUse)"
[[ $code == 2 && "$err" == *"Quick gate failed"* ]]
check "failed gate blocks the commit" $? "code=$code err=$err"

reset_gate
LOVE_GATE=false run gate.sh "$(payload PreToolUse done false 'for c in git jq; do command -v "$c"; done')"
[[ $code == 0 && -z "$err" ]]
check "a command that isn't a commit is not gated" $? "code=$code err=$err"

reset_gate
LOVE_GATE=false run gate.sh "$(payload PreToolUse done false 'git add app.py && git -C . commit -m "$MSG"')"
[[ $code == 2 ]]
check "a commit inside a compound command is gated" $? "code=$code"

reset_gate
LOVE_GATE=false run gate.sh "$(payload Stop)"
[[ $code == 0 && "$out" == *additionalContext* ]]
check "a failed gate goes back to Claude on Stop" $? "code=$code out=$out"

LOVE_GATE=false run gate.sh "$(payload Stop done true)"
[[ $code == 0 && -z "$out" ]]
check "the same failure after a block lets the turn end" $? "code=$code out=$out"

reset_gate
LOVE_GATE=false run gate.sh "$(payload Stop 'Which one do you want?')"
[[ $code == 0 && -z "$out" ]]
check "a turn ending in a question is not blocked" $? "code=$code out=$out"

reset_gate
: >"$tmp/runs"
LOVE_GATE="echo run >>'$tmp/runs'" run gate.sh "$(payload Stop)"
LOVE_GATE="echo run >>'$tmp/runs'" run gate.sh "$(payload Stop)"
runs="$(wc -l <"$tmp/runs")"
[[ $code == 0 && $runs == 1 ]]
check "a passing gate is not run again for the same files" $? "code=$code runs=$runs"

reset_gate
LOVE_GATE='echo "$LOVE_CHANGED" >"'"$tmp"'/changed"' run gate.sh "$(payload PreToolUse)"
[[ $code == 0 && "$(cat "$tmp/changed")" == "app.py" ]]
check "the gate gets the changed files in LOVE_CHANGED" $? "code=$code changed=$(cat "$tmp/changed")"

run gate.sh "$(payload PreToolUse)"
[[ $code == 0 && -z "$err" ]]
check "without LOVE_GATE the gate does nothing" $? "code=$code err=$err"

new_repo
mkdir -p "$repo/docs/specs"
seq 1 121 >"$repo/docs/specs/big.md"
LOVE_GATE=true run gate.sh "$(payload PreToolUse)"
[[ $code == 2 && "$err" == *"docs/specs/big.md has 121 lines, the limit is 120"* ]]
check "a spec over 120 lines blocks the commit" $? "code=$code err=$err"

new_repo
seq 1 61 >"$repo/AGENTS.md"
seq 1 80 >"$repo/PROJECT.md"
LOVE_GATE=true run gate.sh "$(payload PreToolUse)"
[[ $code == 2 && "$err" == *"AGENTS.md has 61 lines"* && "$err" != *"PROJECT.md"* ]]
check "AGENTS.md over 60 lines blocks, other files have no limit" $? "code=$code err=$err"

# format.sh

new_repo
echo 'x = 1' >"$repo/app.py"
file_payload="$(jq -cn --arg p "$repo/app.py" '{tool_input: {file_path: $p}}')"

rm -f "$tmp/formatted"
MARK="$tmp/formatted" LOVE_FORMAT='touch "$MARK"; true' run format.sh "$file_payload"
[[ $code == 0 && -f "$tmp/formatted" ]]
check "format runs on the edited file" $? "code=$code err=$err"

LOVE_FORMAT='echo boom >&2; exit 1' run format.sh "$file_payload"
[[ $code == 0 && -z "$err" ]]
check "a formatter failure stays silent" $? "code=$code err=$err"

# secrets.sh

bin="$tmp/bin"
mkdir -p "$bin"
printf '#!/usr/bin/env bash\necho "leak found"; exit 1\n' >"$bin/gitleaks"
chmod +x "$bin/gitleaks"

PATH="$bin:$PATH" run secrets.sh "$(payload PreToolUse)"
[[ $code == 2 && "$err" == *"Commit blocked"* ]]
check "a secret blocks the commit" $? "code=$code err=$err"

PATH="$bin:$PATH" run secrets.sh "$(payload PreToolUse done false 'echo "$HOME"')"
[[ $code == 0 ]]
check "the secret scan skips commands that aren't a commit" $? "code=$code err=$err"

# main-guard.sh

code_gate="$tmp/code-gate.sh"
cat >"$code_gate" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" == --code ]] || exit 0
for f in $LOVE_CHANGED; do [[ "$f" == *.py ]] && echo "$f"; done
exit 0
EOF
chmod +x "$code_gate"

new_repo
echo seed >"$repo/README.md"
git -C "$repo" add README.md && git -C "$repo" commit -qm seed
echo 'x = 1' >"$repo/app.py"
git -C "$repo" add app.py
LOVE_GATE="$code_gate" run main-guard.sh "$(payload PreToolUse)"
[[ $code == 2 && "$err" == *"app.py"* ]]
check "code committed on main is blocked" $? "code=$code err=$err"

git -C "$repo" reset -q
echo more >>"$repo/README.md"
git -C "$repo" add README.md
LOVE_GATE="$code_gate" run main-guard.sh "$(payload PreToolUse)"
[[ $code == 0 ]]
check "docs committed on main pass" $? "code=$code err=$err"

git -C "$repo" commit -qm docs
echo 'y = 2' >>"$repo/README.md"
echo 'x = 1' >"$repo/app.py"
git -C "$repo" add app.py && git -C "$repo" commit -qm code-sneak 2>/dev/null
echo 'x = 2' >"$repo/app.py"
LOVE_GATE="$code_gate" run main-guard.sh "$(payload PreToolUse done false 'git commit -am x')"
[[ $code == 2 ]]
check "git commit -a on main with modified code is blocked" $? "code=$code err=$err"

git -C "$repo" switch -qc feat/x
LOVE_GATE="$code_gate" run main-guard.sh "$(payload PreToolUse done false 'git commit -am x')"
[[ $code == 0 ]]
check "code committed on a branch passes" $? "code=$code err=$err"

git -C "$repo" switch -q main
: >"$repo/.git/SQUASH_MSG"
LOVE_GATE="$code_gate" run main-guard.sh "$(payload PreToolUse done false 'git commit -am x')"
[[ $code == 0 ]]
check "finishing a squash merge on main passes" $? "code=$code err=$err"
rm -f "$repo/.git/SQUASH_MSG"

# merge-guard.sh

fake_gh() { # exit code, output
  printf '#!/usr/bin/env bash\necho "$*" >"%s/gh-args"\necho "%s"\nexit %s\n' "$tmp" "$2" "$1" >"$bin/gh"
  chmod +x "$bin/gh"
}

fake_gh 0 "all checks passed"
PATH="$bin:$PATH" run merge-guard.sh "$(payload PreToolUse done false 'gh pr merge 12 --squash --delete-branch')"
[[ $code == 0 && "$(cat "$tmp/gh-args")" == "pr checks 12" ]]
check "a merge with every check green passes" $? "code=$code args=$(cat "$tmp/gh-args")"

fake_gh 8 "build pending"
PATH="$bin:$PATH" run merge-guard.sh "$(payload PreToolUse done false 'gh pr merge --squash')"
[[ $code == 2 && "$err" == *"still running"* && "$(cat "$tmp/gh-args")" == "pr checks" ]]
check "a merge with a running check is blocked" $? "code=$code err=$err"

fake_gh 1 "build fail"
PATH="$bin:$PATH" run merge-guard.sh "$(payload PreToolUse done false 'gh pr merge 12 --squash')"
[[ $code == 2 && "$err" == *"failed"* ]]
check "a merge with a failing check is blocked" $? "code=$code err=$err"

fake_gh 1 "no checks reported on the 'x' branch"
PATH="$bin:$PATH" run merge-guard.sh "$(payload PreToolUse done false 'gh pr merge 12')"
[[ $code == 0 ]]
check "a repository with no checks can merge" $? "code=$code err=$err"

fake_gh 1 "build fail"
PATH="$bin:$PATH" run merge-guard.sh "$(payload PreToolUse done false 'gh pr view 12')"
[[ $code == 0 ]]
check "other gh commands are not guarded" $? "code=$code err=$err"

echo
if ((failures == 0)); then echo "all passed"; else
  echo "$failures failed"
  exit 1
fi
