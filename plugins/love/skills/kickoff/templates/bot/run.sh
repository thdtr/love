#!/usr/bin/env bash
# .love/bot/run.sh <issue>   builds one ready issue inside a container and opens its PR
#
# Needs podman, gh and ~/.config/love/bot.env (chmod 600) with
#   CLAUDE_CODE_OAUTH_TOKEN=...   from `claude setup-token`
#   GH_TOKEN=...                  fine-grained token for this repository only
#                                 (contents, issues and pull requests, read and write)

set -euo pipefail

issue="${1:?usage: run.sh <issue>}"
here="$(cd "$(dirname "$0")" && pwd)"
root="$(git -C "$here" rev-parse --show-toplevel)"
env_file="${LOVE_BOT_ENV:-$HOME/.config/love/bot.env}"
[[ -r "$env_file" ]] || { echo "Missing $env_file" >&2; exit 2; }

repo="$(cd "$root" && gh repo view --json nameWithOwner -q .nameWithOwner)"
image="love-bot-$(basename "$root" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9\n' '-')"
mkdir -p "$here/logs"
log="$here/logs/$issue.log"

podman build -q -t "$image" "$here" >/dev/null

podman run --rm -i \
  --cap-add NET_ADMIN --cap-add NET_RAW \
  --env-file "$env_file" \
  -e LOVE_BOT=1 -e REPO="$repo" -e ISSUE="$issue" \
  "$image" bash -s >"$log" 2>&1 <<'INNER'
set -euo pipefail
sudo /usr/local/bin/firewall.sh
gh auth setup-git
branch="$(gh issue view "$ISSUE" -R "$REPO" --json body -q .body | sed -n 's/^Branch: *//p' | head -1)"
[[ -n "$branch" ]] || { echo "Issue #$ISSUE has no Branch line"; exit 1; }
git clone -q --branch "$branch" "https://github.com/$REPO.git" work
cd work
git config user.name "love bot"
git config user.email "love-bot@users.noreply.github.com"
claude plugin marketplace add thdtr/love >/dev/null
claude plugin install love@love >/dev/null
deny='{"permissions":{"deny":["Bash(gh pr merge *)","Bash(git push --force*)","Bash(git push -f*)"]}}'
claude -p "/build #$ISSUE" --dangerously-skip-permissions --settings "$deny" </dev/null
labels="$(gh issue view "$ISSUE" -R "$REPO" --json labels -q '[.labels[].name] | join(",")')"
[[ ",$labels," == *",needs-decision,"* ]] && exit 0
claude -p "/ship" --dangerously-skip-permissions --settings "$deny" </dev/null
INNER
