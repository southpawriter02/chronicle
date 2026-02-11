# Chronicle + FractalRecall: Roadmap Status Overview

**Date Generated:** 2026-02-11
**Version:** 1.0
**Reference:** Derived from `Chronicle-FractalRecall-Master-Strategy.md`

---

## Quick Status Summary

| Category | Status | Details |
|----------|--------|---------|
| **Project-Wide** | On Track | Parallel execution model: Track A (docs) and Track B (prototyping) proceeding independently |
| **Phase 0/1 Completion** | In Progress | 17 core documents + 1 research report complete; D-23 spec + notebook ready (awaiting Colab execution); D-24 is next; 1 blocked (D-15); 5 deferred to Phase 2+ |
| **Critical Path** | Healthy | D-23 (multi-layer enrichment GO/NO-GO) spec and notebook complete; awaiting Colab execution for empirical results |
| **Technology Stack** | Updated | .NET 10 LTS, nomic-embed-text-v2-moe, aligned with Microsoft.Extensions.AI ecosystem |
| **Risk Level** | Medium | Scope creep and model performance are the main concerns; mitigations in place |

---

## What's Done ✅

All foundational documents complete:

- **D-01:** Unified Design Proposal (720 lines) — architecture, constraints, design decisions
- **D-02:** FractalRecall Conceptual Architecture (930 lines) — technical specification, layer system, embedding strategies
- **D-03:** Session Bootstrap Context (123 lines) — quick orientation for new sessions
- **D-04:** Master Execution Strategy (this document's source)
- **D-30:** Legacy Archive Notes — explanation of archived conceptual work
- **D-31:** FractalRecall README (Replacement) — updated project description
- **D-32:** Colab Session Context Briefing — AI assistant briefing for notebooks
- **D-33:** Notebook Context Cell Template — self-documenting markdown cell pattern
- **D-10:** Lore File Schema Specification (v0.2.1, ~1470 lines) — ✅ **COMPLETE** — formal Chronicle data model with 12 default entity types, comprehensive examples, JSON Schema definitions. Amended to v0.2.1 with `supersedes` field and §4.8 Superseding Mechanics.
- **D-11:** Canon Workflow Specification (v0.1.1-draft, ~1250 lines) — ✅ **COMPLETE** — content lifecycle state machine with 3 ceremony tiers, 6 workflows, superseding mechanics, branch conventions, merge semantics, validation rules, changelog integration, 7 edge cases. Incorporates all 7 locked design decisions (OQ-D11-1 through OQ-D11-7). §9.4 mapping table updated to reflect actual D-12 rule IDs.
- **D-12:** Validation Rule Catalog (v0.1.1-draft, ~2900 lines) — ✅ **COMPLETE** — 39 deterministic validation rules across 3 tiers (12 schema, 17 structural, 10 semantic), 3 assertion rule types (`temporal_bound`, `value_constraint`, `pattern_match`), apocryphal relaxation modifier, standardized error message format. Incorporates all 6 locked design decisions (OQ-D12-1 through OQ-D12-6). Verified against Master Strategy §6.3 and all design decisions.
- **D-13:** CLI Command Reference (v0.1.0-draft, ~1670 lines) — ✅ **COMPLETE** — 12 CLI commands across 3 phases (8 Phase 2 core, 2 Phase 3 integration, 2 Phase 4 LLM-powered). Global options, exit code reference, output format specifications, configuration reference, cross-reference index. Verified against D-10, D-11, D-12, and D-01 §4.7.
- **D-14:** LLM Integration Specification (v0.1.0-draft, ~1770 lines) — ✅ **COMPLETE** — Four LLM features (contradiction detection, merge analysis, lore suggestions, stub generation) with complete prompt templates, response schemas, parsing logic, report formats, error handling, and performance characteristics. Soft axiom deep validation. Prose-vs-frontmatter consistency checking (resolves OQ-5). Provider abstraction interface (`ILlmProvider`). Configuration reference. Three design decisions (OQ-D14-1 through OQ-D14-3). Verified against Master Strategy §6.3 and all upstream dependencies.

- **R-01-02-03:** Research Findings (v1.0, ~550 lines) — ✅ **COMPLETE** — Pre-prototyping due diligence for three research tasks. R-01: nomic-embed-text-v2-moe has 512-token context window (CRITICAL — not 8,192 as previously assumed). R-02: Hybrid Semantic + Fixed-Window chunking recommended. R-03: ChromaDB metadata filtering viable with JSON serialization workaround for arrays. Master Strategy and Design Proposal amended.
- **D-20:** Test Corpus Preparation (v1.0, ~530 lines) — ✅ **COMPLETE** — 67-file Aethelgard corpus assessed (388K words). Frontmatter audit (92/100 quality score). D-10 schema alignment gap analysis with field mapping strategy. 36 ground-truth queries across 5 types (single-hop, multi-hop, authority-sensitive, temporal-scoped, exploratory). Coverage gap analysis.
- **D-21:** Notebook 1: Model Selection & Embedding Baseline (v1.0, ~3300 lines) — ✅ **COMPLETE** — Full notebook specification with 22 cells (copy-paste-ready Python + Markdown). Three-model comparison (v2-moe, v1.5, BGE-M3). Hybrid Semantic + Fixed-Window chunking engine. 36 ground-truth queries with IR metrics (Precision@5, Recall@10, NDCG@10, MRR). Weighted decision matrix for model selection. UMAP embedding visualization. ChromaDB persistence for D-22 inheritance. **Executable `.ipynb` generated:** `D21-baseline.ipynb` (103KB, 22 cells).
- **D-22:** Notebook 2: Single-Layer Enrichment (v1.0, ~2900 lines) — ✅ **COMPLETE** — Full notebook specification with 22 cells. Adds single-layer enrichment prefix ("This is a {type} document about {name}. Canon status: {canon}.") to each chunk before embedding. Reuses D-21's entire infrastructure. Delta analysis vs. D-21 baseline with Wilcoxon signed-rank significance testing. Parameterized model selection (SELECTED_MODEL constant, default v1.5). **Executable `.ipynb` generated:** `D22-single-layer.ipynb` (83KB, 22 cells).

- **D-23:** Notebook 3: Multi-Layer Enrichment — GO/NO-GO Decision Point (v1.0, ~4470 lines) — ✅ **COMPLETE** — Full notebook specification with 22 cells. Implements 8-layer composite enrichment (Corpus, Domain, Entity, Authority, Temporal, Relational, Section, Content) with per-chunk prefix construction. 3-way comparison design (D-23 vs D-22 vs D-21). Bonferroni-corrected Wilcoxon signed-rank testing (adjusted α ≈ 0.0167). Rank-biserial correlation effect sizes. 7-criterion GO/NO-GO decision engine with programmatic evaluation. Marginal value analysis isolating layers 2-8 contribution. Layer token audit for D-24 ablation planning. DOMAIN_CATEGORY_MAP for richer entity categorization. **Executable `.ipynb` generated:** `D23-multi-layer.ipynb` (160KB, 22 cells).

These 17 documents plus 1 research report represent complete Phase 0 foundation work, all five Track A documents (D-10 through D-14), and Track B preparation through the first three notebooks (R-01-03, D-20, D-21, D-22, D-23).

---

## What's Next (Immediate Priority)

### Track A — Chronicle Documentation Sprint

**Sequential chain (D-10 → D-11 → D-12 → D-13) — COMPLETE:**

| Document | Status | Dependencies | Actual Effort | Notes |
|-----------|--------|-------------|------------|-------|
| **D-10** | ✅ DONE | D-01 ✅ | ~1470 lines | Lore File Schema Specification — 12 entity types, JSON Schema definitions |
| **D-11** | ✅ DONE | D-10 ✅ | ~1250 lines | Canon Workflow Specification — state machine, 3 ceremony tiers, 6 workflows, superseding, branch conventions, merge, changelog, 7 edge cases |
| **D-12** | ✅ DONE | D-10 ✅, D-11 ✅ | ~2900 lines | Validation Rule Catalog — 39 rules across 3 tiers, 3 assertion rule types, 6 design decisions |
| **D-13** | ✅ DONE | D-10 ✅, D-11 ✅, D-12 ✅ | ~1670 lines | CLI Command Reference — 12 commands across 3 phases, exit codes, output formats, config reference |

**Parallel track:**

| Document | Status | Dependencies | Actual Effort | Notes |
|-----------|--------|-------------|------------|-------|
| **D-14** | ✅ DONE | D-01 ✅ | ~1770 lines | LLM Integration Specification — 4 features, prompt templates, response schemas, parsing, reports, OQ-5 resolved |
| **D-15** | 🔴 BLOCKED | D-10 ✅, D-02 ✅, Track B results | TBD | Integration Design Document — waits for Colab findings (go/no-go point) |

**Track A status:** ✅ **All actionable documents complete.** D-10 through D-14 are drafted and verified. Only D-15 remains, blocked on Track B results (D-23 go/no-go decision). Milestone 2 (Track A Docs Sprint) is achieved.

---

### Track B — FractalRecall Colab Prototyping

**Sequential chain with go/no-go decision point:**

| Document | Status | Dependencies | Effort | Notes |
|-----------|--------|-------------|--------|-------|
| **D-20** | ✅ DONE | D-02 ✅ | ~530 lines | Test Corpus Preparation — 67-file corpus audit, field mapping, 36 ground-truth queries |
| **D-21** | ✅ DONE | D-20 ✅ | ~3300 lines | Notebook 1: Model Selection & Embedding Baseline — 22-cell spec, 3-model comparison, chunking engine, evaluation pipeline |
| **D-22** | ✅ DONE | D-21 ✅ | ~2900 lines | Notebook 2: Single-Layer Enrichment — 22-cell spec + .ipynb, delta analysis vs D-21, Wilcoxon significance test |
| **D-23** | ✅ DONE | D-22 ✅ | ~4470 lines | **Notebook 3: Multi-layer enrichment** — GO/NO-GO POINT — 22-cell spec + .ipynb, 8-layer enrichment, 3-way comparison, Bonferroni-corrected Wilcoxon, 7-criterion GO/NO-GO engine |
| **D-24** | 🔵 NEXT | D-23 ✅ | 1-2 days | Notebook 4: Layer ablation (parallelizable with D-25) |
| **D-25** | Blocked on D-23 | D-23 | 2-3 days | Notebook 5: Embedding strategy comparison (parallelizable with D-24) |
| **D-26** | Blocked on D-24/D-25 | D-24 and D-25 | 2-3 days | Notebook 6: Cross-domain validation |
| **D-27** | Blocked on all notebooks | D-21–D-26 | 2-3 days | Prototyping Findings Document — synthesis of results |
| **D-28** | Blocked on D-27 | D-27, D-02 ✅ | 2-3 days | API Design Spec (Refined) — production API based on findings |

**Environment:** Colab Pro (primary) with JetBrains DataSpell/PyCharm Pro + Mac Studio M3 Ultra as local fallback.

**Critical decision point:** D-23 (Notebook 3) determines whether multi-layer enrichment significantly outperforms single-layer. If yes, proceed as planned. If no, reassess FractalRecall's scope but continue with simplified architecture.

---

## Dependency Graph (Text Format)

```
COMPLETED (Phase 0 Foundation)
├─ D-01: Design Proposal ✅
├─ D-02: Conceptual Architecture ✅
├─ D-03: Session Bootstrap ✅
├─ D-04: Master Strategy ✅
├─ D-30: Archive Notes ✅
├─ D-31: FractalRecall README ✅
├─ D-32: Colab Briefing ✅
├─ D-33: Notebook Template ✅
├─ D-10: Lore Schema ✅
└─ D-11: Canon Workflow ✅

TRACK A: CHRONICLE DOCUMENTATION (Phase 1, Deterministic) ✅ ALL ACTIONABLE DOCS COMPLETE
├─ D-11: Canon Workflow ✅ ← D-10 ✅
│  └─ D-12: Validation Rules ✅ ← D-10 ✅, D-11 ✅
│     └─ D-13: CLI Commands ✅ ← D-10 ✅, D-11 ✅, D-12 ✅
│
├─ D-14: LLM Integration ✅ ← D-01 ✅ [INDEPENDENT, COMPLETED IN PARALLEL]
│
└─ D-15: Integration Design ← D-10 ✅, D-02 ✅, TRACK B RESULTS [BLOCKED]

TRACK B: FRACTALRECALL PROTOTYPING (Phase 0/1, Empirical)
├─ D-20: Test Corpus ✅ ← D-02 ✅
│  └─ D-21: Notebook 1 (Baseline) ✅
│     └─ D-22: Notebook 2 (Single-Layer) ✅
│        └─ D-23: Notebook 3 (Multi-Layer) ← GO/NO-GO DECISION POINT
│           ├─ D-24: Notebook 4 (Ablation)    [CAN PARALLELIZE]
│           └─ D-25: Notebook 5 (Strategy)    [CAN PARALLELIZE]
│              └─ D-26: Notebook 6 (Cross-Domain)
│                 └─ D-27: Findings Document
│                    └─ D-28: Refined API Spec

PHASE 2+ (DEFERRED)
└─ D-40 through D-44: Implementation-phase docs
```

---

## Comprehensive Item Status Table

### All Deliverables (Sorted by Document Number)

| # | Document | Track | Status | Priority | Dependencies | Blocking | Est. Effort | Notes |
|---|----------|-------|--------|----------|------------|----------|------------|-------|
| D-01 | Unified Design Proposal | Both | ✅ DONE | High | None | None | 720 lines | Foundation: architecture, constraints, design decisions |
| D-02 | FractalRecall Conceptual Architecture | FR | ✅ DONE | High | None | D-20, D-23 | 930 lines | Technical specification for all notebooks |
| D-03 | Session Bootstrap Context | Both | ✅ DONE | High | None | None | 123 lines | Quick orientation document |
| D-04 | Master Execution Strategy | Both | ✅ DONE | High | D-01, D-02 | None | This doc | Operational playbook (source) |
| D-10 | Lore File Schema Specification | CHR | ✅ DONE | **CRITICAL** | D-01 | D-11, D-12, D-13, D-15 | ~1470 lines | Data model: 12 entity types (faction, character, entity, locale, event, timeline, system, axiom, item, document, term, meta), fields, validation constraints, JSON Schema, 13 examples |
| D-11 | Canon Workflow Specification | CHR | ✅ DONE | High | D-10 ✅ | D-12, D-13 | ~1250 lines | Content lifecycle: 4 states, 12 transitions, 3 ceremony tiers, 6 workflows, superseding mechanics, branch conventions, merge semantics, validation rules, changelog, 7 edge cases. All 7 design decisions (OQ-D11-1–7) incorporated. |
| D-12 | Validation Rule Catalog | CHR | ✅ DONE | High | D-10 ✅, D-11 ✅ | D-13 | ~2900 lines | 39 validation rules across 3 tiers, 3 assertion rule types, 6 design decisions. Verified against Master Strategy §6.3 and all design decisions. |
| D-13 | CLI Command Reference | CHR | ✅ DONE | Medium | D-10 ✅, D-11 ✅, D-12 ✅ | None | ~1670 lines | 12 commands across 3 phases, exit codes, output formats, configuration reference |
| D-14 | LLM Integration Specification | CHR | ✅ DONE | Medium | D-01 ✅ | None | ~1770 lines | 4 LLM features, prompt templates, response schemas, parsing, reports. OQ-5 resolved. |
| D-15 | Integration Design Document | Both | 🔴 BLOCKED | Low | D-10, D-02, Track B | None | ~300 lines | How Chronicle consumes FractalRecall (waits on D-23 go/no-go) |
| D-20 | Test Corpus Preparation | FR | ✅ DONE | High | D-02, D-10 ✅ | D-21 ✅ | ~530 lines | Corpus audit (67 files, 388K words), D-10 alignment analysis, field mapping strategy, 36 ground-truth queries across 5 types. Critical finding: corpus uses different field names than D-10 (mapping layer needed). |
| D-21 | Notebook 1: Model Selection & Embedding Baseline | FR | ✅ DONE | High | D-20 ✅ | D-22 | ~3300 lines | 22-cell notebook spec: 3-model comparison (v2-moe, v1.5, BGE-M3), Hybrid Semantic + Fixed-Window chunking, 36-query evaluation, weighted model selection decision matrix, UMAP visualization, ChromaDB persistence |
| D-22 | Notebook 2: Single-Layer Enrichment | FR | ✅ DONE | High | D-21 ✅ | D-23 | ~2900 lines | Single-layer enrichment prefix, delta analysis vs D-21 baseline, Wilcoxon significance test, parameterized model selection |
| D-23 | Notebook 3: Multi-Layer Enrichment | FR | ✅ DONE | **CRITICAL** | D-22 ✅ | D-24, D-25, D-27 | ~4470 lines | **GO/NO-GO POINT** — 8-layer enrichment, 3-way comparison, Bonferroni-corrected Wilcoxon, 7-criterion GO/NO-GO engine, layer token audit, marginal value analysis |
| D-24 | Notebook 4: Layer Ablation | FR | 🔵 NEXT | High | D-23 ✅ | D-27 | 1-2 days | Identify valuable layers (can parallelize with D-25) |
| D-25 | Notebook 5: Strategy Comparison | FR | 🔵 NEXT | High | D-23 ✅ | D-27 | 2-3 days | Prefix vs. Multi-Vector vs. Hybrid (can parallelize with D-24) |
| D-26 | Notebook 6: Cross-Domain Validation | FR | 🔵 BLOCKED | Medium | D-24, D-25 | D-27 | 2-3 days | Generalization test on non-worldbuilding corpus |
| D-27 | Prototyping Findings Document | FR | 🔵 BLOCKED | High | D-21–D-26 | D-28 | ~600 lines | Synthesis of all Colab results |
| D-28 | API Design Spec (Refined) | FR | 🔵 BLOCKED | High | D-27, D-02 | None | ~400 lines | Production API based on empirical validation |
| D-30 | Legacy Archive Notes | FR | ✅ DONE | Medium | D-02 | None | ~60 lines | Explains archived legacy conceptual work |
| D-31 | FractalRecall README (Replacement) | FR | ✅ DONE | Medium | D-02 | None | ~163 lines | Aligned with current .NET embedding library vision |
| D-32 | Colab Session Context Briefing | FR | ✅ DONE | High | D-02 | D-21–D-26 | ~230 lines | Gemini context for notebook debugging |
| D-33 | Notebook Context Cell Template | FR | ✅ DONE | High | D-32 | D-21–D-26 | ~50 lines | Self-documenting markdown cell pattern |
| D-40 | FractalRecall README (Full) | FR | ⏸️ DEFERRED | Low | D-28 | None | TBD | NuGet package README |
| D-41 | FractalRecall Contributing Guide | FR | ⏸️ DEFERRED | Low | D-28 | None | TBD | Setup, coding standards, PR process |
| D-42 | Chronicle README | CHR | ⏸️ DEFERRED | Low | D-10–D-13 | None | TBD | Repository README with quick-start |
| D-43 | Chronicle Contributing Guide | CHR | ⏸️ DEFERRED | Low | D-10–D-13 | None | TBD | Setup, coding standards, PR process |
| D-44 | Chronicle User Guide | CHR | ⏸️ DEFERRED | Low | Phase 2 impl | None | TBD | End-user documentation |

**Legend:** ✅ = Complete | 🔵 = In Progress / Next / Ready | 🔴 = Blocked | ⏸️ = Deferred

---

## Research Tasks (Pre/During/Post Prototyping)

### Must Complete Before Track B Starts — ✅ ALL COMPLETE

| ID | Topic | Status | Findings | Reference |
|----|-------|--------|----------|-----------|
| **R-01** | `nomic-embed-text-v2-moe` long-prefix behavior | ✅ DONE | **CRITICAL: 512-token context window, NOT 8,192.** MoE architecture (8 experts, top-2 routing), RoPE positional encoding, Matryoshka at 768/256 dims. Prefix enrichment must be radically compressed (~100 tokens) or model reconsidered. Recommend multi-model comparison in D-21. | R-01-02-03 §2 |
| **R-02** | Optimal chunking for worldbuilding Markdown | ✅ DONE | Hybrid Semantic + Fixed-Window recommended. Parameters: min 128, target 300-400 (v2-moe) or 500-700 (v1.5/BGE-M3), max 450/1024 tokens, 64-128 token overlap. Special handling for glossary entries, tables, narrative, YAML frontmatter. | R-01-02-03 §3 |
| **R-03** | ChromaDB metadata filtering capabilities | ✅ DONE | Scalar filters comprehensive ($eq, $ne, $gt, $in, $and, $or). **No native array metadata support** — requires JSON string serialization + post-query Python filtering for factions_mentioned, locations_mentioned, etc. Pre-query filtering is efficient. Pin to ChromaDB 1.x. | R-01-02-03 §4 |

**Consolidated findings document:** `chronicle/docs/R-01-02-03-research-findings.md` (2026-02-11)

### Can Occur During Prototyping

| ID | Topic | Purpose | Est. Effort | Informs |
|----|-------|---------|------------|----------|
| **R-04** | Contextual Retrieval follow-ups | Check community extensions since Oct 2024 | 2-3 hrs | D-22 methodology |
| **R-05** | Late Chunking + prefix enrichment interaction | Can they be combined? | 4-6 hrs | Future notebooks |
| **R-06** | Matryoshka dimension reduction for layers | Use reduced dimensions for structural filters | 3-4 hrs | D-25 refinement |

### Must Complete Before C# Implementation (Phase 2)

| ID | Topic | Purpose | Est. Effort | Blocks |
|----|-------|---------|------------|--------|
| **R-07** | `Microsoft.Extensions.AI.Abstractions` API | Deep-dive into `IEmbeddingGenerator` | 3-4 hrs | D-28 finalization |
| **R-08** | `Microsoft.Extensions.VectorData.Abstractions` | Evaluate wrapping vs. extending | 3-4 hrs | D-28 finalization |
| **R-09** | SQLite-vec .NET integration options | Workarounds for incomplete bindings | 4-6 hrs | Phase 2 backend selection |
| **R-10** | Semantic Kernel connector architecture | Should FractalRecall provide a connector? | 2-3 hrs | Phase 2 package structure |

---

## What to Do Right Now (Recommended Next Steps)

### Immediate (This Week)

**Priority 1: D-24 — Notebook 4: Layer Ablation Study** (conditionally depends on D-23 GO decision)

- **Start:** After D-23 Colab execution and GO/NO-GO decision.
- **What:** Systematically remove layers to measure individual contributions. Order layers by token cost and information value. Build "minimum viable layers" configuration.
- **Effort:** 1-2 days
- **Why:** Even with a GO from D-23, we need to know which layers matter most for the C# production implementation and token budget optimization.

**Also Next:** D-25 (Notebook 5: Embedding Strategy Comparison) — can be parallelized with D-24 since both depend only on D-23.

**Completed:**

- ✅ **D-13** — CLI Command Reference completed (~1670 lines, 12 commands across 3 phases)
- ✅ **D-14** — LLM Integration Specification completed (~1770 lines, 4 LLM features with full prompt templates)
- ✅ **R-01, R-02, R-03** — Pre-prototyping research complete. Critical 512-token finding documented. Master Strategy and Design Proposal amended. See `R-01-02-03-research-findings.md`.
- ✅ **D-20** — Test Corpus Preparation complete (~530 lines). 67-file corpus assessed, field mapping strategy defined, 36 ground-truth queries created. See `D-20-test-corpus-preparation.md`.
- ✅ **D-21** — Notebook 1: Model Selection & Embedding Baseline complete (~3300 lines + .ipynb). 3-model comparison, evaluation pipeline, model selection decision matrix. See `D-21-notebook1-baseline-spec.md` and `D21-baseline.ipynb`.
- ✅ **D-22** — Notebook 2: Single-Layer Enrichment complete (~2900 lines + .ipynb). Delta analysis vs D-21 baseline, Wilcoxon significance testing, parameterized model selection. See `D-22-notebook2-single-layer-spec.md` and `D22-single-layer.ipynb`.
- ✅ **D-23** — Notebook 3: Multi-Layer Enrichment — GO/NO-GO Decision Point complete (~4470 lines + .ipynb). 8-layer composite enrichment, 3-way comparison, Bonferroni-corrected Wilcoxon testing, 7-criterion GO/NO-GO engine, marginal value analysis, layer token audit. See `D-23-notebook3-multi-layer-spec.md` and `D23-multi-layer.ipynb`. **Awaiting Colab execution.**

### Next 2-3 Weeks

**Track B execution:**
- D-21, D-22, D-23 specs and notebooks complete. Execute D-21 → D-22 → D-23 in Colab sequentially.
- D-23 execution produces GO/NO-GO decision. Schedule decision review after D-23 Colab run completes.
- D-24 and D-25 spec work can proceed in parallel while awaiting Colab results.

**After D-23 Go/No-Go:**
- If GO: Continue D-24–D-26 (parallelizable), then D-27/D-28.
- If NO-GO: Reassess FractalRecall's scope (simplify to metadata filtering + Contextual Retrieval single-layer). Chronicle specs are complete regardless.

**After Track B Complete:**
- D-15 (Integration Design Document) — write after D-28 ✅ provides API spec and D-23 decision is known.
- Phase 2 kickoff: Have full spec suite and empirical validation in hand.

---

## Critical Milestones & Decision Points

### Milestone 1: Foundation Complete ✅

**Status:** ACHIEVED
**Date:** 2026-02-10
**Items:** D-01, D-02, D-03, D-04, D-30, D-31, D-32, D-33, D-10, D-11, D-12

**What it means:** All Phase 0 work complete plus D-10 (Lore Schema) and D-11 (Canon Workflow). Both projects have clear architecture, Chronicle has its data model and content lifecycle. Ready to proceed with validation rules and prototyping.

---

### Milestone 2: Track A Docs Sprint Complete ✅

**Status:** ACHIEVED
**Date:** 2026-02-10
**Items:** D-10 ✅, D-11 ✅, D-12 ✅, D-13 ✅, D-14 ✅
**Outcome:** Complete specification suite for Chronicle implementation (excluding D-15, which is blocked on Track B results)

**What it means:** Chronicle's data model (D-10), content lifecycle (D-11), validation rules (D-12), CLI interface (D-13), and LLM integration (D-14) are fully documented. Phase 2 implementation of all deterministic features can begin with zero ambiguity. Phase 4 LLM features have complete prompt templates and response specifications. Only D-15 (Integration Design) remains, blocked on Track B's go/no-go decision at D-23.

---

### Milestone 3: Track B Go/No-Go Decision (CRITICAL)

**Status:** In Progress
**Target:** ~10-14 days (mid-February 2026)
**Blocking:** D-23 execution and statistical analysis
**Question:** Does multi-layer enrichment significantly outperform single-layer?

**Outcomes:**
- **YES (GO):** FractalRecall proceeds as designed. Continue with D-24–D-28. Integration design (D-15) can be written with confidence.
- **NO (NO-GO):** FractalRecall scope simplifies to a thin wrapper over Contextual Retrieval with metadata filtering. Still valuable, just less novel. D-28 API spec reflects simpler architecture. Reassign resources accordingly.

**What it means:** This single notebook determines whether multi-layer enrichment is worth the additional complexity. Phase 0 specifically exists to fail fast and cheap in Python before betting C# implementation effort on this hypothesis.

---

### Milestone 4: Both Tracks Complete

**Status:** In Progress
**Target:** ~3-4 weeks (late February to early March 2026)
**Blocking:** D-13 (last Track A doc) + D-28 (last Track B doc)
**Outcome:** Full specification suite + empirical validation

**What it means:** Both projects have complete Phase 1 specs and Phase 0 prototyping is done. Phase 2 (C# implementation) can begin with high confidence. D-15 (Integration Design) can now be written since both specs are final.

---

### Milestone 5: Phase 2 Kickoff

**Status:** Pending
**Target:** Early March 2026
**Preconditions:** Milestones 2, 3, 4 complete; decision review meeting held
**Output:** Implementation begins (FractalRecall core library + Chronicle CLI)

**What it means:** Documentation and validation complete. Time to write production code.

---

## Technology Stack Summary

### Python / Google Colab Stack (Track B Prototyping)

| Component | Package | Version | Notes |
|-----------|---------|---------|-------|
| **Embeddings** | `sentence-transformers` | 5.2.2 | Use `encode_query()` / `encode_document()` for IR tasks |
| **Embedding Model** | `nomic-embed-text-v2-moe` | Latest | MoE (475M total, 305M active), multilingual, Matryoshka |
| **Vector DB** | `chromadb` | 1.5.0 | In-memory for prototyping, persistent for iteration |
| **Math/Stats** | `numpy`, `scikit-learn` | Latest | Cosine similarity, clustering, significance tests |
| **Visualization** | `matplotlib`, `seaborn` | Latest | Embedding space visualization, evaluation plots |
| **Environment** | Colab Pro or Kaggle | — | Colab Pro preferred (Ryan has subscription) |

### C# / .NET Stack (Track A + Phase 2)

| Component | Package | Version | Notes |
|-----------|---------|---------|-------|
| **Target Framework** | .NET | 10 (LTS) | Released Nov 2025, support through Nov 2028 |
| **YAML** | YamlDotNet | 16.3.0 | Note breaking changes from v15→v16 |
| **Markdown** | Markdig | 0.44.0 | CommonMark-compliant, stable |
| **CLI** | Spectre.Console.Cli | Latest | Modern opinionated framework |
| **Testing** | xUnit + FluentAssertions | Latest | Unit and integration tests |
| **Embedding Abstraction** | `Microsoft.Extensions.AI.Abstractions` | GA | Standard `IEmbeddingGenerator` interface |
| **Vector Abstraction** | `Microsoft.Extensions.VectorData.Abstractions` | GA | Standard vector CRUD + search |
| **Ollama Client** | OllamaSharp | 5.4.16 | Local embedding generation |
| **Qdrant Client** | `Semantic Kernel connector` | Latest | Production vector store alternative |

### Key Decisions

- **Embedding Model:** `nomic-embed-text-v2-moe` (upgraded from v1.x). MoE architecture is more efficient; multilingual; maintains Matryoshka support.
- **.NET Version:** Target .NET 10 LTS (not .NET 8). Current LTS with 3-year support window.
- **Ecosystem Alignment:** FractalRecall's `IEmbeddingProvider` should implement or wrap `Microsoft.Extensions.AI.Abstractions.IEmbeddingGenerator` for ecosystem compatibility.

---

## Risk Register

### High-Impact Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Multi-layer enrichment doesn't outperform single-layer (D-23 result) | Medium | High | Phase 0 designed to fail fast. If NO-GO, simplify scope. Still delivers value. |
| Scope creep across 8+ documents and 6+ notebooks | High | Medium | Strategy document enforces clear boundaries. Each item has defined "done" state. |
| Aethelgard corpus too small for meaningful evaluation | Low | Medium | Plan for 50+ documents minimum. Can supplement with synthetic or second domain. |
| `nomic-embed-text-v2-moe` handles long prefixed inputs poorly | Medium | Medium | Multiple fallback models available (mxbai, BGE-M3). Test during prototyping. |
| SQLite-vec .NET bindings remain incomplete | Medium | Low | Qdrant is mature alternative. Preference, not requirement. |

### Mitigation Strategies

1. **For "doesn't work" risk:** Phase 0 (Colab) exists specifically to catch showstoppers before C# investment. Embrace the possibility of pivoting; that's the point of prototyping.

2. **For scope creep:** Enforce discipline. When writing specs, don't prototype. When building notebooks, don't optimize. Each phase does one thing. Mixing phases is the primary creep source.

3. **For corpus size:** Establish 50-document minimum as hard floor. Plan synthetic content or second domain if Aethelgard is smaller than expected.

4. **For model performance:** R-01 research (pre-D-21) tests `nomic-embed-text-v2-moe` on long prefixed inputs. Identify issues early. Have fallbacks.

---

## Open Questions (Resolved During Execution)

| ID | Question | Resolved During | Expected Resolution |
|----|----------|-----------------|-------------------|
| OQ-1 | Multi-file entities (parent/child documents)? | D-10 (Schema Spec) | ✅ Resolved: parent/child with 2-level nesting, inheritance rules (§4.7) |
| OQ-2 | Custom entity types from day one? | D-10 (Schema Spec) | ✅ Resolved: Yes, via `.chronicle/schema/custom/` (§8) |
| OQ-3 | Fixed vs. free-form relationship types? | D-10 (Schema Spec) | ✅ Resolved: Recommended vocabulary (~30 types) with free-form allowed (§7.2–§7.3) |
| OQ-4 | Optimal chunking strategy for worldbuilding Markdown? | R-02 + D-21 | Pending |
| OQ-5 | Should Chronicle validate prose against frontmatter? | D-14 (LLM Spec) | ✅ Resolved: Yes, as part of `--deep` validation. Prose-vs-frontmatter consistency checking specified in D-14 §10. |
| OQ-6 | Migration path from Notion for Aethelgard? | D-20 (Corpus Prep) | Pending |
| FR-OQ-1 | Optimal layer ordering in embedded text? | D-23 (Notebook 3) | Pending |
| FR-OQ-2 | Natural language vs. structured tokens for relational layer? | D-23 (Notebook 3) | Pending |
| FR-OQ-3 | Versioned corpora — version as layer or within Corpus layer? | D-24 (Notebook 4) | Pending |
| FR-OQ-4 | Minimum corpus size threshold? | D-26 (Notebook 6) | Pending |
| FR-OQ-6 | Late Chunking + prefix enrichment interaction? | R-05 (optional research) | Pending |

---

## Document Manifest (Quick Reference)

### By Project

**Chronicle (Track A):**
D-01 ✅, D-03 ✅, D-04 ✅, D-10 ✅, D-11 ✅, D-12 ✅, D-13 ✅, D-14 ✅, D-15, D-42, D-43, D-44

**FractalRecall (Track B):**
D-02 ✅, D-20, D-21–D-28, D-30 ✅, D-31 ✅, D-32 ✅, D-33 ✅, D-40, D-41

**Both:**
D-01 ✅, D-03 ✅, D-04 ✅

### By Phase

**Phase 0 (Foundation):** D-01 ✅, D-02 ✅, D-03 ✅, D-04 ✅, D-30 ✅, D-31 ✅, D-32 ✅, D-33 ✅, D-10 ✅, D-11 ✅, D-12 ✅

**Phase 1 (Spec + Prototype):** D-13 ✅, D-14 ✅, D-15, D-20 ✅, D-21 ✅, D-22 ✅, D-23–D-28

**Phase 2 (Implementation):** D-42, D-43, D-44, D-40, D-41

**Phase 2+ (Deferred):** D-40, D-41, D-42, D-43, D-44

---

## Success Criteria

### Track A Success

- [x] D-11 (Canon Workflow) written and reviewed — ✅ v0.1.1-draft, ~1250 lines, all 7 design decisions incorporated, verified against Master Strategy §6.3
- [x] D-12 (Validation Rules) complete with 20+ rule specifications — ✅ v0.1.1-draft, ~2900 lines, 39 rules across 3 tiers, all 6 design decisions incorporated, verified against Master Strategy §6.3
- [x] D-13 (CLI Commands) covers all planned commands — ✅ v0.1.0-draft, ~1670 lines, 12 commands across 3 phases, verified against D-10/D-11/D-12/D-01
- [x] D-14 (LLM Integration) specifies all four LLM features — ✅ v0.1.0-draft, ~1770 lines, 4 features with complete prompt templates/schemas/parsing/reports, OQ-5 resolved, verified against Master Strategy §6.3
- [ ] No blockers on Phase 2 implementation; specs are unambiguous

### Track B Success

- [x] D-20 corpus contains 50+ documents with ground-truth queries — ✅ 67 documents, 36 queries
- [ ] D-21–D-26 notebooks all executed with reproducible results (D-21 spec complete; execution pending)
- [ ] D-23 (multi-layer hypothesis) reaches statistical significance (p < 0.05) — either GO or NO-GO
- [ ] D-27 (Findings) synthesizes all results with clear implications
- [ ] D-28 (API Spec) is production-ready based on empirical validation

### Integration Success

- [ ] D-15 (Integration Design) written after both tracks complete
- [ ] Phase 2 implementation team has unambiguous specs for both projects
- [ ] No scope creep; all items shipped within estimated effort

---

## Glossary

| Term | Definition |
|------|-----------|
| **Track A** | Chronicle documentation sprint — Phase 1 specification work |
| **Track B** | FractalRecall Colab prototyping — Phase 0 empirical validation |
| **Go/No-Go Point** | D-23 (Notebook 3) decision: multi-layer enrichment hypothesis validated? |
| **Composite Representation** | FractalRecall term: a single enriched text combining all context layers before embedding |
| **Context Layer** | One dimension of structural context (Corpus, Domain, Entity, Authority, Temporal, Relational, Section, Content) |
| **Contextual Retrieval** | Anthropic's technique: embedding enrichment with document-level metadata summaries |
| **Multi-Vector Composition** | Embedding strategy: separate vector per layer per chunk, linearly weighted at query time |
| **Prefix Enrichment** | Embedding strategy: prepend enrichment text to chunk before embedding (single vector) |
| **Hybrid Strategy** | Embedding strategy: selected layers embedded, rest as metadata filters |
| **Aethelgard** | Ryan's worldbuilding corpus; used as primary test dataset for FractalRecall |
| **Canon Status** | Chronicle field: true (canonical), false (draft), "apocryphal" (excluded from canonical queries), "deprecated" |
| **Lore File** | Chronicle terminology: a YAML+Markdown file defining a single entity (character, location, faction, etc.) |

---

## Contact & Governance

- **Owner:** Ryan (with strategic planning from Claude)
- **Derived From:** `Chronicle-FractalRecall-Master-Strategy.md`
- **Last Updated:** 2026-02-11
- **Next Review:** After D-23 (go/no-go decision) — recommend decision review meeting
- **Update Frequency:** Weekly during active execution; sync with Master Strategy

---

*This roadmap provides at-a-glance status for managing two parallel projects through Phase 1. Refer to the Master Execution Strategy for deeper context on each document and the overall vision.*
