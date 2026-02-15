# Chronicle + FractalRecall: Master Execution Strategy

**Version:** 0.1.0
**Status:** Active — Governing Document
**Author:** Ryan (with strategic planning from Claude)
**Created:** 2026-02-10
**Last Updated:** 2026-02-10
**Supersedes:** Development Phases section (§8) of `Chronicle-FractalRecall-Design-Proposal.md`
**Companion Documents:**
- `Chronicle-FractalRecall-Design-Proposal.md` (design intent and architecture decisions)
- `fractalrecall-conceptual-architectural-design.md` (FractalRecall technical specification)
- `Chronicle-FractalRecall-Session-Bootstrap.md` (session onboarding context)

---

## Table of Contents

- [1. Purpose of This Document](#1-purpose-of-this-document)
- [2. Strategic Overview: Parallel Tracks](#2-strategic-overview-parallel-tracks)
  - [2.1. Why Parallel, Not Sequential](#21-why-parallel-not-sequential)
  - [2.2. The Two Tracks](#22-the-two-tracks)
  - [2.3. Synchronization Points](#23-synchronization-points)
- [3. Technology Stack Updates](#3-technology-stack-updates)
  - [3.1. Changes from Design Proposal](#31-changes-from-design-proposal)
  - [3.2. Python / Google Colab Stack (Prototyping)](#32-python--google-colab-stack-prototyping)
  - [3.3. C# / .NET Stack (Production)](#33-c--net-stack-production)
  - [3.4. Embedding Models](#34-embedding-models)
- [4. Legacy Content Disposition](#4-legacy-content-disposition)
  - [4.1. What Is Legacy](#41-what-is-legacy)
  - [4.2. Archive Strategy](#42-archive-strategy)
  - [4.3. Concepts That Survived the Pivot](#43-concepts-that-survived-the-pivot)
- [5. Document Manifest](#5-document-manifest)
  - [5.1. Completed Documents](#51-completed-documents)
  - [5.2. Track A Documents (Chronicle — Phase 1)](#52-track-a-documents-chronicle--phase-1)
  - [5.3. Track B Documents (FractalRecall — Phase 0/1)](#53-track-b-documents-fractalrecall--phase-01)
  - [5.4. Shared / Cross-Cutting Documents](#54-shared--cross-cutting-documents)
  - [5.5. Phase 2+ Documents (During Implementation)](#55-phase-2-documents-during-implementation)
- [6. Track A: Chronicle Documentation Sprint](#6-track-a-chronicle-documentation-sprint)
  - [6.1. Sprint Objective](#61-sprint-objective)
  - [6.2. Document Sequencing and Dependencies](#62-document-sequencing-and-dependencies)
  - [6.3. Document Specifications](#63-document-specifications)
- [7. Track B: FractalRecall Colab Prototyping](#7-track-b-fractalrecall-colab-prototyping)
  - [7.1. Sprint Objective](#71-sprint-objective)
  - [7.2. Test Corpus Preparation](#72-test-corpus-preparation)
  - [7.3. Notebook Sequencing and Dependencies](#73-notebook-sequencing-and-dependencies)
  - [7.4. Notebook Specifications](#74-notebook-specifications)
  - [7.5. Exit Criteria](#75-exit-criteria)
- [8. Research Due Diligence](#8-research-due-diligence)
  - [8.1. Research That Must Happen Before Prototyping](#81-research-that-must-happen-before-prototyping)
  - [8.2. Research That Can Happen During Prototyping](#82-research-that-can-happen-during-prototyping)
  - [8.3. Research That Must Happen Before C# Implementation](#83-research-that-must-happen-before-c-implementation)
- [9. Phase 2+ Implementation Planning](#9-phase-2-implementation-planning)
  - [9.1. What Phase 2 Looks Like (Preview)](#91-what-phase-2-looks-like-preview)
  - [9.2. Integration Strategy (Phase 3 Preview)](#92-integration-strategy-phase-3-preview)
- [10. Risk Management](#10-risk-management)
  - [10.1. Critical Path Risks](#101-critical-path-risks)
  - [10.2. Mitigation Strategies](#102-mitigation-strategies)
- [11. Open Questions Carried Forward](#11-open-questions-carried-forward)
- [12. Decision Log](#12-decision-log)
- [13. Document Revision History](#13-document-revision-history)

---

## 1. Purpose of This Document

The Design Proposal captures *what we're building and why*. The Conceptual Architecture captures *how FractalRecall works technically*. This document captures *how we're actually going to execute* — the sequencing, the dependencies, the parallel workstreams, the research gaps, and the concrete next steps.

This is the **operational playbook**. When a new session starts, it should read the Session Bootstrap for orientation, then this document for "what do we do next." The Design Proposal and Conceptual Architecture are referenced as needed for deeper context on specific design decisions.

---

## 2. Strategic Overview: Parallel Tracks

### 2.1. Why Parallel, Not Sequential

The Design Proposal (§8) laid out five phases sequentially: Phase 0 (Colab prototyping) → Phase 1 (documentation) → Phase 2 (implementation) → Phase 3 (integration) → Phase 4 (LLM features). In practice, Phase 0 and Phase 1 have **no blocking dependencies on each other** for large portions of the work:

- **Chronicle's Phase 1 documents** (Lore File Schema Spec, Canon Workflow Spec, Validation Rule Catalog, CLI Command Reference) describe Chronicle's domain logic. They don't depend on FractalRecall's Colab results at all — Chronicle's deterministic validation layer, schema system, and canon workflow exist independent of any embedding strategy.

- **FractalRecall's Phase 0 notebooks** validate the core embedding enrichment hypothesis empirically. They need the existing Conceptual Architecture doc (which is complete) and a test corpus. They don't need Chronicle's specs to be written first.

The only documents that genuinely block on Colab results are the FractalRecall API Design Spec (which refines the conceptual API sketch based on what the prototyping reveals) and the Prototyping Findings Document (which is literally a summary of Colab results). Everything else can proceed in parallel.

### 2.2. The Two Tracks

**Track A — Chronicle Documentation Sprint:** Write all six Phase 1 specification documents for Chronicle. These are purely documentation work — no code, no prototyping, no LLM integration. The output is a complete specification suite that Phase 2 implementation can be built against. This track has no external dependencies and can proceed at whatever pace is comfortable.

**Track B — FractalRecall Colab Prototyping:** Prepare the Aethelgard test corpus, build the six prototyping notebooks, and generate the empirical evidence that validates (or challenges) the multi-layer embedding enrichment hypothesis. This track requires Python work in Google Colab and produces the findings that inform FractalRecall's production API design.

### 2.3. Synchronization Points

The two tracks synchronize at three points:

1. **After Colab Notebook 3 (Multi-Layer Enrichment):** This is the "go/no-go" decision point. If multi-layer enrichment doesn't meaningfully outperform single-layer enrichment, FractalRecall's scope changes significantly. Chronicle's documentation is unaffected (it doesn't depend on FractalRecall's internals), but the Integration Design Document should wait until after this point.

2. **After Track A and Track B both complete:** The Integration Design Document (how Chronicle consumes FractalRecall's API) can only be written when both Chronicle's domain model is fully specified (Track A output) and FractalRecall's API is empirically validated (Track B output).

3. **Phase 2 kickoff:** Both tracks must be complete before C# implementation begins on either project. We need the full spec suite *and* the prototyping results to write production code confidently.

---

## 3. Technology Stack Updates

### 3.1. Changes from Design Proposal

Research conducted on 2026-02-10 revealed several technology updates since the Design Proposal was drafted. The following changes are incorporated into this strategy:

| Area | Design Proposal (2026-02-09) | Updated Recommendation (2026-02-10) | Rationale |
|------|------------------------------|--------------------------------------|-----------|
| .NET Version | .NET 8+ (latest LTS) | **.NET 10** (LTS, released Nov 2025) | .NET 10 is now the current LTS with support through Nov 2028. .NET 8 enters its final support year in 2026. |
| Embedding Model | `nomic-embed-text` (v1.x) | **`nomic-embed-text-v2-moe`** | v2 uses Mixture-of-Experts architecture (475M params, 305M active), multilingual support (~100 languages), Matryoshka dimension support. Significant upgrade. |
| Ollama .NET Client | Unspecified | **OllamaSharp** (v5.4.16, NuGet) | Recommended client; powers Semantic Kernel and .NET Aspire Ollama integration. `Microsoft.Extensions.AI.Ollama` is deprecated. |
| Embedding Abstraction | Custom `IEmbeddingProvider` | **Consider `IEmbeddingGenerator<string, Embedding<float>>`** from `Microsoft.Extensions.AI.Abstractions` | This is the ecosystem-standard interface for .NET AI. Semantic Kernel and all major connectors use it. FractalRecall's `IEmbeddingProvider` should either implement this or wrap it. |
| Vector Store Abstraction | Custom `IFractalIndex` | **Consider `Microsoft.Extensions.VectorData.Abstractions`** | GA library providing standard CRUD and vector search abstractions. Pre-built connectors exist for Qdrant, SQLite-vec, Postgres, in-memory. FractalRecall can build on top of this. |
| sentence-transformers | Unspecified version | **v5.2.2** (latest, Jan 2026) | New features: sparse embedding models, `encode_query()`/`encode_document()` methods for IR tasks. Fully backwards compatible. |
| ChromaDB | Unspecified version | **v1.5.0** (latest, Feb 2026) | Split into `chromadb` + `chromadb-client`. No breaking API changes. |
| YamlDotNet | Unspecified version | **v16.3.0** | Breaking change in v16.0.0: `IYamlTypeConverter` interface changed, position properties changed from `int` to `long`. |
| Colab Alternatives | Google Colab (free tier) | **Kaggle Notebooks** as primary recommendation | More generous free GPU quota (~30 hrs/week), T4 GPUs, persistent storage. Colab free tier has become more restrictive (15-30 GPU hrs/week). |

### 3.2. Python / Google Colab Stack (Prototyping)

| Component | Package | Version | Notes |
|-----------|---------|---------|-------|
| Embeddings | `sentence-transformers` | 5.2.2 | Use `encode_query()` / `encode_document()` for IR tasks |
| Embedding Model | `nomic-embed-text-v2-moe` | Latest | Requires `trust_remote_code=True`. Use `prompt_name="passage"` for docs, `"query"` for search. |
| Fallback Model | `all-MiniLM-L6-v2` | Latest | 384 dims, faster, good for rapid iteration |
| Comparison Model | `mxbai-embed-large` | Latest | 1024 dims, BERT-large class |
| Vector DB | `chromadb` | 1.5.0 | In-memory for prototyping, persistent for iteration |
| Math/Stats | `numpy`, `scikit-learn` | Latest | Cosine similarity, clustering, statistical tests |
| Visualization | `matplotlib`, `seaborn` | Latest | Embedding space visualization, evaluation plots |
| YAML Parsing | `pyyaml` | Latest | For parsing test corpus frontmatter |
| Environment | Kaggle Notebooks or Google Colab | — | Kaggle preferred for GPU quota |

### 3.3. C# / .NET Stack (Production)

| Component | Package/Framework | Version | Notes |
|-----------|-------------------|---------|-------|
| Target Framework | .NET 10 | LTS (Nov 2025 – Nov 2028) | Current LTS version |
| CLI Framework | Spectre.Console.Cli | Latest | Opinionated, modern CLI framework with rich rendering |
| YAML Parser | YamlDotNet | 16.3.0 | Note: breaking changes from v15 → v16 in type converter interfaces |
| Markdown Parser | Markdig | 0.44.0 | CommonMark-compliant, stable, no breaking changes |
| Git Integration | LibGit2Sharp | Latest | For Chronicle's VCS layer |
| Testing | xUnit + FluentAssertions | Latest | Unit and integration testing |
| Embedding Abstraction | `Microsoft.Extensions.AI.Abstractions` | GA | Ecosystem-standard `IEmbeddingGenerator` interface |
| Vector Store Abstraction | `Microsoft.Extensions.VectorData.Abstractions` | GA | Standard vector CRUD + search |
| Ollama Client | OllamaSharp | 5.4.16 | Reference implementation for local embedding generation |
| SQLite Vector | `Microsoft.SemanticKernel.Connectors.SqliteVec` | Preview | Requires manual sqlite-vec setup; .NET bindings incomplete |
| Qdrant Client | `Microsoft.SemanticKernel.Connectors.Qdrant` | Preview | Production-grade alternative to SQLite |

### 3.4. Embedding Models

| Model | Dimensions | Context Window | Architecture | Best For |
|-------|-----------|----------------|--------------|----------|
| `nomic-embed-text-v2-moe` | 768 (Matryoshka: truncatable to 256, 128, 64) | 8,192 tokens | Mixture-of-Experts (475M total, 305M active) | **Primary recommendation.** Best balance of quality, efficiency, and multilingual support. |
| `all-MiniLM-L6-v2` | 384 | 256 tokens | Standard transformer | Fast prototyping, small corpora, when speed matters more than quality |
| `mxbai-embed-large` | 1,024 | 512 tokens | BERT-large | Comparison baseline; state-of-the-art in its parameter class |
| `BGE-M3` | Varies | 8,192 tokens | Multi-granularity | If multilingual or hybrid dense+sparse retrieval needed |

**Design Proposal Update:** The recommendation of `nomic-embed-text` (v1.x) should be updated to `nomic-embed-text-v2-moe` throughout. The v2 model is a significant upgrade — the MoE architecture is more efficient at inference (only 305M of 475M params active per forward pass), supports ~100 languages natively (relevant if Aethelgard ever includes constructed languages or if FractalRecall is used for multilingual corpora), and maintains the Matryoshka dimension support that makes it useful for variable-precision retrieval experiments.

**Design Decision:** FractalRecall's `IEmbeddingProvider` interface should be designed to be compatible with (or a thin wrapper around) `Microsoft.Extensions.AI.Abstractions.IEmbeddingGenerator<string, Embedding<float>>`. This positions FractalRecall within the .NET AI ecosystem rather than as an isolated library with its own abstractions. The benefit is that any embedding provider that already implements the Microsoft interface (OllamaSharp, OpenAI, Azure, etc.) works with FractalRecall out of the box, with zero adapter code from the consuming application.

---

## 4. Legacy Content Disposition

### 4.1. What Is Legacy

The `fractal-recall` repository contains content from an earlier conceptualization of FractalRecall as a **general-purpose AI memory architecture** inspired by cognitive science. This earlier vision explored:

- Human memory models (Atkinson-Shiffrin, Baddeley's Working Memory, Tulving's encoding specificity)
- AI memory systems (MemGPT, Neural Turing Machines, Memory Networks)
- Fractal geometry in biology and language
- Graph and tree data structure theory
- A Python-based `FractalNode` class with `add_memory` / `retrieve_memory` operations

The current vision has **pivoted** FractalRecall into a focused .NET class library for hierarchical context-aware embedding retrieval. The cognitive science origins provided inspirational vocabulary (the DNA metaphor, the fractal self-similarity concept, context encoding principles), but the technical design is now grounded in RAG/embedding literature (Anthropic's Contextual Retrieval, GraphRAG, RAPTOR, Late Chunking).

### 4.2. Archive Strategy

The following files should be moved to `fractal-recall/docs/archive/` to preserve them without cluttering the active documentation:

| File | Current Location | Status |
|------|-----------------|--------|
| `research-plan.md` | `docs/` | Archive. The exhaustive 10-section research plan is no longer on the critical path. Contains ~100+ hours of research tasks that are tangential to the current focused architecture. |
| `scope/1.1-human-memory-architecture.md` | `docs/scope/` | Archive. Detailed scope breakdown for cognitive science research (Atkinson-Shiffrin, Baddeley, LTM subtypes, Tulving). Inspirational but not foundational for current design. |
| `README.md` | Repository root | **Replace** (see separate task). The current README describes a Python-based AI memory system that doesn't match the .NET embedding library vision. |

A brief `docs/archive/ARCHIVE-NOTES.md` document should be created alongside the archived files, explaining what they are and why they were archived. This prevents future contributors (or future-us) from wondering whether they're missing something important.

### 4.3. Concepts That Survived the Pivot

The following concepts from the legacy research are still relevant and have been incorporated into the current Conceptual Architecture. These are documented here for traceability:

1. **The DNA Metaphor (from `research-plan.md` §5.1b):** The idea that every chunk carries its full ancestry context, like a gene carrying its chromosomal address. This directly became FractalRecall's Composite Representation concept and the structural fingerprint mechanism.

2. **Encoding Specificity (from `1.1-human-memory-architecture.md` §1.1d):** Tulving's principle that retrieval succeeds when the retrieval cue matches the encoding context. This directly informed the design decision that context layers must be present at *both* indexing time and query time — the query is enriched with the same structural context types that the indexed chunks carry.

3. **Fractal Self-Similarity (from `research-plan.md` §3.3a):** The mathematical concept that a structure exhibits self-similar patterns at every scale. This became the conceptual foundation for context layers — meaningful structure exists at every level of granularity from corpus to sentence, and the system should be aware of structure at every level.

4. **Hierarchical Memory Tiers (from `research-plan.md` §2.3, `README.md` Level 0-3):** The idea of organizing memory into hierarchical levels with different abstraction scopes. This influenced the context layer hierarchy positions (Corpus=100 → Domain=90 → Entity=80 → ... → Content=0).

5. **Context Propagation (from `research-plan.md` §5.4):** The question of "how far up the ancestry chain does context propagate?" became the composite representation's token budget management and graceful degradation strategy (Rule 5 in the Conceptual Architecture, §6.3).

---

## 5. Document Manifest

### 5.1. Completed Documents

| # | Document | Project | Location | ~Length | Status |
|---|----------|---------|----------|--------|--------|
| D-01 | Unified Design Proposal | Both | `Chronicle-FractalRecall-Design-Proposal.md` | ~720 lines | ✅ Draft Complete |
| D-02 | FractalRecall Conceptual Architecture | FractalRecall | `fractal-recall/docs/fractalrecall-conceptual-architectural-design.md` | ~930 lines | ✅ Draft Complete |
| D-03 | Session Bootstrap Context | Both | `Chronicle-FractalRecall-Session-Bootstrap.md` | ~123 lines | ✅ Draft Complete |
| D-04 | Master Execution Strategy | Both | `Chronicle-FractalRecall-Master-Strategy.md` | This document | ✅ Draft Complete |
| D-30 | Legacy Archive Notes | FractalRecall | `fractal-recall/docs/archive/ARCHIVE-NOTES.md` | ~60 lines | ✅ Complete |
| D-31 | FractalRecall README (Replacement) | FractalRecall | `fractal-recall/README.md` | ~163 lines | ✅ Complete |
| D-32 | Colab Session Context Briefing | FractalRecall | `fractal-recall/notebooks/COLAB-SESSION-CONTEXT.md` | ~230 lines | ✅ Complete |
| D-33 | Notebook Context Cell Template | FractalRecall | `fractal-recall/notebooks/NOTEBOOK-CONTEXT-CELL.md` | ~50 lines | ✅ Complete |

### 5.2. Track A Documents (Chronicle — Phase 1)

| # | Document | Dependencies | Priority | Description |
|---|----------|-------------|----------|-------------|
| D-10 | Lore File Schema Specification | D-01 (§4.3) | **High** | Formal definition of valid YAML frontmatter per entity type. Required fields, optional fields, data types, validation rules, extensibility mechanism. This is Chronicle's "data model" — Phase 2 implementation cannot begin without it. |
| D-11 | Canon Workflow Specification | D-01 (§4.4), D-10 | **High** | Rules governing content lifecycle: draft → canonical promotion, deprecation, apocryphal branching, merge validation, status transition guards. Depends on schema spec because canon status is a schema field. |
| D-12 | Validation Rule Catalog | D-01 (§4.5), D-10, D-11 | **High** | Every deterministic validation check documented as a testable behavior with examples of passing and failing cases. This becomes the unit test specification for Phase 2. Depends on schema and canon specs because validation enforces their rules. |
| D-13 | CLI Command Reference | D-01 (§4.7), D-10–D-12 | **Medium** | Every CLI command with syntax, flags, usage examples, and expected output. Depends on validation and schema specs because commands invoke those subsystems. |
| D-14 | LLM Integration Specification | D-01 (§6) | **Medium** | Prompt templates for each LLM feature, expected response formats, report output schemas. Can be written independently of schema/validation specs since LLM features operate at a different layer. |
| D-15 | Integration Design Document | D-10, D-02, Track B results | **Low (blocked)** | How Chronicle consumes FractalRecall's API. Which layers Chronicle constructs from frontmatter and how. **Blocked until Track B produces Colab results** (needs to know which embedding strategy and layer configuration won). |

### 5.3. Track B Documents (FractalRecall — Phase 0/1)

| # | Document | Dependencies | Priority | Description |
|---|----------|-------------|----------|-------------|
| D-20 | Test Corpus Preparation Guide | D-02 (§11.3) | **High** | Specifies how Aethelgard content is exported from Notion, converted to Markdown + YAML frontmatter, and structured for evaluation. Includes corpus requirements, file format, and ground-truth annotation protocol. |
| D-21 | Colab Notebook 1: Baseline | D-20, D-02 (§10.2) | **High** | Standard RAG baseline on the Aethelgard test corpus. |
| D-22 | Colab Notebook 2: Single-Layer Enrichment | D-21 | **High** | Replicates Anthropic's Contextual Retrieval approach. |
| D-23 | Colab Notebook 3: Multi-Layer Enrichment | D-22 | **Critical** | Tests FractalRecall's core hypothesis. **Go/no-go decision point.** |
| D-24 | Colab Notebook 4: Layer Ablation | D-23 | **High** | Determines which layers matter most. |
| D-25 | Colab Notebook 5: Strategy Comparison | D-24 | **Medium** | Compares Prefix, Multi-Vector, and Hybrid embedding strategies. |
| D-26 | Colab Notebook 6: Cross-Domain Validation | D-24 | **Medium** | Tests generalization on a non-worldbuilding corpus. |
| D-27 | Prototyping Findings Document | D-21–D-26 | **High** | Summary of all Colab results, conclusions, and design implications. Informs the C# API design. |
| D-28 | FractalRecall API Design Spec (Refined) | D-27, D-02 (§9) | **High** | Refined API specification based on Colab findings. Extends the conceptual API sketch. |

### 5.4. Shared / Cross-Cutting Documents

| # | Document | Dependencies | Priority | Description |
|---|----------|-------------|----------|-------------|
| D-30 | Legacy Archive Notes | Legacy content review | ✅ **Complete** | Brief document explaining what's in the archive folder and why. |
| D-31 | FractalRecall README (Replacement) | D-02 | ✅ **Complete** | New README aligned with current vision as a .NET embedding enrichment library. |
| D-32 | Colab Session Context Briefing | D-02, D-21–D-26 | ✅ **Complete** | Gemini-optimized briefing document for AI assistants in Colab/Kaggle. Covers project summary, layer system, tech stack, code patterns, and debugging context. Location: `fractal-recall/notebooks/COLAB-SESSION-CONTEXT.md` |
| D-33 | Notebook Context Cell Template | D-32 | ✅ **Complete** | Template for the self-documenting markdown cell at the top of each notebook. Per-notebook placeholder values. Location: `fractal-recall/notebooks/NOTEBOOK-CONTEXT-CELL.md` |

### 5.5. Phase 2+ Documents (During Implementation)

| # | Document | Dependencies | Priority | Description |
|---|----------|-------------|----------|-------------|
| D-40 | FractalRecall README (Full) | D-28 | Deferred | NuGet package README with quick-start example, installation, and API overview. |
| D-41 | FractalRecall Contributing Guide | D-28 | Deferred | Setup, coding standards, PR process, testing requirements. |
| D-42 | Chronicle README | D-10–D-13 | Deferred | Repository README with installation, quick-start, and feature overview. |
| D-43 | Chronicle Contributing Guide | D-10–D-13 | Deferred | Setup, coding standards, PR process, testing requirements. |
| D-44 | Chronicle User Guide | Phase 2 implementation | Deferred | End-user documentation for setting up and using Chronicle. |

---

## 6. Track A: Chronicle Documentation Sprint

### 6.1. Sprint Objective

Produce six specification documents that fully define Chronicle's domain model, validation rules, canon workflow, CLI interface, and LLM integration layer — in sufficient detail that Phase 2 implementation can proceed with no ambiguity about what to build.

### 6.2. Document Sequencing and Dependencies

```
D-10 Lore File Schema Spec
  ↓
D-11 Canon Workflow Spec (depends on D-10 for canon field definition)
  ↓
D-12 Validation Rule Catalog (depends on D-10 + D-11 for rules to validate)
  ↓
D-13 CLI Command Reference (depends on D-10 through D-12 for command behavior)

D-14 LLM Integration Spec (independent — can be written in parallel with D-10 through D-13)

D-15 Integration Design Doc (blocked — requires Track B results)
```

**Recommended execution order:** D-10 → D-11 → D-12 → D-13, with D-14 interleaved whenever you want a change of pace. D-15 waits.

### 6.3. Document Specifications

#### D-10: Lore File Schema Specification

**Purpose:** Define the complete data model for Chronicle lore files. This is the "database schema" equivalent — every entity type, every field, every constraint.

**Must contain:**
- Default entity types shipped with Chronicle (faction, character, location, event, timeline, system) with full field definitions
- Required vs. optional fields per entity type
- Data types and validation constraints for each field (string, enum, date format, file path reference, list, map)
- The `relationships` block structure: `target`, `type`, `since`, `note` fields with their semantics
- The `canon` field: allowed values (`true`, `false`, `"apocryphal"`, `"deprecated"`), semantic meaning of each
- Extensibility mechanism: how users define custom entity types and add custom fields
- Example frontmatter blocks for each default entity type (minimum: faction, character, location, event)
- JSON Schema or equivalent formal schema definition that the validator will parse

**Open questions to resolve during writing:**
- OQ-2 from Design Proposal: Should custom entity types be supported from day one, or start with a fixed set? (Recommendation: support from day one — the extensibility mechanism is part of the schema spec, even if the initial implementation only ships with defaults.)
- OQ-3 from Design Proposal: Should relationship `type` use a fixed vocabulary or allow free-form? (Recommendation: ship with a recommended vocabulary but allow free-form. The validator warns on non-standard types but doesn't reject them.)

#### D-11: Canon Workflow Specification

**Purpose:** Define the complete content lifecycle and the rules that govern status transitions.

**Must contain:**
- State machine diagram showing all valid transitions between canon statuses
- Transition guards: what conditions must be met for each transition (e.g., draft → canonical requires passing all validation checks on the target branch)
- Branch conventions: which branches correspond to which canon states (e.g., `main` = canonical, feature branches = draft, `apocrypha/*` branches = apocryphal)
- Merge semantics: what happens to `canon` field values when a branch is merged into `main`
- Deprecation workflow: how to deprecate content, the `superseded_by` reference, and how deprecated content is handled in search and validation
- Apocryphal content rules: relaxed validation, permanent exclusion from canonical queries, allowed contradictions
- Edge cases: what happens when a canonical document is modified on a feature branch? When an apocryphal branch references canonical content? When deprecated content is un-deprecated?

#### D-12: Validation Rule Catalog

**Purpose:** Exhaustively document every deterministic validation check as a testable behavior. This document becomes the Phase 2 unit test specification.

**Format per rule:**
```
Rule ID: VAL-SCH-001
Category: Schema Validation
Name: Required Field Presence
Description: Every lore file must contain all fields marked as "required"
              in the schema for its declared entity type.
Severity: Error
Passing Example: [frontmatter with all required fields present]
Failing Example: [frontmatter missing the "name" field]
Error Message: "Schema error in {file}: Missing required field '{field}'
                for entity type '{type}'."
```

**Must contain rules for:**
- Schema validation (required fields, type checking, enum value validation)
- Cross-reference integrity (relationship targets exist, no broken links)
- Timeline consistency (dates within era boundaries)
- Uniqueness constraints (no duplicate unique attributes)
- Alias collision detection (overlapping alternative names)
- Canon status consistency (canonical docs shouldn't reference draft/apocryphal docs)

#### D-13: CLI Command Reference

**Purpose:** Formal specification of every Chronicle CLI command.

**Format per command:**
```
Command: chronicle validate
Synopsis: chronicle validate [options]
Description: Run all deterministic validation checks against the
             current repository state.
Options:
  --deep          Also run LLM-powered semantic checks (requires
                  configured LLM endpoint)
  --output FILE   Write validation report to FILE (Markdown format)
  --severity LVL  Minimum severity to report: error, warning, info
                  (default: warning)
  --type TYPE     Validate only entities of the specified type
                  (e.g., faction, character)
Exit Codes:
  0 — All checks passed
  1 — One or more errors found
  2 — Configuration error (missing schema, invalid config)
Examples:
  $ chronicle validate
  $ chronicle validate --deep --output report.md
  $ chronicle validate --type faction --severity error
```

#### D-14: LLM Integration Specification

**Purpose:** Define the prompt engineering, response parsing, and report generation for each LLM-powered feature.

**Must contain for each feature (contradiction detection, merge analysis, lore suggestions, stub generation):**
- System prompt template (the instructions given to the LLM)
- User prompt template (how the lore content is formatted for the LLM)
- Expected response schema (what the LLM output should look like)
- Response parsing logic (how Chronicle interprets the LLM output)
- Report output format (the Markdown report generated for the human)
- Error handling (what happens when the LLM produces unparseable output)
- Performance characteristics (expected input token counts, batch strategies for large corpora)

#### D-15: Integration Design Document

**Status: Blocked** — Cannot be written until Track B produces Colab results that determine the embedding strategy and layer configuration.

**Will contain:**
- How Chronicle extracts context layer values from YAML frontmatter
- Mapping table: frontmatter field → FractalRecall context layer
- Layer weight defaults for Chronicle's query scenarios
- Incremental indexing strategy (detecting frontmatter changes via Git)
- FractalRecall API usage examples in Chronicle's context

---

## 7. Track B: FractalRecall Colab Prototyping

### 7.1. Sprint Objective

Empirically validate that FractalRecall's multi-layer embedding enrichment improves retrieval quality compared to standard RAG and single-layer enrichment, using the Aethelgard worldbuilding corpus as the primary test dataset. Produce documented, reproducible experimental results that inform the C# library's API design.

### 7.2. Test Corpus Preparation

**Source:** Ryan's existing Aethelgard worldbuilding content, currently maintained in Notion.

**Preparation steps:**

1. **Export from Notion:** Export relevant Aethelgard pages as Markdown. Notion's native export produces Markdown files with some formatting artifacts that will need cleanup.

2. **Add YAML Frontmatter:** Each exported file needs YAML frontmatter added according to Chronicle's schema design (D-10). Since D-10 may not be fully written yet when corpus preparation begins, use the example frontmatter from the Design Proposal (§4.3) as the working format. Any refinements from D-10 can be back-applied.

3. **Corpus Requirements** (from Conceptual Architecture, §11.3):
   - At least 50 documents with structured metadata
   - At least 3 entity types (factions, characters, events, locations, etc.)
   - At least 2 authority levels (canonical and draft/apocryphal)
   - Cross-references between entities (relationship links in frontmatter)
   - Temporal metadata (eras, dates)

4. **Ground-Truth Query Set:** Develop at least 30 test queries with manually annotated ground-truth relevance judgments (following the protocol in Conceptual Architecture, §11.4). Query types should include:
   - Factual single-hop (e.g., "When was the Iron Covenant founded?")
   - Factual multi-hop (e.g., "Which factions were active in the same region as Elena Voss's birthplace?")
   - Authority-sensitive (e.g., "What is the canonical explanation for the Arcane Purges?")
   - Temporal-scoped (e.g., "What major events occurred in the Third Age?")
   - Exploratory (e.g., "What are the political tensions in the Ashenmoor region?")

5. **Storage:** The prepared corpus lives in the `fractal-recall` repository under `notebooks/test-corpus/` (version-controlled as part of the project's evaluation assets).

### 7.3. Notebook Sequencing and Dependencies

```
D-20 Test Corpus Preparation
  ↓
D-21 Notebook 1: Baseline
  ↓
D-22 Notebook 2: Single-Layer
  ↓
D-23 Notebook 3: Multi-Layer  ← GO/NO-GO DECISION POINT
  ↓
D-24 Notebook 4: Ablation  ←─┐
  ↓                            │ (can run in parallel if desired)
D-25 Notebook 5: Strategy  ←─┘
  ↓
D-26 Notebook 6: Cross-Domain
  ↓
D-27 Prototyping Findings Document
  ↓
D-28 API Design Spec (Refined)
```

### 7.4. Notebook Specifications

Each notebook should follow a consistent structure:

```
1. Objective (what question this notebook answers)
2. Setup (imports, model loading, corpus loading)
3. Methodology (what we're doing and why)
4. Implementation (the actual code)
5. Results (metrics, tables, visualizations)
6. Analysis (what the results mean)
7. Implications for C# Design (what we learned for production)
8. Next Steps (what the next notebook should explore)
```

**Notebook 1: Baseline Establishment**
- Load Aethelgard corpus, parse YAML frontmatter, extract body text
- Chunk using heading-based strategy (each Markdown section becomes a chunk, with a maximum chunk size and overflow splitting)
- Embed with `nomic-embed-text-v2-moe` via sentence-transformers (`prompt_name="passage"`)
- Store in ChromaDB (in-memory)
- Run all 30+ ground-truth queries (`prompt_name="query"`)
- Compute: Precision@5, Recall@10, NDCG@10, MRR
- Visualize: per-query-type performance breakdown, embedding space visualization

**Notebook 2: Single-Layer Enrichment**
- Same corpus, same chunking, same queries
- Before embedding each chunk, prepend a document-level context summary derived from YAML frontmatter (document title, entity type, canon status — rendered as a natural language sentence)
- This replicates Anthropic's Contextual Retrieval approach using metadata rather than LLM-generated summaries
- Compare metrics against Notebook 1 baseline
- Visualize: improvement distribution across query types

**Notebook 3: Multi-Layer Enrichment (Core Hypothesis)**
- Same corpus, same chunking, same queries
- Before embedding each chunk, construct the full composite representation with all 8 context layers (Corpus, Domain, Entity, Authority, Temporal, Relational, Section, Content) — rendered as the text template shown in Conceptual Architecture §6.4
- Compare metrics against both Notebook 1 (baseline) and Notebook 2 (single-layer)
- Statistical significance test (Wilcoxon signed-rank, p < 0.05)
- **This is the go/no-go decision point.** If multi-layer doesn't significantly outperform single-layer, document the finding and reassess FractalRecall's scope.

**Notebook 4: Layer Ablation Study**
- Starting from content-only (baseline), add layers one at a time:
  Content → +Authority → +Entity → +Temporal → +Relational → +Domain → +Section → +Corpus
- Measure retrieval quality after each addition
- Identify the "diminishing returns" point
- Determine recommended default layer configuration
- Visualize: marginal improvement per layer, cumulative improvement curve

**Notebook 5: Embedding Strategy Comparison**
- Implement all three embedding strategies using the optimal layer configuration from Notebook 4:
  - Approach A: Prefix Enrichment (single vector per chunk)
  - Approach B: Multi-Vector Composition (one vector per layer per chunk)
  - Approach C: Hybrid with Metadata Sidecar (selected layers in embedding, rest as metadata filters)
- Compare: retrieval quality, indexing time, storage size, query latency
- Determine recommended default strategy for C# library

**Notebook 6: Cross-Domain Validation**
- Prepare a second test corpus from a different domain (technical documentation recommended — e.g., a well-structured API reference or developer guide with clear hierarchy, versioning, and cross-references)
- Apply the same experimental protocol (baseline → single-layer → multi-layer → ablation)
- Compare results to worldbuilding experiments
- Assess whether the technique generalizes or is domain-specific

### 7.5. Exit Criteria

Track B is complete when:
- [ ] All six notebooks have been executed with documented results
- [ ] Multi-layer enrichment has been validated (or invalidated) with statistical significance
- [ ] Layer configuration has been stabilized (recommended defaults established)
- [ ] Embedding strategy has been selected (with rationale)
- [ ] Prototyping Findings Document (D-27) has been written
- [ ] API Design Spec (D-28) has been refined based on findings

---

## 8. Research Due Diligence

### 8.1. Research That Must Happen Before Prototyping

| # | Topic | Purpose | Estimated Effort | Blocks |
|---|-------|---------|-----------------|--------|
| R-01 | `nomic-embed-text-v2-moe` behavior with long prefixed inputs | Understand how the MoE architecture handles context-enriched inputs. Does it attention-attend differently to prefix vs. content? What's the effective context utilization at 4K, 6K, 8K tokens? | 2-3 hours (empirical testing) | D-21 (model selection) |
| R-02 | Optimal chunking strategies for worldbuilding Markdown | Literature review + small-scale testing of heading-based, fixed-window, and hybrid chunking. OQ-4 from Design Proposal. | 3-4 hours | D-21 (chunking implementation) |
| R-03 | ChromaDB metadata filtering capabilities | Verify that ChromaDB supports the metadata filter types needed for Approach C (exact match, contains, range). Document API for filtering. | 1-2 hours | D-25 (Approach C implementation) |

### 8.2. Research That Can Happen During Prototyping

| # | Topic | Purpose | Estimated Effort | Informs |
|---|-------|---------|-----------------|---------|
| R-04 | Anthropic Contextual Retrieval — follow-up work | Check for updated benchmarks, community reproductions, or extensions since Oct 2024. No formal follow-up paper exists as of Feb 2026, but community implementations may provide insights. | 2-3 hours | D-22 methodology |
| R-05 | Late Chunking interaction with prefix enrichment | OQ-6 from Conceptual Architecture. Can Late Chunking and prefix enrichment be combined? Does one subsume the other? | 4-6 hours (empirical) | Future notebook beyond initial six |
| R-06 | Matryoshka dimension reduction for layer-specific embeddings | Can Matryoshka truncation be used to create "zoom levels" — full-dimension for content-rich queries, reduced-dimension for structural filtering? | 3-4 hours | D-25 (strategy refinement) |

### 8.3. Research That Must Happen Before C# Implementation

| # | Topic | Purpose | Estimated Effort | Blocks |
|---|-------|---------|-----------------|--------|
| R-07 | `Microsoft.Extensions.AI.Abstractions` API surface | Deep-dive into `IEmbeddingGenerator` interface, understand how to compose with or wrap it for FractalRecall's needs. | 3-4 hours | D-28 (API design) |
| R-08 | `Microsoft.Extensions.VectorData.Abstractions` capabilities | Evaluate whether FractalRecall's `IFractalIndex` should extend, wrap, or replace these abstractions. | 3-4 hours | D-28 (API design) |
| R-09 | SQLite-vec .NET integration options | The .NET bindings for sqlite-vec are currently incomplete (GitHub issue #193). Evaluate workarounds: P/Invoke, Semantic Kernel connector, or alternative backends. | 4-6 hours | Phase 2 implementation |
| R-10 | Semantic Kernel connector architecture | Understand the connector model to determine whether FractalRecall should provide a Semantic Kernel connector package (e.g., `FractalRecall.SemanticKernel`). | 2-3 hours | Phase 2 package structure |

---

## 9. Phase 2+ Implementation Planning

### 9.1. What Phase 2 Looks Like (Preview)

Phase 2 begins when both tracks are complete. The implementation work is:

**FractalRecall (.NET Class Library):**
- Core abstractions: `ContextLayer`, `CompositeRepresentationBuilder`, layer registry
- Interface definitions: wrapping or extending `IEmbeddingGenerator` and `IVectorStore` from Microsoft abstractions
- Reference implementations: OllamaSharp-backed embedding provider, SQLite-vec or Qdrant-backed index
- Evaluation harness: port of Colab evaluation logic to C# for regression testing
- Unit tests: comprehensive, using in-memory implementations

**Chronicle (.NET CLI Application):**
- Markdown+YAML parser (YamlDotNet + Markdig)
- Directory scanner and entity model builder
- Frontmatter schema validator (implementing D-10 and D-12)
- Canon workflow engine (implementing D-11)
- Deterministic validation engine (implementing D-12)
- CLI command framework (Spectre.Console.Cli, implementing D-13)
- Unit tests: one test per validation rule in D-12

### 9.2. Integration Strategy (Phase 3 Preview)

Phase 3 wires Chronicle to FractalRecall:
- Chronicle's `index` command: extracts frontmatter metadata → constructs FractalRecall context layers → calls embedding provider → stores in FractalRecall index
- Chronicle's `search` command: constructs FractalRecall query with layer weights and metadata filters → executes against index → formats results for CLI output
- Integration tests: end-to-end indexing and search against a test corpus

---

## 10. Risk Management

### 10.1. Critical Path Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Multi-layer enrichment doesn't outperform single-layer | Medium | High — FractalRecall scope must be reconsidered | Phase 0 is designed to catch this early. If confirmed, FractalRecall simplifies to a thin wrapper over Contextual Retrieval with metadata filtering. Still useful, just less novel. |
| Aethelgard corpus too small for meaningful evaluation | Low | Medium — results lack statistical power | Supplement with synthetic content or a second domain corpus. The 50-document minimum from the evaluation framework should be treated as a hard floor. |
| `nomic-embed-text-v2-moe` handles long prefixed inputs poorly | Medium | Medium — forces model switching | Test with multiple models during prototyping. `mxbai-embed-large` and `BGE-M3` are alternatives. |
| SQLite-vec .NET bindings remain incomplete | Medium | Low — alternative backends exist | Qdrant has mature .NET support via Semantic Kernel connector. SQLite-vec is preferred for simplicity but not required. |
| Scope creep across 8+ documents and 6+ notebooks | High | Medium — delays delivery, reduces momentum | This strategy document defines clear boundaries and sequencing. Each document/notebook has a defined scope. Resist adding "one more thing." |
| Context window limitations in Colab notebooks | Low | Low — Kaggle and paid tiers are alternatives | Start with Kaggle Notebooks (more generous free GPU). Escalate to Colab Pro or RunPod if needed. |

### 10.2. Mitigation Strategies

**For the "doesn't work" risk:** The most important mitigation is already built into the plan — Phase 0 exists specifically to fail fast and cheap (in Python notebooks) before investing in C# production code. If multi-layer enrichment provides only marginal improvement, FractalRecall can pivot to being a well-structured metadata filtering + single-layer enrichment library, which is still useful and still demonstrates competence in AI retrieval architecture.

**For scope creep:** Each work item in this strategy has a defined "done" state. When writing Chronicle specs, resist the urge to also prototype implementations. When building Colab notebooks, resist the urge to also optimize performance. Each phase is about one thing: documentation, validation, or implementation. Mixing phases is the primary source of scope creep in docs-first projects.

---

## 11. Open Questions Carried Forward

The following open questions from the Design Proposal and Conceptual Architecture remain unresolved and will be addressed at specific points in the execution:

| OQ | From | Question | When to Resolve |
|----|------|----------|----------------|
| OQ-1 | Design Proposal | Multi-file entities (parent/child documents) | During D-10 (Schema Spec) |
| OQ-2 | Design Proposal | Custom entity types from day one? | During D-10 (Schema Spec) — Recommended: yes |
| OQ-3 | Design Proposal | Fixed vs. free-form relationship types | During D-10 (Schema Spec) — Recommended: recommended vocabulary, allow free-form |
| OQ-4 | Design Proposal | Optimal chunking strategy for worldbuilding Markdown | During R-02 (pre-prototyping research) and D-21 (Notebook 1) |
| OQ-5 | Design Proposal | Should Chronicle validate prose content against frontmatter? | During D-14 (LLM Integration Spec) |
| OQ-6 | Design Proposal | Migration path from Notion for Aethelgard content | During D-20 (Test Corpus Preparation) — will discover the practical challenges |
| FR-OQ-1 | Conceptual Architecture | Optimal layer ordering in embedded text | During D-23 (Notebook 3) — test outermost-first vs. innermost-first |
| FR-OQ-2 | Conceptual Architecture | Natural language vs. structured tokens for relational layer | During D-23 (Notebook 3) — test both renderings |
| FR-OQ-3 | Conceptual Architecture | Versioned corpora — version as dedicated layer or within Corpus layer? | During D-24 (Notebook 4) — ablation may reveal answer |
| FR-OQ-4 | Conceptual Architecture | Minimum corpus size threshold | During D-26 (Notebook 6) — test with varying corpus sizes |
| FR-OQ-5 | Conceptual Architecture | Multi-language corpora — context layer language | Deferred to post-Phase 2 (not on critical path) |
| FR-OQ-6 | Conceptual Architecture | Late Chunking interaction with prefix enrichment | During R-05 (optional research during prototyping) |

---

## 12. Decision Log

Decisions made during strategic planning on 2026-02-10:

| # | Decision | Rationale |
|---|----------|-----------|
| SD-01 | Execute Track A (Chronicle docs) and Track B (Colab prototyping) in parallel, not sequentially | Chronicle docs don't depend on Colab results (except D-15). Parallel execution is fastest path to Phase 2 readiness. |
| SD-02 | Archive legacy FractalRecall docs, don't delete | Preserves history and traceability. Five specific concepts from legacy content survived into current design and are documented in §4.3. |
| SD-03 | Replace the FractalRecall README immediately | Current README describes an architecturally different project (Python AI memory system vs. .NET embedding library). Causes confusion for anyone encountering the repo. |
| SD-04 | Use real Aethelgard content for test corpus, not synthetic | More authentic evaluation. Ryan has deep familiarity with the corpus (essential for ground-truth annotation). Exercises the Notion migration path (OQ-6). |
| SD-05 | Target .NET 10 instead of .NET 8 | .NET 10 is the current LTS (Nov 2025 – Nov 2028). .NET 8 enters final support year in 2026. New projects should target current LTS. |
| SD-06 | Upgrade embedding model recommendation to `nomic-embed-text-v2-moe` | Significant upgrade: MoE architecture (more efficient), multilingual, maintains Matryoshka support. |
| SD-07 | Align FractalRecall interfaces with `Microsoft.Extensions.AI.Abstractions` | Positions FractalRecall within the .NET AI ecosystem. Any embedding provider implementing the Microsoft interface works with FractalRecall out of the box. |
| SD-08 | ~~Prefer Kaggle Notebooks over Google Colab free tier for prototyping~~ **CORRECTED:** Use Colab Pro as primary prototyping environment | Original recommendation was based on free-tier comparison. Ryan has a Colab Pro subscription, which provides priority GPU access, longer runtimes, and more memory — eliminating Kaggle's free-tier advantages. Colab Pro also offers better notebook management UX and direct Google Drive integration. |
| SD-09 | Author notebooks in Claude sessions, execute in Colab Pro | Claude has full FractalRecall context and can explain Python as we go (building Ryan's Python literacy). Gemini serves as a runtime debugging assistant only, not a code authorship partner. A Colab Session Context briefing doc (D-32) provides Gemini with enough context for troubleshooting. |
| SD-10 | Include self-documenting context cell in every notebook | Each notebook carries a condensed version of the project context as its first markdown cell. The notebook is self-documenting — whoever opens it (human or AI) understands what it's doing and where it fits in the experiment sequence. |
| SD-11 | Local execution via JetBrains (DataSpell/PyCharm Pro) + Mac Studio as fallback environment | Ryan's Mac Studio M3 Ultra (512GB RAM) is more than capable of running the embedding workload locally via MPS (Metal Performance Shaders) backend. sentence-transformers supports MPS natively. JetBrains provides professional Jupyter support with code completion, debugging, and variable inspection. Primary environment remains Colab Pro for convenience (pre-configured Python environment, no local dependency management), but local execution is available when cloud is impractical or for longer-running experiments. |

---

## 13. Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1.0 | 2026-02-10 | Ryan + Claude | Initial strategy document. Defines parallel execution tracks, technology stack updates, document manifest, legacy disposition, research due diligence, risk management. |
| 0.1.1 | 2026-02-10 | Ryan + Claude | Added D-32/D-33 to manifest, SD-09/SD-10 to decision log (notebook authorship workflow, self-documenting context cells). |
| 0.1.2 | 2026-02-10 | Ryan + Claude | Corrected SD-08 (Kaggle → Colab Pro). Added SD-11 (local Mac Studio fallback via JetBrains). Reflects Ryan's Colab Pro subscription and local hardware capabilities. |

---

*This document governs execution. The Design Proposal governs design intent. The Conceptual Architecture governs FractalRecall's technical specification. The Session Bootstrap provides onboarding context. Together, these four documents provide complete orientation for any session working on Chronicle or FractalRecall.*
