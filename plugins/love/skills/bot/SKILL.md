---
name: bot
description: Sends ready issues to bots. Each one is built in its own container and comes back as a pull request labeled review, or as an issue labeled needs-decision.
disable-model-invocation: true
argument-hint: "[how many issues, default 1]"
---

# bot

Count: $ARGUMENTS

## 1. Check

- `.love/bot/run.sh` exists. Otherwise point to `/kickoff` and stop.
- `podman --version` and `gh auth status` work, and `~/.config/love/bot.env` exists. Otherwise give the missing steps from the Bots section of `${CLAUDE_PLUGIN_ROOT}/skills/kickoff/reference/autonomy.md` and stop.

## 2. Pick

1. Count open issues labeled `building`. Free slots are 3 minus that count. With no free slots, say so and stop.
2. List open issues labeled `ready`, oldest first (`gh issue list --label ready --state open --json number,title,body,createdAt`).
3. Take up to the requested count (default 1), limited by the free slots. Skip an issue whose body has no `Branch:` line, and say why.
4. With nothing to take, say so and suggest `/spec` to see the inbox.

## 3. Send

For each issue

1. `gh issue edit <n> --remove-label ready --add-label building`.
2. Run `.love/bot/run.sh <n>` with `run_in_background`.

Report which issues went out and that each log is in `.love/bot/logs/<n>.log`. Don't wait or poll.

## 4. When a run ends

Read the last 30 lines of its log.

- A PR was opened, or the issue is labeled `needs-decision`. Report it in one line.
- The run failed. Post a comment on the issue starting with `Bot failed`, holding the last 20 log lines in a code block, and move the label to `needs-decision`.
