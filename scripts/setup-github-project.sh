#!/usr/bin/env bash
# ============================================================================
#  SCRIPT:  setup-github-project.sh
#  PURPOSE: Creates and configures a GitHub Projects V2 board for the
#           Chronicle + FractalRecall + Haiku Protocol initiative.
#
#  VERSION: 1.0.0
#  DATE:    2026-02-15
#  AUTHOR:  Ryan (with implementation from Claude)
#
#  REFERENCE DOCUMENTS:
#    - Chronicle-FractalRecall-Master-Strategy.md (operational playbook)
#    - Haiku-Protocol-Integration-Assessment.docx  (integration assessment)
#    - aethelgard/00-project/github-project-setup.md (original Rune & Rust spec)
#    - aethelgard/plans/github-project-setup-tasks.md (original task plan)
#
#  WHAT THIS SCRIPT DOES:
#    Phase 1: Creates the GitHub Project V2 board
#    Phase 2: Creates all custom fields (Status, Priority, Size, Type, etc.)
#    Phase 3: Links all three repositories to the project
#    Phase 4: Creates issue templates in each repository
#    Phase 5: Prints a manual steps checklist for things the CLI can't do
#             (Views, Automation/Workflows, Iteration configuration)
#
#  WHAT THIS SCRIPT CANNOT DO (CLI Limitations):
#    - Create or configure Views (Roadmap, Board, Table layouts)
#    - Configure Automation/Workflow rules (auto-add, auto-archive, PR sync)
#    - Set colors on Single Select options
#    - Configure Iteration date ranges
#    - Set default grouping/sorting/filtering on views
#    These must be done manually in the GitHub web UI after running this script.
#    Phase 5 of this script prints detailed instructions for each manual step.
#
#  PREREQUISITES:
#    1. GitHub CLI (gh) installed:  https://cli.github.com/
#    2. Authenticated with project scope:  gh auth login -s project
#    3. The three repositories must already exist:
#       - southpawriter02/chronicle
#       - southpawriter02/fractalrecall
#       - southpawriter02/haiku-protocol
#
#  USAGE:
#    chmod +x setup-github-project.sh
#    ./setup-github-project.sh
#
#  IDEMPOTENCY NOTES:
#    - The script checks for an existing project by name before creating.
#    - Field creation is NOT idempotent in the gh CLI — running twice will
#      create duplicate fields. The script checks for existing fields by name
#      and skips creation if they already exist.
#    - Issue template files use standard git operations; re-running will
#      overwrite existing templates (which is the desired behavior for updates).
#
#  EXIT CODES:
#    0  - Success
#    1  - Missing prerequisite (gh CLI not found, not authenticated, etc.)
#    2  - Project creation failed
#    3  - Field creation failed
#    4  - Repository linking failed
#    5  - Issue template creation failed
# ============================================================================

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

# ============================================================================
# SECTION 1: CONFIGURATION
# ============================================================================
# All configurable values are defined here at the top of the script so you
# can modify them without digging through the logic below. Think of this as
# the "settings file" for the entire project board setup.
# ============================================================================

# --- Project Identity ---
# The GitHub account that owns the project and all three repositories.
# For personal accounts, this is your GitHub username.
readonly OWNER="southpawriter02"

# The name of the Project V2 board as it will appear in the GitHub UI.
# This replaces the original "Rune & Rust Master Board" from the Aethelgard era.
readonly PROJECT_TITLE="Chronicle Initiative Board"

# A short description shown in the project's settings page.
readonly PROJECT_DESCRIPTION="Unified tracking board for the Chronicle + FractalRecall + Haiku Protocol proof-of-concept initiative. Manages documentation sprints, Colab prototyping, and integration milestones across all three repositories."

# --- Repository Names ---
# These are the three repositories that will be linked to the project board.
# Issues from any of these repos can be tracked on the unified board.
#
# chronicle       = The .NET CLI tool for worldbuilding repository management (Track A)
# fractalrecall   = The .NET class library for hierarchical context-aware embedding retrieval (Track B)
# haiku-protocol  = The Python semantic compression system using CNL (Track C / Integration)
readonly REPOS=(
    "chronicle"
    "fractalrecall"
    "haiku-protocol"
)

# --- Custom Field Definitions ---
# Each field is defined as a set of variables. The gh CLI uses these to create
# the project's custom fields. The field types supported by GitHub Projects V2 are:
#   TEXT           - Free-form text input
#   SINGLE_SELECT  - Dropdown with predefined options
#   NUMBER         - Numeric value
#   DATE           - Calendar date (YYYY-MM-DD)
#   ITERATION      - Sprint/iteration with date ranges
#
# IMPORTANT: The gh CLI does NOT support setting colors on Single Select options.
# Colors must be set manually in the GitHub web UI after running this script.
# Phase 5 of this script provides the color assignments for reference.

