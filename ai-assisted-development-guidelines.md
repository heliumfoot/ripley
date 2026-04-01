# Project Ripley: AI-Assisted Development Guidelines

## Purpose

These guidelines help the team get consistent, measurable value from AI tools — not just faster code writing, but better daily output, clearer milestone tracking, and more accurate delivery forecasting without the overhead of manually maintaining story points.

---

## The Three-Tool Model

Three AI tools cover different jobs. Using the right one for each task is what makes the system work.

| Tool | Purpose | When to use it |
|------|---------|---------------|
| **GitHub Copilot** (in-editor) | Writing, completing, and refactoring code | Anytime you're actively coding in Android Studio or VS Code |
| **Claude Code** (CLI) | Goal-setting, evaluation, Jira updates, milestone reviews, forecasting | Everything else — daily goals, end-of-day evaluation, planning, Jira |

**Why Claude Code for goal-setting and not just code evaluation?**

Claude Code can read yesterday's actuals and your current milestone file before helping you write today's goals — so it can tell you whether you're planning the right work, not just whether the goals are well-worded. A chat interface can't do that without a lot of copy-pasting. Use Claude.ai only as a fallback when you're away from your dev machine.

The goal is to keep Copilot handling code generation inside the editor, and Claude Code handling everything else — so each tool stays in its lane.

---

## Daily Workflow

### Morning: Write Your Daily Goals

At the start of each workday, Claude drafts a set of goals for you based on context it assembles automatically. Your job is to review, correct, and confirm — not to write from scratch.

Use Claude Code for this. It will read yesterday's actuals, query Jira for your in-progress and to-do tickets, and interview you briefly about each in-progress card before producing the draft.

#### Step 1: In-progress card interview

For each ticket currently In Progress in Jira, Claude asks two questions:

1. What specifically remains on [TICKET-ID]: [title]?
2. Any blockers or surprises since you started?

Based on your answers, Claude re-estimates the remaining effort as S/M/L/XL and flags if the card has grown beyond its original estimate. This remainder — not the original estimate — is what feeds into today's goal draft and the forecast.

#### Step 2: Goal draft

Claude generates a draft in the goal format below, incorporating:
- Remaining work on in-progress cards (from the interview above)
- Any PARTIAL or NOT STARTED goals carried over from yesterday's actuals
- To-do tickets assigned to you in the current sprint; falls back to unassigned sprint tickets if needed

Review the draft, adjust anything that doesn't reflect your actual plan, fill in the "What I'm explicitly NOT doing today" section, and confirm.

**Goal format:**

```
## Daily Goals — [Date]

**Project:** [Project name]
**Milestone:** [Current milestone name or "N/A"]
**Jira tickets:** [Comma-separated ticket IDs, or "none"]

### Goals

1. [Specific, observable outcome — not "work on X" but "X is done when Y"]
2. ...

### Known blockers or risks
- [Anything that could prevent completion]

### What I'm explicitly NOT doing today
- [Helps AI and teammates understand scope boundaries]
```

**Morning prompt:**

```
Read yesterday's actuals from logs/[date].md and the current milestone
definition from milestones/[milestone].md. Then run the Jira CLI to get my
in-progress and to-do tickets for the current sprint.

For each in-progress ticket, ask me:
1. What specifically remains on this ticket?
2. Any blockers or surprises since you started?

After I answer, re-estimate the remaining effort as S/M/L/XL and note if the
card has grown. Then draft today's goals incorporating: remaining in-progress
work, any carryover from yesterday, and next-up to-do tickets. Flag if the
total load looks unrealistic given my historical capacity.
```

Act on any flags, fill in what you're not doing today, then save the finalized goals.

---

### Workday Execution: Let Claude Do the Work

See **[workday.md](workday.md)** for the full workday execution workflow, including card selection, pre-flight, parallel execution, and the PR review requirement.

---

### End of Day: Record Actuals and Get Evaluated

At the end of the day, fill in what actually happened and have Claude evaluate it.

