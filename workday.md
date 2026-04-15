# Workday Execution

Your job during the workday is **oversight, not writing code**. Claude selects cards to work on by querying Jira, pre-flights each one with you, implements the changes, and prepares pull requests. You answer pre-flight questions, respond to blockers, and review diffs before PRs are opened.

Each ticket produces one pull request. You control how many cards run in parallel — just say no when asked if you want to prepare another.

## Before You Start

### Jira CLI Setup

If you're on a new machine or setting up a new project, complete these steps before running the workday execution prompt.

**Step 1 — Install jira CLI**

```bash
brew tap ankitpokhrel/jira-cli
brew install jira-cli
```

**Step 2 — Get an API token**

Go to https://id.atlassian.com/manage-profile/security/api-tokens and create a new token. Keep it handy for the next step.

**Step 3 — Store the token in macOS Keychain**

Run this in a **separate terminal window** (not the one running Claude, to avoid sharing credentials):

```bash
security add-generic-password -s jira-cli -a YOUR_EMAIL@example.com -w YOUR_TOKEN
```

Replace `YOUR_EMAIL@example.com` and `YOUR_TOKEN` with your values. The service name `jira-cli` and account (email) are what jira-cli looks for natively.

**Step 4 — Run `jira init`**

```bash
jira init
```

Follow the prompts: choose Cloud vs. On-Premise, enter your Jira base URL, and specify the project key. This generates `~/.config/.jira/.config.yml`.

**Step 5 — Install direnv and set up `.envrc`**

direnv ensures the correct Jira config is loaded whenever you enter the project directory.

```bash
# Install direnv if not already installed
brew install direnv

# Add the shell hook to ~/.zshrc (if not already present)
eval "$(direnv hook zsh)"
```

Create `.envrc` in the project root:

```bash
export JIRA_CONFIG_FILE=/path/to/project/.jira.yml
```

Then allow it:

```bash
direnv allow
```

---

### Setup: Eliminate Permission Prompts

By default, Claude Code asks for permission every time it runs a `jira` CLI command. Add it to your allowed tools once and the prompts go away. Add the following to your project's `.claude/settings.json` (or `~/.claude/settings.json` to apply across all projects):

```json
{
  "allowedTools": ["Bash(jira *)"]
}
```

