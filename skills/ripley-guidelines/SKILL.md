---
name: ripley-guidelines
description: The team's AI-assisted development process reference — drafting morning daily goals, recording end-of-day actuals and evaluating them, defining milestones and running the weekly milestone review, and forecasting delivery without story points. Includes the exact file formats and the Claude Code prompts for each ritual, plus Jira CLI usage patterns, multi-project and multi-repo formats, and first-time Claude Code setup. Load when starting or running any of these, or when you need the required format for a goals, actuals, or milestone file.
---

# Project Ripley — process reference

This is the working reference for the Ripley process. The always-on rules (tool
lanes, human-owned vs. AI-kept-current, where things live) are in the global
`CLAUDE.md`; this skill holds the formats and prompts you pull in when actually
running a ritual.

**Why Claude Code for goal-setting and not just code evaluation?** Claude Code
can read yesterday's actuals and your current milestone file before helping you
write today's goals — so it can tell you whether you're planning the right work,
not just whether the goals are well-worded. A chat interface can't do that
without a lot of copy-pasting. Use claude.ai only as a fallback when you're away
from your dev machine.

---

## Morning: Write Your Daily Goals

At the start of each workday, Claude drafts a set of goals for you based on
context it assembles automatically. Your job is to review, correct, and confirm
— not to write from scratch.

Use Claude Code for this. It will read yesterday's actuals, query Jira for your
in-progress and to-do tickets, and interview you briefly about each in-progress
card before producing the draft.

### Step 1: In-progress card interview

For each ticket currently In Progress in Jira, Claude asks two questions:

1. What specifically remains on [TICKET-ID]: [title]?
2. Any blockers or surprises since you started?

Based on your answers, Claude re-estimates the remaining effort as S/M/L/XL and
flags if the card has grown beyond its original estimate. This remainder — not
the original estimate — is what feeds into today's goal draft and the forecast.

### Step 2: Goal draft

Claude generates a draft in the goal format below, incorporating:
- Remaining work on in-progress cards (from the interview above)
- Any PARTIAL or NOT STARTED goals carried over from yesterday's actuals
- To-do tickets assigned to you in the current sprint; falls back to unassigned sprint tickets if needed

Review the draft, adjust anything that doesn't reflect your actual plan, fill in
the "What I'm explicitly NOT doing today" section, and confirm.

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

## Workday Execution

The full workday execution workflow — card selection, pre-flight, parallel
execution, and the PR review requirement — lives in the `workday` skill. Start
it there rather than reproducing it here.

---

## End of Day: Record Actuals and Get Evaluated

At the end of the day, fill in what actually happened and have Claude evaluate
it. (The `end-of-day` skill runs the wrap-up; the format and evaluation prompt
below are the reference.)

**Use Claude Code for this step.** Save your actuals to a file (e.g.
`logs/2026-03-15.md`) and run Claude Code in your project directory. It can read
the actuals file, your milestone definition, and relevant code or commit history
without you copying and pasting anything. This also means the evaluation lives
alongside your code, not in a chat window you'll lose.

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

Claude Code will read the files directly. Append its evaluation to the same log
file so everything for a given day is in one place. Over time, this log becomes
the data that drives forecasting.

---

## Milestone Workflow

### Defining a Milestone

A milestone is only useful for AI evaluation if it has explicit, testable
completion criteria — not vague descriptions. When a milestone is created, write
it in this format:

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

Store this in your repo (e.g., `milestones/milestone-N.md`) or in a Jira epic
description. The important thing is that it's readable by AI when you do
milestone reviews.

### Milestone Progress Review

Run a milestone review at least once per week. **Use Claude Code for this** — it
can pull the Jira ticket status, read your milestone file, and scan recent daily
logs all in one session without manual copy-pasting.

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

The traditional Fibonacci-point approach requires someone to manually estimate
every ticket, which is expensive to maintain. This section replaces that
bottleneck with AI-assessed complexity that calibrates automatically over time.

### Step 1: AI Complexity Assessment at Ticket Creation

When a new Jira ticket is created, use Claude Code in your project directory with
this prompt. Because Claude Code can read the codebase directly, you don't need
to manually paste code context — just point it at the right area:

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

