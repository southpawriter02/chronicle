# D-12: Validation Rule Catalog

| Field | Value |
|---|---|
| **Document ID** | D-12 |
| **Version** | 0.1.0-draft |
| **Status** | Draft |
| **Author** | Ryan (with specification guidance from Claude) |
| **Created** | 2026-02-10 |
| **Last Updated** | 2026-02-10 |
| **Dependencies** | D-10 (v0.2.1), D-11 (v0.1.0-draft), D-04 (§6.3) |
| **Downstream Consumers** | D-13 (CLI), D-14 (LLM Integration) |

---

## §1 Document Purpose and Scope

This document defines every validation rule that Chronicle's `chronicle validate` command executes. Each rule has a unique ID, severity level, passing/failing examples with Aethelgard content, standardized error messages, and remediation guidance.

D-12 translates the schema constraints from D-10 (Lore File Schema Specification) and the behavioral policies from D-11 (Canon Workflow Specification) into a testable, implementable catalog. It is the single source of truth for what "valid" means in a Chronicle lore repository.

**Scope:** 37 validation rules across three tiers, plus 3 assertion rule type definitions. Rules are organized by execution tier (Schema → Structural → Semantic) per OQ-D12-4.

**Out of scope:** LLM-based deep validation (D-14), CLI command syntax (D-13), FractalRecall integration (D-15).

---

## §2 Conventions and Terminology

**Tier:** Validation execution phase. Three tiers run sequentially; failure in Tier 1 gates Tiers 2-3 per-file.

**Severity:** ERROR (must fix, blocks promotion), WARNING (should fix, appears in standard output), INFORMATIONAL (style guidance, verbose-only).

**Apocryphal Modifier:** Adjusted severity when the source file has `canon: "apocryphal"`. Per D-11 §9.1.

**Cascade Gating:** If Tier 1 fails for a file, that file's Tier 2 and Tier 3 checks are skipped. Other files continue normally.

**Rule ID Format:** `VAL-{CATEGORY}-{NNN}` where CATEGORY is SCH (schema), REF (cross-reference), SUP (superseding), MFE (multi-file entity), UNQ (uniqueness), BRA (branch), CAN (canon), TMP (temporal), AXM (axiom), VOC (vocabulary).

**PG:** Post-Glitch. Aethelgard's canonical calendar system where year 0 marks the Glitch event.

---

## §3 Validation Tier Architecture

Chronicle's validation system operates in three sequential tiers, each assuming the successful completion of the previous tier:

### Tier 1 — Schema Validation (12 rules)
Per-file structural validity checks. These rules verify that each entry file conforms to the YAML schema specification from D-10. All Tier 1 rules are checked first and independently for each file. If any Tier 1 rule fails with ERROR severity for a file, that file's Tiers 2 and 3 validation are skipped, and processing moves to the final results phase. Other files continue through the full validation pipeline normally.

### Tier 2 — Structural Validation (15 rules)
Cross-file reference integrity checks. These rules assume each file has passed Tier 1 and verify that all inter-file references (via `target` fields, relationship definitions, `supersedes` arrays, etc.) point to valid, existing entries. Tier 2 rules also check multi-file consistency such as bidirectional relationship validity and supersession chains.

### Tier 3 — Semantic Validation (10 rules)
Narrative logic and axiom enforcement. These rules assume the structural graph is intact and validate semantic constraints: canonical/draft/apocryphal consistency, temporal ordering, and axiom assertions. Tier 3 rules are the most restrictive and context-aware.

### Validation Flow Diagram

```
┌─────────────────┐
│  File Input     │
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│   Tier 1: Schema    │ (12 rules)
│    Validation       │
└────────┬────────────┘
         │
         ├─ [FAIL] ──────────────────────────┐
         │  (gated per-file)                  │
         │                                    │
         ├─ [PASS] ──────────┐                │
         │                   ▼                │
         │        ┌──────────────────────┐   │
         │        │ Tier 2: Structural   │   │
         │        │  Validation (15)     │   │
         │        └──────────┬───────────┘   │
         │                   │                │
         │                   ├─ [FAIL] ─────┐│
         │                   │               ││
         │                   ├─ [PASS] ────┐││
         │                   │              │││
         │                   │    ┌────────────────────┐
         │                   │    │ Tier 3: Semantic   │
         │                   │    │ Validation (10)    │
         │                   │    └────────┬───────────┘
         │                   │             │
         │                   │             ▼
         └───────────────────┴────────────────────────┐
                                                       │
                                                       ▼
                                            ┌──────────────────┐
                                            │ Validation Report│
                                            │ (errors, warnings,│
                                            │  infos per file) │
                                            └──────────────────┘
```

### Mapping to D-11 Ceremony Tiers

| Chronicle Tier | Validation Scope | D-11 Ceremony Level |
|---|---|---|
| Tier 1 (Schema) | Per-file structure only | Low (Draft/Internal) |
| Tiers 1+2 (Structural) | Per-file + cross-reference graph | Medium (Team/Review) |
| Tiers 1+2+3 (Semantic) | Full narrative consistency | High (Public/Release) |
| Tiers 1-3 + LLM (Deep) | Tiers 1-3 + contextual LLM checks | Deep (Archive/Historical) |

### Rule Count Summary

| Tier | Category | Rule Count | Severity Distribution |
|---|---|---|---|
| Tier 1 | Schema | 12 | 10 ERROR, 1 WARNING, 1 INFORMATIONAL |
| Tier 2 | Structural | 15 | 10 ERROR, 4 WARNING, 1 INFORMATIONAL |
| Tier 3 | Semantic | 10 | 3 ERROR, 4 WARNING, 3 INFORMATIONAL |
| **Total** | — | **37** | **23 ERROR, 9 WARNING, 5 INFORMATIONAL** |

---

## §4 Rule Definition Format

All validation rules follow a standardized template to ensure consistency, clarity, and implementability:

```markdown
### VAL-XXX-NNN: Rule Name

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-XXX-NNN` |
| **Category** | Category Name |
| **Tier** | N — Name |
| **Severity** | Error / Warning / Informational |
| **Apocryphal** | (adjusted severity or N/A) |
| **Source** | D-10 §X.X / D-11 §X.X |

**Description:** What the rule checks and why, in clear narrative form.

**Passing Example:**
(valid YAML with context)

**Failing Example:**
(invalid YAML with annotations explaining the violation)

**Error Message:**
[SEVERITY] VAL-XXX-NNN — Human-readable message (File: path)

**Remediation:** Step-by-step guidance for fixing the issue.
```

### Error Message Format

All error/warning/informational messages follow this structure:

```
[SEVERITY] RULE-ID — Message describing the violation. (File: path/to/file.md)
```

Where:
- **SEVERITY** is one of: `[ERROR]`, `[WARNING]`, `[INFORMATIONAL]`
- **RULE-ID** is the rule's unique identifier (e.g., `VAL-SCH-001`)
- **Message** is human-readable, provides context, and suggests remediation
- **File** is the relative path to the problematic entry

Remediation hints are available via `--verbose` flag during CLI execution (D-13 §3).

---

## §5 — Tier 1 (Schema Validation) Rules

Tier 1 rules perform per-file structural validity checks that execute first in the validation pipeline. These rules verify that essential file structure, required fields, and field data types conform to the schema before any semantic or relational checks are performed. **If any Tier 1 rule fails for a file, Tiers 2 and 3 are skipped for that file.** All Tier 1 rules use ERROR severity for schema violations, except where noted.

---

### VAL-SCH-001: YAML Frontmatter Parseable

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-SCH-001` |
| **Category** | Frontmatter Structure |
| **Tier** | 1 — Schema |
| **Severity** | Error |
| **Apocryphal** | Error (schema always enforced) |
| **Source** | D-10 §4.1 / D-11 §3.1 |

**Description:** Every entry file must contain valid YAML frontmatter enclosed between `---` delimiters on lines 1 and 3 (or a blank line before the first `---`). The YAML block must be parseable by a standard YAML parser without syntax errors. This is the foundational structural requirement: if frontmatter is malformed, the file cannot be processed.

**Passing Example:**
```yaml
---
type: character
name: Elena Voss
canon: true
---

Elena Voss is the primary protagonist of the Iron Covenant trilogy...
```

**Failing Example:**
```yaml
---
type character
name: Elena Voss
canon: true
---

(missing colon after 'type')
```

**Error Message:**
```
[ERROR] VAL-SCH-001 — YAML frontmatter is not parseable. Check for syntax errors (missing colons, unmatched quotes, invalid indentation). (File: entities/characters/elena-voss.md)
```

**Remediation:** Review the frontmatter block for common YAML errors:
- Missing colons (`:`) after field names
- Mismatched or unescaped quotes
- Incorrect indentation (use spaces, not tabs)
- Unclosed lists or maps
Use a YAML linter or IDE with YAML validation enabled.

---

### VAL-SCH-002: Required Common Fields Present

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-SCH-002` |
| **Category** | Required Fields |
| **Tier** | 1 — Schema |
| **Severity** | Error |
| **Apocryphal** | Error (schema always enforced) |
| **Source** | D-10 §4.1 / D-11 §3.2 |

**Description:** All entry files must include the three required common fields: `type`, `name`, and `canon`. These fields are foundational metadata present on every entity in the Chronicle. Their absence prevents the system from classifying, identifying, and determining the canonical status of the entry.

**Passing Example:**
```yaml
---
type: faction
name: Iron Covenant
canon: true
description: The primary military faction of Aethelgard...
---
```

**Failing Example:**
```yaml
---
name: Iron Covenant
canon: true
---

(missing 'type' field)
```

**Error Message:**
```
[ERROR] VAL-SCH-002 — Missing required field(s): type, name, canon. All entries must include these common fields. (File: entities/factions/iron-covenant.md)
```

**Remediation:** Add the missing required fields to the frontmatter:
- `type`: The entity category (e.g., `character`, `faction`, `locale`, `event`)
- `name`: A unique, descriptive name for the entity
- `canon`: Canonical status (`true`, `false`, `"apocryphal"`, or `"deprecated"`)

---

### VAL-SCH-003: Entity Type Recognized

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-SCH-003` |
| **Category** | Schema Registration |
| **Tier** | 1 — Schema |
| **Severity** | Warning |
| **Apocryphal** | Warning (schema always enforced) |
| **Source** | D-10 §5 / D-11 §4.1 |

**Description:** The `type` value must match a registered schema from the 12 default entity types or a custom schema in `.chronicle/schema/custom/`. If a `type` does not match any registered schema, the validation system continues with common-fields-only processing (no type-specific required fields are enforced). This is a warning because the entry is still structurally valid—it may be intentionally using an undeclared type—but the absence of schema guidance suggests a potential misconfiguration.

**Passing Example (Default Type):**
```yaml
---
type: timeline
name: Age of Echoes
canon: true
start: "480 AE"
---
```

**Passing Example (Custom Type):**
```yaml
---
type: artifact_category
name: Reliquaries
canon: true
artifact_category_description: "Magical containers for preservation"
---
```

**Failing Example (Unrecognized Type):**
```yaml
---
type: magical_phenomenon
name: The Rift Storm
canon: true
---

(no schema found for 'magical_phenomenon')
```

**Error Message:**
```
[WARNING] VAL-SCH-003 — Type 'magical_phenomenon' is not registered in the schema. Processing will continue with common fields only; type-specific field requirements will be skipped. (File: entities/phenomena/rift-storm.md)
```

