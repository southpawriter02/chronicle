# D-11 Design Decisions: Canon Workflow Specification

**Date:** 2026-02-10
**Status:** Locked — Ready for D-11 Drafting
**Participants:** Ryan + Claude
**Context:** These decisions were made during pre-draft scoping for D-11. Each resolves an open design question identified during the scope analysis of upstream documents (D-01 §4.4, D-04 §6.3, D-10 §4.2).

---

## OQ-D11-1: State Machine — Valid Transitions and Ceremony Tiers

**Decision:** All twelve transitions between the four canon states are allowed, but with varying levels of ceremony based on risk.

**Three ceremony tiers:**

### Low Ceremony (just change the field)

No special validation beyond standard schema checks. The author edits the `canon` field directly.

| Transition | Use Case |
|---|---|
| `false → "apocryphal"` | Author reclassifies a draft as a what-if exploration |
| `"apocryphal" → false` | Author converts an exploration into a proper draft |
| `false → "deprecated"` | Author abandons a draft in favor of a different approach |
| `"apocryphal" → "deprecated"` | Author supersedes an old what-if with a newer one |
| `"deprecated" → false` | Author revives deprecated content as a new draft |
| `"deprecated" → "apocryphal"` | Author reclassifies deprecated content as alternate-history material |

### Medium Ceremony (requires passing deterministic validation)

The transition requires `chronicle validate` to pass (deterministic checks only). Some transitions have additional conditions.

| Transition | Use Case | Additional Conditions |
|---|---|---|
| `false → true` | Standard promotion to canonical | Must pass deterministic validation. Executed via `chronicle promote`. |
| `true → false` | Re-drafting canonical content for rework | Only on non-`main` branch. Author checks out canonical content, changes to draft, edits, then re-promotes via normal workflow. |
| `true → "apocryphal"` | Retcon — removing content from canon but preserving as what-if | Explicit confirmation recommended (significant editorial event). |

### High Ceremony (requires full validation including deep/LLM checks)

The transition requires both deterministic and LLM-powered validation to pass. These transitions carry the highest risk of introducing inconsistencies.

| Transition | Use Case | Additional Conditions |
|---|---|---|
| `true → "deprecated"` | Superseding canonical content | Must set `superseded_by` to a valid replacement file. |
| `"deprecated" → true` | Un-deprecating — restoring previously superseded content | Full deep validation required (content may have drifted out of consistency while deprecated). Explicit author confirmation required. |

### Prohibited Direct Transition

| Transition | Reason | Required Path |
|---|---|---|
| `"apocryphal" → true` | Apocryphal content is explicitly allowed to contradict canon. Direct promotion risks introducing contradictions. | Must go `"apocryphal" → false → true` (forces a draft review stage). |

---

## OQ-D11-2: Promotion Mechanism

**Decision:** Explicit CLI command, no Git hooks for v1.

- `chronicle promote` scans the current branch for files with `canon: false`, validates them, updates them to `canon: true`, commits the changes, and generates changelog entries.
- `--dry-run` flag for previewing what would be promoted without making changes.
- `chronicle validate` on `main` catches forgotten promotions: warning "draft content detected on `main` — run `chronicle promote`."
- No Git hook dependency. Optional hook support noted as potential future enhancement.

**Rationale:** Transparency and user control over automation. Chronicle is a CLI tool for individual worldbuilders — explicit commands keep the workflow visible and debuggable. The validator serves as the safety net for forgotten promotions.

---

## OQ-D11-3: Apocryphal Validation Relaxation

**Decision:** Structural integrity always enforced; narrative correctness is not.

| Check Category | Canonical / Draft | Apocryphal |
|---|---|---|
| Schema validation (required fields, types, enums) | Error | **Error** (still enforced) |
| Cross-reference integrity (targets exist) | Error | **Warning** (relaxed) |
| Timeline consistency (dates within era bounds) | Warning | **Skipped** |
| Axiom enforcement — hard | Error | **Skipped** |
| Axiom enforcement — soft | Warning | **Skipped** |
| Canon consistency (canonical → draft/apocryphal refs) | Warning | **No change** (rule applies to canonical side) |
| Uniqueness constraints (duplicate names, alias collisions) | Warning | **Informational** (relaxed) |

**Rationale:** Apocryphal content exists to explore contradictions, alternate timelines, and incomplete ideas. Over-validating defeats its purpose. But it must still be a parseable lore file (schema valid) so Chronicle can index and search it.

---

## OQ-D11-4: Branch Naming Conventions

**Decision:** Soft enforcement via warnings, configurable conventions.

- On `main`: files with `canon: false` trigger warning ("draft content detected — run `chronicle promote`").
- On `apocrypha/*` branches: files with non-apocryphal statuses trigger informational notice.
- On any other branch: no branch-specific checks.
- Non-Git directories: branch checks skipped silently.
- Branch conventions are configurable via `branch_conventions` section in `.chronicle/config.yaml`.
- Defaults: `main` for canonical, `apocrypha/*` for apocryphal.

