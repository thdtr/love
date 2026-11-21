---
name: ship
description: Wraps up the current branch. Folds the spec into docs/PROJECT.md, opens the pull request with a review guide, waits for CI and merges only after the user says so.
disable-model-invocation: true
argument-hint: "[prod] to deploy to production after the merge"
---

# ship

Under `LOVE_BOT=1`, never merge and never deploy. Stop once the PR is open.

## 1. Before shipping

- The current branch isn't the default branch. Commit anything left.
- On a `feat/` branch, every slice is checked and the spec's Review section names a sha with no code commits after it. Otherwise run step 4 of the `build` skill and come back.
- On a `fix/` branch, run the `code-review` skill with `low` and fix the blockers.
- When the diff touches auth, sessions, permissions, payments, webhooks or uploads and there's an `origin` remote, also run the `security-review` skill and fix what's real.
- Run `scripts/gate.sh --all` unless it already passed on this HEAD in this session.

## 2. Fold the spec (feat/ branches)

Read the spec before changing anything, since the PR body needs it.

Update `docs/PROJECT.md` with what this feature changed for good (scope, business rules, architecture, direction). Rewrite affected lines so the file describes the current state. Don't strike text out and don't keep history, since git has it. Keep it within 80 lines.

Delete `docs/specs/<slug>.md` and commit `docs: fold <slug> into PROJECT.md`.

## 3. Pull request

Without a remote or `gh`, say there will be no CI and offer, with AskUserQuestion, a local `git switch main` and `git merge --squash <branch>`.

With a remote

1. `git fetch origin` and `git merge origin/<default branch>`. Never rebase, since the branch may already be public. Resolve conflicts keeping both sides' intent, and run the full gate again if the merge brought changes.
2. `git push -u origin HEAD`.
3. Write the PR body with the Write tool to a file outside the repository, then run `gh pr create --title "<effect of the change>" --body-file <file>` on one line. With an open PR, update it with `gh pr edit --body-file <file>`. The body has these parts, in this order.
   ```
   Risk: low | high, and why in one line

   ## Decide
   - each (auto) decision from the spec, for the user to confirm
   - each review suggestion not applied, with the reason

   ## Look at
   - 3 to 5 file:line places where judgment matters most

   ## Evidence
   - gate result line, eval result line, /verify screenshots if any

   Closes #<n>
   ```
   Risk is high when the diff touches auth, payments, permissions or a migration, or changes more than 800 lines of code. Leave out empty parts. Add `Closes #<n>` when the spec's Issue line or a commit names an issue, and move that issue's label to `review`.
4. Run `gh pr checks --watch` with `run_in_background` and wait for the notification instead of polling. Right after a push, GitHub may not have registered the checks yet and the command ends with "no checks reported". Run it again, a few times at most. If the repository has no CI at all, say so instead of calling the PR green.
5. When CI fails, read the log (`gh run view --log-failed`), fix it with the `fix` skill, push and repeat.
6. When CI is green, share the PR link and stop. The user decides the merge.

Merge only when the user asks, with `gh pr merge --squash --delete-branch`. The hook blocks it while a check is pending or failing. Then `git switch main`, `git pull` and delete the local branch. The next step is `/clear`, then `/spec` to see the inbox.

## 4. Production

Only with `$ARGUMENTS` set to `prod` or an explicit request, after the merge, following the Deploy section of `AGENTS.md`. Migrations go first, then the app, with an explicit confirmation before each production command. Run the health check and show the result. If it fails, offer the rollback from `AGENTS.md` right away, then investigate with the `fix` skill.
