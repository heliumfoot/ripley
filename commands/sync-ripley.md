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

After it runs, report the summary line (how many files updated / new / unchanged)
and, if any were updated, briefly note what changed and where the backup went.

If `$ARGUMENTS` contains `--no-pull`, pass it through to sync from the current
local ripley checkout without fetching.
