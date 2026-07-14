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

The script needs to know where the local ripley checkout is, via `RIPLEY_DIR`.
There is no hardcoded default. Before running the script, resolve it in this
order:

1. If `RIPLEY_DIR` is already set in the environment, or
   `~/.claude/sync-ripley.conf` already exists, just run the script — it uses
   them automatically.
2. Otherwise this is a first run: ask the developer for the absolute path to
   their local ripley checkout. Confirm the path contains a `.git` directory
   (so it's a real clone), then save it by writing a single line
   `RIPLEY_DIR=<absolute-path>` to `~/.claude/sync-ripley.conf`. Future runs
   read the saved path automatically — you won't ask again.

After it runs, report the summary line (how many files updated / new / unchanged)
and, if any were updated, briefly note what changed and where the backup went.

When invoked as `/sync-ripley --no-pull`, pass `--no-pull` through to the script
to sync from the current local ripley checkout without fetching.