This grants Claude permission to run any `jira` CLI command without prompting. See the [Claude Code Setup](ai-assisted-development-guidelines.md#claude-code-setup) section in the main guidelines for a full allowlist covering git, GitHub CLI, and platform build tools.

### Jira CLI Command Reference

Credentials and config are pre-configured in the environment — no extra auth steps needed.

**Common commands:**

```bash
# View a ticket
jira issue view ISSUE-KEY

# Create a story with parent epic and fix version
cat description.md | jira issue create -tStory -pPROJ -s"Title" --parent EPIC-KEY --fix-version 0.2 --no-input

# Update a ticket description
cat file.md | jira issue edit ISSUE-KEY --no-input

# Link two issues
jira issue link ISSUE-1 ISSUE-2 Relates

# Add a watcher
jira issue watch ISSUE-KEY "Full Name"

# Add a ticket to a sprint
jira sprint add SPRINT-ID ISSUE-KEY
```

**Description format (markdown):**

```markdown
### Description formatted by Claude

## Story
**In order to** …
**As a** …
**I want** … **so that** …

## Acceptance Criteria
\`\`\`gherkin
Scenario: 1 - …
Given …
When …
Then …
\`\`\`
(Each scenario in its own code block, numbered)

## Implementation Notes
(optional)
```

**Notes:**
- Always pipe descriptions with `cat` — don't strip the attribution header
- Use `--fix-version` for the version field, not labels

---

## Merged PR Review

Before selecting new work, Claude checks for in-progress cards that may already be done.

Claude queries Jira for all in-progress cards assigned to you, then uses the GitHub CLI to find pull requests whose source branch contains each ticket's ID. For each card with a merged PR, Claude asks: "Is [TICKET-ID] — [title] complete?"

**If yes:**
- Set the card status to "Acceptance Testing"; if that status is not available, set it to "Ready for QA"
- Check the associated worktree:
  - If the worktree is clean and all commits have been pushed: delete the worktree silently
  - If the worktree is not clean or has unpushed commits: ask "This worktree has local changes or unpushed commits — should I commit, push, and delete it, or leave it in place?"

**If no:** leave the card and worktree as-is and move on.

Once all cards with merged PRs have been reviewed, ask: "Are there any other cards you've completed that I should close out?" If yes, ask for the IDs and follow the same completed card workflow for each: set the status to "Acceptance Testing" (or "Ready for QA" if unavailable), and handle the worktree as described above.

Once all completed cards have been handled, proceed to worktree resume.

---

## Worktree Resume

Before presenting card options, Claude scans existing git worktrees and cross-references them with your open in-progress Jira cards. If any worktrees match an open card, they are surfaced first:

```
Worktrees with in-progress work:
1. PROJ-123 — Fix login timeout  [claude/PROJ-123/fixLoginTimeout]
2. Skip — start a new card
```

If you select a worktree, Claude skips card selection and pre-flight and resumes execution of that card directly. If you select "Skip", Claude proceeds to card selection as normal.

---

## Card Selection

While cards are being presented, Claude kicks off the pr-team-review skill in
the background (org inferred from the git remote, last 7 days). The result is
only surfaced when Claude offers to prepare another card — if your review share
is below the team average, Claude will tell you how far below and ask if you'd
rather work on open PRs instead.

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

## Per-Card Pre-Flight

Before touching any code for a card, Claude reads the ticket, identifies any ambiguities or decisions that aren't answerable from the codebase alone, and asks them all at once. Wait for answers before Claude proceeds.

After receiving your answers, Claude enters plan mode and presents an implementation plan before writing any code. The plan covers:
- Summary of what will be implemented
- Files to be created or modified
- Key design decisions
- Test approach

Claude waits for you to explicitly say "execute" (or equivalent) before creating the worktree and beginning implementation.

If there are no upfront questions, Claude skips directly to the plan.

---

## Execution

Run this prompt once to start the workday.

```
Before doing anything else, print: "▶ Setup checks"

Run the following setup checks:

1. Run `which jira`. If jira is not installed, tell the developer and offer to
   install it:
   ```
   brew tap ankitpokhrel/jira-cli
   brew install jira-cli
   ```
   Wait for the developer to confirm installation before proceeding.

2. Check whether JIRA_CONFIG_FILE is set in the environment. If it is not set,
   the project is not configured for Jira CLI. Walk the developer through setup
   in order:

   a. If jira was just installed or is now available: ask for the developer's
      Atlassian email — you'll substitute it into all commands below.

   b. Direct the developer to https://id.atlassian.com/manage-profile/security/api-tokens
      to create an API token. Tell them to come back once they have it.

   c. Tell the developer to run the following command in a **separate terminal
      window** (not this one, to avoid sharing credentials with Claude), replacing
      the placeholders with their actual values:
      ```
      security add-generic-password -s jira-cli -a DEVELOPER_EMAIL -w THEIR_TOKEN
      ```
      Wait for the developer to confirm this is done.

   d. Tell the developer to run `jira init` and walk through the prompts
      (Cloud vs. On-Premise, base URL, project key). Wait for confirmation.

   e. Check whether direnv is installed with `which direnv`. If not, offer to
      install it:
      ```
      brew install direnv
      ```
      Then ask the developer to add the following to ~/.zshrc (or ~/.bashrc) if
      not already present:
      ```
      eval "$(direnv hook zsh)"
      ```
      Then create `.envrc` in the project root:
      ```
      export JIRA_CONFIG_FILE=/path/to/project/.jira.yml
      ```
      Then run `direnv allow` in the project directory. Wait for confirmation.

   Once all setup steps are confirmed complete, proceed.

If both checks pass (jira is installed and JIRA_CONFIG_FILE is set), skip
setup entirely and proceed directly to the merged PR review.

---

Print: "▶ Merged PR review"

First, run the merged PR review: query my in-progress Jira cards assigned to
me, then use the GitHub CLI to find pull requests whose source branch contains
each ticket ID. For each card with a merged PR, ask me if the card is complete.

If yes:
- Set the card status to "Acceptance Testing"; if unavailable, set it to
  "Ready for QA"
- Check the associated worktree. If clean and fully pushed, delete it. If not,
  ask: "This worktree has local changes or unpushed commits — should I commit,
  push, and delete it, or leave it in place?"

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

In parallel with card selection, run the pr-team-review skill in the background:
- Check if the pr-team-review skill is available in the current project.
  If not, ask: "I'd like to check your PR review load, but the pr-team-review
  skill isn't in this project. Can I fetch it from github.com/heliumfoot/ripley?"
  If yes: `gh api /repos/heliumfoot/ripley/contents/pr-team-review.md -H 'Accept: application/vnd.github.raw+json'`
  and follow those instructions. If no, skip the review load check entirely.
- Infer the org from `git remote get-url origin`
- Use a 7-day time window
- Get the current user with `gh api /user --jq '.login'`
- Run the skill non-interactively by supplying its required inputs explicitly:
  use the inferred org/repo scope as the answer to the repos question, and
  use "last 7 days" as the answer to the time-window question; suppress all output
- Store the current user's share % for later use
- Also store the number of reviewers included in the pr-team-review output for
  that 7-day window; compute and store the team average share % as
  `100% / reviewer count` (do not assume the skill prints a team average)

Begin card selection: query
in-progress cards assigned to me in the current sprint, sorted by rank. If
there are none, fall back to unassigned in-progress cards in the current
sprint. Present them numbered with key and title; mark unassigned cards with
[unassigned]. Add "None of these" as the last option and ask me to select one.

When no in-progress cards remain or I select "None of these", query the top 5
to-do cards in the current sprint, sorted by rank. Add "Provide a card ID" as
the last option.

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
- Write code that follows these principles:
  - **Human readable** — prefer clarity over cleverness
  - **Modularized** — break logic into small, focused units
  - **DRY** — don't repeat yourself; extract shared logic
  - **No magic numbers** — give constants meaningful names
  - **Self-documenting names** — variables, functions, and types should explain themselves without comments
  - **Prefer immutability** — avoid mutable state where possible
- Log each non-obvious decision so it appears at review time
- If you hit uncertainty that a quick question would resolve better than your
  best guess, ask — you don't need to be fully blocked to interrupt. Prefer
  a short question over a decision the developer might want to make themselves
- Whenever you ask me a question or report a blocker during execution, end the
  message with the working directory path: "Working directory: [full path to worktree]"

**Before creating the PR, complete every step in the [Pre-PR Checklist](#pre-pr-checklist).** If a step doesn't apply, ask the developer before skipping it.

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
and anything that doesn't match existing patterns. Also verify the coding
guidelines were followed: code is human readable, logic is modularized, no
repeated code, no magic numbers, names are self-documenting, and immutability
is preferred. Fix any issues found before proceeding.

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
```

---

## Pull Request Reviews

When Claude completes the implementation it opens a draft PR and begins asking after every response whether it's ready for review. Use this time to read the diff, prompt Claude for refinements, or push your own changes to the branch. When you're satisfied, tell Claude the PR is ready — it will add the Jira comment and mark the PR as Ready for Review, making it visible to the rest of the team.

Every draft PR includes a test plan section in the description covering:
- **Automated tests:** the test files/suites added and the scenarios they cover
- **Manual tests:** step-by-step scenarios to verify by hand before approving

The test plan is also printed to the console alongside the "Is this pull request ready for review?" prompt.

> **Note on PR descriptions:** Claude will generate the PR description automatically. A standard template for PR descriptions is planned — see the Open Questions section of the main guidelines.