**Rationale:** Catches the most common workflow mistake (forgetting to promote after merge) without blocking legitimate workflows. Gracefully degrades if Git isn't present.

---

## OQ-D11-5: Merge Conflict Resolution

**Decision:** Documentation and validation only — no custom merge tooling for v1.

- Standard Git conflict resolution applies.
- D-11 documents explicit resolution guidance for each conflict scenario:
  - **Scenario A:** Feature branch `false` vs. `main` `true` → resolve to `true` on `main` (or leave as `false` and run `chronicle promote`).
  - **Scenario B:** Content merge with canon field conflict → accept content changes, let `chronicle promote` handle status.
  - **Scenario C:** Apocryphal branch referencing deprecated canonical content → allowed, no special handling.
  - **Scenario D:** Mixed canon statuses on a single branch merged to `main` → each file's status handled independently by `chronicle promote`.
- `chronicle validate` catches post-merge inconsistencies via branch convention warnings (OQ-D11-4).
- Custom Git merge driver noted as potential future enhancement.

**Rationale:** Consistent with the transparency-over-automation philosophy. The validator is the safety net. Custom merge drivers are powerful but add complexity premature for v1.

---

## OQ-D11-6: Changelog Triggers

**Decision:** Automatic entries for transitions into/out of canonical status. Manual entries via CLI for author-judged significant content changes.

### Automatic Changelog Entries

| Transition | Entry Type |
|---|---|
| `false → true` | "New Entry" |
| `true → "deprecated"` | "Deprecated" |
| `true → false` | "Returned to Draft" |
| `true → "apocryphal"` | "Retconned" |
| `"deprecated" → true` | "Restored" |
| Canonical frontmatter fields modified | "Revised" |

### Manual Changelog Entries

- CLI command (verb TBD in D-13, e.g., `chronicle log`) allows the author to add a changelog note with a message, similar to `git commit -m`.
- Example: `chronicle log "factions/iron-covenant.md" -m "Revised founding date from 410 PG to 412 PG based on timeline reconciliation"`
- `chronicle promote` optionally prompts the author for a changelog note during promotion.

### Not Logged

- Transitions between non-canonical states (`false ↔ "apocryphal"`, `false → "deprecated"`, etc.)
- These are editorial bookkeeping, not canon history. Information is in Git history if needed.

### Storage

- Structured data in `.chronicle/` (machine-readable YAML).
- Human-readable Markdown changelog generated on demand via CLI command.

---

## OQ-D11-7: Superseding Mechanics

**Decision:** Bidirectional superseding with automatic inference. New `supersedes` common field added to D-10.

### Fields

| Field | Location | Type | Description |
|---|---|---|---|
| `superseded_by` | Deprecated file | `string` (file path) | Points to the replacement file. |
| `supersedes` | Replacement file | `string` or `list[string]` (file paths) | Points to the file(s) this entry replaces. Inferred at scan time if not explicitly set. |

### Validation Rules

| Situation | Severity | Message |
|---|---|---|
| Deprecated with `superseded_by` pointing to existing file (any canon status) | **No warning** | Expected workflow state |
| Deprecated with `superseded_by` pointing to nonexistent file | **Error** | "Superseding reference broken: [path] does not exist" |
| Deprecated with no `superseded_by` at all | **Warning** | "Deprecated without replacement reference" |
| `supersedes` and `superseded_by` both set but disagree | **Warning** | "Superseding references inconsistent between [A] and [B]" |
| Circular `superseded_by` chains | **Error** | "Circular superseding chain detected: [chain]" |
| Canonical entries referencing deprecated content | **Warning** | "References deprecated entry [Y]; review when replacement [Z] is promoted" |

### Behavior

- Many-to-one allowed: multiple deprecated files can point to the same replacement.
- Chronicle infers `supersedes` at scan time from `superseded_by` references (same pattern as bidirectional relationships in D-10 §7.4).
- Deprecated content excluded from search by default; `--include-deprecated` flag includes it.

### Required D-10 Amendment

Add `supersedes` to §4.6 (Common Fields — Metadata Fields).

---

## Summary: All Seven Decisions

| OQ | Short Name | Decision |
|---|---|---|
| OQ-D11-1 | State Machine | All 12 transitions allowed; 3 ceremony tiers; `apocryphal → true` prohibited (must go through draft) |
| OQ-D11-2 | Promotion Mechanism | Explicit `chronicle promote` CLI command; no Git hooks for v1 |
| OQ-D11-3 | Apocryphal Validation | Structural integrity enforced; narrative correctness skipped |
| OQ-D11-4 | Branch Conventions | Soft enforcement via warnings; configurable in `.chronicle/config.yaml` |
| OQ-D11-5 | Merge Conflicts | Documentation + validation only; no custom merge driver for v1 |
| OQ-D11-6 | Changelog Triggers | Automatic for canon transitions; manual CLI command for content changes |
| OQ-D11-7 | Superseding Mechanics | Bidirectional with `supersedes` field; automatic inference; new D-10 common field |

---

*These decisions are inputs to D-11 drafting. They will be incorporated into the specification and referenced in the revision history.*
