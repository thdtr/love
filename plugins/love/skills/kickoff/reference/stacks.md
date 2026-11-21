# Commands per stack

Fill `scripts/gate.sh` with one line per stack as `name|directory|extensions|quick check|full check`, and `scripts/format.sh` as `directory|extensions|format command`, each line in single quotes. The quick check gets `$LOVE_CHANGED` with that stack's changed files, relative to its directory. Replace `pnpm exec` with the project's runner (`npx --no-install`, `yarn`, `bunx`). Prefer quiet reporters (`--reporter=dot`, `-q`), since short output saves tokens.

## Gate and format

| Stack | Extensions | Quick check | Full check | Format |
|---|---|---|---|---|
| TS, ESLint, Vitest | `ts,tsx,js,jsx,mjs,cjs` | `pnpm exec tsc --noEmit --incremental && pnpm exec eslint --max-warnings=0 --no-warn-ignored $LOVE_CHANGED && pnpm exec vitest related --run --passWithNoTests $LOVE_CHANGED` | `pnpm lint && pnpm typecheck && pnpm test && pnpm build` | `pnpm exec prettier --write --ignore-unknown --log-level=silent` |
| TS, Biome | same | `pnpm exec tsc --noEmit --incremental && pnpm exec biome check --no-errors-on-unmatched $LOVE_CHANGED && pnpm exec vitest related --run --passWithNoTests $LOVE_CHANGED` | same | `pnpm exec biome format --write --no-errors-on-unmatched` |
| TS, Jest | same | replace vitest with `pnpm exec jest --findRelatedTests --passWithNoTests $LOVE_CHANGED` | same | same |
| Go | `go` | `go vet ./... && go test ./...` | `go vet ./... && go test -race ./... && go build ./...` | `gofmt -w` |
| Python, ruff, pytest | `py` | `uv run ruff check $LOVE_CHANGED && uv run pytest -q -x --testmon` | `uv run ruff check && uv run ruff format --check && uv run pyright && uv run pytest -q` | `uv run ruff format` |
| Dart, Flutter | `dart` | `dart analyze --fatal-infos $LOVE_CHANGED` | `dart analyze --fatal-infos && flutter test` | `dart format` |
| PHP, Pint, PHPStan, Pest | `php` | `vendor/bin/phpstan analyse --no-progress $LOVE_CHANGED && vendor/bin/pest --dirty` | `vendor/bin/pint --test && vendor/bin/phpstan analyse --no-progress && vendor/bin/pest` | `vendor/bin/pint` |

Go caches the tests of packages that didn't change, so `go test ./...` stays quick. Without `pytest-testmon`, `pytest -q -x` runs the whole suite.

## Package manager safety

| Package manager | Setting |
|---|---|
| pnpm 10 or newer | Dependency install scripts don't run unless listed in `onlyBuiltDependencies`. Add `minimumReleaseAge: 1440` to `pnpm-workspace.yaml` so versions published in the last day aren't installed. |
| npm | `ignore-scripts=true` in `.npmrc`. |
| Bun | Dependency install scripts only run for packages in `trustedDependencies`. Keep that list short. |
| uv | CI runs `uv sync --locked`. |
| Composer | List allowed plugins in `config.allow-plugins` and nothing else. |

## Ask rules

Add to `permissions.ask` in `.claude/settings.json` the commands this stack uses that touch production or destroy data. Examples follow.

| Tool | Rules |
|---|---|
| Prisma | `Bash(*prisma migrate deploy*)`, `Bash(*prisma migrate reset*)`, `Bash(*prisma db push*)` |
| Drizzle | `Bash(*drizzle-kit push*)`, `Bash(*drizzle-kit migrate*)` |
| Vercel | `Bash(*vercel *)` |
| Fly | `Bash(*fly deploy*)` |
| SSH deploy | `Bash(ssh *)`, `Bash(scp *)` |

## CI setup

| Stack | Steps before `scripts/gate.sh` |
|---|---|
| pnpm | `pnpm/action-setup@v6`, `actions/setup-node@v7` with `node-version: 24` and `cache: pnpm`, `pnpm install --frozen-lockfile` |
| Go | `actions/setup-go@v6` with `go-version-file: go.mod` |
| uv | `astral-sh/setup-uv@v7`, `uv sync --locked` |
| Flutter | `subosito/flutter-action@v2` with `channel: stable` and `cache: true`, `flutter pub get` |
| PHP | `shivammathur/setup-php@v2`, `composer install --no-interaction` |

The dependency audit for the weekly job is `pnpm audit --prod --audit-level=high`, `govulncheck ./...`, `uvx pip-audit` or `composer audit`.
