# D-12 Session Handoff: Validation Rule Catalog

**Date:** 2026-02-10
**Session Scope:** D-10 Verification, D-11 Design Decisions + Drafting, D-12 Scoping
**Participants:** Ryan + Claude
**Status:** Ready for D-12 Drafting (6 Design Questions Pending)

---

## 1. What Was Accomplished This Session

### 1.1. D-10 Verified and Amended (v0.2.0 → v0.2.1)

D-10 was verified against Master Strategy §6.3 — all 10 requirements passed. It was then amended to v0.2.1 with two additions driven by OQ-D11-7 (Superseding Mechanics):

- Added `supersedes` field to §4.6 (Common Fields — Metadata Fields)
- Added new §4.8 (Superseding Mechanics): bidirectional inference, many-to-one consolidation, chain resolution, 6 validation rules

### 1.2. D-11 Design Decisions Locked (7 of 7)

Seven open design questions were identified through scope analysis, discussed interactively, and locked:

| OQ | Short Name | Decision |
|---|---|---|
| OQ-D11-1 | State Machine | All 12 transitions; 3 ceremony tiers; `apocryphal → true` prohibited |
| OQ-D11-2 | Promotion | Explicit `chronicle promote` CLI; no Git hooks for v1 |
| OQ-D11-3 | Apocryphal Validation | Structural integrity enforced; narrative correctness skipped |
| OQ-D11-4 | Branch Conventions | Soft enforcement via warnings; configurable in `.chronicle/config.yaml` |
| OQ-D11-5 | Merge Conflicts | Documentation + validation only; no custom merge driver for v1 |
| OQ-D11-6 | Changelog Triggers | Automatic for canon transitions; manual CLI with `-m` flag |
| OQ-D11-7 | Superseding Mechanics | Bidirectional `superseded_by`/`supersedes`; automatic inference |

All 7 decisions persisted to `D-11-design-decisions.md`.

### 1.3. D-11 Drafted and Verified (~1,250 lines)

Full specification across 14 sections: Purpose/Scope, Conventions/Terminology, Canon Status Model, State Machine (Mermaid + text table), 6 Workflows (Promotion, Deprecation, Apocryphal, Restoration, Re-Drafting, Retcon), Superseding Mechanics, Branch Conventions, Merge Semantics, Validation Rules, Changelog Integration, Edge Cases (7 scenarios), Multi-File Entity Canon Behavior, Dependencies, Revision History.

Verified against all 7 Master Strategy §6.3 requirements and all 7 design decisions. **All checks passed.**

D-11 §9.4 provides a mapping table with 11 anticipated D-12 rule IDs (VAL-SCH-001 through VAL-BRA-011).

### 1.4. D-12 Scope Analysis Complete

Thorough analysis of D-10, D-11, D-01 §4.5, and D-04 §6.3 identified ~40–50 validation rules across 13 categories. Six open design questions were identified. Ryan requested this handoff before switching computers.

---

## 2. D-12 Scope Summary

### Validation Rule Categories

| # | Category | Est. Rules | Primary Source |
|---|---|---|---|
| 1 | Schema Validation | ~12 | D-10 §5 (Entity Types), §10.2 (JSON Schema) |
| 2 | Cross-Reference Integrity | ~6 | D-10 §6.5 (File Paths), §7.5 (Relationship Validation) |
| 3 | Timeline Consistency | ~3 | D-10 §4.3 (Temporal Fields), §5.6 (Timeline Type) |
| 4 | Axiom Enforcement | ~3 | D-10 §5.8 (Axiom Type), §9.8 (Axiom Examples) |
| 5 | Uniqueness Constraints | ~3 | D-10 §4.1 (Identity Fields) |
| 6 | Canon Status | ~5 | D-11 §9 (Validation Rules), §7.2, §11 (Edge Cases) |
| 7 | Superseding Mechanics | ~5 | D-10 §4.8, D-11 §6 and §9.3 |
| 8 | Multi-File Entity | ~3 | D-10 §4.7 (Multi-File Entity Fields) |
| 9 | Custom Schema | ~2 | D-10 §8 (Extensibility) |
| 10 | Apocryphal Relaxation | (modifier) | D-11 §9.1 — adjusts severity for categories 1–8 |
| 11 | Convenience Field Cross-Ref | ~5+ | D-10 §5 (entity-specific field descriptions) |
| 12 | Relationship Vocabulary | ~1 | D-10 §7.2–7.3 (Recommended Vocabulary) |
| 13 | Changelog Integration | (integration) | D-11 §10 — triggers, not validation errors |

**Total: ~40–50 rules**, each with the standard D-12 format per Master Strategy §6.3.

---

## 3. Open Design Questions (MUST RESOLVE BEFORE DRAFTING)

### OQ-D12-1: Assertion Rule Syntax

**Context:** D-10 §5.8 introduces `assertion_rule` on axiom entries with one example (`temporal_bound`). D-10 does not formally specify the complete grammar.

**Question:** How formally should D-12 define the assertion rule language for v1?

**Options:**
- **A) Minimal** — Define only `temporal_bound` (the one example in D-10)
- **B) Small set** — Define 2–3 types (`temporal_bound`, `value_constraint`, `pattern_match`) as structured YAML maps
- **C) Full mini-language** — BNF grammar, extensible rule types, operator set

**Recommendation:** Option B — small set with structured YAML maps. Useful without over-engineering.

### OQ-D12-2: Enum Case Sensitivity

**Context:** All D-10 enum examples use lowercase. Should the validator accept `"Active"` when the schema defines `"active"`?