**Remediation:** Either:
1. Change `type` to a recognized default type (faction, character, entity, locale, event, timeline, system, axiom, item, document, term, meta)
2. Create a custom schema at `.chronicle/schema/custom/magical_phenomenon.json` to register the new type formally

---

### VAL-SCH-004: Canon Field Value Valid

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-SCH-004` |
| **Category** | Field Values |
| **Tier** | 1 — Schema |
| **Severity** | Error |
| **Apocryphal** | Error (schema always enforced) |
| **Source** | D-10 §4.2 / D-11 §5.1 |

**Description:** The `canon` field must be set to exactly one of four allowed values: `true` (canonical entry), `false` (non-canonical/cut content), `"apocryphal"` (in-universe mythology), or `"deprecated"` (superseded but retained for reference). Any other value is a schema violation. Note that `"apocryphal"` and `"deprecated"` are strings, while `true` and `false` are YAML booleans.

**Passing Example (Canonical):**
```yaml
---
type: character
name: Elena Voss
canon: true
---
```

**Passing Example (Apocryphal):**
```yaml
---
type: legend
name: The Sundering of Stars
canon: "apocryphal"
---
```

**Failing Example (Invalid Value):**
```yaml
---
type: character
name: Elena Voss
canon: "canonical"
---

(should be 'true', not the string "canonical")
```

**Error Message:**
```
[ERROR] VAL-SCH-004 — Invalid canon value: 'canonical'. Must be exactly one of: true, false, "apocryphal", "deprecated". (File: entities/characters/elena-voss.md)
```

**Remediation:** Change the `canon` field to one of the four allowed values:
```yaml
canon: true                # For entries in the primary timeline
canon: false               # For cut or alternate content
canon: "apocryphal"        # For in-universe myths or legends
canon: "deprecated"        # For superseded entries
```

---

### VAL-SCH-005: Required Type-Specific Fields Present

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-SCH-005` |
| **Category** | Required Fields |
| **Tier** | 1 — Schema |
| **Severity** | Error |
| **Apocryphal** | Error (schema always enforced) |
| **Source** | D-10 §5 / D-11 §3.3 |

**Description:** Beyond the three common fields (`type`, `name`, `canon`), certain entity types require additional type-specific fields. This rule enforces those requirements:
- **axiom**: `axiom_type`, `enforcement`, `assertion`
- **timeline**: `start`
- **entity**: `entity_class`
- **item**: `item_type`
- **document**: `document_type`
- **term**: `term_type`
- **meta**: `meta_type`
- **faction, character, locale, event, system**: No additional required fields beyond common

If a file declares a type that has required type-specific fields but omits them, this rule fails.

**Passing Example (Axiom):**
```yaml
---
type: axiom
name: The Principle of Binding
canon: true
axiom_type: metaphysical
enforcement: hard
assertion: "All magic requires a binding consent between wielder and force."
---
```

**Passing Example (Timeline):**
```yaml
---
type: timeline
name: Age of Echoes
canon: true
start: "480 AE"
---
```

**Failing Example (Missing Type-Specific Field):**
```yaml
---
type: axiom
name: The Principle of Binding
canon: true
axiom_type: metaphysical
enforcement: hard
---

(missing 'assertion' field)
```

**Error Message:**
```
[ERROR] VAL-SCH-005 — Type 'axiom' requires fields: axiom_type, enforcement, assertion. Missing: assertion. (File: entities/axioms/principle-of-binding.md)
```

**Remediation:** Add the missing required field(s) for the entity type. Refer to the schema documentation for your type to determine what is required.

---

### VAL-SCH-006: Field Data Type Correct

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-SCH-006` |
| **Category** | Field Values |
| **Tier** | 1 — Schema |
| **Severity** | Error |
| **Apocryphal** | Error (schema always enforced) |
| **Source** | D-10 §6 / D-11 §5.2 |

**Description:** Each field value must match the data type declared in the schema. Common field type violations include:
- String field given a number or boolean value without quotes
- Boolean field given a string instead of `true`/`false`
- List field given a single scalar value
- Map/object field given a string or list
- Numeric field given a non-numeric string

This rule catches structural type mismatches that would prevent downstream processing.

**Passing Example:**
```yaml
---
type: character
name: Elena Voss
canon: true
age: 32
aliases:
  - The Voss
  - The Silver Sentinel
metadata:
  birth_year: 2458
  status: active
---
```

**Failing Example (Type Mismatch):**
```yaml
---
type: character
name: Elena Voss
canon: "true"
age: "thirty-two"
aliases: Elena's Aliases
---

(canon should be boolean true, not string "true";
 age should be number 32, not string "thirty-two";
 aliases should be a list, not a string)
```

**Error Message:**
```
[ERROR] VAL-SCH-006 — Field 'age' has incorrect type. Expected: number, got: string ("thirty-two"). (File: entities/characters/elena-voss.md)
```

**Remediation:** Correct the field value to match its declared type in the schema. Use unquoted numbers for numeric fields, `true`/`false` for booleans, quoted strings for text, and proper YAML list syntax (`- item`) for arrays.

---

### VAL-SCH-007: Enum Value Valid

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-SCH-007` |
| **Category** | Field Values |
| **Tier** | 1 — Schema |
| **Severity** | Error (unrecognized); Informational (case mismatch) |
| **Apocryphal** | Error (schema always enforced) |
| **Source** | D-10 §6 / D-11 §5.3 / OQ-D12-2 |

**Description:** Fields that define a closed set of allowed values (enums) must contain one of those values. Per OQ-D12-2, enum matching is case-insensitive: if a field value matches an enum option in a different case, the validation system automatically normalizes it to the canonical case and emits an informational notice (not an error). If a value does not match any enum option—even case-insensitively—the rule fails with an error.

**Passing Example (Correct Case):**
```yaml
---
type: axiom
name: Principle of Binding
canon: true
axiom_type: metaphysical
enforcement: hard
assertion: "All magic requires consent."
---

(axiom_type='metaphysical' matches enum [temporal, physical, metaphysical, social, narrative, constraint])
```

**Passing Example (Case Mismatch → Normalized):**
```yaml
---
type: axiom
name: Principle of Binding
canon: true
axiom_type: METAPHYSICAL
enforcement: Hard
assertion: "All magic requires consent."
---

(Will be normalized to 'metaphysical' and 'hard' with informational notice)
```

**Failing Example (Unrecognized Enum Value):**
```yaml
---
type: axiom
name: Principle of Binding
canon: true
axiom_type: mystical_force
enforcement: hard
assertion: "All magic requires consent."
---

(axiom_type='mystical_force' is not in the enum)
```

**Error Message (Unrecognized):**
```
[ERROR] VAL-SCH-007 — Field 'axiom_type' value 'mystical_force' is not a recognized enum option. Allowed values: temporal, physical, metaphysical, social, narrative, constraint. (File: entities/axioms/principle-of-binding.md)
```

**Error Message (Case Mismatch):**
```
[INFORMATIONAL] VAL-SCH-007 — Field 'axiom_type' value 'METAPHYSICAL' normalized to 'metaphysical' (case-insensitive match). (File: entities/axioms/principle-of-binding.md)
```

**Remediation (Unrecognized):** Check the schema for the correct enum values and update the field to match one of them exactly.

**Remediation (Case Mismatch):** Use the canonical case provided by the schema; the system will auto-normalize, but consistency is preferred.

---

### VAL-SCH-008: Date Format Valid

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-SCH-008` |
| **Category** | Field Values |
| **Tier** | 1 — Schema |
| **Severity** | Error |
| **Apocryphal** | Error (schema always enforced) |
| **Source** | D-10 §6 / D-11 §6.1 |

**Description:** The system timestamp field `last_validated` must conform to ISO 8601 date format: `YYYY-MM-DD` (e.g., `2025-02-10`). Other date or datetime fields in the entry are treated as free-text and are not validated by this rule—they may use any format the entry author chooses. Only `last_validated` is structurally enforced.

**Passing Example:**
```yaml
---
type: event
name: The Siege of Thornhaven
canon: true
date_occurred: "Winter 502 AE"
last_validated: 2025-02-10
---
```

**Failing Example (Invalid Format):**
```yaml
---
type: event
name: The Siege of Thornhaven
canon: true
date_occurred: "Winter 502 AE"
last_validated: "February 10, 2025"
---

(should be 2025-02-10)
```

**Error Message:**
```
[ERROR] VAL-SCH-008 — Field 'last_validated' does not match ISO 8601 format (YYYY-MM-DD). Got: 'February 10, 2025'. (File: entities/events/siege-of-thornhaven.md)
```

**Remediation:** Update `last_validated` to ISO 8601 format: `YYYY-MM-DD`. For example:
```yaml
last_validated: 2025-02-10
```

Other date fields can remain in any format. Only `last_validated` is strictly validated.

---

### VAL-SCH-009: File Path Format Valid

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-SCH-009` |
| **Category** | Field Values |
| **Tier** | 1 — Schema |
| **Severity** | Error |
| **Apocryphal** | Error (schema always enforced) |
| **Source** | D-10 §6.5 / D-11 §7.1 |

**Description:** Any field containing a file path (including `superseded_by`, `supersedes`, `parent`, `children`, and relationship `target` fields) must conform to the following format rules:
1. Use forward slashes (`/`), never backslashes
2. Be relative to the repository root (no leading `/` or `../` parent directory references)
3. Include the `.md` file extension
4. Point to valid entry files within the chronicle structure

This rule ensures that all inter-file references are consistent and resolvable.

**Passing Example:**
```yaml
---
type: event
name: The Fall of Istermere
canon: true
superseded_by: entities/events/fall-of-istermere-revised.md
related_events:
  - target: entities/events/siege-of-thornhaven.md
    type: preceded_by
---
```

**Failing Example (Invalid Path Format):**
```yaml
---
type: event
name: The Fall of Istermere
canon: true
superseded_by: \entities\events\fall-of-istermere-revised
related_events:
  - target: ../entities/events/siege-of-thornhaven.md
    type: preceded_by
---

(backslashes instead of forward slashes;
 missing .md extension;
 parent directory reference ../entities)
```

**Error Message:**
```
[ERROR] VAL-SCH-009 — Field 'superseded_by' contains an invalid file path: '\entities\events\fall-of-istermere-revised'. Paths must use forward slashes, be relative (no leading / or ../), and include .md extension. (File: entities/events/fall-of-istermere.md)
```

**Remediation:** Rewrite file path references to conform to the standard:
- Use `/` instead of `\`
- Remove leading `/` or `../` references
- Add `.md` extension if missing
- Ensure the path is relative to the repository root

Example correction:
```yaml
superseded_by: entities/events/fall-of-istermere-revised.md
```

---

### VAL-SCH-010: Relationship Entry Structure Valid

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-SCH-010` |
| **Category** | Relationship Structure |
| **Tier** | 1 — Schema |
| **Severity** | Error |
| **Apocryphal** | Error (schema always enforced) |
| **Source** | D-10 §7.1 / D-11 §7.2 |

**Description:** Relationship entries (within any `relationships` list or equivalent relationship field) must include two required fields:
- `target` (string, non-empty): File path to the related entity
- `type` (string, non-empty): The relationship type (e.g., `allies_with`, `opposed_to`, `preceded_by`)

Optional fields that may be present include:
- `since` (string or date): When the relationship began
- `until` (string or date): When the relationship ended
- `note` (string): Additional context
- `bidirectional` (boolean): Whether the relationship is mutual