# --- Status Field ---
# The core workflow state field. Items move left-to-right through these statuses.
# This is identical to the original Rune & Rust board — the workflow model proved
# sound and doesn't need modification for the three-project architecture.
#
# Flow: Backlog → Spec Review → Ready → In Progress → QA / Verify → Done
#
# Entry/Exit criteria for each status:
#   Backlog     : Entry = Item created. Exit = Triage selects for upcoming work.
#   Spec Review : Entry = Selected from Backlog; complexity > S. Exit = Spec artifact committed.
#   Ready       : Entry = Spec approved; dependencies met. Exit = Developer starts work.
#   In Progress : Entry = Developer starts work. Exit = PR opened.
#   QA / Verify : Entry = PR merged. Exit = Verification passed; changelog updated.
#   Done        : Entry = QA passed. Exit = Auto-archived after 14 days.
readonly STATUS_OPTIONS="Backlog,Spec Review,Ready,In Progress,QA / Verify,Done"

# Suggested colors (must be set manually in the web UI):
#   Backlog     = Gray
#   Spec Review = Blue
#   Ready       = Green
#   In Progress = Yellow
#   QA / Verify = Purple
#   Done        = Dark Green

# --- Priority Field ---
# Triage sorting field. Determines the order in which work gets picked up.
# Unchanged from the Rune & Rust board — the P0-P3 scale is universal.
#
# Definitions:
#   P0 (Critical) : Blocks all progress or is a live defect. Drop everything.
#   P1 (High)     : Should be completed this milestone. Core functionality.
#   P2 (Normal)   : Standard work. Complete within 2-3 milestones.
#   P3 (Someday)  : Nice-to-have. No committed timeline.
readonly PRIORITY_OPTIONS="P0 (Critical),P1 (High),P2 (Normal),P3 (Someday)"

# Suggested colors:
#   P0 (Critical) = Red
#   P1 (High)     = Orange
#   P2 (Normal)   = Blue
#   P3 (Someday)  = Gray

# --- Size Field ---
# Estimation field for rough effort sizing. Used for velocity tracking and
# deciding whether something needs a Spec Review before implementation.
# Rule of thumb: anything > S probably needs a spec.
# Rule of thumb: anything XL should be decomposed into smaller issues.
#
# Definitions:
#   XS : < 1 hour.  Trivial change, single-line fix, config tweak.
#   S  : 1-2 hours. Single function/file. Minimal testing.
#   M  : 1 day.     Multiple files. Focused attention + testing.
#   L  : 2-3 days.  Multiple components. Design + thorough testing.
#   XL : ~1 week.   Major initiative. Consider decomposition.
readonly SIZE_OPTIONS="XS,S,M,L,XL"

# --- Type Field ---
# Categorization field. This is where the biggest change from the original
# Rune & Rust board happens. We've:
#   REMOVED: "Lore" (no worldbuilding content tracking — technical only)
#   ADDED:   "Research"  (for empirical validation work, Colab experiments)
#            "Spec"      (for specification/design documents — distinct from general Docs)
#            "Notebook"  (for Colab notebook development — Track B deliverables)
#
# Definitions:
#   Feature  : New functionality. User-facing value. (e.g., "Implement FractalRecall layer enrichment")
#   Bug      : Defect in existing functionality. Something is broken. (e.g., "Embedding cache returns stale vectors")
#   Refactor : Internal improvements, no behavior change. (e.g., "Extract embedding service interface")
#   Docs     : Technical documentation, READMEs, changelogs. (e.g., "Update Master Strategy roadmap status")
#   Research : Empirical investigation, benchmarking, literature review. (e.g., "Benchmark nomic-embed-text-v2-moe on lore corpus")
#   Spec     : Design specifications, architecture documents. (e.g., "Write D-14 LLM Integration Spec")
#   Notebook : Colab/Jupyter notebook development. (e.g., "Notebook 3: Multi-Layer Enrichment Prototype")
readonly TYPE_OPTIONS="Feature,Bug,Refactor,Docs,Research,Spec,Notebook"

# Suggested colors:
#   Feature  = Green
#   Bug      = Red
#   Refactor = Orange
#   Docs     = Blue
#   Research = Purple
#   Spec     = Teal/Cyan
#   Notebook = Pink

# --- Track Field ---
# NEW FIELD (replaces the original "Feature Group" text field).
# This is a Single Select instead of free-text to enforce consistency across
# the three-project architecture. Maps directly to the parallel execution tracks
# defined in the Master Strategy document.
#
# Definitions:
#   Track A (Chronicle)      : Chronicle documentation sprint + .NET CLI work.
#   Track B (FractalRecall)  : Colab prototyping + embedding enrichment research.
#   Track C (Haiku Protocol) : Semantic compression system + CNL grammar work.
#   Cross-Cutting            : Work that spans multiple tracks or is project-wide.
#                              Examples: Master Strategy updates, integration specs,
#                              shared CNL specification, session bootstraps.
readonly TRACK_OPTIONS="Track A (Chronicle),Track B (FractalRecall),Track C (Haiku Protocol),Cross-Cutting"

