#!/usr/bin/env bash
# Tests for the gate.sh and format.sh templates that /kickoff copies into a project.
#   bash tests/templates.sh

set -uo pipefail

templates="$(cd "$(dirname "$0")/../plugins/love/skills/kickoff/templates" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
failures=0
pass() { echo "ok   $1"; }
fail() {
  echo "FAIL $1"
  echo "     $2"
  failures=$((failures + 1))
}

repo="$tmp/repo"
mkdir -p "$repo/scripts" "$repo/api/pkg" "$repo/app/lib"
log="$tmp/log"

# Two stacks whose checks record which ran, where, and with which files.
make_gate() { # api quick check, eval check
  python3 - "$templates/gate.sh" "$repo/scripts/gate.sh" "$1" "$2" "$log" <<'PY2'
import sys
src, dst, api_quick, eval_check, log = sys.argv[1:]
text = open(src).read()
lines = (f"'api|api|go|{api_quick}|echo api full >>{log}' "
         f"'app|app|dart|echo app quick $PWD $LOVE_CHANGED >>{log}|echo app full >>{log}'")
text = text.replace("'<name>|<directory>|<ext,ext>|<quick check>|<full check>'", lines)
text = text.replace('eval_check=""', f'eval_check="{eval_check}"')
open(dst, "w").write(text)
PY2
}
make_gate 'echo api quick $PWD $LOVE_CHANGED >>'"$log" ""

gate() {
  : >"$log"
  out="$(cd "$repo" && LOVE_CHANGED="$1" bash scripts/gate.sh ${2:+"$2"} 2>&1)"
  code=$?
  ran="$(cat "$log")"
}

gate "api/pkg/a.go api/b.go"
if [[ $code == 0 && "$ran" == "api quick "*"/api pkg/a.go b.go" ]]; then pass "the quick gate runs only the touched stack, inside it, with its own paths"; else fail "the quick gate runs only the touched stack" "code=$code ran=$ran out=$out"; fi

gate "README.md api/notes.md"
if [[ $code == 0 && -z "$ran" ]]; then pass "files outside every stack run nothing"; else fail "files outside every stack run nothing" "code=$code ran=$ran"; fi

gate "" --all
if [[ $code == 0 && "$ran" == *"api full"* && "$ran" == *"app full"* && "$ran" != *quick* ]]; then pass "--all runs every stack's full check"; else fail "--all runs every stack's full check" "code=$code ran=$ran"; fi

gate "" app
if [[ $code == 0 && "$ran" == "app full" ]]; then pass "a stack name runs only that full check"; else fail "a stack name runs only that full check" "code=$code ran=$ran"; fi

gate "" nope
if [[ $code == 2 && "$out" == *"Unknown stack"* ]]; then pass "an unknown stack fails"; else fail "an unknown stack fails" "code=$code out=$out"; fi

gate "api/b.go README.md app/lib/main.dart docs/x.md" --code
if [[ $code == 0 && "$out" == $'api/b.go\napp/lib/main.dart' && -z "$ran" ]]; then pass "--code lists only files that belong to a stack"; else fail "--code lists only files that belong to a stack" "code=$code out=$out"; fi

gate "" --eval
if [[ $code == 0 && "$out" == *"No quality check"* ]]; then pass "--eval without a quality check passes"; else fail "--eval without a quality check passes" "code=$code out=$out"; fi

make_gate "exit 1" "exit 3"
gate "api/b.go"
if [[ $code != 0 ]]; then pass "a failing check fails the gate"; else fail "a failing check fails the gate" "code=$code"; fi

gate "" --eval
if [[ $code == 3 ]]; then pass "--eval returns the quality check's result"; else fail "--eval returns the quality check's result" "code=$code"; fi

# A single stack at the root.
python3 - "$templates/gate.sh" "$repo/scripts/gate.sh" "$log" <<'PY2'
import sys
src, dst, log = sys.argv[1:]
text = open(src).read().replace("'<name>|<directory>|<ext,ext>|<quick check>|<full check>'", f"'py|.|py|echo root $LOVE_CHANGED >>{log}|true'")
open(dst, "w").write(text)
PY2
gate "src/a.py README.md"
if [[ $code == 0 && "$ran" == "root src/a.py" ]]; then pass "a root stack gets paths relative to the root"; else fail "a root stack gets paths relative to the root" "code=$code ran=$ran"; fi

# format.sh
python3 - "$templates/format.sh" "$repo/scripts/format.sh" "$log" <<'PY2'
import sys
src, dst, log = sys.argv[1:]
text = open(src).read().replace("'<directory>|<ext,ext>|<format command>'", f"'api|go|echo api >>{log}; echo' 'app|dart|echo app >>{log}; echo'")
open(dst, "w").write(text)
PY2

: >"$log"
(cd "$repo" && bash scripts/format.sh "$repo/app/lib/main.dart")
if [[ "$(cat "$log")" == "app" ]]; then pass "format picks the stack by directory and extension"; else fail "format picks the stack by directory and extension" "log=$(cat "$log")"; fi

: >"$log"
(cd "$repo" && bash scripts/format.sh "$repo/api/notes.md")
if [[ -z "$(cat "$log")" ]]; then pass "format ignores other extensions"; else fail "format ignores other extensions" "log=$(cat "$log")"; fi

echo
if ((failures == 0)); then echo "all passed"; else
  echo "$failures failed"
  exit 1
fi