If a relationship entry is missing `target` or `type`, or if optional fields are present with incorrect types, this rule fails.

**Passing Example:**
```yaml
---
type: faction
name: Iron Covenant
canon: true
relationships:
  - target: entities/factions/silver-order.md
    type: opposed_to
    since: "478 AE"
    note: "Historic conflict over Aethelgard's governance"
    bidirectional: true
  - target: entities/locales/thornhaven.md
    type: stronghold
---
```

**Failing Example (Missing Required Field):**
```yaml
---
type: faction
name: Iron Covenant
canon: true
relationships:
  - target: entities/factions/silver-order.md
    since: "478 AE"
---

(missing 'type' field)
```

**Failing Example (Optional Field With Wrong Type):**
```yaml
---
type: faction
name: Iron Covenant
canon: true
relationships:
  - target: entities/factions/silver-order.md
    type: opposed_to
    bidirectional: "yes"
---

(bidirectional should be boolean true/false, not string "yes")
```

**Error Message:**
```
[ERROR] VAL-SCH-010 — Relationship entry missing required field(s): target, type. (File: entities/factions/iron-covenant.md, relationship index 0)
```

**Remediation:** Ensure every relationship entry includes `target` and `type`. Correct optional field types:
- `since`, `until`, `note`: strings
- `bidirectional`: boolean (`true` or `false`)

---

### VAL-SCH-011: Tag Format Normalized

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-SCH-011` |
| **Category** | Tag Normalization |
| **Tier** | 1 — Schema |
| **Severity** | Informational |
| **Apocryphal** | Informational (schema always enforced) |
| **Source** | D-10 §6 / D-11 §5.4 / OQ-D12-6 |

**Description:** Per OQ-D12-6, tags are automatically normalized to a canonical format: lowercase letters and hyphens (no spaces, underscores, or mixed case). When normalization occurs, an informational notice is emitted to alert the author. This is not a hard error—the entry remains valid—but the notice prompts consistency. For example, `War Strategy` is normalized to `war-strategy`, and `Aethelgard_Politics` is normalized to `aethelgard-politics`.

**Passing Example (Already Normalized):**
```yaml
---
type: character
name: Elena Voss
canon: true
tags:
  - aethelgard-protagonist
  - iron-covenant-leader
  - silver-sentinel
---
```

**Passing Example (Normalization Applied):**
```yaml
---
type: character
name: Elena Voss
canon: true
tags:
  - Aethelgard Protagonist
  - Iron_Covenant_Leader
  - Silver Sentinel
---

(Will be normalized to: aethelgard-protagonist, iron-covenant-leader, silver-sentinel)
```

**Informational Message:**
```
[INFORMATIONAL] VAL-SCH-011 — Tag 'Aethelgard Protagonist' normalized to 'aethelgard-protagonist'. (File: entities/characters/elena-voss.md)
```

**Remediation:** Use lowercase with hyphens for all tags. While the system will auto-normalize, adopting the canonical format directly improves readability and consistency:
```yaml
tags:
  - aethelgard-protagonist
  - iron-covenant-leader
  - silver-sentinel
```

---

### VAL-SCH-012: Custom Schema Valid

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-SCH-012` |
| **Category** | Schema Registration |
| **Tier** | 1 — Schema |
| **Severity** | Error |
| **Apocryphal** | Error (schema always enforced) |
| **Source** | D-10 §8 / D-11 §4.2 |

**Description:** Custom schemas stored in `.chronicle/schema/custom/` must be valid JSON documents. Additionally, custom schemas must:
1. Be a JSON object (not an array, string, or other type)
2. Not redefine the common field names (`type`, `name`, `canon`)
3. Follow the schema structure convention (defining properties, required fields, types, etc.)

If a custom schema file is malformed, structurally invalid, or attempts to override common fields, this rule fails.

**Passing Example (Custom Schema File):**
```json
{
  "type": "object",
  "properties": {
    "artifact_class": {
      "type": "string",
      "enum": ["relic", "enchanted_object", "cursed_item", "divine_artifact"]
    },
    "provenance": {
      "type": "string",
      "description": "Historical origin of the artifact"
    },
    "current_location": {
      "type": "string",
      "description": "Where the artifact is stored or located"
    }
  },
  "required": ["artifact_class"]
}
```

**Failing Example (Invalid JSON):**
```json
{
  "type": "object",
  "properties": {
    "artifact_class": {
      "type": "string"
      "enum": ["relic", "enchanted_object"]
    }
  }
}

(missing comma after "string")
```

**Failing Example (Redefines Common Field):**
```json
{
  "type": "object",
  "properties": {
    "name": {
      "type": "number",
      "description": "Numeric ID instead of string name"
    },
    "artifact_class": {
      "type": "string"
    }
  }
}

(redefines 'name', which is a common field)
```

**Error Message (Invalid JSON):**
```
[ERROR] VAL-SCH-012 — Custom schema file contains invalid JSON: Unexpected token. Check for missing commas, brackets, or quotes. (File: .chronicle/schema/custom/artifact.json)
```

**Error Message (Redefines Common Field):**
```
[ERROR] VAL-SCH-012 — Custom schema attempts to redefine common field 'name'. Common fields (type, name, canon) cannot be redefined. (File: .chronicle/schema/custom/artifact.json)
```

**Remediation:**
1. Validate JSON syntax using a JSON linter (e.g., jsonlint, VS Code JSON validator)
2. Remove any property definitions that conflict with common fields (`type`, `name`, `canon`)
3. Ensure the schema is an object type with a `properties` section defining custom fields
4. Specify the `required` array if additional fields must be present on entries using this schema

---

## Summary: Tier 1 Validation Flow

When a file enters the validation system:

1. **VAL-SCH-001** checks that YAML frontmatter is parseable
2. **VAL-SCH-002** verifies the three common fields exist
3. **VAL-SCH-003** confirms the entity type is registered (warning if not)
4. **VAL-SCH-004** validates the `canon` field value
5. **VAL-SCH-005** ensures type-specific required fields are present
6. **VAL-SCH-006** checks that all field values match their declared types
7. **VAL-SCH-007** validates enum fields (case-insensitive, with auto-normalization notices)
8. **VAL-SCH-008** ensures `last_validated` uses ISO 8601 format
9. **VAL-SCH-009** validates file path field formats
10. **VAL-SCH-010** checks relationship entry structure
11. **VAL-SCH-011** auto-normalizes tags and emits informational notices
12. **VAL-SCH-012** validates custom schema files in `.chronicle/schema/custom/`

**If any of rules 1, 2, 4, 5, 6, 8, 9, 10, or 12 fail (ERROR severity), Tier 2 and Tier 3 validation are skipped for that file.** Rules 3, 7, and 11 (WARNING or INFORMATIONAL severity) allow processing to continue.

---

## §6 — Tier 2 (Structural Validation) Rules

Tier 2 rules assume all files have passed Tier 1 and perform cross-file reference validation and structural graph checks. These rules ensure that the relationship network is internally consistent and that all references point to valid, existing entries. Tier 2 rules run for each file whose Tier 1 checks passed; if any Tier 2 rule fails for a file, that file's Tier 3 checks are skipped.

---

### VAL-REF-001: Reference Target Exists

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-001` |
| **Category** | Cross-Reference Integrity |
| **Tier** | 2 — Structural |
| **Severity** | Error |
| **Apocryphal** | Error (structural integrity enforced) |
| **Source** | D-10 §7.1 |

**Description:** Any field containing a file path reference (`target` in relationships, `supersedes`, `superseded_by`, `parent`, `children`) must point to a file that exists in the chronicle repository. References to nonexistent files break the relationship graph and prevent downstream processing. This rule verifies that all target paths resolve to actual entry files.

**Passing Example:**
```yaml
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/factions/iron-covenant.md
    type: member_of
superseded_by: entities/characters/elena-voss-revised.md
---
```

**Failing Example:**
```yaml
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/factions/nonexistent-faction.md
    type: member_of
---

(entities/factions/nonexistent-faction.md does not exist)
```

**Error Message:**
```
[ERROR] VAL-REF-001 — Reference target 'entities/factions/nonexistent-faction.md' does not exist in the repository. (File: entities/characters/elena-voss.md)
```

**Remediation:** Verify the correct file path of the target entry and update the reference. Use relative paths from the repository root, and confirm the `.md` extension.

---

### VAL-REF-002: Bidirectional Relationship Consistency

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-002` |
| **Category** | Cross-Reference Integrity |
| **Tier** | 2 — Structural |
| **Severity** | Warning |
| **Apocryphal** | Warning |
| **Source** | D-10 §7.1 rule 3 |

**Description:** If a relationship is marked `bidirectional: true`, the target entry should contain a reciprocal relationship pointing back to the source entry with the same relationship type (or a semantically inverse type such as `allies_with` / `allies_with` or `mentor_of` / `mentored_by`). If the reciprocal is missing, a warning is emitted to prompt review. This rule catches asymmetric relationships that should be symmetric.

**Passing Example:**
```yaml
# characters/elena-voss.md
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/characters/marcus-wright.md
    type: allies_with
    bidirectional: true
---

# characters/marcus-wright.md (separate file)
---
type: character
name: Marcus Wright
canon: true
relationships:
  - target: entities/characters/elena-voss.md
    type: allies_with
    bidirectional: true
---
```

**Failing Example (Missing Reciprocal):**
```yaml
# characters/elena-voss.md
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/characters/marcus-wright.md
    type: allies_with
    bidirectional: true
---

# characters/marcus-wright.md (separate file)
---
type: character
name: Marcus Wright
canon: true
---

(Elena declares a bidirectional relationship with Marcus, but Marcus does not reciprocate)
```

**Error Message:**
```
[WARNING] VAL-REF-002 — Bidirectional relationship "allies_with" from "Elena Voss" to "Marcus Wright" has no reciprocal in the target. Consider adding the reciprocal relationship or setting bidirectional: false. (File: entities/characters/elena-voss.md)
```

**Remediation:** Either:
1. Add the reciprocal relationship to the target entry
2. Change `bidirectional: false` if the relationship is intentionally asymmetric
3. Review and clarify the relationship semantics

---

### VAL-REF-003: Supersession Chain Valid

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-003` |
| **Category** | Cross-Reference Integrity |
| **Tier** | 2 — Structural |
| **Severity** | Warning |
| **Apocryphal** | Warning |
| **Source** | D-10 §4.4 |

**Description:** If a file has a `supersedes` or `superseded_by` field, all referenced entries must have the inverse field set. Additionally, chains of supersession should form valid linear or branching structures (no cycles). If supersession references are incomplete or circular, a warning is emitted.

**Passing Example (Linear Chain):**
```yaml
# entities/characters/elena-voss-v1.md
---
type: character
name: Elena Voss (v1)
canon: deprecated
superseded_by: entities/characters/elena-voss-v2.md
---

# entities/characters/elena-voss-v2.md (separate file)
---
type: character
name: Elena Voss (v2)
canon: deprecated
supersedes: entities/characters/elena-voss-v1.md
superseded_by: entities/characters/elena-voss-v3.md
---

# entities/characters/elena-voss-v3.md (separate file)
---
type: character
name: Elena Voss (v3)
canon: true
supersedes: entities/characters/elena-voss-v2.md
---
```

**Failing Example (Incomplete Chain):**
```yaml
# entities/characters/elena-voss-v1.md
---
type: character
name: Elena Voss (v1)
canon: deprecated
superseded_by: entities/characters/elena-voss-v2.md
---

