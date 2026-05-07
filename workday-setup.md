# Workday Setup

Read this file when one of the workday prechecks fails (jira CLI not installed, or `JIRA_CONFIG_FILE` not set). Walk the developer through only the steps needed to fix what failed; skip anything already in place. After each developer action, wait for explicit confirmation before continuing.

## Jira CLI Setup

Before any of the steps below, ask the developer for their Atlassian email. Substitute it into every command that references the developer's email — do not leave placeholder text in commands you ask them to run.

### Step 1 — Install jira CLI

Run `which jira`. If it's already on the path, skip this step.

If missing, offer to install it:

```bash
brew tap ankitpokhrel/jira-cli
brew install jira-cli
```

Wait for the developer to confirm installation before proceeding.

### Step 2 — Get an API token

Direct the developer to https://id.atlassian.com/manage-profile/security/api-tokens to create a new token. Tell them to come back once they have it. Wait for confirmation.

### Step 3 — Store the token in macOS Keychain

Tell the developer to run this in a **separate terminal window** (not the one running Claude, to avoid sharing credentials), substituting their email and the token they just generated:

```bash
security add-generic-password -s jira-cli -a <developer-email> -w <token>
```

The service name `jira-cli` and account (email) are what jira-cli looks for natively. Wait for the developer to confirm this is done.

### Step 4 — Run `jira init`

Tell the developer to run:

```bash
jira init
```

Walk them through the prompts: Cloud vs. On-Premise, Jira base URL, project key. This generates `~/.config/.jira/.config.yml`. Wait for confirmation.

### Step 5 — Install direnv and set up `.envrc`

direnv ensures the correct Jira config is loaded whenever the developer enters the project directory.

Run `which direnv`. If it's already on the path, skip the install command below.

If missing:

```bash
brew install direnv
```

Then add the shell hook to the developer's shell rc file (if not already present). Detect or ask which shell they use:

- For zsh, add to `~/.zshrc`: `eval "$(direnv hook zsh)"`
- For bash, add to `~/.bashrc`: `eval "$(direnv hook bash)"`

Then create `.envrc` in the project root:

```bash
export JIRA_CONFIG_FILE=/path/to/project/.jira.yml
```

Then have them run `direnv allow` in the project directory. Wait for confirmation.

Once all incomplete steps are confirmed complete, proceed with the workday flow.

---

## Jira CLI Command Reference

Use these patterns when constructing jira CLI commands. Credentials and config are pre-configured in the environment — no extra auth steps needed.

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
