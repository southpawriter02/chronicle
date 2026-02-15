# D-16: Worldbuilding Grammar Profile Specification

**Document ID:** D-16
**Version:** 0.1.1-draft
**Status:** Draft
**Author:** Ryan (with specification guidance from Claude)
**Created:** 2026-02-15
**Last Updated:** 2026-02-15
**Track:** Cross-Cutting (Track C / Integration)
**Dependencies:** v0.0.2b (Haiku Protocol Operator Design), D-10 (Lore File Schema Spec), D-02 (FractalRecall Conceptual Architecture), Haiku-Protocol-Integration-Assessment.docx
**Downstream Consumers:** D-15 (Integration Design Document), Haiku Protocol Phase 2 Encoder (worldbuilding profile), FractalRecall enrichment prefix pipeline

---

## Table of Contents

- [1. Document Purpose and Scope](#1-document-purpose-and-scope)
- [2. Background: The Procedural CNL](#2-background-the-procedural-cnl)
  - [2.1. What Haiku Protocol Is](#21-what-haiku-protocol-is)
  - [2.2. The Existing 12-Operator Grammar](#22-the-existing-12-operator-grammar)
  - [2.3. The Operator Specification Format](#23-the-operator-specification-format)
  - [2.4. Why This Matters for Worldbuilding](#24-why-this-matters-for-worldbuilding)
- [3. The Problem: Procedural vs. Narrative Content](#3-the-problem-procedural-vs-narrative-content)
  - [3.1. Structural Differences](#31-structural-differences)
  - [3.2. Semantic Differences](#32-semantic-differences)
  - [3.3. What the Existing Grammar Cannot Express](#33-what-the-existing-grammar-cannot-express)
- [4. Operator Compatibility Audit](#4-operator-compatibility-audit)
  - [4.1. Direct Mapping (No Changes Needed)](#41-direct-mapping-no-changes-needed)
  - [4.2. Adaptation Required (Reinterpretation)](#42-adaptation-required-reinterpretation)
  - [4.3. Replacement Required (New Operators)](#43-replacement-required-new-operators)
  - [4.4. Compatibility Matrix](#44-compatibility-matrix)
- [5. Worldbuilding Grammar Design Principles](#5-worldbuilding-grammar-design-principles)
- [6. New Worldbuilding Operators (Full Specification)](#6-new-worldbuilding-operators-full-specification)
  - [6.1. WB-001: ENTITY](#61-wb-001-entity)
  - [6.2. WB-002: RELATION](#62-wb-002-relation)
  - [6.3. WB-003: TEMPORAL](#63-wb-003-temporal)
  - [6.4. WB-004: CANON](#64-wb-004-canon)
  - [6.5. WB-005: DESC](#65-wb-005-desc)
- [7. Adapted Operators (Worldbuilding Reinterpretation)](#7-adapted-operators-worldbuilding-reinterpretation)
  - [7.1. META in Worldbuilding Context](#71-meta-in-worldbuilding-context)
  - [7.2. REF in Worldbuilding Context](#72-ref-in-worldbuilding-context)
  - [7.3. State in Worldbuilding Context](#73-state-in-worldbuilding-context)
  - [7.4. REQUIRES in Worldbuilding Context](#74-requires-in-worldbuilding-context)
  - [7.5. IF/THEN/ELSE in Worldbuilding Context](#75-ifthenelse-in-worldbuilding-context)
  - [7.6. VERIFY in Worldbuilding Context](#76-verify-in-worldbuilding-context)
  - [7.7. NOTE in Worldbuilding Context](#77-note-in-worldbuilding-context)
- [8. Composition Rules for Worldbuilding](#8-composition-rules-for-worldbuilding)
  - [8.1. Entity Declaration Block](#81-entity-declaration-block)
  - [8.2. Narrative Block](#82-narrative-block)
  - [8.3. Relational Block](#83-relational-block)
  - [8.4. Rule Block](#84-rule-block)
  - [8.5. Block Ordering Convention](#85-block-ordering-convention)
- [9. Worked Example: The Forsaken](#9-worked-example-the-forsaken)
  - [9.1. Source Material](#91-source-material)
  - [9.2. Compression Strategy](#92-compression-strategy)
  - [9.3. Full Haiku Encoding](#93-full-haiku-encoding)
  - [9.4. Compression Analysis](#94-compression-analysis)
- [10. FractalRecall Integration Surface](#10-fractalrecall-integration-surface)
  - [10.1. Operator-to-Layer Mapping](#101-operator-to-layer-mapping)
  - [10.2. Haiku as Enrichment Prefix](#102-haiku-as-enrichment-prefix)
  - [10.3. Compression as Layer Token Budget Solution](#103-compression-as-layer-token-budget-solution)
- [11. Token Budget Analysis](#11-token-budget-analysis)
  - [11.1. Estimated Compression Ratios](#111-estimated-compression-ratios)
  - [11.2. Comparison with Procedural Compression](#112-comparison-with-procedural-compression)
  - [11.3. Model Context Window Implications](#113-model-context-window-implications)
- [12. Decision Tree: When to Use Which Operator](#12-decision-tree-when-to-use-which-operator)
- [13. Open Questions and Decision Log](#13-open-questions-and-decision-log)
- [14. Dependencies and Cross-References](#14-dependencies-and-cross-references)
- [15. Document Revision History](#15-document-revision-history)

---

## 1. Document Purpose and Scope

This document formally specifies a **Worldbuilding Grammar Profile** for the Haiku Protocol's Controlled Natural Language (CNL). The Haiku Protocol was designed to compress procedural documentation (runbooks, deployment guides, operational procedures) into semantically dense, machine-parseable "haiku" encodings. This specification extends that grammar to handle **narrative and worldbuilding content** — the kind of structured fiction found in worldbuilding repositories like Aethelgard.

**Why this document exists:** The Chronicle + FractalRecall + Haiku Protocol initiative hypothesizes that Haiku Protocol's semantic compression can serve as a density layer for FractalRecall's embedding enrichment pipeline. Instead of prepending raw metadata text as enrichment prefixes (consuming 80-150 tokens per chunk, per D-23 §1), compressed haiku encodings of the same metadata could deliver equivalent semantic signal in significantly fewer tokens. This is especially critical for models with constrained context windows (e.g., `nomic-embed-text-v2-moe`'s 512-token limit, per R-01 findings).

However, the existing Haiku Protocol grammar was designed for procedural content and cannot express the core semantic patterns of worldbuilding: entities with attributes, inter-entity relationships, temporal contexts, canonical authority, and descriptive prose. This document bridges that gap.

**What this document covers:**

- A self-contained summary of Haiku Protocol's existing 12-operator grammar (so future AI sessions can work from this document alone without reading v0.0.2b)
- A systematic audit of which existing operators map to worldbuilding, which need adaptation, and which need replacement
- Full specifications for 5 new worldbuilding-specific operators (ENTITY, RELATION, TEMPORAL, CANON, DESC) following the same format as v0.0.2b
- Adaptation rules for 7 existing operators in worldbuilding context
- Composition rules for how operators chain together in narrative content
- A worked example compressing a real Aethelgard faction entry (The Forsaken) from YAML+Markdown to haiku form
- Analysis of how compressed haikus integrate with FractalRecall's 8 context layers
- Token budget analysis comparing worldbuilding compression ratios to procedural compression

**What this document does NOT cover:**

- Encoder implementation details (that's Haiku Protocol Phase 2+ work)
- The formal BNF grammar unification (that would be a v0.0.2c extension)
- FractalRecall's embedding pipeline implementation (that's D-15 / Phase 2)
- Empirical validation of compression quality (that depends on Track B Colab results)

**Relationship to the Grammar Profile concept:** This document defines a "grammar profile" — a domain-specific operator set and composition ruleset that extends the base Haiku Protocol grammar. The procedural grammar (v0.0.2b) becomes the "Procedural Profile." This document defines the "Worldbuilding Profile." Future profiles could target other domains (legal, medical, academic) using the same extension mechanism. The shared CNL specification recommended in the Integration Assessment (Option C) would define the profile system formally; this document is the first concrete profile.

---

## 2. Background: The Procedural CNL

This section provides a self-contained summary of Haiku Protocol's existing grammar. A future AI session should be able to understand the worldbuilding extensions in §6-§8 after reading only this section, without needing to consult v0.0.2b directly.

### 2.1. What Haiku Protocol Is

Haiku Protocol is a semantic compression system that transforms verbose natural-language documentation into dense, structured encodings called "haikus." It uses a Controlled Natural Language (CNL) — a restricted subset of English with formal syntax rules — to represent the semantic content of documents in a fraction of the original token count.

The compression pipeline has four stages:

1. **Chunker** — Splits source documents into semantic units (fully implemented in Phase 2, v0.2.1, with 107 tests passing)
2. **Extractor** — Identifies semantic patterns in each chunk (stub — Phase 2 future work)
3. **Synthesizer** — Encodes extracted patterns into haiku form using the CNL grammar (stub)
4. **Validator** — Checks encoded haiku for syntactic and semantic correctness (stub)

The CNL grammar is the heart of the system. It defines a set of **operators** — typed semantic primitives — that can be composed into structured expressions. Each operator has a formal syntax (BNF production rule), defined semantics, precedence level, and composition rules governing how it chains with other operators.

### 2.2. The Existing 12-Operator Grammar

The procedural grammar (v0.0.2b) defines 12 operators derived from corpus analysis of technical documentation. These operators were designed to encode the semantic patterns found in runbooks, deployment guides, and operational procedures.

| ID | Operator | Symbol | Semantics | Precedence |
|----|----------|--------|-----------|------------|
| OP-001 | **Action** | `Action:` | A single imperative procedure step (run, create, deploy) | 5 |
| OP-002 | **State** | `State:` | A precondition or postcondition (online, configured, exists) | 6 |
| OP-003 | **REQUIRES** | `REQUIRES` | Dependency declaration — action cannot execute until states are true | 7 |
| OP-004 | **EXEC** | `EXEC:` or `→` | Attaches a concrete executable command to an action | 4 |
| OP-005 | **IF/THEN/ELSE** | `IF:` `THEN:` `ELSE:` | Conditional branching based on test results or state checks | 3 |
| OP-006 | **WARN** | `WARN:` or `⚠` | Declares that an action carries a risk or consequence (advisory) | 5 |
| OP-007 | **VERIFY** | `VERIFY:` or `✓` | Post-action check or assertion — confirms success | 5 |
| OP-008 | **SEQ** | `SEQ:` or `;` | Explicit sequential ordering of statements | 2 |
| OP-009 | **REF** | `REF:` or `→ref` | Cross-reference to another document or section | 8 |
| OP-010 | **META** | `META:` or `@` | Machine-readable metadata annotation (version, author, etc.) | 9 |
| OP-011 | **LOOP** | `LOOP:` or `⟳` | Repetition / iteration (count-based or condition-based) | 3 |
| OP-012 | **NOTE** | `NOTE:` or `#` | Non-critical information, tips, optional guidance | 10 |

**Naming conventions:**

- Identifiers (Actions, States, References): `PascalCase_With_Underscores` (e.g., `Action:Backup_Database`)
- Commands (in EXEC): lowercase with hyphens or shell syntax (e.g., `EXEC:docker build -t myapp:latest`)
- Metadata keys (in META): `lowercase_with_underscores` (e.g., `META:version=1.0`)

**Composition model:** Operators compose left-to-right with semicolon (`;`) as the statement separator. REQUIRES preconditions must be satisfied before their associated Action. IF/THEN/ELSE introduces branching. VERIFY follows Action/EXEC to check success. META appears at the beginning of a haiku. NOTE and WARN are advisory annotations.

**Example of a complete procedural haiku:**

```
META:version=1.0; META:author=SRE_Team;
Action:Backup_DB REQUIRES State:DB_Online -> EXEC:backup.sh;
VERIFY:Backup_File_Exists;
Action:Deploy -> EXEC:deploy.sh;
IF:Deploy_Fail THEN:Action:Rollback ELSE:VERIFY:Service_Running;
WARN:Skip_Backup -> Data_Loss
```

This encodes what might be a full page of deployment documentation into ~50 tokens.

### 2.3. The Operator Specification Format

Every operator in the Haiku Protocol follows a standardized specification format. The worldbuilding operators in §6 use the same format to ensure consistency:

```python
class OperatorSpec(TypedDict):
    id: str                    # e.g., "WB-001"
    name: str                  # e.g., "ENTITY"
    symbol: str                # e.g., "ENTITY:" or "E:"
    syntax: str                # BNF production rule
    semantics: str             # Detailed meaning
    example_before: str        # Verbose natural language
    example_after: str         # Haiku encoding
    precedence: int            # 0-10 (10 = highest binding)
    composable_with: List[str] # Operator IDs that can follow
    edge_cases: List[str]      # Known edge cases
    notes: str                 # Implementation guidance
```

### 2.4. Why This Matters for Worldbuilding

The procedural grammar excels at encoding _what to do_ — imperative sequences with preconditions, verification, and error handling. Worldbuilding content is fundamentally different: it describes _what exists_ — declarative statements about entities, their properties, their relationships, and their history.

Consider a faction entry like The Forsaken from the Aethelgard corpus. The content includes:

- **Entity identity:** The Forsaken are a status class in Niflheim, not a political faction
- **Relationships:** Subservient to Scavenger Barons, envied by outsiders, founded ~Year 47 PG
- **Temporal context:** Age of Echoes (contemporary, 783 PG), with historical roots in Year 47 PG
- **Quantitative attributes:** Population 12,000-18,000, economic system (Ice-Debt, 2-4 Cog-Units/day)
- **Cultural artifacts:** Fimbul-Cant dialect, Gutter-Sagas oral tradition, "Fear the Calm" survival wisdom
- **Canon status:** Draft, Layer 2 diagnostic

None of these patterns map cleanly to `Action:`, `EXEC:`, `SEQ:`, or `LOOP:`. They require new operators that encode entity declarations, relationships, temporal contexts, canonical authority, and descriptive summaries.

---

## 3. The Problem: Procedural vs. Narrative Content

### 3.1. Structural Differences

Procedural documents and worldbuilding documents differ in fundamental structure:

| Dimension | Procedural Content | Worldbuilding Content |
|-----------|-------------------|----------------------|
| **Primary mode** | Imperative ("do this") | Declarative ("this exists / is true") |
| **Flow** | Sequential (step 1 → step 2 → step 3) | Hierarchical (entity → attributes → relationships) |
| **Time model** | Real-time execution (now, next, then) | Historical / narrative time (eras, dates, events) |
| **Entities** | Systems, services, infrastructure | Characters, factions, locations, items |
| **Relationships** | Dependencies (A requires B) | Semantic connections (A founded B, A rivals C) |
| **Verification** | State checks (is service running?) | Canon consistency (does this contradict established lore?) |
| **Metadata** | Version, author, prerequisites | Entity type, canon status, era, domain |
| **Typical document** | 1-5 pages, linear | 2-20 pages, multi-section with fragments |

### 3.2. Semantic Differences

The procedural grammar's 12 operators were derived from corpus analysis of technical documentation (v0.0.2a). A comparable corpus analysis of the Aethelgard worldbuilding repository reveals a different set of dominant semantic patterns:

| Semantic Pattern | Frequency in Procedural Corpus | Frequency in Worldbuilding Corpus | Existing Operator |
|-----------------|-------------------------------|----------------------------------|-------------------|
| Entity declaration | Rare | **Very High** | None |
| Attribute assignment | Rare | **Very High** | None (META is closest) |
| Relationship assertion | Low (dependency only) | **Very High** | REQUIRES (partial) |
| Temporal positioning | None | **High** | None |
| Canonical authority | None | **High** | None |
| Descriptive prose | Low (NOTE) | **Very High** | NOTE (inadequate) |
| Imperative action | **Very High** | Low | Action |
| Command execution | **Very High** | None | EXEC |
| Sequential ordering | **High** | Medium | SEQ |
| Iteration/loops | **High** | None | LOOP |
| Risk declaration | **High** | Low | WARN |

The mismatch is clear: the 5 most frequent patterns in worldbuilding content have no direct operator, while the 3 most frequent patterns in procedural content (imperative action, command execution, iteration) are nearly absent from worldbuilding.

### 3.3. What the Existing Grammar Cannot Express

Here are concrete examples of worldbuilding content that the procedural grammar cannot encode:

**Example 1: Entity Identity**
```
Source: "The Forsaken are not a people. They are a condition — the terminal
status of those who have fallen through every other social safety net post-Glitch
Aethelgard provides."

Problem: No operator for "X is Y" (declarative identity assertion).
Action: is imperative. State: is binary (online/offline). META: is key-value
metadata about the document, not the entity.
```

**Example 2: Rich Relationships**
```
Source: "Baron Ironjaw offered freezing refugees a binary choice: swear fealty
or die. Those who swore became the first links in what their descendants call
'the Rusted Chain.'"

Problem: REQUIRES can encode "A depends on B" but not "A was founded by B"
or "A exploits C through mechanism D." The relationship vocabulary here
(fealty, exploitation, ancestral inheritance) has no procedural analog.
```

**Example 3: Temporal Positioning**
```
Source: "The Forsaken emerged approximately Year 47 PG, when the first
Scavenger Barons offered freezing refugees a binary choice."

Problem: No operator for "Event X occurred at Time Y." The procedural grammar
has no time model beyond "now" and "next."
```

**Example 4: Quantitative Worldbuilding Data**
```
Source: "Population: 12,000-18,000 individuals. Daily overhead: 2-4 Cog-Units.
Salvage labor credit: 1-3 Cog-Units/day."

Problem: These are neither actions nor states. They're entity attributes with
numeric ranges. META could store them as key-value pairs, but loses the semantic
structure (what kind of attribute? what unit? what's the context?).
```

---

## 4. Operator Compatibility Audit

This section systematically evaluates each of the 12 existing operators against worldbuilding content, categorizing them as "direct mapping," "adaptation required," or "replacement required."

### 4.1. Direct Mapping (No Changes Needed)

These operators work as-is in worldbuilding context:

**META (OP-010):** Worldbuilding documents have rich metadata — entity type, document version, author, era, layer, complexity. META's key-value syntax handles all of these naturally.

**REF (OP-009):** Cross-references are even more important in worldbuilding than in procedures. Entities reference other entities constantly ("See: Scavenger Barons dossier," "Cross-reference: CPS hazard documentation"). REF's syntax is fully adequate.

**NOTE (OP-012):** Integration notes, editorial commentary, and non-canonical observations all map to NOTE. The operator's "advisory, non-executable" semantics are exactly right.

**SEQ (OP-008):** While worldbuilding content is less sequential than procedures, ordered lists do appear (genesis pathways, historical timelines, fragment sequences). SEQ/semicolon composition works as-is.

### 4.2. Adaptation Required (Reinterpretation)

These operators retain their syntax but gain new semantic interpretations in worldbuilding context:

**State (OP-002):** In procedures, State represents system conditions (online/offline). In worldbuilding, State represents **entity status** — the current condition of a faction, character, or location. Examples: `State:Faction_Active`, `State:Character_Deceased`, `State:Locale_Hazardous`. The syntax is unchanged; the semantic domain broadens from infrastructure to narrative entities.

**REQUIRES (OP-003):** In procedures, REQUIRES declares execution dependencies. In worldbuilding, REQUIRES declares **narrative preconditions** — facts that must be true for an assertion to hold. Example: `ENTITY:Ice_Debt REQUIRES State:Baron_Controls_Dreadnought` — the Ice-Debt system only functions because Barons control access to warmth. This is a lore-level dependency, not an execution dependency.

**IF/THEN/ELSE (OP-005):** In procedures, IF tests runtime conditions. In worldbuilding, IF encodes **conditional lore** — assertions that are true only under certain circumstances. Example: `IF:Baron_Death THEN:State:Forsaken_Temporarily_Free ELSE:State:Ice_Debt_Continues`. This maps conditional worldbuilding mechanics (what happens when a Baron dies?) into the same branching structure.

**VERIFY (OP-007):** In procedures, VERIFY checks that an action succeeded. In worldbuilding, VERIFY asserts **canon consistency** — that a statement doesn't contradict established lore. Example: `VERIFY:Forsaken_Population_Consistent_With_Census`. This becomes a validation hook that Chronicle's canon workflow (D-11) can check.

**WARN (OP-006):** In procedures, WARN flags operational risks. In worldbuilding, WARN flags **canon risks or contradictions** — statements that are potentially inconsistent with other lore. Example: `WARN:Population_Estimate_Exceeds_Dreadnought_Capacity -> Verify_With_Architecture_Specs`. Less common than in procedures, but still meaningful.

### 4.3. Replacement Required (New Operators)

These procedural operators have no meaningful worldbuilding analog and are **not included in the Worldbuilding Profile**:

**Action (OP-001):** Imperative procedure steps ("run this command") don't appear in worldbuilding content. Entities don't execute commands — they have attributes and relationships. **Replaced by:** ENTITY (declarations) and DESC (descriptions).

**EXEC (OP-004):** Shell/script commands are exclusively procedural. No worldbuilding equivalent. **Replaced by:** No direct replacement needed; the concept doesn't exist in the worldbuilding domain.

**LOOP (OP-011):** Iteration and retry logic are procedural patterns. Worldbuilding doesn't have "repeat 3 times" semantics. (Recurring events are encoded as TEMPORAL patterns, not loops.) **Replaced by:** TEMPORAL handles cyclical/recurring events differently.

### 4.4. Compatibility Matrix

| Operator | Procedural Profile | Worldbuilding Profile | Notes |
|----------|-------------------|----------------------|-------|
| Action (OP-001) | ✅ Core | ❌ Not included | Replaced by ENTITY + DESC |
| State (OP-002) | ✅ Core | ✅ Adapted | Broadened to entity status |
| REQUIRES (OP-003) | ✅ Core | ✅ Adapted | Broadened to narrative preconditions |
| EXEC (OP-004) | ✅ Core | ❌ Not included | No worldbuilding equivalent |
| IF/THEN/ELSE (OP-005) | ✅ Core | ✅ Adapted | Conditional lore mechanics |
| WARN (OP-006) | ✅ Core | ✅ Adapted | Canon risk flagging |
| VERIFY (OP-007) | ✅ Core | ✅ Adapted | Canon consistency assertions |
| SEQ (OP-008) | ✅ Core | ✅ Direct | Unchanged |
| REF (OP-009) | ✅ Core | ✅ Direct | Unchanged |
| META (OP-010) | ✅ Core | ✅ Direct | Unchanged |
| LOOP (OP-011) | ✅ Bonus | ❌ Not included | Replaced by TEMPORAL |
| NOTE (OP-012) | ✅ Bonus | ✅ Direct | Unchanged |
| ENTITY (WB-001) | — | ✅ **New** | Entity declaration |
| RELATION (WB-002) | — | ✅ **New** | Inter-entity relationships |
| TEMPORAL (WB-003) | — | ✅ **New** | Time positioning |
| CANON (WB-004) | — | ✅ **New** | Canonical authority level |
| DESC (WB-005) | — | ✅ **New** | Compressed descriptive prose |

**Worldbuilding Profile operator count:** 12 (5 new + 7 reused from procedural)

---

## 5. Worldbuilding Grammar Design Principles

The procedural grammar was built on five design principles (§ Operator Design Principles in v0.0.2b). The worldbuilding profile inherits the same five and adds two worldbuilding-specific principles:

```
┌────────────────────────────────────────────────────────┐
│ 1. MINIMAL AMBIGUITY (inherited)                       │
│    Each operator maps to one semantic meaning.         │
│    No conflation of concepts.                          │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ 2. MAXIMUM EXPRESSIVENESS (inherited, reframed)        │
│    Operators cover 95%+ of WORLDBUILDING patterns      │
│    from Aethelgard corpus analysis.                    │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ 3. CONSISTENT SYNTAX (inherited)                       │
│    All operators follow shared naming and              │
│    structure conventions from v0.0.2b.                 │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ 4. COMPOSABILITY (inherited)                           │
│    Operators chain together predictably.               │
│    No unexpected side effects.                         │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ 5. HUMAN READABILITY (inherited)                       │
│    Compressed but still interpretable by               │
│    worldbuilders without full decoding.                │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ 6. SCHEMA ALIGNMENT (new)                              │
│    Worldbuilding operators map directly to Chronicle   │
│    D-10 schema fields. ENTITY types mirror D-10's 12  │
│    entity types. RELATION vocabulary mirrors D-10 §7.  │
│    This ensures the grammar encodes the same data      │
│    model that Chronicle validates.                     │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ 7. LAYER AWARENESS (new)                               │
│    Operators are designed with FractalRecall's 8       │
│    context layers in mind (see §10.1 for the full     │
│    operator-to-layer mapping). Each operator produces  │
│    output that maps to one or more FractalRecall       │
│    layers (Corpus, Domain, Entity, Authority,          │
│    Temporal, Relational, Section, Content — as         │
│    defined in D-02 and used in D-23).                  │
│    Compressed haiku output can serve directly as       │
│    enrichment prefix material.                         │
└────────────────────────────────────────────────────────┘
```

---

## 6. New Worldbuilding Operators (Full Specification)

---

### 6.1. WB-001: ENTITY

**Name:** Entity Declaration

**Symbol:** `ENTITY:` or `E:`

**Syntax:**
```
<entity>       ::= 'ENTITY:' <entity_type> ':' <identifier> <attrs>?
<entity_type>  ::= 'faction' | 'character' | 'entity' | 'locale' | 'event'
                 | 'timeline' | 'system' | 'axiom' | 'item' | 'document'
                 | 'term' | 'meta' | <custom_type>
<identifier>   ::= [A-Za-z_][A-Za-z0-9_ ]*
<attrs>        ::= '{' <attr_list> '}'
<attr_list>    ::= <attr> (',' <attr>)*
<attr>         ::= <key> '=' <value>
<key>          ::= [A-Za-z_][A-Za-z0-9_]*
<value>        ::= [^,}]+
<custom_type>  ::= [a-z_]+
```

**Semantics:**
Declares a worldbuilding entity with a typed identity and optional inline attributes. This is the foundational operator of the worldbuilding profile — equivalent to Action in the procedural profile. Every worldbuilding haiku contains at least one ENTITY declaration. The `entity_type` must be one of D-10's 12 default entity types or a custom type registered in `.chronicle/schema/custom/`.

The optional attribute block `{...}` supports inline key-value pairs for compact metadata. This is syntactic sugar — the same information could be expressed as multiple META operators — but it dramatically reduces token count for entities with many attributes.

**Example:**
```
BEFORE:
"The Forsaken are a faction in the Aethelgard worldbuilding corpus. They are
a status class of indentured laborers in the realm of Niflheim, bound by
Ice-Debt to the Scavenger Barons. Population: 12,000-18,000. Status: active."

AFTER:
ENTITY:faction:The_Forsaken {population=12000-18000, status=active,
  realm=Niflheim, classification=status_class}
```

**Another Example:**
```
BEFORE:
"Fimbul-Cant is a pidgin dialect spoken by the Forsaken in Niflheim.
It is classified as a constructed dialect (pidgin) with approximately
107 documented terms."

AFTER:
ENTITY:term:Fimbul-Cant {term_type=dialect, subtype=pidgin,
  speakers=Forsaken, documented_terms=107}
```

**Precedence:** 9 (highest — entity declarations are primary structural elements)

**Composable With:** RELATION, TEMPORAL, CANON, DESC, META, REF, State, NOTE

**Edge Cases:**
- Entity with no attributes: `ENTITY:character:Helga` (valid — attributes can be added later via separate operators)
- Entity with complex attribute values: `ENTITY:system:Ice_Debt {daily_overhead=2-4_Cog_Units, discharge_rate=impossible}` — ranges and qualitative values are stored as strings
- Entity referencing another entity in attributes: `ENTITY:faction:Forsaken {leader=None, master=Scavenger_Barons}` — use RELATION for formal relationships; inline attributes are for simple values
- Custom entity type: `ENTITY:dialect:Fimbul-Cant` — requires corresponding custom schema in `.chronicle/schema/custom/`
- Multi-file child entity: `ENTITY:faction:Forsaken:Ice_Debt_System` — colon-delimited path for parent/child entities (D-10 §4.7)

**Notes:**
- Entity type values MUST align with D-10 §5 (the 12 default types). Using an unrecognized type should produce a validation warning unless it's a registered custom type.
- The identifier allows spaces (e.g., `The_Forsaken` or `Ice-Debt_System`) using underscores. This departs from v0.0.2b's strict PascalCase convention because worldbuilding names are often multi-word and readability is critical.
- Attribute keys follow META's `lowercase_with_underscores` convention.
- ENTITY is the worldbuilding analog of Action — it's the "fundamental unit" that every haiku contains.

**FractalRecall Layer Mapping:** ENTITY produces output for the **Domain** layer (entity type) and the **Entity** layer (specific identity).

---

### 6.2. WB-002: RELATION

**Name:** Relationship Declaration

**Symbol:** `RELATION:` or `R:`

**Syntax:**
```
<relation>     ::= 'RELATION:' <source> <rel_type> <target> <qualifier>?
<source>       ::= <identifier>
<target>       ::= <identifier>
<rel_type>     ::= <recommended_type> | <free_form_type>
<recommended_type> ::= 'founded_by' | 'leader_of' | 'member_of' | 'allied_with'
                     | 'rival_of' | 'located_in' | 'created_by' | 'parent_of'
                     | 'child_of' | 'employs' | 'worships' | 'trades_with'
                     | 'conflicts_with' | 'mentors' | 'originates_from'
                     | 'governs' | 'inhabits' | 'studies' | 'exploits'
                     | 'protects' | 'fears' | 'succeeded_by' | 'preceded_by'
                     | 'variant_of' | 'component_of' | 'supersedes'
<free_form_type> ::= [a-z_]+
<qualifier>    ::= '(' <text> ')'
<text>         ::= [^)]+
```

**Semantics:**
Declares a directed relationship between two entities. The relationship has a typed verb (from D-10 §7.2's recommended vocabulary or free-form), a source entity, a target entity, and an optional qualifier providing context. Relationships are the worldbuilding analog of REQUIRES — they encode how entities connect — but with a much richer vocabulary than binary dependency.

The relationship vocabulary is drawn directly from D-10 §7.2's recommended relationship types (~30 types). Free-form relationship types are allowed (per D-10 §7.3) but should produce an informational notice during validation, consistent with Chronicle's validation behavior.

**Example:**
```
BEFORE:
"The Forsaken emerged approximately Year 47 PG, when the first Scavenger
Barons offered freezing refugees a binary choice: swear fealty or die."

AFTER:
RELATION:Forsaken exploits Scavenger_Barons (Ice-Debt_indenture_system);
RELATION:Scavenger_Barons founded_by first_refugees (Year_47_PG)
```

**Another Example:**
```
BEFORE:
"One-Eyed Helga defeated a Cryo-Vörðr and dragged its core back to
Baron Grímr, who credited her three months off her debt."

AFTER:
RELATION:Helga conflicts_with Cryo-Vordr (defeated_in_salvage_zone);
RELATION:Helga trades_with Baron_Grimr (core_for_3_months_debt_credit)
```

**Precedence:** 7 (high — relationships are structural elements, binding tighter than descriptions)

**Composable With:** ENTITY, TEMPORAL, CANON, NOTE, REF

**Edge Cases:**
- Self-referential relationship: `RELATION:Forsaken exploits Forsaken (internal_hierarchy)` — valid but unusual; flag for review
- Bidirectional relationship: Express as two RELATION operators. `RELATION:A allied_with B; RELATION:B allied_with A`. D-10 §7.4 defines which relationship types are inherently bidirectional.
- Relationship with no qualifier: `RELATION:Forsaken located_in Niflheim` — qualifier is optional
- Relationship involving non-entity target: `RELATION:Forsaken fears silence (CPS_onset_risk)` — targets can be abstract concepts, not just named entities
- Relationship chain: `RELATION:A founded_by B; RELATION:B mentors C` — chains are expressed as separate operators, not nested

**Notes:**
- Relationship direction matters. `RELATION:A exploits B` is not the same as `RELATION:B exploits A`. Use the natural language reading: "A exploits B."
- The recommended vocabulary is not exhaustive. Free-form types like `enslaves`, `envy`, `mythologizes` are valid when no recommended type captures the semantics. Chronicle will emit an informational notice (not an error) for non-standard types, per D-12 validation rules.
- Qualifiers in parentheses are free-text context — they're not parsed formally but are preserved in the haiku for human readability and decoder enrichment.

**FractalRecall Layer Mapping:** RELATION produces output for the **Relational** layer.

---

### 6.3. WB-003: TEMPORAL

**Name:** Temporal Positioning

**Symbol:** `TEMPORAL:` or `T:`

**Syntax:**
```
<temporal>     ::= 'TEMPORAL:' <time_spec> (':' <scope>)?
<time_spec>    ::= <absolute_time> | <relative_time> | <era_ref> | <span>
<absolute_time> ::= 'Year_' <integer> ('_' <calendar>)?
<relative_time> ::= '~' <integer> '_' <unit> ('_' <direction>)?
<era_ref>      ::= <identifier>
<span>         ::= <time_spec> '-' <time_spec>
<calendar>     ::= 'PG' | 'BG' | 'CE' | <custom_calendar>
<unit>         ::= 'years' | 'decades' | 'centuries' | 'generations'
<direction>    ::= 'ago' | 'hence'
<scope>        ::= 'point' | 'period' | 'era' | 'ongoing'
```

**Semantics:**
Positions content in narrative time. Unlike the procedural grammar, which has no time model beyond "now" and "next," worldbuilding content exists in complex temporal contexts — specific years, historical eras, date ranges, and relative time references. TEMPORAL declares when something happened, when it was true, or what era it belongs to.

The `scope` qualifier clarifies whether the temporal reference is a point event, a period, an era label, or an ongoing condition. This matters for FractalRecall's Temporal context layer — a faction that existed "Year 47 PG through present" needs different enrichment than a battle that happened "Year 761 PG" (point event).

**Example:**
```
BEFORE:
"The Forsaken emerged approximately Year 47 PG, when the first Scavenger
Barons offered freezing refugees a binary choice."

AFTER:
TEMPORAL:Year_47_PG:point (founding_of_Forsaken_status_class)
```

**Another Example:**
```
BEFORE:
"Era: Age of Echoes (Contemporary, 783 PG). The Forsaken have existed
for approximately 736 years."

AFTER:
TEMPORAL:Age_of_Echoes:era;
TEMPORAL:Year_47_PG-Year_783_PG:period (Forsaken_existence_span)
```

**Another Example:**
```
BEFORE:
"When Baron Ironjaw's vessel suffered core breach (Year 761 PG)..."

AFTER:
TEMPORAL:Year_761_PG:point (Baron_Ironjaw_core_breach)
```

**Precedence:** 6 (mid-high — temporal context qualifies entities and relationships)

**Composable With:** ENTITY, RELATION, DESC, CANON, NOTE

**Edge Cases:**
- Uncertain dates: `TEMPORAL:~Year_47_PG:point` — tilde prefix indicates approximation
- Recurring events: `TEMPORAL:cyclical:ongoing (Baron_death_and_re-enslavement_cycle)` — use `ongoing` scope for recurring patterns
- Multiple calendars: `TEMPORAL:Year_783_PG:point; TEMPORAL:Year_1447_CE:point` — when a worldbuilding setting maps to real-world calendars (rare for Aethelgard)
- No specific date: `TEMPORAL:Age_of_Echoes:era` — era-level positioning without a specific year
- Pre-history: `TEMPORAL:Pre-Glitch:era` — calendar-relative positioning

**Notes:**
- The `PG` calendar suffix stands for "Post-Glitch" — Aethelgard's calendar epoch. Other settings would define their own calendar identifiers. The grammar is calendar-agnostic; `PG` is just an identifier.
- TEMPORAL operators often appear immediately after the ENTITY they qualify: `ENTITY:event:Founding_Oath; TEMPORAL:Year_47_PG:point`
- For D-10 alignment: TEMPORAL maps to the `era` and `date` common fields in the Lore File Schema.

**FractalRecall Layer Mapping:** TEMPORAL produces output for the **Temporal** layer.

---

### 6.4. WB-004: CANON

**Name:** Canonical Authority Declaration

**Symbol:** `CANON:` or `C:`

**Syntax:**
```
<canon>        ::= 'CANON:' <authority_level> (':' <source>)?
<authority_level> ::= 'true' | 'false' | 'apocryphal' | 'deprecated'
                    | 'contested' | 'speculative'
<source>       ::= <identifier>
```

**Semantics:**
Declares the canonical authority of the content — whether the information is established truth in the worldbuilding setting, a draft, apocryphal (excluded from canonical queries), deprecated (superseded by newer lore), contested (multiple conflicting accounts), or speculative (theoretical/unconfirmed).

This operator is unique to worldbuilding and has no procedural analog. It maps directly to D-10's `canon` field (§4.2) and D-11's canon workflow state machine. The authority level determines how the content should be treated during retrieval — canonical content is authoritative, apocryphal content is excluded from standard queries, deprecated content points to its superseding entry.

The optional `source` qualifier identifies who or what establishes the authority — useful for contested lore where different in-world factions disagree about facts.

**Example:**
```
BEFORE:
"Status: draft. Layer: L2 (Diagnostic). This faction entry is compiled
from multiple Scriptorium sources and is considered accurate but not yet
formally canonized."

AFTER:
CANON:false:Scriptorium_Compilation
```

**Another Example:**
```
BEFORE:
"The population estimate of 12,000-18,000 is based on Dvergr census data
and may be inaccurate. The Forsaken themselves do not keep records."

AFTER:
CANON:contested:Dvergr_Census (Forsaken_have_no_records)
```

**Another Example:**
```
BEFORE:
"This account of the Founding Oath is canonical within the Aethelgard
setting, established across multiple corroborating sources."

AFTER:
CANON:true
```

**Precedence:** 8 (high — authority level is a fundamental qualifier)

**Composable With:** ENTITY, DESC, RELATION, TEMPORAL, VERIFY

**Edge Cases:**
- Content with mixed authority: Use multiple CANON operators scoping different sections. `CANON:true (population_data); CANON:speculative (CPS_neurological_restructuring)`
- Apocryphal content: `CANON:apocryphal` — excluded from standard retrieval per D-11's apocryphal semantics
- Deprecated content: `CANON:deprecated:superseded_by=Forsaken_v2` — include supersession reference
- Authority without source: `CANON:true` — source is optional when authority is unambiguous

**Notes:**
- The four core authority levels (`true`, `false`, `apocryphal`, `deprecated`) are from D-10 §4.2 and D-11. The additions `contested` and `speculative` are proposed for the worldbuilding profile because narrative content frequently has in-world disagreements and unconfirmed theories that need encoding.
- Adding `contested` and `speculative` to the CANON vocabulary is a **design decision** (OQ-D16-1) that would need to be reflected in D-10 and D-11 if accepted. For now, they are Profile-level extensions.
- CANON at the haiku level sets the default authority. Individual statements within the haiku can override with their own CANON operator.

**FractalRecall Layer Mapping:** CANON produces output for the **Authority** layer.

---

### 6.5. WB-005: DESC

**Name:** Compressed Description

**Symbol:** `DESC:` or `D:`

**Syntax:**
```
<description>  ::= 'DESC:' <category> ':' <text>
<category>     ::= 'identity' | 'appearance' | 'behavior' | 'culture'
                 | 'economy' | 'biology' | 'language' | 'history'
                 | 'politics' | 'geography' | 'military' | 'religion'
                 | 'technology' | 'custom'
<text>         ::= [^;]+
```

**Semantics:**
Encodes a compressed prose summary of an aspect of a worldbuilding entity. DESC is the worldbuilding analog of NOTE but with a critical difference: while NOTE is advisory and ignorable, DESC carries semantic content that is essential to understanding the entity. DESC operates in a different mode than other operators — it contains compressed natural language rather than structured key-value data.

The `category` qualifier classifies what aspect of the entity the description covers. This is important for two reasons: (1) it enables selective retrieval ("show me only the economy descriptions"), and (2) it maps to FractalRecall's Section-level context layer, allowing enrichment prefixes to include relevant category information.

**Compression style for DESC:** The text within a DESC operator should be **maximally compressed natural language** — not full sentences, but not pure keywords either. Think of it as a telegram: remove articles, minimize prepositions, use semicolons for clause separation, preserve key nouns and verbs. This is where the "haiku" metaphor is most literal.

**Example:**
```
BEFORE:
"The Forsaken are not a people. They are a condition — the terminal status
of those who have fallen through every other social safety net post-Glitch
Aethelgard provides. This distinction, often overlooked by external observers,
is foundational to understanding Niflheim's dominant population."

AFTER:
DESC:identity:Status_class_not_ethnic_group; terminal_social_category;
  bound_by_circumstance_not_blood; Niflheim_dominant_population
```

**Another Example:**
```
BEFORE:
"Fimbul-Cant exhibits diagnostic linguistic markers: Cold/Temperature: 23
terms (vs. 7 standard). Debt/Obligation: 31 terms (vs. 12 standard).
No word for 'future' beyond 'next shift'. No word for 'home' — only 'berth'."

AFTER:
DESC:language:Fimbul-Cant; survival-optimized_pidgin; cold=23_terms(vs_7);
  debt=31_terms(vs_12); no_future/home/hope_vocabulary;
  language_reflects_material_conditions
```

**Another Example:**
```
BEFORE:
"Under optimal conditions — consistent salvage yields, no injuries, favorable
weather — a Forsaken laborer achieves equilibrium: neither accumulating nor
discharging debt. Any disruption tips the balance toward accumulation. The
system is designed to maintain a permanent labor force, not to process
individuals through to freedom."

AFTER:
DESC:economy:Ice-Debt=self-perpetuating_indenture;
  daily_overhead=2-4_Cog_Units; daily_credit=1-3_Cog_Units(optimal);
  net_balance=equilibrium_at_best; designed_for_stasis_not_liberation;
  Kings_Find_myth=control_mechanism(0_documented_liberations)
```

**Precedence:** 4 (low — descriptions are content, not structural elements)

**Composable With:** ENTITY, TEMPORAL, CANON, REF, NOTE

**Edge Cases:**
- Very long descriptions: Break into multiple DESC operators with different categories. `DESC:economy:...; DESC:culture:...; DESC:biology:...`
- Descriptions with quotes: Use single quotes within DESC text. `DESC:culture:Gutter-Sagas; dark_humor; punchline='The_Chain_dont_care_how_bright_you_burn'`
- Descriptions referencing other entities: Use inline REF. `DESC:history:Founded_Year_47_PG; REF:Scavenger_Barons; binary_choice=swear_or_die`
- Purely quantitative descriptions: Use ENTITY attributes for structured data; use DESC for narrative context around the data.

**Notes:**
- DESC is intentionally the loosest operator in the worldbuilding profile. Its text content is not formally parsed beyond the category prefix — the decoder treats it as compressed natural language to be expanded. This is by design: worldbuilding prose is too varied and nuanced to fully structure.
- The compression style guidance ("telegram mode") is a convention, not a syntactic requirement. The grammar allows any text after the category. But for the protocol to deliver on its compression promise, encoders should follow the convention.
- DESC categories are extensible. The listed categories cover common worldbuilding domains, but `custom` allows any domain. Future profile versions may add domain-specific categories.
- **Practical compression guidance:** When encoding DESC text, aim for 3-8 semicolon-separated clauses per DESC operator. Preserve all proper nouns, quantitative data, and causal relationships. Drop articles, copular verbs ("is," "are," "was"), and hedging language. Use underscores for compound concepts (`status_class_not_ethnic_group`), equals signs for definitions (`daily_overhead=2-4_Cog_Units`), and parenthetical qualifiers for context (`vs_7_standard`). See §9.3 for a fully worked example demonstrating these conventions across all DESC categories.

**FractalRecall Layer Mapping:** DESC produces output for the **Content** layer (the actual substance), with the category mapping to the **Section** layer (topical classification).

---

## 7. Adapted Operators (Worldbuilding Reinterpretation)

This section details how each reused procedural operator changes behavior in the worldbuilding context. Syntax remains unchanged from v0.0.2b; only the semantic interpretation and usage patterns differ.

### 7.1. META in Worldbuilding Context

**Unchanged syntax.** In worldbuilding, META encodes document-level metadata rather than procedure-level metadata:

```
Procedural:  META:version=1.0; META:author=SRE_Team; META:compatible_with=PostgreSQL_12+
Worldbuilding: META:type=faction; META:era=Age_of_Echoes; META:layer=L2_Diagnostic;
               META:complexity=Moderate; META:fragments=10
```

**Key difference:** Worldbuilding META keys map to D-10's common metadata fields (§4.6): `type`, `era`, `layer`, `complexity`, `fragments`, `tags`, `version`, `summary`, `last_validated`.

**FractalRecall Layer Mapping:** META produces output for the **Corpus** layer (corpus-level metadata) and contributes to **Domain** (entity type via `META:type=`).

### 7.2. REF in Worldbuilding Context

**Unchanged syntax.** Cross-references in worldbuilding point to other lore entries rather than runbooks:

```
Procedural:  REF:Runbook-Migration-v2:Rollback_Procedure
Worldbuilding: REF:Scavenger_Barons_Dossier; REF:CPS_Hazard_Documentation;
               REF:Ice-Debt_Cultural_Study
```

**Key difference:** REF targets are entity identifiers or document paths within the Chronicle repository, not external URLs or system documentation. The decoder/resolver must understand Chronicle's file system structure.

### 7.3. State in Worldbuilding Context

**Unchanged syntax.** States describe entity conditions rather than system conditions:

```
Procedural:  State:DB_Online; State:Service_Running
Worldbuilding: State:Faction_Active; State:Character_Deceased;
               State:Locale_Hazardous; State:System_Self-Perpetuating
```

**Key difference:** State identifiers use D-10's entity-specific status enums where they exist. For factions: `active`, `dissolved`, `dormant`, `fragmented`, `unknown` (D-10 §5.1). For characters: D-10 §5.2's status values. States that don't map to D-10 enums are free-form (same as procedural).

### 7.4. REQUIRES in Worldbuilding Context

**Unchanged syntax.** REQUIRES declares narrative preconditions — facts that must be true for an assertion to hold:

```
Procedural:  Action:Deploy REQUIRES State:DB_Online
Worldbuilding: ENTITY:system:Ice_Debt REQUIRES State:Baron_Controls_Dreadnought,
                 State:Geothermal_Core_Operational
```

**Key difference:** In procedures, REQUIRES gates execution ("don't do X until Y"). In worldbuilding, REQUIRES declares logical dependencies in the lore ("X is only true because Y is true"). This is useful for encoding worldbuilding axioms — foundational truths whose validity depends on other conditions.

### 7.5. IF/THEN/ELSE in Worldbuilding Context

**Unchanged syntax.** Conditional lore mechanics — what happens under different circumstances:

```
Procedural:  IF:Deploy_Success THEN:Action:Verify ELSE:Action:Rollback
Worldbuilding: IF:Baron_Death THEN:State:Forsaken_Temporarily_Free
               ELSE:State:Ice_Debt_Continues;
               IF:Kings_Find THEN:State:Debt_Discharged
               ELSE:NOTE:Zero_documented_liberations
```

**Key difference:** Conditions test narrative state, not runtime state. Useful for encoding worldbuilding rules and mechanics (what happens when a Baron dies? what happens if a Forsaken finds a King's Find?).

### 7.6. VERIFY in Worldbuilding Context

**Unchanged syntax.** Canon consistency assertions rather than post-action checks:

```
Procedural:  VERIFY:All_Pods_Running
Worldbuilding: VERIFY:Population_Within_Dreadnought_Capacity;
               VERIFY:Timeline_Consistent_With_Era_Designation;
               VERIFY:Relationship_Target_Exists
```

**Key difference:** VERIFY becomes a validation hook. During encoding, it flags assertions that Chronicle's validation system (D-12) should check. During decoding, it ensures that expanded content is consistent with the rest of the corpus.

### 7.7. NOTE in Worldbuilding Context

**Unchanged syntax.** Integration notes, editorial commentary, and observer annotations:

```
Procedural:  NOTE:Consider_checking_logs
Worldbuilding: NOTE:L2_diagnostic_voice_maintains_demographic_precision;
               NOTE:Cross-reference_Silent_Folk_Population_Dossier;
               NOTE:Peripheral_exclusion_hypothesis
```

**Key difference:** Worldbuilding NOTEs often carry meta-narrative information — the "voice" or "layer" of the content, editorial assessments of reliability, cross-reference suggestions. They're more substantive than procedural notes but remain non-essential to the entity's core encoding.

---

## 8. Composition Rules for Worldbuilding

Procedural haikus compose as sequential action chains (Rule 1: Sequential Composition in v0.0.2b). Worldbuilding haikus compose as **declarative blocks** — groups of related operators that collectively describe an aspect of an entity.

### 8.1. Entity Declaration Block

Every worldbuilding haiku begins with an Entity Declaration Block: ENTITY, followed by META, CANON, and TEMPORAL qualifiers.

```
ENTITY:<type>:<name> {<inline_attrs>};
META:<key>=<value>; ...
CANON:<authority>;
TEMPORAL:<time_spec>
```

**Example:**
```
ENTITY:faction:The_Forsaken {population=12000-18000, status=active};
META:layer=L2_Diagnostic; META:complexity=Moderate; META:fragments=10;
CANON:false:Scriptorium_Compilation;
TEMPORAL:Year_47_PG-Year_783_PG:period
```

### 8.2. Narrative Block

After the declaration, one or more DESC operators provide compressed summaries of the entity's various aspects:

```
DESC:<category>:<compressed_text>;
DESC:<category>:<compressed_text>;
...
```

**Example:**
```
DESC:identity:Status_class_not_ethnic_group; terminal_social_category;
DESC:economy:Ice-Debt=self-perpetuating_indenture; equilibrium_at_best;
DESC:culture:Gutter-Sagas; dark_humor; survival_wisdom='Fear_the_Calm';
DESC:language:Fimbul-Cant; survival-optimized_pidgin; vocabulary_gaps;
DESC:biology:CPS_resistance(5+yr=18-24hr_onset); psychological_flattening
```

### 8.3. Relational Block

RELATION operators encode the entity's connections to other entities:

```
RELATION:<source> <verb> <target> (<qualifier>);
RELATION:<source> <verb> <target> (<qualifier>);
...
```

**Example:**
```
RELATION:Forsaken exploits Scavenger_Barons (Ice-Debt_indenture);
RELATION:Forsaken located_in Niflheim;
RELATION:Forsaken trades_with Midgard_Combine (salvage_for_grain);
RELATION:Forsaken fears silence (CPS_onset_risk)
```

### 8.4. Rule Block

For entities that have mechanical rules or conditional behaviors (particularly axioms and systems), REQUIRES/IF/THEN/ELSE/VERIFY operators encode the logic:

```
REQUIRES <state_list>;
IF:<condition> THEN:<outcome> ELSE:<outcome>;
VERIFY:<consistency_check>
```

**Example:**
```
REQUIRES State:Baron_Controls_Dreadnought;
IF:Baron_Death THEN:State:Temporary_Freedom ELSE:State:Ice_Debt_Continues;
IF:Kings_Find THEN:State:Theoretical_Liberation ELSE:NOTE:Zero_documented_cases;
VERIFY:Population_Within_Dreadnought_Capacity
```

### 8.5. Block Ordering Convention

Worldbuilding haikus follow a standard block order:

```
1. Entity Declaration Block  (WHO/WHAT — identity, metadata, authority, time)
2. Narrative Block           (WHAT — descriptions of attributes and properties)
3. Relational Block          (HOW — connections to other entities)
4. Rule Block                (WHY — conditional mechanics, axioms, constraints)
5. Reference Block           (WHERE — cross-references to related documents)
```

This ordering is a convention, not a syntactic requirement. Parsers must handle operators in any order. But consistent ordering improves human readability and makes decoder implementation more predictable.

---

## 9. Worked Example: The Forsaken

This section demonstrates a full compression of the Forsaken faction entry from the Aethelgard corpus. The source material is a 646-line Markdown document with YAML frontmatter, containing an assembled entry (narrative synthesis), 10 numbered fragments (oral histories, specimen analyses, linguistic studies, economic analyses, visual surveys, and echo recordings), and integration notes.

### 9.1. Source Material

**File:** `aethelgard/lore/factions/forsaken.md`
**Length:** ~646 lines, ~4,200 words (estimated ~5,500 tokens)
**Structure:** YAML frontmatter + assembled narrative entry + 10 fragments with per-fragment metadata

**Frontmatter:**
```yaml
id: AAM-WB-FACTION-FORSAKEN
title: "The Forsaken — Assembled Entry (Ice-Thralls of Niflheim)"
version: 1.0
status: draft
layer: L2 (Diagnostic)
fragments: 10
category: Cultural Study (Faction Analysis)
era: Age of Echoes (Contemporary, 783 PG)
complexity: Moderate
```

**Content sections:** Origins (The Rusted Chain), Ice-Debt System (Economic Architecture), Physiological Adaptation (CPS Resistance), Fimbul-Cant (Language), Gutter-Sagas (Cultural Production), External Relations, The Cycle (Breaking and Reforming), Diagnostic Synthesis, plus 10 individual fragments.

### 9.2. Compression Strategy

The compression targets the **assembled entry** (the narrative synthesis), not the individual fragments. Fragments are referenced but not individually encoded — each fragment would be its own haiku in a full-corpus compression. This reflects how Chronicle would process the document: the assembled entry is the "entity" and fragments are source evidence.

**Approach:**
1. ENTITY block captures identity, metadata, and authority
2. DESC operators compress each major section (Origins, Economy, Biology, Language, Culture, Relations, Cycle, Synthesis)
3. RELATION operators capture inter-entity connections
4. TEMPORAL operators capture time positioning
5. Rule block encodes the Ice-Debt mechanics and Baron-death cycle
6. REF operators point to fragment sources and cross-references

### 9.3. Full Haiku Encoding

```
-- Entity Declaration Block --
ENTITY:faction:The_Forsaken {population=12000-18000, status=active,
  realm=Niflheim, classification=status_class, alt_name=Ice-Thralls};
META:id=AAM-WB-FACTION-FORSAKEN; META:layer=L2_Diagnostic;
META:complexity=Moderate; META:fragments=10;
META:category=Cultural_Study_Faction_Analysis;
CANON:false:Scriptorium_Compilation;
TEMPORAL:Age_of_Echoes:era; TEMPORAL:Year_47_PG-Year_783_PG:period;

-- Narrative Block --
DESC:identity:Status_class_not_ethnic_group; terminal_social_category;
  bound_by_circumstance_not_blood; no_territory/ideology/leadership;
  Niflheim_dominant_population(80-90%_non-Baron);
DESC:history:Founded_~Year_47_PG; first_Barons_offered_binary_choice
  (swear_or_die); heterogeneous_origins=exiled_Iron-Banes(15%) +
  displaced_Midgardian_farmers(35%) + bankrupt_Rust-Clan(25%) +
  failed_fortune-seekers(20%) + misc_refugees(5%);
DESC:economy:Ice-Debt=self-perpetuating_indenture;
  daily_overhead=2-4_Cog_Units; daily_credit=1-3_Cog_Units(optimal);
  net=equilibrium_at_best; Kings_Find_myth=control_mechanism
  (requires_15000-25000_CU; rate=1/500-1000_labor-years;
  documented_liberations=0); designed_for_stasis;
DESC:biology:CPS_resistance_via_long-term_exposure;
  5yr=18-24hr_baseline(vs_6-12_outsider); 10yr=22-28hr_baseline;
  Stage-1_onset_delayed_2x; cost=elevated_dissociation +
  reduced_emotional_range + survival-only_memory_formation;
  optimal_for_high-CPS_salvage_operations;
DESC:language:Fimbul-Cant=survival-optimized_pidgin;
  cold=23_terms(vs_7_standard); debt=31_terms(vs_12);
  labor=45_terms(vs_18); emotion=8_terms(vs_34);
  no_words_for:future/home/hope/family; only:next_shift/berth/Kings_Find/crew;
DESC:culture:Gutter-Sagas=short_brutal_darkly_humorous;
  heroes_survive_not_escape; One-Eyed_Helga=exemplar
  (eye_for_3_months_debt_credit); punchline='Chain_dont_care_how_bright_you_burn';
  Fear_the_Calm=counter-intuitive_survival_wisdom
  (storms_honest/silence_dangerous=CPS_onset);
DESC:politics:All_factions_viewed_as_warmth-haves;
  envy_not_hate(hate=luxury); Iron-Banes=liberation_to_freeze;
  God-Sleepers=next-life_warmth_irrelevant; Jotunn-Readers=honest_specimens;
  Dvergr=inventory_not_slaves; Combine=trade_then_close_gates;
DESC:synthesis:Humanitys_lower_bound_of_post-Glitch_adaptation;
  minimum_viable_social_organization; sustainable_indefinitely;
  adaptations=remarkable(CPS_resistance/linguistic_efficiency/cultural_survival);
  whether_survival_or_living_death='winter_keeps_the_ledger_either_way';

-- Relational Block --
RELATION:Forsaken exploits Scavenger_Barons (Ice-Debt_indenture);
RELATION:Forsaken located_in Niflheim;
RELATION:Forsaken originates_from multiple_failed_trajectories (5_source_populations);
RELATION:Forsaken trades_with Midgard_Combine (salvage_for_grain);
RELATION:Forsaken fears silence (CPS_onset);
RELATION:Forsaken created_by Scavenger_Barons (Year_47_PG_binary_choice);

-- Rule Block --
REQUIRES State:Baron_Controls_Dreadnought, State:Geothermal_Core_Operational;
IF:Baron_Death THEN:State:Temporary_Freedom(hours)
  ELSE:State:Ice_Debt_Continues;
IF:Baron_Death THEN:TEMPORAL:~6_hours:period(lethal_threshold)
  ELSE:State:Re-enslavement_To_Next_Baron;
IF:Kings_Find THEN:State:Theoretical_Liberation
  ELSE:NOTE:Zero_documented_cases;
VERIFY:Population_Within_Dreadnought_Capacity;
VERIFY:Daily_Overhead_Exceeds_Daily_Credit;

-- Reference Block --
REF:Scavenger_Barons_Dossier; REF:CPS_Hazard_Documentation;
REF:Ice-Debt_Cultural_Study; REF:Fimbul-Cant_Glossary;
REF:Dreadnought_Specifications; REF:Silent_Folk_Population_Dossier;
NOTE:L2_diagnostic_voice; NOTE:Echo-Mother_confirmation_aligns_with_acoustic_data;
NOTE:Cross-reference_Specimen_SPEC-SF-779-03_necropsy
```

### 9.4. Compression Analysis

| Metric | Source | Haiku | Ratio |
|--------|--------|-------|-------|
| **Lines** | 646 | 52 | 12.4:1 |
| **Words** (approx.) | 4,200 | ~450 | 9.3:1 |
| **Tokens** (estimated) | ~5,500 | ~600 | 9.2:1 |
| **Semantic coverage** | 100% | ~90% | — |

**What was preserved:**
- All entity identity information
- All quantitative data (population, economic figures, CPS statistics, linguistic counts)
- All inter-entity relationships
- The Ice-Debt mechanical model
- Cultural artifacts (Gutter-Sagas, Fear the Calm, faction assessments)
- Temporal positioning (founding, current era, Baron Ironjaw event)
- Canon status and source attribution

**What was lost (acceptable losses):**
- Individual fragment metadata (each fragment would be its own haiku)
- Exact prose phrasing and narrative voice (the "L2 diagnostic voice" quality)
- Extended quotations (Helga's saga, the Founding Chain oral history, emergency broadcast transcript)
- Redundancy across assembled entry and fragments (the source document repeats information)

**What was lost (notable):**
- The emotional register and literary quality of the oral histories
- The full CPS study methodology (sample sizes, controls)
- The Dreadnought hold demographic visual survey details

These losses are expected for a compression system targeting ~10:1 ratios. The haiku preserves all facts and relationships needed for retrieval and enrichment, while the original document remains available for full reading.

---

## 10. FractalRecall Integration Surface

### 10.1. Operator-to-Layer Mapping

Each worldbuilding operator maps to one or more of FractalRecall's 8 context layers (as defined in D-02 and used in D-23):

| Operator | Primary Layer | Secondary Layer | Notes |
|----------|--------------|----------------|-------|
| ENTITY (type) | **Domain** | — | Entity type → domain category |
| ENTITY (name) | **Entity** | — | Specific entity identity |
| ENTITY (attrs) | **Entity** | **Content** | Inline attributes enrich both |
| RELATION | **Relational** | — | Directed relationships |
| TEMPORAL | **Temporal** | — | Time positioning |
| CANON | **Authority** | — | Canonical status |
| DESC | **Content** | **Section** | DESC category → Section; DESC text → Content |
| META | **Corpus** | **Domain** | Corpus-level and type metadata |
| REF | **Relational** | — | Cross-entity references |
| State | **Authority** | **Entity** | Entity status → authority context |
| NOTE | — | — | Not mapped (advisory only) |

**Coverage analysis:** All 8 FractalRecall layers have at least one operator producing content for them. This means a single worldbuilding haiku contains enough structured information to populate all enrichment layers.

### 10.2. Haiku as Enrichment Prefix

The D-23 multi-layer enrichment template prepends 7 metadata layers before the content chunk, consuming ~80-150 tokens. A worldbuilding haiku encoding the same entity's metadata could serve as a **pre-compressed enrichment prefix** — delivering the same semantic signal in fewer tokens.

**Current approach (D-23 format):**
```
Corpus: Aethelgard Worldbuilding Corpus v5.0
Domain: This content is from a faction document in the organizations category.
Entity: This content describes The Forsaken.
Authority: This content is draft and not yet canonized.
Temporal: The events described span the Age of Echoes (Year 47-783 PG).
Relationships: The Forsaken are exploited by the Scavenger Barons, located in
  Niflheim, and trade with the Midgard Combine.
Section: This content is from the Economy section.

[chunk text]
```
**Estimated tokens:** ~100-120 for the prefix alone.

**Proposed haiku approach:**
```
E:faction:The_Forsaken; C:false; T:Year_47_PG-Year_783_PG:period;
R:Forsaken exploits Scavenger_Barons; R:Forsaken located_in Niflheim;
D:economy:[chunk-specific summary]

[chunk text]
```
**Estimated tokens:** ~40-60 for the prefix.

**Token savings:** ~50-60% reduction in enrichment prefix size. For models with 512-token context windows (nomic-embed-text-v2-moe), this frees ~40-60 tokens for actual content — a significant improvement in content-to-metadata ratio.

### 10.3. Compression as Layer Token Budget Solution

The R-01 research findings identified a critical constraint: `nomic-embed-text-v2-moe` has a 512-token context window, not 8,192. With D-23's natural-language enrichment prefix consuming ~100-150 tokens, only ~350-400 tokens remain for actual content. For dense worldbuilding documents, this is often insufficient.

Haiku Protocol compression addresses this directly:

| Approach | Prefix Tokens | Content Budget (512 model) | Content Budget (8192 model) |
|----------|--------------|---------------------------|---------------------------|
| No enrichment (D-21 baseline) | 0 | 512 | 8,192 |
| Natural language prefix (D-23) | 100-150 | 362-412 | 8,042-8,092 |
| Haiku-compressed prefix | 40-60 | 452-472 | 8,132-8,152 |
| **Savings vs. D-23** | **40-90 tokens** | **+40-90 tokens** | **+40-90 tokens** |

For the 512-token model, this is a ~10-25% increase in available content budget. Whether this matters depends on Track B's empirical results — if multi-layer enrichment shows significant retrieval improvement (D-23 GO decision), then maximizing the content-to-prefix ratio becomes important for production deployment.

---

## 11. Token Budget Analysis

### 11.1. Estimated Compression Ratios

Based on the Forsaken worked example and extrapolation across entity types:

| Entity Type | Typical Source Size (tokens) | Estimated Haiku Size (tokens) | Compression Ratio |
|-------------|---------------------------|-----------------------------|--------------------|
| Faction (large, multi-fragment) | 5,000-6,000 | 500-700 | ~8-10:1 |
| Character (detailed) | 2,000-3,000 | 250-400 | ~7-8:1 |
| Locale (with hazards) | 1,500-2,500 | 200-350 | ~7-8:1 |
| Event (point event) | 500-1,000 | 80-150 | ~6-7:1 |
| System (mechanical) | 1,000-2,000 | 150-250 | ~7-8:1 |
| Axiom (single rule) | 200-500 | 40-80 | ~5-6:1 |
| Term (glossary entry) | 100-300 | 30-60 | ~4-5:1 |

**Average estimated compression ratio: ~7-8:1** for worldbuilding content.

### 11.2. Comparison with Procedural Compression

Haiku Protocol's baseline metrics (from BASELINE_METRICS_REPORT.md) for procedural content:

| Complexity | Source Tokens | LLMLingua Ratio | Haiku Target Ratio |
|-----------|-------------|-----------------|-------------------|
| Simple | 101 | 52% (1.9:1) | 30-40% (2.5-3.3:1) |
| Medium | 443 | 48% (2.1:1) | 40-50% (2.0-2.5:1) |
| Complex | 1,589 | 46% (2.2:1) | 45-55% (1.8-2.2:1) |

Worldbuilding compression ratios (~7-8:1) are significantly higher than procedural (~2-3:1). This is because worldbuilding content has more redundancy (repeated entity names, verbose descriptions, duplicated information across fragments) and more structured data (dates, populations, economic figures) that compress efficiently into operator syntax.

### 11.3. Model Context Window Implications

| Model | Context Window | Enrichment Prefix (haiku) | Remaining for Content | Chunks per Document (avg faction) |
|-------|---------------|--------------------------|----------------------|----------------------------------|
| nomic-embed-text-v2-moe | 512 | ~50 | ~462 | ~11-13 |
| nomic-embed-text-v1.5 | 8,192 | ~50 | ~8,142 | 1 (entire doc) |
| BGE-M3 | 8,192 | ~50 | ~8,142 | 1 (entire doc) |

For the 512-token model, haiku-compressed prefixes keep the metadata overhead to ~10% of the context window (vs. ~20-30% for natural language prefixes). This is the primary practical benefit for FractalRecall integration.

---

## 12. Decision Tree: When to Use Which Operator

```
START: I want to encode a piece of worldbuilding content
  │
  ├─ Am I declaring a new entity or named concept?
  │  └─ YES → Use ENTITY: with type from D-10 taxonomy
  │
  ├─ Am I describing a relationship between entities?
  │  └─ YES → Use RELATION: with verb from D-10 §7.2 vocabulary
  │
  ├─ Am I positioning something in time?
  │  └─ YES → Use TEMPORAL: with appropriate scope
  │
  ├─ Am I declaring the canonical authority of this content?
  │  └─ YES → Use CANON: with authority level
  │
  ├─ Am I compressing descriptive prose about an entity?
  │  └─ YES → Use DESC: with appropriate category
  │
  ├─ Am I encoding document-level metadata?
  │  └─ YES → Use META: (same as procedural)
  │
  ├─ Am I cross-referencing another lore entry?
  │  └─ YES → Use REF: (same as procedural)
  │
  ├─ Am I describing the current state/condition of an entity?
  │  └─ YES → Use State: (broadened from procedural)
  │
  ├─ Am I encoding a rule or conditional mechanic?
  │  └─ YES → Use IF/THEN/ELSE + REQUIRES
  │
  ├─ Am I asserting something that should be validated?
  │  └─ YES → Use VERIFY: (canon consistency check)
  │
  ├─ Am I adding editorial/integration notes?
  │  └─ YES → Use NOTE: (same as procedural)
  │
  ├─ Am I flagging a potential canon inconsistency?
  │  └─ YES → Use WARN: (adapted from procedural)
  │
  └─ Default: DESC: (most general — compressed prose)
```

---

## 13. Open Questions and Decision Log

### Open Questions

**OQ-D16-1: Should `contested` and `speculative` be added to D-10's canon field?**
The Worldbuilding Profile proposes extending CANON's authority levels beyond D-10's four (`true`, `false`, `apocryphal`, `deprecated`) to include `contested` (multiple conflicting accounts) and `speculative` (unconfirmed theories). This is currently a Profile-level extension only. Should it be proposed as an amendment to D-10 §4.2 and D-11's canon workflow?
**Status:** Open. Decision depends on whether Track B prototyping surfaces use cases for in-corpus authority disagreements.

**OQ-D16-2: Should ENTITY support inheritance for parent/child documents?**
D-10 §4.7 defines parent/child entity relationships with inheritance semantics (children inherit parent frontmatter unless overridden). Should `ENTITY:faction:Forsaken:Ice_Debt_System` automatically inherit the parent's META, CANON, and TEMPORAL operators? Or should child haikus be fully self-contained?
**Status:** Open. Deferred to D-15 (Integration Design).

**OQ-D16-3: How should fragment-level compression work?**
The Forsaken entry contains 10 fragments, each with its own metadata, perspective, and evidence type. Should each fragment be a separate haiku? Or should fragments be encoded as sub-blocks within the parent entity's haiku?
**Status:** Open. Recommend separate haikus per fragment with REF links to parent, mirroring D-10's file-per-entity model.

**OQ-D16-4: DESC compression quality — how do we measure it?**
DESC operators contain compressed natural language. Unlike structured operators (ENTITY, RELATION, TEMPORAL), DESC's "quality" is subjective — how much meaning is preserved? A future research task should define metrics for DESC compression quality (semantic similarity between source and expansion, information retention rate, retrieval effectiveness).
**Status:** Open. Propose as R-11 research task if the Worldbuilding Profile advances to implementation.

**OQ-D16-5: Grammar profile switching — can a single document contain both profiles?**
Some documents might contain both procedural and narrative content (e.g., a Chronicle CLI guide that references worldbuilding examples). Should the grammar support inline profile switching? Or should mixed documents be split into profile-specific sections?
**Status:** Open. Low priority — most documents are clearly one profile or the other.

### Decision Log

**D16-001:** Worldbuilding Profile uses same OperatorSpec format as v0.0.2b.
**Rationale:** Consistency. Future implementations can process both profiles with the same parser infrastructure.

**D16-002:** ENTITY types aligned with D-10's 12 default entity types.
**Rationale:** Schema alignment principle (§5, Principle 6). The grammar encodes the same data model that Chronicle validates.

**D16-003:** RELATION vocabulary aligned with D-10 §7.2's recommended relationship types.
**Rationale:** Same as D16-002. Free-form types are allowed per D-10 §7.3.

**D16-004:** DESC uses category-prefixed compressed natural language rather than fully structured encoding.
**Rationale:** Worldbuilding prose is too varied and nuanced for full structure. DESC's loose format trades parsability for expressiveness — the right trade-off for narrative content.

**D16-005:** Block ordering convention (Entity → Narrative → Relational → Rule → Reference) is a convention, not a syntactic requirement.
**Rationale:** Composability principle (§5, Principle 4). Parsers must handle any order, but convention improves human readability.

**D16-006:** The Worldbuilding Profile excludes Action, EXEC, and LOOP from the procedural grammar.
**Rationale:** These operators encode exclusively procedural patterns (imperative commands, shell execution, iteration) with no meaningful worldbuilding equivalent. Including them would violate the Minimal Ambiguity principle.

---

## 14. Dependencies and Cross-References

| Document | Relationship to D-16 |
|----------|---------------------|
| v0.0.2b: Haiku Protocol Operator Design | **Upstream.** Defines the 12-operator procedural grammar that D-16 extends. D-16 mirrors its format and inherits 7 of its operators. |
| D-10: Lore File Schema Specification | **Upstream.** Provides the entity type taxonomy, common fields, relationship vocabulary, and FractalRecall layer mapping that D-16's operators are aligned with. |
| D-02: FractalRecall Conceptual Architecture | **Upstream.** Defines the 8 context layers that D-16's operators map to. |
| D-23: Notebook 3 — Multi-Layer Enrichment | **Upstream.** Defines the enrichment prefix format that haiku compression aims to optimize. |
| R-01: nomic-embed-text-v2-moe Research | **Upstream.** Identifies the 512-token constraint that motivates compressed enrichment prefixes. |
| Haiku-Protocol-Integration-Assessment.docx | **Upstream.** Proposed the grammar adaptation and recommended D-16 as a deliverable. |
| D-15: Integration Design Document | **Downstream.** Will use D-16's operator definitions to specify how Chronicle consumes Haiku Protocol output. |
| Haiku Protocol Phase 2 Encoder | **Downstream.** The worldbuilding encoder implementation will implement D-16's operator specifications. |
| D-11: Canon Workflow Specification | **Related.** D-16's CANON operator and VERIFY assertions interact with D-11's canon state machine. |
| D-12: Validation Rule Catalog | **Related.** D-16's VERIFY operators become validation hooks that D-12's rules can check. |

---

## 15. Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1.0-draft | 2026-02-15 | Ryan + Claude | Initial draft. 5 new worldbuilding operators (ENTITY, RELATION, TEMPORAL, CANON, DESC). 7 adapted procedural operators. Composition rules. Worked example (The Forsaken). FractalRecall integration surface. Token budget analysis. 5 open questions. 6 design decisions. |
| 0.1.1-draft | 2026-02-15 | Ryan + Claude | Post-reader-test fixes: added forward reference in §5 Principle 7 (Layer Awareness) to §10.1 for FractalRecall layer context; added practical DESC compression guidance in §6.5 notes with cross-reference to §9.3 worked example. |

---

*This document defines the Worldbuilding Grammar Profile for Haiku Protocol's CNL. For the procedural grammar, see v0.0.2b (Operator Design & Syntax Definition). For Chronicle's data model that this grammar encodes, see D-10 (Lore File Schema Specification). For FractalRecall's context layers that this grammar maps to, see D-02 (FractalRecall Conceptual Architecture).*
