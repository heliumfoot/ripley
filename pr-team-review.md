# PR Review Load

Show how evenly pull request review work is distributed across a team, weighted by reviewable lines changed.

## Prerequisites

The `gh` CLI must be authenticated (`gh auth status`).

```
Before doing anything else, run this single preflight Bash command to warm up permissions:

```
gh auth status && echo "gh ok" && python3 --version && echo "python3 ok"
```

This ensures `gh` and `python3` are authenticated and available, and surfaces any permission prompts upfront before the analysis begins.

Then ask me two questions:

1. "Which repos should I analyze? Provide a GitHub team in `org/team-name` format, a list of `owner/repo` names, or a mix of both."
2. "What time period? (e.g. 'last 30 days', 'last sprint', 'since 2025-01-01')"

Wait for both answers before continuing.

---

**Resolving repos and team members:**

If a GitHub team was provided (e.g. `myorg/my-team`):
- Resolve the member list: `gh api /orgs/myorg/teams/my-team/members --jq '[.[].login]'`
- Resolve the repo list: `gh api /orgs/myorg/teams/my-team/repos --jq '[.[].full_name]'`

If individual repos were also provided (beyond the team's repos), add them to the repo list. After fetching all PRs and reviews from those extra repos, expand the team member list by unioning in any author or reviewer logins found there. These added members appear in the final table and can receive ⚠️ if they did no reviews.

If only individual repos were provided (no team), the member list is built entirely from the PR authors and reviewers found across all those repos.

Convert the time window into an ISO 8601 date range. For relative windows like "last 30 days", compute the start date from today's date.

---

For each repo in the list:

1. Fetch merged PRs in the window:
   ```
   gh pr list --repo owner/repo --state merged --json number,author \
     --search "merged:>=START_DATE merged:<=END_DATE"
   ```

2. For each PR:
   a. Get per-file data:
      ```
      gh api /repos/owner/repo/pulls/NUMBER/files \
        --jq '[.[] | {filename, additions, deletions, patch}]'
      ```
      (PR author comes from step 1.)
   b. Get the reviews:
      ```
      gh api /repos/owner/repo/pulls/NUMBER/reviews \
        --jq '[.[] | {login: .user.login, state}]'
      ```

3. For each file in the PR, apply the exclusion rules below. Compute the PR's **reviewable lines** as the sum of `additions + deletions` across all non-excluded files. If all files are excluded, the PR's reviewable lines = 0.

**Exclusion rules — exclude a file if any of the following are true:**

- **Binary:** the file has no `patch` field in the API response
- **Whitespace-only:** the file has a `patch`, but every added line (`+` prefix, excluding `+++` header) and every removed line (`-` prefix, excluding `---` header) contains only whitespace characters when stripped
- **Generated / non-reviewable filename patterns:**
  - Exact names: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Gemfile.lock`, `Cargo.lock`, `poetry.lock`, `go.sum`, `composer.lock`, `Podfile.lock`
  - Path prefixes: `dist/`, `build/`, `vendor/`, `.next/`, `out/`, `Pods/`
  - Directory suffix: `*.xcassets/` (any path containing a `.xcassets` directory component)
  - File suffixes/patterns: `*.min.js`, `*.min.css`, `*_generated.go`, `*_gen.go`, `*.pb.go`, `*.snap`

4. For each review, skip it if the reviewer login matches the PR author login (self-review).

5. For each remaining review, record one contribution per reviewer per PR (not per review event). The contribution value is the PR's **reviewable lines**.

---

Aggregate across all repos:

For each reviewer:
- **Reviews**: number of distinct PRs reviewed (self-reviews excluded)
- **Weighted score**: sum of reviewable lines for each PR reviewed (one entry per reviewer per PR)

Compute the total weighted score as the sum across all reviewers. Compute each reviewer's share as their weighted score ÷ total weighted score.

If a team was resolved, include all team members in the table even if their review count is 0.

Sort the table descending by weighted score. Flag anyone with 0 reviews with ⚠️.

---

Print the results in this format:

```
PR Review Load — START_DATE to END_DATE
Repos: owner/repo1, owner/repo2 (N PRs, M weighted line-reviews)

Reviewer      Reviews   Weighted Score   Share
──────────────────────────────────────────────
alice              18            4,130    49%
bob               12            2,700    32%
carol               7            1,590    19%
dave                0                0    0%  ⚠️
```

"Weighted Score" = sum of reviewable lines changed (additions + deletions, excluding binary, whitespace-only, and generated files) across each PR this person reviewed.
"Share" = that person's weighted score ÷ total weighted score across all reviewers.

Percentages should sum to 100% (rounding to nearest integer is fine).
```
