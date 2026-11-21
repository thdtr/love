# Changelog

Each version is the `version` in `plugins/love/.claude-plugin/plugin.json`. Installed copies only update when that number changes.

## 0.1.1 - 2026-11-21

### Fixed

- `scripts/format.sh`, as `/kickoff` writes it, stops when it can't enter the project folder instead of formatting from the wrong place.

## 0.1.0 - 2026-11-21

First release.

### Added

- `/kickoff` sets up a new or existing project, or only the machine of someone joining it.
- `/spec` interviews you and writes a short spec with vertical slices. Alone, it shows the inbox with decisions waiting, pull requests to merge and failing CI.
- `/build` builds the spec one tested slice at a time and ends with an independent review.
- `/fix` finds the root cause before changing code.
- `/ship` folds the spec into `docs/PROJECT.md`, opens the pull request with a review guide and waits for CI.
- `/bot` sends ready issues to bots running in a Podman container.
- Hooks that format each edit, run the quick gate before each commit and at the end of each turn, scan for secrets, keep code off main and block merges while CI is pending or red.
- Size limits for `AGENTS.md`, `docs/PROJECT.md` and specs.
