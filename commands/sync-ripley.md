---
description: Pull the latest team Claude config from the ripley repo into ~/.claude (one-way; never pushes back)
allowed-tools: Bash(~/.claude/sync-ripley.sh*), Bash(bash ~/.claude/sync-ripley.sh*)
---

Run the one-way sync that pulls team-managed Claude config from the ripley repo into the local `~/.claude` layer:

```bash
~/.claude/sync-ripley.sh
```

This pulls the latest `ripley` and overwrites only the managed files (the long
guidelines → `~/.claude/CLAUDE.md`, the `workday` / `end-of-day` / `test-ticket`
/ `sync-ripley` commands, and the `pending-reviews` script → `~/bin/`). It backs
up anything it overwrites and never commits or pushes to ripley. Personal files
in `~/.claude` are left untouched.

The script needs `RIPLEY_DIR` set to your local ripley checkout (there is no
default). Set it once in your shell profile, e.g. `export RIPLEY_DIR=~/path/to/ripley`.
If it isn't set, the script exits with instructions rather than guessing.

After it runs, report the summary line (how many files updated / new / unchanged)
and, if any were updated, briefly note what changed and where the backup went.

When invoked as `/sync-ripley --no-pull`, pass `--no-pull` through to the script
to sync from the current local ripley checkout without fetching.
