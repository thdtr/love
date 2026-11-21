# Contributing to love

Bug fixes and improvements to what's already here are the most useful contributions. For a new feature, open an issue first so we can talk about it. Issues and pull requests in Portuguese are welcome too.

## Running it locally

```sh
git clone https://github.com/thdtr/love && cd love
claude --plugin-dir ./plugins/love     # Claude Code with your local copy of the plugin
bash tests/hooks.sh                    # hook scripts
bash tests/templates.sh                # gate.sh and format.sh templates
claude plugin validate .               # plugin and marketplace manifests
```

The evals in `plugins/love/evals/` run real Claude sessions with and without the plugin, so they cost money. Run only the ones for the skill you changed.

```sh
cd plugins/love
claude plugin eval . --scaffold --allow-tools Edit --case spec-redirects-small-change
```

## Where things are

| Path | What's there |
|---|---|
| `plugins/love/skills/` | One folder per command. `kickoff/templates/` holds the files copied into projects |
| `plugins/love/agents/` | The reviewer and the spec checker |
| `plugins/love/hooks/hooks.json` | When each script in `plugins/love/scripts/` runs |
| `plugins/love/evals/` | Eval cases |
| `tests/` | Tests for the scripts and templates |
| `tools/` | Logo, folder tree and social preview images |

Skills and agents are read by Claude, not by people. Write them as short, direct instructions, with no explanations of why.

## Pull requests

- One topic per pull request.
- `tests/hooks.sh`, `tests/templates.sh` and `claude plugin validate .` must pass. CI also runs shellcheck.
- Any change under `plugins/love/` needs a new `version` in `plugins/love/.claude-plugin/plugin.json` and a section for it in `CHANGELOG.md`. Installed copies only update when the version changes. CI checks both and tags the release after the merge.

## Logo and images

The logo comes from `tools/make_logo.py`, the folder tree in the README from `tools/make_tree.py` and the social card from `tools/make_social_preview.py`. Edit the scripts instead of the images and run them again (they need Pillow, fonttools and ImageMagick 7). Run `make_tree.py` after adding or removing a file in the plugin.

## Commit messages

Write the subject in the imperative and keep it short (`Block merges while checks are pending`). Explain the reason in the body when it isn't obvious.

## License

By contributing, you agree that your work is licensed under MIT, like the rest of the project.
