---
name: build
description: Builds an approved spec from docs/specs/, one slice at a time, with a test and a commit per slice, and ends with an independent review.
disable-model-invocation: true
argument-hint: "spec slug or #issue (empty uses the feat/<slug> branch)"
---

# build

Target: $ARGUMENTS

Without AskUserQuestion, or when `LOVE_BOT=1`, nobody is watching. Follow the bot rules in step 3.

## 1. Load

- `#<n>` is an issue. Read it with `gh issue view <n> --comments`. The branch is in its `Branch:` line. Fetch and switch to it.
- A slug means `feat/<slug>`. Switch to it if needed.
- With no argument, take the slug from the current `feat/<slug>` branch.

Open `docs/specs/<slug>.md`. With no spec, or a spec without slices, point to `/spec` and stop.

Copy into Decisions any answer the issue comments hold that the spec doesn't have yet. With an issue, move its label to `building` (`gh issue edit <n> --remove-label ready --add-label building`).

## 2. Each unchecked slice, in order

1. Write or adjust the test for the slice's behavior and watch it fail for the right reason.
2. Write the least code that makes it pass, following `AGENTS.md`. The quick gate runs by itself before each commit and at the end of each turn. Fix what it reports.
3. Run the slice's Verify command. For a slice with UI, also check it in the running app with `/verify`.
4. Check the slice's box and commit `feat(<slug>): <observable effect>` without asking.

An unexpected bug on the way gets the `fix` skill (root cause before the fix), then you return to the slice.

## 3. When the spec isn't enough

- A reversible choice. Take the recommended option and add it to Decisions marked `(auto)`.
- An irreversible choice (data model, permissions, public contract, money, deleting data). Ask with AskUserQuestion and record the answer in Decisions.
- A slice bigger than expected. Split it in the spec before going on.

Bot rules for an irreversible choice. Commit what's done and push. Post a comment on the issue that starts with `Decision needed`, states the question in one line, lists 2 to 4 options with the recommended one first and says what each one changes. Move the label to `needs-decision` and stop.

## 4. Finish

With every slice checked

1. Run `scripts/gate.sh --all`, then `scripts/gate.sh --eval`. Fix what fails.
2. Delegate to the `reviewer` subagent with the spec path and the base branch (the remote's default, or `main`). When the diff touches auth, payments, permissions or a migration, or changes more than 800 lines of code, also run the `code-review` skill with `high`, in parallel.
3. Fix every blocker with the `fix` skill. Skip findings that don't affect correctness or the spec.
4. Check the Done when items you verified. Add a `## Review` section to the spec with `<short HEAD sha>, no blockers` and the suggestions you didn't apply, one line each with the reason. Commit.
5. Next step is `/ship`. Under `LOVE_BOT=1`, stop here, since the bot runs `/ship` next.
