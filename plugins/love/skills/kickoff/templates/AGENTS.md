# AGENTS.md

## Project

<What the product is, in one line.> Scope, business rules and architecture are in `docs/PROJECT.md`.

<Only the stack facts the code doesn't show, such as hosting, where migrations run and external services.>

## Commands

| Task | Command |
|---|---|
| Dev server | `<command>` |
| Full gate | `scripts/gate.sh --all` |
| Quality check | `scripts/gate.sh --eval` |
| One test | `<command>` |

The quick gate runs by itself before every commit and at the end of every turn.

## Rules

- <A project rule the code doesn't make obvious.>

## Do not touch

- `secrets/**`
- Migrations already applied in production. Create a new one instead.

## How we work

- Code goes through a `feat/<slug>` or `fix/<slug>` branch. Docs and data can be committed straight to main.
- A feature in progress has its spec in `docs/specs/<slug>.md`. Keep its checkboxes and Decisions up to date.
- Take the recommended option on reversible decisions and record it in the spec's Decisions, marked `(auto)`. Ask me with AskUserQuestion before an irreversible one, such as data model, permissions, a public contract or money.
- Don't fix problems outside the task on the way. Offer to open an issue and open it only after I say yes.
- After two failed attempts at the same problem, stop. Tell me what you tried and what the evidence ruled out, and suggest `/clear`.
- When I correct the same kind of mistake twice, propose a check that catches it (test, lint rule, type) instead of a new line in this file.
- Evidence is the command you ran plus its result line, not the whole output.

## Deploy

| Step | Command |
|---|---|
| Production, only after I confirm | `<command>` |
| Rollback | `<command>` |
| Health check | `<command>` |
