#!/usr/bin/env bash
# No remote. One feature half built on its branch, one goal not started.
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
git config commit.gpgsign false
mkdir -p docs src
cat > docs/PROJECT.md <<'J'
# Shop

A small online store.

## Direction

- Checkout with card payment
- Wishlist to save products for later
J
printf 'export const shop = "shop";\n' > src/index.ts
git add -A && git commit -qm "feat: product list"
git switch -qc feat/checkout
mkdir -p docs/specs
cat > docs/specs/checkout.md <<'J'
# Checkout

Branch: feat/checkout

## Slices

### 1. Cart

- [x] done
- Verify: `pnpm test cart`

### 2. Card payment

- [ ] done
- Verify: `pnpm test payment`
J
git add -A && git commit -qm "docs: spec checkout"
git switch -q main
