#!/bin/bash
#
# pending-reviews — Lists GitHub PRs awaiting your review
#
# Shows PRs across an org that are:
#   - Open and not drafts
#   - Requesting your review (or a team you belong to)
#   - Have no human reviewer comments yet (author + bot comments are ignored)
#
# Usage:
#   pending-reviews              # prints to stdout
#   pending-reviews --notify     # also sends macOS notification summary
#
# Configuration (via environment variables):
#   REVIEW_ORG        — GitHub org to search (default: NU-MSS)
#   REVIEW_USER       — GitHub username (default: auto-detected from `gh api user`)
#   REVIEW_IGNORE     — Regex of bot usernames to ignore (default: copilot|github-actions|dependabot)
#
# Requirements: gh (GitHub CLI, authenticated), jq
#
# To install for the whole team:
#   1. Copy this script to ~/bin/pending-reviews (or anywhere on PATH)
#   2. chmod +x ~/bin/pending-reviews
#   3. Make sure ~/bin is on PATH: export PATH="$HOME/bin:$PATH" in ~/.zshrc
#   4. Each user must have `gh auth login` completed
#

set -euo pipefail

# Configuration with defaults
ORG="${REVIEW_ORG:-NU-MSS}"
IGNORED_COMMENTERS="${REVIEW_IGNORE:-copilot|github-actions|dependabot}"
NOTIFY=false

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --notify) NOTIFY=true ;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
  esac
done

# Auto-detect GitHub user if not set
if [ -z "${REVIEW_USER:-}" ]; then
  GITHUB_USER=$(gh api user --jq '.login' 2>/dev/null)
  if [ -z "$GITHUB_USER" ]; then
    echo "Error: Could not detect GitHub user. Run 'gh auth login' or set REVIEW_USER." >&2
    exit 1
  fi
else
  GITHUB_USER="$REVIEW_USER"
fi

echo "Fetching PRs requesting review from $GITHUB_USER in $ORG..."
echo ""

# Get all open, non-draft PRs requesting review from me
prs=$(gh search prs \
  --review-requested="$GITHUB_USER" \
  --state=open \
  --owner="$ORG" \
  --json repository,number,title,author,isDraft,url \
  --jq '[.[] | select(.isDraft == false)]')

count=$(echo "$prs" | jq 'length')

if [ "$count" -eq 0 ]; then
  echo "No PRs awaiting your review."
  if [ "$NOTIFY" = true ]; then
    osascript -e 'display notification "No PRs need your review" with title "PR Reviews" sound name "default"'
  fi
  exit 0
fi

needs_review=0
pr_summaries=""

while read -r pr; do
  repo=$(echo "$pr" | jq -r '.repository.name')
  number=$(echo "$pr" | jq -r '.number')
  title=$(echo "$pr" | jq -r '.title')
  author=$(echo "$pr" | jq -r '.author.login')
  url=$(echo "$pr" | jq -r '.url')

  # Get review comments (PR review comments, not issue comments)
  # Filter out: author's own comments, and bot/AI comments
  reviewer_comments=$(gh api "repos/$ORG/$repo/pulls/$number/comments" \
    --jq "[.[] | select(
      .user.login != \"$author\" and
      (.user.login | test(\"$IGNORED_COMMENTERS\") | not)
    )] | length" 2>/dev/null || echo "0")

  # Also check PR reviews (approve/request changes/comment reviews)
  reviewer_reviews=$(gh api "repos/$ORG/$repo/pulls/$number/reviews" \
    --jq "[.[] | select(
      .user.login != \"$author\" and
      (.user.login | test(\"$IGNORED_COMMENTERS\") | not) and
      .state != \"PENDING\"
    )] | length" 2>/dev/null || echo "0")

  total_reviewer_activity=$((reviewer_comments + reviewer_reviews))

  if [ "$total_reviewer_activity" -eq 0 ]; then
    echo "  $repo#$number — $title"
    echo "    Author: $author"
    echo "    $url"
    echo ""
    pr_summaries="${pr_summaries}${repo}#${number} ($author)\n"
    needs_review=$((needs_review + 1))
  fi
done < <(echo "$prs" | jq -c '.[]')

if [ "$needs_review" -eq 0 ]; then
  echo "All requested PRs already have reviewer activity."
  if [ "$NOTIFY" = true ]; then
    osascript -e 'display notification "All PRs already have reviewer activity" with title "PR Reviews" sound name "default"'
  fi
else
  echo "Found $needs_review PR(s) awaiting your review."
  if [ "$NOTIFY" = true ]; then
    # Truncate summary for notification (macOS has a length limit)
    short_summary=$(echo -e "$pr_summaries" | head -5)
    if [ "$needs_review" -gt 5 ]; then
      short_summary="${short_summary}...and $((needs_review - 5)) more"
    fi
    osascript -e "display notification \"$short_summary\" with title \"$needs_review PR(s) need your review\" sound name \"default\""
  fi
fi
