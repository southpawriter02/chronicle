# Session Handoff: Chronicle + FractalRecall + Haiku Protocol Initiative

**Date:** 2026-02-16
**Purpose:** Ramp up a new AI session on current project status, in-progress work, and immediate next steps.
**Owner:** Ryan (southpawriter02)

---

## 1. What This Initiative Is (30-Second Version)

Three concurrent open-source C#/.NET projects, currently in the documentation-and-prototyping phase (no production C# code yet):

- **Chronicle** — A CLI tool that treats worldbuilding lore like a software codebase. Git-based version control with domain intelligence: YAML frontmatter validation, canon workflows, cross-reference integrity, semantic search, LLM-powered advisory features. First target: Ryan's Aethelgard worldbuilding corpus (~2,225 files).
- **FractalRecall** — A .NET class library (future NuGet package) that improves embedding-based retrieval by encoding hierarchical structural context into embeddings. Domain-agnostic; Chronicle is the first consumer. Core hypothesis: multi-layer context enrichment significantly improves retrieval quality over standard RAG.
- **Haiku Protocol** — A semantic compression system using a Controlled Natural Language (CNL) of typed operators. Originally designed for procedural documentation; now being extended to worldbuilding content as a "density layer" for FractalRecall's enrichment pipeline.

**Key architectural principle:** These are separate repos (`southpawriter02/chronicle`, `southpawriter02/fractalrecall`, `southpawriter02/haiku-protocol`) plus a standalone worldbuilding corpus (`southpawriter02/aethelgard`, private). Chronicle depends on FractalRecall as a package reference. FractalRecall is domain-agnostic. Haiku Protocol's compressed output serves as a token-efficient enrichment prefix for FractalRecall.

---

## 2. Repository Map

| Repo | GitHub | Purpose | Key Contents |
|------|--------|---------|-------------|
| `chronicle` | `southpawriter02/chronicle` | Coordination hub, Chronicle specs | `docs/` (D-10 through D-23 specs, roadmap, research), `docs/strategy/` (cross-cutting strategy docs, session bootstraps), `docs/assessments/` (integration assessments), `scripts/` (project setup, issue filing) |
| `fractalrecall` | `southpawriter02/fractalrecall` | FractalRecall specs + Colab notebooks | `notebooks/` (D21/D22/D23 .ipynb files, test-corpus, results), `docs/` |
| `haiku-protocol` | `southpawriter02/haiku-protocol` | Haiku Protocol CNL design | `docs/design/phase-0/` (v0.0.0 through v0.0.3 operator specs) |
| `aethelgard` | `southpawriter02/aethelgard` (PRIVATE) | Worldbuilding corpus | 2,225 files — lore, design, factions, characters, etc. |

**GitHub Project Board:** "Chronicle Initiative" under `southpawriter02`, spanning all three public repos. Created via `scripts/setup-github-project.sh`. Custom fields: Status, Priority (P0-P3), Size (XS-XL), Type, Track (A/B/C/Cross-Cutting), Milestone, Document ID.

---

## 3. Three-Track Execution Model

### Track A — Chronicle Documentation (COMPLETE)

All deterministic Chronicle specs are done. Five documents totaling ~9,000+ lines:

| Doc | Title | Lines | Status |
|-----|-------|-------|--------|
| D-10 | Lore File Schema Specification | ~1,470 | ✅ Complete (v0.2.1) |
| D-11 | Canon Workflow Specification | ~1,250 | ✅ Complete (v0.1.1-draft) |
| D-12 | Validation Rule Catalog | ~2,900 | ✅ Complete (v0.1.1-draft) |
| D-13 | CLI Command Reference | ~1,670 | ✅ Complete (v0.1.0-draft) |
| D-14 | LLM Integration Specification | ~1,770 | ✅ Complete (v0.1.0-draft) |
| D-15 | Integration Design Document | TBD | 🔴 BLOCKED on Track B results |

### Track B — FractalRecall Colab Prototyping (IN PROGRESS)

Sequential notebook chain validating multi-layer enrichment hypothesis:

