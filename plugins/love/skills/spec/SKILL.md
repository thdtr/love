---
name: spec
description: With no argument, shows the inbox (decisions waiting, PRs to review, failing CI, ready work). With a feature or issue, interviews the user and writes docs/specs/<slug>.md with done criteria and verifiable vertical slices.
disable-model-invocation: true
effort: high
argument-hint: "feature description or #issue (empty shows the inbox)"
---

# spec

Feature: $ARGUMENTS

The interview and the approval go through AskUserQuestion. Without that tool, ask the same questions as plain text, at most 4, and stop until they're answered.

With no argument, follow `${CLAUDE_SKILL_DIR}/inbox.md` and stop there.

## 1. Context

- `#<n>` is an issue. Read it with `gh issue view <n> --comments`, assign it with `gh issue edit <n> --add-assignee @me` and derive the slug from its title.
- Anything else describes the feature.

Read `docs/PROJECT.md` and the code the feature touches. Use Explore for a broad search.

Size the work before asking anything.

- The change fits in one sentence. Say it doesn't need a spec, point to `/fix` (with the issue number if there is one) and stop.
- One small change with no decision about data, permissions or what the user sees. Say it doesn't need a spec, suggest plan mode or just asking for it, and stop.
- Otherwise keep going.

## 2. Interview

Open the first AskUserQuestion call by playing back your understanding in up to 5 lines (the problem, who has it, what done looks like), with "Is this right?" as the first question.

Then ask only what the code, `PROJECT.md` and `AGENTS.md` can't answer. Look facts up yourself and ask the user only for decisions. Up to 4 questions per call, each with your recommended option first, 3 rounds at most. Dig into

- what the user sees when it works and when it fails;
- who can do what;
- data changes, migrations and existing data;
- edge cases such as empty states, limits and concurrency;
- what is explicitly left out.

A vague answer on data, permissions or what the user sees gets a second, concrete question. Decide minor details yourself and record them in Decisions.

### Variants

When a decision is about taste (layout, interaction, API shape, wording) and a throwaway prototype takes minutes, offer to show 2 or 3 variants before deciding. If the user accepts, start one general-purpose subagent per variant, in parallel, each with `isolation: worktree`, a one-paragraph brief of its direction, and the instruction to build the smallest working prototype, run `/verify` on it if it has UI, and reply with the worktree path, how to run it and a screenshot path. Show the results side by side, ask which one wins, record the choice in Decisions and remove the worktrees.

## 3. Write `docs/specs/<slug>.md`

Short kebab-case slug, 120 lines at most. Use this format.

```markdown
# <Feature>

Issue: #<n>
Branch: feat/<slug>

## Problem

## Done when

- [ ] <something a user or a test can observe>

## Out of scope

## Decisions

- <data model, contracts, permission rule, migration plan>

## Slices

### 1. <end-to-end behavior>

- [ ] done
- Verify: `<command that fails without this slice>`

## Risks
```

Slice rules.

- Vertical. Each slice cuts through the data, server and UI it needs and delivers behavior that can be tested alone. Never "create tables" or "create endpoints".
- The first slice is the smallest end-to-end version. The next ones extend it.
- Each slice has a Verify command that fails without it.
- A slice that doesn't fit in one work session gets split.
- Record decisions and signatures, not code.

## 4. Builder check

Delegate to the `spec-check` subagent with the spec path and wait for its answer. Settle `detail` items yourself in Decisions. `decision` items go to the user in the approval round.

## 5. Approval

Show the file path and a summary of 5 to 10 lines (slices, plus decisions the user didn't make explicitly). In the same turn, ask with AskUserQuestion about the open `decision` items and the approval. The approval options are

- Approve, and I'll build it now;
- Approve, and leave it for a bot (offer this only when the spec meets the rules in `${CLAUDE_PLUGIN_ROOT}/skills/kickoff/reference/autonomy.md`);
- Adjust.

Record answers in the spec. After an adjustment, edit and ask again. A decision the user wants to make later stays as an open question in Decisions.

## 6. After approval

1. `git switch main`, `git pull` when there is a remote, `git switch -c feat/<slug>`, then commit the spec as `docs: spec <slug>`.
2. With a GitHub remote, push the branch with `git push -u origin feat/<slug>`. Create the issue if there isn't one (`gh issue create` with the title and a body holding a one-line problem and `Branch: feat/<slug>`), or add the `Branch:` line to the existing issue's body. Then label it, `needs-decision` if a decision is still open (with the question as a comment), otherwise `ready`.
3. Tell the user the next step. To build now, `/clear` then `/build <slug>`. To hand it off, `/bot`.