**Options:**
- **A) Strict** — Case-sensitive; `"Active"` is an error
- **B) Lenient with nudge** — Case-insensitive comparison; informational notice suggesting lowercase
- **C) Silent normalization** — Case-insensitive; no notice

**Recommendation:** Option B — accept but nudge. Prevents frustration while encouraging consistency.

### OQ-D12-3: Error Message Standardization

**Question:** Should every error message follow a standardized template?

**Proposed format:** `[SEVERITY] RULE-ID — Message (File: path)`
Example: `[ERROR] VAL-SCH-001 — Missing required field 'name' for entity type 'faction' (File: factions/iron-covenant.md)`

Each rule would also include a remediation hint displayable via `--verbose`.

### OQ-D12-4: Rule Execution Order

**Question:** Should rules execute in dependency order with cascade gating, or all at once?

**Options:**
- **A) All at once** — Run everything, report everything
- **B) Tiered with gating** — Tier 1 (Schema) → Tier 2 (Structural) → Tier 3 (Semantic). If Tier 1 fails for a file, skip Tiers 2–3 for that file.
- **C) Strict sequential** — Each rule has explicit dependencies; skip downstream rules on any failure

**Recommendation:** Option B — tiered with per-file cascade gating. Prevents noise without hiding issues.

### OQ-D12-5: Free-Text Date Comparison

**Question:** How should the validator handle era boundary checks when in-world dates are free-text strings?

**Options:**
- **A) Skip all temporal checks** — Dates are free-text; temporal validation is deferred to LLM
- **B) Structured-only** — Temporal checks work only when axiom rules and entities both provide numeric/structured date components; narrative dates skipped with informational notice
- **C) Heuristic parsing** — Attempt to extract numeric components from free-text via regex

**Recommendation:** Option B — structured-only. Consistent with "structural integrity enforced, narrative correctness is best-effort."

### OQ-D12-6: Tag Format Enforcement

**Question:** Should the validator enforce the "lowercase, hyphenated" tag convention?

**Options:**
- **A) No check** — Convention documented but not validated
- **B) Informational notice** — Emit notice with suggested correction
- **C) Warning** — Stronger severity; appears in standard output

**Recommendation:** Option B — informational notice. Nudges consistency without blocking.

---

## 4. Key File Locations

| Document | Path (relative to workspace root) |
|---|---|
| D-04 Master Strategy | `Chronicle-FractalRecall-Master-Strategy.md` |
| D-01 Design Proposal | `Chronicle-FractalRecall-Design-Proposal.md` |
| D-10 Lore Schema (v0.2.1) | `chronicle/docs/D-10-lore-file-schema-spec.md` |
| D-11 Canon Workflow | `chronicle/docs/D-11-canon-workflow-spec.md` |
| D-11 Design Decisions | `chronicle/docs/D-11-design-decisions.md` |
| ROADMAP-STATUS | `chronicle/docs/ROADMAP-STATUS.md` |

D-12 does not yet exist. Create it at `chronicle/docs/D-12-validation-rule-catalog.md` after design questions are resolved.

---

## 5. Instructions for Next Session

1. **Read key files for context:** D-10 (schema), D-11 (especially §9.4 for D-12 mapping table), D-04 §6.3 (D-12 requirements), D-01 §4.5 (validation design intent). The D-11 design decisions doc is a quick reference.

2. **Resolve OQ-D12-1 through OQ-D12-6:** Walk through each with Ryan one at a time. Present options, recommendation, rationale. Lock each decision.

3. **Persist decisions:** Create `D-12-design-decisions.md` (same format as `D-11-design-decisions.md`).

4. **Draft D-12:** Standard format from Master Strategy §6.3 (Rule ID, Category, Name, Description, Severity, Passing Example, Failing Example, Error Message). The 11 anticipated rule IDs from D-11 §9.4 provide a starting framework. Expect ~40–50 rules, 800–1200 lines.

5. **Verify D-12:** Compare against Master Strategy §6.3 point by point, confirm all design decisions incorporated.

6. **Update ROADMAP-STATUS.md:** Mark D-12 complete, update D-13 to NEXT, update document counts.

---

## 6. Project-Wide Status

| Document | Status | Notes |
|---|---|---|
| D-01 | ✅ DONE | Design Proposal (720 lines) |
| D-02 | ✅ DONE | Conceptual Architecture (930 lines) |
| D-03 | ✅ DONE | Session Bootstrap (123 lines) |
| D-04 | ✅ DONE | Master Strategy (governing document) |
| D-10 | ✅ DONE | Lore Schema v0.2.1 (~1470 lines, 12 entity types) |
| D-11 | ✅ DONE | Canon Workflow v0.1.0-draft (~1250 lines, 7 design decisions) |
| D-12 | 🟡 SCOPED | Validation Rule Catalog — 6 OQs pending, then draft |
| D-13 | 🔵 BLOCKED | CLI Command Reference — blocked on D-12 |
| D-14 | 🔵 READY | LLM Integration — independent, can start anytime |
| D-15 | 🔴 BLOCKED | Integration Design — blocked on Track B |
| D-30–D-33 | ✅ DONE | Archive, README, Colab briefing, notebook template |

**Track A critical path:** D-10 ✓ → D-11 ✓ → D-12 (6 OQs pending) → D-13

**Notable:** Master Strategy §6.3 still references original 6 entity types; should be amended to reflect D-10's expanded 12-type taxonomy.

---

*This document was generated at the end of a session to facilitate handoff. The .docx version contains identical content with professional formatting.*
