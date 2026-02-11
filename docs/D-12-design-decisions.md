# D-12 Design Decisions: Validation Rule Catalog

**Date:** 2026-02-10
**Participants:** Ryan + Claude
**Status:** All 6 decisions LOCKED
**Upstream:** D-10 (v0.2.1), D-11 (v0.1.0-draft), D-04 §6.3

---

## Decision Summary

| OQ | Short Name | Decision | Option |
|---|---|---|---|
| OQ-D12-1 | Assertion Rule Syntax | Small set of 3 structured YAML rule types | B |
| OQ-D12-2 | Enum Case Sensitivity | Case-insensitive match with informational nudge | B |
| OQ-D12-3 | Error Message Standardization | Standardized template: `[SEVERITY] RULE-ID — Message (File: path)` | Approved |
| OQ-D12-4 | Rule Execution Order | Three-tier cascade with per-file gating | B |
| OQ-D12-5 | Free-Text Date Comparison | Structured-only; canonical calendar is YYY PG | B |
| OQ-D12-6 | Tag Format Enforcement | Informational notice with auto-normalization | B (modified) |

---

## OQ-D12-1: Assertion Rule Syntax

**Question:** How formally should D-12 define the `assertion_rule` language for v1?

**Context:** D-10 §5.8 introduces `assertion_rule` on axiom entries with one example (`temporal_bound`). The field is defined as a YAML map, but D-10 explicitly defers the full syntax to D-12.

**Options Considered:**
- A) Minimal — Define only `temporal_bound`
- B) Small set — Define 3 types as structured YAML maps
- C) Full mini-language — BNF grammar, extensible rule types, operator set

**Decision: Option B — Small set of 3 structured assertion rule types**

D-12 will define three deterministic assertion rule types:

| Rule Type | Purpose | Example Use |
|---|---|---|
| `temporal_bound` | Check date/era boundaries | "No character born after 300 PG" |
| `value_constraint` | Check field values against conditions | "Character status must be 'dead' when death_date is set" |
| `pattern_match` | Check field values against regex patterns | "Faction names must match `^[A-Z][a-z]`" |

Each rule type is a structured YAML map with defined keys (not a free-form expression language). This is forward-compatible with a richer grammar in future versions — the map format can be extended without breaking existing rules.

**Rationale:** Covers the three most common deterministic validation patterns (temporal, value, format) without the engineering overhead of a full DSL. Authors who need more complex checks can use `enforcement: "soft"` to delegate to the LLM (D-14 territory).

---

## OQ-D12-2: Enum Case Sensitivity

**Question:** Should the validator accept `"Active"` when the schema defines `"active"`?

**Context:** All D-10 enum examples use lowercase. The spec doesn't explicitly state whether matching is case-sensitive.

**Options Considered:**
- A) Strict — Case-sensitive; `"Active"` is an error
- B) Lenient with nudge — Case-insensitive comparison; informational notice suggesting lowercase
- C) Silent normalization — Case-insensitive; no notice

**Decision: Option B — Lenient with informational nudge**

Enum validation uses case-insensitive comparison. `"Active"` matches `"active"` and passes schema validation. An informational notice is emitted recommending the canonical lowercase form:

```
[INFO] VAL-SCH-xxx — Enum value "Active" accepted; lowercase "active" recommended (File: factions/iron-covenant.md)
```

**Rationale:** Prevents frustration from typo-level casing errors while encouraging consistency across the lore base. Informational severity means the notice only appears in verbose/style-check output, not standard validation. Consistent with D-11's soft enforcement philosophy.

---

## OQ-D12-3: Error Message Standardization

**Question:** Should every validation message follow a standardized template?

**Decision: Approved — Standardized template with remediation hints**

All validation messages follow this format:

```
[SEVERITY] RULE-ID — Message (File: path/to/file.md)
```

Example:
```
[ERROR] VAL-SCH-001 — Missing required field 'name' for entity type 'faction' (File: factions/iron-covenant.md)
```

Severity levels: `ERROR`, `WARNING`, `INFO`

Each rule definition in D-12 includes a **remediation hint** — a brief sentence explaining how to fix the issue. Hints are displayed via `chronicle validate --verbose`.

Example hint for VAL-SCH-001: *"Add `name: \"your-entry-name\"` to the YAML frontmatter."*

**Rationale:** Standardized format enables programmatic parsing of validation output, consistent author experience, and direct cross-referencing from error messages to D-12 rule definitions via rule IDs.

---

## OQ-D12-4: Rule Execution Order

**Question:** Should rules execute in dependency order with cascade gating, or all at once?

**Context:** A file with broken schema (e.g., missing `type` field) would produce cascading failures in downstream rules (cross-reference checks, timeline checks, etc.) that are all symptoms of the same root cause.

**Options Considered:**
- A) All at once — Run everything, report everything
- B) Tiered with per-file cascade gating — Three tiers; if Tier 1 fails for a file, skip Tiers 2–3 for that file
- C) Strict sequential — Explicit per-rule dependency graph

**Decision: Option B — Three-tier cascade with per-file gating**