Add the AI's size estimate as a label or custom field in Jira. This takes 2–3
minutes per ticket and does not require team consensus meetings.

### Step 2: Track Actuals Automatically

Your daily log files already contain what was completed each day. Claude Code can
compile the calibration table for you:

```
Read all daily logs in logs/ and extract every completed Jira ticket.
For each one, note the date completed and the size label from Jira.
Build a table: Date | Ticket | Size | Developer | Notes
Then calculate average and range of completion time per size (S/M/L/XL)
based on how many tickets of each size were completed per day.
```

After a few weeks of daily logs, you'll have a real calibration curve. This
replaces the manual "points to hours" conversion you've been doing.

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

**For in-progress tickets:** use the remaining-effort estimate from the morning
interview (S/M/L/XL re-estimate based on what specifically remains), not the
original size label. This keeps the forecast grounded in current reality rather
than initial estimates that may no longer reflect the work left.

You can rerun this forecast daily or weekly with updated ticket status. Because
the inputs are structured, the forecast is reproducible and explainable to
stakeholders.

---

## Jira Integration

Claude Code can run Jira CLI commands directly, which keeps developers in the
terminal instead of the Jira UI. Because Claude Code understands context — your
daily log, your milestone, what you just finished — it can update Jira more
accurately than a one-shot command generator. (For what Claude may update
autonomously vs. what humans own, see the global `CLAUDE.md`.)

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

The goal is that developers never open the Jira UI for routine updates. Jira
stays current because it's low-friction to update, not because someone is
policing it.

> **Note on Copilot CLI:** If some developers prefer Copilot CLI for simple Jira
> status changes, that's fine. The advantage of Claude Code is context — it can
> write meaningful Jira comments derived from your daily log rather than
> one-liners. For anything beyond a status change, use Claude Code.

> **Jira CLI setup and command reference** live in the `workday` skill
> (`workday.md`), which is the primary working document for day-to-day use.

---

## Working on Multiple Projects

When a developer is working across two or more projects in the same day, adjust
the daily goal format:

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

AI evaluation should then assess each project independently but also flag if the
total load across projects appears unrealistic.

### Cards That Span Multiple Repos

When a single Jira card requires changes in more than one repository, a few
adjustments keep things coherent.

**Starting the session:** Open Claude Code from a parent directory that contains
all relevant repos, or from the primary repo and provide explicit relative paths
to the others. Name the repos upfront so Claude knows the layout before touching
code:

> "This card touches both `repo-a` and `repo-b`. The repos are siblings —
> `../repo-b` is the path relative to the current directory."

**Worktrees:** Create a branch in each affected repo under the same ticket ID:
- `claude/PROJ-123/fixLoginTimeout` in `repo-a`
- `claude/PROJ-123/fixLoginTimeout` in `repo-b`

**Pull requests:** Open one PR per repo. The PR description in each should name
all repos involved and link to the others, so reviewers have the full picture.

**Pre-flight:** Claude should ask during pre-flight which repos are in scope and
confirm the relative paths before any implementation begins.

---

## Claude Code Setup

To get full value from the workday execution workflow, configure Claude Code to
run tool calls without prompting for each one. The developer's job is to review
diffs and PRs — not to approve every terminal command.

Add the following to `.claude/settings.json` in each project repo (or
`~/.claude/settings.json` to apply globally). Adjust for your platform:

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

| Task | Prompt |
|------|--------|
| Refine morning goals | [Morning prompt](#morning-write-your-daily-goals) |
| Evaluate end-of-day actuals | [Evaluation prompt](#end-of-day-record-actuals-and-get-evaluated) |
| Assess ticket complexity | [Complexity assessment prompt](#step-1-ai-complexity-assessment-at-ticket-creation) |
| Milestone progress review | [Review prompt](#milestone-progress-review) |
| Delivery date forecast | [Forecast prompt](#step-3-forecast-delivery-date) |

---

Unresolved design decisions and ideas for future iterations of this process are
tracked in `docs/deferred-ideas.md` in the ripley repo (not synced into
`~/.claude`).