# entities/characters/elena-voss-v2.md (separate file)
---
type: character
name: Elena Voss (v2)
canon: true
---

(v2 declares no 'supersedes' reference back to v1)
```

**Error Message:**
```
[WARNING] VAL-REF-003 — Supersession reference incomplete: "Elena Voss (v1)" declares superseded_by pointing to "Elena Voss (v2)", but the target does not declare supersedes pointing back. (File: entities/characters/elena-voss-v1.md)
```

**Remediation:** Ensure all supersession relationships are bidirectional. Add the missing `supersedes` or `superseded_by` field to the target entry.

---

### VAL-REF-004: Relationship Target Type Sensible

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-004` |
| **Category** | Cross-Reference Integrity |
| **Tier** | 2 — Structural |
| **Severity** | Informational |
| **Apocryphal** | Informational |
| **Source** | D-10 §7.2 rule 2 |

**Description:** Some relationship types are semantically paired with specific entity types (e.g., `member_of` typically targets factions, `participant` targets events). If a relationship type is paired with a mismatched target type, an informational notice is emitted. This is not an error—relationships are flexible by design—but the notice prompts review of intent.

**Passing Example:**
```yaml
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/factions/iron-covenant.md
    type: member_of
  - target: entities/events/the-first-schism.md
    type: participant
---
```

**Failing Example (Type Mismatch):**
```yaml
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/locales/thornhaven.md
    type: member_of
---

(member_of typically targets factions, not locales)
```

**Error Message:**
```
[INFORMATIONAL] VAL-REF-004 — Relationship type "member_of" from character "Elena Voss" targets locale "thornhaven" instead of faction. Verify intent or consider an alternative type (e.g., "resides_in"). (File: entities/characters/elena-voss.md)
```

**Remediation:** Either update the relationship type to a more appropriate semantic (e.g., `resides_in`, `associated_with`) or document the unusual pairing in a `note` field.

---

### VAL-REF-005: Parent-Child Hierarchy Valid

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-005` |
| **Category** | Cross-Reference Integrity |
| **Tier** | 2 — Structural |
| **Severity** | Error |
| **Apocryphal** | Error |
| **Source** | D-10 §4.5 |

**Description:** If an entry declares a `parent` field, that parent must also declare the entry in its `children` list. Similarly, all entries in a `children` array must have the child's `parent` field pointing back to the parent. This rule ensures bidirectional consistency in hierarchical relationships.

**Passing Example:**
```yaml
# entities/events/age-of-echoes.md
---
type: timeline
name: Age of Echoes
canon: true
start: 50 PG
children:
  - entities/events/echoes-arise.md
  - entities/events/echoes-recede.md
---

# entities/events/echoes-arise.md (separate file)
---
type: event
name: Echoes Arise
canon: true
parent: entities/events/age-of-echoes.md
---
```

**Failing Example (Missing Child in Parent List):**
```yaml
# entities/events/age-of-echoes.md
---
type: timeline
name: Age of Echoes
canon: true
start: 50 PG
children:
  - entities/events/echoes-arise.md
---

# entities/events/echoes-recede.md (separate file)
---
type: event
name: Echoes Recede
canon: true
parent: entities/events/age-of-echoes.md
---

(echoes-recede.md declares age-of-echoes.md as parent, but age-of-echoes.md does not list echoes-recede.md in children)
```

**Error Message:**
```
[ERROR] VAL-REF-005 — Entry "Echoes Recede" declares parent "Age of Echoes", but parent does not include child in its children list. (File: entities/events/echoes-recede.md)
```

**Remediation:** Ensure all parent-child relationships are bidirectional:
- If a child declares a parent, the parent must list the child in `children`
- If a parent lists a child, the child must declare the parent in `parent`

---

### VAL-REF-006: Unique Entry Names (Per Type)

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-006` |
| **Category** | Uniqueness |
| **Tier** | 2 — Structural |
| **Severity** | Warning |
| **Apocryphal** | Informational (relaxed per D-11 §9.1) |
| **Source** | D-10 §4.3 |

**Description:** Within the canonical chronicle, each entity `name` should be unique for its `type`. Multiple entries of the same type with identical names can cause ambiguity in references and manual lookups. This rule warns when duplicate names are detected. Apocryphal entries are held to a lower standard (informational) because apocryphal content may intentionally explore alternate versions.

**Passing Example:**
```yaml
# entities/characters/elena-voss.md
---
type: character
name: Elena Voss
canon: true
---

# entities/factions/iron-covenant.md (separate file)
---
type: faction
name: Iron Covenant
canon: true
---

(Both entries exist, but different types allow identical names in different contexts)
```

**Failing Example (Duplicate Names, Same Type):**
```yaml
# entities/characters/elena-voss-v1.md
---
type: character
name: Elena Voss
canon: true
---

# entities/characters/elena-voss-v2.md (separate file)
---
type: character
name: Elena Voss
canon: true
---

(Two canonical characters with identical names)
```

**Error Message:**
```
[WARNING] VAL-REF-006 — Multiple canonical entries of type "character" share the name "Elena Voss". Consider renaming or deprecating one. (File: entities/characters/elena-voss-v2.md)
```

**Remediation:** Rename one of the entries to be more specific, or convert one to deprecated/draft status via the promotion workflow.

---

### VAL-REF-007: Circular Reference Detection

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-007` |
| **Category** | Cross-Reference Integrity |
| **Tier** | 2 — Structural |
| **Severity** | Warning |
| **Apocryphal** | Warning |
| **Source** | D-10 §4.5 rule 3 |

**Description:** Relationships should not form unintended cycles (e.g., A → B → C → A). While some cycles may be intentional (e.g., mutual alliances), deep cycles (3+ hops) may indicate structural issues or broken narratives. This rule detects cycles deeper than 2 hops and warns the author.

**Passing Example (Mutual Alliance — 2-hop cycle, acceptable):**
```yaml
# entities/factions/iron-covenant.md
---
type: faction
name: Iron Covenant
canon: true
relationships:
  - target: entities/factions/silver-order.md
    type: allies_with
---

# entities/factions/silver-order.md (separate file)
---
type: faction
name: Silver Order
canon: true
relationships:
  - target: entities/factions/iron-covenant.md
    type: allies_with
---
```

**Failing Example (Deeper Cycle):**
```yaml
# entities/characters/elena-voss.md
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/factions/iron-covenant.md
    type: member_of
---

# entities/factions/iron-covenant.md (separate file)
---
type: faction
name: Iron Covenant
canon: true
relationships:
  - target: entities/locales/thornhaven.md
    type: headquarters
---

# entities/locales/thornhaven.md (separate file)
---
type: locale
name: Thornhaven
canon: true
relationships:
  - target: entities/characters/elena-voss.md
    type: home_of
---

(A → B → C → A forms a 3-hop cycle)
```

**Error Message:**
```
[WARNING] VAL-REF-007 — Circular reference detected: Elena Voss → Iron Covenant → Thornhaven → Elena Voss (3+ hops). Verify intended relationship structure. (File: entities/characters/elena-voss.md)
```

**Remediation:** Review the chain of relationships and either:
1. Remove one relationship to break the cycle
2. Document the cycle as intentional narrative structure
3. Restructure relationships to clarify cause-and-effect

---

### VAL-REF-008: Relationship Type Format Valid

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-008` |
| **Category** | Cross-Reference Integrity |
| **Tier** | 2 — Structural |
| **Severity** | Error |
| **Apocryphal** | Error |
| **Source** | D-10 §7.2 |

**Description:** Relationship type values must be non-empty strings containing only lowercase letters, digits, and underscores (snake_case). Spaces, uppercase letters, or special characters are invalid. This rule enforces consistent naming conventions across all relationship definitions.

**Passing Example:**
```yaml
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/factions/iron-covenant.md
    type: member_of
  - target: entities/characters/marcus-wright.md
    type: influenced_by_mentor
---
```

**Failing Example (Invalid Format):**
```yaml
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/factions/iron-covenant.md
    type: Member Of
  - target: entities/characters/marcus-wright.md
    type: influenced by mentor
---

(spaces and uppercase letters are invalid)
```

**Error Message:**
```
[ERROR] VAL-REF-008 — Relationship type "Member Of" uses invalid format. Relationship types must be snake_case (lowercase letters, digits, underscores only). (File: entities/characters/elena-voss.md)
```

**Remediation:** Use snake_case for all relationship types:
- `member_of` (not `Member Of`)
- `influenced_by` (not `Influenced By`)
- `predecessor_to` (not `Predecessor To`)

---

### VAL-REF-009: File Path Consistency

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-009` |
| **Category** | Cross-Reference Integrity |
| **Tier** | 2 — Structural |
| **Severity** | Warning |
| **Apocryphal** | Warning |
| **Source** | D-10 §6.5 |

**Description:** File path references should be consistent across the chronicle. If the same target is referenced multiple times in different files, the path format should match exactly. Inconsistent path formats can cause references to fail or be treated as duplicates. This rule detects and warns about path inconsistencies (e.g., `entities/characters/elena-voss.md` vs. `entities/characters/Elena-Voss.md`).

**Passing Example:**
```yaml
# File A
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/factions/iron-covenant.md
    type: member_of
---

# File B
---
type: faction
name: Iron Covenant
canon: true
relationships:
  - target: entities/characters/elena-voss.md
    type: members
---

(Both files reference entities/characters/elena-voss.md consistently)
```

**Failing Example (Inconsistent Paths):**
```yaml
# File A
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/factions/Iron-Covenant.md
    type: member_of
---

# File B
---
type: faction
name: Iron Covenant
canon: true
relationships:
  - target: entities/factions/iron-covenant.md
    type: members
---

(File A references Iron-Covenant, File B references iron-covenant — inconsistent casing)
```

**Error Message:**
```
[WARNING] VAL-REF-009 — Inconsistent file path references to the same target: "Iron-Covenant.md" (File A) vs. "iron-covenant.md" (File B). Standardize path casing and format. (File: entities/characters/elena-voss.md)
```

**Remediation:** Standardize file path references across all files. Prefer lowercase, hyphenated names for consistency with D-10 §6.5.

---

### VAL-REF-010: Relationship Temporal Bounds Valid

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-010` |
| **Category** | Cross-Reference Integrity |
| **Tier** | 2 — Structural |
| **Severity** | Warning |
| **Apocryphal** | Warning |
| **Source** | D-10 §7.1 rule 5 |

**Description:** Relationship `since` and `until` fields must follow the same format as the relationship itself (free-text or structured). If mixed formats are used (one structured, one free-text), a warning is emitted to prompt clarification. Prefer consistency: either use free-text dates for both or structured dates for both.

**Passing Example (Consistent Free-Text):**
```yaml
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/factions/iron-covenant.md
    type: member_of
    since: "After the First Schism"
    until: "The Great Betrayal"
---
```

**Passing Example (Consistent Structured):**
```yaml
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/factions/iron-covenant.md
    type: member_of
    since: 180 PG
    until: 210 PG
---
```

**Failing Example (Mixed Formats):**
```yaml
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/factions/iron-covenant.md
    type: member_of
    since: "After the First Schism"
    until: 210 PG
---

(Mixed free-text and structured dates)
```

**Error Message:**
```
[WARNING] VAL-REF-010 — Relationship temporal bounds mix formats: since uses free-text, until uses structured (210 PG). Standardize to one format for clarity. (File: entities/characters/elena-voss.md)
```

