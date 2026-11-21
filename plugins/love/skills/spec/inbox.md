# Inbox

Show everything that waits for the user in one message, then resolve it in batches. Skip any section that's empty, without comment.

## Without GitHub

If there's no GitHub remote or `gh` fails, list the local `feat/*` and `fix/*` branches, with each spec's checked and total slices, and the goals in Direction of `docs/PROJECT.md` that have no branch. Ask which one to pick up and stop.

## With GitHub

Gather these with `gh`.

1. Decisions. `gh issue list --label needs-decision --state open --json number,title`, and for each one the last comment (`gh issue view <n> --comments`), which holds the question and the recommended answer.
2. PRs to review. `gh pr list --state open --json number,title,headRefName,isDraft,statusCheckRollup,url`. For each, the check state (passing, running, failing) and the Risk line of its body.
3. Counts of issues labeled `ready` and `building`.
4. Goals in Direction of `docs/PROJECT.md` with no open issue.

Show them as short lists with numbers and links. Then work through them in this order, with AskUserQuestion, up to 4 questions per call.

1. Each decision, with the recommended answer as the first option. Post the answer as a comment on the issue, then move the label from `needs-decision` to `ready`.
2. Each PR with every check passing. Options are merge now, I'll review it first, and send it back. Merge with `gh pr merge <n> --squash --delete-branch`. Send it back by asking what to change, posting that as a comment on its issue and moving the issue label to `ready`.
3. Failing PRs. Offer to fix one now with `/fix`.
4. With `ready` issues and fewer than 3 `building`, offer `/bot`.
5. Offer to spec the next goal or a free issue.
