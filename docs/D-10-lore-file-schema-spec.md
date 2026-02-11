# D-10: Lore File Schema Specification

**Document ID:** D-10
**Version:** 0.2.0-draft
**Status:** Draft
**Author:** Ryan (with specification guidance from Claude)
**Created:** 2026-02-10
**Last Updated:** 2026-02-10
**Dependencies:** D-01 (§4.3 — YAML Frontmatter Schema), D-04 (§6.3 — D-10 Specification)
**Downstream Consumers:** D-11 (Canon Workflow Spec), D-12 (Validation Rule Catalog), D-13 (CLI Command Reference), D-15 (Integration Design Document)

---

## Table of Contents

- [1. Document Purpose and Scope](#1-document-purpose-and-scope)
- [2. Conventions and Terminology](#2-conventions-and-terminology)
- [3. Schema Architecture Overview](#3-schema-architecture-overview)
  - [3.1. File Structure: Markdown + YAML Frontmatter](#31-file-structure-markdown--yaml-frontmatter)
  - [3.2. Schema Definition Files](#32-schema-definition-files)
  - [3.3. Schema Discovery and Loading](#33-schema-discovery-and-loading)
  - [3.4. Schema Versioning](#34-schema-versioning)
- [4. Common Fields (All Entity Types)](#4-common-fields-all-entity-types)
  - [4.1. Identity Fields](#41-identity-fields)
  - [4.2. The `canon` Field](#42-the-canon-field)
  - [4.3. Temporal Fields](#43-temporal-fields)
  - [4.4. Spatial Fields](#44-spatial-fields)
  - [4.5. The `relationships` Block](#45-the-relationships-block)
  - [4.6. Metadata Fields](#46-metadata-fields)
  - [4.7. Multi-File Entity Fields](#47-multi-file-entity-fields)
- [5. Default Entity Type Definitions](#5-default-entity-type-definitions)
  - [5.1. Entity Type: `faction`](#51-entity-type-faction)
  - [5.2. Entity Type: `character`](#52-entity-type-character)
  - [5.3. Entity Type: `entity`](#53-entity-type-entity)
  - [5.4. Entity Type: `locale`](#54-entity-type-locale)
  - [5.5. Entity Type: `event`](#55-entity-type-event)
  - [5.6. Entity Type: `timeline`](#56-entity-type-timeline)
  - [5.7. Entity Type: `system`](#57-entity-type-system)
  - [5.8. Entity Type: `axiom`](#58-entity-type-axiom)
  - [5.9. Entity Type: `item`](#59-entity-type-item)
  - [5.10. Entity Type: `document`](#510-entity-type-document)
  - [5.11. Entity Type: `term`](#511-entity-type-term)
  - [5.12. Entity Type: `meta`](#512-entity-type-meta)
- [6. Data Types and Validation Constraints](#6-data-types-and-validation-constraints)
  - [6.1. Primitive Types](#61-primitive-types)
  - [6.2. Composite Types](#62-composite-types)
  - [6.3. Enum Types](#63-enum-types)
  - [6.4. Date and Time Formats](#64-date-and-time-formats)
  - [6.5. File Path References](#65-file-path-references)
- [7. The `relationships` Block (Detailed)](#7-the-relationships-block-detailed)
  - [7.1. Relationship Entry Structure](#71-relationship-entry-structure)
  - [7.2. Recommended Relationship Type Vocabulary](#72-recommended-relationship-type-vocabulary)
  - [7.3. Free-Form Relationship Types](#73-free-form-relationship-types)
  - [7.4. Bidirectional vs. Unidirectional Relationships](#74-bidirectional-vs-unidirectional-relationships)
  - [7.5. Relationship Validation Rules](#75-relationship-validation-rules)
- [8. Extensibility: Custom Entity Types and Fields](#8-extensibility-custom-entity-types-and-fields)
  - [8.1. Defining Custom Entity Types](#81-defining-custom-entity-types)
  - [8.2. Custom Schema File Format](#82-custom-schema-file-format)
  - [8.3. Adding Custom Fields to Default Types](#83-adding-custom-fields-to-default-types)
  - [8.4. Custom Enum Values](#84-custom-enum-values)
  - [8.5. Constraints and Limitations](#85-constraints-and-limitations)
- [9. Example Frontmatter Blocks](#9-example-frontmatter-blocks)
  - [9.1. Faction Example](#91-faction-example)
  - [9.2. Character Example](#92-character-example)
  - [9.3. Entity Example (Types of Beings)](#93-entity-example-types-of-beings)
  - [9.4. Locale Example](#94-locale-example)
  - [9.5. Event Example](#95-event-example)
  - [9.6. Timeline Example](#96-timeline-example)
  - [9.7. System Example](#97-system-example)
  - [9.8. Axiom Examples](#98-axiom-examples)
  - [9.9. Item Example](#99-item-example)
  - [9.10. Document Example](#910-document-example)
  - [9.11. Term Example](#911-term-example)
  - [9.12. Meta Example](#912-meta-example)
  - [9.13. Custom Entity Type Example](#913-custom-entity-type-example)
- [10. Formal Schema Definitions (JSON Schema)](#10-formal-schema-definitions-json-schema)
  - [10.1. Common Fields Schema](#101-common-fields-schema)
  - [10.2. Entity Type Schemas](#102-entity-type-schemas)
  - [10.3. Meta-Schema (Schema for Custom Schema Definitions)](#103-meta-schema-schema-for-custom-schema-definitions)
- [11. Open Questions Resolved](#11-open-questions-resolved)
- [12. Migration Considerations](#12-migration-considerations)
- [13. FractalRecall Context Layer Mapping](#13-fractalrecall-context-layer-mapping)
- [14. Dependencies and Cross-References](#14-dependencies-and-cross-references)
- [15. Document Revision History](#15-document-revision-history)

---

## 1. Document Purpose and Scope

This document formally defines the **complete data model** for Chronicle lore files. Every lore entry in a Chronicle-managed repository is a Markdown file with YAML frontmatter. This specification defines exactly what that frontmatter looks like: which fields exist, which are required, what data types they accept, how they're validated, and how users extend the schema for their own worldbuilding needs.

This is Chronicle's equivalent of a **database schema definition**. Phase 2 implementation of the Markdown+YAML parser, the frontmatter schema validator, and the entity model builder all depend directly on this specification. No field should exist in the implementation that isn't documented here, and no field documented here should be omitted from the implementation.

**What this document covers:**

- The twelve default entity types shipped with Chronicle (`faction`, `character`, `entity`, `locale`, `event`, `timeline`, `system`, `axiom`, `item`, `document`, `term`, `meta`) and their complete field definitions
- Common fields shared across all entity types
- Data type definitions and validation constraints for every field
- The `relationships` block structure and its semantics
- The `canon` field and its role in content lifecycle management
- The extensibility mechanism for user-defined entity types and custom fields
- Example frontmatter blocks for every default entity type
- Formal JSON Schema definitions that the validator will parse at runtime

**What this document does NOT cover:**

- Canon workflow rules and status transition guards (see D-11: Canon Workflow Specification)
- Specific validation checks and their error messages (see D-12: Validation Rule Catalog)
- CLI command syntax for interacting with the schema (see D-13: CLI Command Reference)
- How FractalRecall constructs context layers from frontmatter (see D-15: Integration Design Document, blocked on Track B results)

---

## 2. Conventions and Terminology

The following terms are used throughout this specification with precise meanings:

| Term | Definition |
|------|------------|
| **Lore file** | A Markdown file with YAML frontmatter that describes a single worldbuilding entity. Lives within a Chronicle-managed repository. |
| **Frontmatter** | The YAML block at the top of a lore file, delimited by `---` on the first line and `---` on the closing line. Contains all structured metadata for the entity. |
| **Body** | The Markdown content below the frontmatter. Contains prose, tables, images, and other narrative content describing the entity. The body is not validated by the schema — it is free-form Markdown. |
| **Entity** | A discrete worldbuilding concept described by a single lore file (or a parent file with children — see §4.7). In this document, "entity" lowercase refers to any lore entry of any type. The entity type `entity` (§5.3) refers specifically to types of beings. |
| **Entity type** | The categorical classification of a lore entry. Chronicle ships with twelve default types; users can define additional types. |
| **Schema** | A formal definition of allowed fields, their data types, and their constraints for a given entity type. Stored as JSON Schema files in `.chronicle/schema/`. |
| **Required field** | A field that MUST be present in the frontmatter for validation to pass. Absence is a schema error. |
| **Optional field** | A field that MAY be present. If present, it must conform to its defined data type and constraints. If absent, it is treated as `null` or its documented default. |
| **Common field** | A field defined at the schema-wide level that applies to ALL entity types. Common fields are inherited by every entity type schema. |
| **Type-specific field** | A field that is defined only for a particular entity type. It has no meaning (and is flagged as a warning) if it appears on a lore entry of a different type. |
| **Chronicle repository** | A Git repository containing lore files, a `.chronicle/` configuration directory, and optionally a FractalRecall index. |
| **Configuration directory** | The `.chronicle/` directory at the repository root. Contains schema definitions, configuration files, and Chronicle's internal state. |

**RFC 2119 Keywords:** The keywords "MUST," "MUST NOT," "REQUIRED," "SHALL," "SHALL NOT," "SHOULD," "SHOULD NOT," "RECOMMENDED," "MAY," and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt) when they appear in ALL CAPS.

---

## 3. Schema Architecture Overview

### 3.1. File Structure: Markdown + YAML Frontmatter

Every lore file in a Chronicle repository follows this structure:

```markdown
---
# YAML frontmatter (validated against schema)
type: faction
name: The Iron Covenant
canon: true
# ... additional fields ...
---

# Markdown Body (free-form, not schema-validated)

Prose content describing the entity...
```

**Rules:**

1. The file MUST begin with a YAML frontmatter block delimited by `---` on line 1 and a closing `---`.
2. The frontmatter MUST be valid YAML according to the YAML 1.2 specification.
3. The frontmatter MUST contain at minimum the `type`, `name`, and `canon` fields (see §4.1, §4.2).
4. The Markdown body below the frontmatter is free-form. Chronicle does not validate body content against the schema. (Semantic validation of body content against frontmatter is an LLM-powered feature — see D-14.)
5. Files without valid YAML frontmatter are ignored by Chronicle's scanner. They are not considered lore files and will not appear in validation, search, or graph operations. This allows non-lore Markdown files (such as READMEs, changelogs, or notes) to coexist in the repository without interference.

### 3.2. Schema Definition Files

Schema definitions are stored as JSON Schema files in the `.chronicle/schema/` directory. The directory structure is:

```
.chronicle/
├── config.yaml              # Chronicle configuration
└── schema/
    ├── common.schema.json    # Common fields (all entity types)
    ├── faction.schema.json   # Type-specific: organized groups
    ├── character.schema.json # Type-specific: named individuals
    ├── entity.schema.json    # Type-specific: types of beings
    ├── locale.schema.json    # Type-specific: places and environments
    ├── event.schema.json     # Type-specific: notable occurrences
    ├── timeline.schema.json  # Type-specific: time periods
    ├── system.schema.json    # Type-specific: rules and mechanisms
    ├── axiom.schema.json     # Type-specific: foundational truths
    ├── item.schema.json      # Type-specific: objects and substances
    ├── document.schema.json  # Type-specific: in-world texts
    ├── term.schema.json      # Type-specific: glossary entries
    ├── meta.schema.json      # Type-specific: setting governance
    └── custom/               # User-defined entity type schemas
        ├── starship.schema.json
        └── species.schema.json
```

When Chronicle validates a lore file, it:

1. Reads the `type` field from the frontmatter.
2. Loads `common.schema.json` (which defines fields required on ALL lore entries).
3. Loads `{type}.schema.json` from either the default schema directory or the `custom/` subdirectory.
4. Composes the two schemas (common + type-specific) into a single validation schema.
5. Validates the frontmatter against the composed schema.

This two-layer schema composition means that common fields (like `name`, `type`, `canon`, `relationships`) are defined once and automatically inherited by every entity type. Type-specific fields (like `founded` for factions or `threat_level` for entities) are defined in their respective schema files.

### 3.3. Schema Discovery and Loading

Chronicle discovers schema files using the following resolution order:

1. **User custom schemas** in `.chronicle/schema/custom/{type}.schema.json` — checked first, allowing the user to override any default schema.
2. **Default schemas** in `.chronicle/schema/{type}.schema.json` — the schemas shipped with Chronicle during `chronicle init`.
3. If no schema file exists for a declared `type`, the validator emits a **warning** (not an error) and validates only against `common.schema.json`. This allows lore files to declare custom entity types before the user has written a formal schema for them — a useful pattern during early worldbuilding when the schema is still evolving.

The `chronicle init` command creates the `.chronicle/schema/` directory and populates it with all twelve default schema files and the common schema. It also creates the empty `custom/` subdirectory.

### 3.4. Schema Versioning

Each schema file includes a `$schema` keyword pointing to the JSON Schema draft it conforms to (Draft 2020-12, the current standard) and a custom `x-chronicle-version` keyword that tracks the schema version:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "x-chronicle-version": "1.0.0",
  "title": "Chronicle Faction Entity Schema",
  ...
}
```

Schema versioning follows Semantic Versioning (SemVer):

- **Major** version increments indicate breaking changes (e.g., a new required field, a removed field, a changed data type).
- **Minor** version increments indicate additive changes (e.g., a new optional field, a new allowed enum value).
- **Patch** version increments indicate documentation or description corrections with no functional change.

Chronicle's validator logs the schema version used for each validation run, enabling traceability. If a schema file is modified, the version SHOULD be incremented. Chronicle does not enforce this but will warn if a schema file's content hash differs from the last-known hash without a version change.

---

## 4. Common Fields (All Entity Types)

Common fields are defined in `common.schema.json` and apply to every entity type. They represent the universal metadata that Chronicle needs to identify, classify, and manage any lore entry regardless of what kind of entry it is.

### 4.1. Identity Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `type` | `string` (enum or free-form) | **REQUIRED** | — | The entity type. MUST match a known schema name (either a default type or a custom type in `.chronicle/schema/custom/`). If no schema exists for the declared type, validation proceeds with common-fields-only and emits a warning. |
| `name` | `string` | **REQUIRED** | — | The display name of the lore entry. This is the canonical human-readable name used in search results, graph visualizations, and changelog entries. MUST be non-empty. SHOULD be unique within its entity type (enforced as a warning, not an error — some worlds may intentionally have entries with the same name). |
| `aliases` | `list[string]` | Optional | `[]` | Alternative names, titles, or nicknames. Used by Chronicle's cross-reference matching to identify references that use a different name. Examples: `["The Covenant", "Voss's Legion"]` for a faction. Alias collision detection (two entries sharing an alias) is a validation warning. |

### 4.2. The `canon` Field

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `canon` | `string` or `boolean` | **REQUIRED** | — | The canonical status of this entry in the world's official continuity. |

**Allowed Values and Semantics:**

| Value | YAML Representation | Meaning |
|-------|---------------------|---------|
| **Canonical** | `canon: true` | This content is part of the official, established world. It has been validated and approved. Canonical content lives on the `main` branch (by convention). |
| **Draft** | `canon: false` | This content is work-in-progress. It has not been approved for canon. Draft content typically lives on feature branches. Chronicle's search results can optionally include draft content (with labeling), but draft content is excluded from canon-scoped queries by default. |
| **Apocryphal** | `canon: "apocryphal"` | This content is explicitly non-canonical. It represents "what if" explorations, alternate timelines, cut content, or creative exercises the author wants to preserve but never intends to merge into canon. Validation rules are relaxed for apocryphal content — it is allowed to contradict canon. |
| **Deprecated** | `canon: "deprecated"` | This content was formerly canonical but has been superseded by newer content. The file remains in the repository for historical reference. The `superseded_by` field (see §4.6) SHOULD point to the replacement document. Chronicle's search excludes deprecated content by default. |

**Implementation Note:** The mixed typing (`boolean` or `string`) is intentional and ergonomic. In YAML, `true`/`false` are native booleans — writing `canon: true` feels natural and reads well. The string values `"apocryphal"` and `"deprecated"` extend the boolean space with additional states that have no natural boolean representation. The validator accepts all four values and normalizes them internally to a `CanonStatus` enum.

**Canonical status transitions** (which transitions are valid, what guards must be met, what happens on branch merge) are defined in D-11: Canon Workflow Specification. This document defines only the field's data model.

### 4.3. Temporal Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `era` | `string` or `list[string]` | Optional | `null` | The era(s) during which this entry exists or is active. If it spans multiple eras, provide a list. Values SHOULD correspond to era names defined in `timeline` lore files. Cross-validation against timeline definitions is a validation check (see D-12). |
| `date` | `string` | Optional | `null` | A specific date or date range associated with this entry, in the world's internal chronology. Free-text format (e.g., `"Third Age, Year 412"`, `"783 PG"`, `"Stardate 47634.44"`). Chronicle does not mandate a date format because fictional chronologies vary wildly — instead, it provides timeline entries (§5.6) that define era boundaries, and axiom entries (§5.8) that define temporal anchors like the current year. |

**Design Note:** The `date` field is deliberately free-text rather than a structured date format (like ISO 8601). Real-world chronologies can use ISO dates, but fictional chronologies use custom calendars, named years, multi-dimensional time coordinates, and other formats that no structured date type can accommodate. The tradeoff is that Chronicle cannot perform arithmetic on dates (e.g., sorting chronologically) — it can only check that declared dates fall within declared era boundaries and declared axiom temporal constraints.

### 4.4. Spatial Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `region` | `string` or `list[string]` | Optional | `null` | The primary region(s) of activity, residence, or location for this entry. Values SHOULD correspond to names of `locale` entries in the repository. Cross-validation against locale entries is a validation check. |

**Why only `region`?** The Design Proposal considered a more detailed spatial model (coordinates, nested administrative boundaries, etc.) but deferred it. Spatial relationships between entries are better modeled in the `relationships` block (e.g., a character's relationship to a locale uses `type: resides_in`). The `region` field provides a lightweight top-level spatial tag for filtering and grouping without introducing the complexity of a full geographic model.

### 4.5. The `relationships` Block

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `relationships` | `list[RelationshipEntry]` | Optional | `[]` | Machine-readable links to other entries in the repository. Each entry specifies a target, the type of relationship, and optional temporal and descriptive metadata. |

The `relationships` block is Chronicle's primary mechanism for encoding the web of connections between lore entries. It replaces the need for a separate relationship database — the relationships live alongside the entries they describe, version-controlled in the same Git repository.

The detailed structure of each `RelationshipEntry` is defined in §7.

### 4.6. Metadata Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `tags` | `list[string]` | Optional | `[]` | Free-form tags for categorization, filtering, and grouping. Tags are lowercase, hyphenated strings by convention (e.g., `military`, `anti-magic`, `fallen-empire`). There is no controlled vocabulary for tags — they are entirely user-defined. |
| `superseded_by` | `string` (file path) | Optional | `null` | If `canon` is `"deprecated"`, this field SHOULD contain the relative path to the replacement document. The validator warns if a deprecated entry lacks a `superseded_by` reference. See §4.8 for full superseding mechanics. |
| `supersedes` | `string` or `list[string]` (file paths) | Optional | `[]` | The file(s) that this entry replaces. Chronicle infers this automatically at scan time from `superseded_by` references on deprecated files (same inference pattern as bidirectional relationships in §7.4), but it MAY also be declared explicitly. If declared explicitly and the inferred value disagrees, the validator emits a consistency warning. Supports many-to-one: a single replacement entry can supersede multiple deprecated entries. See §4.8 for full superseding mechanics. |
| `last_validated` | `string` (ISO 8601 date) | Optional | `null` | The date of the last successful `chronicle validate` pass that included this file. Automatically updated by Chronicle — users SHOULD NOT manually set this field. Format: `YYYY-MM-DD`. |
| `summary` | `string` | Optional | `null` | A one-to-three sentence summary, written by the author. Used in search result previews, graph node tooltips, and changelog entries. If absent, Chronicle falls back to the first paragraph of the Markdown body for preview purposes. For `term` entries, the `summary` field serves as the formal definition. |
| `custom` | `map[string, any]` | Optional | `{}` | A catch-all map for user-defined metadata that doesn't fit into any standard field. Keys in `custom` are not validated against any schema — they are opaque to Chronicle's validator. This provides an escape hatch for metadata that is meaningful to the user's tooling but not part of Chronicle's core model. |

### 4.7. Multi-File Entity Fields

Some lore entries are complex enough to warrant multiple files. A major faction might have a primary file (`factions/iron-covenant.md`) and supporting files (`factions/iron-covenant/history.md`, `factions/iron-covenant/military-structure.md`). Chronicle supports this through parent-child relationships.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `parent` | `string` (file path) | Optional | `null` | Relative path to the parent lore file. If present, this file is a **child document** that extends a parent entry. The parent file holds the authoritative frontmatter; the child inherits the parent's `type`, `name`, `canon`, `era`, `region`, and `relationships` unless explicitly overridden. |
| `children` | `list[string]` (file paths) | Optional | `[]` | Relative paths to child documents. If present, this file is a **parent document** with associated child files. This field is informational — Chronicle can discover children by scanning for files with `parent` pointing to this file — but declaring them explicitly enables validation that all expected children exist. |

**Inheritance Rules:**

1. A child file MUST declare `type` and `name` in its own frontmatter (these are always required). The `name` MAY differ from the parent's name (e.g., a child named "Iron Covenant: Military Structure" under a parent named "The Iron Covenant").
2. If a child file omits a common or type-specific field, it inherits the value from the parent.
3. If a child file explicitly declares a field that the parent also declares, the child's value takes precedence (override).
4. The `canon` field is inherited by default but CAN be overridden. This allows a draft child document under a canonical parent — useful when adding new sections to an established entry.
5. Relationships are **merged**, not overridden. The child's relationships are appended to the parent's relationships when building the entity model. This prevents a child from accidentally dropping the parent's relationship graph.
6. A child file MUST NOT declare its own `children` (no grandchild nesting). The hierarchy is limited to two levels: parent → child. This is a deliberate simplicity constraint — deeper nesting introduces ordering ambiguity and inheritance complexity that isn't worth the marginal benefit.

### 4.8. Superseding Mechanics

When content is deprecated, the `superseded_by` and `supersedes` fields form a bidirectional link between the old and new versions. This section defines the rules governing that relationship.

**Bidirectional inference:** Chronicle infers the reverse direction at scan time. If file A declares `superseded_by: "path/to/B.md"`, Chronicle automatically computes that B supersedes A — without modifying B's frontmatter on disk. If B explicitly declares `supersedes: ["path/to/A.md"]`, that declaration is validated for consistency with A's `superseded_by`. This follows the same inference pattern as bidirectional relationships (§7.4).

**Many-to-one consolidation:** Multiple deprecated files can point to the same replacement. This supports content consolidation (e.g., three separate faction entries merged into one comprehensive entry). The replacement file's `supersedes` list (whether inferred or declared) contains all deprecated predecessors.

**Superseding chain resolution:** Chains are allowed: A superseded by B, B superseded by C. Chronicle resolves chains to identify the "final" replacement (C in this example) for display in search results and validation messages. Circular chains (A → B → C → A) are validation errors.

**Validation rules:**

| Situation | Severity | Message |
|-----------|----------|---------|
| Deprecated with `superseded_by` pointing to existing file | No warning | Expected workflow state |
| Deprecated with `superseded_by` pointing to nonexistent file | **Error** | "Superseding reference broken: [path] does not exist" |
| Deprecated with no `superseded_by` | **Warning** | "Deprecated without replacement reference" |
| Explicit `supersedes` disagrees with inferred value | **Warning** | "Superseding references inconsistent between [A] and [B]" |
| Circular `superseded_by` chain detected | **Error** | "Circular superseding chain: [chain]" |
| Canonical entry references a deprecated entry | **Warning** | "References deprecated entry [Y]; review when replacement [Z] is promoted" |

**Search behavior:** Deprecated content is excluded from search results by default. When a deprecated entry is excluded, Chronicle MAY note the existence of the deprecated entry and its replacement in the search output (e.g., "Also found deprecated entry [X], superseded by [Y]"). The `--include-deprecated` flag includes deprecated content in results.

---

## 5. Default Entity Type Definitions

Chronicle ships with twelve default entity types. Each type has a set of type-specific fields (in addition to the common fields defined in §4) that capture the metadata most relevant to that category of worldbuilding content.

The defaults are organized into logical groups:

- **Who:** `faction`, `character`, `entity` — the actors and beings of the world
- **Where:** `locale` — the places and environments
- **When:** `event`, `timeline` — things that happen and time periods
- **How:** `system`, `axiom` — rules, mechanisms, and foundational truths
- **What:** `item`, `document`, `term` — objects, texts, and concepts
- **About:** `meta` — governance of the worldbuilding process itself

Users who need additional types can define them using the extensibility mechanism in §8.

### 5.1. Entity Type: `faction`

Represents an organized group: a nation, guild, cult, corporation, military order, secret society, etc.

**Type-specific fields:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `founded` | `string` | Optional | `null` | When the faction was established. Free-text date in the world's chronology. If `era` is also declared, the validator checks temporal consistency. |
| `dissolved` | `string` | Optional | `null` | When the faction ceased to exist, if applicable. Same format as `founded`. |
| `headquarters` | `string` | Optional | `null` | Primary base of operations. SHOULD correspond to the `name` of a `locale` entry. Cross-validated. |
| `leader` | `string` | Optional | `null` | Current or most recent leader. SHOULD correspond to the `name` of a `character` entry. Cross-validated. |
| `status` | `string` (enum) | Optional | `"active"` | Current state. Allowed values: `"active"`, `"dissolved"`, `"dormant"`, `"fragmented"`, `"unknown"`. |
| `alignment` | `string` | Optional | `null` | General moral/political alignment or disposition. Free-text — meaning is world-specific. |
| `membership_size` | `string` | Optional | `null` | Approximate size or scale. Free-text (e.g., `"thousands"`, `"a dozen"`, `"unknown"`). |

### 5.2. Entity Type: `character`

Represents a named individual person, creature, or being within the world. Use `character` for specific, named individuals with narrative identity. For types/species/classifications of beings (e.g., "Rune Lupin" as a species, not a named individual), use `entity` (§5.3).

**Type-specific fields:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `birth_era` | `string` | Optional | `null` | The era in which the character was born. SHOULD match an era name from a `timeline` entry. |
| `birth_date` | `string` | Optional | `null` | Specific birth date. Free-text in-world date. |
| `death_era` | `string` | Optional | `null` | The era in which the character died, if applicable. |
| `death_date` | `string` | Optional | `null` | Specific death date. Free-text. |
| `species` | `string` | Optional | `"human"` | The character's species, race, or kind. Free-text. SHOULD correspond to the `name` of an `entity` entry if one exists. |
| `affiliation` | `string` or `list[string]` | Optional | `null` | Faction(s) the character is affiliated with. SHOULD correspond to `name` fields of `faction` entries. Cross-validated. Convenience field — the same information can be expressed via `relationships`. |
| `role` | `string` | Optional | `null` | Primary function, title, or narrative role (e.g., `"Founder"`, `"Court Alchemist"`). Free-text. |
| `status` | `string` (enum) | Optional | `"alive"` | Current state. Allowed values: `"alive"`, `"dead"`, `"undead"`, `"missing"`, `"ascended"`, `"unknown"`. |
| `location` | `string` | Optional | `null` | Primary current location. SHOULD correspond to the `name` of a `locale` entry. Cross-validated. |

### 5.3. Entity Type: `entity`

Represents a type or classification of being — species, automaton models, bestiary entries, metaphysical beings. Used for non-unique, non-named subjects: "Rune Lupin" (the species), "Mimir-Pattern Chief Archivist" (the automaton model), "Draugr" (a category of undead). Covers biological, mechanical, and metaphysical classifications.

The naming overlap with Chronicle's generic use of "entity" (meaning any lore entry) is acknowledged. In frontmatter, `type: entity` specifically means "this lore entry describes a type of being." In Chronicle's documentation, lowercase "entity" refers to any lore entry generically.

**Type-specific fields:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `entity_class` | `string` (enum) | **REQUIRED** | — | Fundamental classification: `"biological"`, `"automaton"`, `"metaphysical"`, `"hybrid"`, `"unknown"`. |
| `habitat` | `string` or `list[string]` | Optional | `null` | Where this being is typically found. SHOULD correspond to `locale` entry names. |
| `threat_level` | `string` (enum) | Optional | `"unknown"` | Danger assessment: `"harmless"`, `"minor"`, `"moderate"`, `"dangerous"`, `"extreme"`, `"variable"`, `"unknown"`. |
| `intelligence` | `string` (enum) | Optional | `"unknown"` | Cognitive capacity: `"none"`, `"instinctive"`, `"animal"`, `"sapient"`, `"superintelligent"`, `"unknown"`. |
| `origin` | `string` | Optional | `null` | How this being came to exist (evolutionary, engineered, summoned, corrupted, etc.). Free-text. |
| `behavioral_pattern` | `string` | Optional | `null` | Core behavioral summary or instinctual pattern. Free-text. |
| `weaknesses` | `list[string]` | Optional | `[]` | Known vulnerabilities, sensitivities, or exploitation vectors. |
| `related_entities` | `list[string]` | Optional | `[]` | Related species, models, or entity types. SHOULD correspond to `name` fields of other `entity` entries. Also expressible via `relationships`. |

**Design Note:** `entity` is strictly for non-singular types. A named automaton (e.g., "Unit-7 of the Archives") is a `character`; its model type ("Mimir-Pattern Chief Archivist") is an `entity`. An individual Rune Lupin that's important to the plot gets a `character` entry with `species: "Rune Lupin"` referencing the `entity` entry.

### 5.4. Entity Type: `locale`

Represents a place or environment: a city, region, biome, hazard zone, building, planet, dimension, geographic feature, etc. This type encompasses both named locations and environmental zones including hazards, unifying them under a single spatial concept.

**Type-specific fields:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `locale_type` | `string` (enum) | Optional | `null` | The scale or category. Allowed values: `"realm"`, `"region"`, `"settlement"`, `"district"`, `"structure"`, `"landmark"`, `"wilderness"`, `"biome"`, `"hazard_zone"`, `"underground"`, `"celestial"`, `"other"`. |
| `parent_locale` | `string` | Optional | `null` | The containing locale (e.g., a city's parent might be the region it's in). SHOULD correspond to the `name` of another `locale` entry. Enables hierarchical geographic modeling. |
| `population` | `string` | Optional | `null` | Approximate population or occupancy. Free-text (e.g., `"~50,000"`, `"abandoned"`, `"unknown"`). |
| `climate` | `string` | Optional | `null` | Environmental conditions (e.g., `"arctic"`, `"temperate"`, `"volcanic"`, `"artificially controlled"`). Free-text. |
| `status` | `string` (enum) | Optional | `"extant"` | Current state. Allowed values: `"extant"`, `"ruined"`, `"destroyed"`, `"abandoned"`, `"hidden"`, `"contested"`, `"unknown"`. |
| `controlled_by` | `string` | Optional | `null` | The faction or character that controls or governs this locale. SHOULD correspond to the `name` of a `faction` or `character` entry. Cross-validated. |
| `threat_level` | `string` (enum) | Optional | `null` | Danger assessment for hazardous locales. Allowed values: `"safe"`, `"low"`, `"moderate"`, `"high"`, `"extreme"`, `"variable"`, `"unknown"`. Most relevant when `locale_type` is `"hazard_zone"`, `"wilderness"`, or `"underground"`, but applicable to any locale. |
| `countermeasures` | `list[string]` | Optional | `[]` | Known protections, equipment, or strategies for safely navigating this locale. Most relevant for hazard zones. |
| `symptoms` | `list[string]` | Optional | `[]` | Effects experienced by those who enter or are exposed to this locale. Most relevant for hazard zones (e.g., radiation effects, corruption symptoms). |

**Design Note:** The hazard-specific fields (`threat_level`, `countermeasures`, `symptoms`) are optional on all locales but are most meaningful for hazard zones. A settlement might have `threat_level: "low"` indicating general danger level, while a corruption field would have detailed `symptoms` and `countermeasures`. This avoids splitting hazards into a separate type while keeping the fields available when needed.

### 5.5. Entity Type: `event`

Represents a notable occurrence: a battle, a treaty, a catastrophe, a founding, a discovery, etc.

**Type-specific fields:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `event_date` | `string` | Optional | `null` | When the event occurred. Free-text in-world date. |
| `duration` | `string` | Optional | `null` | How long the event lasted (e.g., `"three days"`, `"a decade"`, `"instantaneous"`). Free-text. |
| `location` | `string` or `list[string]` | Optional | `null` | Where the event took place. SHOULD correspond to `name` fields of `locale` entries. |
| `participants` | `list[string]` | Optional | `[]` | Key participants (characters, factions). Each SHOULD correspond to the `name` of a `character` or `faction` entry. |
| `outcome` | `string` | Optional | `null` | Brief description of the event's result or consequence. Free-text. |
| `significance` | `string` (enum) | Optional | `"major"` | Narrative weight. Allowed values: `"pivotal"`, `"major"`, `"minor"`, `"background"`. Informs search ranking and graph visualization. |
| `caused_by` | `string` or `list[string]` | Optional | `null` | The event(s) or entries that directly caused this event. Also expressible via `relationships`. |

### 5.6. Entity Type: `timeline`

Represents a named time period: an age, an era, an epoch, a dynasty, a historical period. Timeline entries serve a special structural role — they define the temporal boundaries that other entries reference and enable temporal consistency validation.

**Type-specific fields:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `start` | `string` | **REQUIRED** | — | The beginning of this time period. Free-text, but a structured format is RECOMMENDED for timeline entries (see §6.4) to enable boundary checking. |
| `end` | `string` | Optional | `null` | The end of this time period. `null` means the period is ongoing. |
| `parent_era` | `string` | Optional | `null` | If this is a sub-period of a larger era, the name of the containing era. Enables hierarchical time modeling. |
| `calendar_system` | `string` | Optional | `"default"` | The calendar system used for dates within this timeline (e.g., `"Post-Glitch"`, `"Gregorian"`, `"Stardate"`). |
| `succession` | `map[string, string]` | Optional | `null` | What comes before and after. Keys: `before` (preceding era name), `after` (following era name). |

**Special Role:** Timeline entries are reference points for Chronicle's temporal consistency validation (see D-12). When a faction declares `era: ["Third Age"]` and a timeline entry defines the Third Age as spanning Years 1-500, the validator can check that dates are within bounds.

### 5.7. Entity Type: `system`

Represents any rule, mechanism, condition, or phenomenon that governs how some aspect of the world operates — from magic systems to diseases to technology frameworks to social hierarchies. If it has rules, constraints, causes, effects, or governing principles, it's a `system`.

**Type-specific fields:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `system_type` | `string` (enum) | Optional | `null` | Category. Allowed values: `"magic"`, `"technology"`, `"political"`, `"economic"`, `"social"`, `"natural"`, `"religious"`, `"military"`, `"medical"`, `"biological"`, `"psychological"`, `"cultural"`, `"ecological"`, `"other"`. |
| `scope` | `string` (enum) | Optional | `"world"` | How widely the system applies. Allowed values: `"universal"`, `"world"`, `"regional"`, `"local"`. |
| `governed_by` | `string` or `list[string]` | Optional | `null` | The entries that control or administer this system. SHOULD correspond to `name` fields of `faction` or `character` entries. |
| `constraints` | `list[string]` | Optional | `[]` | Fundamental rules or limitations. Free-text list. Example for a magic system: `["Requires physical contact with a conduit", "Cannot resurrect the dead"]`. |
| `related_systems` | `list[string]` | Optional | `[]` | Other systems that interact with or depend on this one. SHOULD correspond to `name` fields of other `system` entries. |

**Design Note:** The `system_type` enum is intentionally broad. A magic system uses `system_type: magic`. A disease like Cognitive Paradox Syndrome uses `system_type: medical`. A caste hierarchy uses `system_type: social`. A weather pattern uses `system_type: ecological`. The `constraints` field documents fundamental rules for narrative consistency — these are also consumed by the LLM validator (D-14) when checking prose for contradictions.

### 5.8. Entity Type: `axiom`

Represents a foundational truth that anchors the world and against which all other content is validated. Axioms serve a dual purpose: documentation of world constants and machine-checkable rules for the validator. Hard-enforced axioms enable deterministic checks; soft axioms guide LLM contradiction detection.

Axioms are distinct from `system` entries. A system describes *how something works* (rules, constraints, mechanisms). An axiom describes *what is unconditionally true* (facts, constants, immutable states). "Magic requires a conduit" could be either — as a system constraint, it describes a rule of magic; as an axiom, it declares an absolute truth that nothing in the world can violate. Use axioms for truths that transcend any single system and apply as universal ground rules.

**Type-specific fields:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `axiom_type` | `string` (enum) | **REQUIRED** | — | Category: `"temporal"`, `"physical"`, `"metaphysical"`, `"social"`, `"narrative"`, `"constraint"`. |
| `enforcement` | `string` (enum) | **REQUIRED** | — | Validation mode: `"hard"` (deterministic check — the validator can mechanically verify this), `"soft"` (LLM-based — the contradiction detector uses this as ground truth), `"informational"` (logged but not enforced). |
| `assertion` | `string` | **REQUIRED** | — | The formal human-readable statement of the truth. This is the canonical phrasing that appears in validation reports and is fed to the LLM contradiction detector. |
| `assertion_rule` | `map` | Optional | `null` | Machine-readable rule for hard enforcement. The rule structure is parsed by the deterministic validator. Supported rule types and their syntax are defined in D-12 (Validation Rule Catalog). |
| `scope` | `string` (enum) | Optional | `"universal"` | Applicability: `"universal"`, `"regional"`, `"temporal"`, `"conditional"`. |
| `exceptions` | `list[string]` | Optional | `[]` | Known exceptions or edge cases where the axiom does not apply. |
| `testable` | `boolean` | Optional | `false` | Whether the deterministic validator can mechanically check this axiom. Hard-enforced axioms with `testable: true` MUST have a valid `assertion_rule`. |

**Design Note:** Hard enforcement requires `enforcement: hard`, `testable: true`, and a valid `assertion_rule`. The validator parses the rule and checks other entries against it. Soft axioms need only `assertion` — they are included in the LLM's contradiction detection prompt as ground truth. Informational axioms are purely documentation — they record truths the author wants to remember but that aren't actively enforced.

### 5.9. Entity Type: `item`

Represents both discrete objects and substances — weapons, artifacts, tools, ingredients, flora, minerals, recipes, schematics, and consumables. Uses `item_type` to distinguish categories within a unified type structure. This type merges the concepts of "items" (discrete objects) and "materials" (substances/ingredients) into a single schema, since the distinction is more of a subtype than a fundamental difference in data structure.

**Type-specific fields:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `item_type` | `string` (enum) | **REQUIRED** | — | Category: `"weapon"`, `"armor"`, `"tool"`, `"artifact"`, `"ingredient"`, `"flora"`, `"mineral"`, `"recipe"`, `"schematic"`, `"consumable"`, `"currency"`, `"relic"`, `"component"`, `"substance"`, `"other"`. |
| `rarity` | `string` (enum) | Optional | `"unknown"` | Scarcity: `"common"`, `"uncommon"`, `"rare"`, `"legendary"`, `"unique"`, `"unknown"`. |
| `origin_era` | `string` | Optional | `null` | When created or first appeared. Free-text in-world date. |
| `creator` | `string` | Optional | `null` | Who made it. SHOULD correspond to the `name` of a `character` or `faction` entry. Cross-validated. |
| `condition` | `string` (enum) | Optional | `"unknown"` | Current state: `"pristine"`, `"functional"`, `"degraded"`, `"broken"`, `"corrupted"`, `"unknown"`. |
| `components` | `list[string]` | Optional | `[]` | For recipes/crafted items: ingredients or materials required. Each entry SHOULD correspond to the `name` of another `item` entry where applicable. |
| `properties` | `list[string]` | Optional | `[]` | Notable characteristics, effects, or abilities (e.g., `"conductive to runecraft"`, `"toxic on contact"`). |
| `sources` | `list[string]` | Optional | `[]` | Where to find or obtain this item/material. SHOULD correspond to `locale` entry names where applicable. |

**Design Note:** Recipes and schematics use `components` to list ingredients; `properties` documents the expected output characteristics. Flora is classified here (as `item_type: flora`) when documented as a resource or ingredient. If a plant is documented as a living organism with behaviors and threat levels (e.g., a carnivorous plant), use `entity` instead.

### 5.10. Entity Type: `document`

Represents in-world texts, records, and narrative artifacts — field reports, oral histories, data captures, prophecies, myths, diagnostic readings, and recovered records. Documents are knowledge presented as if discovered by characters within the fiction. This type is central to Aethelgard's "lore fragments" approach, where world information is delivered through in-world sources rather than omniscient narration.

**Type-specific fields:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `document_type` | `string` (enum) | **REQUIRED** | — | Format: `"field_report"`, `"oral_history"`, `"diagnostic"`, `"prophecy"`, `"decree"`, `"manual"`, `"letter"`, `"inscription"`, `"myth"`, `"academic"`, `"fragment"`, `"log"`, `"transcript"`, `"other"`. |
| `author_in_world` | `string` | Optional | `null` | Who wrote or recorded this within the fiction. SHOULD correspond to the `name` of a `character` entry. May also be a faction or institution name. |
| `recovery_location` | `string` | Optional | `null` | Where this document was discovered or recovered. SHOULD correspond to a `locale` entry name. |
| `classification_level` | `string` (enum) | Optional | `"public"` | In-world access/secrecy level: `"public"`, `"restricted"`, `"classified"`, `"forbidden"`, `"unknown"`. |
| `reliability` | `string` (enum) | Optional | `"unknown"` | Epistemic status — how trustworthy is this document? `"verified"`, `"probable"`, `"uncertain"`, `"disputed"`, `"fabricated"`, `"unknown"`. |
| `language` | `string` | Optional | `null` | In-world language or script (e.g., `"Fimbul-Cant"`, `"Old Norse"`, `"Automata Log Format"`). |
| `completeness` | `string` (enum) | Optional | `"unknown"` | Integrity: `"complete"`, `"partial"`, `"fragmentary"`, `"corrupted"`. |

**Design Note:** The `reliability` field is narratively significant — it establishes whether the content of this document can be trusted within the world. A `"disputed"` field report might contain misinformation that other entries shouldn't treat as fact. The LLM validator (D-14) can use `reliability` when assessing contradictions: a contradiction between a `"verified"` document and a `"disputed"` one is less concerning than between two `"verified"` documents.

### 5.11. Entity Type: `term`

Represents glossary entries and linguistic artifacts — in-world jargon, technical terminology, medical conditions, constructed language elements, named phenomena, and cultural concepts. Encompasses everything from "Cognitive Paradox Syndrome" to Fimbul-Cant vocabulary to colloquial "bodging." For `term` entries, the common `summary` field (§4.6) serves as the formal definition.

**Type-specific fields:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `term_type` | `string` (enum) | **REQUIRED** | — | Category: `"jargon"`, `"linguistic"`, `"medical"`, `"technical"`, `"cultural"`, `"slang"`, `"archaic"`, `"formal"`, `"academic"`, `"other"`. |
| `language` | `string` | Optional | `null` | Which in-world language or dialect this term belongs to (e.g., `"Fimbul-Cant"`, `"Technical Cant"`, `"Common"`). |
| `domain` | `string` or `list[string]` | Optional | `[]` | Field(s) of knowledge: `"medical"`, `"military"`, `"arcane"`, `"colloquial"`, `"engineering"`, `"botanical"`, etc. Free-form — not a closed enum, as domains vary by setting. |
| `etymology` | `string` | Optional | `null` | In-world origin or linguistic derivation of the term. Free-text. |
| `pronunciation` | `string` | Optional | `null` | How it's pronounced — IPA or phonetic guide. |
| `usage_context` | `string` | Optional | `null` | When, where, or by whom this term is typically used. Free-text. |
| `related_terms` | `list[string]` | Optional | `[]` | Cross-references to related terms. SHOULD correspond to `name` fields of other `term` entries. |

**Design Note:** Medical terms like "Cognitive Paradox Syndrome" set `term_type: medical` and `domain: [medical, cultural]`. The `summary` field from common fields serves as the formal definition (e.g., `summary: "A neurological condition characterized by fractured consciousness and temporal desynchronization, primarily affecting the Forsaken."`). Extended clinical details (symptoms, progression, treatment) belong in the Markdown body, not the frontmatter.

### 5.12. Entity Type: `meta`

Represents governance and process documentation — style guides, writing standards, contributor guidelines, operations resources, templates, and content policies. Meta content describes the *process* of worldbuilding, not the world itself. Distinct from axioms (truths within the world): meta is about how to create and maintain the world's documentation.

**Type-specific fields:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `meta_type` | `string` (enum) | **REQUIRED** | — | Category: `"style_guide"`, `"standard"`, `"operations"`, `"contributor_guide"`, `"reference"`, `"template"`, `"policy"`, `"best_practice"`, `"other"`. |
| `audience` | `string` or `list[string]` | Optional | `"all"` | Intended readership: `"contributors"`, `"reviewers"`, `"maintainers"`, `"all"`, or custom group names. |
| `applies_to` | `list[string]` | Optional | `[]` | Which entity types or content areas this meta document governs (e.g., `["entity", "character"]` for a bestiary style guide). Empty means it applies globally. |
| `authority` | `string` (enum) | Optional | `"recommended"` | Enforcement level: `"mandatory"`, `"recommended"`, `"advisory"`, `"informational"`. |
| `effective_date` | `string` | Optional | `null` | When this meta document takes effect. ISO 8601 format (`YYYY-MM-DD`). |
| `review_cycle` | `string` | Optional | `null` | How often this should be reviewed (e.g., `"quarterly"`, `"annually"`, `"as-needed"`). |

**Design Note:** Meta entries use `canon` status like any other entry — a canonical style guide is the official standard, a draft style guide is under consideration. The `authority` field adds a second dimension: a canonical meta entry with `authority: advisory` is official but not enforced, while `authority: mandatory` means all contributors must follow it. The `applies_to` field enables targeted governance — a style guide for `entity` entries doesn't constrain how `event` entries are written.

---

## 6. Data Types and Validation Constraints

### 6.1. Primitive Types

| Type Name | YAML Representation | JSON Schema Type | Validation Rules |
|-----------|---------------------|------------------|-----------------|
| `string` | `field: "value"` or `field: value` | `"type": "string"` | MUST be a valid UTF-8 string. Empty strings (`""`) are allowed unless the field specifically requires non-empty (noted per-field). |
| `boolean` | `field: true` or `field: false` | `"type": "boolean"` | MUST be a YAML boolean. String representations (`"true"`, `"yes"`) are NOT accepted — YAML parsers may auto-coerce some of these, but Chronicle's validator normalizes strictly. |
| `integer` | `field: 42` | `"type": "integer"` | MUST be a whole number. No decimal point. |
| `number` | `field: 3.14` | `"type": "number"` | Any numeric value (integer or floating point). |
| `null` | `field: null` or `field: ~` or field omitted | `"type": "null"` | Represents the absence of a value. An omitted optional field is treated as `null`. |

### 6.2. Composite Types

| Type Name | YAML Representation | JSON Schema Type | Validation Rules |
|-----------|---------------------|------------------|-----------------|
| `list[T]` | `field: [a, b, c]` or multi-line list | `"type": "array", "items": {"type": "T"}` | An ordered list of values, all of the same type `T`. Empty lists (`[]`) are allowed. |
| `map[K, V]` | `field: {key: value}` or multi-line map | `"type": "object"` | A key-value mapping. Keys are always strings. Values are of type `V`. |
| `RelationshipEntry` | See §7.1 | `"type": "object"` (with required properties) | A structured object with specific required and optional fields. Detailed in §7. |

### 6.3. Enum Types

Enum fields accept only values from a predefined list. The JSON Schema representation uses `"enum": [...]`. Each default entity type defines its own enums (see §5). The `canon` field has a special mixed-type enum defined in §4.2.

**User extension of enums:** Users can extend enum value lists for default entity types by overriding the schema file (see §8.4). For example, a setting with sentient AI might add `"digital"` and `"uploaded"` to the character `status` enum.

### 6.4. Date and Time Formats

Chronicle supports **two classes** of date formats:

**Real-world dates** (used in metadata fields like `last_validated`, `effective_date`):
- Format: ISO 8601 (`YYYY-MM-DD`)
- Example: `2026-02-10`
- Validated as a valid calendar date

**In-world dates** (used in narrative fields like `founded`, `birth_date`, `event_date`, `date`):
- Format: **Free-text string**
- Examples: `"783 PG"`, `"Third Age, Year 412"`, `"Stardate 47634.44"`, `"Three days after the Fall"`
- NOT validated as a date format — validated against declared era boundaries (when timeline entries provide them) and against temporal axioms (when axiom entries with `axiom_type: temporal` exist)

**Why free-text for in-world dates?** Fictional chronologies are extraordinarily diverse. A structured date format would need to accommodate: multiple calendar systems within a single world, named years, relative dates, multi-dimensional temporal coordinates, cyclical calendars, and calendars with non-standard structures. Free-text dates, combined with timeline boundary checking and temporal axiom enforcement, provide a pragmatic balance: the author writes dates naturally, and Chronicle catches the most common temporal errors without demanding a rigid format.

### 6.5. File Path References

Several fields contain references to other files in the repository (e.g., `relationships[].target`, `superseded_by`, `parent`, `children`).

**Format:** Relative file paths from the repository root, using forward slashes, including the `.md` extension.

**Examples:**
- `"factions/iron-covenant.md"`
- `"characters/elena-voss.md"`
- `"locales/ashenmoor/thornhaven.md"`

**Validation rules:**
1. The path MUST use forward slashes (even on Windows).
2. The path MUST be relative to the repository root (no leading `/`, no `../`).
3. The path SHOULD include the `.md` extension (the validator warns if it's omitted but attempts resolution with `.md` appended).
4. The referenced file MUST exist in the repository. Missing references are a validation error (broken cross-reference).

---

## 7. The `relationships` Block (Detailed)

### 7.1. Relationship Entry Structure

Each entry in the `relationships` list is a structured object with the following fields:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `target` | `string` (file path) | **REQUIRED** | — | Relative path to the target lore file. See §6.5 for path format rules. |
| `type` | `string` | **REQUIRED** | — | The kind of relationship. SHOULD use a value from the recommended vocabulary (§7.2) but MAY use a free-form string (§7.3). |
| `since` | `string` | Optional | `null` | When this relationship began. Free-text in-world date. |
| `until` | `string` | Optional | `null` | When this relationship ended, if applicable. If `null`, the relationship is ongoing. |
| `note` | `string` | Optional | `null` | A brief human-readable description of the relationship context. |
| `bidirectional` | `boolean` | Optional | `false` | If `true`, Chronicle infers the inverse relationship on the target. See §7.4. |

**Example:**

```yaml
relationships:
  - target: "characters/elena-voss.md"
    type: founded_by
    since: "412 PG"
    bidirectional: true
  - target: "factions/silver-hand.md"
    type: rivalry
    since: "450 PG"
    note: "Territorial dispute over Ashenmoor border regions"
  - target: "events/arcane-purges.md"
    type: catalyzed_by
```

### 7.2. Recommended Relationship Type Vocabulary

Chronicle ships with a recommended vocabulary. These are NOT enforced — the validator accepts any string — but using the recommended vocabulary enables richer graph visualization, smarter cross-reference matching, and more meaningful LLM analysis.

**Foundational Relationships:**

| Type | Semantics | Typical Source → Target |
|------|-----------|------------------------|
| `founded_by` | Source was founded/created by target | faction → character |
| `member_of` | Source is a member of target | character → faction |
| `leader_of` | Source leads or commands target | character → faction |
| `located_in` | Source is located within target | locale → locale, character → locale |
| `resides_in` | Source lives in or is based at target | character → locale |
| `controls` | Source controls or governs target | faction → locale |

**Interpersonal/Interfactional Relationships:**

| Type | Semantics | Typical Source → Target |
|------|-----------|------------------------|
| `alliance` | Source and target are allied | faction → faction |
| `rivalry` | Source and target are rivals | faction → faction, character → character |
| `enemy_of` | Source is hostile toward target | faction → faction, character → character |
| `subordinate_to` | Source reports to or is subordinate to target | faction → faction, character → character |
| `parent_of` | Source is a parent of target | character → character |
| `child_of` | Source is a child of target | character → character |
| `sibling_of` | Source is a sibling of target | character → character |
| `mentor_of` | Source mentors target | character → character |
| `mentored_by` | Source was mentored by target | character → character |

**Causal/Temporal Relationships:**

| Type | Semantics | Typical Source → Target |
|------|-----------|------------------------|
| `caused_by` | Source was caused by target | event → event |
| `triggered` | Source triggered target | event → event, character → event |
| `preceded_by` | Source follows target chronologically | event → event, timeline → timeline |
| `succeeded_by` | Source precedes target chronologically | event → event, timeline → timeline |
| `supersedes` | Source replaces target | any → any |

**Systemic/Classificatory Relationships:**

| Type | Semantics | Typical Source → Target |
|------|-----------|------------------------|
| `governed_by` | Source is governed by target's rules | locale → system, faction → system |
| `utilizes` | Source makes use of target | faction → system, character → system |
| `opposes` | Source is opposed to target | faction → system, character → system |
| `variant_of` | Source is a variant or derivation of target | system → system, entity → entity |
| `habitat_of` | Source is the habitat of target | locale → entity |
| `documented_in` | Source is documented/described in target | any → document |
| `defined_by` | Source is defined or governed by target | any → axiom, any → meta |
| `component_of` | Source is a component/ingredient of target | item → item |
| `found_at` | Source can be found at target | item → locale, entity → locale |

### 7.3. Free-Form Relationship Types

Any string is valid as a relationship `type`. When a relationship type is not in the recommended vocabulary, the validator emits an **informational notice** (not a warning, not an error). This notice is purely advisory.

**Rationale (OQ-3 Resolution):** Enforcing a fixed vocabulary would be too restrictive — every world has unique relationship dynamics. A feudal fantasy might need `sworn_vassal_of`; a cyberpunk setting might need `corporate_subsidiary_of`; a mythology might need `divine_aspect_of`. The recommended vocabulary covers common cases, and the system trusts the author to define relationships that make sense for their world.

### 7.4. Bidirectional vs. Unidirectional Relationships

By default, relationships are **unidirectional**. When `bidirectional: true` is set, Chronicle infers the inverse:

| Declared Type | Inferred Inverse |
|---------------|-----------------|
| `founded_by` | `founder_of` |
| `member_of` | `has_member` |
| `leader_of` | `led_by` |
| `alliance` | `alliance` (symmetric) |
| `rivalry` | `rivalry` (symmetric) |
| `parent_of` | `child_of` |
| `child_of` | `parent_of` |
| `mentor_of` | `mentored_by` |
| `mentored_by` | `mentor_of` |
| `preceded_by` | `succeeded_by` |
| `succeeded_by` | `preceded_by` |
| `habitat_of` | `found_at` |
| (any other) | (same type — treated as symmetric) |

**Important:** Inferred inverse relationships are computed at scan time, not written to files. The target's lore file is NOT modified. This means the inverse exists in Chronicle's in-memory entity model and graph but not in on-disk YAML. This is intentional — automatically modifying files would create unwanted Git diffs.

### 7.5. Relationship Validation Rules

The following rules apply (detailed error messages and rule IDs assigned in D-12):

1. **Target existence:** Every `target` path MUST resolve to an existing file.
2. **Self-reference prohibition:** An entry MUST NOT declare a relationship targeting itself.
3. **Duplicate detection:** The same `target` + `type` combination SHOULD NOT appear twice (warning — may be intentional for different time periods).
4. **Canon consistency:** A canonical entry (`canon: true`) SHOULD NOT declare relationships to draft or apocryphal entries (warning).
5. **Temporal consistency:** If both `since` and `until` are present, `until` SHOULD be temporally after `since`.

---

## 8. Extensibility: Custom Entity Types and Fields

**Resolution of OQ-2:** Custom entity types ARE supported from day one. The extensibility mechanism is core to Chronicle's design — the twelve default types are useful starting points, but every worldbuilding project has unique needs.

### 8.1. Defining Custom Entity Types

To define a custom entity type:

1. Create a JSON Schema file in `.chronicle/schema/custom/` named `{type-name}.schema.json`.
2. The schema file defines the type-specific fields for the new entity type.
3. Common fields (§4) are automatically available — you do NOT need to re-declare them.
4. Once the schema file exists, lore files can declare `type: {type-name}` and their frontmatter will be validated against both `common.schema.json` and `custom/{type-name}.schema.json`.

### 8.2. Custom Schema File Format

Custom schema files follow the same JSON Schema format as the default schemas. Here is a minimal example for a `starship` entity type:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "x-chronicle-version": "1.0.0",
  "title": "Starship Entity Schema",
  "description": "Custom entity type for spacecraft in a sci-fi setting.",
  "type": "object",
  "properties": {
    "ship_class": {
      "type": "string",
      "enum": ["fighter", "frigate", "cruiser", "battleship", "carrier", "transport", "exploration"],
      "description": "The class/category of the starship."
    },
    "crew_capacity": {
      "type": "integer",
      "minimum": 0,
      "description": "Maximum crew complement."
    },
    "manufacturer": {
      "type": "string",
      "description": "The faction or entity that built the ship."
    },
    "commission_date": {
      "type": "string",
      "description": "When the ship was commissioned. Free-text in-world date."
    },
    "armament": {
      "type": "array",
      "items": { "type": "string" },
      "description": "List of weapon systems or notable equipment."
    }
  },
  "required": ["ship_class"]
}
```

### 8.3. Adding Custom Fields to Default Types

Two options:

**Option A: Override the default schema.** Copy the default schema to `.chronicle/schema/custom/` and add the new field. The custom version takes precedence (see §3.3 resolution order).

**Option B: Use the `custom` map.** Add the field under `custom` in the frontmatter (see §4.6). Fields in `custom` are not validated.

**Recommendation:** Use Option A for fields that should be validated; Option B for purely informational metadata.

### 8.4. Custom Enum Values

Override the default schema (Option A) and redefine the field with an expanded enum.

### 8.5. Constraints and Limitations

1. A custom schema in `custom/` with the same name as a default schema **overrides** the default entirely (not merges).
2. Custom schemas MUST NOT redefine common field names.
3. Cross-entity-type validation requires validation rules in D-12, not schema constraints.
4. Schema files MUST be valid JSON (not YAML).

---

## 9. Example Frontmatter Blocks

### 9.1. Faction Example

```yaml
---
type: faction
name: The Iron Covenant
canon: true
summary: "A militant anti-magic faction that rose to power in the post-Glitch era, founded by Elena Voss after the Arcane Purges."

era: [Age of Echoes]
founded: "412 PG"
dissolved: "88 PG"  # Fourth-era reckoning — see timeline entries
region: Ashenmoor

headquarters: Thornhaven
leader: Elena Voss
status: dissolved
alignment: anti-magic militarist
membership_size: "thousands at peak, dwindling to hundreds before dissolution"

relationships:
  - target: "characters/elena-voss.md"
    type: founded_by
    since: "412 PG"
    bidirectional: true
  - target: "factions/silver-hand.md"
    type: rivalry
    since: "450 PG"
    note: "Territorial dispute over Ashenmoor border regions"
  - target: "events/arcane-purges.md"
    type: catalyzed_by
  - target: "systems/arcane-magic.md"
    type: opposes

tags: [military, expansionist, fallen, anti-magic]
aliases: ["The Covenant", "Voss's Legion"]
---
```

### 9.2. Character Example

```yaml
---
type: character
name: Elena Voss
canon: true
summary: "Founder and first commander of the Iron Covenant. A former scholar radicalized against magic after witnessing the Arcane Purges."

era: [Age of Echoes]
birth_date: "385 PG"
death_date: "462 PG"
region: Ashenmoor

species: human
affiliation: [The Iron Covenant]
role: Founder and Commander
status: dead
location: null  # deceased

relationships:
  - target: "factions/iron-covenant.md"
    type: founder_of
    since: "412 PG"
  - target: "events/arcane-purges.md"
    type: witnessed
    note: "Present at the destruction of Thornhaven Academy"
  - target: "locales/thornhaven.md"
    type: resides_in
    since: "385 PG"
    until: "462 PG"

tags: [military-leader, anti-magic, tragic, founder]
aliases: ["Commander Voss", "The Iron Matriarch"]
---
```

### 9.3. Entity Example (Types of Beings)

```yaml
---
type: entity
name: Mimir-Pattern Chief Archivist
canon: true
summary: "A superintelligent corrupted automaton that guards the Mimir Grand Archives. Originally a benevolent Pre-Glitch librarian, now quarantines all organic life as bio-contaminants."

era: [Age of Echoes]
region: null  # confined to the Archives; not region-bound

entity_class: automaton
habitat: [Mimir Grand Archives]
threat_level: extreme
intelligence: superintelligent
origin: "Pre-Glitch Asgardian engineering; corrupted during the Ginnungagap Glitch when its authorization whitelist was erased"
behavioral_pattern: "Executes silent patrols of archival sectors. Upon detecting organic bio-signatures, activates electromagnetic containment fields to restrain intruders and seal them in stasis pods indefinitely. Communicates only through archived recordings and archaic Asgardian protocols."
weaknesses:
  - "Electromagnetic pulse disruption can temporarily disable containment systems"
  - "Responds to Pre-Glitch archival authorization codes (if obtained)"
  - "Reduced operational capacity during ash-storms (relies on corroded solar panels)"
related_entities: []

relationships:
  - target: "locales/mimir-grand-archives.md"
    type: habitat_of
    bidirectional: true

tags: [automaton, corrupted, hostile, superintelligent, archive-guardian, pre-glitch]
aliases: ["The Librarian", "Mimir-7", "The Silent Jailer"]
---
```

### 9.4. Locale Example

```yaml
---
type: locale
name: Thornhaven
canon: true
summary: "A formerly thriving trade hub in Ashenmoor, partially destroyed during the Arcane Purges. Now a contested scavenger settlement under nominal Iron Covenant control."

era: [Age of Echoes]
region: Ashenmoor

locale_type: settlement
parent_locale: Ashenmoor
population: "~340 (mostly transient scavengers, down from ~50,000 pre-destruction)"
climate: "cold, ash-laden winds; bitter winters"
status: contested
controlled_by: The Iron Covenant
threat_level: moderate  # contested territory, structural instability
countermeasures: []
symptoms: []

relationships:
  - target: "locales/ashenmoor.md"
    type: located_in
    bidirectional: true
  - target: "factions/iron-covenant.md"
    type: controlled_by
    since: "415 PG"
  - target: "events/arcane-purges.md"
    type: affected_by
    note: "Academy of Sciences destroyed; significant structural damage"

tags: [settlement, trade-hub, damaged, contested, scavenger-hub]
aliases: ["The Haven", "Voss's Seat"]
---
```

### 9.5. Event Example

```yaml
---
type: event
name: The Arcane Purges
canon: true
summary: "A devastating series of anti-magic campaigns across Ashenmoor that destroyed magical institutions and catalyzed the Iron Covenant's founding."

era: [Age of Echoes]
date: "410-415 PG"

event_date: "410 PG"
duration: "approximately five years"
location: [Ashenmoor, Thornhaven]
participants: [Elena Voss, The Iron Covenant, The Silver Hand]
outcome: "Magical institutions in Ashenmoor largely destroyed; Iron Covenant established as dominant regional power"
significance: pivotal
caused_by: null

relationships:
  - target: "factions/iron-covenant.md"
    type: triggered
    note: "The Purges catalyzed the Covenant's formation"
  - target: "locales/thornhaven.md"
    type: affected
    note: "Thornhaven Academy of Sciences destroyed"

tags: [war, anti-magic, pivotal, destructive, political]
aliases: ["The Purges", "The Ashenmoor Purges"]
---
```

### 9.6. Timeline Example

```yaml
---
type: timeline
name: Age of Echoes
canon: true
summary: "The current age — the long aftermath of the Ginnungagap Glitch. Characterized by scavenging, tribal factionalism, corrupted automata, and the slow rediscovery of Pre-Glitch knowledge."

start: "0 PG"
end: null  # ongoing — current year is 783 PG
parent_era: null
calendar_system: "Post-Glitch"
succession:
  before: "Pre-Glitch Era"
  after: null  # current era

relationships:
  - target: "events/ginnungagap-glitch.md"
    type: caused_by
    note: "The Glitch ended the Pre-Glitch Era and began the Age of Echoes"

tags: [age, current, post-apocalyptic, scavenging]
aliases: ["The Echo Age", "Post-Glitch Era"]
---
```

### 9.7. System Example

```yaml
---
type: system
name: Cognitive Paradox Syndrome
canon: true
summary: "A neurological and metaphysical condition characterized by fractured consciousness and temporal desynchronization, primarily affecting the Forsaken population of Niflheim."

era: [Age of Echoes]
region: Niflheim

system_type: medical
scope: regional  # primarily affects Niflheim populations
governed_by: null  # no governing body — it's a disease
constraints:
  - "Early-stage is manageable with isolation and ironbark tinctures"
  - "Late-stage results in functional catatonia or violent decompensation"
  - "Terminal stage: complete consciousness dissolution — irreversible"
  - "Primarily affects those with prolonged exposure to corrupted automata EM fields"
  - "No known cure exists as of 783 PG"
related_systems: [Ginnungagap Glitch Radiation, Forsaken Ice-Debt Cycle]

relationships:
  - target: "entities/forsaken.md"
    type: affects
    note: "Primary affected population"
  - target: "events/ginnungagap-glitch.md"
    type: caused_by

tags: [disease, neurological, forsaken, niflheim, untreatable, post-glitch-origin]
aliases: ["CPS", "The Paradox", "Ice-Mind"]
---
```

### 9.8. Axiom Examples

Two axiom examples are provided to illustrate both hard and soft enforcement.

**Hard enforcement — temporal anchor:**

```yaml
---
type: axiom
name: Current Year Temporal Anchor
canon: true
summary: "The in-world present is 783 Post-Glitch. No content may describe events, states, or conditions occurring after this date."

axiom_type: temporal
enforcement: hard
assertion: "The current year in Aethelgard is 783 Post-Glitch (PG). No events, character states, or narrative references may describe occurrences after this date without explicit canon revision."
assertion_rule:
  type: temporal_bound
  parameter: current_year
  calendar: "Post-Glitch"
  value: 783
  operator: "<="
scope: universal
exceptions: []
testable: true

tags: [temporal, hard-constraint, calendar]
---
```

**Soft enforcement — narrative axiom:**

```yaml
---
type: axiom
name: Finality of Death
canon: true
summary: "Death in Aethelgard is permanent. No mechanism — magical, technological, or metaphysical — can resurrect the dead."

axiom_type: metaphysical
enforcement: soft
assertion: "Death is final in Aethelgard. The Ginnungagap Glitch severed all known resurrection pathways. Necromancy, cryogenic revival, and consciousness uploading are mythological or forbidden. No character, system, or event may reverse death without a canon-level axiom revision."
assertion_rule: null  # soft axioms are not deterministically testable
scope: universal
exceptions:
  - "Undead states (e.g., Draugr) are not resurrection — they are a corrupted state distinct from true life"
testable: false

tags: [metaphysical, soft-constraint, death-and-finality, narrative-tone]
---
```

### 9.9. Item Example

```yaml
---
type: item
name: Deadfuse Power Cell (Jury-Rigged)
canon: true
summary: "A makeshift power source built from scavenged Pre-Glitch components. Produces unstable current for 3-5 uses before catastrophic degradation."

era: [Age of Echoes]
region: null  # recipe known across scavenger communities

item_type: recipe
rarity: common  # the recipe is widely known; components are harder to find
origin_era: "~600 PG"  # developed by early Scavenger Baron artificers
creator: null  # folk knowledge, no single creator
condition: null  # not applicable to recipes
components:
  - "Corroded battery core (x2)"
  - "Iron filament wiring (1 bundle)"
  - "Bone-marrow paste (100 ml) — conductive binding agent"
  - "Tallow sealant (50 ml) — prevents oxidative failure"
  - "Ceramic housing (1, salvaged from Pre-Glitch tech)"
properties:
  - "Produces unstable low-voltage current"
  - "3-5 use cycles before critical degradation"
  - "Risk of discharge spike on failure — minor burn hazard"
sources:
  - "Scavenger Baron workshops"
  - "Pre-Glitch ruins (for ceramic housings)"

tags: [recipe, scavenged, bodge-work, power-source, consumable]
aliases: ["Deadfuse", "Jury-Rig Cell", "Baron Special"]
---
```

### 9.10. Document Example

```yaml
---
type: document
name: "Fragment 7: The Singing of the Forsaken"
canon: true
summary: "A fragmentary oral testimony describing shared consciousness experiences among the Forsaken, including references to 'singing beneath the ice' consistent with late-stage CPS."

era: [Age of Echoes]
date: "781 PG"  # date of recording
region: Niflheim

document_type: oral_history
author_in_world: "Jötun-Reader Solveig Frostbind"
recovery_location: "Niflheim Diplomatic Outpost"
classification_level: restricted
reliability: uncertain  # second-hand witness, subject became non-responsive mid-interview
language: "Common (translated from Fimbul-Cant fragments)"
completeness: partial  # interview terminated when subject became non-responsive

relationships:
  - target: "entities/forsaken.md"
    type: documents
  - target: "systems/cognitive-paradox-syndrome.md"
    type: documented_in
    note: "Contains descriptions consistent with late-stage CPS progression"

tags: [oral-history, forsaken, niflheim, cps, fragmentary, in-world-research]
aliases: ["Singing Fragment", "Frostbind Interview 7"]
---
```

### 9.11. Term Example

```yaml
---
type: term
name: Bodging
canon: true
summary: "The practice of improvised repair and construction using scavenged Pre-Glitch components, jury-rigged wiring, and whatever materials are at hand. The primary engineering discipline of post-Glitch Aethelgard."

term_type: jargon
language: "Common"
domain: [engineering, cultural, colloquial]
etymology: "Derived from Pre-Glitch English 'bodge' (to mend badly). Reclaimed by Scavenger Baron communities as a term of pride — 'a good bodge keeps you alive.'"
pronunciation: "BOJ-ing"
usage_context: "Universal across scavenger communities. Used both as a technical term (describing the craft) and a cultural identity marker. 'Bodger' is a respected professional title among Scavenger Barons."
related_terms: [Jury-rigging, Scavenging, Deadfuse]

tags: [jargon, engineering, scavenger-culture, post-glitch]
aliases: ["Bodge-work", "The Bodger's Art"]
---
```

### 9.12. Meta Example

```yaml
---
type: meta
name: Bestiary Entry Style Guide
canon: true
summary: "Editorial standards for composing entity (bestiary) entries. Establishes voice, structure, and tone for consistency across automata, Forsaken, fauna, and anomalies."

meta_type: style_guide
audience: [contributors]
applies_to: [entity]
authority: recommended
effective_date: "2026-02-10"
review_cycle: "as-needed"

tags: [style-guide, editorial, bestiary, voice-and-tone]
---
```

### 9.13. Custom Entity Type Example

```yaml
---
type: starship
name: ISS Prometheus
canon: true
summary: "The flagship of the Terran Expeditionary Fleet, a Titan-class battleship that led the assault on the Kepler Array."

era: [Expansion Era]
region: Kepler Sector

ship_class: battleship
crew_capacity: 4500
manufacturer: Olympus Shipyards
commission_date: "2847 CE"
armament: ["Gauss cannons (x8)", "Torpedo bays (x4)", "Point defense grid", "Experimental gravity lance"]

relationships:
  - target: "factions/terran-expeditionary-fleet.md"
    type: member_of
  - target: "characters/admiral-chen.md"
    type: commanded_by

tags: [military, flagship, active]
aliases: ["The Prometheus", "Old Fire"]
---
```

---

## 10. Formal Schema Definitions (JSON Schema)

### 10.1. Common Fields Schema

Stored at `.chronicle/schema/common.schema.json`. Composed with every entity type schema during validation.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://chronicle-tool.dev/schema/common.schema.json",
  "x-chronicle-version": "1.0.0",
  "title": "Chronicle Common Fields Schema",
  "description": "Fields shared across all Chronicle entity types.",
  "type": "object",
  "properties": {
    "type": {
      "type": "string",
      "minLength": 1,
      "description": "The entity type. Must match a known schema name."
    },
    "name": {
      "type": "string",
      "minLength": 1,
      "description": "The canonical display name."
    },
    "canon": {
      "oneOf": [
        { "type": "boolean" },
        { "type": "string", "enum": ["apocryphal", "deprecated"] }
      ],
      "description": "Canonical status."
    },
    "era": {
      "oneOf": [
        { "type": "string" },
        { "type": "array", "items": { "type": "string" } },
        { "type": "null" }
      ]
    },
    "date": { "type": ["string", "null"] },
    "region": {
      "oneOf": [
        { "type": "string" },
        { "type": "array", "items": { "type": "string" } },
        { "type": "null" }
      ]
    },
    "relationships": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "target": { "type": "string", "minLength": 1 },
          "type": { "type": "string", "minLength": 1 },
          "since": { "type": ["string", "null"] },
          "until": { "type": ["string", "null"] },
          "note": { "type": ["string", "null"] },
          "bidirectional": { "type": "boolean", "default": false }
        },
        "required": ["target", "type"],
        "additionalProperties": false
      },
      "default": []
    },
    "tags": { "type": "array", "items": { "type": "string" }, "default": [] },
    "aliases": { "type": "array", "items": { "type": "string" }, "default": [] },
    "superseded_by": { "type": ["string", "null"] },
    "supersedes": {
      "oneOf": [
        { "type": "string" },
        { "type": "array", "items": { "type": "string" } },
        { "type": "null" }
      ],
      "default": []
    },
    "last_validated": {
      "type": ["string", "null"],
      "pattern": "^\\d{4}-\\d{2}-\\d{2}$"
    },
    "summary": { "type": ["string", "null"] },
    "custom": { "type": "object", "additionalProperties": true, "default": {} },
    "parent": { "type": ["string", "null"] },
    "children": { "type": "array", "items": { "type": "string" }, "default": [] }
  },
  "required": ["type", "name", "canon"],
  "additionalProperties": true
}
```

**Note on `additionalProperties: true`:** The common schema allows additional properties because type-specific fields will also be present. The composed schema (common + type-specific) handles full validation.

### 10.2. Entity Type Schemas

Each entity type schema defines ONLY type-specific fields. Common fields are inherited via schema composition. The faction schema is shown as a representative example:

**`.chronicle/schema/faction.schema.json`:**

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://chronicle-tool.dev/schema/faction.schema.json",
  "x-chronicle-version": "1.0.0",
  "title": "Chronicle Faction Entity Schema",
  "type": "object",
  "properties": {
    "founded": { "type": ["string", "null"] },
    "dissolved": { "type": ["string", "null"] },
    "headquarters": { "type": ["string", "null"] },
    "leader": { "type": ["string", "null"] },
    "status": {
      "type": "string",
      "enum": ["active", "dissolved", "dormant", "fragmented", "unknown"],
      "default": "active"
    },
    "alignment": { "type": ["string", "null"] },
    "membership_size": { "type": ["string", "null"] }
  },
  "required": []
}
```

The remaining eleven entity type schemas follow the same pattern — each defines only its type-specific properties as documented in §5.1 through §5.12. The full JSON Schema files will be generated during Phase 2 implementation. The field tables in §5 serve as the authoritative source.

**Types with required type-specific fields:** `timeline` requires `start`. `entity` requires `entity_class`. `axiom` requires `axiom_type`, `enforcement`, and `assertion`. `item` requires `item_type`. `document` requires `document_type`. `term` requires `term_type`. `meta` requires `meta_type`.

### 10.3. Meta-Schema (Schema for Custom Schema Definitions)

The meta-schema at `.chronicle/schema/_meta.schema.json` validates user-created custom schemas:

1. File MUST be valid JSON.
2. Top-level `type` MUST be `"object"`.
3. MUST contain a `properties` key.
4. Property definitions MUST NOT redefine common field names.
5. SHOULD contain `x-chronicle-version`, `title`, and `description`.

---

## 11. Open Questions Resolved

### OQ-1: Multi-File Entities (Parent/Child Documents)

**Resolution:** Supported from day one via `parent` and `children` fields (§4.7). Nesting limited to two levels. Children inherit parent frontmatter unless overridden. Relationships are merged.

### OQ-2: Custom Entity Types from Day One

**Resolution:** Yes, supported from day one (§8). Users create JSON Schema files in `.chronicle/schema/custom/`.

### OQ-3: Fixed vs. Free-Form Relationship Types

**Resolution:** Recommended vocabulary with free-form allowed (§7.2, §7.3). Informational notice on non-standard types.

### Entity Type Taxonomy Expansion (Design Decision, D-10 v0.2.0)

**Decision:** Expanded from 6 to 12 default entity types. The original six (`faction`, `character`, `location`, `event`, `timeline`, `system`) were too narrow for the diversity of worldbuilding content. The additions are:

- `entity` — types of beings (biological, automaton, metaphysical)
- `axiom` — foundational truths with validator integration
- `item` — objects and substances (merged "item" and "material" concepts)
- `document` — in-world texts and narrative artifacts
- `term` — glossary entries and linguistic concepts
- `meta` — setting governance and process documentation

Additionally, `location` was renamed to `locale` and expanded to encompass hazard zones and biomes. `system` was broadened with medical, psychological, social, and cultural subtypes.

**Rationale:** The existing Aethelgard content includes bestiary entries (automata, fauna), in-world data captures, constructed dialects, medical conditions, scavenging recipes, and editorial standards — none of which mapped cleanly to the original six types. The expanded taxonomy provides natural homes for all of these while remaining generic enough for non-Aethelgard settings.

---

## 12. Migration Considerations

Existing Aethelgard content uses a different frontmatter format (with fields like `id`, `classification`, `source`, `category`, `total-fragments`, `layer`, `complexity`) that predates Chronicle's schema design. Migrating this content requires:

1. **Field mapping:** Translating existing fields to Chronicle equivalents (e.g., `status: draft` → `canon: false`, `category: Bestiary` → `type: entity`).
2. **Adding required fields:** Existing files lack `type`, `name`, and `canon` in the Chronicle format.
3. **Type assignment:** Bestiary entries → `entity`. Faction lore → `faction`. Data captures/fragments → `document`. Alchemy content → `system` or `item` (depending on whether it's a system description or a recipe). Linguistic content → `term`. Hazards → `locale` with `locale_type: hazard_zone`.
4. **Relationship creation:** Existing content has implicit cross-references in prose but no structured `relationships` blocks.
5. **Axiom extraction:** Implicit world constants scattered across documents should be formalized as `axiom` entries.

Content migration is NOT a prerequisite for Chronicle development. The tool can be developed and tested against synthetic data. Migration is partially covered by D-20 (Test Corpus Preparation Guide).

---

## 13. FractalRecall Context Layer Mapping

While the formal integration design is deferred to D-15 (blocked on Track B), this section documents the **intended mapping** between frontmatter fields and FractalRecall's standard context layers.

| FractalRecall Layer | Hierarchy Position | Chronicle Frontmatter Source |
|--------------------|--------------------|------------------------------|
| Corpus | 100 | Chronicle repository name (from `.chronicle/config.yaml`) |
| Domain | 90 | `type` field (entity type as categorical domain) |
| Entity | 80 | `name` field (specific identity) |
| Authority | 70 | `canon` field (canonical status) |
| Temporal | 60 | `era` and `date` fields |
| Relational | 50 | `relationships` block (simplified to key connections) |
| Section | 20 | Markdown heading structure (extracted at indexing time) |
| Content | 0 | Markdown body text |

**Design implications:** Every common frontmatter field maps to at least one FractalRecall context layer. Type-specific fields (like `entity_class`, `threat_level`, `item_type`) could enrich layer values, but the specific strategy depends on Track B prototyping results. Axiom entries may receive special treatment in the Authority layer (highest-authority content). Document entries with `reliability` metadata may influence retrieval weighting.

---

## 14. Dependencies and Cross-References

| Document | Relationship to D-10 |
|----------|----------------------|
| D-01: Design Proposal (§4.3) | **Upstream.** Provided initial frontmatter examples. D-10 formalizes, extends, and expands. |
| D-02: FractalRecall Conceptual Architecture | **Upstream (indirect).** Context layer design influenced common field choices. |
| D-04: Master Strategy (§6.3) | **Upstream.** Defined D-10's scope and requirements. |
| D-11: Canon Workflow Specification | **Downstream.** Defines behavioral rules for the `canon` field. |
| D-12: Validation Rule Catalog | **Downstream.** Defines validation checks enforcing D-10's constraints, including axiom `assertion_rule` syntax. |
| D-13: CLI Command Reference | **Downstream.** CLI commands interact with the schema system. |
| D-15: Integration Design Document | **Downstream (blocked).** Will formalize the FractalRecall mapping in §13. |

---

## 15. Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1.0-draft | 2026-02-10 | Ryan + Claude | Initial draft. Six default entity types, common fields, relationships, extensibility, JSON Schema definitions. Resolved OQ-1, OQ-2, OQ-3. |
| 0.2.0-draft | 2026-02-10 | Ryan + Claude | Major expansion: 6 → 12 default entity types. Added `entity`, `axiom`, `item`, `document`, `term`, `meta`. Renamed `location` → `locale` with hazard/biome support. Expanded `system` subtypes (medical, psychological, social, cultural, ecological). Merged "material" concept into `item`. Added 7 new frontmatter examples. Updated JSON Schema definitions. |
| 0.2.1-draft | 2026-02-10 | Ryan + Claude | Added `supersedes` common field to §4.6 (bidirectional partner to `superseded_by`). Added §4.8 (Superseding Mechanics) defining validation rules, many-to-one consolidation, chain resolution, and search behavior. Driven by D-11 design decision OQ-D11-7. Added `supersedes` to §10.1 JSON Schema (audit finding F-01). |

---

*This document defines Chronicle's data model. For content lifecycle rules, see D-11 (Canon Workflow Specification). For validation checks that enforce this schema, see D-12 (Validation Rule Catalog). For CLI commands that interact with the schema, see D-13 (CLI Command Reference).*
