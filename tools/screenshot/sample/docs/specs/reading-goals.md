# Reading goals

Issue: #14
Branch: feat/reading-goals

## Problem

Clubs agree on how much to read each week in chat, and nobody remembers.

## Done when

- [x] An admin sets a weekly page goal for the club.
- [ ] Each member sees how far they are from this week's goal.

## Out of scope

- Goals per member.

## Decisions

- Goal lives on the club, `weekly_pages` integer, null means no goal.
- The week starts on Monday in the club's time zone. (auto)

## Slices

### 1. Admin sets the goal

- [x] done
- Verify: `pnpm exec vitest run src/lib/goals.test.ts`

### 2. Members see their progress

- [ ] done
- Verify: `pnpm exec playwright test e2e/goals.spec.ts`

## Risks

- Members in other time zones may see the week change at odd hours.
