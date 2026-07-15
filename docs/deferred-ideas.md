# Ripley — Open Questions & Deferred Ideas

These are unresolved design decisions and ideas to incorporate in a future
iteration of the Ripley process. None of them are blocking the current workflow
— they're improvements to build toward.

This file is a design backlog. It lives in the repo only and is deliberately
**not** synced into `~/.claude`, so it never loads into a working session's
context. The active process reference is the `ripley-guidelines` skill; the
always-on rules are in the global `CLAUDE.md`.

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

This appears as a standard macOS notification and works even when the terminal is in the background. Requires `Bash(osascript *)` in your `allowedTools` — see the Claude Code Setup section in the `ripley-guidelines` skill.

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

### Re-estimating cards

The current guidelines treat complexity estimates (S/M/L/XL) as set once at ticket creation. A workflow for re-estimation may be needed — for example when work turns out to be larger than expected, or when a card is split or merged.

---

## Postscript: Why "Ripley"

This project is named after Ellen Ripley from *Alien*.

The name fits on two levels.

First, the oversight model. Ripley is the one who stays calm, assesses the situation, and gets things done while others panic — and she insists on human judgment at every critical decision, famously skeptical of automated systems left to run on their own. That's exactly what this process enforces: Claude does the work, but the developer remains in control at every decision point that matters.

Second, the power loader. In the climax of *Aliens*, Ripley doesn't fight the alien queen bare-handed — she climbs into a powered exoskeleton that amplifies what she can do. She's still the one in control, still directing the fight. The machine just does the heavy lifting.

That's the model here. The developer is Ripley. Claude is the suit.
