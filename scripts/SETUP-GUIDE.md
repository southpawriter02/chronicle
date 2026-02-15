# GitHub Project V2 Setup Guide

**Script:** `setup-github-project.sh`
**Version:** 1.0.0
**Date:** 2026-02-15
**Project:** Chronicle + FractalRecall + Haiku Protocol Initiative

---

## What This Script Does

This script automates the creation and configuration of a GitHub Projects V2 board called **"Chronicle Initiative Board"** that serves as the unified tracking system for all three projects in the initiative:

- **Chronicle** (Track A) — .NET CLI for worldbuilding repository management
- **FractalRecall** (Track B) — .NET class library for hierarchical context-aware embedding retrieval
- **Haiku Protocol** (Track C) — Python semantic compression system using Controlled Natural Language

The script was adapted from the original "Rune & Rust Master Board" setup (see `aethelgard/00-project/github-project-setup.md`) with the following key changes:

| Aspect | Original (Rune & Rust) | New (Chronicle Initiative) |
|--------|------------------------|---------------------------|
| **Project Name** | Rune & Rust Master Board | Chronicle Initiative Board |
| **Repositories** | 1 (rune-rust) | 3 (chronicle, fractalrecall, haiku-protocol) |
| **Type Field** | Feature, Bug, Refactor, Docs, **Lore** | Feature, Bug, Refactor, Docs, **Research, Spec, Notebook** |
| **Grouping** | Feature Group (free text) | **Track** (Single Select: A/B/C/Cross-Cutting) |
| **Iteration** | Target Ver (2-week sprints) | **Milestone** (free text: Phase 0/1/2/3) |
| **New Fields** | — | **Document ID** (maps to D-10, D-21, R-01, etc.) |
| **Issue Templates** | Feature Request, Bug Report | Feature Request, Bug Report, **Spec Document, Research Task** |
| **Views** | Roadmap, Board, Spec Review, Backlog Triage | Roadmap, Board, Spec Review, Backlog Triage, **By Track** |

---

## Prerequisites

Before running the script, ensure you have the following installed and configured:

### 1. GitHub CLI (`gh`)

