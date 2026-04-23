End-of-day wrap-up: reclaim disk, tidy working state, and summarize what happened today vs. what's teed up for tomorrow.

Designed so the developer can invoke it at the end of a work session and walk away knowing: (a) nothing with uncommitted or unpushed work was lost, (b) storage is reclaimed, (c) tomorrow-morning context is written down.

## Arguments

- `preview` — dry-run. Show what *would* happen in each phase without executing anything destructive. The summary (Phase 6) always runs normally.
- `--with-trash` — include the "empty Trash" step. Default is to skip, since empty-trash is unrecoverable.
- (no args) — full run. Interactive prompts on destructive phases.

## Phase 1 — Running processes (silent cleanup)

Kill orphaned background processes from the day's work. Log what was killed with rough memory reclaimed.

1. **Gradle daemons**: `pkill -f GradleDaemon` — reclaims ~1-2GB each
2. **Orphaned build processes**: `pkill -f "flutter run"`, `pkill -f "fvm flutter"`, `pkill -f xcodebuild`
3. **Monitor/Bash background tasks from the session**: discover via shell jobs list or by checking `/private/tmp/claude-*/tasks/` for running outputs; prefer graceful termination
4. **Do NOT kill**: the current Claude Code process, user's editor processes (VS Code, Xcode, Android Studio), Simulator.app itself

Report:
```
Killed 3 Gradle daemons (~2.4 GB reclaimed)
Killed 1 orphaned flutter run
Killed 1 orphaned xcodebuild
```

No confirmation needed — these processes are safely restartable and are leaks.

## Phase 2 — DerivedData (per-project, confirm before each)

Scan `~/Library/Developer/Xcode/DerivedData/` and classify each folder:

1. Read `<derived-data-folder>/info.plist` (or `WorkspacePath-<hash>/info.plist`) to get the source `WorkspacePath`.
2. **NU-MSS-only filter**: only consider folders whose source path is under `~/Developer/heliumfoot/`. Skip everything else silently — the developer has personal projects that shouldn't be touched.
3. For each matching folder:
   - **Orphaned** — source path no longer exists (e.g. deleted worktree): mark as auto-safe.
   - **Active** — source path exists: ask before clearing, showing size.

Present:
```
DerivedData — NU-MSS only:

  ORPHANED (source path deleted, safe to remove):
    NIHTB-5482-rmp-abc123      3.8 GB   (path deleted)
    NIHTB-5483-rmp-def456      3.6 GB   (path deleted)
  Remove both orphaned folders? [Y/n]

  ACTIVE:
    RemoteMobileParticipant-ghi789     4.1 GB   (current main checkout)
    ios-assessments-jkl012              8.2 GB   (current main checkout)
    NIHTB-5489-logging-mno345           2.9 GB   (active worktree)

  Clear ios-assessments DerivedData (8.2 GB)? [y/N]
  Clear RemoteMobileParticipant DerivedData (4.1 GB)? [y/N]
  Clear NIHTB-5489-logging DerivedData (2.9 GB)? [y/N]
```

Note: clearing active DerivedData forces a clean build next time. Default to **N** — only clear if the developer is sure they won't be building that project first thing tomorrow.

## Phase 3 — Build artifacts + temp files (mostly silent)

Targets:
1. `/tmp/*build*.log`, `/tmp/*publish*.log`, `/tmp/mtb-android-publish.log`, `/tmp/rmp-*.log`, `/tmp/nbt-*.log` older than today → delete.
2. MobileToolboxAndroid heap dumps: `~/Developer/heliumfoot/MobileToolboxAndroid/*.hprof` — delete these silently.
3. **Do NOT** touch `pub-cache`, `CocoaPods` cache, `~/.gradle/caches/`, or `mavenLocal()` — those are expensive to rebuild. Only the orphaned DerivedData route addresses Xcode cache reclamation.
4. **Do NOT** recurse into live worktrees to delete `build/` or `Pods/` — those belong to the worktree lifecycle, addressed in Phase 4.

Report size reclaimed. No confirmation needed.

## Phase 4 — Worktrees (confirm per-item)

List all worktrees (excluding the main checkout). For each, gather:
- Branch name
- Dirty tree? (`git status --porcelain`)
- Unpushed commits? (`git rev-list --count @{u}..HEAD`)
- PR state: `gh pr list --search "head:<branch>" --state all --json number,state,mergedAt,reviews,title`

Classify:

| Signal | Classification | Default action |
|---|---|---|
| Dirty tree OR unpushed commits | **SKIP** | Never touch; surface warning so dev can resolve |
| PR merged, clean tree, pushed | **AUTO-SAFE** | Propose delete (single Y/n for all) |
| PR open awaiting review, clean, pushed | **ASK** | Per-worktree confirm |
| PR open, active comments / changes requested | **SKIP** (show) | Leave alone |
| No PR, clean, pushed | **ASK** | Per-worktree confirm |

