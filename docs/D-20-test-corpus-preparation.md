---
title: "D-20: Test Corpus Preparation"
document_id: "D-20"
version: "1.0"
status: "Complete"
date: "2026-02-11"
author: "Ryan + Claude (Cowork)"
blocks: "D-21 (Model Selection & Embedding Baseline)"
depends_on: "D-10 (Lore File Schema Spec), R-01-02-03 (Research Findings)"
authority: "Chronicle-FractalRecall-Master-Strategy.md §7.2"
---

# D-20: Test Corpus Preparation

**Aethelgard Test Corpus Assessment, Field Mapping, and Ground-Truth Query Set**

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Corpus Inventory](#2-corpus-inventory)
3. [Minimum Requirements Verification](#3-minimum-requirements-verification)
4. [Frontmatter Audit Results](#4-frontmatter-audit-results)
5. [D-10 Schema Alignment Analysis](#5-d-10-schema-alignment-analysis)
6. [Field Mapping Strategy](#6-field-mapping-strategy)
7. [Coverage Gap Analysis](#7-coverage-gap-analysis)
8. [Ground-Truth Query Set](#8-ground-truth-query-set)
9. [Chunking Preview](#9-chunking-preview)
10. [Recommendations for D-21](#10-recommendations-for-d-21)
11. [Open Questions](#11-open-questions)
12. [Revision History](#12-revision-history)

---

## 1. Executive Summary

The Aethelgard test corpus already exists at `fractal-recall/notebooks/test-corpus/` with **67 Markdown files** containing YAML frontmatter. This significantly reduces D-20's originally-scoped work (Master Strategy §7.2 steps 1-2 — export from Notion and add frontmatter — are already complete).

### 1.1. Top-Line Findings

| Requirement | Status | Details |
|-------------|--------|---------|
| Minimum 50 documents | ✅ **PASS** | 67 documents (34% above floor) |
| Minimum 3 entity types | ✅ **PASS** | 38 unique entity types (far exceeds minimum) |
| Minimum 2 authority levels | ✅ **PASS** | 3 primary levels (L1, L2, L3) |
| Cross-references between entities | ✅ **PASS** | 100% of files have cross_references |
| Temporal metadata | ✅ **PASS** | 97% of files have temporal_markers |
| Ground-truth query set (30+) | ✅ **DELIVERED** | 36 queries across 5 query types (§8) |
| D-10 schema alignment | ⚠️ **GAP** | Field names differ; mapping strategy required (§5-6) |

### 1.2. Key Decision

The corpus frontmatter uses field names (`title`, `entity_type`, `canon_status`, `authority_layer`) that differ from D-10's formal schema (`name`, `type`, `canon`, no `authority_layer` equivalent). Rather than rewriting all 67 files, the **D-21 notebook should implement a field mapping layer** that translates between the corpus's actual field names and D-10's formal field names at index time. This approach:

- Preserves the corpus as-is (no risk of corrupting working data)
- Documents the mapping explicitly (reproducible)
- Tests the real-world scenario of "messy data in, structured data out" that Chronicle will face with user imports

---

## 2. Corpus Inventory

### 2.1. File Count and Location

- **Path:** `fractal-recall/notebooks/test-corpus/`
- **Total files:** 67 Markdown files
- **Total word count:** ~388,550 words
- **Word count range:** 700 – 18,500 words per file
- **Median word count:** ~4,200 words
- **Mean word count:** ~5,800 words

### 2.2. File Naming Patterns

The corpus uses four naming conventions reflecting its Notion export origin:

| Prefix | Pattern | Count | Content Type |
|--------|---------|-------|-------------|
| `000-` | `000-{category}_{name}.md` | 25 | Reference materials, codex entries, gazetteer entries, cultural studies |
| `db02-wb_` | `db02-wb_{name}.md` | 5 | Worldbuilding assembled entries (factions, creatures) |
| `db03-dc_` | `db03-dc_{name}.md` | 28 | Data capture documents (field observations, analyses, case studies) |
| `standalone_` | `standalone_{name}.md` | 8 | Systems, architecture, rune concordances |
| `codex_` | `codex_{name}.md` | 1 | Standalone codex entry (Chrome-Lurker) |

### 2.3. Source Hierarchy Distribution

| Source Hierarchy | Files | Percentage |
|-----------------|-------|-----------|
| DB05-DC (appears as db03-dc in filenames) | 28 | 41.8% |
| 000/Resources-v4 | 10 | 14.9% |
| Standalone | 8 | 11.9% |
| 000/Codex | 6 | 9.0% |
| DB02-WB | 5 | 7.5% |
| 000/Gazetteer | 4 | 6.0% |
| 000/Cultural-Studies | 3 | 4.5% |
| 000/Worldbuilding Data Capture | 2 | 3.0% |
| Codex (no prefix) | 1 | 1.5% |

---

## 3. Minimum Requirements Verification

The Master Strategy §7.2 step 3, sourced from the Conceptual Architecture §11.3, defines five corpus requirements. All five are met.

### 3.1. Document Count

**Requirement:** At least 50 documents with structured metadata.
**Result:** ✅ **67 documents**, all with complete YAML frontmatter (100% have title, entity_type, authority_layer, canon_status).

### 3.2. Entity Type Diversity

**Requirement:** At least 3 entity types (factions, characters, events, locations, etc.).
**Result:** ✅ **38 unique entity_type values** across the corpus.

The corpus significantly exceeds this minimum, though the entity types use free-form descriptive strings rather than D-10's formal taxonomy. Grouping by broad category:

| Broad Category | Corpus entity_type Examples | Approximate File Count |
|---------------|----------------------------|----------------------|
| Cultural/Anthropological | "cultural-practice", "Cultural & Anthropological Study" | ~19 |
| Creature/Biological | "creature", "Hybrid Organism, Environmental Hazard" | ~8 |
| Organizational/Faction | "faction", "Urban Anthropology, Black Market Economy" | ~7 |
| Technical/System | "AI System, Strategic Governance", "Infrastructure" | ~10 |
| Linguistic/Phenomenon | "Linguistic Hazard, Phenomenon", "field-observation" | ~8 |
| Narrative/Historical | "narrative", "incident-report" | ~8 |
| Reference/Meta | "Aggregated Glossary", "resources" | ~7 |

### 3.3. Authority Level Diversity

**Requirement:** At least 2 authority levels (canonical and draft/apocryphal).
**Result:** ✅ **3 primary authority layers** plus compound designations.

| Authority Layer | Files | Percentage |
|----------------|-------|-----------|
| L2-Diagnostic | 43 | 64.2% |
| L3-Technical | 12 | 17.9% |
| L1-Mythological | 1 | 1.5% |
| Compound (L1\|L2\|L3, etc.) | 3 | 4.5% |
| Narrative format variants | 6 | 9.0% |
| "World Bible" | 2 | 3.0% |

Additionally, the `canon_status` field provides a separate dimension:

| Canon Status | Files | Percentage |
|-------------|-------|-----------|
| Canonical | 38 | 56.7% |
| Draft (all variants) | 22 | 32.8% |
| Published | 2 | 3.0% |
| Done | 2 | 3.0% |
| SUPERSEDED | 1 | 1.5% |
| Not started | 1 | 1.5% |

### 3.4. Cross-References

**Requirement:** Cross-references between entities (relationship links in frontmatter).
**Result:** ✅ **100% of files** have non-empty `cross_references` arrays.

The cross-reference density is excellent — every file links to at least 2-3 other concepts, with some files (like the comprehensive glossary) linking to 6+ entries.

### 3.5. Temporal Metadata

**Requirement:** Temporal metadata (eras, dates).
**Result:** ✅ **97% of files** (65/67) have `temporal_markers` arrays.

The two files without temporal markers are the rune concordances (`standalone_dagaz-concordance.md` and `standalone_gebo-concordance.md`), which describe timeless symbolic/runic concepts. This is a content-appropriate omission.

---

## 4. Frontmatter Audit Results

A comprehensive audit of all 67 files was performed using a Python script (`corpus_audit.py`). The full audit report is available at `CORPUS_AUDIT_REPORT.md`. Key findings:

### 4.1. Data Quality Score: 92/100

- **Completeness:** 98/100 (required fields 100%, optional fields 97-100%)
- **Consistency:** 85/100 (version type inconsistencies, authority layer naming variants)
- **Standardization:** 88/100 (entity type diversity, mixed naming conventions)
- **Accuracy:** 98/100 (no corrupt or invalid YAML)

### 4.2. Issues Identified

| # | Issue | Severity | Files Affected | Impact on D-21 |
|---|-------|----------|---------------|----------------|
| 1 | **Version field type inconsistency** | Medium | 12 files (17.9%) — numeric instead of string | Low — version not used in embedding |
| 2 | **Authority layer naming variants** | Medium | 10 files (14.9%) — "Layer 2: The Echoes" vs. "L2-Diagnostic" | Medium — affects metadata filtering accuracy |
| 3 | **Entity type free-form values** | Medium | 51 files (76.1%) — 38 unique types vs. D-10's 12 | Medium — affects entity type filtering |
| 4 | **Canon status workflow values** | Low | 5 files (7.5%) — "Draft 1 - Done" etc. | Low — normalize to "Draft" in mapping |
| 5 | **Source hierarchy notation** | Low | 2 files (3.0%) — minor path inconsistencies | Negligible |

### 4.3. Recommendation

**Do NOT fix these issues in the corpus files.** Instead, handle them in D-21's data ingestion pipeline through normalization functions. This tests a realistic scenario — real user data will have similar inconsistencies, and the system needs to handle them gracefully.

---

## 5. D-10 Schema Alignment Analysis

### 5.1. The Mismatch

The corpus predates D-10's formal schema specification. As a result, the field names and value formats differ significantly:

| Concept | D-10 Field Name | Corpus Field Name | Match? |
|---------|----------------|-------------------|--------|
| Entity type | `type` | `entity_type` | ❌ Name differs |
| Display name | `name` | `title` | ❌ Name differs |
| Canon status | `canon` (boolean/string: true, false, "apocryphal", "deprecated") | `canon_status` (string: "Canonical", "Draft", "Published", etc.) | ❌ Name and value format differ |
| Era/temporal | `era` | `temporal_markers` (array) | ❌ Name and structure differ |
| Region/spatial | `region` | `locations_mentioned` (array) | ❌ Name and semantics differ |
| Tags | `tags` | (not present) | ❌ Missing from corpus |
| Relationships | `relationships` (structured RelationshipEntry objects) | `cross_references` (flat string array) | ❌ Structure differs significantly |
| Summary | `summary` | (not present) | ❌ Missing from corpus |
| Aliases | `aliases` | (not present) | ❌ Missing from corpus |

### 5.2. Fields Present in Corpus but Not in D-10

| Corpus Field | D-10 Equivalent | Notes |
|-------------|-----------------|-------|
| `notion_id` | None | Notion export artifact. Useful as a stable identifier but not part of D-10 schema. |
| `source_hierarchy` | None | Notion database path. Could map to D-10's hierarchical path concept but no direct equivalent. |
| `authority_layer` | None | D-10 doesn't define an authority layer field — it uses `canon` for status. Authority layers (L1-Mythological, L2-Diagnostic, L3-Technical) are an Aethelgard-specific concept. |
| `factions_mentioned` | None (could be inferred from `relationships`) | Useful metadata for filtering. No direct D-10 equivalent. |
| `word_count_approx` | None | Useful for chunking decisions. |
| `last_edited` | None (D-10 has `last_validated`) | Different semantics (edit date vs. validation date). |

### 5.3. Significance for D-21

D-10 defines Chronicle's **production schema** — what lore files will look like when managed by the Chronicle CLI. The test corpus represents **pre-Chronicle data** — lore exported from Notion before Chronicle exists.

This gap is actually **desirable for testing purposes.** FractalRecall must work with the data as it exists, not as it will exist after perfect D-10 migration. The D-21 notebook should:

1. Use the corpus fields as-is for embedding and retrieval testing
2. Implement a mapping layer that demonstrates how corpus fields would translate to D-10 fields
3. Document which fields are useful for embedding enrichment (regardless of their D-10 alignment)

---

## 6. Field Mapping Strategy

### 6.1. Mapping Table for D-21 Ingestion

The following mapping should be implemented as a Python dictionary in D-21's data ingestion pipeline:

```python
# Field mapping: corpus field name -> FractalRecall internal field name
FIELD_MAP = {
    # Direct mappings (rename only)
    "title": "name",
    "entity_type": "type",
    "canon_status": "canon",

    # Passthrough fields (corpus-specific, useful for metadata)
    "authority_layer": "authority_layer",      # No D-10 equivalent; keep as custom metadata
    "source_hierarchy": "source_hierarchy",    # No D-10 equivalent; keep as custom metadata
    "notion_id": "notion_id",                  # Stable identifier; keep as custom metadata
    "word_count_approx": "word_count_approx",  # Useful for chunking; keep as custom metadata
    "last_edited": "last_edited",              # Keep for corpus versioning

    # Semantic mappings (rename + may need normalization)
    "cross_references": "relationships",        # Flat array -> simplified relationship list
    "factions_mentioned": "factions_mentioned",  # Keep as-is; no D-10 equivalent
    "locations_mentioned": "locations_mentioned", # Partial overlap with D-10 "region"
    "temporal_markers": "temporal_markers",       # Partial overlap with D-10 "era"
}
```

### 6.2. Value Normalization Functions

```python
def normalize_canon_status(value: str) -> str:
    """Map corpus canon_status values to D-10 canon equivalents."""
    mapping = {
        "Canonical": "true",
        "Draft": "false",
        "Published": "true",
        "Done": "true",
        "SUPERSEDED": "deprecated",
        "Not started": "false",
    }
    # Handle compound workflow values like "Draft 1 - Done"
    if "Draft" in str(value):
        return "false"
    if "Outline" in str(value):
        return "false"
    return mapping.get(str(value), "false")


def normalize_authority_layer(value: str) -> str:
    """Standardize authority layer to L1/L2/L3 notation."""
    value = str(value)
    if "L1" in value or "Layer 1" in value or "Mythological" in value:
        return "L1-Mythological"
    elif "L3" in value or "Layer 3" in value or "Technical" in value:
        return "L3-Technical"
    elif "World Bible" in value:
        return "L1-Mythological"  # World Bible = foundational canon
    else:
        return "L2-Diagnostic"  # Default for "Layer 2", compound, or unrecognized


def normalize_version(value) -> str:
    """Ensure version is always a string in 'v#.#' format."""
    if isinstance(value, (int, float)):
        return f"v{value}"
    return str(value)
```

### 6.3. Entity Type Normalization

The 38 unique entity types in the corpus should be mapped to a smaller set for metadata filtering purposes. This is optional for D-21 (the full type string can be embedded as-is for semantic matching), but useful for Approach C's metadata filtering:

```python
def normalize_entity_type(value: str) -> str:
    """Map free-form entity types to broad categories for filtering."""
    value = str(value).lower()

    if any(k in value for k in ["creature", "organism", "fauna", "beast", "flora"]):
        return "entity"      # D-10: types of beings
    elif any(k in value for k in ["faction", "organization", "political", "guild"]):
        return "faction"
    elif any(k in value for k in ["cultural", "anthropolog", "linguistic", "calendar", "reckoning"]):
        return "document"    # D-10: in-world texts (closest match for cultural studies)
    elif any(k in value for k in ["incident", "mobilization", "establishment", "dispute"]):
        return "event"
    elif any(k in value for k in ["system", "ai", "infrastructure", "architecture", "protocol"]):
        return "system"
    elif any(k in value for k in ["field-observation", "observation", "diagnostic"]):
        return "document"
    elif any(k in value for k in ["glossary", "lexicon", "reference", "resources"]):
        return "term"        # D-10: glossary entries
    elif any(k in value for k in ["narrative", "ballad", "saga"]):
        return "document"
    elif "hazard" in value:
        return "system"
    else:
        return "document"    # Safe default for unrecognized types
```

---

## 7. Coverage Gap Analysis

### 7.1. Entity Type Coverage vs. D-10

D-10 defines 12 default entity types. The corpus covers some well and others not at all:

| D-10 Entity Type | Corpus Coverage | Gap? |
|-----------------|----------------|------|
| `faction` | ✅ Good — Iron-Banes, God-Sleepers, Scavenger Barons, Dvergr, Rangers Guild, Combine, etc. are extensively described | No |
| `character` | ❌ **No dedicated character files** | **Yes — significant** |
| `entity` (types of beings) | ✅ Good — Silent Folk, Chrome-Lurker, Svin-fylking, Hela-Caste Custodians, etc. | No |
| `locale` | ⚠️ Partial — locations appear in gazetteer entries and as context within other files, but few dedicated locale files | Minor gap |
| `event` | ✅ Good — sanctuary establishment, crusade mobilization, contract dispute, etc. | No |
| `timeline` | ⚠️ Partial — temporal markers exist throughout, but no dedicated timeline-overview file defining eras | Minor gap |
| `system` | ✅ Good — ODIN Protocol, Aether-Weave OS, Nine Tiers Architecture | No |
| `axiom` | ❌ **No dedicated axiom files** | **Yes — minor** |
| `item` | ❌ **No dedicated item files** | **Yes — minor** |
| `document` (in-world texts) | ✅ Excellent — many files are framed as in-world documents (field observations, reports, manuals) | No |
| `term` | ✅ Good — comprehensive glossary with hundreds of terms | No |
| `meta` | ⚠️ Partial — one meta/style guide file exists | Minor gap |

### 7.2. Significant Gaps

**Characters:** The corpus has zero dedicated character files. Characters like "Grimhild Three-Fingers" or "Solveig Deepdelver" appear as mentions within other documents but have no standalone entries. This means:
- **Impact on D-21:** Character-specific queries (e.g., "Who is Solveig Deepdelver?") will require the system to find relevant passages within other documents, testing multi-hop retrieval.
- **Impact on Approach C:** No `type: character` metadata filter will be available.
- **Recommendation:** This is actually a useful test case — real-world corpora often have entities mentioned but not independently documented. Do not add synthetic character files.

**Items and Axioms:** No standalone item or axiom files. Items (weapons, substances, artifacts) and axioms (foundational truths about the world) are embedded within other documents. Similar reasoning as characters — useful for testing retrieval from context rather than dedicated entries.

### 7.3. Content Distribution Gaps

| Dimension | Distribution | Gap? |
|-----------|-------------|------|
| **Word count** | 700 – 18,500 (good range) | No — tests both short and very long documents |
| **Factions** | Iron-Banes, God-Sleepers, Dvergr, Rangers Guild, Combine, Scavenger Barons, Forsaken, Silent Folk all well-represented | No |
| **Locations** | Midgard, Niflheim, Svartalfheim, Jötunheim, Asgard, Vanaheim, Helheim all covered | No |
| **Time periods** | Year 0 PG through 783 PG plus pre-Glitch | No |
| **Authority layers** | L1 underrepresented (1 file), L2 dominant (43 files), L3 reasonable (12 files) | Minor — L1 thin |

---

## 8. Ground-Truth Query Set

### 8.1. Query Set Design

The Master Strategy §7.2 step 4 requires at least 30 test queries with manually annotated ground-truth relevance judgments. Five query types are specified:

1. **Factual single-hop** — Answer found in one document
2. **Factual multi-hop** — Answer requires information from 2+ documents
3. **Authority-sensitive** — Answer depends on canonical status or authority layer
4. **Temporal-scoped** — Answer filtered by time period
5. **Exploratory** — Broad question requiring thematic synthesis

### 8.2. Relevance Scoring

Each query's expected results use a 3-level relevance scale:

| Score | Meaning |
|-------|---------|
| **3** (Highly Relevant) | Directly answers the query. Primary source of the answer. |
| **2** (Relevant) | Contains significant supporting information. Partial answer or important context. |
| **1** (Marginally Relevant) | Mentions the topic but doesn't substantively answer the query. |

### 8.3. Queries

---

#### Q-01 (Factual Single-Hop)
**Query:** "What is Echo-Cant?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `000-codex_echo-cant.md` | 3 | Primary definition and detailed analysis of Echo-Cant |
| `000-resources_comprehensive-glossary.md` | 2 | Contains glossary definition of Echo-Cant |
| `standalone_fimbul-cant.md` | 1 | Mentions Echo-Cant in context of Aethelgardian languages |

---

#### Q-02 (Factual Single-Hop)
**Query:** "How do the Scavenger Barons govern their Dreadnoughts?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `000-codex_scavenger-barons.md` | 3 | Detailed organizational structure, Baron's law, hierarchy |
| `db02-wb_scavenger-barons-assembled-entry.md` | 3 | Population figures, Ice-Debt system, thermodynamic despotism |
| `standalone_fimbul-cant.md` | 1 | Linguistic evidence of Baron authority structures |

---

#### Q-03 (Factual Single-Hop)
**Query:** "What happened to the Silent Folk during the Ginnungagap event?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db02-wb_silent-folk-assembled-entry.md` | 3 | Full account: 2,847 sealed in Mimir's Well bunker, 783-year isolation |
| `000-codex_echo-cant.md` | 2 | Describes Silent Folk's evolved acoustic language from isolation |
| `000-resources_comprehensive-glossary.md` | 1 | Brief glossary entry on Silent Folk |

---

#### Q-04 (Factual Single-Hop)
**Query:** "What is the ODIN Protocol?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `000-codex_odin-protocol.md` | 3 | Full specification of ODIN AI Matrix |
| `standalone_aether-weave-os.md` | 2 | ODIN.NET protocol context within Aether-Weave OS architecture |
| `standalone_nine-tiers-architecture.md` | 2 | ODIN's role in Nine Tiers governance |

---

#### Q-05 (Factual Single-Hop)
**Query:** "What are the corrosion rates in the Ginnungagap Coolant Chasm?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db03-dc_ginnungagap-coolant-chasm.md` | 3 | Exact corrosion rates: Grade-B 2mm/hour, Grade-C structural failure 4 hours |

---

#### Q-06 (Factual Single-Hop)
**Query:** "What is a Hela-Caste Custodian?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `000-codex_hela-caste-custodian.md` | 3 | Full specification: bio-mechanical immortal wardens |
| `000-resources_comprehensive-glossary.md` | 2 | Glossary definition |

---

#### Q-07 (Factual Single-Hop)
**Query:** "How does the Combine Reckoning calendar work?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `standalone_combine-reckoning.md` | 3 | Full calendar system: agricultural overlay on Dvergr months |
| `db03-dc_combine-month-names.md` | 3 | Month-by-month naming and agricultural associations |
| `000-cultural_skaldic-year-naming.md` | 2 | Related calendar/naming conventions |

---

#### Q-08 (Factual Multi-Hop)
**Query:** "How do Iron-Bane and God-Sleeper theological positions on Svin-fylking differ?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db03-dc_iron-bane-theological-analysis.md` | 3 | Iron-Bane position: "Flesh-Iron Abominations," mercy-killing doctrine |
| `db03-dc_god-sleeper-operational-doctrine.md` | 3 | God-Sleeper position: divine creatures, non-provocation protocol |
| `db02-wb_svin-fylking-assembled-entry.md` | 2 | Svin-fylking biology and behavior (object of theological dispute) |

---

#### Q-09 (Factual Multi-Hop)
**Query:** "What calendar systems exist in post-Glitch Aethelgard and how do they relate to each other?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `standalone_combine-reckoning.md` | 3 | Combine agricultural calendar overlaying Dvergr system |
| `db03-dc_dvergr-guild-chronicle.md` | 3 | Dvergr numerical notation mandate (Year 287 PG) |
| `000-cultural_rangers-trail-reckoning.md` | 3 | Rangers Guild geographic-temporal hybrid calendar |
| `db03-dc_contract-dispute-case-study.md` | 2 | Calendar confusion precedent driving standardization |
| `db03-dc_combine-month-names.md` | 2 | Month naming conventions |
| `db03-dc_jotun-reader-chronology.md` | 2 | Chronology reconstruction of early post-Glitch period |

---

#### Q-10 (Factual Multi-Hop)
**Query:** "What evidence exists about pre-Glitch Aesir governance technology?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `000-codex_odin-protocol.md` | 3 | ODIN AI Matrix specifications |
| `standalone_aether-weave-os.md` | 3 | Aether-Weave distributed OS architecture |
| `standalone_nine-tiers-architecture.md` | 3 | Yggdrasil functional hierarchy |
| `000-codex_hela-caste-custodian.md` | 2 | Custodian program as Aesir bio-engineering |
| `000-gazetteer_gleipnir-containment-pens.md` | 2 | Pre-Glitch Vanir bioweapons facility |

---

#### Q-11 (Factual Multi-Hop)
**Query:** "What is the relationship between the Dvergr and other factions in terms of trade and arbitration?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db03-dc_dvergr-guild-chronicle.md` | 3 | Dvergr calendar as universal arbitration standard |
| `db03-dc_contract-dispute-case-study.md` | 3 | Dvergr arbitration in action (Ironholt v. Frostmark) |
| `000-cultural_gutter-tangle.md` | 2 | Dvergr economic relationships |
| `db02-wb_scavenger-barons-assembled-entry.md` | 1 | Dvergr as external trade partners to Barons |

---

#### Q-12 (Factual Multi-Hop)
**Query:** "What creatures or biological threats exist in the post-Glitch world?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db02-wb_gorge-maws-population-dossier.md` | 3 | Gorge Maws creature dossier |
| `db02-wb_skrap-troll-assembled-entry.md` | 3 | Skrap-Troll biological profile |
| `db02-wb_svin-fylking-assembled-entry.md` | 3 | Svin-fylking biology |
| `000-codex_chrome-lurker.md` | 3 | Chrome-Lurker codex entry |
| `000-codex_lure-lichen.md` | 2 | Lure-Lichen biological hazard |
| `000-codex_mycelian-weaver.md` | 2 | Mycelian Weaver organism |
| `000-resources_wall-and-the-spear.md` | 2 | Threat classification (Fang/Hoof, Iron/Cold, Blight) |

---

#### Q-13 (Factual Multi-Hop)
**Query:** "How did early post-Glitch communities establish themselves during the Age of Silence?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db03-dc_sanctuary-establishment.md` | 3 | Sanctuary establishment protocol (Years 1-10 PG) |
| `db03-dc_jotun-reader-chronology.md` | 3 | Chronology of Age of Silence (Years 0-122 PG) |
| `standalone_daily-life-midgard.md` | 2 | Daily survival patterns that emerged |
| `db03-dc_inter-generational-knowledge-transfer.md` | 2 | Knowledge preservation during isolation |

---

#### Q-14 (Authority-Sensitive)
**Query:** "What is the canonical explanation for the Ginnungagap event?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `standalone_aether-weave-os.md` | 3 | Technical (L3) explanation of Aether-Weave failure cascade — **Canonical** |
| `standalone_nine-tiers-architecture.md` | 2 | Architectural vulnerability that enabled cascading failure — **Canonical** |
| `000-codex_odin-protocol.md` | 2 | ODIN's destruction during Ginnungagap — **Draft** (lower confidence) |
| `db03-dc_ballad-of-the-broken-gate.md` | 1 | Mythological (L1) narrative interpretation — **Canonical** but folklore, not technical truth |

**Authority Notes:** The "correct" answer depends on authority layer. L3-Technical sources give mechanistic explanations (Aether-Weave failure). L1-Mythological sources give narrative explanations (gods sleeping, broken gates). An authority-sensitive retrieval system should surface the technical canonical sources first but acknowledge the mythological layer.

---

#### Q-15 (Authority-Sensitive)
**Query:** "What is the official Iron-Bane doctrine on corrupted creatures?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db03-dc_iron-bane-theological-analysis.md` | 3 | **Canonical** Iron-Bane theological position document |
| `db03-dc_crusade-mobilization.md` | 2 | Operational implementation of doctrine — **Canonical** |
| `db03-dc_crusader-field-training.md` | 2 | Training doctrine derived from theological position |
| `db03-dc_god-sleeper-operational-doctrine.md` | 1 | Opposing viewpoint (useful for contradiction detection, not for answering "Iron-Bane doctrine" directly) |

---

#### Q-16 (Authority-Sensitive)
**Query:** "What do we know about the pre-Glitch Vanir faction?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `000-gazetteer_gleipnir-containment-pens.md` | 3 | Vanir bio-weapons facility, pre-Glitch Vanir activities |
| `000-codex_odin-protocol.md` | 2 | Vanir's role in Aesir governance structure |
| `000-resources_comprehensive-glossary.md` | 1 | Glossary entry on Vanir |

**Authority Notes:** Pre-Glitch information is mostly L3-Technical (reconstruction) with L1-Mythological overlay. Search should prefer L3 sources for factual queries.

---

#### Q-17 (Authority-Sensitive)
**Query:** "Are Svin-fylking divine or corrupted?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db03-dc_god-sleeper-operational-doctrine.md` | 3 | Divine interpretation — God-Sleeper theological position |
| `db03-dc_iron-bane-theological-analysis.md` | 3 | Corruption interpretation — Iron-Bane theological position |
| `db02-wb_svin-fylking-assembled-entry.md` | 3 | Biological facts — L2-Diagnostic observational data |

**Authority Notes:** This is an intentional contradiction in the worldbuilding. The "correct" answer depends on perspective. An ideal retrieval system surfaces all three viewpoints and labels their authority layers.

---

#### Q-18 (Temporal-Scoped)
**Query:** "What happened in the first 10 years after the Glitch?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db03-dc_sanctuary-establishment.md` | 3 | Years 1-10 PG sanctuary establishment protocol |
| `db03-dc_jotun-reader-chronology.md` | 3 | Age of Silence chronology (Years 0-122 PG, detail on earliest years) |
| `db02-wb_silent-folk-assembled-entry.md` | 2 | Silent Folk sealed in Mimir's Well at Glitch onset |

---

#### Q-19 (Temporal-Scoped)
**Query:** "What significant events occurred around Year 287 PG?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db03-dc_dvergr-guild-chronicle.md` | 3 | Year 287 PG — mandatory calendar notation adopted |
| `db03-dc_contract-dispute-case-study.md` | 3 | Year 285 PG — dispute that catalyzed 287 PG reform |

---

#### Q-20 (Temporal-Scoped)
**Query:** "What is happening in the current year (783 PG)?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `standalone_daily-life-midgard.md` | 3 | Current-era daily life analysis |
| `000-codex_echo-cant.md` | 2 | Contemporary field observation dated 783 PG |
| `standalone_fimbul-cant.md` | 2 | Current-era linguistic analysis (783 PG stabilized creole) |
| `db03-dc_ballad-of-the-broken-gate.md` | 1 | Performance dated 780 PG (near-contemporary) |

---

#### Q-21 (Temporal-Scoped)
**Query:** "How did the Scavenger Baron system emerge over time?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `000-codex_scavenger-barons.md` | 3 | Genesis period 50-120 PG, organizational evolution |
| `db02-wb_scavenger-barons-assembled-entry.md` | 3 | Current-era Baron system (~783 PG) |
| `standalone_fimbul-cant.md` | 2 | Linguistic evolution of Fimbul-Cant (250-650 PG) reflecting Baron system |

---

#### Q-22 (Temporal-Scoped)
**Query:** "What was the pre-Glitch world like?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `standalone_aether-weave-os.md` | 3 | Pre-Glitch computational architecture |
| `standalone_nine-tiers-architecture.md` | 3 | Pre-Glitch societal structure |
| `000-codex_odin-protocol.md` | 3 | Pre-Glitch AI governance |
| `000-gazetteer_gleipnir-containment-pens.md` | 2 | Pre-Glitch bioweapons research |
| `000-codex_hela-caste-custodian.md` | 2 | Pre-Glitch bio-engineering program |

---

#### Q-23 (Exploratory)
**Query:** "What are the political tensions in post-Glitch Aethelgard?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db03-dc_iron-bane-theological-analysis.md` | 3 | Iron-Bane vs. God-Sleeper doctrinal conflict |
| `db03-dc_god-sleeper-operational-doctrine.md` | 3 | God-Sleeper vs. Iron-Bane and Rust-Clan tensions |
| `db03-dc_jarl-authority-exercise.md` | 3 | Jarl governance and authority disputes |
| `db02-wb_scavenger-barons-assembled-entry.md` | 2 | Baron tyranny and inter-Baron competition |
| `standalone_daily-life-midgard.md` | 2 | Inter-faction relations in daily life |

---

#### Q-24 (Exploratory)
**Query:** "How do different factions view the same events differently?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db03-dc_iron-bane-theological-analysis.md` | 3 | Iron-Bane perspective on Svin-fylking |
| `db03-dc_god-sleeper-operational-doctrine.md` | 3 | God-Sleeper perspective on same creatures |
| `db03-dc_ballad-of-the-broken-gate.md` | 2 | L1 mythological perspective on history |
| `standalone_aether-weave-os.md` | 2 | L3 technical perspective on same history |

---

#### Q-25 (Exploratory)
**Query:** "What survival strategies did post-Glitch populations develop?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `standalone_daily-life-midgard.md` | 3 | Comprehensive survival culture analysis |
| `db03-dc_sanctuary-establishment.md` | 3 | Early Hold survival infrastructure |
| `000-resources_wall-and-the-spear.md` | 3 | Defensive doctrine as survival strategy |
| `000-cultural_rangers-trail-reckoning.md` | 2 | Rangers' logistic coordination for trade/supply survival |
| `db03-dc_inter-generational-knowledge-transfer.md` | 2 | Knowledge preservation as survival strategy |

---

#### Q-26 (Exploratory)
**Query:** "What linguistic diversity exists across Aethelgardian factions?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `000-codex_echo-cant.md` | 3 | Silent Folk's acoustic language system |
| `standalone_fimbul-cant.md` | 3 | Forsaken pidgin/creole language |
| `000-resources_comprehensive-glossary.md` | 3 | Comprehensive glossary covering all faction-specific cants |
| `000-cultural_rangers-trail-reckoning.md` | 1 | Trail Reckoning as specialized notation system |

---

#### Q-27 (Factual Single-Hop)
**Query:** "What are Lure-Lichen?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `000-codex_lure-lichen.md` | 3 | Primary codex entry for Lure-Lichen |
| `000-resources_comprehensive-glossary.md` | 1 | Glossary reference |

---

#### Q-28 (Factual Single-Hop)
**Query:** "How does the Huskarl Wall defense doctrine work?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `000-resources_wall-and-the-spear.md` | 3 | Full field manual on Hold defense |

---

#### Q-29 (Factual Multi-Hop)
**Query:** "What role do the Jötun-Readers play across different aspects of post-Glitch society?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db03-dc_jotun-reader-chronology.md` | 3 | Jötun-Reader historical scholarship |
| `db03-dc_jarn-madr-behavioral-study.md` | 3 | Jötun-Reader field observation work |
| `db03-dc_ginnungagap-coolant-chasm.md` | 2 | Jötun-Reader field chemistry |
| `db03-dc_echo-caller-field-observation.md` | 2 | Jötun-Reader xenobiology fieldwork |
| `db02-wb_silent-folk-assembled-entry.md` | 2 | Jötun-Reader diplomatic/scholarly contact with Silent Folk |

---

#### Q-30 (Factual Single-Hop)
**Query:** "What was Project Gungnir?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `000-gazetteer_project-gungnir.md` | 3 | Primary entry for Project Gungnir |
| `000-resources_comprehensive-glossary.md` | 1 | Glossary reference |

---

#### Q-31 (Authority-Sensitive)
**Query:** "What is the Ballad of the Broken Gate and how reliable is it as historical source?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db03-dc_ballad-of-the-broken-gate.md` | 3 | Full transcription — **L1-Mythological**, Canonical but oral tradition (Evidence Tier B) |

**Authority Notes:** The document itself classifies its reliability as "Provisional — oral tradition; multiple variant versions exist." An authority-sensitive system should surface this document but flag that it's L1-Mythological with provisional evidence.

---

#### Q-32 (Exploratory)
**Query:** "How does religion function in post-Glitch Aethelgard?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db03-dc_iron-bane-theological-analysis.md` | 3 | Iron-Bane religious doctrine |
| `db03-dc_god-sleeper-operational-doctrine.md` | 3 | God-Sleeper religious theology |
| `db03-dc_iron-banes-liturgical-calendar.md` | 2 | Iron-Bane religious calendar |
| `db03-dc_crusade-mobilization.md` | 2 | Religion as military mobilization framework |
| `standalone_daily-life-midgard.md` | 2 | Religious practices in daily life |

---

#### Q-33 (Temporal-Scoped)
**Query:** "How did the Iron-Bane Crusade evolve over the centuries?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db03-dc_iron-bane-theological-analysis.md` | 3 | Theological foundation and doctrinal development |
| `db03-dc_crusade-mobilization.md` | 3 | Current-era mobilization procedures (Year 781 PG) |
| `db03-dc_crusader-field-training.md` | 2 | Training practices reflecting doctrinal evolution |
| `db03-dc_iron-banes-liturgical-calendar.md` | 2 | Liturgical calendar as institutional structure |
| `000-wbdc_iron-bane-reconnaissance.md` | 1 | Iron-Bane reconnaissance protocols |

---

#### Q-34 (Factual Single-Hop)
**Query:** "What is the Loki Protocol?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `000-gazetteer_loki-protocol-suppressed-warning.md` | 3 | Suppressed warning about Loki Protocol |
| `db03-dc_loki-protocol-warning.md` | 3 | Protocol warning document |
| `db03-dc_loki-archive-security-audit.md` | 2 | Security implications of Loki Archives |

---

#### Q-35 (Factual Multi-Hop)
**Query:** "What hazardous environments exist in post-Glitch Aethelgard?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db03-dc_ginnungagap-coolant-chasm.md` | 3 | Chemical hazard: toxic coolant analysis |
| `000-gazetteer_gleipnir-containment-pens.md` | 3 | Biological hazard: containment failure |
| `000-gazetteer_depth-sickness.md` | 3 | Environmental hazard: subterranean condition |
| `000-codex_echo-cant.md` | 2 | Acoustic hazard: Silent Folk detection protocols |
| `db03-dc_jotunheim-swarm-density.md` | 2 | Creature density hazard in Jötunheim |

---

#### Q-36 (Exploratory)
**Query:** "How do information and knowledge flow between factions in Aethelgard?"
**Expected Top Results:**
| File | Score | Rationale |
|------|-------|-----------|
| `db03-dc_gutter-skald-info-exchange.md` | 3 | Gutter-Skald information exchange network |
| `db03-dc_inter-generational-knowledge-transfer.md` | 3 | Knowledge transfer mechanisms |
| `000-resources_scriptorium-record-manual.md` | 2 | Scriptorium archival practices |
| `db03-dc_archive-cataloging-standards.md` | 2 | Formal cataloging and archive standards |
| `db03-dc_quiet-nod-protocol.md` | 2 | Covert information exchange protocol |

---

### 8.4. Query Distribution Summary

| Query Type | Count | Percentage |
|-----------|-------|-----------|
| Factual Single-Hop | 11 | 30.6% |
| Factual Multi-Hop | 8 | 22.2% |
| Authority-Sensitive | 5 | 13.9% |
| Temporal-Scoped | 6 | 16.7% |
| Exploratory | 6 | 16.7% |
| **Total** | **36** | **100%** |

---

## 9. Chunking Preview

Based on R-02's recommendations (see `R-01-02-03-research-findings.md` §3) and the corpus statistics from the audit:

### 9.1. Estimated Chunk Counts

| Model | Target Chunk | Estimated Total Chunks | Notes |
|-------|-------------|----------------------|-------|
| v2-moe (512 tokens) | 300-400 tokens | ~1,200-1,500 | Many documents will produce 5-15 chunks each |
| v1.5 / BGE-M3 (8,192 tokens) | 500-700 tokens | ~700-900 | Fewer, larger chunks |

### 9.2. Special Cases to Handle

| Case | Files | Handling |
|------|-------|---------|
| **Glossary** | `000-resources_comprehensive-glossary.md` (8,500 words) | Treat entries as atomic chunks; group adjacent entries to minimum size |
| **Very long files** (>15,000 words) | 5 files | Will produce 20-40+ chunks each at 512-token model |
| **Very short files** (<1,000 words) | 2 files | May produce only 1-2 chunks; consider merging with metadata |
| **Narrative/poetic** | `db03-dc_ballad-of-the-broken-gate.md` | Stanza-boundary splitting per R-02 §3.6.2 |
| **Tables** | Several files with specification tables | Atomic table chunking per R-02 §3.6.4 |

---

## 10. Recommendations for D-21

### 10.1. Data Ingestion Pipeline

D-21's data ingestion should follow this sequence:

1. **Scan** `test-corpus/` directory for `.md` files
2. **Parse** YAML frontmatter with PyYAML
3. **Apply field mapping** (§6.1) to normalize field names
4. **Apply value normalization** (§6.2) for canon_status, authority_layer, version
5. **Strip frontmatter** from body text (frontmatter becomes metadata, not chunk content)
6. **Chunk** body text using Hybrid Semantic + Fixed-Window strategy (R-02)
7. **Build enrichment prefix** from normalized metadata per chunk
8. **Index** chunks into ChromaDB with scalar metadata for filtering

### 10.2. Multi-Model Comparison Design

Per R-01's recommendation (Option D), D-21 should compare at minimum:

| Model | Chunk Size | Enrichment Budget | Notes |
|-------|-----------|-------------------|-------|
| `nomic-embed-text-v2-moe` | 300-400 tokens | ~100 tokens | Test compressed enrichment |
| `nomic-embed-text-v1.5` | 500-700 tokens | ~500-2,000 tokens | Test full enrichment (if available in Ollama) |
| `BGE-M3` | 500-700 tokens | ~500-2,000 tokens | Test hybrid dense+sparse |

### 10.3. Evaluation Metrics

For each model × chunking configuration, evaluate against the 36 ground-truth queries using:

- **Recall@5:** Of the relevant documents, how many appear in the top 5 results?
- **Recall@10:** Of the relevant documents, how many appear in the top 10?
- **MRR (Mean Reciprocal Rank):** Average of 1/rank of the first relevant result
- **nDCG@10 (Normalized Discounted Cumulative Gain):** Measures ranking quality using the 3-level relevance scores

---

## 11. Open Questions

| ID | Question | Impact | Proposed Resolution |
|----|----------|--------|-------------------|
| OQ-D20-1 | Should the corpus files be updated to use D-10 field names, or should the mapping layer be permanent? | Low (D-21 design) | Keep mapping layer for prototyping; defer file migration to Phase 2 |
| OQ-D20-2 | Is `nomic-embed-text-v1.5` available through Ollama for local inference in Colab? | Medium (D-21 blocking) | Check Ollama model library before D-21 notebook design |
| OQ-D20-3 | Should the 5 files with compound canon_status values ("Draft 1 - Done") be manually cleaned up? | Low | No — handle in normalization code. Tests realistic data quality. |
| OQ-D20-4 | The glossary file has 8,500 words of individual terms. Should it be indexed differently from narrative files? | Medium (D-21 chunking) | Yes — implement glossary-specific chunking per R-02 §3.6.1 |
| OQ-D20-5 | Should the ground-truth query set be stored as a separate JSON/YAML file for machine-readable evaluation? | Low (D-21 convenience) | Yes — create `test-corpus/ground-truth-queries.yaml` at D-21 start |

---

## 12. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-11 | Ryan + Claude (Cowork) | Initial corpus assessment, field mapping strategy, gap analysis, 36-query ground-truth set. |