| Doc | Notebook | Status | Key Finding |
|-----|----------|--------|-------------|
| D-20 | Test Corpus Preparation | ✅ Complete | 67-file corpus, 36 ground-truth queries, field mapping |
| **D-21** | **Notebook 1: Baseline** | **✅ EXECUTED** | **See §4 below — real results obtained** |
| **D-22** | **Notebook 2: Single-Layer** | **🔄 CURRENTLY RUNNING ON COLAB** | **Audited & fixed (11 issues); executing now** |
| **D-23** | **Notebook 3: Multi-Layer (GO/NO-GO)** | **📋 Spec complete, awaiting D-22 results** | **Must be updated with D-22 findings before execution** |
| D-24 | Notebook 4: Layer Ablation | 🔵 Next (spec not started) | Depends on D-23 GO |
| D-25 | Notebook 5: Strategy Comparison | 🔵 Next (spec not started) | Can parallelize with D-24 |
| D-26 | Notebook 6: Cross-Domain Validation | Blocked on D-24/D-25 | |
| D-27 | Prototyping Findings Document | Blocked on all notebooks | |
| D-28 | API Design Spec (Refined) | Blocked on D-27 | |

### Track C — Haiku Protocol Integration (STARTED)

| Doc | Title | Lines | Status |
|-----|-------|-------|--------|
| D-16 | Worldbuilding Grammar Profile Spec | ~1,348 | ✅ Complete (v0.1.1-draft, reader-tested) |
| D-15 | Integration Design Document | TBD | 🔴 BLOCKED on Track B |

D-16 defines 5 new worldbuilding operators (ENTITY, RELATION, TEMPORAL, CANON, DESC) plus 7 adapted procedural operators. It includes a fully worked compression example of The Forsaken faction entry (~9:1 ratio) and maps all operators to FractalRecall's 8 context layers.

**5 open questions from D-16** are ready to be filed as GitHub issues. Script prepared at `chronicle/scripts/file-d16-issues.sh` — run it locally where `gh` is installed.

---

## 4. D-21 Results (CRITICAL — Real Empirical Data)

D-21 was executed on 2026-02-15 on Google Colab (A100 GPU, High-RAM). Results are in `fractalrecall/notebooks/results/D21-findings.md` and `D21_baseline.ipynb`.

