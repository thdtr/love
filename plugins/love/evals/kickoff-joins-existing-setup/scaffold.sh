#!/usr/bin/env bash
# A project already set up by love, opened by someone who just joined.
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
git config commit.gpgsign false
mkdir -p .claude docs scripts src
cat > AGENTS.md <<'J'
# AGENTS.md

## Project

Shop, a small online store. Scope, business rules and architecture are in `docs/PROJECT.md`.

## Commands

| Task | Command |
|---|---|
| Full gate | `scripts/gate.sh --all` |
J
printf '@AGENTS.md\n' > CLAUDE.md
cat > .claude/settings.json <<'J'
{
  "env": { "LOVE_GATE": "scripts/gate.sh", "LOVE_FORMAT": "scripts/format.sh" },
  "enabledPlugins": { "love@love": true }
}
J
printf '#!/usr/bin/env bash\nexit 0\n' > scripts/gate.sh
printf '#!/usr/bin/env bash\nexit 0\n' > scripts/format.sh
cat > docs/PROJECT.md <<'J'
# Shop

A small online store.

## Direction

- Login and product list
J
printf 'export const shop = "shop";\n' > src/index.ts
git add -A && git commit -qm "chore: set up love"