**Remediation:** Use consistent date formats for both `since` and `until`:
- Either both free-text: `"After the First Schism"` and `"The Great Betrayal"`
- Or both structured: `180 PG` and `210 PG`

---

### VAL-REF-011: Locale Containment Valid

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-011` |
| **Category** | Multi-File Entity Consistency |
| **Tier** | 2 — Structural |
| **Severity** | Warning |
| **Apocryphal** | Warning |
| **Source** | D-10 §4.5 rule 2 |

**Description:** If a locale (geographic location) declares child locales (e.g., a city contains districts), the hierarchy should follow geographic containment logic. A locale cannot be its own ancestor, and child locales should be geographically contained within the parent. While this rule cannot verify geographic accuracy, it checks for obvious structural impossibilities (e.g., a continent being contained within a city).

**Passing Example:**
```yaml
# entities/locales/aethelgard.md
---
type: locale
name: Aethelgard
canon: true
children:
  - entities/locales/thornhaven.md
  - entities/locales/silver-reach.md
---

# entities/locales/thornhaven.md (separate file)
---
type: locale
name: Thornhaven
canon: true
parent: entities/locales/aethelgard.md
children:
  - entities/locales/thornhaven-harbor.md
---
```

**Failing Example (Self-Containment):**
```yaml
# entities/locales/aethelgard.md
---
type: locale
name: Aethelgard
canon: true
parent: entities/locales/aethelgard.md
children:
  - entities/locales/thornhaven.md
---

(Aethelgard cannot be its own parent)
```

**Error Message:**
```
[WARNING] VAL-REF-011 — Locale "Aethelgard" creates self-containment cycle (parent: Aethelgard, children include: Thornhaven). Verify hierarchical structure. (File: entities/locales/aethelgard.md)
```

**Remediation:** Remove the self-referential parent declaration or fix the hierarchy.

---

### VAL-REF-012: Required Cross-Reference Fields

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-012` |
| **Category** | Cross-Reference Integrity |
| **Tier** | 2 — Structural |
| **Severity** | Error |
| **Apocryphal** | Error |
| **Source** | D-10 §4.4 |

**Description:** Entries with certain `type` values may require cross-reference fields to ensure proper graph connectivity. For example, an entry with `canon: deprecated` should always have a `superseded_by` field pointing to its replacement. This rule enforces that required cross-reference fields are present based on entry status and type.

**Passing Example:**
```yaml
---
type: character
name: Elena Voss (v1)
canon: deprecated
superseded_by: entities/characters/elena-voss-v2.md
---
```

**Failing Example (Missing Cross-Reference):**
```yaml
---
type: character
name: Elena Voss (v1)
canon: deprecated
---

(missing superseded_by field for deprecated entry)
```

**Error Message:**
```
[ERROR] VAL-REF-012 — Deprecated entry "Elena Voss (v1)" does not declare a superseded_by field. Deprecated entries must point to their replacements. (File: entities/characters/elena-voss-v1.md)
```

**Remediation:** Add the required cross-reference field:
- For `canon: deprecated`: add `superseded_by: path/to/replacement.md`

---

### VAL-REF-013: Relationship Target Canon Exists

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-013` |
| **Category** | Cross-Reference Integrity |
| **Tier** | 2 — Structural |
| **Severity** | Error |
| **Apocryphal** | Error |
| **Source** | D-10 §7.1 |

**Description:** Some relationships define an optional `target_canon` field that explicitly declares the canonical status of the target entry (for reference or caching purposes). If `target_canon` is present, the actual canonical status of the target entry must match the declared value. This rule validates that `target_canon` assertions are accurate.

**Passing Example:**
```yaml
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/factions/iron-covenant.md
    type: member_of
    target_canon: true
---
```

**Failing Example (Mismatched Canon Status):**
```yaml
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/factions/nonexistent-group.md
    type: member_of
    target_canon: true
---

(The target is either nonexistent or has different canon status than declared)
```

**Error Message:**
```
[ERROR] VAL-REF-013 — Relationship target_canon (true) does not match actual entry canon status. Target "nonexistent-group.md" has canon: false or does not exist. (File: entities/characters/elena-voss.md)
```

**Remediation:** Either update `target_canon` to match the actual entry status, or verify that the target file exists and update its `canon` field if needed.

---

### VAL-REF-014: Schema-Aware Relationship Validation

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-014` |
| **Category** | Cross-Reference Integrity |
| **Tier** | 2 — Structural |
| **Severity** | Warning |
| **Apocryphal** | Warning |
| **Source** | D-10 §7 |

**Description:** Relationship validation respects custom schemas. If a custom schema defines a `relationships` field with specific constraints (e.g., allowed types, required fields), those constraints are applied during Tier 2 validation. If a relationship violates schema-defined constraints, a warning is emitted.

**Passing Example:**
```yaml
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/factions/iron-covenant.md
    type: member_of
    note: "Founding member"
---
```

**Failing Example (Violates Custom Schema):**
```yaml
---
type: character
name: Elena Voss
canon: true
relationships:
  - target: entities/factions/iron-covenant.md
    type: unknown_relationship
---

(Custom schema for 'character' type may not allow 'unknown_relationship')
```

**Error Message:**
```
[WARNING] VAL-REF-014 — Relationship type "unknown_relationship" violates constraints defined in custom schema for character type. (File: entities/characters/elena-voss.md)
```

**Remediation:** Check the custom schema for the entry type and use only allowed relationship types, or extend the schema if a new type is needed.

---

### VAL-REF-015: Multi-File Entry Completeness

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-015` |
| **Category** | Multi-File Entity Consistency |
| **Tier** | 2 — Structural |
| **Severity** | Warning |
| **Apocryphal** | Warning |
| **Source** | D-10 §4.6 |

**Description:** Some entities may be split across multiple files (e.g., a faction with separate files for each leader, or a timeline with separate files for each era). If a multi-file entity declares a `components` or `parts` field listing related entries, all listed entries should be present and should reciprocally declare their parent. This rule ensures that multi-file entities are complete and bidirectionally referenced.

**Passing Example:**
```yaml
# entities/factions/iron-covenant.md
---
type: faction
name: Iron Covenant
canon: true
components:
  - entities/factions/iron-covenant-leadership.md
  - entities/factions/iron-covenant-divisions.md
---

# entities/factions/iron-covenant-leadership.md (separate file)
---
type: entity
name: Iron Covenant Leadership
canon: true
parent: entities/factions/iron-covenant.md
---
```

**Failing Example (Incomplete Multi-File Entity):**
```yaml
# entities/factions/iron-covenant.md
---
type: faction
name: Iron Covenant
canon: true
components:
  - entities/factions/iron-covenant-leadership.md
  - entities/factions/iron-covenant-divisions.md
---

# entities/factions/iron-covenant-leadership.md (separate file exists)
---
type: entity
name: Iron Covenant Leadership
canon: true
---

# entities/factions/iron-covenant-divisions.md (missing file)
```

**Error Message:**
```
[WARNING] VAL-REF-015 — Multi-file entity "Iron Covenant" declares component "iron-covenant-divisions.md" that does not exist. Complete or remove the component reference. (File: entities/factions/iron-covenant.md)
```

**Remediation:** Either create the missing component file or remove it from the `components` list. Ensure all components declare their parent relationship.

---

### VAL-REF-016: Branch Convention — Draft on Main

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-016` |
| **Category** | Branch Conventions |
| **Tier** | 2 — Structural |
| **Severity** | Warning |
| **Apocryphal** | N/A (rule checks for draft status specifically) |
| **Source** | D-11 §7.2 |

**Description:** When `chronicle validate` runs on the `main` branch (or the configured `canonical_branch` from `.chronicle/config.yaml`), files with `canon: false` (draft status) are flagged. The `main` branch should contain only canonical (`canon: true`) or deprecated (`canon: "deprecated"`) content. Draft content on `main` suggests an unpromoted file that should either be promoted via `chronicle promote` or moved to a feature branch.

This is a soft convention enforced per D-11 §7.2 — it does not block validation, but emits a warning to alert the author. The configured branch name is read from `.chronicle/config.yaml` under `branch_conventions.canonical_branch` (default: `main`). If Git context is unavailable (non-Git directory, detached HEAD), this check is silently skipped.

**Passing Example:**
```yaml
# On branch: main
---
type: character
name: Elena Voss
canon: true
---
```

**Failing Example:**
```yaml
# On branch: main
---
type: character
name: Elena Voss
canon: false
---

(Draft content detected on main branch)
```

**Error Message:**
```
[WARNING] VAL-REF-016 — Draft content detected on main: "Elena Voss" has canon: false. Run 'chronicle promote' to update, or move to a feature branch. (File: entities/characters/elena-voss.md)
```

**Remediation:** Either promote the entry to canonical status using `chronicle promote`, or move it to a feature branch for continued drafting. Draft content on `main` may confuse consumers who expect only canonical or deprecated entries.

---

