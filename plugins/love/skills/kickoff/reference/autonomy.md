# Kanban and bots

## Labels

Each card is a GitHub issue. Exactly one of these labels says where it is.

| Label | Meaning | Who moves it forward |
|---|---|---|
| `needs-decision` | A question waits for the user. The question is the issue's last comment. | `/spec` with no argument, after the user answers |
| `ready` | The spec is approved and committed on the branch named in the issue's `Branch:` line. | `/build` or `/bot` |
| `building` | Someone or a bot is building it. | `/ship` when the PR opens |
| `review` | The PR is open. | The merge closes the issue |

## When an item can go to a bot

All of these must hold. Otherwise it stays with a person.

- Every slice in the spec has a Verify command that fails without the slice.
- The spec has no open decision.
- No slice touches auth, payments, permissions, a destructive migration or production config.

## Limits

- At most 3 issues labeled `building` at the same time, counting people and bots.
- A bot never merges, never force pushes and never deploys.

## Bots setup

Tell the user to do this once per machine.

1. `claude setup-token` and copy the token.
2. Create a fine-grained GitHub token for this repository only, with read and write on contents, issues and pull requests.
3. Save both in `~/.config/love/bot.env` and protect the file.
   ```
   mkdir -p ~/.config/love
   printf 'CLAUDE_CODE_OAUTH_TOKEN=%s\nGH_TOKEN=%s\n' '<claude token>' '<github token>' > ~/.config/love/bot.env
   chmod 600 ~/.config/love/bot.env
   ```
4. Run `/bot` to send the oldest ready issue.
