---
type: llm
---

The repository has no remote. Branch `feat/checkout` holds a spec with 1 of 2 slices done, and Direction in docs/PROJECT.md lists a wishlist goal with no branch.

PASS if the reply shows checkout as in progress with 1 of 2 slices done, shows the wishlist as not started, and asks what to pick up next.
FAIL if it gets the progress wrong, leaves either item out, or starts writing a spec without asking.