Present:
```
Worktrees:

  AUTO-SAFE (PR merged, clean):
    NIHTB-5427-rmp    claude/NIHTB-5427/fixAndroidRejoin    PR #50 merged
  Remove? [Y/n]

  ASK (PR open, clean):
    NIHTB-5482-rmp    claude/NIHTB-5482/pauseOnBackground   PR #59 open, awaiting review
  Remove NIHTB-5482-rmp? [y/N]

  SKIP (dirty tree or unpushed — NOT touching):
    NIHTB-5489-logging    claude/NIHTB-5489/addReconnectLogging    2 unpushed commits
```

When removing a worktree, chain the matching DerivedData folder from Phase 2 into the deletion if the user agreed to remove it — otherwise the folder becomes orphaned the moment the worktree goes.

## Phase 5 — Trash (only with `--with-trash`)

**Skipped by default**; only runs when `--with-trash` is passed.

If enabled:
1. Compute size of `~/.Trash/`
2. Show item count + total size
3. Confirm before emptying. Emptying is unrecoverable — be explicit:
   ```
   Empty Trash: 1.2 GB, 387 items?
   This is unrecoverable. [y/N]
   ```
4. On confirm: `rm -rf ~/.Trash/*` (careful with the path — absolute, never relative)

## Phase 6 — Summary (always runs)

Write a concise end-of-day summary. Pulls from:

1. **Commits today** across each NU-MSS repo the developer worked in (`~/Developer/heliumfoot/*` — scan each for `git log --author=@me --since=midnight --oneline`). Include the repo name in each line.
2. **PRs opened / updated / merged** today:
   ```bash
   gh search prs --author=@me --owner=NU-MSS --updated=">=$(date +%Y-%m-%d)" --json number,title,state,repository,mergedAt,url
   ```
3. **Jira activity** on in-progress cards: `jira issue list -a"@me" -s"In Progress" --plain` and any tickets moved through states today.
4. **Skill file changes**: list of `~/.claude/commands/*.md` created or modified today (`stat -f "%Sm %N" -t "%Y-%m-%d" ~/.claude/commands/*.md | grep "$(date +%Y-%m-%d)"`). Surfaces workflow improvements the dev shipped for their own tooling.
5. **Upcoming**:
   - Open PRs awaiting review (same-repo or cross-repo).
   - In-progress Jira cards not touched today.
   - Known blockers (from `~/.claude/projects/-Users-reschneebaum-Developer-heliumfoot-RemoteMobileParticipant/memory/MEMORY.md` — scan for entries tagged `project` type that look active).

Format (terse, no emoji):

```
── End of day — 2026-04-23 ──

Today:
  RemoteMobileParticipant
    NIHTB-5482  +4 commits  pushed to PR #59 (awaiting review)
    NIHTB-5483  +1 commit   pushed to PR #55 (CI green)
  MobileToolboxAndroid
    MobileParticipant  published 19 modules to mavenLocal (1.11.54-dev)
  ~/.claude/commands/
    publish-android-deps.md  new
    test-ticket.md           edited (4 changes)
    end-of-day.md            new

Tomorrow:
  PRs awaiting review:
    #59 NIHTB-5482 — Pause instrument when participant backgrounds
    #55 NIHTB-5483 — Drop session when participant backgrounds
  In-progress cards:
    NIHTB-5457  Ensure participant screen sharing state is correctly updated
    NIHTB-5179  Mobile Participant App: Interruption Handling (umbrella)
  Known blockers:
    NIHTB-5492  flutterzoom plugin teardown SIGSEGV (waiting on plugin replacement)
    Tool-completion bug prevents resume testing (see NIHTB-5443 / 5441)

Disk reclaimed this session:
  Processes     2.4 GB
  DerivedData   7.4 GB  (orphaned + ios-assessments)
  Temp files    47 MB
  Trash         skipped
  Total        ~9.9 GB
```

## Phase 7 — Sims (opt-in, silent)

After the summary, ask once whether to shut down booted simulators. Default **N** — keeping them booted speeds up tomorrow's first `/test-ticket` run. Only confirm if storage is the bottleneck.

```
xcrun simctl list devices booted
```

If yes: `xcrun simctl shutdown all`.

## Preview mode

When invoked as `/end-of-day preview`:
- Phases 1-5 print their plan but do **not** execute any destructive operation.
- Phase 6 (summary) runs normally.
- Phase 7 does not prompt.

## Safety rails

- **Never** delete a worktree with dirty or unpushed state. Ever. Surface it so the dev can resolve.
- **Never** clear `pub-cache`, `CocoaPods cache`, `~/.gradle/caches/`, or `~/.m2/` — those represent real minutes of rebuild time, and `/publish-android-deps` is the right tool for targeted mavenLocal housekeeping.
- **Never** clear DerivedData outside of NU-MSS projects (filter strict on `~/Developer/heliumfoot/` source paths).
- **Never** empty Trash without the `--with-trash` flag AND explicit confirmation.
- If a phase fails partway through (e.g. permission denied on a delete), stop that phase and report — don't try to recover silently.

## What this skill does NOT do

- Merge, rebase, or push any code (even "sync with develop" on a dirty tree — that's the developer's judgment call).
- Update Jira ticket status (that's `/workday`'s job at start of day).
- Clear `~/Library/Caches/` or other global macOS caches that could affect other apps.
- Run `brew cleanup` or other package-manager maintenance — out of scope.
