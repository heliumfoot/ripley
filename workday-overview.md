# Workday Overview

A developer-facing explanation of what `/workday` does and how the flow plays out. The executable instructions live in `workday.md`; the on-demand setup walkthrough lives in `workday-setup.md`. This file is for understanding, not execution.

## How It Works

### Merged PR Review

Before selecting new work, Claude checks for in-progress cards that may already be done.

Claude queries Jira for all in-progress cards assigned to you, then uses the GitHub CLI to find pull requests whose source branch contains each ticket's ID. For each card with a merged PR, Claude asks: "Is [TICKET-ID] — [title] complete?"

**If yes:**
- Set the card status to "Acceptance Testing"; if that status is not available, set it to "Ready for QA"
- Check the associated worktree:
  - If the worktree is clean and all commits have been pushed: delete the worktree silently
  - If the worktree is not clean or has unpushed commits: ask "This worktree has local changes or unpushed commits — should I commit, push, and delete it, or leave it in place?"

**If no:** leave the card and worktree as-is and move on.

Once all cards with merged PRs have been reviewed, Claude asks: "Are there any other cards you've completed that I should close out?" If yes, provide the IDs and Claude follows the same completed card workflow for each.

Once all completed cards have been handled, Claude proceeds to worktree resume.

---

### Worktree Resume

Before presenting card options, Claude scans existing git worktrees and cross-references them with your open in-progress Jira cards. If any worktrees match an open card, they are surfaced first:

```
Worktrees with in-progress work:
1. PROJ-123 — Fix login timeout  [claude/PROJ-123/fixLoginTimeout]
2. Skip — start a new card
```

If you select a worktree, Claude skips card selection and pre-flight and resumes execution of that card directly. If you select "Skip", Claude proceeds to card selection as normal.

---

### Card Selection

While cards are being presented, Claude kicks off the pr-team-review skill in the background (org inferred from the git remote, last 7 days). The result is only surfaced when Claude offers to prepare another card — if your review share is below the team average, Claude will tell you how far below and ask if you'd rather work on open PRs instead.

Claude selects cards through the following flow. This repeats each time a new card is needed.

**In-progress cards first:**

Claude queries Jira for in-progress cards assigned to you in the current sprint, sorted by rank. If there are none, it falls back to unassigned in-progress cards in the current sprint. Unassigned cards are marked so you can tell at a glance:

```
In-progress cards:
1. PROJ-123 — Fix login timeout on slow connections
2. PROJ-117 — Refactor auth token storage [unassigned]
3. None of these
```

Select a number. Claude begins the pre-flight for that card immediately.

**When in-progress cards are exhausted:**

When no in-progress cards remain, or you select "None of these", Claude queries the top 5 to-do cards in the current sprint, sorted by rank:

```
To-do cards (top 5 by rank):
1. PROJ-131 — Add push notification support
2. PROJ-134 — Migrate settings screen to new design system
3. PROJ-138 — Fix crash on tablet rotation
4. PROJ-140 — Update API client to v2
5. PROJ-145 — Add unit tests for sync manager
6. Provide a card ID
```

Select a number, or select "Provide a card ID" to type in any ticket ID. Claude immediately moves the selected card to In Progress in Jira, then begins the pre-flight.

---

### Per-Card Pre-Flight

Before touching any code for a card, Claude reads the ticket, identifies any ambiguities or decisions that aren't answerable from the codebase alone, and asks them all at once. Wait for answers before Claude proceeds.

After receiving your answers, Claude enters plan mode and presents an implementation plan before writing any code. The plan covers:
- Summary of what will be implemented
- Files to be created or modified
- Key design decisions
- Test approach

Claude waits for you to explicitly say "execute" (or equivalent) before creating the worktree and beginning implementation.

If there are no upfront questions, Claude skips directly to the plan.

---

## Pull Request Reviews

When Claude completes the implementation it opens a draft PR and begins asking after every response whether it's ready for review. Use this time to read the diff, prompt Claude for refinements, or push your own changes to the branch. When you're satisfied, tell Claude the PR is ready — it will add the Jira comment and mark the PR as Ready for Review, making it visible to the rest of the team.

Every draft PR includes a test plan section in the description covering:
- **Automated tests:** the test files/suites added and the scenarios they cover
- **Manual tests:** step-by-step scenarios to verify by hand before approving

The test plan is also printed to the console alongside the "Is this pull request ready for review?" prompt.

> **Note on PR descriptions:** Claude will generate the PR description automatically. A standard template for PR descriptions is planned — see the Open Questions section of the main guidelines.

---

## Eliminate Permission Prompts

By default, Claude Code asks for permission every time it runs a `jira` CLI command. Add it to your allowed tools once and the prompts go away. Add the following to your project's `.claude/settings.json` (or `~/.claude/settings.json` to apply across all projects):

```json
{
  "allowedTools": ["Bash(jira *)"]
}
```

This grants Claude permission to run any `jira` CLI command without prompting. See the [Claude Code Setup](ai-assisted-development-guidelines.md#claude-code-setup) section in the main guidelines for a full allowlist covering git, GitHub CLI, and platform build tools.
