# Workday Execution

Your job during the workday is **oversight, not writing code**. Claude selects cards to work on by querying Jira, pre-flights each one with you, implements the changes, and prepares pull requests. You answer pre-flight questions, respond to blockers, and review diffs before PRs are opened.

Each ticket produces one pull request. You control how many cards run in parallel — just say no when asked if you want to prepare another.

---

Before doing anything else, print: "▶ Setup checks"

Run two checks:
1. `which jira` — jira CLI is installed
2. `[ -n "$JIRA_CONFIG_FILE" ]` — project is configured

If both pass, skip setup entirely and proceed directly to the merged PR review.

If either fails, read `workday-setup.md` (alongside this file) and walk the
developer through only the steps needed to fix what failed. Once all
incomplete steps are confirmed complete, proceed.

---

Print: "▶ Merged PR review"

First, run the merged PR review: query my in-progress Jira cards assigned to
me, then use the GitHub CLI to find pull requests whose source branch contains
each ticket ID. For each card with a merged PR, ask: "Is [TICKET-ID] — [title] complete?"

If yes:
- Set the card status to "Acceptance Testing"; if unavailable, set it to
  "Ready for QA"
- Check the associated worktree. If clean and fully pushed, delete it without
  prompting. If not, ask: "This worktree has local changes or unpushed commits
  — should I commit, push, and delete it, or leave it in place?"

If no: leave the card and worktree as-is.

Once all merged PRs have been reviewed, ask: "Are there any other cards
you've completed that I should close out?" If yes, ask for the IDs and follow
the same completed card workflow for each.

Once all completed cards have been handled, print: "▶ Checking for in-progress worktrees"

Run `git worktree list` and cross-reference the results with your open
in-progress Jira cards. If any worktrees match an open card, present them:

```
Worktrees with in-progress work:
1. PROJ-123 — Fix login timeout  [claude/PROJ-123/fixLoginTimeout]
2. Skip — start a new card
```

If I select a worktree, print: "▶ Resuming: [TICKET-ID]" and skip card
selection and pre-flight — go straight to execution for that card using the
existing worktree.

If no worktrees match open cards, or I select "Skip", print: "▶ Card selection"

In parallel with card selection, run the pr-team-review skill (org from
`git remote get-url origin`, last 7 days, non-interactively). If the skill
isn't present, ask to fetch it from github.com/heliumfoot/ripley before
proceeding. Store the current user's share % and compute team average as
`100% / reviewer count` from the output.

Begin card selection: query
in-progress cards assigned to me in the current sprint, sorted by rank. If
there are none, fall back to unassigned in-progress cards in the current
sprint. Mark unassigned cards with [unassigned]. Add "None of these" as the
last option:

```
In-progress cards:
1. PROJ-123 — Fix login timeout on slow connections
2. PROJ-117 — Refactor auth token storage [unassigned]
3. None of these
```

When no in-progress cards remain or I select "None of these", query the top 5
to-do cards in the current sprint, sorted by rank. Add "Provide a card ID" as
the last option:

```
To-do cards (top 5 by rank):
1. PROJ-131 — Add push notification support
2. PROJ-134 — Migrate settings screen to new design system
3. PROJ-138 — Fix crash on tablet rotation
4. PROJ-140 — Update API client to v2
5. PROJ-145 — Add unit tests for sync manager
6. Provide a card ID
```

If I select a to-do card (not already in-progress), move it to In Progress
in Jira before starting the pre-flight.

For the selected card, print: "▶ Pre-flight: [TICKET-ID]"

Do the pre-flight: read the ticket, identify any
ambiguities or decisions not answerable from the codebase alone, and ask them
all now. Wait for my answers.

After receiving answers, print: "▶ Planning: [TICKET-ID]"

Enter plan mode and produce an implementation plan before writing any code.
The plan must include:
- Summary of what will be implemented
- Files to be created or modified
- Key design decisions
- Test approach

Wait for me to explicitly say "execute" (or equivalent) before proceeding.
If there are no pre-flight questions, skip directly to the plan step.

Ask the user what the default branch is for this project if not known.

Ask the user what branch to branch off (use the default for the suggestion if known)
and confirm the worktree branch name to use in this PR with the user.

As soon as I say "execute", print: "▶ Executing: [TICKET-ID]"

Create a git worktree and branch for that card and begin implementation immediately. Name the branch
`claude/[TICKET-ID]/[camelCaseName]` where [camelCaseName] is a 2–4 word
camel case summary of the work (e.g. `claude/PROJ-123/fixLoginTimeout`). If
that branch name already exists, try a different camel case name. If no
distinct name can be found, append an incrementing counter (e.g.
`claude/PROJ-123/fixLoginTimeout2`).