### VAL-REF-017: Branch Convention — Non-Apocryphal on Apocrypha Branch

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-REF-017` |
| **Category** | Branch Conventions |
| **Tier** | 2 — Structural |
| **Severity** | Informational |
| **Apocryphal** | N/A (rule checks branch context, not canon modifier) |
| **Source** | D-11 §7.2 |

**Description:** When `chronicle validate` runs on a branch matching the `apocryphal_pattern` (default: `apocrypha/*` from `.chronicle/config.yaml`), files with `canon: true` or `canon: false` are flagged with an informational notice. The `apocrypha/*` branch pattern is conventionally reserved for explicitly non-canonical exploration content (alternate timelines, cut content, speculative entries). Finding canonical or draft content on such a branch suggests the file may be misplaced or needs its status updated.

This is a soft convention — it emits an informational notice, not an error or warning. If Git context is unavailable, this check is silently skipped.

**Passing Example:**
```yaml
# On branch: apocrypha/iron-covenant-alternate
---
type: faction
name: Iron Covenant (Alternate)
canon: "apocryphal"
---
```

**Failing Example:**
```yaml
# On branch: apocrypha/iron-covenant-alternate
---
type: faction
name: Iron Covenant (Alternate)
canon: true
---

(Canonical content on apocryphal branch)
```

**Error Message:**
```
[INFORMATIONAL] VAL-REF-017 — File "Iron Covenant (Alternate)" has canon status 'true' on apocryphal branch 'apocrypha/iron-covenant-alternate'. Consider setting canon: "apocryphal" or moving to a feature branch. (File: entities/factions/iron-covenant-alternate.md)
```

**Remediation:** Either update the entry's `canon` field to `"apocryphal"` (if this is intended as non-canonical exploration), or move the file to a feature branch or `main` (if it should be canonical or draft).

---

## Summary: Tier 2 Validation

Tier 2 rules validate the integrity of cross-file references and structural relationships:

| Rule | Focus | Severity |
|---|---|---|
| VAL-REF-001 | Target existence | Error |
| VAL-REF-002 | Bidirectional consistency | Warning |
| VAL-REF-003 | Supersession chains | Warning |
| VAL-REF-004 | Relationship type sensibility | Informational |
| VAL-REF-005 | Parent-child hierarchy | Error |
| VAL-REF-006 | Name uniqueness | Warning |
| VAL-REF-007 | Circular references | Warning |
| VAL-REF-008 | Relationship type format | Error |
| VAL-REF-009 | Path consistency | Warning |
| VAL-REF-010 | Temporal bounds consistency | Warning |
| VAL-REF-011 | Locale containment | Warning |
| VAL-REF-012 | Cross-reference requirements | Error |
| VAL-REF-013 | Target canon accuracy | Error |
| VAL-REF-014 | Schema-aware relationship | Warning |
| VAL-REF-015 | Multi-file entity completeness | Warning |
| VAL-REF-016 | Branch convention — draft on main | Warning |
| VAL-REF-017 | Branch convention — non-apocryphal on apocrypha/* | Informational |

---

## §7: Tier 3 (Semantic Validation) Rules

Tier 3 validation rules perform narrative logic and semantic checks on the Aethelgard canonical chronicle. These rules assume the input has passed Tier 1 (schema validation) and Tier 2 (structural graph validation). Tier 3 rules enforce five logical categories:

1. **Canon Consistency (VAL-CAN-xxx):** Relationships between canonical, draft, apocryphal, and deprecated content states.
2. **Timeline Consistency (VAL-TMP-xxx):** Temporal ordering and era boundary checks (per OQ-D12-5, structured dates only).
3. **Axiom Enforcement (VAL-AXM-xxx):** Deterministic and soft-check validation of axiom entries per D-10 §5.8 and OQ-D12-1.
4. **Relationship Vocabulary (VAL-VOC-xxx):** Informational notices for non-standard relationship types per D-10 §7.2–§7.3.

**Key Design Principles:**
- Free-text date comparison is not supported (OQ-D12-5). Temporal checks activate only when both sides provide machine-parseable data (structured YAML numbers in PG format). Free-text dates are skipped with an informational notice.
- Axiom assertions use three structured rule types: `temporal_bound`, `value_constraint`, `pattern_match` (OQ-D12-1).
- Apocryphal severity modifiers apply per D-11 §9.1: hard axiom violations and timeline inconsistencies are skipped for apocryphal entries, while canon consistency checks do not fire for apocryphal sources.

---

## Canon Consistency Rules

### VAL-CAN-001: Canonical References Draft Content

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-CAN-001` |
| **Category** | Canon Consistency |
| **Tier** | 3 — Semantic |
| **Severity** | Warning |
| **Apocryphal** | N/A (rule only fires for canonical source) |
| **Source** | D-10 §7.5 rule 4, D-11 §9.2 row 1 |

**Description:** A canonical file (`canon: true`) that has a relationship targeting a draft file (`canon: false`) is flagged for review. Draft content represents work-in-progress entries that may be incomplete, unvetted, or subject to removal. Canonical entries should reference only stable, validated content.

**Passing Example:**
```yaml
# characters/elena-voss.md
---
type: character
name: Elena Voss
canon: true
relationships:
  - type: member_of
    target: entities/factions/iron-covenant.md
    target_canon: true
---
Elena Voss is a founding member of the Iron Covenant.
```

**Failing Example:**
```yaml
# characters/elena-voss.md
---
type: character
name: Elena Voss
canon: true
relationships:
  - type: influenced_by
    target: entities/characters/theorist-unnamed.md
    target_canon: false
---
Elena Voss was influenced by an unnamed theorist.
```

**Error Message:**
```
[WARNING] VAL-CAN-001 — Canonical entry "Elena Voss" references draft entry "theorist-unnamed". Consider promoting the target to canonical or removing the reference. (File: characters/elena-voss.md)
```

**Remediation:** Either promote the target entry (`canon: false` → `canon: true`) via the chronicle validation workflow, remove the relationship, or downgrade the source to draft status if the reference is speculative.

---

### VAL-CAN-002: Canonical References Apocryphal Content

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-CAN-002` |
| **Category** | Canon Consistency |
| **Tier** | 3 — Semantic |
| **Severity** | Warning |
| **Apocryphal** | N/A (rule only fires for canonical source) |
| **Source** | D-10 §7.5 rule 4, D-11 §9.2 row 2 |

**Description:** A canonical file that has a relationship targeting an apocryphal file is flagged. Apocryphal entries represent alternate timelines, hypothetical scenarios, or rejected narratives. Canonical content should not depend on apocryphal possibilities.

**Passing Example:**
```yaml
# events/the-arcane-purges.md
---
type: event
name: The Arcane Purges
canon: true
start: 180 PG
end: 200 PG
relationships:
  - type: participant
    target: entities/factions/iron-covenant.md
    target_canon: true
---
The Iron Covenant played a crucial role in the Arcane Purges.
```

**Failing Example:**
```yaml
# events/the-arcane-purges.md
---
type: event
name: The Arcane Purges
canon: true
start: 180 PG
end: 200 PG
relationships:
  - type: alternative_outcome
    target: entities/events/purges-alternate-timeline-a.md
    target_canon: apocryphal
---
In an alternate timeline, the Purges ended differently.
```

**Error Message:**
```
[WARNING] VAL-CAN-002 — Canonical entry "The Arcane Purges" references apocryphal entry "purges-alternate-timeline-a". Canonical narrative should not depend on apocryphal possibilities. (File: events/the-arcane-purges.md)
```

**Remediation:** Remove the relationship to the apocryphal entry, or convert the relationship into a separate apocryphal file that references the canonical entry instead (inverting the direction of canonical dependency).

---

### VAL-CAN-003: Canonical References Deprecated Content

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-CAN-003` |
| **Category** | Canon Consistency |
| **Tier** | 3 — Semantic |
| **Severity** | Warning |
| **Apocryphal** | N/A (rule only fires for canonical source) |
| **Source** | D-10 §7.5 rule 4, D-11 §9.2 row 3 |

**Description:** A canonical file that references a deprecated file is flagged with replacement guidance. Deprecated entries have been superseded by newer canonical content (via the `supersedes` field). Canonical entries should reference the replacement entry instead.

**Passing Example:**
```yaml
# characters/elena-voss-v2.md
---
type: character
name: Elena Voss (Revised)
canon: true
relationships:
  - type: member_of
    target: entities/factions/iron-covenant.md
    target_canon: true
---
Elena Voss leads the Iron Covenant.
```

**Failing Example:**
```yaml
# characters/elena-voss-v2.md
---
type: character
name: Elena Voss (Revised)
canon: true
relationships:
  - type: predecessor_to
    target: entities/characters/elena-voss-v1.md
    target_canon: deprecated
    target_supersedes: elena-voss-v2
---
This version replaces an earlier draft.
```

**Error Message:**
```
[WARNING] VAL-CAN-003 — Canonical entry "Elena Voss (Revised)" references deprecated entry "elena-voss-v1"; review when replacement "elena-voss-v2" is promoted. Consider updating references to the current canonical version. (File: characters/elena-voss-v2.md)
```

**Remediation:** Review the deprecated entry's `supersedes` field to identify the replacement canonical entry. Update the relationship to target the replacement instead, or document why the historical reference is necessary.

---

### VAL-CAN-004: Child Canon Hierarchy

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-CAN-004` |
| **Category** | Canon Consistency |
| **Tier** | 3 — Semantic |
| **Severity** | Error |
| **Apocryphal** | Error |
| **Source** | D-10 §4.7, D-11 §11.1 |

**Description:** A child document cannot have a higher canonical status than its parent. Specifically: a draft parent (`canon: false`) cannot have a canonical child (`canon: true`), and a canonical parent (`canon: true`) cannot have a deprecated child (`canon: deprecated`). A canonical parent with an apocryphal child triggers a warning (not an error). This rule enforces hierarchical consistency in the chronicle graph.

**Passing Example:**
```yaml
# eras/age-of-echoes.md
---
type: timeline
name: Age of Echoes
canon: true
start: 50 PG
end: 210 PG
children:
  - entities/events/echoes-arise.md
  - entities/events/echoes-recede.md
---
The Age of Echoes spanned from 50 PG to 210 PG.
```

**Failing Example (Draft Parent, Canonical Child):**
```yaml
# eras/age-of-echoes-draft.md
---
type: timeline
name: Age of Echoes (Draft)
canon: false
children:
  - entities/events/echoes-arise-canonical.md
---
# In events/echoes-arise-canonical.md:
---
type: event
name: Echoes Arise
canon: true
parent: entities/timelines/age-of-echoes-draft.md
---
```

**Error Message:**
```
[ERROR] VAL-CAN-004 — Child document "events/echoes-arise-canonical.md" (canon: true) cannot have higher status than parent "eras/age-of-echoes-draft.md" (canon: false). Promote parent to canonical or downgrade child to draft. (File: events/echoes-arise-canonical.md)
```

**Remediation:** Promote the parent to canonical status (`canon: true`) or downgrade the child to match the parent's status. For apocryphal children under canonical parents, consider promoting the child or converting the relationship to an apocryphal variant.

---

### VAL-CAN-005: Replacement Promotion Predecessor Check

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-CAN-005` |
| **Category** | Canon Consistency |
| **Tier** | 3 — Semantic |
| **Severity** | Warning |
| **Apocryphal** | N/A (promotion is a canonical action) |
| **Source** | D-11 §9.3 rule 1 |

**Description:** When a file with a `supersedes` field is promoted from draft to canonical (`chronicle promote`), all entries in the `supersedes` array should be marked as `canon: deprecated`. If any superseded entry remains in draft or canonical status, a warning is emitted to ensure clean replacement semantics.

**Passing Example:**
```yaml
# characters/elena-voss-v2.md
---
type: character
name: Elena Voss (Revised)
canon: true
supersedes:
  - entities/characters/elena-voss-v1.md
---
This is the authoritative version of Elena Voss.

# characters/elena-voss-v1.md (separate file)
---
type: character
name: Elena Voss
canon: deprecated
superseded_by: entities/characters/elena-voss-v2.md
---
```

**Failing Example:**
```yaml
# characters/elena-voss-v2.md
---
type: character
name: Elena Voss (Revised)
canon: true
supersedes:
  - entities/characters/elena-voss-v1.md
---
This is the authoritative version of Elena Voss.

# characters/elena-voss-v1.md (separate file)
---
type: character
name: Elena Voss
canon: true  # Should be deprecated!
superseded_by: entities/characters/elena-voss-v2.md
---
```

**Error Message:**
```
[WARNING] VAL-CAN-005 — Entry "elena-voss-v2.md" is promoted to canonical but supersedes "elena-voss-v1.md", which is still marked canon: true. Mark the superseded entry as deprecated (canon: deprecated). (File: characters/elena-voss-v2.md)
```

**Remediation:** Update all entries listed in `supersedes` to set `canon: deprecated`. Add a `superseded_by` field pointing to the new canonical entry.

---

## Timeline Consistency Rules

### VAL-TMP-001: Timeline Era Boundary Order

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-TMP-001` |
| **Category** | Timeline Consistency |
| **Tier** | 3 — Semantic |
| **Severity** | Warning |
| **Apocryphal** | Skipped |
| **Source** | D-10 §5.6 |

**Description:** For timeline or era entities, if both `start` and `end` are machine-parseable (structured numeric dates in PG format, e.g., `50 PG`, `210 PG`), the `end` date must be temporally after the `start` date. Free-text dates (e.g., "sometime after the First Schism") are not machine-parseable and are skipped with an informational notice per OQ-D12-5. This rule does not apply to apocryphal entries, which may explore alternate chronologies.

**Passing Example:**
```yaml
# eras/age-of-echoes.md
---
type: timeline
name: Age of Echoes
canon: true
start: 50 PG
end: 210 PG
---
The Age of Echoes was a period of great change, spanning 160 years.
```

**Failing Example:**
```yaml
# eras/age-of-shadows.md
---
type: timeline
name: Age of Shadows
canon: true
start: 250 PG
end: 150 PG
---
The Age of Shadows is temporally malformed.
```

**Error Message:**
```
[WARNING] VAL-TMP-001 — Timeline "Age of Shadows" has end date (150 PG) before start date (250 PG). Verify temporal bounds. (File: eras/age-of-shadows.md)
```

**Remediation:** Verify the intended chronology and correct the `start` and `end` dates so that `end` > `start`. If the timeline describes an alternate or paradoxical timeline, convert the entry to apocryphal status (`canon: apocryphal`) or clarify the temporal logic in a note field.

---

### VAL-TMP-002: Relationship Temporal Order

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-TMP-002` |
| **Category** | Timeline Consistency |
| **Tier** | 3 — Semantic |
| **Severity** | Warning |
| **Apocryphal** | Skipped |
| **Source** | D-10 §7.5 rule 5 |

**Description:** If a relationship has both `since` and `until` fields with machine-parseable dates (structured numeric PG values), the `until` date must be temporally after the `since` date. Free-text temporal descriptors are skipped with an informational notice per OQ-D12-5. This rule does not apply to apocryphal relationships.

**Passing Example:**
```yaml
# characters/elena-voss.md
---
type: character
name: Elena Voss
canon: true
relationships:
  - type: member_of
    target: entities/factions/iron-covenant.md
    since: 180 PG
    until: 210 PG
---
Elena Voss was a member of the Iron Covenant for thirty years.
```

**Failing Example:**
```yaml
# characters/elena-voss.md
---
type: character
name: Elena Voss
canon: true
relationships:
  - type: member_of
    target: entities/factions/iron-covenant.md
    since: 210 PG
    until: 180 PG
---
Elena Voss was a member of the Iron Covenant.
```

**Error Message:**
```
[WARNING] VAL-TMP-002 — Relationship "member_of" in "Elena Voss" has until (180 PG) before since (210 PG). Verify the relationship duration. (File: characters/elena-voss.md)
```

**Remediation:** Correct the `since` and `until` dates so that `until` > `since`, or clarify the relationship as a one-time event (remove temporal bounds) or convert it to an apocryphal variant if temporal paradox is intentional.

---

## Axiom Enforcement Rules

### VAL-AXM-001: Hard Axiom Deterministic Enforcement

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-AXM-001` |
| **Category** | Axiom Enforcement |
| **Tier** | 3 — Semantic |
| **Severity** | Error |
| **Apocryphal** | Skipped |
| **Source** | D-10 §5.8, OQ-D12-1 |

**Description:** Axiom entries with `enforcement: "hard"` and a valid `assertion_rule` are checked deterministically using three rule types: `temporal_bound`, `value_constraint`, and `pattern_match` (per OQ-D12-1). Hard axioms represent absolute truths in the canonical chronicle and violations are errors. If an `assertion_rule` is not provided or uses an unrecognized type, the axiom is flagged as "not machine-checkable" (informational). This rule does not apply to apocryphal entries.

**Passing Example:**
```yaml
# axioms/no-mortal-aetherium-exposure.md
---
type: axiom
name: No Mortal Can Survive Direct Aetherium Exposure
canon: true
enforcement: hard
assertion_rule:
  type: pattern_match
  field: cause_of_death
  pattern: /aetherium/i
  violation: "mortal character survived direct aetherium exposure"
---
This axiom protects the fundamental vulnerability of mortals to aetherium.
```

**Failing Example (Assertion Broken):**
```yaml
# characters/elena-voss.md
---
type: character
name: Elena Voss
canon: true
cause_of_death: "Survived a direct aetherium explosion"
---
Elena Voss miraculously survived direct aetherium exposure.
```

**Error Message:**
```
[ERROR] VAL-AXM-001 — Hard axiom "No Mortal Can Survive Direct Aetherium Exposure" violated. Character "Elena Voss" has cause_of_death matching the forbidden pattern. (File: characters/elena-voss.md)
```

**Remediation:** Either revise the character entry to comply with the axiom (remove the contradiction) or, if intentional, petition for axiom amendment through the chronicle governance process (D-11 §10).

---

### VAL-AXM-002: Soft Axiom LLM Flag

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-AXM-002` |
| **Category** | Axiom Enforcement |
| **Tier** | 3 — Semantic |
| **Severity** | Informational |
| **Apocryphal** | Skipped |
| **Source** | D-10 §5.8, D-14 (future) |

**Description:** Axiom entries with `enforcement: "soft"` are flagged for LLM deep-check during `chronicle validate --deep` operations (per D-14 integration). No deterministic validation is performed at Tier 3; soft axioms require contextual semantic analysis beyond structured pattern matching. An informational notice is emitted indicating that the axiom exists and will be checked during deep validation.

**Passing Example:**
```yaml
# axioms/glitch-occurred-at-year-zero.md
---
type: axiom
name: The Glitch Occurred at Year 0 PG
canon: true
enforcement: soft
assertion_rule:
  type: temporal_bound
  field: established_date
  boundary: 0 PG
  relation: equals
  note: "The Glitch marks the start of the Post-Glitch calendar; soft enforcement allows exploration of pre-Glitch references."
---
This axiom grounds the Aethelgard timeline.
```

**Failing Example (Will Be Flagged for Deep Check):**
```yaml
# events/pre-glitch-artifact-discovery.md
---
type: event
name: Discovery of Pre-Glitch Artifacts
canon: true
established_date: -50 PG
---
Artifacts predate the Glitch by fifty years.
```

**Error Message:**
```
[INFORMATIONAL] VAL-AXM-002 — Soft axiom "The Glitch Occurred at Year 0 PG" flagged for LLM deep-check. Entry "Discovery of Pre-Glitch Artifacts" may violate temporal boundary. Run 'chronicle validate --deep' for semantic analysis. (File: events/pre-glitch-artifact-discovery.md)
```

**Remediation:** Run `chronicle validate --deep` to obtain LLM-based validation. Review the deep-check report for semantic violations. If the entry legitimately represents pre-Glitch material, document the narrative rationale (e.g., recovered historical records) and re-run validation.

---

## Relationship Vocabulary Rule

### VAL-VOC-001: Relationship Type Vocabulary Notice

| Attribute | Value |
|---|---|
| **Rule ID** | `VAL-VOC-001` |
| **Category** | Relationship Vocabulary |
| **Tier** | 3 — Semantic |
| **Severity** | Informational |
| **Apocryphal** | Informational |
| **Source** | D-10 §7.2, §7.3 |

**Description:** If a relationship `type` is not in D-10 §7.2's recommended vocabulary (e.g., `member_of`, `participant`, `influenced_by`, `oversees`, `predecessor_to`, `alternative_outcome`), an informational notice is emitted. This rule is explicitly informational and not an error or warning. Free-form relationship types are allowed per D-10 §7.3 and may represent domain-specific or narrative relationships not yet standardized. The notice helps contributors discover potential vocabulary mismatches without blocking validation.

**Passing Example:**
```yaml
# characters/elena-voss.md
---
type: character
name: Elena Voss
canon: true
relationships:
  - type: member_of
    target: entities/factions/iron-covenant.md
  - type: influenced_by
    target: entities/events/first-schism.md
  - type: oversees
    target: entities/entities/covenant-research-division.md
---
Elena Voss has multiple standard relationships.
```

**Failing Example (Non-Standard Type):**
```yaml
# characters/elena-voss.md
---
type: character
name: Elena Voss
canon: true
relationships:
  - type: vaguely_aware_of
    target: entities/factions/some-distant-faction.md
---
Elena Voss has a non-standard relationship type.
```

**Error Message:**
```
[INFORMATIONAL] VAL-VOC-001 — Relationship type "vaguely_aware_of" in "Elena Voss" is not in the D-10 §7.2 recommended vocabulary. Consider using a standard type (e.g., influenced_by, related_to) or documenting the custom type. (File: characters/elena-voss.md)
```

**Remediation:** Either adopt a standard relationship type from D-10 §7.2, or document the custom type in the chronicle's type registry (D-10 §7.3 extension process). Custom types are valid but should be intentional and documented.

---

## Summary of Tier 3 Severity Distribution

| Rule | Severity | Apocryphal Behavior |
|---|---|---|
| VAL-CAN-001 | Warning | N/A (canonical source only) |
| VAL-CAN-002 | Warning | N/A (canonical source only) |
| VAL-CAN-003 | Warning | N/A (canonical source only) |
| VAL-CAN-004 | Error | Error (preserved) |
| VAL-CAN-005 | Warning | N/A (canonical action) |
| VAL-TMP-001 | Warning | Skipped |
| VAL-TMP-002 | Warning | Skipped |
| VAL-AXM-001 | Error | Skipped |
| VAL-AXM-002 | Informational | Skipped |
| VAL-VOC-001 | Informational | Informational |

---

## §8 Apocryphal Relaxation Modifier

Per D-11 §9.1, apocryphal entries (`canon: "apocryphal"`) are subject to relaxed validation constraints. The following table shows how severity changes for apocryphal source entries:

| Check Category | Canonical/Draft | Apocryphal | Rationale |
|---|---|---|---|
| Schema validation | Error | Error (enforced) | Chronicle must parse and index apocryphal content |
| Cross-reference integrity | Error | Warning (relaxed) | May reference nonexistent entries |
| Timeline consistency | Warning | Skipped | May explore alternate chronologies |
| Axiom enforcement — hard | Error | Skipped | May violate truths by design |
| Axiom enforcement — soft | Warning | Skipped | For canonical contradiction detection |
| Canon consistency | Warning | No change | Protects canonical side, not apocryphal |
| Uniqueness constraints | Warning | Informational (relaxed) | May create intentional duplicates |

### Affected Tier 1 Rules

All Tier 1 rules remain ERROR severity for apocryphal entries. Schema validity is enforced uniformly.

### Affected Tier 2 Rules

- **VAL-REF-001** (Reference Target Exists): Warning (relaxed from Error) for apocryphal sources
- **VAL-REF-003** (Supersession Chain Valid): Warning → no change
- **VAL-REF-006** (Unique Entry Names): Informational (relaxed from Warning) for apocryphal entries
- **VAL-REF-007** (Circular Reference Detection): Warning → no change
- **VAL-REF-012** (Required Cross-Reference Fields): Warning (relaxed from Error) for apocryphal sources
- **VAL-REF-013** (Relationship Target Canon Exists): Warning (relaxed from Error) for apocryphal sources

### Affected Tier 3 Rules

- **VAL-CAN-001 through VAL-CAN-003**: N/A (do not fire for apocryphal sources)
- **VAL-CAN-004** (Child Canon Hierarchy): Error → no change (preservation of hierarchy)
- **VAL-TMP-001** (Timeline Era Boundary Order): Warning → Skipped
- **VAL-TMP-002** (Relationship Temporal Order): Warning → Skipped
- **VAL-AXM-001** (Hard Axiom Enforcement): Error → Skipped
- **VAL-AXM-002** (Soft Axiom Flag): Informational → Skipped
- **VAL-VOC-001** (Relationship Vocabulary Notice): Informational → no change

---

## §9 Assertion Rule Type Definitions

From OQ-D12-1, the Chronicle validation system supports three structured YAML rule types for deterministic axiom assertion checking. These types are used in the `assertion_rule` field of axiom entries (D-10 §5.8).

### Type 1: temporal_bound

Checks date/era boundaries. Used to enforce temporal constraints on entries.

**Schema:**
```yaml
assertion_rule:
  type: temporal_bound
  field: <field_name>           # Target field name (e.g., "birth_year", "established_date")
  boundary: <numeric_pg_value>  # Numeric PG value (e.g., 0, 180, 210)
  relation: <relation_type>     # One of: before, after, equals, between
  boundary_end: <numeric_pg_value>  # Optional; required when relation: between
  note: <string>                # Optional; human-readable explanation
```

**Relation Types:**
- `before`: Field value must be strictly before boundary
- `after`: Field value must be strictly after boundary
- `equals`: Field value must equal boundary
- `between`: Field value must be between boundary and boundary_end (inclusive)

**Calendar System:** PG (Post-Glitch). Year 0 PG marks the Glitch event. Negative values (e.g., -50 PG) represent pre-Glitch dates.

**Full Example:**
```yaml
---
type: axiom
name: The Glitch Occurred at Year 0 PG
canon: true
axiom_type: metaphysical
enforcement: soft
assertion_rule:
  type: temporal_bound
  field: established_date
  boundary: 0
  relation: equals
  note: "The Glitch marks the absolute beginning of recorded time in Aethelgard."
---
The Glitch is the foundational event of Aethelgard's chronology.
```

---

### Type 2: value_constraint

Checks field values against conditions. Used to enforce value restrictions, existence checks, and conditional logic.

**Schema:**
```yaml
assertion_rule:
  type: value_constraint
  field: <field_name>           # Target field name (e.g., "status", "faction")
  operator: <operator_type>     # One of: equals, not_equals, one_of, not_one_of, exists, not_exists
  value: <value_or_list>        # Expected value(s); list for one_of/not_one_of, null for exists/not_exists
  when: <conditional_map>       # Optional; condition map {field: X, operator: Y, value: Z}
  note: <string>                # Optional; human-readable explanation
```

**Operator Types:**
- `equals`: Field value must equal specified value
- `not_equals`: Field value must not equal specified value
- `one_of`: Field value must be one of the specified values (list)
- `not_one_of`: Field value must not be one of the specified values (list)
- `exists`: Field must be present (value ignored)
- `not_exists`: Field must not be present (value ignored)

**Conditional Logic (Optional `when`):** If specified, the constraint only applies when the `when` condition is true (e.g., check field X only if field Y equals "active").

**Full Example:**
```yaml
---
type: axiom
name: Only Bind-Touched Can Wield Binding Magic
canon: true
axiom_type: metaphysical
enforcement: hard
assertion_rule:
  type: value_constraint
  field: magical_ability
  operator: not_one_of
  value: ["binding_magic"]
  when:
    field: character_status
    operator: not_equals
    value: "bind_touched"
  note: "Non-Bind-Touched characters must not possess binding_magic."
---
This axiom restricts access to binding magic to the Bind-Touched order.
```

---

### Type 3: pattern_match

Checks field values against regex patterns. Used to enforce format constraints and forbidden content patterns.

**Schema:**
```yaml
assertion_rule:
  type: pattern_match
  field: <field_name>           # Target field name (e.g., "cause_of_death", "description")
  pattern: <regex_string>       # Regex pattern (e.g., "/aetherium/i" for case-insensitive match)
  flags: <regex_flags>          # Optional; i (case-insensitive), m (multiline), s (dotall), etc.
  violation: <string>           # Human-readable violation description
```

**Pattern Syntax:** Standard regex (PCRE-compatible). Special characters must be escaped. Pattern is typically written as `/regex/flags` but stored as a string.

**Flags:**
- `i`: Case-insensitive matching
- `m`: Multiline mode (^ and $ match line boundaries)
- `s`: Dotall mode (. matches newlines)
- `g`: Global matching (all occurrences, not just first)

**Full Example:**
```yaml
---
type: axiom
name: No Mortal Can Survive Direct Aetherium Exposure
canon: true
axiom_type: physical
enforcement: hard
assertion_rule:
  type: pattern_match
  field: cause_of_death
  pattern: "/aetherium/i"
  flags: "i"
  violation: "Mortal character survived direct aetherium exposure."
---
Aetherium is lethal to mortals. Any character marked as mortal cannot have a cause_of_death that mentions aetherium.
```

---

## Examples of Each Assertion Rule Type

### Temporal Bound Example

```yaml
---
type: axiom
name: The Age of Echoes Lasted from 50 PG to 210 PG
canon: true
axiom_type: temporal
enforcement: hard
assertion_rule:
  type: temporal_bound
  field: end_year
  boundary: 210
  relation: after
  note: "Any event recorded after 210 PG must fall outside the Age of Echoes."
---
```

### Value Constraint Example

```yaml
---
type: axiom
name: All Factions Must Declare Their Alignment
canon: true
axiom_type: constraint
enforcement: hard
assertion_rule:
  type: value_constraint
  field: alignment
  operator: exists
  note: "Every faction must have an alignment field to clarify their role in Aethelgard."
---
```

### Pattern Match Example

```yaml
---
type: axiom
name: Forbidden Names in Canonical Content
canon: true
axiom_type: narrative
enforcement: hard
assertion_rule:
  type: pattern_match
  field: name
  pattern: "/placeholder|temp|tbd/i"
  violation: "Entry contains placeholder or temporary naming."
---
```

---

## §10 Error Message Quick Reference

| Rule ID | Rule Name | Tier | Severity | Apocryphal |
|---|---|---|---|---|
| VAL-SCH-001 | YAML Frontmatter Parseable | 1 | Error | Error |
| VAL-SCH-002 | Required Common Fields Present | 1 | Error | Error |
| VAL-SCH-003 | Entity Type Recognized | 1 | Warning | Warning |
| VAL-SCH-004 | Canon Field Value Valid | 1 | Error | Error |
| VAL-SCH-005 | Required Type-Specific Fields Present | 1 | Error | Error |
| VAL-SCH-006 | Field Data Type Correct | 1 | Error | Error |
| VAL-SCH-007 | Enum Value Valid | 1 | Error/Info | Error |
| VAL-SCH-008 | Date Format Valid | 1 | Error | Error |
| VAL-SCH-009 | File Path Format Valid | 1 | Error | Error |
| VAL-SCH-010 | Relationship Entry Structure Valid | 1 | Error | Error |
| VAL-SCH-011 | Tag Format Normalized | 1 | Info | Info |
| VAL-SCH-012 | Custom Schema Valid | 1 | Error | Error |
| VAL-REF-001 | Reference Target Exists | 2 | Error | Warning |
| VAL-REF-002 | Bidirectional Relationship Consistency | 2 | Warning | Warning |
| VAL-REF-003 | Supersession Chain Valid | 2 | Warning | Warning |
| VAL-REF-004 | Relationship Target Type Sensible | 2 | Info | Info |
| VAL-REF-005 | Parent-Child Hierarchy Valid | 2 | Error | Error |
| VAL-REF-006 | Unique Entry Names (Per Type) | 2 | Warning | Info |
| VAL-REF-007 | Circular Reference Detection | 2 | Warning | Warning |
| VAL-REF-008 | Relationship Type Format Valid | 2 | Error | Error |
| VAL-REF-009 | File Path Consistency | 2 | Warning | Warning |
| VAL-REF-010 | Relationship Temporal Bounds Valid | 2 | Warning | Warning |
| VAL-REF-011 | Locale Containment Valid | 2 | Warning | Warning |
| VAL-REF-012 | Required Cross-Reference Fields | 2 | Error | Warning |
| VAL-REF-013 | Relationship Target Canon Exists | 2 | Error | Warning |
| VAL-REF-014 | Schema-Aware Relationship Validation | 2 | Warning | Warning |
| VAL-REF-015 | Multi-File Entry Completeness | 2 | Warning | Warning |
| VAL-REF-016 | Branch Convention — Draft on Main | 2 | Warning | N/A |
| VAL-REF-017 | Branch Convention — Non-Apocryphal on Apocrypha | 2 | Info | N/A |
| VAL-CAN-001 | Canonical References Draft Content | 3 | Warning | N/A |
| VAL-CAN-002 | Canonical References Apocryphal Content | 3 | Warning | N/A |
| VAL-CAN-003 | Canonical References Deprecated Content | 3 | Warning | N/A |
| VAL-CAN-004 | Child Canon Hierarchy | 3 | Error | Error |
| VAL-CAN-005 | Replacement Promotion Predecessor Check | 3 | Warning | N/A |
| VAL-TMP-001 | Timeline Era Boundary Order | 3 | Warning | Skipped |
| VAL-TMP-002 | Relationship Temporal Order | 3 | Warning | Skipped |
| VAL-AXM-001 | Hard Axiom Deterministic Enforcement | 3 | Error | Skipped |
| VAL-AXM-002 | Soft Axiom LLM Flag | 3 | Info | Skipped |
| VAL-VOC-001 | Relationship Type Vocabulary Notice | 3 | Info | Info |

---

## §11 Dependencies and Cross-References

### Upstream Dependencies

The D-12 Validation Rule Catalog depends on the following documents:

- **D-10 (v0.2.1):** Lore File Schema Specification — defines the schema, field types, required fields, entity types, and relationship structures that underpin all Tier 1 and Tier 2 validation
- **D-11 (v0.1.0-draft):** Canon Workflow Specification — defines canonical status values, promotion workflow, apocryphal modifier rules, and temporal semantics
- **D-04 (§6.3):** Chronicle Architecture — provides the overall system context for validation
- **D-01 (§4.5):** Aethelgard Lore Foundation — establishes the PG calendar system and core axioms

### Downstream Consumers

The D-12 Validation Rule Catalog is consumed by:

- **D-13 (CLI):** Command-line interface for `chronicle validate` — displays error messages, respects --verbose flag, and implements rule enforcement
- **D-14 (LLM Integration):** Deep validation using language models for soft axiom checks and semantic rule types; receives flagged entries from VAL-AXM-002

### Design Decisions

Six locked design decisions underpin this catalog:

1. **OQ-D12-1:** Structured axiom rule types (temporal_bound, value_constraint, pattern_match)
2. **OQ-D12-2:** Case-insensitive enum matching with auto-normalization
3. **OQ-D12-3:** Standardized rule template format for consistency
4. **OQ-D12-4:** Three-tier validation architecture with cascade gating
5. **OQ-D12-5:** Free-text date handling; structured-only temporal comparisons
6. **OQ-D12-6:** Tag normalization to lowercase-hyphenated with informational notices

For detailed design rationale, see **D-12-design-decisions.md** (in the chronicle docs directory).

---

## §12 Document Revision History

| Version | Date | Author | Changes |
|---|---|---|---|
| 0.1.0-draft | 2026-02-10 | Ryan + Claude | Initial draft. 37 rules across 3 tiers. 3 assertion rule types. 6 design decisions (OQ-D12-1 through OQ-D12-6). All rules include passing examples, failing examples, error messages, and remediation guidance. Apocryphal modifier applied per D-11 §9.1. |
| 0.1.1-draft | 2026-02-10 | Ryan + Claude | Post-verification corrections. Fixed `axiom_type` enum values (VAL-SCH-007, §9 examples) to match D-10 §5.8: temporal, physical, metaphysical, social, narrative, constraint. Fixed `enforcement` examples from invalid `absolute` to correct `hard`. Added VAL-REF-016 (Branch Convention — Draft on Main) and VAL-REF-017 (Branch Convention — Non-Apocryphal on Apocrypha) per D-11 §7.2. Total rules: 39. Fixed OQ-D12-6 reference from "snake_case" to "lowercase-hyphenated". |

---

**End of D-12 Validation Rule Catalog**