**Use Claude Code for this step.** Save your actuals to a file (e.g. `logs/2026-03-15.md`) and run Claude Code in your project directory. It can read the actuals file, your milestone definition, and relevant code or commit history without you copying and pasting anything. This also means the evaluation lives alongside your code, not in a chat window you'll lose.

**Actuals format:**

```
## Daily Actuals — [Date]

### Goal outcomes

1. [Goal 1 text] → [DONE / PARTIAL / NOT STARTED]
   - What was completed: ...
   - What wasn't: ...
   - Reason if not done: ...

2. ...

### Unplanned work
- [Anything significant you did that wasn't in the goals, and why]

### Blockers encountered
- [New blockers discovered today]

### Artifacts
- PRs opened/merged: ...
- Commits: ...
- Other: ...
```

**Evaluation prompt** (tell Claude Code where your files are):

```
Read my goals and actuals for today from logs/[date].md, and my current
milestone definition from milestones/[milestone].md. Evaluate:
1. What percentage of the planned work was completed?
2. Were incomplete items due to poor scoping, external blockers, or underestimation?
3. Is there anything in the unplanned work that suggests my priorities were wrong?
4. What should I carry forward to tomorrow?
Keep the response concise and direct.
```

Claude Code will read the files directly. Append its evaluation to the same log file so everything for a given day is in one place. Over time, this log becomes the data that drives forecasting.

---

## Milestone Workflow

### Defining a Milestone

A milestone is only useful for AI evaluation if it has explicit, testable completion criteria — not vague descriptions. When a milestone is created, write it in this format:

```
## Milestone: [Name]
**Target date:** [Date]
**Project:** [Project name]

### What "done" means
- [ ] [Specific, verifiable criterion]
- [ ] [...]
- [ ] [...]

### What is explicitly out of scope
- [Features or fixes intentionally deferred to a later milestone]

### Open Jira tickets in scope
- [PROJ-123]: [Brief description]
- ...

### Known risks at milestone start
- [Technical unknowns, dependencies, etc.]
```

Store this in your repo (e.g., `milestones/milestone-N.md`) or in a Jira epic description. The important thing is that it's readable by AI when you do milestone reviews.

---

### Milestone Progress Review

Run a milestone review at least once per week. **Use Claude Code for this** — it can pull the Jira ticket status, read your milestone file, and scan recent daily logs all in one session without manual copy-pasting.

**Review prompt:**

```
Do a milestone review for [milestone name].
- Read the milestone definition from milestones/[milestone].md
- Run the Jira CLI to list all open tickets for epic [EPIC-ID] with their current status
- Read daily logs from the past week in logs/
Then evaluate:
1. What percentage of the milestone criteria are verifiably complete?
2. Which criteria are at risk based on what's still open or blocked?
3. Based on the past week's daily logs, is the target date still realistic?
4. What is the single highest-leverage thing to focus on this week to protect the target date?
```

---

## Forecasting Without Manual Story Points

The traditional Fibonacci-point approach requires someone to manually estimate every ticket, which is expensive to maintain. This section replaces that bottleneck with AI-assessed complexity that calibrates automatically over time.

### Step 1: AI Complexity Assessment at Ticket Creation

When a new Jira ticket is created, use Claude Code in your project directory with this prompt. Because Claude Code can read the codebase directly, you don't need to manually paste code context — just point it at the right area:

```
Here is a Jira ticket we just created: [paste ticket description]

It touches [describe area, e.g. "the auth module" or "the data sync layer"].
Look at the relevant code in that area and estimate complexity using this scale:
  S — a few hours, well-understood change
  M — half a day to a full day, some uncertainty
  L — 2–3 days, meaningful unknowns or cross-cutting changes
  XL — more than 3 days, significant unknowns or architectural impact

Return: size (S/M/L/XL), a one-sentence rationale, and any questions
that, if answered, would change the estimate.
```

Add the AI's size estimate as a label or custom field in Jira. This takes 2–3 minutes per ticket and does not require team consensus meetings.

### Step 2: Track Actuals Automatically

Your daily log files already contain what was completed each day. Claude Code can compile the calibration table for you:

