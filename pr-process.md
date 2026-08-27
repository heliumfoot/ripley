# PR Process

A checklist for getting a pull request ready. Six steps before opening, three
for opening.

The ordering is the point: the cheap passes run before the expensive ones, and
nothing reaches a human reviewer that a machine could have caught first.

| # | Step | What it catches |
|---|---|---|
| **Before opening** | | |
| 1 | AC + plan check | scope the ticket never asked for |
| 2 | Self-review for fit | is there a simpler, more efficient way? Follow the patterns this repo already uses, and challenge the code even when the better one isn't in the repo yet. Prefer the language's own constructs over hand-rolled ones |
| 3 | Readability + idiom | ask the code: is this human readable, simple, self-documenting? Does it use the common vocabulary of the language? Name magic values and indices, enum + switch over string matching, a small widget over a `Builder` |
| 4 | Comments | good names first. A comment restating the line below it is noise. Keep the *why* (the constraint, why the obvious thing is wrong), and leave ticket numbers out |
| 5 | Tests | tests that pull weight, not filler |
| 6 | Automated review | whatever the first five missed |
| **Opening** | | |
| 7 | Open as draft | signals not ready for humans yet |
| 8 | Fill the template | concise and easy for the reviewer to read. Keep only what they need to know, why over what |
| 9 | Request Copilot | one free pass before humans read it |

Steps 2–6 apply just as well to a PR that is already open.

## Notes from running it

What each step actually caught in practice, so the checklist reads as more than
a formality.

**Step 2 is where reuse gets caught.** A hand-rolled
`firedAtOffset == null && !cancelled` predicate turned out to duplicate a
`ScheduledEventStatus.pending` that already existed. Grep for the existing
vocabulary before writing a predicate — and prefer the enum to re-deriving it,
because the enum documents itself.

**Step 3 catches things no tool can see.** A new top-level function inserted
between a doc comment and the function it documented silently re-parented the
docs: the new function inherited a description of something else, and the
original was left undocumented. Analyzer clean, tests green. Only reading the
diff as a stranger finds it. The same defect then recurred in the test file, so
check every file the diff touches rather than the one you were thinking about.

**Step 4 is usually a deletion.** Two call-site comments ran ~24 lines for
6 lines of code and mostly restated the spec. The comment pass removed twice
what it added.

**Step 5 means checking for coverage that already exists**, not just "are there
tests". One new test duplicated an existing one 300 lines up in the same file.

**Step 6 belongs after 2–5, not before.** Run first, it reports findings you
were about to fix anyway. Run last, it earns its place: on one PR it caught a
test that *could not fail* — the mutation it was supposed to detect makes the
package fail to compile, so the suite never loads and the assertion never runs —
and a robustness fix that had no coverage at all.

**A green mutation check is not proof.** Confirm the mutation failed on the
*assertion*, not on a compile error, an unrelated early-return, or a suite that
never loaded. That misread happened twice on a single PR, both times reading
"the test caught it" when something else had.

## Using it with Claude

Two ways, and they serve different purposes.

**Per-PR, on demand:** the `/pr-check` command in `commands/pr-check.md` walks
steps 1–6 against the current diff and reports findings before anything is
pushed. Install it with:

```bash
mkdir -p ~/.claude/commands
cp commands/pr-check.md ~/.claude/commands/pr-check.md
```

**Always on:** put the checklist in your personal `~/.claude/CLAUDE.md` so
Claude applies it when preparing a PR without being asked. That file is yours —
it is deliberately **not** synced from this repo, so team guidance never
overwrites your own instructions.

Step 6 assumes a code-review command is available (`/code-review` in Claude
Code). If yours differs, substitute it.