After creating the worktree, print: "Working directory: [full path to worktree]"
Also print: "▶ Status: [PROJECT-NAME] | [TICKET-ID] — [ticket title]"
where PROJECT-NAME is the name of the repo root directory.

If this is a flutter project, copy the android/key.properties and android/local.properties
from the main project working directory (do not overwrite files if they exist)
as these files are not source controlled but needed for the build.
Also, do an `fvm flutter pub get`.

**Parallel work:** After handing off the card:
- If the background pr-team-review check has completed and the user's share
  is below the team average, ask:
  "Your review share is X% vs a team average of Y% — you're Z percentage
  points below average. Would you like to work on open PRs awaiting your
  review, or should I prepare another card?"
  If they choose PR reviews, list open PRs where they've been requested as
  a reviewer within the previously inferred org: `gh search prs --owner "$INFERRED_ORG" --review-requested=@me --state open`
- Otherwise (check not ready, or user is at/above average), ask:
  "Would you like to prepare another card for me to work on in parallel?"

If they want another card, follow the card selection flow and pre-flight the
next card. Start it as soon as pre-flight answers arrive. Repeat this offer
each time a new card begins executing.

For each card in execution:
- Make judgment calls consistent with existing patterns
- Log each non-obvious decision so it appears at review time
- If you hit uncertainty that a quick question would resolve better than your
  best guess, ask — you don't need to be fully blocked to interrupt. Prefer
  a short question over a decision the developer might want to make themselves
- Whenever you ask me a question or report a blocker during execution, end the
  message with the working directory path: "Working directory: [full path to worktree]"

**Before creating the PR, complete every step in the Pre-PR Checklist below.** If a step doesn't apply, ask the developer before skipping it.

---

## Pre-PR Checklist

Run through each step in order before creating the PR.

### 1. Tests

Only add tests that are actually valuable and practical. If the change is
pure UI, config-only, or trivial, skip this step. When tests are warranted,
write them and confirm they pass. Use the framework appropriate for the
project's platform:
- Native iOS / cross-platform Swift: XCTest
- Native Android: JUnit
- Flutter: flutter_test
- Node.js / Firebase / Amplify: Jest

Test public interfaces and meaningful branching logic — happy path, error
paths, and edge cases that could realistically behave differently. Do not test
private helpers, simple getters/setters, or generated code. Aim for ones to
tens of tests per card, not exhaustive line coverage.

If tests fail, apply the same judgment used for questions during execution: fix
straightforward issues silently; ask if there is meaningful uncertainty about
the right approach.

Do not create the PR until all tests pass.

### 2. Self-review

Self-review the full diff. Check for: leftover debug code, missing error
handling, naming consistency with the existing codebase, unnecessary changes,
and anything that doesn't match existing patterns. Fix any issues found before
proceeding.

### 3. Build

Build the project locally and fix all compiler errors before pushing or
creating a PR. Use the appropriate build tool for the repo (`xcodebuild`,
`./gradlew`, `fvm flutter build`). Do not push code that doesn't compile.

### 4. PR description

When creating the PR, check for a PR template in the repo (e.g.
`.github/pull_request_template.md`). If one exists, fill it out completely.
If the repo has no template, write a concise description and include a
"How to Test" section with steps to verify the change.

---

Completion happens in two stages.

**Stage 1 — Implementation complete:**
1. Create a draft pull request using the GitHub CLI. The PR description must
   include a test plan section covering:
   - **Automated tests:** list the test files/suites added and what scenarios they cover
   - **Manual tests:** step-by-step scenarios the developer should verify by hand before approving
2. Show me the PR URL
3. Add Copilot as a reviewer: `gh api /repos/OWNER/REPO/pulls/PR_NUMBER/requested_reviewers --method POST --field 'reviewers[]=copilot-pull-request-reviewer[bot]'`
4. Print the test plan to the console, then ask: "Is this pull request ready for review?"

From this point, continue responding to any prompts to refine the solution.
After every response, ask: "Is this pull request ready for review?"

**Stage 2 — Ready for review:**
When the developer answers yes:
1. Add a comment to the Jira ticket summarizing what was implemented; note
   explicitly that both the work and this comment were completed by Claude
2. Mark the pull request as Ready for Review using the GitHub CLI
3. Remove the worktree

---

## Pull Request Reviews

When Claude completes the implementation it opens a draft PR and begins asking after every response whether it's ready for review. Use this time to read the diff, prompt Claude for refinements, or push your own changes to the branch. When you're satisfied, tell Claude the PR is ready — it will add the Jira comment and mark the PR as Ready for Review, making it visible to the rest of the team.

> **Note on PR descriptions:** Claude will generate the PR description automatically. A standard template for PR descriptions is planned — see the Open Questions section of the main guidelines.