```
Read all daily logs in logs/ and extract every completed Jira ticket.
For each one, note the date completed and the size label from Jira.
Build a table: Date | Ticket | Size | Developer | Notes
Then calculate average and range of completion time per size (S/M/L/XL)
based on how many tickets of each size were completed per day.
```

After a few weeks of daily logs, you'll have a real calibration curve. This replaces the manual "points to hours" conversion you've been doing.

### Step 3: Forecast Delivery Date

With a calibrated table and your Jira backlog, ask Claude Code:

```
Using the calibration data you just built, and the current open tickets for
epic [EPIC-ID] (pull them from Jira now), forecast a completion date range
for milestone [name].
Factor in:
- [X] developers at roughly [Y] productive hours/day
- Scope creep: look at how many new tickets were added to this epic per week
  over the past month and include that rate in the projection
- Planned absences: [list any known]

Return: optimistic date, realistic date, pessimistic date, and which tickets
carry the most forecast risk.
```

**For in-progress tickets:** use the remaining-effort estimate from the morning interview (S/M/L/XL re-estimate based on what specifically remains), not the original size label. This keeps the forecast grounded in current reality rather than initial estimates that may no longer reflect the work left.

You can rerun this forecast daily or weekly with updated ticket status. Because the inputs are structured, the forecast is reproducible and explainable to stakeholders.

---

## Jira Integration

### Using Claude Code + Jira CLI

Claude Code can run Jira CLI commands directly, which keeps developers in the terminal instead of the Jira UI. Because Claude Code understands context — your daily log, your milestone, what you just finished — it can update Jira more accurately than a one-shot command generator.

**Updating ticket status after completing a goal:**

```
# In Claude Code, after finishing work:
Mark PROJ-123 as Done in Jira and add a comment summarizing what was
implemented based on today's log in logs/[date].md
```

**Pulling milestone ticket status for a review:**

```
List all open tickets in epic PROJ-50, showing status, assignee, and size label
```

**Adding a complexity label after estimation:**

```
Add the label 'size-M' to ticket PROJ-456 in Jira
```

**Bulk-updating after a productive day:**

```
Based on today's actuals in logs/[date].md, update the status of all
completed tickets in Jira and add brief comments for each
```

The goal is that developers never open the Jira UI for routine updates. Jira stays current because it's low-friction to update, not because someone is policing it.

> **Note on Copilot CLI:** If some developers prefer Copilot CLI for simple Jira status changes, that's fine. The advantage of Claude Code is context — it can write meaningful Jira comments derived from your daily log rather than one-liners. For anything beyond a status change, use Claude Code.

