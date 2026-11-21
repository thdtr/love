---
name: fix
description: Use when something is broken, such as a bug, an unexpected error or a failing test. Reproduces it, finds the root cause, fixes and verifies. Called as /fix, it also takes a small change that doesn't need a spec.
argument-hint: "symptom, the change you want, or #issue"
---

# fix

Target: $ARGUMENTS

## 0. Scope

- `#<n>` is an issue. Read it with `gh issue view <n> --comments`, assign it with `gh issue edit <n> --add-assignee @me` and move its label to `building`. Its body is the symptom or the change.
- New behavior, several modules, or a product or data decision isn't a fix. Point to `/spec` and stop.
- On the default branch, run `git pull` when there is a remote, then `git switch -c fix/<slug>`. Inside a feature in progress, stay on its branch.

## 1. Bug, root cause before any edit

1. Reproduce it with a test that fails with the symptom, or with the command that shows it. In a project without tests, reproduce it through the command or the running app (`/verify`) and write a test that pins the current behavior when you can. Without a reproduction, don't fix anything. Say what's missing to reproduce it.
2. Find it by reading the code along the symptom's path. Use Explore for a broad search.
3. State the cause in 1 to 3 lines, with `file:line` and why it produces the symptom. Then fix it, unless the fix touches Do not touch in `AGENTS.md` or changes a public contract. In that case ask with AskUserQuestion first.
4. Fix the cause, not the symptom. No silenced errors, `as any`, `@ts-ignore`, skipped tests or loosened assertions.
5. Run the reproduction and the related tests.

After two attempts without solving it, stop. Write down what you tried, what each attempt assumed and what the evidence ruled out. Name the shared assumption nobody checked yet and suggest `/clear` with that summary.

## 2. Small change

Make the edit and run whatever check exists (test, build, running app).

## 3. Commit

`fix: <effect>` or `chore: <effect>`, without asking. When it came from an issue, end the subject with `(#<n>)`. Outside a feature in progress, the next step is `/ship`.
