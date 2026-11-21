---
name: kickoff
description: Sets up a project for love, new or existing. Writes AGENTS.md, docs/PROJECT.md, settings, gate and format scripts, CI, Kanban labels and, if wanted, the bot container. On a project already set up, it only sets up this machine.
disable-model-invocation: true
effort: high
argument-hint: "[short product description]"
---

# kickoff

User context: $ARGUMENTS

Every confirmation goes through AskUserQuestion. Without that tool, ask the same questions as plain text, at most 4, and stop until they're answered.

Templates are in `${CLAUDE_SKILL_DIR}/templates/`. Per-stack commands are in `${CLAUDE_SKILL_DIR}/reference/stacks.md`. For a project that already has code, also read `${CLAUDE_SKILL_DIR}/reference/adopt.md`.

## 1. Check the machine

love runs on Linux only. On any other platform, say so in one line and stop.

Check that `bash` is version 5 or newer and that `git` and `jq` are installed. Check `gh auth status`, `gitleaks version` and, only if the user wants bots, `podman --version`. Each missing tool goes into the step 4 plan with its install command for the distro in `/etc/os-release`.

## 2. Project already set up

If `AGENTS.md` exists and `.claude/settings.json` has `LOVE_GATE`, someone is joining or running it again. Don't interview and don't touch committed files. Only check this machine.

- The tools from step 1.
- The plugin is installed. If not, give `claude plugin install love@love --scope project`.
- If `.love/bot/` exists, whether `~/.config/love/bot.env` exists with mode 600. If not, give the steps from the Bots section of `reference/autonomy.md`.

Report what you checked and stop. `git status` must stay clean. Redo the setup only if the user asks.

## 3. Survey and interview

Read manifests and lockfiles, configs (types, lint, format, tests, framework, ORM), `.github/workflows/`, the folder layout, `docs/`, and any `CLAUDE.md`, `AGENTS.md` and `.claude/`. On a large repo, delegate the survey to Explore. Don't ask what the code answers.

Ask only what's missing, with AskUserQuestion, up to 4 questions per call, recommended option first.

- New project. What it is, the problem, who it's for, v1 scope, what's out of scope.
- Language, framework, package manager and data store, if not decided.
- Hosting and deploy, where migrations run, rollback and health check.
- Tests. Runner, test database, e2e.
- How we know the product works well. A metric, golden set or eval that can fail when quality drops becomes the quality check (`eval_check` in `scripts/gate.sh`). None is a valid answer.
- UI. Is there one, and should `docs/DESIGN.md` be written now?
- Bots. Will ready work run in a container without supervision?

Never infer Do not touch, deploy, rollback or production commands. Confirm them.

## 4. Plan

In one message, list every file to create or change and the decisions taken. When adopting, include the inventory table from `adopt.md`. For an existing file, show what changes and never drop the user's content silently. Ask for a single confirmation with AskUserQuestion in the same turn.

## 5. Write

Files under `.claude/` only with Write or Edit.

- `AGENTS.md` from the template. Fill every `<...>` and delete lines that don't apply. 60 lines at most, only facts that change how an agent works here.
- `CLAUDE.md` with `@AGENTS.md`. If it already has content, move the project facts into `AGENTS.md` and keep the import on top.
- `.claude/settings.json` from the template, merged with the existing one. Add `ask` rules for this stack's production and destructive commands from `stacks.md`.
- `scripts/gate.sh` and `scripts/format.sh` from the templates, one line per stack, using `stacks.md`. Use `.` as the directory for a single stack at the root. Run both once before saving and fix them until they pass.
- Package manager safety from `stacks.md`.
- `.claude/rules/tests.md`, and `.claude/rules/ui.md` when there is UI. Fill the `<...>` and match `paths:` to the real layout.
- `docs/PROJECT.md` from the template. 80 lines at most. Business rules are only the invariants whose violation costs money, data or trust, each with where it came from. Direction holds the next goals in a few words.
- `docs/DESIGN.md` from the template, only if the user wants it now.
- Architecture checks. For TypeScript, `dependency-cruiser` as a dev dependency, `.dependency-cruiser.cjs` from the template with the layer rules that follow from the Architecture section, and `depcruise src` in the lint step. Other languages get the equivalent if one exists (import-linter in Python).
- `.github/workflows/ci.yml` from the template, with the setup and install steps for each stack. Delete the eval job when there is no quality check.
- `.gitignore` gets the lines from `templates/gitignore`. `.worktreeinclude` from the template. `.env.example` with the variables the code reads and no values.
- With a GitHub remote, create the Kanban labels.
  ```
  gh label create needs-decision --color D93F0B --description "Waiting for a decision" --force
  gh label create ready --color 0E8A16 --description "Spec approved, ready to build" --force
  gh label create building --color FBCA04 --description "Being built" --force
  gh label create review --color 1D76DB --description "PR open, waiting for review" --force
  ```
- Bots, if wanted. Copy `templates/bot/` to `.love/bot/`, add the stacks' toolchain to the Containerfile (same versions as CI) and their package registries to `hosts` in `firewall.sh`. Then give the user the setup steps from the Bots section of `reference/autonomy.md`.

## 6. Wrap up

Run `scripts/gate.sh --all` and report the command and its result line. Then, in 5 lines or fewer, say

- the LSP plugin to install if the language has one and it isn't installed (`/plugin install typescript-lsp@claude-plugins-official`, `pyright-lsp`, `gopls-lsp`);
- the commit to make, `chore: set up love` (when adopting, first `chore: remove <workflow> files` with only the deletions);
- the next step, `/spec` with the first goal from Direction.
