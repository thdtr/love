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

new_repo() {
  repo="$tmp/repo-$RANDOM"
  git init -q -b main "$repo"
  git -C "$repo" config user.email t@example.com
  git -C "$repo" config user.name t
  git -C "$repo" config commit.gpgsign false
}

payload() { # event, last message, stop_hook_active, command
  jq -cn --arg e "$1" --arg cwd "$repo" --arg m "${2:-Finished.}" --argjson s "${3:-false}" \
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
if [[ $code == 2 && "$err" == *"Quick gate failed"* ]]; then pass "failed gate blocks the commit"; else fail "failed gate blocks the commit" "code=$code err=$err"; fi

reset_gate
LOVE_GATE=false run gate.sh "$(payload PreToolUse Finished. false 'for c in git jq; do command -v "$c"; done')"
if [[ $code == 0 && -z "$err" ]]; then pass "a command that isn't a commit is not gated"; else fail "a command that isn't a commit is not gated" "code=$code err=$err"; fi

reset_gate
LOVE_GATE=false run gate.sh "$(payload PreToolUse Finished. false 'git add app.py && git -C . commit -m "$MSG"')"
if [[ $code == 2 ]]; then pass "a commit inside a compound command is gated"; else fail "a commit inside a compound command is gated" "code=$code"; fi

reset_gate
LOVE_GATE=false run gate.sh "$(payload Stop)"
if [[ $code == 0 && "$out" == *additionalContext* ]]; then pass "a failed gate goes back to Claude on Stop"; else fail "a failed gate goes back to Claude on Stop" "code=$code out=$out"; fi

LOVE_GATE=false run gate.sh "$(payload Stop Finished. true)"
if [[ $code == 0 && -z "$out" ]]; then pass "the same failure after a block lets the turn end"; else fail "the same failure after a block lets the turn end" "code=$code out=$out"; fi

reset_gate
LOVE_GATE=false run gate.sh "$(payload Stop 'Which one do you want?')"
if [[ $code == 0 && -z "$out" ]]; then pass "a turn ending in a question is not blocked"; else fail "a turn ending in a question is not blocked" "code=$code out=$out"; fi

reset_gate
: >"$tmp/runs"
LOVE_GATE="echo run >>'$tmp/runs'" run gate.sh "$(payload Stop)"
LOVE_GATE="echo run >>'$tmp/runs'" run gate.sh "$(payload Stop)"
runs="$(wc -l <"$tmp/runs")"
if [[ $code == 0 && $runs == 1 ]]; then pass "a passing gate is not run again for the same files"; else fail "a passing gate is not run again for the same files" "code=$code runs=$runs"; fi

reset_gate
LOVE_GATE='echo "$LOVE_CHANGED" >"'"$tmp"'/changed"' run gate.sh "$(payload PreToolUse)"
if [[ $code == 0 && "$(cat "$tmp/changed")" == "app.py" ]]; then pass "the gate gets the changed files in LOVE_CHANGED"; else fail "the gate gets the changed files in LOVE_CHANGED" "code=$code changed=$(cat "$tmp/changed")"; fi

run gate.sh "$(payload PreToolUse)"
if [[ $code == 0 && -z "$err" ]]; then pass "without LOVE_GATE the gate does nothing"; else fail "without LOVE_GATE the gate does nothing" "code=$code err=$err"; fi

new_repo
mkdir -p "$repo/docs/specs"
seq 1 121 >"$repo/docs/specs/big.md"
LOVE_GATE=true run gate.sh "$(payload PreToolUse)"
if [[ $code == 2 && "$err" == *"docs/specs/big.md has 121 lines, the limit is 120"* ]]; then pass "a spec over 120 lines blocks the commit"; else fail "a spec over 120 lines blocks the commit" "code=$code err=$err"; fi

new_repo
seq 1 61 >"$repo/AGENTS.md"
seq 1 80 >"$repo/PROJECT.md"
LOVE_GATE=true run gate.sh "$(payload PreToolUse)"
if [[ $code == 2 && "$err" == *"AGENTS.md has 61 lines"* && "$err" != *"PROJECT.md"* ]]; then pass "AGENTS.md over 60 lines blocks, other files have no limit"; else fail "AGENTS.md over 60 lines blocks, other files have no limit" "code=$code err=$err"; fi

# format.sh

new_repo
echo 'x = 1' >"$repo/app.py"
file_payload="$(jq -cn --arg p "$repo/app.py" '{tool_input: {file_path: $p}}')"

rm -f "$tmp/formatted"
MARK="$tmp/formatted" LOVE_FORMAT='touch "$MARK"; true' run format.sh "$file_payload"
if [[ $code == 0 && -f "$tmp/formatted" ]]; then pass "format runs on the edited file"; else fail "format runs on the edited file" "code=$code err=$err"; fi

LOVE_FORMAT='echo boom >&2; exit 1' run format.sh "$file_payload"
if [[ $code == 0 && -z "$err" ]]; then pass "a formatter failure stays silent"; else fail "a formatter failure stays silent" "code=$code err=$err"; fi

# secrets.sh

bin="$tmp/bin"
mkdir -p "$bin"
printf '#!/usr/bin/env bash\necho "leak found"; exit 1\n' >"$bin/gitleaks"
chmod +x "$bin/gitleaks"

PATH="$bin:$PATH" run secrets.sh "$(payload PreToolUse)"
if [[ $code == 2 && "$err" == *"Commit blocked"* ]]; then pass "a secret blocks the commit"; else fail "a secret blocks the commit" "code=$code err=$err"; fi

PATH="$bin:$PATH" run secrets.sh "$(payload PreToolUse Finished. false 'echo "$HOME"')"
if [[ $code == 0 ]]; then pass "the secret scan skips commands that aren't a commit"; else fail "the secret scan skips commands that aren't a commit" "code=$code err=$err"; fi

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
if [[ $code == 2 && "$err" == *"app.py"* ]]; then pass "code committed on main is blocked"; else fail "code committed on main is blocked" "code=$code err=$err"; fi

git -C "$repo" reset -q
echo more >>"$repo/README.md"
git -C "$repo" add README.md
LOVE_GATE="$code_gate" run main-guard.sh "$(payload PreToolUse)"
if [[ $code == 0 ]]; then pass "docs committed on main pass"; else fail "docs committed on main pass" "code=$code err=$err"; fi

git -C "$repo" commit -qm docs
echo 'y = 2' >>"$repo/README.md"
echo 'x = 1' >"$repo/app.py"
git -C "$repo" add app.py && git -C "$repo" commit -qm code-sneak 2>/dev/null
echo 'x = 2' >"$repo/app.py"
LOVE_GATE="$code_gate" run main-guard.sh "$(payload PreToolUse Finished. false 'git commit -am x')"
if [[ $code == 2 ]]; then pass "git commit -a on main with modified code is blocked"; else fail "git commit -a on main with modified code is blocked" "code=$code err=$err"; fi

git -C "$repo" switch -qc feat/x
LOVE_GATE="$code_gate" run main-guard.sh "$(payload PreToolUse Finished. false 'git commit -am x')"
if [[ $code == 0 ]]; then pass "code committed on a branch passes"; else fail "code committed on a branch passes" "code=$code err=$err"; fi

git -C "$repo" switch -q main
: >"$repo/.git/SQUASH_MSG"
LOVE_GATE="$code_gate" run main-guard.sh "$(payload PreToolUse Finished. false 'git commit -am x')"
if [[ $code == 0 ]]; then pass "finishing a squash merge on main passes"; else fail "finishing a squash merge on main passes" "code=$code err=$err"; fi
rm -f "$repo/.git/SQUASH_MSG"

# merge-guard.sh

fake_gh() { # exit code, output
  printf '#!/usr/bin/env bash\necho "$*" >"%s/gh-args"\necho "%s"\nexit %s\n' "$tmp" "$2" "$1" >"$bin/gh"
  chmod +x "$bin/gh"
}

fake_gh 0 "all checks passed"
PATH="$bin:$PATH" run merge-guard.sh "$(payload PreToolUse Finished. false 'gh pr merge 12 --squash --delete-branch')"
if [[ $code == 0 && "$(cat "$tmp/gh-args")" == "pr checks 12" ]]; then pass "a merge with every check green passes"; else fail "a merge with every check green passes" "code=$code args=$(cat "$tmp/gh-args")"; fi

fake_gh 8 "build pending"
PATH="$bin:$PATH" run merge-guard.sh "$(payload PreToolUse Finished. false 'gh pr merge --squash')"
if [[ $code == 2 && "$err" == *"still running"* && "$(cat "$tmp/gh-args")" == "pr checks" ]]; then pass "a merge with a running check is blocked"; else fail "a merge with a running check is blocked" "code=$code err=$err"; fi

fake_gh 1 "build fail"
PATH="$bin:$PATH" run merge-guard.sh "$(payload PreToolUse Finished. false 'gh pr merge 12 --squash')"
if [[ $code == 2 && "$err" == *"failed"* ]]; then pass "a merge with a failing check is blocked"; else fail "a merge with a failing check is blocked" "code=$code err=$err"; fi

fake_gh 1 "no checks reported on the 'x' branch"
PATH="$bin:$PATH" run merge-guard.sh "$(payload PreToolUse Finished. false 'gh pr merge 12')"
if [[ $code == 0 ]]; then pass "a repository with no checks can merge"; else fail "a repository with no checks can merge" "code=$code err=$err"; fi

fake_gh 1 "build fail"
PATH="$bin:$PATH" run merge-guard.sh "$(payload PreToolUse Finished. false 'gh pr view 12')"
if [[ $code == 0 ]]; then pass "other gh commands are not guarded"; else fail "other gh commands are not guarded" "code=$code err=$err"; fi

echo
if ((failures == 0)); then echo "all passed"; else
  echo "$failures failed"
  exit 1
fi