### Corpus
- **77 Markdown documents** from Aethelgard (expanded from D-20's original 67-file audit)
- Three document prefix types: `000-codex_`, `db02-wb_`, `db03-dc_`

### Chunking
- Hybrid Semantic + Fixed-Window per R-02 spec
- v2-moe: 1,257 chunks (avg 134 tokens); v1.5/bge-m3: 1,215 chunks (avg 136 tokens)

### Model Comparison (Mean Across 36 Queries)

| Model | Precision@5 | Recall@10 | NDCG@10 | MRR |
|-------|------------|-----------|---------|-----|
| nomic-embed-text-v2-moe | **0.4611** | 0.7083 | 0.6834 | 0.8166 |
| BAAI/bge-m3 | 0.4171 | **0.7454** | 0.6973 | 0.7917 |
| nomic-embed-text-v1.5 | 0.3894 | 0.7384 | **0.7315** | **0.8611** |

### Model Selection Decision
**nomic-embed-text-v1.5 selected as primary model for D-22+** because:
- Best ranking quality (NDCG@10, MRR) — enrichment should amplify this
- 8,192-token context window — room for multi-layer prefixes without truncation
- Competitive recall (0.7384)
- Strongest on EXPLORATORY queries (the primary enrichment target — Precision@5 ≈ 0.25, massive headroom)

### Key Patterns
- **MULTI_HOP** queries performed best across all models (MRR = 1.000 for all three)
- **EXPLORATORY** queries are the weakest (Precision@5 ≈ 0.25) — primary target for enrichment
- **TEMPORAL** queries revealed v2-moe's 512-token limitation (Recall@10 drops to 0.750 vs 0.917)
- Minimum chunk size filter needed (2-token chunks provide no signal)

---

## 5. D-22 Status (CURRENTLY RUNNING ON COLAB)

### What D-22 Tests
Single-layer enrichment: adds a document-level context prefix to each chunk before embedding:
```
"This is a {type} document about {name}. Canon status: {canon}."
```

### Audit & Fixes Applied
Before execution, a cell-by-cell audit found **11 alignment issues** between D-22 and D-21 (see `fractalrecall/notebooks/D22-audit-and-fixes.md`):
- 4 critical (runtime crashes: wrong glob pattern, wrong paths, missing import)
- 5 major (incorrect results: query taxonomy mismatch, wrong model loader, CSV column mismatch)
- 2 minor (structural: duplicate query definitions, ModelConfig field drift)

All 11 issues were resolved via `fix_d22.py` and `fix_d22_phase2.py`. The fixed notebook is `fractalrecall/notebooks/D22-single-layer.ipynb`.

### What to Do When D-22 Results Come In

**This is the most important section of this handoff.** When Ryan has D-22 results:

1. **Document the results immediately.** Create `fractalrecall/notebooks/results/D22-findings.md` following the same format as `D21-findings.md`. Include:
   - Overall metrics table (Precision@5, Recall@10, NDCG@10, MRR)
   - Per-query-type breakdown
   - Delta analysis vs D-21 baseline (per-metric, per-query-type)
   - Wilcoxon signed-rank test results (p-values for each metric)
   - Which query types improved most / least
   - Any unexpected degradations

2. **Save the executed notebook.** Copy the executed `.ipynb` (with all outputs) to `fractalrecall/notebooks/results/D22_single_layer.ipynb`.

3. **Save the CSV artifacts.** D-22 produces:
   - `d22_results.csv` — per-query metrics
   - `d22_delta.csv` — per-query deltas vs D-21
   Copy these to `fractalrecall/notebooks/results/` or ensure they're in the D-22 output directory.

4. **Update D-23 accordingly.** D-23's notebook (`D23-multi-layer.ipynb`) needs to:
   - Reference D-22's actual results CSV path (currently a placeholder)
   - Use D-22's confirmed `SELECTED_MODEL` value (expected: `v1.5`)
   - Be audited for the same 11 alignment issues that affected D-22 — apply equivalent fixes
   - Verify the 3-way comparison logic (D-23 vs D-22 vs D-21) works with real CSV data

5. **Assess D-22 success criteria before proceeding to D-23:**
   - Mean metric delta positive? (D-22 > D-21)
   - Wilcoxon p < 0.05 for at least one metric?
   - Fewer than 50% of queries degraded?
   - If D-22 shows no improvement at all, that's important context for whether D-23 is worth running.

---

## 6. D-23 Preparation Checklist

D-23 is the **GO/NO-GO decision point** for the entire FractalRecall multi-layer hypothesis. Before executing it:

### Pre-Execution Audit (CRITICAL)
D-22 had 11 alignment bugs. **D-23 almost certainly has similar issues.** Before running D-23 on Colab, perform a cell-by-cell audit checking:

- [ ] Import ordering (all imports in Cell 2, no late imports)
- [ ] Corpus glob pattern uses `*.md` not `*.yaml`
- [ ] `CORPUS_DIR`, `OUTPUT_DIR`, `D21_RESULTS_PATH`, `D22_RESULTS_PATH` point to correct relative paths
- [ ] Query set matches D-21's exact 36 queries with 5-type taxonomy
- [ ] `relevant_docs` reference `.md` filenames
- [ ] Model loading is conditional (SentenceTransformer vs BGEM3FlagModel)
- [ ] D-21 and D-22 CSV column names match what the comparison code expects
- [ ] All comparison loops iterate over all 5 query types
- [ ] Bonferroni correction uses α/3 ≈ 0.0167 (3 pairwise comparisons)
- [ ] GO/NO-GO engine references correct column names from CSV

### Post-Execution Documentation
Same as D-22: create `D23-findings.md`, save executed notebook, save CSVs, document the GO/NO-GO decision with full rationale.

### The 7 GO/NO-GO Criteria (from D-23 spec §1)
D-23's programmatic evaluation checks:
1. Multi-layer (D-23) significantly outperforms baseline (D-21) on NDCG@10
2. Multi-layer significantly outperforms single-layer (D-22) on NDCG@10
3. Multi-layer achieves highest mean MRR
4. Multi-layer shows improvement on majority of query types
5. Effect size (rank-biserial) is at least "small" (≥ 0.1)
6. No catastrophic degradation on any query type
7. Token overhead is sustainable (enrichment prefix < 30% of context window)

**GO** requires 5 of 7 criteria met. **NO-GO** if fewer than 3 met. **CONDITIONAL GO** if 3-4 met.

---

## 7. Docs-First Mandate

Ryan follows a strict docs-first methodology. **Every result, decision, and finding must be documented before moving on.** This applies especially to notebook execution:

- **Never skip the findings document.** Every executed notebook gets a `D{XX}-findings.md` in `fractalrecall/notebooks/results/`.
- **Preserve executed notebooks.** The `.ipynb` with outputs is a permanent research artifact, not throwaway work.
- **Update upstream documents.** When D-22 results are known, check whether `ROADMAP-STATUS.md` needs updating. When D-23 decides GO/NO-GO, that status change propagates to the roadmap, Master Strategy, and dependency graph.
- **Document decisions, not just results.** If D-22 shows unexpected patterns (e.g., enrichment hurts AUTHORITY queries), document the observation, hypothesize why, and note implications for D-23.

---

## 8. File Locations Quick Reference

### Chronicle Repo (`chronicle/`)
```
docs/
├── D-10-lore-file-schema-spec.md          # Data model (12 entity types)
├── D-11-canon-workflow-spec.md            # Content lifecycle state machine
├── D-12-validation-rule-catalog.md        # 39 validation rules
├── D-13-cli-command-reference.md          # 12 CLI commands
├── D-14-llm-integration-spec.md           # 4 LLM features
├── D-16-worldbuilding-grammar-profile-spec.md  # Worldbuilding grammar (Track C)
├── D-20-test-corpus-preparation.md        # Corpus audit + 36 queries
├── D-21-notebook1-baseline-spec.md        # Notebook 1 spec (~3,300 lines)
├── D-22-notebook2-single-layer-spec.md    # Notebook 2 spec (~2,900 lines)
├── D-23-notebook3-multi-layer-spec.md     # Notebook 3 spec (~4,470 lines)
├── R-01-02-03-research-findings.md        # Pre-prototyping research
├── ROADMAP-STATUS.md                      # At-a-glance project status
├── COLAB-EXECUTION-GUIDE.md               # How to run notebooks
├── strategy/
│   ├── Chronicle-FractalRecall-Design-Proposal.md
│   ├── Chronicle-FractalRecall-Master-Strategy.md
│   └── Chronicle-FractalRecall-Session-Bootstrap.md
├── assessments/
│   └── Haiku-Protocol-Integration-Assessment.docx
scripts/
├── setup-github-project.sh                # GitHub Project V2 board setup
├── SETUP-GUIDE.md                         # Companion guide
└── file-d16-issues.sh                     # Files 5 D-16 open question issues
```

### FractalRecall Repo (`fractalrecall/`)
```
notebooks/
├── D21-baseline.ipynb                     # Notebook 1 (template)
├── D22-single-layer.ipynb                 # Notebook 2 (fixed, currently running)
├── D23-multi-layer.ipynb                  # Notebook 3 (needs audit before run)
├── D22-audit-and-fixes.md                 # D-22 bug audit documentation
├── fix_d22.py                             # Fix script (safe to delete post-verify)
├── fix_d22_phase2.py                      # Fix script phase 2
├── COLAB-SESSION-CONTEXT.md               # Gemini context briefing
├── NOTEBOOK-CONTEXT-CELL.md               # Cell template
├── test-corpus/                           # 77 Aethelgard MD files
├── results/
│   ├── D21-findings.md                    # ★ D-21 empirical results
│   └── D21_baseline.ipynb                 # Executed notebook with outputs
```

### Haiku Protocol Repo (`haiku-protocol/`)
```
docs/design/phase-0/
├── v0.0.0-OVERVIEW.md                     # Phase 0 overview
├── v0.0.1/                                # Initial design
├── v0.0.2/                                # Operator design (12 procedural operators)
│   └── v0.0.2b-operator_design_and_syntax_definition.md  # 937 lines
├── v0.0.3/                                # (latest)
```

---

## 9. Immediate Action Items (Priority Order)

1. **🔴 When D-22 finishes:** Document results in `D22-findings.md`, save artifacts, assess success criteria (see §5 above)
2. **🔴 Audit D-23 notebook** for the same 11 classes of bugs found in D-22 (see §6 checklist)
3. **🟡 Update D-23 with D-22 results** — ensure CSV paths, model selection, and comparison logic reflect actual D-22 output
4. **🟡 Execute D-23 on Colab** — this is the GO/NO-GO decision. Document everything.
5. **🟢 File D-16 issues** — run `chronicle/scripts/file-d16-issues.sh` locally (5 open questions: OQ-D16-1 through OQ-D16-5)
6. **🟢 Update ROADMAP-STATUS.md** — add D-16 to document manifest, update D-21 status to "EXECUTED," note D-22 status

---

## 10. Technology Context

### Python / Colab Stack (Track B)
- `sentence-transformers` 5.2.2 — embedding model loader
- `nomic-embed-text-v1.5` — **selected model** (8,192 token window, 768 dims)
- `chromadb` 1.5.0 — vector DB (in-memory for prototyping)
- `FlagEmbedding` — required only if switching to bge-m3
- Colab Pro with A100 GPU, High-RAM

### C# / .NET Stack (Future Phase 2)
- .NET 10 LTS, YamlDotNet 16.3.0, Markdig 0.44.0, Spectre.Console.Cli
- `Microsoft.Extensions.AI.Abstractions` + `Microsoft.Extensions.VectorData.Abstractions`
- OllamaSharp 5.4.16 for local embedding generation

### Critical Finding from R-01
`nomic-embed-text-v2-moe` has a **512-token context window**, not 8,192 as originally assumed. This is why v1.5 (8,192 tokens) was selected — it has room for multi-layer enrichment prefixes. All enrichment prefix budgets are designed around this constraint.

---

## 11. Ryan's Preferences & Working Style

- Docs-first mentality — check for existing specs before implementing anything
- Prefers C# and Markdown; uses Python only for Colab prototyping
- Values extensive documentation: inline comments, PRDs, design specs, user stories, unit tests
- Technical user but not a programmer by nature — explain code and terminology
- Don't invent features that aren't documented; point out missing documentation instead
- Uses Mac Studio M3 Ultra (512GB RAM) for local LLM inference
- Active job hunter — these repos serve as portfolio projects

---

## 12. Key Documents to Read First

If you're a new AI session picking this up, read these in order:

1. **This document** (you're here)
2. **`chronicle/docs/ROADMAP-STATUS.md`** — comprehensive status of every deliverable
3. **`fractalrecall/notebooks/results/D21-findings.md`** — actual empirical results
4. **`fractalrecall/notebooks/D22-audit-and-fixes.md`** — what went wrong with D-22 and how it was fixed (critical context for D-23 audit)
5. **`chronicle/docs/D-23-notebook3-multi-layer-spec.md`** §1 — GO/NO-GO criteria

For deeper context on any specific area:
- Architecture: `chronicle/docs/strategy/Chronicle-FractalRecall-Design-Proposal.md`
- Full roadmap: `chronicle/docs/strategy/Chronicle-FractalRecall-Master-Strategy.md`
- Haiku Protocol integration: `chronicle/docs/D-16-worldbuilding-grammar-profile-spec.md`
- Procedural grammar: `haiku-protocol/docs/design/phase-0/v0.0.2/v0.0.2b-operator_design_and_syntax_definition.md`

---

*This handoff was generated on 2026-02-16. The most time-sensitive item is documenting D-22 results when they arrive and auditing D-23 before execution.*
