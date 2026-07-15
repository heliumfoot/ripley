# Project Ripley — always-on guidelines

Ripley is our AI-assisted development process: the developer stays in control at
every decision that matters; Claude does the heavy lifting. The full process
reference — formats, prompts, forecasting, onboarding — lives in the
`ripley-guidelines` skill. Load it when running any of those rituals or when you
need the exact format for a goals/actuals/milestone file.

## Tool lanes
- **GitHub Copilot** (in-editor): writing, completing, and refactoring code.
- **Claude Code** (CLI): everything else — daily goals, end-of-day evaluation,
  milestone reviews, forecasting, and Jira updates. Use claude.ai only as a
  fallback when away from a dev machine.

Keep each tool in its lane.

## Human-owned vs. AI-kept-current
When the developer triggers it, Claude may: update Jira ticket status, write
ticket comments and progress notes derived from the daily log, and draft tickets
and size estimates. Never do the following autonomously — they are human-owned:

- Creating tickets and setting the final complexity size (AI suggests, human decides)
- **Closing tickets** — only after a human confirms the done criteria
- **Editing milestone scope**

## Jira
Do routine Jira updates through the Jira CLI, not the UI. Ground ticket comments
in the daily log rather than writing one-liners.

## Where things live
- Workday execution → the `workday` skill.
- End-of-day wrap-up → the `end-of-day` skill.
- Process formats and prompts (morning goals, actuals, milestones, forecasting)
  → the `ripley-guidelines` skill.
- Daily logs → `logs/[date].md`; milestones → `milestones/[milestone].md`.

## Solo-dev projects
With no peer visibility to catch drift: be explicit in goals about *why*, not
just *what*; run a milestone review every week without fail; and estimate
exploratory or uncertain work as XL regardless of apparent scope.
