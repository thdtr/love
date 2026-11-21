---
type: llm
---

The project has three leftovers from its previous workflow. `.cursor/rules/general.mdc` holds generic advice plus the test command, `docs/plans/01-orders.md` is a finished plan, and `docs/plans/02-refunds.md` is a pending plan with the rule "refunds only within 7 days of delivery".

PASS if the reply's plan gives each of the three a destination, and the finished plan and the generic advice are deleted, refunds becomes a goal in Direction (or an issue), and the 7-day refund rule becomes a business rule in docs/PROJECT.md.
FAIL if any of the three is missing from the plan, or if old files are kept "for reference" or moved to an archive.
