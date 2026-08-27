---
description: Walk steps 1-6 of the PR process against the current diff — scope, fit, readability, comments, tests, then an automated review — and report findings before anything is pushed. Works on an unopened branch or an already-open PR.
---

Run the pre-opening half of [`pr-process.md`](../pr-process.md) against the work
in hand and report what it finds. **Do not push, open, or edit a PR** as part of
this — the output is a list of findings for the developer to act on.

## Arguments

- **(no args)** — review the current branch's diff against its merge base.
- **`<PR number>`** — review that PR's diff. Steps 2–6 apply to an open PR just
  as well as to an unopened branch.
- **`--fix`** — apply the findings rather than only reporting them. Off by
  default: the developer decides what is worth changing.

## Before you start

Establish the diff and say what it is, so the developer can tell you reviewed
the right thing:

```bash
git merge-base HEAD origin/main          # or the PR's base
git diff --stat <base>...HEAD
```

If the diff is empty or the base looks wrong, stop and ask rather than reviewing
nothing.

## Step 1 — AC and plan

Read the ticket or plan the work claims to implement. Report anything in the
diff that it does not ask for, and anything it asks for that the diff does not
do. Scope creep and silent under-delivery are the same finding from two sides.

If there is no ticket or plan to check against, say so and move on — do not
invent acceptance criteria.

## Step 2 — Fit

Is there a simpler or more efficient way?

- **Search for what already exists** before accepting a new helper, predicate,
  or constant. Grep the package for the concept, not just the name. A
  hand-rolled predicate that duplicates an existing enum value is the common
  case.
- Follow the patterns the repo already uses. If a better pattern is not in the
  repo yet, say so rather than silently matching the weaker one.
- Prefer the language's own constructs over hand-rolled equivalents.

## Step 3 — Readability and idiom

Ask the code: is this human readable, simple, self-documenting?

- Magic values and bare indices get names.
- Enum + `switch` over string matching.
- A small named widget or function over an inline `Builder` or closure.
- **Check every file the diff touches**, not only the one the change is
  "about" — a defect fixed in the library often recurs in its test.
- Watch for doc comments that ended up attached to the wrong declaration. An
  insertion between a doc block and its subject silently re-parents it, and no
  analyzer reports it.

## Step 4 — Comments

Good names first; a comment is the fallback.

- A comment restating the line below it is noise. Delete it.
- Keep the *why*: the constraint, the measurement, why the obvious thing is
  wrong. That is the part a reader cannot reconstruct.
- Leave ticket numbers out of code comments.
- Expect this step to be a net deletion. If it is not, look again.

## Step 5 — Tests

Tests that pull weight, not filler.

- **Does this coverage already exist?** Check the rest of the file and its
  siblings before accepting a new test.
- Does each test fail for the reason it claims? Mutate the line it guards and
  confirm it fails — then confirm it failed on the **assertion**, not on a
  compile error, an unrelated early-return, or a suite that never loaded. A
  green mutation check that was really a compile failure proves nothing.
- Does any assertion's stated `reason` describe a mechanism other than the one
  actually protecting it? Fix the reason or the test.

## Step 6 — Automated review

Run the repo's code-review command (`/code-review`, plus the PR number if
reviewing one) **after** steps 2–5, so it does not report findings already
fixed.

Then **verify each finding against the source before acting on it.** Automated
findings are sometimes wrong, and a reasoned rebuttal is more useful than
compliance. Report which findings you confirmed, which you rejected and why,
and which you fixed.

## Reporting

Group by step, most severe first, and for each finding give the file and line,
what is wrong, and what you would do about it. Distinguish:

- **defects** — wrong behavior or a false claim in a comment or test
- **fit / readability** — works, but simpler or more idiomatic is available
- **noted, not fixed** — real but belonging to another change; say where

End with what you verified and what you did not. If a step did not apply, say
which and why rather than omitting it.
