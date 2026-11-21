# Adopting an existing project

The previous workflow's files don't stay next to love. Everything below goes into the step 4 plan, and nothing changes before the user confirms.

## Inventory

Look for what other workflows and agents left behind.

- Agent instructions such as `CLAUDE.md` content, an `AGENTS.md` love didn't write, `.cursorrules`, `.cursor/rules/`, `.windsurfrules`, `.clinerules`, `GEMINI.md`, `.github/copilot-instructions.md`, `.github/instructions/`, `.kiro/`.
- Spec and planning kits such as `openspec/`, `.specify/`, `memory-bank/`, and `specs/` or `docs/specs/` in another format.
- Plans and lists such as `docs/plans/`, `plans/`, `TODO.md`, `ROADMAP.md`, `docs/adr/`, and loose docs about how the product should behave.
- Skills, agents or hooks in `.claude/` that do the same job as love (spec, build, fix, ship, review, formatting, a Stop gate).

## Where each item goes

| Content | Destination |
|---|---|
| A fact that changes how an agent works here and the code doesn't show | `AGENTS.md`, within its 60 lines |
| A rule that only applies to some paths | `.claude/rules/<name>.md` with `paths:` |
| A business invariant (prices, permissions, states, limits) | Business rules in `docs/PROJECT.md`, one line with its origin |
| An architecture decision that still holds | Architecture in `docs/PROJECT.md` |
| A pending plan, TODO or idea | Direction in `docs/PROJECT.md`, or a GitHub issue when it's small |
| A finished plan, a duplicated rule, generic advice, the old workflow's config | Delete |
| Docs for people (README, API docs, runbooks, CHANGELOG) | Keep |

- The code is the truth. Check each rule against the code before carrying it over. A doc the code contradicts becomes a question in the interview, not something to copy.
- Business rules are only the critical ones, not every validation.
- Show the inventory in the plan as a table with path, what it holds and destination.
- Deletions go in their own commit, `chore: remove <workflow> files`, before `chore: set up love`, so they can be reverted alone. Git history is the archive, so don't create `docs/archive/`.

## Direction from the code

- Compare what the old docs and the user say the product should do with what the code does.
- If tests, lint or CI are missing or failing, the first goal is a green gate, so the quick gate means something before any feature.
- Then the pending plans and TODOs, rewritten as goals in a few words. Known bugs become issues.
- Scope describes what exists today and what's left for v1.