# Suggested colors:
#   Track A (Chronicle)      = Blue
#   Track B (FractalRecall)  = Green
#   Track C (Haiku Protocol) = Purple
#   Cross-Cutting            = Gray

# --- Milestone Field ---
# NEW FIELD (replaces the original "Target Ver" iteration field).
# The original board used 2-week sprint iterations, which makes sense for
# a single game dev project. For this initiative, we're milestone-based instead,
# because the three tracks have different cadences and deliverable types.
#
# We use a TEXT field here (not ITERATION) because:
#   1. Milestones don't have fixed 2-week date ranges
#   2. Different tracks may hit milestones at different times
#   3. The gh CLI has limited support for configuring ITERATION date ranges
#
# Expected values (free-text, but these are the conventions):
#   "Phase 0"   = Current phase. Documentation + Colab prototyping.
#   "Phase 1"   = .NET implementation begins. Chronicle CLI + FractalRecall library.
#   "Phase 2"   = Integration. FractalRecall embedded in Chronicle.
#   "Phase 3"   = Haiku Protocol integration. Full three-pillar system.
#   "Someday"   = Backlog parking lot. No committed phase.
readonly MILESTONE_FIELD_TYPE="TEXT"

# ============================================================================
# SECTION 2: UTILITY FUNCTIONS
# ============================================================================
# Helper functions for logging, error handling, and common operations.
# These keep the main logic clean and provide consistent output formatting.
# ============================================================================

# Color codes for terminal output.
# These make the script's output easier to scan visually.
# If your terminal doesn't support colors, the output will still be readable.
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'  # No Color (reset)

# log_info: Print an informational message to stdout.
# Usage: log_info "Creating project..."
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# log_success: Print a success message to stdout.
# Usage: log_success "Project created successfully."
log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# log_warn: Print a warning message to stderr.
# Warnings are non-fatal — the script continues executing.
# Usage: log_warn "Field 'Status' already exists. Skipping."
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

# log_error: Print an error message to stderr and exit with the given code.
# Usage: log_error "gh CLI not found. Please install it." 1
log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit "${2:-1}"
}

