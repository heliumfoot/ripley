# pending-reviews — PR Review Finder for NU-MSS

Lists open GitHub PRs across NU-MSS that need your review:
- Open and not drafts
- Requesting you (or a team you belong to) as reviewer
- No human reviewer comments yet (author + bot comments are ignored)

## Prerequisites

- **gh** (GitHub CLI) — `brew install gh` then `gh auth login`
- **jq** — `brew install jq` (usually pre-installed on macOS)

## Install

```bash
# 1. Create ~/bin if it doesn't exist
mkdir -p ~/bin

# 2. Download the script (update the URL if the gist is forked)
curl -fsSL https://gist.githubusercontent.com/reschneebaum/593261134242ca46ab01c8a646247c51/raw/pending-reviews -o ~/bin/pending-reviews

# 3. Make it executable
chmod +x ~/bin/pending-reviews

# 4. Add ~/bin to PATH (add to ~/.zshrc if not already there)
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Usage

```bash
# Print PRs needing review to terminal
pending-reviews

# Also pop a macOS notification
pending-reviews --notify

# Show help
pending-reviews --help
```

## Optional: Daily Cron Notification

Get a macOS notification at 9 AM on weekdays:

```bash
(crontab -l 2>/dev/null; echo '# Pending PR reviews at 9 AM weekdays
PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin
0 9 * * 1-5 $HOME/bin/pending-reviews --notify >> /tmp/pending-reviews.log 2>&1') | crontab -
```

## Optional: Claude Code Skill

To use as `/pending-reviews` in Claude Code:

```bash
mkdir -p ~/.claude/skills/pending-reviews
cat > ~/.claude/skills/pending-reviews/SKILL.md << 'SKILL'
---
name: pending-reviews
description: List open NU-MSS PRs that need your review
allowed-tools: Bash(~/bin/pending-reviews *)
---
Run the pending-reviews script: ~/bin/pending-reviews
Summarize results in a numbered list with repo, PR number, title, and author.
SKILL
```

## Configuration

All optional — defaults work for most NU-MSS team members:

| Variable | Default | Description |
|----------|---------|-------------|
| `REVIEW_ORG` | `NU-MSS` | GitHub org to search |
| `REVIEW_USER` | auto-detected from `gh` | Your GitHub username |
| `REVIEW_IGNORE` | `copilot\|github-actions\|dependabot` | Bot accounts to skip |
