# D-13: CLI Command Reference

**Document ID:** D-13
**Version:** 0.1.0-draft
**Status:** Draft
**Author:** Ryan (with specification guidance from Claude)
**Created:** 2026-02-10
**Last Updated:** 2026-02-10
**Dependencies:** D-01 (§4.7 — CLI Command Surface), D-10 (v0.2.1 — Lore File Schema), D-11 (v0.1.1-draft — Canon Workflow), D-12 (v0.1.1-draft — Validation Rule Catalog)
**Downstream Consumers:** D-42 (Chronicle README), D-44 (Chronicle User Guide), Phase 2 Implementation

---

## Table of Contents

- [1. Document Purpose and Scope](#1-document-purpose-and-scope)
- [2. Conventions and Terminology](#2-conventions-and-terminology)
  - [2.1. Command Specification Format](#21-command-specification-format)
  - [2.2. Argument and Option Notation](#22-argument-and-option-notation)
  - [2.3. Implementation Phase Labels](#23-implementation-phase-labels)
- [3. Global Options](#3-global-options)
- [4. Exit Code Reference](#4-exit-code-reference)
- [5. Phase 2 Commands (Core)](#5-phase-2-commands-core)
  - [5.1. `chronicle init`](#51-chronicle-init)
  - [5.2. `chronicle scan`](#52-chronicle-scan)
  - [5.3. `chronicle validate`](#53-chronicle-validate)
  - [5.4. `chronicle promote`](#54-chronicle-promote)
  - [5.5. `chronicle log`](#55-chronicle-log)
  - [5.6. `chronicle changelog`](#56-chronicle-changelog)
  - [5.7. `chronicle graph`](#57-chronicle-graph)
  - [5.8. `chronicle status`](#58-chronicle-status)
- [6. Phase 3 Commands (Integration)](#6-phase-3-commands-integration)
  - [6.1. `chronicle index`](#61-chronicle-index)
  - [6.2. `chronicle search`](#62-chronicle-search)
- [7. Phase 4 Commands (LLM-Powered)](#7-phase-4-commands-llm-powered)
  - [7.1. `chronicle suggest`](#71-chronicle-suggest)
  - [7.2. `chronicle stub`](#72-chronicle-stub)
- [8. Output Formats](#8-output-formats)
  - [8.1. Validation Report Format](#81-validation-report-format)
  - [8.2. Changelog Output Format](#82-changelog-output-format)
  - [8.3. Graph Output Formats](#83-graph-output-formats)
  - [8.4. Search Result Format](#84-search-result-format)
- [9. Configuration Reference](#9-configuration-reference)
  - [9.1. Configuration File Location](#91-configuration-file-location)
  - [9.2. Configuration Sections](#92-configuration-sections)
- [10. Cross-Reference Index](#10-cross-reference-index)
  - [10.1. Commands to D-12 Validation Rules](#101-commands-to-d-12-validation-rules)
  - [10.2. Commands to D-11 Workflows](#102-commands-to-d-11-workflows)
  - [10.3. Commands to D-10 Schema Elements](#103-commands-to-d-10-schema-elements)
- [11. Dependencies and Cross-References](#11-dependencies-and-cross-references)
- [12. Document Revision History](#12-document-revision-history)

---

## 1. Document Purpose and Scope

This document formally specifies every CLI command in the Chronicle tool. It defines the command syntax, all arguments and options, behavioral semantics, exit codes, expected output, and worked examples using Aethelgard content. This is the specification that Phase 2 implementation of the Spectre.Console.Cli command framework will be built against.

**What this document covers:**

- Every `chronicle` subcommand with complete synopsis, description, and option definitions
- Behavioral specifications: what each command does, in what order, and what side effects it has (file modifications, Git commits, changelog entries)
- Exit codes for every command
- Worked examples with realistic Aethelgard input and expected console output
- Error scenarios and how each command responds to failures
- Cross-references to D-10 (schema elements each command interacts with), D-11 (workflows each command implements), and D-12 (validation rules each command invokes)

**What this document does NOT cover:**

- The schema data model itself (see D-10: Lore File Schema Specification)
- Canon workflow policies and transition rules (see D-11: Canon Workflow Specification)
- Individual validation rule definitions and test cases (see D-12: Validation Rule Catalog)
- LLM prompt templates and response parsing (see D-14: LLM Integration Specification)
- FractalRecall embedding strategy and context layer construction (see D-15: Integration Design Document, blocked on Track B results)

**Implementation phasing:** Commands are organized by the development phase in which they will be implemented. Phase 2 commands (§5) are the core CLI that operates on Chronicle's deterministic domain model. Phase 3 commands (§6) integrate FractalRecall for embedding and search. Phase 4 commands (§7) add LLM-powered analysis features. Phase 3 and Phase 4 command specifications are marked as **preliminary** — their behavioral details will be refined after the Track B Colab prototyping results (D-23 go/no-go decision) and D-14 (LLM Integration Specification) are complete.

**CLI commands vs. manual operations:** D-11 defines six canonical workflows (promotion, deprecation, apocryphal creation, restoration, re-drafting, retconning). Of these, D-13 provides dedicated CLI commands for operations that serve as quality gates — transitions that require validation, confirmation, changelog generation, or Git integration:

- **`chronicle promote`** handles promotion (draft → canonical) and restoration (deprecated → canonical), because these are the transitions that introduce content into canon and require the most rigorous validation gating.

The remaining four workflows — deprecation, retconning, re-drafting, and apocryphal reclassification — are performed by **directly editing the `canon` field** in the YAML frontmatter and running `chronicle validate` afterward. This is intentional and follows D-11's ceremony tier model: low-ceremony transitions (D-11 §4.3) require only a field edit, and even medium-ceremony transitions like re-drafting (D-11 §4.4) are structurally just field edits with a validation step. Providing wrapper commands for every field edit would add CLI surface area without adding safety. The validation command is the universal quality gate.

Future versions may add convenience commands (e.g., `chronicle deprecate`, `chronicle retcon`) if workflow friction warrants them. These would be thin wrappers around field edits + validation + changelog generation, not new behavioral primitives.

---

## 2. Conventions and Terminology

### 2.1. Command Specification Format

Every command in this document follows a standardized specification template:

```
Command: chronicle <subcommand>
Synopsis: chronicle <subcommand> [arguments] [options]
Phase: N — Phase Name
Description: What the command does, why it exists, and what side effects it has.
Arguments: Positional arguments (if any), with types and defaults.
Options: Named options and flags, with types, defaults, and descriptions.
Exit Codes: Numeric codes returned on completion.
Behavior: Step-by-step description of what happens when the command runs.
Examples: Worked examples with Aethelgard content showing input and expected output.
Error Scenarios: Common failure modes and how the command responds.
Cross-References: Links to D-10, D-11, and D-12 sections that govern this command.
```

### 2.2. Argument and Option Notation

This document uses the following notation conventions, consistent with POSIX and Spectre.Console.Cli conventions:

| Notation | Meaning |
|---|---|
| `<arg>` | Required positional argument |
| `[arg]` | Optional positional argument |
| `--option VALUE` | Named option requiring a value |
| `--flag` | Boolean flag (present = true, absent = false) |
| `--option VALUE1,VALUE2` | Comma-separated list value |
| `VALUE...` | Repeatable argument (one or more values) |
| `[options]` | Placeholder for any applicable options |
| `\|` | Mutually exclusive alternatives |

**Type abbreviations used in option tables:**

| Abbreviation | Meaning | Example |
|---|---|---|
| `string` | Free-form text value | `--output report.md` |
| `path` | File system path (relative to repository root) | `factions/iron-covenant.md` |
| `enum` | Value from a fixed set | `--severity error\|warning\|info` |
| `int` | Integer value | `--top 10` |
| `bool` | Boolean flag (no value required) | `--deep` |
| `glob` | Unix glob pattern | `--type faction` |

### 2.3. Implementation Phase Labels

Each command specification includes a phase label indicating when the command will be implemented:

| Label | Meaning | Specification Depth |
|---|---|---|
| **Phase 2 — Core** | Deterministic CLI commands. No FractalRecall or LLM dependencies. | Full specification. Implementable as-is. |
| **Phase 3 — Integration** | Commands that require FractalRecall embedding/search integration. | Preliminary specification. Behavioral details subject to refinement after D-23 (go/no-go) and D-15 (Integration Design). |
| **Phase 4 — LLM-Powered** | Commands that require a configured LLM endpoint for analysis and generation. | Preliminary specification. Prompt templates and response parsing defined in D-14 (LLM Integration Specification). |

---

## 3. Global Options

The following options are available on every `chronicle` subcommand. They control output behavior, configuration loading, and help display.

| Option | Type | Default | Description |
|---|---|---|---|
| `--help`, `-h` | `bool` | `false` | Display help text for the current command, including synopsis, description, and all available options. |
| `--version` | `bool` | `false` | Display the Chronicle version string and exit. Format: `chronicle X.Y.Z` (SemVer). |
| `--config <path>` | `path` | `.chronicle/config.yaml` | Specify an alternate configuration file. If the path does not exist, Chronicle exits with code 2 and an error message. |
| `--verbose`, `-v` | `bool` | `false` | Enable verbose output. For `validate`, this includes remediation hints for each rule violation. For other commands, this includes additional diagnostic information (files scanned, timing, internal state). |
| `--quiet`, `-q` | `bool` | `false` | Suppress all output except errors. Mutually exclusive with `--verbose`. If both are specified, `--quiet` wins. |
| `--no-color` | `bool` | `false` | Disable ANSI color codes in output. Useful for piping output to files or non-terminal consumers. Chronicle auto-detects non-TTY output and disables color automatically; this flag forces the behavior in TTY contexts. |
| `--no-git` | `bool` | `false` | Disable all Git integration. Branch detection, commit generation, and merge analysis are skipped. Useful for operating on exported archives or standalone documentation folders outside of Git repositories. See D-11 §7.1 for Git-optional behavior. |

**Mutual exclusivity:** `--verbose` and `--quiet` are mutually exclusive. If both are provided, `--quiet` takes precedence (errors only).

**Auto-detection:** Chronicle auto-detects whether stdout is a TTY. In non-TTY contexts (pipes, file redirection), color is disabled and progress spinners are replaced with simple status lines.

---

## 4. Exit Code Reference

All Chronicle commands return one of the following exit codes. Commands document which codes they can produce in their individual specifications.

| Code | Name | Meaning |
|---|---|---|
| `0` | `SUCCESS` | Command completed successfully. For `validate`, this means zero errors (warnings and informational messages do not affect exit code). |
| `1` | `ERROR` | Command completed but found problems. For `validate`, at least one ERROR-severity rule failed. For `promote`, validation failed or the user cancelled the confirmation prompt. For other commands, a recoverable operational error occurred. |
| `2` | `CONFIG_ERROR` | Configuration or environment problem prevented the command from running. Examples: `.chronicle/` directory not found (`init` not run), config file malformed, schema file missing or invalid, required option missing. |
| `3` | `GIT_ERROR` | A Git operation failed or required Git context is unavailable and `--no-git` was not specified. Examples: not a Git repository, merge conflict detected, branch detection failed. |
| `4` | `LLM_ERROR` | An LLM endpoint is required but not configured or not responding. Only returned by commands that use `--deep` or Phase 4 commands (`suggest`, `stub`). |

**Signal handling:** If the user interrupts Chronicle with Ctrl+C (SIGINT), the tool terminates cleanly with exit code 130 (standard POSIX convention: 128 + signal number). Any in-progress file modifications are rolled back; no partial writes are left on disk.

**Exit code design rationale:** The graduated exit codes allow shell scripts and CI/CD pipelines to distinguish between "validation found problems" (code 1, expected in development workflows) and "something is misconfigured" (code 2, needs operator attention). The separation of Git errors (code 3) and LLM errors (code 4) from general errors helps diagnose environment issues without parsing output text.

---

## 5. Phase 2 Commands (Core)

These commands form Chronicle's core CLI. They operate entirely on the deterministic domain model — YAML parsing, schema validation, cross-reference integrity, canon workflow, and changelog management. They have no dependencies on FractalRecall or LLM services.

---

### 5.1. `chronicle init`

```
Command:  chronicle init
Synopsis: chronicle init [options]
Phase:    2 — Core
```

**Description:** Initialize a new Chronicle repository in the current directory. Creates the `.chronicle/` configuration directory, populates it with the twelve default entity type schema files, the common schema, and a default `config.yaml`. If a `.chronicle/` directory already exists, the command exits with a warning and takes no action (idempotent safety).

This is typically the first Chronicle command a user runs in a new or existing Git repository. After `init`, the repository is ready for `chronicle scan` and `chronicle validate`.

**Arguments:** None.

**Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `--force` | `bool` | `false` | Re-initialize an existing Chronicle repository. Overwrites default schema files with fresh copies but preserves custom schemas in `.chronicle/schema/custom/`, `config.yaml` (if modified), and changelog data in `.chronicle/changelog/`. Use when default schemas need to be reset after a Chronicle version upgrade. |

**Exit Codes:** `0` (success), `2` (config error — e.g., no write permission).

**Behavior:**

1. Check whether `.chronicle/` exists in the current directory.
   - If it exists and `--force` is NOT set: print warning `"Chronicle repository already initialized. Use --force to re-initialize."` and exit with code 0.
   - If it exists and `--force` IS set: proceed to step 2, preserving custom schemas, config modifications, and changelog data.
2. Create the `.chronicle/` directory structure:
   ```
   .chronicle/
   ├── config.yaml              # Default configuration
   ├── schema/
   │   ├── common.schema.json    # Common fields (all entity types)
   │   ├── faction.schema.json   # 12 default entity type schemas
   │   ├── character.schema.json
   │   ├── entity.schema.json
   │   ├── locale.schema.json
   │   ├── event.schema.json
   │   ├── timeline.schema.json
   │   ├── system.schema.json
   │   ├── axiom.schema.json
   │   ├── item.schema.json
   │   ├── document.schema.json
   │   ├── term.schema.json
   │   ├── meta.schema.json
   │   └── custom/               # Empty directory for user-defined schemas
   └── changelog/                # Empty directory for per-entity changelogs
   ```
3. Write the default `config.yaml` (see §9.2 for full configuration reference):
   ```yaml
   # .chronicle/config.yaml
   # Chronicle Configuration — generated by chronicle init
   chronicle_version: "1.0.0"

   branch_conventions:
     canonical_branch: "main"
     apocryphal_pattern: "apocrypha/*"

   validation:
     default_severity: "warning"

   changelog:
     auto_generate: true
   ```
4. Print a summary of what was created.

**Example:**

```
$ chronicle init

Chronicle initialized.
  Created: .chronicle/config.yaml
  Created: .chronicle/schema/ (12 default schemas + common schema)
  Created: .chronicle/schema/custom/ (empty — for user-defined types)
  Created: .chronicle/changelog/ (empty — populated on first promotion)

Next steps:
  1. Add lore files with YAML frontmatter (see schema docs)
  2. Run 'chronicle scan' to build the entity model
  3. Run 'chronicle validate' to check for issues
```

**Example (already initialized):**

```
$ chronicle init
Chronicle repository already initialized at .chronicle/
Use --force to re-initialize (preserves custom schemas and config).
```

**Example (re-initialize):**

```
$ chronicle init --force

Chronicle re-initialized.
  Refreshed: 12 default schema files + common schema
  Preserved: .chronicle/schema/custom/ (2 custom schemas)
  Preserved: .chronicle/config.yaml (user-modified)
  Preserved: .chronicle/changelog/ (14 entries)
```

**Error Scenarios:**

| Scenario | Behavior |
|---|---|
| No write permission to current directory | Exit code 2. Message: `"Cannot create .chronicle/ directory: permission denied."` |
| Disk full | Exit code 2. Message: `"Cannot create .chronicle/ directory: insufficient disk space."` |
| `.chronicle/` is a file (not a directory) | Exit code 2. Message: `".chronicle exists but is a file, not a directory. Remove it and retry."` |

**Cross-References:**

- D-10 §3.2 — Schema definition file structure and the twelve default schemas created by `init`
- D-10 §3.3 — Schema discovery and loading order (default vs. custom)
- D-10 §8.1 — Custom entity type schema location (`.chronicle/schema/custom/`)
- D-11 §7.3 — Branch convention configuration section in `config.yaml`

---

### 5.2. `chronicle scan`

```
Command:  chronicle scan
Synopsis: chronicle scan [options]
Phase:    2 — Core
```

**Description:** Scan the repository and build (or rebuild) the in-memory entity model — a graph of all lore files, their frontmatter metadata, and their inter-entity relationships. The scan operation parses every Markdown file in the repository that contains valid YAML frontmatter, extracts the structured data, and constructs an entity graph that subsequent commands (`validate`, `promote`, `graph`, `status`, `changelog`) operate on.

The scan is a **read-only** operation. It does not modify any files. Its output is an in-memory data structure that lives for the duration of the command invocation. In practice, most other commands implicitly run a scan as their first step — `scan` as an explicit command is useful for timing, diagnostics, and verifying that Chronicle correctly discovers and parses all lore files.

**Arguments:** None.

**Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `--path <dir>` | `path` | `.` (repository root) | Scan only files under the specified directory. Useful for large repositories where you want to validate a subdirectory without scanning everything. |
| `--stats` | `bool` | `false` | Display detailed statistics after scanning: file count by entity type, relationship count, canon status distribution, schema coverage. |

**Exit Codes:** `0` (success), `2` (config error — `.chronicle/` not found).

**Behavior:**

1. Verify that `.chronicle/` exists. If not, exit with code 2: `"No Chronicle repository found. Run 'chronicle init' first."`
2. Load schema definitions from `.chronicle/schema/` (common + all type-specific + custom).
3. Recursively scan the target directory for `.md` files.
4. For each `.md` file:
   a. Attempt to parse YAML frontmatter (lines between `---` delimiters).
   b. If no valid frontmatter: skip the file (it is not a lore file). See D-10 §3.1 rule 5.
   c. If valid frontmatter: extract `type`, `name`, `canon`, `relationships`, and all other fields.
   d. Register the entity in the in-memory graph.
5. After all files are parsed, resolve relationships:
   a. For each `relationships` entry, resolve `target` to a known entity.
   b. Compute bidirectional relationship inference (D-10 §7.4).
   c. Compute `supersedes` inference from `superseded_by` references (D-10 §4.8, D-11 §6.1).
6. Print scan summary.

**Example:**

```
$ chronicle scan

Chronicle Scan Complete
=======================
Files scanned:    147
Lore files found: 89 (58 non-lore Markdown files skipped)
Parse errors:     0

Entity Type Distribution:
  character:  23
  faction:    12
  locale:     18
  event:      14
  timeline:    4
  system:      6
  axiom:       3
  item:        5
  document:    2
  term:        1
  meta:        1
  (custom):    0

Canon Status Distribution:
  canonical:   52
  draft:       29
  apocryphal:   5
  deprecated:   3

Relationships: 214 declared, 198 resolved (16 unresolved targets)
```

**Example (with `--stats`):**

```
$ chronicle scan --stats

[... same as above, plus:]

Schema Coverage:
  Files with recognized type:     89 / 89 (100%)
  Files with all required fields: 86 / 89 (96.6%)
  Files with type-specific schema: 89 / 89 (100%)

Scan Timing:
  File discovery:   12ms
  YAML parsing:    145ms
  Graph assembly:   23ms
  Total:           180ms
```

**Error Scenarios:**

| Scenario | Behavior |
|---|---|
| `.chronicle/` not found | Exit code 2. Message: `"No Chronicle repository found. Run 'chronicle init' first."` |
| Schema file malformed (invalid JSON) | Exit code 2. Message: `"Schema file '{file}' is not valid JSON: {parse_error}."` |
| YAML parse error in a lore file | The file is reported as a parse error in the summary but does NOT prevent scanning of other files. The scan completes with exit code 0 (parse errors are surfaced by `validate`, not `scan`). |

**Cross-References:**

- D-10 §3.1 — File structure rules (frontmatter delimiters, non-lore file handling)
- D-10 §3.2 — Schema definition files loaded during scan
- D-10 §3.3 — Schema discovery and resolution order
- D-10 §7.4 — Bidirectional relationship inference computed during graph assembly
- D-10 §4.8 — Superseding inference computed during graph assembly

---

### 5.3. `chronicle validate`

```
Command:  chronicle validate
Synopsis: chronicle validate [<path>...] [options]
Phase:    2 — Core (deterministic); Phase 4 extension (--deep)
```

**Description:** Run validation checks against the current repository state. This is Chronicle's primary quality assurance command. It scans all lore files (or a specified subset), builds the entity model, and executes the validation rules defined in D-12 (Validation Rule Catalog) across three tiers: Schema (Tier 1), Structural (Tier 2), and Semantic (Tier 3).

The deterministic validation (Tiers 1-3) is a Phase 2 command with no external dependencies. The `--deep` flag extends validation with LLM-powered semantic checks (Phase 4), which require a configured LLM endpoint.

Validation follows the cascade gating architecture defined in D-12 §3: if any Tier 1 rule fails for a file, that file's Tier 2 and Tier 3 checks are skipped. Other files continue through the full pipeline. The final validation report aggregates results across all files.

**Arguments:**

| Argument | Type | Required | Description |
|---|---|---|---|
| `<path>...` | `path` (repeatable) | No | One or more file paths or directory paths to validate. If omitted, validates the entire repository. If a directory is specified, all lore files under that directory are validated. Paths are relative to the repository root. |

**Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `--deep` | `bool` | `false` | **[Phase 4]** Run LLM-powered semantic validation in addition to deterministic checks. Requires a configured LLM endpoint (see §9.2). Sends clusters of related documents to the LLM for contradiction detection, narrative tension identification, and consistency analysis. Results are appended to the validation report under a "Deep Validation" section. |
| `--output <file>` | `path` | `null` (console only) | Write the validation report to a Markdown file in addition to console output. The file is created or overwritten. Useful for archiving validation results or sharing with collaborators. |
| `--severity <level>` | `enum` | `warning` | Minimum severity level to include in the report. Filters output to show only messages at or above the specified level. Allowed values: `error`, `warning`, `info`. Note: this does NOT affect which rules are executed — all rules always run. It only filters what appears in the report. |
| `--type <type>` | `string` (repeatable) | `null` (all types) | Validate only entities of the specified type(s). Accepts any of the 12 default types or custom type names. Multiple `--type` flags can be combined: `--type faction --type character`. |
| `--rule <rule-id>` | `string` (repeatable) | `null` (all rules) | Run only the specified validation rule(s). Useful for focused debugging. Accepts rule IDs from D-12 (e.g., `VAL-SCH-001`, `VAL-REF-003`). Multiple `--rule` flags can be combined. |
| `--tier <tier>` | `enum` | `null` (all tiers) | Run only rules in the specified tier. Allowed values: `1` (Schema), `2` (Structural), `3` (Semantic). Useful for isolating categories of issues. |

**Exit Codes:** `0` (all checks passed), `1` (one or more ERROR-severity rules failed), `2` (config error), `4` (LLM error, only with `--deep`).

**Behavior:**

1. Run an implicit scan (§5.2 behavior) to build the entity model.
2. Load all validation rules from D-12 (or the subset specified by `--rule` / `--tier`).
3. For each lore file in scope (filtered by `<path>` and `--type` arguments):
   a. **Tier 1 — Schema Validation** (D-12 §5): Execute all 12 schema rules (VAL-SCH-001 through VAL-SCH-012). If any ERROR-severity rule fails, mark the file as Tier 1 failed and skip Tiers 2-3 for this file.
   b. **Tier 2 — Structural Validation** (D-12 §6): Execute all 15 structural rules (cross-references, superseding chains, multi-file entity hierarchy, uniqueness, branch conventions). These rules operate on the full entity graph and check inter-file consistency.
   c. **Tier 3 — Semantic Validation** (D-12 §7): Execute all 10 semantic rules (canon consistency, temporal ordering, axiom enforcement). These rules check narrative logic and world-internal coherence.
4. Apply apocryphal modifier to severity levels for files with `canon: "apocryphal"` (D-11 §9.1, D-12 §2):
   - Schema rules: severity unchanged (Error remains Error)
   - Cross-reference rules: Error → Warning
   - Timeline rules: Skipped entirely
   - Axiom rules: Skipped entirely
   - Uniqueness rules: Warning → Informational
5. If `--deep` is specified:
   a. Verify LLM endpoint is configured and reachable. If not, exit with code 4.
   b. Identify clusters of related documents (by shared tags, relationships, entity references).
   c. Send document clusters to the LLM for semantic analysis (see D-14 for prompt templates).
   d. Parse LLM responses and append findings to the validation report.
6. Aggregate results and generate the validation report (see §8.1 for format).
7. If `--output` is specified, write the report to the specified file.
8. Return exit code based on highest severity found: 0 if no errors, 1 if any errors.

**Example (clean validation):**

```
$ chronicle validate

Chronicle Validation Report
============================
Repository: /home/ryan/aethelgard
Branch:     feature/iron-covenant-update
Files:      89 lore files scanned

Tier 1 — Schema Validation:     89 / 89 passed
Tier 2 — Structural Validation: 89 / 89 passed
Tier 3 — Semantic Validation:   89 / 89 passed

Summary: 0 errors, 0 warnings, 0 informational
✓ All checks passed.
```

**Example (validation with issues):**

```
$ chronicle validate

Chronicle Validation Report
============================
Repository: /home/ryan/aethelgard
Branch:     feature/iron-covenant-update
Files:      89 lore files scanned

Tier 1 — Schema Validation:     87 / 89 passed (2 files gated)
Tier 2 — Structural Validation: 84 / 87 passed
Tier 3 — Semantic Validation:   82 / 84 passed

Results:

[ERROR] VAL-SCH-002 — Missing required field(s): canon. All entries must
  include type, name, and canon. (File: factions/shadow-conclave.md)

[ERROR] VAL-SCH-005 — Type 'axiom' requires fields: axiom_type, enforcement,
  assertion. Missing: assertion.
  (File: axioms/law-of-conservation.md)

[WARNING] VAL-REF-001 — Relationship target 'characters/marcus-thane.md' does
  not exist. Referenced from 'factions/iron-covenant.md' (relationship:
  'leader').

[WARNING] VAL-CAN-001 — Canonical entry 'factions/iron-covenant.md' references
  draft entry 'characters/elena-voss.md' via relationship 'allied_with'.
  Canonical entries should not reference draft content.

[INFORMATIONAL] VAL-SCH-007 — Field 'axiom_type' value 'METAPHYSICAL'
  normalized to 'metaphysical' (case-insensitive match).
  (File: axioms/principle-of-binding.md)

Summary: 2 errors, 2 warnings, 1 informational
✗ Validation failed. Fix errors before promotion.
```

**Example (filtered by type):**

```
$ chronicle validate --type faction --severity error

Chronicle Validation Report
============================
Filter: type=faction, severity≥error
Files:  12 faction files scanned

[ERROR] VAL-SCH-002 — Missing required field(s): canon. All entries must
  include type, name, and canon. (File: factions/shadow-conclave.md)

Summary: 1 error (warnings and informational messages filtered)
✗ Validation failed.
```

**Example (verbose with remediation hints):**

```
$ chronicle validate --verbose factions/shadow-conclave.md

Chronicle Validation Report
============================
File: factions/shadow-conclave.md

[ERROR] VAL-SCH-002 — Missing required field(s): canon. All entries must
  include type, name, and canon. (File: factions/shadow-conclave.md)

  Remediation: Add the missing required fields to the frontmatter:
    - type: The entity category (e.g., character, faction, locale, event)
    - name: A unique, descriptive name for the entity
    - canon: Canonical status (true, false, "apocryphal", or "deprecated")

  Source: D-10 §4.1, D-12 VAL-SCH-002

⚠ Tier 1 failed for this file. Tiers 2-3 skipped.

Summary: 1 error
```

**Example (deep validation with LLM):**

```
$ chronicle validate --deep

Chronicle Validation Report
============================
Files: 89 lore files scanned

Tier 1 — Schema Validation:     89 / 89 passed
Tier 2 — Structural Validation: 89 / 89 passed
Tier 3 — Semantic Validation:   89 / 89 passed

Deep Validation (LLM-Powered):
  Clusters analyzed: 12
  Contradictions found: 1
  Narrative tensions: 2

  ⚠ CONTRADICTION: factions/iron-covenant.md states the Covenant "never
    practiced magic" (body, paragraph 3), but events/arcane-purge.md
    describes "Iron Covenant ritualists channeling arcane energy" (body,
    paragraph 7). Review for consistency.

  ℹ TENSION: characters/elena-voss.md describes Voss as "distrustful of
    all institutional authority," but her relationship to the Iron Covenant
    is listed as type 'loyal_member'. This may be intentional character
    complexity or an oversight.

  ℹ TENSION: timeline/age-of-echoes.md places the Covenant's founding at
    "early Third Age," while factions/iron-covenant.md gives a specific
    date of "412 PG." These are compatible but readers may find the
    imprecision confusing.

Summary: 0 errors, 0 warnings, 0 informational (deterministic)
         1 contradiction, 2 tensions (deep)
✓ Deterministic checks passed. Review deep validation findings.
```

**Error Scenarios:**

| Scenario | Behavior |
|---|---|
| `.chronicle/` not found | Exit code 2. Message: `"No Chronicle repository found. Run 'chronicle init' first."` |
| `--deep` but no LLM endpoint configured | Exit code 4. Message: `"LLM endpoint not configured. Set 'llm.endpoint' in .chronicle/config.yaml or pass --llm-endpoint."` |
| `--deep` but LLM endpoint unreachable | Exit code 4. Message: `"Cannot reach LLM endpoint at {url}. Check configuration and connectivity."` |
| `--rule` with unrecognized rule ID | Exit code 2. Message: `"Unknown rule ID: '{id}'. See D-12 for valid rule IDs."` |
| Specified path does not exist | Exit code 2. Message: `"Path not found: '{path}'."` |

**Cross-References:**

- D-12 §3 — Validation tier architecture (cascade gating, tier sequencing)
- D-12 §4 — Rule definition format (error message structure)
- D-12 §5 — Tier 1 rules (VAL-SCH-001 through VAL-SCH-012)
- D-12 §6 — Tier 2 rules (VAL-REF-001 through VAL-REF-017)
- D-12 §7 — Tier 3 rules (VAL-CAN-001 through VAL-CAN-005, VAL-TMP-001/002, VAL-AXM-001/002, VAL-VOC-001)
- D-11 §9.1 — Apocryphal validation relaxation table
- D-11 §7.2 — Branch-canon consistency checks (VAL-REF-016, VAL-REF-017)
- D-14 — LLM prompt templates for `--deep` validation (Phase 4)

---

### 5.4. `chronicle promote`

```
Command:  chronicle promote
Synopsis: chronicle promote [<path>...] [options]
Phase:    2 — Core
```

**Description:** Promote one or more lore files from draft (`canon: false`) to canonical (`canon: true`). This command implements the Promotion Workflow defined in D-11 §5.1. It is the primary mechanism for introducing content into the official canon.

Promotion is a **medium-ceremony transition** (D-11 §4.4). It requires deterministic validation to pass, displays a promotion plan for user confirmation, modifies the `canon` field in the target file(s), generates an automatic commit, and creates changelog entries.

The command can also be used for the **Restoration Workflow** (D-11 §5.4) — restoring deprecated content to canonical status. In this case, it acts as a high-ceremony transition requiring `--deep` validation.

**Arguments:**

| Argument | Type | Required | Description |
|---|---|---|---|
| `<path>...` | `path` (repeatable) | No (if `--all`) | One or more paths to lore files to promote. Each file must currently have `canon: false` or `canon: "deprecated"`. If `--all` is used, no paths are required. |

**Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `--all` | `bool` | `false` | Promote all draft files (`canon: false`) in the repository (or in the directory specified by `--path`). Does NOT promote deprecated or apocryphal files — use explicit paths for those. |
| `--dry-run` | `bool` | `false` | Preview the promotion plan without applying any changes. Shows which files would be promoted, what validation results look like, and what changelog entries would be generated. No files are modified, no commits are made. |
| `--message <text>`, `-m <text>` | `string` | `null` | Attach a changelog note to the promotion entry. If not provided, Chronicle prompts interactively: `"Add a changelog note for this promotion? (y/n)"`. In non-interactive mode (piped input), omitting `-m` means no note is attached. |
| `--no-commit` | `bool` | `false` | Modify the `canon` field in the file(s) but do not create a Git commit. The user is responsible for staging and committing the changes. Useful for batching promotions with other changes into a single commit. |
| `--yes`, `-y` | `bool` | `false` | Skip the confirmation prompt and proceed with promotion. Use with caution — bypasses the "are you sure?" guard. Intended for scripted/CI workflows where the user has already reviewed the plan via `--dry-run`. |

**Exit Codes:** `0` (promotion succeeded), `1` (validation failed or user cancelled), `2` (config error), `3` (Git error).

**Behavior:**

1. Run an implicit scan to build the entity model.
2. Determine the promotion set:
   - If `<path>` arguments provided: validate that each file exists and has `canon: false` or `canon: "deprecated"`.
   - If `--all` specified: collect all files with `canon: false`.
   - If neither: exit with code 2 and usage help.
3. For each file in the promotion set, check current canon status:
   - `canon: false` → standard promotion (medium ceremony, D-11 §4.4).
   - `canon: "deprecated"` → restoration (high ceremony, D-11 §4.5). Chronicle warns: `"Restoring deprecated content requires full validation. Consider running with --deep."` If the file has a `superseded_by` reference, the confirmation prompt includes: `"You are restoring [name]. It was previously superseded by [replacement]. Continue?"`
   - `canon: "apocryphal"` → **error**. Message: `"Cannot promote apocryphal content directly. First convert to draft (canon: false), then promote. See D-11 §4.6."` Exit code 1.
   - `canon: true` → **warning**. Message: `"File is already canonical: {path}. Skipping."` Continue with other files.
4. Run deterministic validation (Tiers 1-3) on the promotion set. If any ERROR-severity rule fails, display the errors and exit with code 1.
5. If `--dry-run`: display the promotion plan (see example below) and exit with code 0.
6. Display the promotion plan and prompt for confirmation (unless `--yes`):
   ```
   Chronicle Promote
   =================
   Files to promote: N

     path/to/file1.md: false → true
     path/to/file2.md: false → true

   Proceed? (y/n):
   ```
7. If confirmed:
   a. For each file: rewrite the `canon` field from `false` to `true` in the YAML frontmatter. All other fields and the Markdown body are untouched.
   b. Update the `last_validated` field to today's date (ISO 8601).
   c. Generate changelog entries (D-11 §10.1):
      - Type: `"New Entry"` for draft → canonical.
      - Type: `"Restored"` for deprecated → canonical.
   d. If `-m` provided, attach the message to the changelog entry.
   e. If `-m` NOT provided and running interactively, prompt: `"Add a changelog note? (y/n)"`.
   f. Unless `--no-commit`: stage the modified files and create a Git commit with message `"Promote: {entity name(s)}"`.
8. Print summary:
   ```
   ✓ path/to/file.md promoted.
     Changelog: "New Entry: Faction — The Iron Covenant"

   Commit: a1b2c3d (Promote: Iron Covenant faction entry)
   ```

**Example (single file promotion):**

```
$ chronicle promote factions/iron-covenant.md

Chronicle Promote
=================
Validation: ✓ All checks passed.
Files to promote: 1

  factions/iron-covenant.md: false → true
    Entity: The Iron Covenant (faction)

Proceed? (y/n): y

Add a changelog note? (y/n): y
Note: Initial faction entry with founding narrative and military structure.

✓ factions/iron-covenant.md promoted.
  Changelog: "New Entry: Faction — The Iron Covenant"
  Note: "Initial faction entry with founding narrative and military structure."

Commit: a1b2c3d (Promote: Iron Covenant faction entry)
```

**Example (batch promotion with `--all`):**

```
$ chronicle promote --all

Chronicle Promote
=================
Validation: ✓ All checks passed.
Files to promote: 3

  factions/iron-covenant.md:     false → true  (The Iron Covenant)
  characters/elena-voss.md:      false → true  (Elena Voss)
  events/founding-covenant.md:   false → true  (The Founding of the Iron Covenant)

Proceed? (y/n): y

✓ 3 files promoted.
  Changelog: 3 "New Entry" records generated.

Commit: b2c3d4e (Promote: The Iron Covenant, Elena Voss, The Founding of the Iron Covenant)
```

**Example (dry run):**

```
$ chronicle promote --dry-run factions/iron-covenant.md

Chronicle Promote (Dry Run)
============================
Validation: ✓ All checks passed.
Files that would be promoted: 1

  factions/iron-covenant.md: false → true
    Entity: The Iron Covenant (faction)

No changes made. Remove --dry-run to execute.
```

**Example (validation failure):**

```
$ chronicle promote factions/shadow-conclave.md

Chronicle Promote
=================
Validation: ✗ 2 errors found.

[ERROR] VAL-SCH-002 — Missing required field(s): canon. All entries must
  include type, name, and canon. (File: factions/shadow-conclave.md)

[ERROR] VAL-REF-001 — Relationship target 'characters/unknown-agent.md'
  does not exist. (File: factions/shadow-conclave.md)

Promotion blocked. Fix errors and retry.
```

**Example (attempting to promote apocryphal content):**

```
$ chronicle promote factions/iron-covenant-alternate.md

[ERROR] Cannot promote apocryphal content directly. File
  'factions/iron-covenant-alternate.md' has canon: "apocryphal".

  Required path: First convert to draft (canon: false), then promote.
  See D-11 §4.6 for the two-step procedure.
```

**Example (restoring deprecated content):**

```
$ chronicle promote factions/iron-covenant-original.md

Chronicle Promote
=================
⚠ Restoration detected: factions/iron-covenant-original.md has canon: "deprecated".
  Restoring deprecated content requires full validation.
  Consider running with --deep for LLM-powered contradiction detection.

  You are restoring "The Iron Covenant (Original)" to canonical.
  It was previously superseded by "factions/iron-covenant-revised.md".

Validation: ✓ All checks passed (deterministic).

Proceed? (y/n): y

✓ factions/iron-covenant-original.md restored to canonical.
  Changelog: "Restored: Faction — The Iron Covenant (Original)"

Commit: c3d4e5f (Restore: The Iron Covenant (Original))
```

**Error Scenarios:**

| Scenario | Behavior |
|---|---|
| No files specified and `--all` not set | Exit code 2. Message: `"No files specified. Provide file paths or use --all."` |
| File does not exist | Exit code 2. Message: `"File not found: '{path}'."` |
| File is not a lore file (no frontmatter) | Exit code 2. Message: `"File '{path}' is not a lore file (no YAML frontmatter)."` |
| Validation fails | Exit code 1. Errors displayed. Message: `"Promotion blocked. Fix errors and retry."` |
| User cancels at confirmation | Exit code 1. Message: `"Promotion cancelled."` |
| Git commit fails | Exit code 3. Message: `"Git commit failed: {error}. Files were modified but not committed. Stage and commit manually."` |
| Not a Git repository and `--no-git` not set | Exit code 3. Message: `"Not a Git repository. Use --no-commit to promote without Git, or run 'git init' first."` |

**Cross-References:**

- D-11 §4.4 — Medium ceremony transition (draft → canonical) and its validation requirements
- D-11 §4.5 — High ceremony transition (deprecated → canonical) and its additional guards
- D-11 §4.6 — Prohibited direct transition (apocryphal → canonical)
- D-11 §5.1 — Promotion Workflow (step-by-step procedure)
- D-11 §5.4 — Restoration Workflow (deprecated → canonical)
- D-11 §10.1 — Automatic changelog entries generated by promotion
- D-11 §10.2 — Manual changelog notes attached during promotion
- D-12 — All validation rules executed as promotion gate

---

### 5.5. `chronicle log`

```
Command:  chronicle log
Synopsis: chronicle log <path> -m <message> [options]
Phase:    2 — Core
```

**Description:** Add a manual changelog entry to a lore file. This command allows authors to record editorial decisions, revision notes, and contextual annotations in the structured changelog without requiring a canon status transition. Manual entries appear alongside automatic entries in the changelog output.

The `chronicle log` command name was chosen as a placeholder in D-11 §10.2. It follows the Git convention of `git log` for history inspection, but with a `-m` flag for message creation (similar to `git commit -m`).

**Arguments:**

| Argument | Type | Required | Description |
|---|---|---|---|
| `<path>` | `path` | **Yes** | Path to the lore file to annotate. Must be a valid lore file with YAML frontmatter. |

**Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `-m <message>`, `--message <message>` | `string` | **Required** | The changelog note text. If not provided, Chronicle opens the user's `$EDITOR` for multi-line input (similar to `git commit` without `-m`). |

**Exit Codes:** `0` (entry recorded), `2` (config error — file not found, not a lore file).

**Behavior:**

1. Verify the target file exists and is a valid lore file.
2. Determine the changelog file path: `.chronicle/changelog/{relative-path}.changelog.yaml` (mirroring the lore file's directory structure).
3. Create the changelog directory structure if it doesn't exist.
4. Append a new entry to the changelog file:
   ```yaml
   - id: "{date}-{sequence}"
     type: "Manual Note"
     timestamp: "{ISO 8601 datetime}"
     author: "{git user.name or system user}"
     message: "{user-provided message}"
   ```
5. Print confirmation.

**Example:**

```
$ chronicle log factions/iron-covenant.md \
    -m "Revised founding date from 410 PG to 412 PG based on timeline reconciliation"

✓ Changelog entry recorded for "The Iron Covenant" (faction).
  Type: Manual Note
  Date: 2026-02-10T14:32:00Z
  Note: "Revised founding date from 410 PG to 412 PG based on timeline reconciliation"
```

**Error Scenarios:**

| Scenario | Behavior |
|---|---|
| File not found | Exit code 2. Message: `"File not found: '{path}'."` |
| File is not a lore file | Exit code 2. Message: `"File '{path}' is not a lore file (no YAML frontmatter)."` |
| No message provided and not interactive | Exit code 2. Message: `"No message provided. Use -m 'message' or run interactively."` |

**Cross-References:**

- D-11 §10.2 — Manual changelog entry semantics
- D-11 §10.3 — Changelog storage format and YAML structure
- D-11 §10.4 — What is NOT logged (this command logs anything the user wants)

---

### 5.6. `chronicle changelog`

```
Command:  chronicle changelog
Synopsis: chronicle changelog [<path>...] [options]
Phase:    2 — Core
```

**Description:** Generate a human-readable changelog for one or more entities, or for the entire repository. This command reads the structured changelog data from `.chronicle/changelog/` and renders it as Markdown output. It can also generate a diff-based changelog showing what has changed on the current branch compared to the canonical branch — useful for pre-merge review.

**Arguments:**

| Argument | Type | Required | Description |
|---|---|---|---|
| `<path>...` | `path` (repeatable) | No | One or more lore file paths to show changelogs for. If omitted, generates a repository-wide changelog covering all entities. |

**Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `--output <file>` | `path` | `null` (console) | Write the changelog to a Markdown file. |
| `--since <date>` | `string` (ISO 8601) | `null` (all entries) | Show only entries from the specified date onward. Format: `YYYY-MM-DD`. |
| `--diff` | `bool` | `false` | Generate a diff-based changelog: show what changed on the current branch compared to the canonical branch (configured in `config.yaml`, default `main`). Useful for pre-merge review. Requires Git. |
| `--type <entry-type>` | `string` (repeatable) | `null` (all types) | Filter by changelog entry type. Allowed values: `"New Entry"`, `"Deprecated"`, `"Revised"`, `"Restored"`, `"Retconned"`, `"Returned to Draft"`, `"Manual Note"`. |

**Exit Codes:** `0` (success), `2` (config error), `3` (Git error, only with `--diff`).

**Behavior:**

1. If `<path>` arguments provided: load changelog files for the specified entities.
2. If no arguments: load all changelog files from `.chronicle/changelog/`.
3. If `--diff`: compare current branch to canonical branch using Git, identify changed lore files, and generate changelog entries for those changes.
4. Apply filters (`--since`, `--type`).
5. Render as Markdown (see §8.2 for format).
6. Output to console or `--output` file.

**Example (single entity):**

```
$ chronicle changelog factions/iron-covenant.md

# Changelog: The Iron Covenant

## 2026-02-12 — Manual Note
> Faction relationships finalized. Ready for cross-reference integration.

## 2026-02-11 — Revised
Founded date updated from 410 PG to 412 PG. Reconciliation with Age of Echoes timeline.

## 2026-02-10 — New Entry
Promoted from Draft to Canonical.
  Note: "Initial faction entry with founding narrative and military structure."
```

**Example (branch diff):**

```
$ chronicle changelog --diff

# Changelog: feature/iron-covenant-update → main

## New Entries (2)
- **The Iron Covenant** (faction) — factions/iron-covenant.md
- **Elena Voss** (character) — characters/elena-voss.md

## Revised (1)
- **Age of Echoes** (timeline) — timeline/age-of-echoes.md
  Changed fields: start ("470 AE" → "480 AE")

## Deprecated (0)
## Manual Notes (1)
- **The Iron Covenant**: "Revised founding date from 410 PG to 412 PG"
```

**Cross-References:**

- D-11 §10.1 — Automatic changelog entry types and triggers
- D-11 §10.3 — Changelog storage and YAML format
- D-11 §10.4 — What is NOT logged

---

### 5.7. `chronicle graph`

```
Command:  chronicle graph
Synopsis: chronicle graph [options]
Phase:    2 — Core
```

**Description:** Generate a visualization of the entity relationship graph. Outputs the graph of all lore entities and their declared relationships in one of several formats suitable for rendering or programmatic consumption.

**Arguments:** None.

**Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `--format <fmt>` | `enum` | `mermaid` | Output format. Allowed values: `mermaid` (Mermaid diagram syntax for Markdown embedding), `dot` (DOT language for Graphviz rendering), `json` (structured JSON for programmatic consumption). |
| `--output <file>` | `path` | `null` (console) | Write graph output to a file. |
| `--type <type>` | `string` (repeatable) | `null` (all types) | Include only entities of the specified type(s). Useful for focusing the graph on a subset (e.g., only factions and characters). |
| `--canon <status>` | `enum` (repeatable) | `true` | Include only entities with the specified canon status(es). Default: canonical only. Use `--canon true --canon false` to include canonical and draft. Allowed values: `true`, `false`, `apocryphal`, `deprecated`. |
| `--depth <n>` | `int` | `null` (unlimited) | Maximum relationship traversal depth from the root entities. Useful for exploring the neighborhood of specific entities without graphing the entire repository. |
| `--root <path>` | `path` (repeatable) | `null` (all entities) | Start the graph from specific entity/entities and include only entities reachable within `--depth` hops. Without `--root`, all entities matching other filters are included. |

**Exit Codes:** `0` (success), `2` (config error).

**Behavior:**

1. Run an implicit scan to build the entity model.
2. Filter entities by `--type`, `--canon`, `--root`, and `--depth`.
3. Render the filtered entity graph in the specified `--format`.
4. Output to console or `--output` file.

**Example (Mermaid output):**

```
$ chronicle graph --type faction --type character

graph LR
  iron_covenant["The Iron Covenant<br/>(faction)"]
  elena_voss["Elena Voss<br/>(character)"]
  shadow_conclave["The Shadow Conclave<br/>(faction)"]
  marcus_thane["Marcus Thane<br/>(character)"]

  elena_voss -->|leader| iron_covenant
  marcus_thane -->|member| iron_covenant
  iron_covenant -->|rival| shadow_conclave
  elena_voss -->|enemy| shadow_conclave
```

**Example (JSON output):**

```
$ chronicle graph --format json --root factions/iron-covenant.md --depth 1

{
  "nodes": [
    {"id": "factions/iron-covenant.md", "name": "The Iron Covenant", "type": "faction", "canon": true},
    {"id": "characters/elena-voss.md", "name": "Elena Voss", "type": "character", "canon": true},
    {"id": "characters/marcus-thane.md", "name": "Marcus Thane", "type": "character", "canon": false},
    {"id": "factions/shadow-conclave.md", "name": "The Shadow Conclave", "type": "faction", "canon": true}
  ],
  "edges": [
    {"source": "characters/elena-voss.md", "target": "factions/iron-covenant.md", "type": "leader"},
    {"source": "characters/marcus-thane.md", "target": "factions/iron-covenant.md", "type": "member"},
    {"source": "factions/iron-covenant.md", "target": "factions/shadow-conclave.md", "type": "rival"}
  ]
}
```

**Cross-References:**

- D-10 §7 — Relationship block structure (the data source for graph edges)
- D-10 §7.2 — Recommended relationship type vocabulary (edge labels)
- D-10 §7.4 — Bidirectional relationship inference (reverse edges)

---

### 5.8. `chronicle status`

```
Command:  chronicle status
Synopsis: chronicle status [options]
Phase:    2 — Core
```

**Description:** Display a summary of the current repository state, similar in spirit to `git status` but focused on Chronicle's domain concepts. Shows entity counts by type and canon status, pending promotions (draft files on the current branch), recently modified files, and any validation issues detected in a quick scan.

This command is designed for daily workflow use — a quick check before diving into edits, promotions, or merges.

**Arguments:** None.

**Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `--full` | `bool` | `false` | Run a complete validation scan and include the summary in the status output. Without `--full`, status runs a lightweight check (schema-only, no cross-reference or semantic validation). |

**Exit Codes:** `0` (success), `2` (config error).

**Behavior:**

1. Run an implicit scan.
2. Display repository summary: entity counts by type and canon status.
3. If in a Git repository: show current branch and how it maps to Chronicle's branch conventions (D-11 §7.1).
4. Identify "actionable" items:
   - Draft files on `main` (should be promoted or moved to a feature branch).
   - Deprecated files without `superseded_by` references (orphaned deprecations).
   - Recently modified files (since last validation).
5. If `--full`: run full validation and append a summary (error/warning/info counts).

**Example:**

```
$ chronicle status

Chronicle Status
================
Repository: /home/ryan/aethelgard
Branch:     feature/iron-covenant-update (feature branch)

Entity Summary:
  89 lore files (52 canonical, 29 draft, 5 apocryphal, 3 deprecated)
  12 entity types in use (0 custom)
  214 relationships (16 unresolved)

Actionable Items:
  ⚡ 3 draft files ready for review on this branch:
     factions/iron-covenant.md
     characters/elena-voss.md
     events/founding-covenant.md

  ⚠ 1 deprecated file without replacement reference:
     locales/old-thornhaven.md

Last validation: 2026-02-09 (1 day ago)
Run 'chronicle validate' for a fresh check.
```

**Cross-References:**

- D-11 §7.1 — Branch conventions (displayed in status header)
- D-11 §9.1 — Apocryphal relaxation (status notes when on apocryphal branches)
- D-10 §4.6 — `superseded_by` field (orphaned deprecation detection)

---

## 6. Phase 3 Commands (Integration)

These commands integrate Chronicle with FractalRecall for embedding-based operations. They are **preliminary specifications** — behavioral details will be refined after Track B Colab prototyping results (D-23 go/no-go decision) and D-15 (Integration Design Document) are complete.

**Prerequisites:** Phase 3 commands require a configured FractalRecall backend (embedding model, vector store). Configuration is managed in `.chronicle/config.yaml` under the `fractalrecall` section (see §9.2).

---

### 6.1. `chronicle index`

```
Command:  chronicle index
Synopsis: chronicle index [options]
Phase:    3 — Integration (Preliminary Specification)
```

**Description:** Build or rebuild the FractalRecall embedding index from the current repository state. Processes all lore files, extracts frontmatter metadata, constructs composite representations using FractalRecall's context layer system, generates embeddings via the configured embedding model, and stores them in the vector index.

This command is the bridge between Chronicle's domain model and FractalRecall's retrieval capabilities. It translates YAML frontmatter fields into FractalRecall context layers (the mapping defined in D-15) and delegates embedding generation and storage to FractalRecall's API.

**Arguments:** None.

**Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `--incremental` | `bool` | `false` | Update only files that have changed since the last indexing run. Uses structural fingerprint comparison to detect changes (see FractalRecall Conceptual Architecture, D-02 §8). Without this flag, the full index is rebuilt from scratch. |
| `--canon <status>` | `enum` (repeatable) | `true` | Index only entities with the specified canon status(es). Default: canonical only. Apocryphal and draft content can be indexed for search but are excluded by default to keep the primary index focused. |
| `--dry-run` | `bool` | `false` | Preview what would be indexed without actually generating embeddings. Shows file count, estimated token count, and layer configuration. |

**Exit Codes:** `0` (success), `2` (config error), `4` (LLM/embedding error — model unreachable).

**Example (preliminary):**

```
$ chronicle index

Chronicle Index
===============
Files to index: 52 (canonical)
Embedding model: nomic-embed-text-v2-moe (via Ollama)
Context layers: 8 (Corpus, Domain, Entity, Authority, Temporal, Relational, Section, Content)
Vector store: .chronicle/index/fractal.db (SQLite-vec)

Processing: ████████████████████████████████ 52/52

Index built successfully.
  Chunks generated: 347
  Embeddings stored: 347
  Index size: 12.4 MB
  Duration: 2m 14s
```

**Cross-References:**

- D-02 §6 — Context layer definitions (Corpus, Domain, Entity, Authority, Temporal, Relational, Section, Content)
- D-02 §8 — Structural fingerprint for incremental indexing
- D-15 — Frontmatter-to-layer mapping (blocked on Track B results)
- D-04 §9.2 — Phase 3 integration strategy

---

### 6.2. `chronicle search`

```
Command:  chronicle search
Synopsis: chronicle search <query> [options]
Phase:    3 — Integration (Preliminary Specification)
```

**Description:** Perform a semantic search across the lore corpus using FractalRecall's context-aware embedding retrieval. Chronicle constructs an enriched query with layer constraints based on the user's filters, delegates the search to FractalRecall, and formats the results for CLI display.

**Arguments:**

| Argument | Type | Required | Description |
|---|---|---|---|
| `<query>` | `string` | **Yes** | Natural language search query. FractalRecall enriches this with context layer constraints before embedding and searching. |

**Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `--top <n>` | `int` | `10` | Number of results to return. |
| `--canon-only` | `bool` | `true` | Include only canonical content in results. This is the default; use `--include-draft`, `--include-apocrypha`, or `--include-deprecated` to expand scope. |
| `--include-draft` | `bool` | `false` | Include draft (`canon: false`) content in search results. Draft results are labeled `[DRAFT]` in output. |
| `--include-apocrypha` | `bool` | `false` | Include apocryphal (`canon: "apocryphal"`) content in results. Apocryphal results are labeled `[APOCRYPHAL]` in output. |
| `--include-deprecated` | `bool` | `false` | Include deprecated (`canon: "deprecated"`) content in results. Deprecated results are labeled `[DEPRECATED]` and include the `superseded_by` reference. |
| `--era <era>` | `string` | `null` | Filter results to entities associated with the specified era. The era name must match a `timeline` entity's `name` field. |
| `--type <type>` | `string` (repeatable) | `null` (all) | Filter by entity type. |
| `--region <region>` | `string` | `null` | Filter by region (matches the `region` common field). |
| `--format <fmt>` | `enum` | `summary` | Output format. `summary` (default: file path, entity name, score, excerpt), `detail` (full metadata and layer score breakdown), `json` (structured JSON for programmatic consumption). |

**Exit Codes:** `0` (results found or empty results), `2` (config error — index not built), `4` (embedding error).

**Example (preliminary):**

```
$ chronicle search "What factions have a presence in the northern territories?"

Chronicle Search Results
========================
Query: "What factions have a presence in the northern territories?"
Results: 5 of 52 canonical entries (top 10 requested)

1. [0.87] The Iron Covenant (faction)
   factions/iron-covenant.md
   "A militaristic faction controlling the northern border regions..."
   Region: Northern Reaches | Era: Third Age

2. [0.82] The Shadow Conclave (faction)
   factions/shadow-conclave.md
   "Operating from hidden enclaves in the northern wilderness..."
   Region: Northern Reaches | Era: Third Age

3. [0.74] The Ashenmoor Wardens (faction)
   factions/ashenmoor-wardens.md
   "Rangers and scouts who patrol the northern frontier..."
   Region: Ashenmoor | Era: Third Age

4. [0.68] The Siege of Thornhaven (event)
   events/siege-thornhaven.md
   "The Iron Covenant's assault on the northern fortress..."
   Region: Northern Reaches | Era: Third Age, Year 412

5. [0.61] Thornhaven (locale)
   locales/thornhaven.md
   "A fortified city at the northern boundary of the Ashenmoor region..."
   Region: Northern Reaches
```

**Cross-References:**

- D-02 §5.2–5.3 — FractalRecall query pipeline and data flow
- D-10 §4.2 — Canon field values (used for status filtering)
- D-10 §4.3 — `era` field (used for `--era` filtering)
- D-10 §4.4 — `region` field (used for `--region` filtering)
- D-11 §3.1 — Canon status search inclusion rules (default excludes draft, apocryphal, deprecated)
- D-15 — Query enrichment and layer weight configuration (blocked on Track B results)

---

## 7. Phase 4 Commands (LLM-Powered)

These commands require a configured LLM endpoint for text generation and analysis. They are **preliminary specifications** — prompt templates, response schemas, and report formats will be fully defined in D-14 (LLM Integration Specification).

**Prerequisites:** Phase 4 commands require a configured LLM endpoint in `.chronicle/config.yaml` (see §9.2). Local inference via Ollama or LM Studio is the primary target; cloud APIs (OpenAI-compatible, Anthropic) are supported as alternatives.

---

### 7.1. `chronicle suggest`

```
Command:  chronicle suggest
Synopsis: chronicle suggest [options]
Phase:    4 — LLM-Powered (Preliminary Specification)
```

**Description:** Run the LLM-powered lore expansion analysis. Scans the repository for gaps in the worldbuilding corpus and generates a structured suggestion report. Gaps include: entities with few or no relationships, sparsely documented regions, referenced-but-undefined entities, entity types with low coverage, and narrative threads that appear to trail off.

**Arguments:** None.

**Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `--output <file>` | `path` | `null` (console) | Write the suggestion report to a Markdown file. |
| `--scope <scope>` | `enum` | `full` | Scope of analysis. `full` (entire repository), `local` (only entities connected to recently modified files). |
| `--type <type>` | `string` (repeatable) | `null` (all) | Limit suggestions to specific entity types. |

**Exit Codes:** `0` (success), `2` (config error), `4` (LLM error).

**Example (preliminary):**

```
$ chronicle suggest --output suggestions.md

Chronicle Suggestion Report
============================
Analyzing 89 lore files across 12 entity types...

Structural Gaps:
  ⚡ 3 referenced-but-undefined entities:
     - "characters/marcus-thane.md" (referenced by 4 files)
     - "locales/deep-reaches.md" (referenced by 2 files)
     - "events/battle-of-ashenmoor.md" (referenced by 1 file)

  ⚡ 2 entities with no outbound relationships:
     - axioms/temporal-anchor.md (The Temporal Anchor)
     - terms/glitch-event.md (The Glitch)

Narrative Suggestions (LLM):
  💡 The Iron Covenant has extensive military documentation but no
     cultural or religious practices described. Consider adding a
     system or document entry exploring their belief system.

  💡 Elena Voss has relationships to 6 factions but no family
     relationships. Is she orphaned? Estranged? This gap may be
     intentional but could enrich the narrative.

Report written to: suggestions.md
```

**Cross-References:**

- D-01 §4.7 — `chronicle suggest` original command proposal
- D-14 — Prompt templates and response parsing for suggestion generation (to be written)

---

### 7.2. `chronicle stub`

```
Command:  chronicle stub
Synopsis: chronicle stub <path> [options]
Phase:    4 — LLM-Powered (Preliminary Specification)
```

**Description:** Generate a draft stub document for a referenced-but-undefined entity. Uses the LLM to infer initial content from existing references to the entity across the corpus. The stub is created with `canon: false` and clearly marked as machine-generated in both the frontmatter and the Markdown body.

**Arguments:**

| Argument | Type | Required | Description |
|---|---|---|---|
| `<path>` | `path` | **Yes** | The file path where the stub should be created. Should follow the repository's directory conventions (e.g., `characters/marcus-thane.md`). The entity type is inferred from the directory name or can be specified with `--type`. |

**Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `--type <type>` | `string` | Inferred from path | The entity type for the stub. If not specified, Chronicle infers it from the directory name (e.g., `characters/` → `character`). If the directory doesn't match a known type, this option is required. |
| `--dry-run` | `bool` | `false` | Preview the stub content without creating the file. |

**Exit Codes:** `0` (stub created), `1` (file already exists), `2` (config error), `4` (LLM error).

**Example (preliminary):**

```
$ chronicle stub characters/marcus-thane.md

Chronicle Stub Generator
========================
Entity: Marcus Thane (character)
References found: 4 files reference this entity
  - factions/iron-covenant.md (relationship: member)
  - events/founding-covenant.md (body reference)
  - characters/elena-voss.md (relationship: ally)
  - locales/thornhaven.md (body reference)

Generating stub from context...

✓ Stub created: characters/marcus-thane.md
  Type: character
  Canon: false (draft)
  Status: ⚠ Machine-generated stub. Review and revise before promotion.

Preview:
---
type: character
name: Marcus Thane
canon: false
summary: "[STUB] A member of the Iron Covenant and ally of Elena Voss,
  associated with the founding events and the Thornhaven region."
tags: [stub, machine-generated]
relationships:
  - target: factions/iron-covenant.md
    type: member
  - target: characters/elena-voss.md
    type: ally
---

> **⚠ Machine-Generated Stub** — This entry was generated by Chronicle
> from existing references. Review, revise, and promote when ready.

# Marcus Thane
[Content to be written]
```

**Cross-References:**

- D-01 §4.7 — `chronicle stub` original command proposal
- D-14 — Prompt templates for stub generation and reference extraction (to be written)
- D-12 VAL-REF-001 — Cross-reference integrity (stubs resolve broken references)

---

## 8. Output Formats

This section defines the standardized output formats used across multiple commands. Consistent formatting ensures predictable parsing by scripts and CI/CD pipelines.

### 8.1. Validation Report Format

The validation report produced by `chronicle validate` follows this structure:

```
Chronicle Validation Report
============================
Repository: {absolute path}
Branch:     {current branch} ({branch convention label})
Files:      {N} lore files scanned
Filter:     {active filters, if any}

Tier 1 — Schema Validation:     {passed} / {total} passed {(N files gated)}
Tier 2 — Structural Validation: {passed} / {total} passed
Tier 3 — Semantic Validation:   {passed} / {total} passed

Results:

{messages sorted by severity (ERROR first, then WARNING, then INFORMATIONAL)}

[SEVERITY] RULE-ID — Message. (File: path/to/file.md)

Summary: {N} errors, {N} warnings, {N} informational
✓ All checks passed. | ✗ Validation failed. Fix errors before promotion.
```

**When `--verbose` is active:** Each message is followed by a remediation block:
```
  Remediation: {step-by-step fix guidance}
  Source: {D-10/D-11/D-12 section reference}
```

**When `--output <file>` is active:** The same content is written as Markdown with headers, code blocks, and proper formatting.

### 8.2. Changelog Output Format

Changelogs are rendered in reverse chronological order:

```markdown
# Changelog: {Entity Name}

## {Date} — {Entry Type}
{Message or description}

## {Date} — {Entry Type}
{Message or description}
```

Entry types: `New Entry`, `Deprecated`, `Revised`, `Restored`, `Retconned`, `Returned to Draft`, `Manual Note`.

For repository-wide changelogs, entries are grouped by entity with the most recent activity first.

### 8.3. Graph Output Formats

**Mermaid:** Standard Mermaid `graph LR` syntax with entity labels including name and type. Edge labels are relationship types.

**DOT:** Standard Graphviz DOT language. Nodes have `label` and `shape` attributes. Edges have `label` attributes.

**JSON:** Structured JSON with `nodes` array (objects with `id`, `name`, `type`, `canon`) and `edges` array (objects with `source`, `target`, `type`).

### 8.4. Search Result Format

**Summary format (default):**
```
{rank}. [{score}] {Entity Name} ({entity type})
   {file path}
   "{excerpt from matched content...}"
   Region: {region} | Era: {era}
```

**Detail format:** Adds layer score breakdown, full frontmatter metadata, and relationship list.

**JSON format:** Structured JSON array of result objects with all metadata fields.

---

## 9. Configuration Reference

### 9.1. Configuration File Location

Chronicle's configuration lives in `.chronicle/config.yaml`, created by `chronicle init`. The file follows YAML 1.2 syntax.

The `--config <path>` global option overrides this location. If the specified config file does not exist, Chronicle exits with code 2.

### 9.2. Configuration Sections

```yaml
# .chronicle/config.yaml — Complete Reference
# =============================================

# Chronicle tool version that created this config
chronicle_version: "1.0.0"

# --- Branch Conventions (D-11 §7.3) ---
branch_conventions:
  # Branch that represents canonical, production-ready content
  canonical_branch: "main"
  # Pattern for apocryphal content branches (supports glob wildcards)
  apocryphal_pattern: "apocrypha/*"

# --- Validation Defaults ---
validation:
  # Default minimum severity for report output (overridden by --severity)
  default_severity: "warning"

# --- Changelog Settings (D-11 §10) ---
changelog:
  # Whether to auto-generate changelog entries on promotion/deprecation
  auto_generate: true

# --- LLM Configuration (Phase 4) ---
# Uncomment and configure when using --deep validation, suggest, or stub.
# llm:
#   endpoint: "http://localhost:11434"  # Ollama default
#   model: "llama3.2:70b"              # Model name for text generation
#   timeout: 120                        # Request timeout in seconds

# --- FractalRecall Configuration (Phase 3) ---
# Uncomment and configure when using index or search commands.
# fractalrecall:
#   embedding_model: "nomic-embed-text-v2-moe"
#   embedding_endpoint: "http://localhost:11434"  # Ollama for embeddings
#   vector_store: "sqlite-vec"                     # or "qdrant"
#   vector_store_path: ".chronicle/index/fractal.db"
#   context_layers:                                 # Layer weights (0.0-1.0)
#     corpus: 0.3
#     domain: 0.5
#     entity: 0.8
#     authority: 0.7
#     temporal: 0.6
#     relational: 0.6
#     section: 0.4
#     content: 1.0
```

---

## 10. Cross-Reference Index

### 10.1. Commands to D-12 Validation Rules

This table maps each command to the D-12 validation rules it invokes or is affected by. D-12 defines 37 rules across three tiers (12 Schema + 15 Structural + 10 Semantic). Rules use six category prefixes: `VAL-SCH` (schema), `VAL-REF` (cross-reference, superseding, multi-file entity, uniqueness, and branch convention rules), `VAL-CAN` (canon consistency), `VAL-TMP` (temporal), `VAL-AXM` (axiom enforcement), and `VAL-VOC` (vocabulary). See D-12 §2 for the complete rule ID format and §3 for the tier architecture.

| Command | D-12 Rules Invoked | Tiers | Notes |
|---|---|---|---|
| `chronicle validate` | All rules | 1, 2, 3 | Core validation command. Executes all rules across all three tiers. Filterable by `--tier` and `--rule` options. |
| `chronicle validate --deep` | All rules + LLM checks | 1, 2, 3, Deep | Extends deterministic validation with LLM-powered semantic analysis (D-14). |
| `chronicle promote` | All rules (as validation gate) | 1, 2, 3 | Promotion requires all deterministic validation rules to pass. Validation is run implicitly before the promotion plan is displayed. |
| `chronicle scan` | None directly | — | Scan does not validate; it builds the entity model. Parse errors are noted but not surfaced as validation failures. |
| `chronicle status` | Tier 1 rules only (unless `--full`) | 1 (or 1, 2, 3) | Lightweight schema check by default; `--full` runs all tiers. |
| `chronicle init` | None | — | Creates the schema files that validation rules reference. |

**D-12 Rule Category Quick Reference:**

| Prefix | Category | Tier | Count | Example Rules |
|---|---|---|---|---|
| `VAL-SCH` | Schema Validation | 1 | 12 | Frontmatter parseable, required fields, data types, enum values, relationship structure |
| `VAL-REF` | Structural Validation | 2 | 17* | Reference targets exist, bidirectional consistency, supersession chains, uniqueness, branch conventions |
| `VAL-CAN` | Canon Consistency | 3 | 5 | Canonical references draft/apocryphal/deprecated content, hierarchy, promotion checks |
| `VAL-TMP` | Temporal Validation | 3 | 2 | Timeline era boundary order, relationship temporal order |
| `VAL-AXM` | Axiom Enforcement | 3 | 2 | Hard axiom deterministic enforcement, soft axiom LLM flag |
| `VAL-VOC` | Vocabulary | 3 | 1 | Relationship type vocabulary notice |

*\*Note: D-12 §3 states 15 Structural (Tier 2) rules in the summary table, but the rule catalog defines 17 `VAL-REF-*` rules (VAL-REF-001 through VAL-REF-017). This may reflect a summary table count that predates final rule additions. D-13 references the full catalog as authoritative. See D-12 for reconciliation.*

### 10.2. Commands to D-11 Workflows

**CLI-Driven Workflows:**

| Command | D-11 Workflow | Ceremony | D-11 Sections |
|---|---|---|---|
| `chronicle promote` | Promotion (draft → canonical) | Medium | §4.4, §5.1 |
| `chronicle promote` | Restoration (deprecated → canonical) | High | §4.5, §5.4 |
| `chronicle validate` | Branch convention enforcement | — | §7.2 (VAL-REF-016, VAL-REF-017) |
| `chronicle validate --deep` | Deep validation (LLM-powered) | High | §4.5 (recommended for deprecation and restoration) |
| `chronicle log` | Manual changelog entry | — | §10.2 |
| `chronicle changelog` | Changelog rendering | — | §10.1, §10.3 |

**Manual Operations (field edit + `chronicle validate`):**

| Workflow | Ceremony | D-11 Section | Procedure |
|---|---|---|---|
| Deprecation (canonical → deprecated) | High | §4.5, §5.2 | Edit `canon` to `"deprecated"`, set `superseded_by`, run `validate --deep` |
| Retconning (canonical → apocryphal) | Medium | §4.4, §5.6 | Edit `canon` to `"apocryphal"`, run `validate` |
| Re-Drafting (canonical → draft) | Medium | §4.4, §5.5 | Edit `canon` to `false` on a feature branch, run `validate` |
| Apocryphal creation (draft → apocryphal) | Low | §4.3, §5.3 | Edit `canon` to `"apocryphal"` |
| Draft revival (deprecated → draft) | Low | §4.3 | Edit `canon` to `false` |
| Apocryphal ↔ deprecated reclassification | Low | §4.3 | Edit `canon` field |

**Prohibited Transition:**

| Transition | D-11 Section | Enforcement |
|---|---|---|
| Apocryphal → canonical (direct) | §4.6 | `chronicle promote` rejects with error. Must go through draft first. |

### 10.3. Commands to D-10 Schema Elements

| Command | D-10 Schema Elements Used | D-10 Sections |
|---|---|---|
| `chronicle init` | Creates all schema files | §3.2 (schema file structure) |
| `chronicle scan` | Parses all frontmatter fields, builds relationship graph, infers `supersedes` | §3.1 (file structure), §3.3 (schema discovery), §4 (common fields), §5 (entity types), §7 (relationships), §4.8 (superseding) |
| `chronicle validate` | Validates against all schema constraints | §4 (common fields), §5 (type-specific fields), §6 (data types), §7 (relationships), §8 (extensibility) |
| `chronicle promote` | Modifies `canon` field, updates `last_validated` | §4.2 (`canon` field), §4.6 (`last_validated` field) |
| `chronicle graph` | Reads `relationships` block for graph edges | §7 (relationship structure) |
| `chronicle search` | Filters by `canon`, `era`, `region`, `type` | §4.2, §4.3, §4.4, §4.1 |
| `chronicle index` | Maps frontmatter fields to FractalRecall context layers | §13 (FractalRecall context layer mapping) |

---

## 11. Dependencies and Cross-References

| Document | Relationship to D-13 | Key Sections |
|---|---|---|
| **D-01** (Design Proposal) | D-13 formalizes the CLI command surface proposed in D-01 §4.7. | §4.7 (CLI Command Surface) |
| **D-10** (Lore File Schema) | D-13 commands operate on the data model defined in D-10. Schema files are created by `init`, parsed by `scan`, validated by `validate`, and filtered by `search`. | §3 (Schema Architecture), §4 (Common Fields), §5 (Entity Types), §7 (Relationships), §8 (Extensibility) |
| **D-11** (Canon Workflow) | D-13 commands implement the workflows defined in D-11. `promote` implements promotion and restoration workflows. `validate` enforces branch conventions. `log` and `changelog` implement changelog management. | §4 (State Machine), §5 (Workflows), §7 (Branch Conventions), §10 (Changelog Integration) |
| **D-12** (Validation Rules) | D-13's `validate` and `promote` commands execute the 37 rules cataloged in D-12. Error messages, severity levels, and cascade gating behavior are defined in D-12. | §3 (Tier Architecture), §5–§7 (All Rules) |
| **D-14** (LLM Integration) | D-13's `--deep`, `suggest`, and `stub` commands will use prompt templates and response parsing defined in D-14. | To be written. |
| **D-15** (Integration Design) | D-13's `index` and `search` commands depend on the frontmatter-to-layer mapping and query enrichment strategy defined in D-15. | Blocked on Track B results. |
| **D-02** (FractalRecall Architecture) | D-13's `index` and `search` commands delegate to FractalRecall's API as specified in D-02. | §5 (Data Flow), §6 (Context Layers), §8 (Structural Fingerprint) |

---

## 12. Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1.0-draft | 2026-02-10 | Ryan + Claude | Initial CLI Command Reference. 8 Phase 2 commands (init, scan, validate, promote, log, changelog, graph, status) at full specification depth. 2 Phase 3 commands (index, search) and 2 Phase 4 commands (suggest, stub) at preliminary specification depth. Global options, exit code reference, output format specifications, configuration reference, and cross-reference index. |

---

*This document specifies Chronicle's complete CLI interface. D-10 defines the data model. D-11 defines the workflows. D-12 defines the validation rules. D-13 defines how users interact with all of it. Together, D-10 through D-13 form the complete Phase 1 specification suite for Chronicle implementation.*