# log_phase: Print a phase header. Makes the output easy to scan.
# Usage: log_phase 1 "Project Creation"
log_phase() {
    local phase_num="$1"
    local phase_name="$2"
    echo ""
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  Phase ${phase_num}: ${phase_name}${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# log_step: Print a numbered step within a phase.
# Usage: log_step "2.1" "Creating Status field"
log_step() {
    local step_id="$1"
    local step_name="$2"
    echo -e "${BOLD}  [${step_id}]${NC} ${step_name}"
}

# get_project_number: Given a project title, find the project number.
# Returns the project number on stdout, or empty string if not found.
# This is used for idempotency — we check if the project already exists
# before trying to create it.
#
# How it works:
#   1. Lists all projects for the owner in JSON format
#   2. Uses jq to filter by title and extract the number
#   3. Returns the first match (there should only be one)
get_project_number() {
    local title="$1"
    gh project list --owner "${OWNER}" --format json -L 100 \
        | jq -r ".projects[] | select(.title==\"${title}\") | .number" \
        | head -1
}

# field_exists: Check if a field with the given name already exists in the project.
# Returns 0 (true) if it exists, 1 (false) if it doesn't.
# Used for idempotency — we skip field creation if it already exists.
#
# Parameters:
#   $1 = Project number
#   $2 = Field name to check for
field_exists() {
    local project_num="$1"
    local field_name="$2"
    local result

    result=$(gh project field-list "${project_num}" --owner "${OWNER}" --format json \
        | jq -r ".fields[] | select(.name==\"${field_name}\") | .name" \
        | head -1)

    [[ -n "${result}" ]]
}

# create_single_select_field: Create a Single Select field with options.
# Checks for existence first (idempotent).
#
# Parameters:
#   $1 = Project number
#   $2 = Field name
#   $3 = Comma-separated options string
create_single_select_field() {
    local project_num="$1"
    local field_name="$2"
    local options="$3"

    if field_exists "${project_num}" "${field_name}"; then
        log_warn "Field '${field_name}' already exists. Skipping creation."
        return 0
    fi

    log_info "Creating field: ${field_name} (Single Select)"
    gh project field-create "${project_num}" \
        --owner "${OWNER}" \
        --name "${field_name}" \
        --data-type "SINGLE_SELECT" \
        --single-select-options "${options}"

    log_success "Field '${field_name}' created with options: ${options}"
}

# create_text_field: Create a Text field.
# Checks for existence first (idempotent).
#
# Parameters:
#   $1 = Project number
#   $2 = Field name
create_text_field() {
    local project_num="$1"
    local field_name="$2"

    if field_exists "${project_num}" "${field_name}"; then
        log_warn "Field '${field_name}' already exists. Skipping creation."
        return 0
    fi

    log_info "Creating field: ${field_name} (Text)"
    gh project field-create "${project_num}" \
        --owner "${OWNER}" \
        --name "${field_name}" \
        --data-type "TEXT"

    log_success "Field '${field_name}' created."
}

# ============================================================================
# SECTION 3: PREREQUISITE CHECKS
# ============================================================================
# Before doing anything, verify that the environment is set up correctly.
# This prevents confusing errors halfway through the script.
# ============================================================================

log_phase "0" "Prerequisite Checks"

# Check 1: Is the gh CLI installed?
# The gh (GitHub CLI) tool is the foundation of this entire script.
# Install it from: https://cli.github.com/
log_step "0.1" "Checking for gh CLI..."
if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) is not installed. Install it from https://cli.github.com/" 1
fi
log_success "gh CLI found: $(gh --version | head -1)"

# Check 2: Is the user authenticated?
# The gh CLI needs to be logged in with a token that has the 'project' scope.
# If you haven't added the project scope, run: gh auth refresh -s project
log_step "0.2" "Checking gh authentication..."
if ! gh auth status &> /dev/null; then
    log_error "gh is not authenticated. Run 'gh auth login' first." 1
fi
log_success "gh is authenticated."

# Check 3: Is jq installed?
# jq is a command-line JSON processor. We use it to parse the JSON output
# from gh commands to extract IDs, check for existing resources, etc.
# Install it from: https://jqlang.github.io/jq/
log_step "0.3" "Checking for jq..."
if ! command -v jq &> /dev/null; then
    log_error "jq is not installed. Install it from https://jqlang.github.io/jq/" 1
fi
log_success "jq found: $(jq --version)"

# Check 4: Do the target repositories exist?
# Each of the three repos must already exist under the owner's account.
# This script does NOT create repositories — only the project board.
log_step "0.4" "Checking repository access..."
for repo in "${REPOS[@]}"; do
    if ! gh repo view "${OWNER}/${repo}" &> /dev/null; then
        log_error "Repository '${OWNER}/${repo}' not found or not accessible. Ensure it exists and you have access." 1
    fi
    log_success "Repository '${OWNER}/${repo}' is accessible."
done

echo ""
log_success "All prerequisites passed."

# ============================================================================
# SECTION 4: PHASE 1 — PROJECT CREATION
# ============================================================================
# Create the GitHub Projects V2 board. This is the container that holds
# all custom fields, views, items, and automation rules.
#
# The project is created at the user level (not org level) since all three
# repos live under the same personal account (southpawriter02).
# ============================================================================

log_phase "1" "Project Creation"

# Check if the project already exists (idempotency).
# If it does, we'll reuse it. If not, we create it.
log_step "1.1" "Checking for existing project: '${PROJECT_TITLE}'"
PROJECT_NUM=$(get_project_number "${PROJECT_TITLE}")

if [[ -n "${PROJECT_NUM}" ]]; then
    log_warn "Project '${PROJECT_TITLE}' already exists (number: ${PROJECT_NUM}). Reusing."
else
    log_info "Creating project: '${PROJECT_TITLE}'"

    # gh project create returns the project URL on success.
    # We capture it, then look up the project number for subsequent commands.
    gh project create \
        --owner "${OWNER}" \
        --title "${PROJECT_TITLE}"

    # After creation, look up the number we just created.
    # There can be a slight propagation delay, so we retry a few times.
    sleep 2
    PROJECT_NUM=$(get_project_number "${PROJECT_TITLE}")

    if [[ -z "${PROJECT_NUM}" ]]; then
        log_error "Project was created but could not find its number. Check the GitHub UI." 2
    fi

    log_success "Project created: number ${PROJECT_NUM}"
fi

# Set the project description.
# This provides context when someone visits the project page.
log_step "1.2" "Setting project description"
gh project edit "${PROJECT_NUM}" \
    --owner "${OWNER}" \
    --description "${PROJECT_DESCRIPTION}"
log_success "Description set."

# Store the project number for use in subsequent phases.
# This variable is used by every field-create and link command below.
echo ""
log_info "Project number: ${PROJECT_NUM}"
log_info "Project URL: https://github.com/users/${OWNER}/projects/${PROJECT_NUM}"

# ============================================================================
# SECTION 5: PHASE 2 — CUSTOM FIELDS
# ============================================================================
# Create all custom fields that define the project's metadata schema.
# Fields are the columns/properties that appear on each issue when viewed
# in the project board.
#
# GitHub Projects V2 has a built-in "Status" field, but it only has
# "Todo", "In Progress", "Done" by default. We replace it with our
# custom Status field that has the full workflow stages.
#
# NOTE: The gh CLI creates fields but CANNOT set colors on Single Select
# options. Colors must be assigned manually in the web UI.
# ============================================================================

log_phase "2" "Custom Fields"

# --- 2.1: Status Field ---
# The core workflow state. Items flow through these stages from left to right.
# This field powers the Kanban board view.
log_step "2.1" "Creating Status field"
create_single_select_field "${PROJECT_NUM}" "Status" "${STATUS_OPTIONS}"

# --- 2.2: Priority Field ---
# Determines triage order. P0 items get worked on immediately; P3 items
# sit in the backlog until someone has time (or forever).
log_step "2.2" "Creating Priority field"
create_single_select_field "${PROJECT_NUM}" "Priority" "${PRIORITY_OPTIONS}"

# --- 2.3: Size Field ---
# T-shirt sizing for effort estimation. Helps with planning and deciding
# whether an issue needs a specification before implementation.
log_step "2.3" "Creating Size field"
create_single_select_field "${PROJECT_NUM}" "Size" "${SIZE_OPTIONS}"

# --- 2.4: Type Field ---
# Categorizes the nature of the work. This is the most heavily modified field
# compared to the original Rune & Rust board:
#   - "Lore" removed (we're technical-only, no worldbuilding content tracking)
#   - "Research" added (for Colab experiments and empirical validation)
#   - "Spec" added (for design documents — separate from general Docs)
#   - "Notebook" added (for Colab/Jupyter notebook development)
log_step "2.4" "Creating Type field"
create_single_select_field "${PROJECT_NUM}" "Type" "${TYPE_OPTIONS}"

# --- 2.5: Track Field ---
# NEW FIELD. Replaces the free-text "Feature Group" from the original board.
# Using Single Select instead of Text ensures consistent values and enables
# the Roadmap view to group by track reliably.
log_step "2.5" "Creating Track field"
create_single_select_field "${PROJECT_NUM}" "Track" "${TRACK_OPTIONS}"

# --- 2.6: Milestone Field ---
# NEW FIELD. Replaces the "Target Ver" iteration field from the original board.
# We use Text instead of Iteration because:
#   - Milestones don't have fixed 2-week cadences
#   - Different tracks progress at different rates
#   - Text is more flexible for a research-heavy initiative
log_step "2.6" "Creating Milestone field"
create_text_field "${PROJECT_NUM}" "Milestone"

# --- 2.7: Document ID Field ---
# NEW FIELD. Tracks which deliverable document an issue maps to.
# The Master Strategy defines specific document IDs (D-10 through D-15 for
# Track A, D-20 through D-28 for Track B). This field links an issue back
# to its specification in the document manifest.
# Examples: "D-10", "D-14", "D-21", "R-01"
log_step "2.7" "Creating Document ID field"
create_text_field "${PROJECT_NUM}" "Document ID"

echo ""
log_success "All custom fields created."

# ============================================================================
# SECTION 6: PHASE 3 — REPOSITORY LINKING
# ============================================================================
# Link each of the three repositories to the project. This enables:
#   1. Issues from any repo to appear on the board
#   2. The "Add to Project" option when creating issues in those repos
#   3. PR/Issue cross-references to work with the project's automation rules
#
# The gh project link command connects a repository to a project so that
# the project appears in the repo's "Projects" sidebar.
# ============================================================================

log_phase "3" "Repository Linking"

for repo in "${REPOS[@]}"; do
    log_step "3.x" "Linking repository: ${OWNER}/${repo}"

    # The --repo flag takes "owner/repo" format.
    # If the link already exists, gh will return a non-zero exit code,
    # which we catch and treat as a warning (not an error).
    if gh project link "${PROJECT_NUM}" --owner "${OWNER}" --repo "${OWNER}/${repo}" 2>/dev/null; then
        log_success "Linked ${OWNER}/${repo} to project."
    else
        log_warn "Could not link ${OWNER}/${repo}. It may already be linked, or permissions may be insufficient."
    fi
done

echo ""
log_success "Repository linking complete."

# ============================================================================
# SECTION 7: PHASE 4 — ISSUE TEMPLATES
# ============================================================================
# Create standardized issue templates in each repository.
# These templates ensure consistent metadata when creating new issues,
# which helps both human developers and AI assistants (like Claude)
# understand the context and requirements of each issue.
#
# We create four templates in each repo:
#   1. Feature Request  - New functionality
#   2. Bug Report       - Defect report
#   3. Spec Document    - NEW: Design specification task
#   4. Research Task    - NEW: Empirical investigation / benchmarking
#
# Templates are stored in .github/ISSUE_TEMPLATE/ as Markdown files
# with YAML front matter that configures the template picker UI.
#
# NOTE: This section uses heredocs to write the template content.
# The templates are written to a temporary directory first, then committed
# to each repo. If you don't want auto-commits, set DRY_RUN_TEMPLATES=true.
# ============================================================================

log_phase "4" "Issue Templates"

# We'll write template files to a temp directory, then provide instructions
# for adding them to each repo. We don't auto-commit to repos because:
#   1. The repos might not be cloned locally
#   2. Auto-pushing could conflict with branch protection rules
#   3. The user should review templates before committing

# Create temp directory for template files
TEMPLATE_DIR="/tmp/gh-project-templates"
mkdir -p "${TEMPLATE_DIR}"

# --- Template 1: Feature Request ---
log_step "4.1" "Generating Feature Request template"
cat > "${TEMPLATE_DIR}/feature_request.md" << 'TEMPLATE_EOF'
---
name: "Feature Request"
about: "Propose new functionality for Chronicle, FractalRecall, or Haiku Protocol"
title: "[Feature] "
labels: ""
assignees: ""
---

## Context

<!-- Link to relevant spec, strategy document, or Notion page -->
<!-- Example: See D-14 LLM Integration Spec, Section 3.2 -->

**Track:** <!-- Track A (Chronicle) | Track B (FractalRecall) | Track C (Haiku Protocol) | Cross-Cutting -->
**Document ID:** <!-- e.g., D-10, D-21, R-05, or N/A -->

## Requirements

<!-- List the specific, testable requirements for this feature -->
- [ ] Requirement 1
- [ ] Requirement 2
- [ ] Requirement 3

## Acceptance Criteria

<!-- How do we know this is "done"? Be specific. -->
- [ ] Criterion 1
- [ ] Criterion 2

## Dependencies

<!-- What must be completed before this can start? -->
- Relies on: <!-- #issue_number or "None" -->
- Blocks: <!-- #issue_number or "None" -->

## Documentation

<!-- Where does the spec or design doc live? -->
- Spec: <!-- e.g., docs/D-14-llm-integration-spec.md -->
- Plan: <!-- e.g., Chronicle-FractalRecall-Master-Strategy.md, Section 6.3 -->

## Notes

<!-- Any additional context, constraints, or open questions -->
TEMPLATE_EOF
log_success "Feature Request template generated."

# --- Template 2: Bug Report ---
log_step "4.2" "Generating Bug Report template"
cat > "${TEMPLATE_DIR}/bug_report.md" << 'TEMPLATE_EOF'
---
name: "Bug Report"
about: "Report a defect in Chronicle, FractalRecall, or Haiku Protocol"
title: "[Bug] "
labels: ""
assignees: ""
---

## Description

<!-- What happened? What did you expect to happen instead? -->

## Environment

- **Project:** <!-- Chronicle | FractalRecall | Haiku Protocol -->
- **Version/Branch:** <!-- e.g., main, v0.2.1, feat/chunker-pipeline -->
- **Runtime:** <!-- e.g., .NET 10, Python 3.11, Colab Pro -->
- **OS:** <!-- e.g., Windows 11, Ubuntu 22.04, macOS Sonoma -->

## Stack Trace / Error Output

```
(Paste error output or stack trace here)
```

## Reproduction Steps

1. Go to...
2. Run...
3. Observe...

## Expected Behavior

<!-- What should have happened? -->

## Actual Behavior

<!-- What actually happened? -->

## Additional Context

<!-- Screenshots, logs, related issues, etc. -->
TEMPLATE_EOF
log_success "Bug Report template generated."

# --- Template 3: Spec Document (NEW) ---
# This template didn't exist on the original Rune & Rust board.
# It's designed for the documentation-first workflow where specs must be
# written and reviewed before implementation begins.
log_step "4.3" "Generating Spec Document template"
cat > "${TEMPLATE_DIR}/spec_document.md" << 'TEMPLATE_EOF'
---
name: "Spec Document"
about: "Create or update a design specification or architecture document"
title: "[Spec] "
labels: ""
assignees: ""
---

## Spec Overview

<!-- What system, feature, or component does this spec describe? -->

**Track:** <!-- Track A (Chronicle) | Track B (FractalRecall) | Track C (Haiku Protocol) | Cross-Cutting -->
**Document ID:** <!-- e.g., D-10, D-14, D-22 -->
**Target Path:** <!-- e.g., docs/D-14-llm-integration-spec.md -->

## Scope

<!-- What decisions does this spec need to make? What questions does it answer? -->
- Decision 1: ...
- Decision 2: ...

## Prior Art

<!-- What existing documents, research, or code informs this spec? -->
- Reference: <!-- e.g., Chronicle-FractalRecall-Master-Strategy.md, Section 6.3 -->
- Reference: <!-- e.g., fractalrecall-conceptual-architectural-design.md -->

## Deliverables

<!-- What artifacts will this spec produce? -->
- [ ] Spec document committed to `docs/`
- [ ] Decision log entries added to Master Strategy
- [ ] Dependent issues updated with spec reference

## Open Questions

<!-- What needs to be resolved during spec writing? -->
1. ...
2. ...

## Definition of Done

- [ ] Spec document reviewed and committed
- [ ] All open questions resolved or explicitly deferred
- [ ] Related issues linked to this spec
- [ ] Status moved from "Spec Review" to "Ready" for implementation issues
TEMPLATE_EOF
log_success "Spec Document template generated."

# --- Template 4: Research Task (NEW) ---
# This template supports the empirical validation work that is central to
# Track B (FractalRecall Colab prototyping) and the Haiku Protocol integration.
# Research tasks produce data and findings, not necessarily code.
log_step "4.4" "Generating Research Task template"
cat > "${TEMPLATE_DIR}/research_task.md" << 'TEMPLATE_EOF'
---
name: "Research Task"
about: "Empirical investigation, benchmarking, or literature review"
title: "[Research] "
labels: ""
assignees: ""
---

## Research Question

<!-- What specific question are we trying to answer? -->

**Track:** <!-- Track A (Chronicle) | Track B (FractalRecall) | Track C (Haiku Protocol) | Cross-Cutting -->
**Research ID:** <!-- e.g., R-01, R-05 from Master Strategy Section 8 -->

## Hypothesis

<!-- What do we expect to find? State it as a testable hypothesis. -->
<!-- Example: "FractalRecall's multi-layer enrichment will improve retrieval precision by >15% vs. baseline embedding." -->

## Methodology

<!-- How will we investigate this? -->
- **Approach:** <!-- e.g., Colab notebook experiment, literature review, benchmark comparison -->
- **Data Source:** <!-- e.g., Aethelgard test corpus, synthetic data, public dataset -->
- **Metrics:** <!-- What will we measure? e.g., retrieval precision@5, compression ratio, token count -->
- **Tools:** <!-- e.g., Google Colab Pro, nomic-embed-text-v2-moe, LLMLingua -->

## Deliverables

- [ ] Notebook/report with findings
- [ ] Summary of results in Master Strategy decision log
- [ ] Go/No-Go recommendation (if applicable)

## Success Criteria

<!-- What result would validate the hypothesis? What would invalidate it? -->
- **Validates if:** ...
- **Invalidates if:** ...

## Dependencies

- Relies on: <!-- #issue_number or "None" -->
- Informs: <!-- What future work depends on this research? -->

## Notes

<!-- Additional context, references, or constraints -->
TEMPLATE_EOF
log_success "Research Task template generated."

echo ""
log_success "All templates generated in: ${TEMPLATE_DIR}/"
echo ""
log_info "To add these templates to a repository, copy them into the repo's"
log_info ".github/ISSUE_TEMPLATE/ directory and commit:"
echo ""
for repo in "${REPOS[@]}"; do
    echo -e "  ${CYAN}# For ${repo}:${NC}"
    echo "  mkdir -p /path/to/${repo}/.github/ISSUE_TEMPLATE"
    echo "  cp ${TEMPLATE_DIR}/*.md /path/to/${repo}/.github/ISSUE_TEMPLATE/"
    echo "  cd /path/to/${repo} && git add .github/ && git commit -m \"Add issue templates for project board\""
    echo ""
done

# ============================================================================
# SECTION 8: PHASE 5 — MANUAL CONFIGURATION CHECKLIST
# ============================================================================
# The gh CLI has significant limitations when it comes to configuring the
# visual and behavioral aspects of a GitHub Project V2 board. The following
# items MUST be configured manually through the GitHub web UI.
#
# This section prints a detailed, step-by-step checklist so you don't have
# to remember what needs to be done — just follow the instructions.
# ============================================================================

log_phase "5" "Manual Configuration Checklist"

echo -e "${BOLD}The following items must be configured manually in the GitHub web UI.${NC}"
echo -e "${BOLD}Project URL: https://github.com/users/${OWNER}/projects/${PROJECT_NUM}${NC}"
echo ""

# --- 5.1: Field Colors ---
cat << 'COLORS_EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  5.1  SET FIELD OPTION COLORS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Go to: Project Settings > Fields > (each field) > Edit options

  STATUS:
    □  Backlog       → Gray
    □  Spec Review   → Blue
    □  Ready         → Green
    □  In Progress   → Yellow
    □  QA / Verify   → Purple
    □  Done          → Dark Green

  PRIORITY:
    □  P0 (Critical) → Red
    □  P1 (High)     → Orange
    □  P2 (Normal)   → Blue
    □  P3 (Someday)  → Gray

  TYPE:
    □  Feature       → Green
    □  Bug           → Red
    □  Refactor      → Orange
    □  Docs          → Blue
    □  Research      → Purple
    □  Spec          → Teal / Cyan
    □  Notebook      → Pink

  TRACK:
    □  Track A (Chronicle)      → Blue
    □  Track B (FractalRecall)  → Green
    □  Track C (Haiku Protocol) → Purple
    □  Cross-Cutting            → Gray

COLORS_EOF

# --- 5.2: Views ---
cat << VIEWS_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  5.2  CREATE VIEWS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  VIEW 1: "Roadmap" (Timeline Layout)
    □  New View > Name: "Roadmap" > Layout: Timeline
    □  Group By: Track
    □  Filter: Status is not "Done"
    □  Purpose: Strategic view — "What are we building across all three tracks?"

  VIEW 2: "The Board" (Kanban Layout)
    □  New View > Name: "The Board" > Layout: Board
    □  Group By: Status
    □  Sort: Priority (Descending)
    □  Purpose: Daily execution — the active sprint view.

  VIEW 3: "Spec Review" (Table Layout)
    □  New View > Name: "Spec Review" > Layout: Table
    □  Filter: Status == "Spec Review"
    □  Columns: Title, Track, Priority, Size, Document ID, Assignee
    □  Purpose: Focus area for Claude/AI architecture tasks.

  VIEW 4: "Backlog Triage" (Table Layout)
    □  New View > Name: "Backlog Triage" > Layout: Table
    □  Filter: Status == "Backlog"
    □  Sort: Priority (Desc) > Type
    □  Purpose: Weekly planning — pull items from here into The Board.

  VIEW 5: "By Track" (Table Layout)  [NEW]
    □  New View > Name: "By Track" > Layout: Table
    □  Group By: Track
    □  Sort: Priority (Desc)
    □  Filter: Status is not "Done"
    □  Purpose: See all active work organized by project track.

VIEWS_EOF

# --- 5.3: Automation / Workflows ---
cat << AUTOMATION_EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  5.3  CONFIGURE AUTOMATION RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Go to: Project Settings > Workflows

  RULE 1: Auto-Add from chronicle
    □  Trigger: When an Issue is created in ${OWNER}/chronicle
    □  Action: Add to "${PROJECT_TITLE}"

  RULE 2: Auto-Add from fractalrecall
    □  Trigger: When an Issue is created in ${OWNER}/fractalrecall
    □  Action: Add to "${PROJECT_TITLE}"

  RULE 3: Auto-Add from haiku-protocol
    □  Trigger: When an Issue is created in ${OWNER}/haiku-protocol
    □  Action: Add to "${PROJECT_TITLE}"

  RULE 4: Auto-Archive
    □  Trigger: Item is in "Done" for 14 days
    □  Action: Archive

  RULE 5: PR Merge → QA (Optional but recommended)
    □  Trigger: Linked PR is merged
    □  Action: Set Status to "QA / Verify"
    □  Purpose: Reminds you to verify before marking Done.

  RULE 6: Item Closed → Done (Optional)
    □  Trigger: Item is closed
    □  Action: Set Status to "Done"

AUTOMATION_EOF

# --- 5.4: Default Status ---
cat << 'DEFAULT_EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  5.4  SET DEFAULT STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Go to: Project Settings > Fields > Status > Edit

    □  Set default value for new items: "Backlog"

DEFAULT_EOF

# ============================================================================
# SECTION 9: SUMMARY
# ============================================================================

log_phase "✓" "Setup Complete"

echo -e "${BOLD}What was created:${NC}"
echo "  • Project: '${PROJECT_TITLE}' (number ${PROJECT_NUM})"
echo "  • Custom Fields: Status, Priority, Size, Type, Track, Milestone, Document ID"
echo "  • Repository Links: ${REPOS[*]}"
echo "  • Issue Templates: Generated in ${TEMPLATE_DIR}/"
echo ""
echo -e "${BOLD}What still needs manual configuration:${NC}"
echo "  • Field option colors (Section 5.1)"
echo "  • Views — Roadmap, Board, Spec Review, Backlog Triage, By Track (Section 5.2)"
echo "  • Automation rules — 3x auto-add, auto-archive, PR sync (Section 5.3)"
echo "  • Default Status value set to 'Backlog' (Section 5.4)"
echo ""
echo -e "${BOLD}Project URL:${NC} https://github.com/users/${OWNER}/projects/${PROJECT_NUM}"
echo ""
echo -e "${GREEN}Done.${NC} Follow the manual checklist above to complete setup."
