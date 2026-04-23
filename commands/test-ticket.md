---
description: Set up an integration-testing session for a Jira ticket — resolve the right branch in a worktree, recommend the paired branch on the other app, build and launch both (Android devices/emulators and iOS simulators) from the correct source, and surface testing steps. Guarantees the code running on the device matches the branch under test.
---

Set up an integration-testing session for a ticket on the NBT / RMP pair. The developer's biggest bottleneck is accidentally testing from the wrong worktree or branch. This skill's job is to **eliminate that ambiguity** — the code running on the device is always built from a specific worktree+branch that the skill owns, printed prominently in the output so the developer can verify.

## Repo vocabulary

- **RMP** = `$RMP_PATH` — Flutter participant app (Android + iOS). Base branch: `develop`.
- **NBT / ios-assessments** = `$NBT_PATH` — native iOS examiner app. Base branch: `developmentForBanffV3Remote`. Xcode project: `mss-admin/admin-shell.xcodeproj`. Likely scheme: `nih-baby-toolbox-debug` (ask if a different variant is needed).
- **Worktrees dir**: `$WORKTREE_PATH` — standard location for per-ticket checkouts.

## Arguments

- `<ticket-id>` (e.g. `NIHTB-5483`) — full workflow
- `stop` — tear down any builds started in this session (no ticket needed)

## Phase 1 — Resolve what to test

1. Take the ticket ID from args. Run `jira issue view TICKET-ID --plain` to get title, labels, links, description.
2. Classify primary repo:
   - If labels or title mention RMP / Flutter / participant / mobile — it's RMP
   - If title or description references examiner, ios-assessments, or NBT — it's ios-assessments
   - If still unclear, ask the developer
3. Find the primary branch:
   - `gh pr list --state open --author=@me --search TICKET-ID --json headRefName,number` (in the correct repo dir)
   - If there's a matching open PR, use its `headRefName`
   - If no open PR, check if a local branch matches `claude/TICKET-ID/*`
   - If nothing, fall back to the base branch (`develop` or `developmentForBanffV3Remote`) and **warn the developer that the ticket has no in-flight branch yet**

## Phase 2 — Recommend the paired branch on the other app

Default to the other app's base branch (`develop` for RMP, `developmentForBanffV3Remote` for ios-assessments).

**Smart override:** scan the ticket's Jira links (relates-to / blocks / is-blocked-by) and any related tickets mentioned in the PR description. If a related ticket has an open PR on the other app and the behaviors interact, recommend that branch instead, briefly explaining why. Example: "NIHTB-5483 depends on NIHTB-5427's rejoin race fix; recommend pairing with `claude/NIHTB-5427/fixAndroidRejoin`."

When unsure, ask. Do not silently pick a non-default pairing.

Present the recommendation with a short rationale and allow the developer to override.

## Phase 3 — Device selection

For each app the developer wants to run, list available devices and ask them to pick.

**Critical constraint: when both apps run on iOS simulators, they must be on SEPARATE sims.** The two apps communicate in real time via Zoom, and only one sim can be "active" at a time — putting both on the same sim breaks the test. Additionally, RMP is phone-intended (iPhone sim) while NBT is iPad-only — so the natural pairing is an iPhone sim for RMP + an iPad sim for NBT. Don't offer "same sim for both" as a convenience.

