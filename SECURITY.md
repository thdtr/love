# Security Policy

## Supported versions

Only the latest release gets fixes.

## Reporting a vulnerability

Please don't open a public issue. Report it privately through GitHub, in the *Security* tab, under *Report a vulnerability*. You'll get an answer within 7 days.

These matter most.

- A way for an agent to bypass the permission rules or hooks that love installs.
- A way out of the bot container's network or file limits.
- A hook script that runs something it shouldn't, or leaks data.
- Secrets that reach a commit, a pull request or a log.
