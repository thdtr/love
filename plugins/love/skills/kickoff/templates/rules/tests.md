---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/__tests__/**"
  - "tests/**"
  - "e2e/**"
---

# Tests

- Runner is <runner>. Tests live <next to the code | in tests/> and are named <*.test.ts>.
- Tests use <an in-process database | a dedicated container>, never the dev database.
- E2E covers critical flows only, in <e2e/>.
- Test what the user or caller sees (return value, HTTP response, what shows on screen), not internals.
- A test only counts if it fails when the logic breaks. A fixed bug gets a test that reproduces it.
- Mock only at the edges (network, payments, email, clock), never the module under test.
- Never weaken a test to make it pass, whether by removing an assert, skipping it or loosening what it expects. Changing an existing test needs a reason in the commit message.