- **RMP (Flutter):** `cd <rmp-worktree> && fvm flutter devices --machine` returns JSON with `id`, `name`, `targetPlatform`. Group into: physical Android, Android emulator, iOS simulator, iOS physical, macOS/web (filter out).
- **ios-assessments (native iOS):** `xcrun simctl list devices --json` for simulators (filter to `isAvailable == true` AND `'iPad' in name` — **the NBT examiner app is iPad-only**, iPhone simulators aren't useful). `xcrun xctrace list devices 2>&1 | grep -v Simulator` for physical iOS devices (filter to iPad models). When listing simulators, group by model family (Air / Pro / mini / base iPad) and show latest iOS per model first; highlight any already-booted sim since reusing it saves time.

Present as a numbered pick-list, marked by category. If a physical iOS device is picked for ios-assessments, **do not attempt to build** — print:

> Running on a physical iOS device requires code signing. Open `~/Developer/heliumfoot/ios-assessments/mss-admin/admin-shell.xcodeproj` in Xcode, check out `<branch>`, select scheme `<scheme>`, and Cmd-R. Let me know when it's running.

## Phase 4 — Worktree setup (the load-bearing guarantee)

For each app being built:

1. Determine the target branch from Phase 1 (primary app) or Phase 2 (paired app).
2. Check if a worktree already has that branch checked out: `git worktree list` in the repo.
3. If yes, use that worktree path.
4. If no, create one at `~/Developer/heliumfoot/worktrees/<ticket>-<repo>` (or `<branch-basename>-<repo>` if no ticket for the paired side). Use `git worktree add <path> <branch>` — fetch first if the branch is remote-only.
5. Print the worktree path and branch prominently:

```
── RMP ──────────────────────────
   Worktree: ~/Developer/heliumfoot/worktrees/NIHTB-5483-rmp
   Branch:   claude/NIHTB-5483/leaveSessionOnMeetingBackground
   Device:   Pixel 7 Pro (emulator)
── ios-assessments ──────────────
   Worktree: ~/Developer/heliumfoot/ios-assessments
   Branch:   developmentForBanffV3Remote
   Sim:      iPhone 15 (iOS 18.0)
   Scheme:   nih-baby-toolbox-debug
```

**Never** build from the main checkout if that would mean building the wrong branch — the developer's number-one pain point is exactly that.

### Pull latest on paired branches before building

Before kicking off either build, run `git fetch && git pull --ff-only` on the branch that's going to be built — the NBT main checkout for ios-assessments, and the worktree for RMP. Two reasons:
- Teammates frequently merge PRs that affect shared infrastructure (screen sharing, lifecycle helpers, PEAP commands). Testing against a stale checkout wastes cycles debugging bugs that were already fixed upstream.
- The default branch (`developmentForBanffV3Remote` for NBT, `develop` for RMP) moves multiple times per day during active sprints.

If the tree has uncommitted tracked changes, stop and ask the developer — don't silently stash. Untracked files are fine to leave alone. If the pull results in new commits, rebuild even if a prior binary is already installed on the device.

## Phase 5 — Build and launch

### RMP (Android device or emulator)

From the worktree dir, run in the background:

```bash
cd <rmp-worktree>
CI=true fvm flutter run -d <device-id>
```

`CI=true` is required so the `MobileToolboxFlutterPlugin` pulls `latest.integration` (see project notes). Use `run_in_background: true` and capture output.

Watch for success signals in the output:
- `"Flutter run key commands."` line, OR
- `"Debug service listening on ws://"` line, OR
- `"Connecting to VM Service at"` after the app is installed

Watch for failure signals:
- `"Build failed"` / `"FAILURE: Build failed"`
- `"Error:"` lines from Gradle
- Non-zero exit before "running" state

### RMP (iOS simulator)

From the worktree dir:

```bash
cd <rmp-worktree>
CI=true fvm flutter run -d <simulator-udid>
```

Same success/failure heuristics.

### ios-assessments (iOS simulator)

1. Boot the simulator if needed: `xcrun simctl boot <udid>` (idempotent — errors if already booted, suppress with `2>/dev/null || true`).
2. Open Simulator.app if not visible: `open -a Simulator`.
3. Build:
   ```bash
   cd ~/Developer/heliumfoot/ios-assessments/mss-admin
   xcodebuild -project admin-shell.xcodeproj \
              -scheme <scheme> \
              -destination "platform=iOS Simulator,id=<udid>" \
              -configuration Debug \
              build
   ```
   Run in the background. Success: `"BUILD SUCCEEDED"`. Failure: `"BUILD FAILED"` or exit != 0.
4. Find the built `.app`:
   ```bash
   xcodebuild -project admin-shell.xcodeproj -scheme <scheme> -showBuildSettings -configuration Debug 2>/dev/null | grep -m1 " BUILT_PRODUCTS_DIR" | awk -F'= ' '{print $2}'
   ```
   The app bundle is `<BUILT_PRODUCTS_DIR>/<scheme>.app` (scheme name may differ from product name — if the expected path doesn't exist, fall back to `ls <BUILT_PRODUCTS_DIR>/*.app | head -1`).
5. Install:
   ```bash
   xcrun simctl install <udid> <app-path>
   ```
6. Read the app's bundle ID from `<app-path>/Info.plist` via `defaults read <app-path>/Info CFBundleIdentifier`.
7. Launch:
   ```bash
   xcrun simctl launch <udid> <bundle-id>
   ```

### ios-assessments workspace/scheme conflict

If `~/Developer/heliumfoot/ios-assessments` (the main checkout) is on a different branch than the one you want built, you have a problem: there's no worktree pattern for Xcode projects that reliably plays well with CocoaPods / derived data. Ask the developer:

> ios-assessments main checkout is on `<current-branch>`, but this test wants `<target-branch>`. Xcode doesn't love being pointed at a worktree. Two options: (a) I can switch the main checkout to `<target-branch>` (your current uncommitted work stays in the stash) or (b) you keep your setup and I skip the ios-assessments auto-build — please run from Xcode manually.

Default to (b) if there are uncommitted changes; (a) is fine when the tree is clean.

## Phase 6 — Monitor, report, surface test plan

While the builds run in background, do NOT poll — use the Monitor tool or similar to stream output. When both succeed, notify:

```
✅ RMP running on <device-name> from branch <branch> (worktree: <path>)
✅ NBT running on <sim-name> from branch <branch> (worktree: <path>)

Now testing: NIHTB-5483 — Drop session when participant backgrounds during meeting

Test steps (from ticket AC + PR description):
  1. Join a session on both apps.
  2. Background the RMP app (home button, app switcher).
  3. Expected: examiner sees "Waiting for Participant" / "Participant Left Meeting".
  4. Foreground RMP via app switcher.
  5. Expected: RMP lands on Join-Meeting screen; participant must rejoin.
  6. Start an assessment; background RMP.
  7. Expected: participant is paused, NOT dropped from session.
```

If a build fails: print the failure's first error line and the path to full log. Don't kill the other side's build; let the developer know one succeeded and one failed so they can pick.

## Phase 7 — `stop` mode

When invoked as `/test-ticket stop`:

1. List background build processes started by the skill (tracked via PID or command name).
2. Kill them cleanly: `kill <pid>` or `pkill -f "flutter run"` for Flutter, `xcrun simctl terminate booted <bundle-id>` for iOS simulator apps.
3. Report which processes were stopped.

## Edge cases and safety

- **Developer cancels mid-setup**: don't leave half-booted simulators or orphaned `fvm flutter run` processes.
- **Branch doesn't exist locally**: fetch first (`git fetch origin`), then `git worktree add`. If fetch fails (network), report and stop.
- **Worktree already exists on a different branch**: use it anyway if the branch matches; otherwise error with the current state so the developer can resolve.
- **Ambiguous scheme**: if multiple likely schemes exist (debug / qa / release variants), ask the developer. Remember their choice for this session.
- **Flutter plugin-version quirks**: the `CI=true` env var is required for RMP builds (pulls `latest.integration` for MTB native deps). If you forget, builds will silently use a stale pinned version. Always set it.
- **RMP Android build failing with `MobileToolboxFlutterPlugin` Kotlin unresolved references** (e.g. `launch`, `LaunchParameterLookup`, `MtbProgressListener`, `getLaunchParametersJson`): the plugin's `CI=true` path uses `mavenLocal()` + `latest.integration`, which requires a fresh `remote_baby_assessments_provider` artifact in `~/.m2`. If whoever owns the native SDK hasn't published a recent-enough version locally, the plugin's Kotlin will fail to compile against stale symbols. **Do not burn time debugging this at the skill level.** Surface the failure and recommend (in order): (a) run `/publish-android-deps` to refresh mavenLocal from MobileToolboxAndroid's default branch — this is the fastest path; (b) if that still fails, iOS sim fallback; (c) as a last resort, ask in team chat which native version pairs with the plugin's current commit.
- **Disk full** during a build: iOS builds can easily eat 20+GB of DerivedData. Always `df -h /` before starting a build and warn if <10GB free. If a build fails with "no space left on device", prompt the developer to clear DerivedData (Finder or `rm -rf ~/Library/Developer/Xcode/DerivedData/*`) and old iOS simulator runtimes before retrying.
- **RMP iOS build failing with `Pods-Runner-frameworks.sh: line 42: source: unbound variable`**: the worktree's CocoaPods integration is stale (often after a `pubspec.lock` change or a develop merge). Run `cd <worktree>/ios && arch -arm64 pod install` — the `arch -arm64` prefix is required on Apple Silicon when a plain `pod install` fails with `LoadError - cannot load such file -- ffi_c` (native gem arch mismatch). Retry the flutter build after pod install completes.
- **RMP `flutter analyze` / `flutter test` failing with `AppLocalizations` / `AppLocalizationsEn` undefined or `uri_does_not_exist` for `app_localizations.dart`** after merging `develop` into a branch: the generated l10n Dart files (`lib/l10n/app_localizations*.dart`) are not checked in — only the `.arb` sources are. Merging develop often pulls in new l10n keys referenced by freshly-added screens, and the local generated bundle from the branch becomes stale or missing. Run `fvm flutter gen-l10n` to regenerate. This also applies the first time a developer checks out a fresh worktree if pub-get hasn't triggered the codegen.

## Output style

Terse. Use the block format shown in Phase 4 for the "here's what will run" summary. Use checkmarks / X marks for status. Don't narrate internal steps ("I will now run xcodebuild…") — just do them and report the result.

## What this skill does NOT do

- Build for physical iOS devices (falls back to "please use Xcode")
- Automate actual testing actions in the app (taps, navigation) — that's a future concern
- Run the `flutter test` unit suite (different scope; use the test plan the developer already runs manually)
- Manage Jira status transitions (use `/workday` for that)

## Closing

When the developer says they're done testing, suggest they run `/test-ticket stop` to tear down. Or, if the session's been going a while and the developer moved on, offer to clean up proactively after ~30 min of inactivity.