Install from [cli.github.com](https://cli.github.com/).

```bash
# Verify installation
gh --version
```

### 2. Authentication with Project Scope

The `gh` CLI must be authenticated with a token that includes the `project` scope. If you've previously authenticated but without this scope, refresh:

```bash
# Add the project scope to your existing authentication
gh auth refresh -s project

# Or authenticate from scratch
gh auth login -s project
```

### 3. jq (JSON Processor)

The script uses `jq` to parse JSON output from `gh` commands. Install from [jqlang.github.io/jq](https://jqlang.github.io/jq/).

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Windows (via Chocolatey)
choco install jq
```

### 4. Repositories Must Exist

The three repositories must already exist under `southpawriter02`:

- `southpawriter02/chronicle`
- `southpawriter02/fractalrecall`
- `southpawriter02/haiku-protocol`

The script does **not** create repositories — it only creates the project board and links to existing repos.

---

## Usage

```bash
# Make the script executable (one-time)
chmod +x scripts/setup-github-project.sh

# Run the script
./scripts/setup-github-project.sh
```

The script will walk through five phases:

1. **Phase 0:** Prerequisite checks (gh, jq, auth, repos)
2. **Phase 1:** Create the project board
3. **Phase 2:** Create all 7 custom fields
4. **Phase 3:** Link all 3 repositories
5. **Phase 4:** Generate issue templates (to temp directory)
6. **Phase 5:** Print the manual configuration checklist

---

## Idempotency

The script is designed to be safe to run multiple times:

- **Project creation:** Checks if a project with the same name already exists; reuses it if found.
- **Field creation:** Checks if each field already exists by name; skips if found.
- **Repository linking:** Catches errors from already-linked repos and treats them as warnings.
- **Issue templates:** Generated to `/tmp/gh-project-templates/` — must be manually copied to repos.

---

## What the Script CANNOT Do

Due to limitations in the GitHub CLI, the following must be configured manually in the GitHub web UI after running the script. The script prints a detailed checklist (Phase 5) with step-by-step instructions for each item.

### Field Option Colors

The `gh` CLI creates Single Select fields and their options, but cannot assign colors. You'll need to manually set colors for Status, Priority, Type, and Track options.

### Views

Views (Roadmap, Board, Table layouts) must be created manually. The script outputs the exact configuration for each view:

- **Roadmap** (Timeline) — grouped by Track, filtered to exclude Done
- **The Board** (Kanban) — grouped by Status, sorted by Priority
- **Spec Review** (Table) — filtered to Status == "Spec Review"
- **Backlog Triage** (Table) — filtered to Status == "Backlog"
- **By Track** (Table) — grouped by Track, filtered to exclude Done

### Automation Rules

Workflow automations must be configured manually:

- 3x Auto-Add rules (one per repository)
- Auto-Archive (Done items after 14 days)
- PR Merge → QA / Verify (optional)
- Item Closed → Done (optional)

---

## Issue Templates

The script generates four issue template files in `/tmp/gh-project-templates/`:

| Template | File | Purpose |
|----------|------|---------|
| Feature Request | `feature_request.md` | New functionality proposals |
| Bug Report | `bug_report.md` | Defect reports with reproduction steps |
| Spec Document | `spec_document.md` | Design specification tasks (NEW) |
| Research Task | `research_task.md` | Empirical investigation tasks (NEW) |

To install these in a repository:

```bash
# Example for the chronicle repo
mkdir -p /path/to/chronicle/.github/ISSUE_TEMPLATE
cp /tmp/gh-project-templates/*.md /path/to/chronicle/.github/ISSUE_TEMPLATE/
cd /path/to/chronicle
git add .github/
git commit -m "Add issue templates for Chronicle Initiative Board"
git push
```

Repeat for each of the three repositories.

---

## Custom Field Reference

### Status (Workflow Stages)

| Status | Entry Criteria | Exit Criteria |
|--------|---------------|---------------|
| **Backlog** | Item created | Triage selects for upcoming work |
| **Spec Review** | Selected from Backlog; complexity > S | Spec artifact committed to `docs/` |
| **Ready** | Spec approved; dependencies met | Developer starts work |
| **In Progress** | Developer starts work | PR opened |
| **QA / Verify** | PR merged; feature in build | Verification passed; changelog updated |
| **Done** | QA passed; all tasks checked | Auto-archived after 14 days |

### Type (Work Categories)

| Type | Definition |
|------|-----------|
| **Feature** | New functionality that adds capabilities |
| **Bug** | Defect — something is broken |
| **Refactor** | Internal improvements, no behavior change |
| **Docs** | READMEs, changelogs, general documentation |
| **Research** | Empirical investigation, benchmarking, literature review |
| **Spec** | Design specifications, architecture documents |
| **Notebook** | Colab/Jupyter notebook development |

### Track (Execution Tracks)

| Track | Scope |
|-------|-------|
| **Track A (Chronicle)** | Documentation sprint + .NET CLI work |
| **Track B (FractalRecall)** | Colab prototyping + embedding enrichment |
| **Track C (Haiku Protocol)** | Semantic compression + CNL grammar |
| **Cross-Cutting** | Multi-track work, strategy docs, integration specs |

---

## Customization

All configurable values are defined in **Section 1 (Configuration)** at the top of the script. You can modify:

- `OWNER` — GitHub username
- `PROJECT_TITLE` — Board name
- `REPOS` — Array of repository names
- `*_OPTIONS` — Field option values for each Single Select field

The script's inline comments explain the rationale for each configuration choice.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `gh: command not found` | Install GitHub CLI from [cli.github.com](https://cli.github.com/) |
| `could not determine auth status` | Run `gh auth login -s project` |
| `project scope not granted` | Run `gh auth refresh -s project` |
| `repository not found` | Ensure all three repos exist under `southpawriter02` |
| `duplicate field created` | Delete the duplicate in the web UI; the script should skip existing fields on re-run |
| `permission denied on link` | Ensure you have admin access to all three repos |

---

## Related Documents

- `Chronicle-FractalRecall-Master-Strategy.md` — The operational playbook
- `Haiku-Protocol-Integration-Assessment.docx` — Integration feasibility analysis
- `aethelgard/00-project/github-project-setup.md` — Original board configuration (Rune & Rust)
- `aethelgard/plans/github-project-setup-tasks.md` — Original 17-task implementation plan
