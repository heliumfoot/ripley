#!/bin/bash
#
# sync-ripley — one-way sync of team Claude config FROM the ripley repo INTO ~/.claude
#
# Pulls the latest ripley (a shared team repo) and copies a fixed set of
# "managed" files into your local Claude config. It is strictly one-way:
# it only ever reads from ripley and writes into your home dir. It NEVER
# commits or pushes to ripley, so your personal changes can't leak upstream.
#
# Anything in ~/.claude that is NOT in the manifest below is left untouched —
# that's your personal layer (own commands, skills, notes).
#
# Every file is backed up before it's overwritten, so the first run is
# fully recoverable. Backups go to ~/.claude/backups/ripley-sync/<timestamp>/.
#
# Usage:
#   ~/.claude/sync-ripley.sh           # pull + sync
#   ~/.claude/sync-ripley.sh --no-pull # sync from the current local ripley checkout
#
# Config (override via env):
#   RIPLEY_DIR  — path to the ripley checkout (default: ~/Developer/heliumfoot/ripley)

set -euo pipefail

RIPLEY_DIR="${RIPLEY_DIR:-$HOME/Developer/heliumfoot/ripley}"
CLAUDE_DIR="$HOME/.claude"
BACKUP_ROOT="$CLAUDE_DIR/backups/ripley-sync"
PULL=1
[ "${1:-}" = "--no-pull" ] && PULL=0

# --- Managed manifest: "<source path in ripley>::<destination on disk>" --------
# To add/remove a synced file, edit this list. Destinations use $HOME.
MANIFEST=(
	"ai-assisted-development-guidelines.md::$CLAUDE_DIR/CLAUDE.md"
	"workday.md::$CLAUDE_DIR/commands/workday.md"
	"commands/end-of-day.md::$CLAUDE_DIR/commands/end-of-day.md"
	"commands/test-ticket.md::$CLAUDE_DIR/commands/test-ticket.md"
	"commands/sync-ripley.md::$CLAUDE_DIR/commands/sync-ripley.md"
	"scripts/sync-ripley.sh::$CLAUDE_DIR/sync-ripley.sh"
	"scripts/pending-reviews.sh::$HOME/bin/pending-reviews"
)

# --- Preflight -----------------------------------------------------------------
if [ ! -d "$RIPLEY_DIR/.git" ]; then
	echo "ERROR: ripley checkout not found at: $RIPLEY_DIR" >&2
	echo "       Clone it or set RIPLEY_DIR=/path/to/ripley" >&2
	exit 1
fi

# --- Pull latest (best-effort; never blocks the sync) --------------------------
if [ "$PULL" -eq 1 ]; then
	echo "→ Pulling latest ripley ($RIPLEY_DIR)…"
	if ! git -C "$RIPLEY_DIR" pull --ff-only --quiet 2>/dev/null; then
		echo "  ⚠ Could not fast-forward (offline, dirty tree, or diverged)."
		echo "    Syncing from the current local checkout instead."
	fi
else
	echo "→ Skipping pull (--no-pull); using current local ripley checkout."
fi

# --- Sync ----------------------------------------------------------------------
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$TS"
changed=0 unchanged=0 added=0 missing=0
backed_up=0

for entry in "${MANIFEST[@]}"; do
	src="$RIPLEY_DIR/${entry%%::*}"
	dst="${entry##*::}"

	if [ ! -f "$src" ]; then
		echo "  ⚠ MISSING in ripley: ${entry%%::*} (skipped)"
		missing=$((missing + 1))
		continue
	fi

	mkdir -p "$(dirname "$dst")"

	if [ ! -f "$dst" ]; then
		cp "$src" "$dst"
		echo "  + NEW       $dst"
		added=$((added + 1))
	elif cmp -s "$src" "$dst"; then
		unchanged=$((unchanged + 1))
	else
		# back up the existing file before overwriting
		rel="${dst#$HOME/}"
		mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
		cp "$dst" "$BACKUP_DIR/$rel"
		backed_up=$((backed_up + 1))
		cp "$src" "$dst"
		echo "  ~ UPDATED   $dst"
		changed=$((changed + 1))
	fi

	# keep shell scripts executable
	case "$dst" in
		*.sh|"$HOME/bin/"*) chmod +x "$dst" ;;
	esac
done

# --- Summary -------------------------------------------------------------------
echo ""
echo "Done. $changed updated, $added new, $unchanged unchanged, $missing missing."
if [ "$backed_up" -gt 0 ]; then
	echo "Backed up $backed_up file(s) before overwrite → $BACKUP_DIR"
fi