Rules are organized into three tiers:

| Tier | Name | Scope | Rules |
|---|---|---|---|
| 1 | Schema | Per-file structural validity | Required fields, type correctness, enum values, JSON Schema compliance |
| 2 | Structural | Cross-file references | Cross-reference integrity, superseding mechanics, multi-file entity consistency, uniqueness |
| 3 | Semantic | Narrative logic | Timeline consistency, axiom enforcement, canon status, relationship canon checks |

**Gating behavior:** If a file fails any Tier 1 rule, Tiers 2 and 3 are **skipped for that file only**. Other files that passed Tier 1 continue through all tiers. The skipped tiers are noted in output:

```
[INFO] — Tiers 2–3 skipped for factions/iron-covenant.md due to schema errors
```

**Mapping to D-11 ceremony tiers:**
- Low ceremony ≈ Tier 1
- Medium ceremony ≈ Tiers 1 + 2
- High ceremony ≈ Tiers 1 + 2 + 3 + LLM deep checks (D-14)

**Rationale:** Eliminates cascade noise without hiding real issues in other files. Three tiers are intuitive and straightforward to implement as sequential passes.

---

## OQ-D12-5: Free-Text Date Comparison

**Question:** How should the validator handle temporal checks when in-world dates are free-text strings?

**Context:** D-10 allows free-text dates for narrative fields (e.g., `date: "Third moon of the Shattering Era"`). This is great for worldbuilding flexibility but creates a problem for deterministic temporal validation.

**Options Considered:**
- A) Skip all temporal checks — Defer entirely to LLM
- B) Structured-only — Temporal checks work only when both sides provide machine-parseable data
- C) Heuristic parsing — Regex extraction of numeric components from free-text

**Decision: Option B — Structured-only temporal checks**

Temporal validation activates only when **both sides** of a comparison provide structured, machine-parseable date components. Free-text narrative dates are skipped with an informational notice:

```
[INFO] VAL-xxx — Temporal check skipped: free-text date not machine-parseable (File: characters/elena-voss.md)
```

**Aethelgard canonical calendar: YYY PG (Post-Glitch)**

The Aethelgard setting uses **YYY PG** (Post-Glitch) as its canonical calendar system, with the Glitch event as epoch zero. Structured dates in this system use numeric year values (e.g., `120 PG`, `347 PG`). The `temporal_bound` assertion rule type can parse `NNN PG` patterns as numeric values for comparison.

The validator recognizes structured dates when:
- The `calendar_system` field on a timeline entity is set (e.g., `"PG"`)
- Both the axiom rule threshold and the entity date field contain parseable numeric components in the declared calendar system

When either side is a free-text narrative date (e.g., `"sometime during the Age of Echoes"`), the check is skipped gracefully.

**Rationale:** Consistent with the project's running principle: "structural integrity enforced, narrative correctness is best-effort." Avoids the false-confidence trap of heuristic parsing while enabling real enforcement where data supports it.

---

## OQ-D12-6: Tag Format Enforcement

**Question:** Should the validator enforce the "lowercase, hyphenated" tag convention from D-10 §4.6?

**Context:** D-10 documents `tags` as `list[string]` with a convention of "lowercase, hyphenated" (e.g., `pre-glitch`, `iron-covenant`). The convention is documented but not enforced.

**Options Considered:**
- A) No check — Convention documented but not validated
- B) Informational notice — Emit notice with suggested correction
- C) Warning — Stronger severity in standard output

**Decision: Option B (modified) — Informational notice with auto-normalization**

The validator performs two actions on non-conforming tags:

1. **Auto-normalize internally:** Convert to lowercase, replace spaces with hyphens. The normalized value is what Chronicle uses for search, filtering, and deduplication. The on-disk file is **not** modified (consistent with Chronicle's read-only validation principle).

2. **Emit informational notice:** Tell the author what was normalized:

```
[INFO] VAL-SCH-xxx — Tag "Iron Covenant" normalized to "iron-covenant" (File: factions/iron-covenant.md)
```

**Normalization rules:**
- Convert to lowercase
- Replace spaces with hyphens
- Trim leading/trailing whitespace

**Rationale:** Prevents silent deduplication failures (where `"Pre-Glitch"` and `"pre-glitch"` would be treated as different tags) while being more helpful than a bare notice. The author's intent is preserved, the system works correctly, and there's a clear breadcrumb for manual cleanup. Consistent with the lenient-with-nudge philosophy established in OQ-D12-2.

---

## Impact on D-10

No D-10 amendments required for D-12 design decisions. All decisions operate within D-10's existing field definitions and data types. The `YYY PG` calendar system is Aethelgard-specific content, not a schema-level change.

## Impact on D-11

No D-11 amendments required. The three-tier execution order (OQ-D12-4) maps cleanly to D-11's ceremony tiers. The error message format (OQ-D12-3) is consistent with D-11's validation rule references in §9.

---

*All 6 decisions locked on 2026-02-10. These decisions govern the drafting of D-12: Validation Rule Catalog.*