> **Jira CLI setup and command reference** have moved to [workday.md](workday.md#before-you-start), which is the primary working document for day-to-day use.

### What AI Keeps Updated vs. What Humans Own

| Task | Who does it |
|------|------------|
| Creating tickets | Human (AI can draft, human creates) |
| Setting complexity size label | Human, with AI suggestion |
| Updating ticket status | AI via CLI, triggered by developer |
| Writing ticket comments (progress, blockers) | AI via CLI, from daily log content |
| Closing tickets | Human, after confirming done criteria |
| Editing milestone scope | Human only |

---

## Working on Multiple Projects

When a developer is working across two or more projects in the same day, adjust the daily goal format:

```
## Daily Goals — [Date]

### Project A — [Name]
**Milestone:** ...
**Goals:**
1. ...

### Project B — [Name]
**Milestone:** ...
**Goals:**
1. ...

### Context-switch budget
I plan to switch between projects [N] times today.
Deep work blocks: [describe when you'll focus on each]
```

AI evaluation should then assess each project independently but also flag if the total load across projects appears unrealistic.

### Cards That Span Multiple Repos

When a single Jira card requires changes in more than one repository, a few adjustments keep things coherent.

**Starting the session:** Open Claude Code from a parent directory that contains all relevant repos, or from the primary repo and provide explicit relative paths to the others. Name the repos upfront so Claude knows the layout before touching code:

> "This card touches both `repo-a` and `repo-b`. The repos are siblings — `../repo-b` is the path relative to the current directory."

**Worktrees:** Create a branch in each affected repo under the same ticket ID:
- `claude/PROJ-123/fixLoginTimeout` in `repo-a`
- `claude/PROJ-123/fixLoginTimeout` in `repo-b`

**Pull requests:** Open one PR per repo. The PR description in each should name all repos involved and link to the others, so reviewers have the full picture.

**Pre-flight:** Claude should ask during pre-flight which repos are in scope and confirm the relative paths before any implementation begins.

### Solo-Developer Projects

When you are the only developer on a project, the daily log and milestone review are especially important — there is no peer visibility to catch drift. Compensate by:

1. Being more explicit in your goals about *why* you're doing something, not just what (this helps AI evaluate whether the work is actually moving the milestone)
2. Running a milestone review every week without fail, even if it's brief
3. Flagging in your daily goals when you're doing exploratory/uncertain work, which should be estimated as XL regardless of apparent scope

---

## Claude Code Setup

To get full value from the workday execution workflow, configure Claude Code to run tool calls without prompting for each one. The developer's job is to review diffs and PRs — not to approve every terminal command.

Add the following to `.claude/settings.json` in each project repo (or `~/.claude/settings.json` to apply globally). Adjust for your platform:

```json
{
  "allowedTools": [
    "Bash(git *)",
    "Bash(jira *)",
    "Bash(gh *)",
    "Bash(osascript *)",
    "Bash(./gradlew *)",
    "Bash(flutter *)",
    "Bash(xcodebuild *)"
  ]
}
```

| Tool pattern | Purpose |
|---|---|
| `Bash(git *)` | Branch, commit, push, worktree management |
| `Bash(jira *)` | All Jira CLI operations |
| `Bash(gh *)` | GitHub CLI — PRs, branch queries |
| `Bash(osascript *)` | macOS system notifications for blockers |
| `Bash(./gradlew *)` | Android builds and tests |
| `Bash(flutter *)` | Flutter builds and tests |
| `Bash(xcodebuild *)` | iOS builds and tests |

Add or remove entries based on your project's tech stack.

---

## Getting Started

### Week 1
- [ ] Each developer picks a format for storing daily goals + actuals (file, Notion, Jira comment — just be consistent)
- [ ] Write milestone definitions for all active milestones in the structured format above
- [ ] Start daily goals + end-of-day evaluation for all team members

### Week 2–3
- [ ] Add AI complexity size labels to all open Jira tickets in current milestone scope (use Claude Code in each repo)
- [ ] Set up Jira CLI and confirm Claude Code can run it (test with a status update on one ticket)
- [ ] Run first milestone progress review using Claude Code and the prompt above

### Week 4+
- [ ] Ask Claude Code to compile the first actuals calibration table from daily logs
- [ ] Run first AI-generated delivery forecast and compare to your intuition
- [ ] Adjust the process based on what's working — these guidelines are a starting point, not a contract

---

## Prompt Quick Reference

| Task | Prompt to use |
|------|--------------|
| Refine morning goals | [Morning refinement prompt](#morning-write-your-daily-goals) |
| Evaluate end-of-day actuals | [Evaluation prompt](#end-of-day-record-actuals-and-get-evaluated) |
| Assess ticket complexity | [Complexity assessment prompt](#step-1-ai-complexity-assessment-at-ticket-creation) |
| Milestone progress review | [Review prompt](#milestone-progress-review) |
| Delivery date forecast | [Forecast prompt](#step-3-forecast-delivery-date) |

---

## Open Questions & Deferred Ideas

These are unresolved design decisions and ideas to incorporate in a future iteration of these guidelines. None of them are blocking the current workflow — they're improvements to build toward.

---

### Shared `/workday` slash command across all projects

The workday execution prompt should be available as a Claude Code slash command (`/workday`) so developers don't need to copy-paste it each morning. Because it should work across all projects and all developers, it needs to be defined in a shared location rather than per-repo — likely a shared dotfiles repo or a team-wide Claude configuration that gets distributed to each developer's machine.

Open questions: where does the canonical command definition live, how do developers get updates when the prompt changes, and does it need any per-project parameterization (e.g. different Jira project keys)?

---

### Where do daily logs live?

The current guidelines leave log storage to each developer's discretion. The preferred direction is a **shared Git repo** (e.g. `team-daily-logs`) with per-developer directories:

```
logs/
  alice/2026-03-15.md
  bob/2026-03-15.md
```

This gives the whole team visibility into each other's goals and history, and lets Claude Code read across all developers' logs for forecasting. Stakeholder visibility into this repo is not a requirement. Not yet adopted — finish the first pass of the guidelines before incorporating.

---

### Daily goals as input to workday execution

Currently, workday execution is started by the developer providing a list of Jira ticket IDs directly. The natural next step is to connect the morning goal-setting workflow so that the finalized daily goals feed automatically into workday execution — Claude reads the goals file and derives the ticket list rather than the developer providing it manually.

This also opens up using the "what specifically remains" context from the morning in-progress card interview to give Claude a sharper starting point per card, rather than relying solely on the Jira ticket description.

To be incorporated once the daily goal workflow and workday execution are both stable in practice.

---

### Collaborative standup

Instead of each developer running their own morning goal check-in independently, standup could be extended so that everyone evaluates yesterday's goals and sets new ones together — with Claude facilitating. Everyone would share how they did and what they're targeting for the day.

Open questions: shared screen vs. each person runs their own session and shares output? How does this work for distributed teams?

---

### Claude suggests goals from Jira

Rather than waiting for a developer to write goals from scratch, Claude could propose a starting point by pulling assigned cards from the current sprint. If a developer doesn't have enough assigned cards, Claude falls back to unassigned cards in the current sprint, then the upcoming sprint. Developer confirms or adjusts. Reduces morning friction and keeps goals grounded in sprint commitments.

---

### Milestones defined as Jira fix versions

Milestones will eventually be defined in Jira as a Fix Version/Release rather than as markdown files in the repo. Claude Code would query the fix version to get milestone scope, making Jira the authoritative source. The `milestones/` directory approach in the current guidelines will likely be revised.

Open question: Jira fix versions don't have a structured "done criteria" field — need to decide where that definition lives (fix version description, a pinned comment, or a small supplementary file).

---

### Weekly stakeholder milestone report

After the internal weekly milestone review, Claude should generate a second, shorter stakeholder-facing summary: plain language, focused on what's done, what's next, whether the target date is on track, and any risks. Distinct from the detailed internal review. Should be generatable with a single additional Claude Code prompt.

---

### Forecasting improvements

Several improvements to the forecasting section are planned:

**Deterministic forecast program** — Rather than prompting Claude to reason through the forecast conversationally, write a program that computes it deterministically. Inputs: calibration table, remaining tickets with sizes, developer availability, scope creep rate. Output: date ranges. Benefits: reproducible, diffable week-over-week, fast. Claude's role shifts to writing/maintaining the program and interpreting its output.

**Multi-scenario forecasting** — Present forecasts as named scenarios driven by three independent factors: team strength (absentees), churn (scope creep rate), and velocity (relative to baseline). This makes it actionable — "if we freeze scope we hit the date; if churn continues we need to cut" — rather than a single blended range.

**Forecast impact of adding cards** — When new cards are added to a milestone mid-stream, immediately forecast the impact on the delivery date. Makes the cost of scope additions visible in real time rather than at the next weekly review.

**Per-developer calibration curves** — Should the S/M/L/XL → hours calibration be per-developer rather than team-wide? More accurate, but requires more data to be reliable and raises questions about whether it feels like performance tracking. Needs a deliberate decision.

---

### Blocker notifications in advanced mode

When Claude is running in parallel across multiple worktrees, it needs a way to interrupt the developer that is hard to miss. A developer overseeing multiple agents may not be watching any one terminal session when a blocker surfaces.

**Recommended approach (macOS):** Claude fires a system notification via `osascript`:

```bash
osascript -e 'display notification "PROJ-123 is blocked: [reason]" with title "Ripley — Blocker"'
```

This appears as a standard macOS notification and works even when the terminal is in the background. Requires `Bash(osascript *)` in your `allowedTools` — see the [Claude Code Setup](#claude-code-setup) section.

**Fallback (cross-platform):** Claude appends the blocker to a `blockers.md` file in the repo root. The developer can keep this file open in a separate window or monitor it on a short polling interval. Less immediate than a system notification but works on any OS.

---

### Test coverage as proof of completion

Unit tests are now defined in the workday execution workflow. Still to resolve: integration tests — whether they are required, when they apply, and how they interact with the unit test standard already in place.

---

### Code generation guidelines for Claude

Claude needs explicit guidelines for how it generates code — covering things like naming conventions, file and module structure, error handling patterns, test coverage expectations, and code style. Without these, Claude defaults to its own judgment, which may be inconsistent with how the team writes code or with each other across cards.

Guidelines should be layered:
- **Shared** — team-wide conventions that apply to all developers and all cards, maintained collectively (e.g. `docs/claude-code-guidelines.md`)
- **Personal** — per-developer preferences and overrides, for things like preferred patterns, areas of the codebase a developer owns, or stylistic choices that differ from the team default

Claude should load the shared guidelines first, then the developer's personal guidelines on top. Personal guidelines take precedence where they conflict with shared ones.

To be defined — needs input from the team on current conventions, decisions on what belongs in shared vs. personal, and a file location convention for personal guidelines (e.g. `~/.claude/[project]-guidelines.md` or a `dev/[name].md` in the repo).

---

### Architectural document for per-card decisions

Claude needs access to an architectural reference when making implementation decisions on individual cards — covering things like which layers own which responsibilities, how the codebase is structured, key patterns in use, and decisions that have already been made and shouldn't be relitigated. Without this, Claude may implement things in ways that are locally correct but architecturally inconsistent.

This document should be readable by Claude during workday execution — either as a standalone file (e.g. `docs/architecture.md`) or as part of the same context loaded alongside code generation guidelines. It should describe the current architecture, not aspirational state, and be kept up to date as the codebase evolves.

To be defined — likely a collaborative effort between the team and Claude, since Claude can help draft it from the existing codebase.

---

### Pull request description template

When Claude opens a PR after workday execution, it generates the description automatically. A standard template is needed so PR descriptions are consistent and useful to reviewers — covering at minimum: what changed, which Jira ticket it closes, and a brief testing notes section. Template to be defined and added to the guidelines; Claude should reference it when opening PRs.

---

### Energy-aware card sorting

Card selection now sorts by difficulty based on how many cards have been completed today — heavier cards first when fresh (fewer than 3 completed), lighter cards first when winding down (3 or more completed). This is a gentle default, not a rule; the developer always picks.

The insight is that cognitive energy is a depletable resource. A system that accounts for this — rather than treating every hour as fungible — leads to better output over a full day. See the [Difficulty indicator and sort order](workday.md#difficulty-indicator-and-sort-order) section in workday.md.

---

### Re-estimating cards

The current guidelines treat complexity estimates (S/M/L/XL) as set once at ticket creation. A workflow for re-estimation may be needed — for example when work turns out to be larger than expected, or when a card is split or merged.

---

## Postscript: Why "Ripley"

This project is named after Ellen Ripley from *Alien*.

The name fits on two levels.

First, the oversight model. Ripley is the one who stays calm, assesses the situation, and gets things done while others panic — and she insists on human judgment at every critical decision, famously skeptical of automated systems left to run on their own. That's exactly what this process enforces: Claude does the work, but the developer remains in control at every decision point that matters.

Second, the power loader. In the climax of *Aliens*, Ripley doesn't fight the alien queen bare-handed — she climbs into a powered exoskeleton that amplifies what she can do. She's still the one in control, still directing the fight. The machine just does the heavy lifting.

That's the model here. The developer is Ripley. Claude is the suit.

