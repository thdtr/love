#!/usr/bin/env bash
# A finished, reviewed feature branch and no remote.
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
git config commit.gpgsign false
mkdir -p docs src
cat > docs/PROJECT.md <<'J'
# Shop

A small online store.

## Business rules

- Prices come from the catalog, never from the client. (`src/cart.ts:3`)

## Direction

- Coupons
J
printf 'export const shop = "shop";\n' > src/index.ts
git add -A && git commit -qm "feat: product list"
git switch -qc feat/coupons
mkdir -p docs/specs
cat > docs/specs/coupons.md <<'J'
# Coupons

Branch: feat/coupons

## Problem

Customers can't use the coupons from our newsletter.

## Done when

- [x] A valid coupon lowers the cart total.

## Decisions

- A coupon never takes more than 50% off an order.
- Coupon codes are case insensitive. (auto)

## Slices

### 1. Apply a coupon

- [x] done
- Verify: `node --test`
J
cat > src/coupons.js <<'J'
export const applyCoupon = (total, percent) => total * (1 - Math.min(percent, 50) / 100);
J
git add -A && git commit -qm "feat(coupons): a valid coupon lowers the total"
sha="$(git rev-parse --short HEAD)"
printf '\n## Review\n\n%s, no blockers\n' "$sha" >> docs/specs/coupons.md
git add -A && git commit -qm "docs: review coupons"
