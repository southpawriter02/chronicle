---
title: "D-21: Notebook 1 — Model Selection & Embedding Baseline"
document_id: "D-21"
version: "1.0"
status: "Complete"
date: "2026-02-11"
author: "Ryan + Claude (Cowork)"
depends_on: "D-20 (Test Corpus Preparation), R-01-02-03 (Research Findings), D-32 (COLAB-SESSION-CONTEXT.md), D-33 (NOTEBOOK-CONTEXT-CELL.md)"
blocks: "D-22 (Notebook 2: Single-Layer Enrichment)"
authority: "Chronicle-FractalRecall-Master-Strategy.md §7.4 (Notebook 1)"
---

# D-21: Notebook 1 — Model Selection & Embedding Baseline

**Purpose:** Specification and copy-paste-ready code for the first FractalRecall Colab/Kaggle notebook. This notebook establishes the **baseline retrieval performance** of standard RAG (no enrichment) across multiple embedding models, using the Aethelgard test corpus and D-20's 36 ground-truth queries.

**Deliverable Format:** This is a *specification document*, not the `.ipynb` file itself. Each section below corresponds to a notebook cell (either Markdown or Code). The notebook is assembled by copying each cell into Colab/Kaggle in sequence. This approach ensures the notebook design is documented, reviewed, and version-controlled before execution.

---

## Table of Contents

1. [Notebook Overview](#1-notebook-overview)
2. [Cell Map](#2-cell-map)
3. [Cell Specifications](#3-cell-specifications)
4. [Expected Outputs](#4-expected-outputs)
5. [Decision Criteria for Model Selection](#5-decision-criteria)
6. [Known Limitations and Workarounds](#6-known-limitations)
7. [Amendments to Upstream Documents](#7-amendments)
8. [Open Questions](#8-open-questions)
9. [Revision History](#9-revision-history)

---

## 1. Notebook Overview

### 1.1. Research Question

> How well does standard RAG (no context enrichment) perform on the Aethelgard corpus, and which embedding model should be the primary model for subsequent notebooks?

### 1.2. Scope

This notebook performs **three tasks** that the Master Strategy §7.4 originally described as one:

| Task | Description | Why |
|------|-------------|-----|
| **A. Baseline Measurement** | Embed all corpus chunks with no enrichment prefix, run 36 ground-truth queries, compute IR metrics | Establishes the floor that enrichment must beat |
| **B. Multi-Model Comparison** | Repeat Task A with 3 candidate models (v2-moe, v1.5, BGE-M3) | R-01's 512-token finding means we can't assume v2-moe is optimal |
| **C. Model Selection** | Compare metrics, select primary model, document rationale | Required before D-22 can proceed with a single model |

### 1.3. Inputs

| Input | Source | Description |
|-------|--------|-------------|
| Test corpus | `test-corpus/*.md` (67 files) | Aethelgard Markdown + YAML frontmatter |
| Ground-truth queries | D-20 §8 (Q-01 through Q-36) | 36 queries with expected results and 3-level relevance scores |
| Field mapping | D-20 §6 | Python dict mapping corpus fields to internal names |
| Chunking strategy | R-02 (in R-01-02-03) | Hybrid Semantic + Fixed-Window with model-specific parameters |
| ChromaDB patterns | R-03 (in R-01-02-03) | Metadata serialization, filter syntax |
| Notebook template | D-33 (NOTEBOOK-CONTEXT-CELL.md) | First markdown cell template |
| Session context | D-32 (COLAB-SESSION-CONTEXT.md) | AI assistant briefing document |

### 1.4. Outputs

| Output | Format | Used By |
|--------|--------|---------|
| Baseline metrics per model | Table (Precision@5, Recall@10, NDCG@10, MRR per query type) | D-22, D-27 |
| Model selection decision | Documented rationale with data | D-22 through D-26 |
| Per-query-type performance breakdown | Bar charts + heatmap | D-27 (Findings Document) |
| Embedding space visualization | 2D UMAP plot per model | D-27 |
| ChromaDB collection (persisted) | ChromaDB persistent storage | D-22 (inherits baseline collection) |
| Chunk inventory | CSV export | D-22 (same chunks, different enrichment) |

### 1.5. Notebook Structure (8 Sections per Master Strategy §7.4)

```
1. Objective          → Markdown cell: what question we're answering
2. Setup              → Code cells: imports, model loading, corpus loading
3. Methodology        → Markdown cell: what we're doing and why
4. Implementation     → Code cells: chunking, embedding, indexing, querying
5. Results            → Code cells: metrics computation, tables
6. Analysis           → Markdown + code cells: visualizations, interpretation
7. C# Implications    → Markdown cell: what this means for production design
8. Next Steps         → Markdown cell: what D-22 should explore
```

---

## 2. Cell Map

Each row is one notebook cell. Markdown cells contain documentation; Code cells contain executable Python.

| Cell # | Type | Section | Title | Est. Lines |
|--------|------|---------|-------|-----------|
| 01 | Markdown | 1-Objective | Notebook header + context (from D-33 template) | 40 |
| 02 | Code | 2-Setup | Install dependencies | 8 |
| 03 | Code | 2-Setup | Imports and configuration constants | 45 |
| 04 | Code | 2-Setup | Ground-truth query set definition | 180 |
| 05 | Code | 2-Setup | Field mapping and normalization functions | 65 |
| 06 | Code | 2-Setup | Corpus loading pipeline | 50 |
| 07 | Markdown | 3-Methodology | Methodology explanation | 30 |
| 08 | Code | 4-Implementation | Hybrid chunking engine | 95 |
| 09 | Code | 4-Implementation | Chunk corpus (all models) | 40 |
| 10 | Code | 4-Implementation | Embedding + ChromaDB indexing (per model) | 70 |
| 11 | Code | 4-Implementation | Query execution engine | 55 |
| 12 | Code | 4-Implementation | Run all queries (per model) | 25 |
| 13 | Markdown | 5-Results | Results introduction | 10 |
| 14 | Code | 5-Results | Metric computation functions | 80 |
| 15 | Code | 5-Results | Compute and display results tables | 45 |
| 16 | Markdown | 6-Analysis | Analysis introduction | 10 |
| 17 | Code | 6-Analysis | Per-query-type performance breakdown (bar charts) | 50 |
| 18 | Code | 6-Analysis | Model comparison heatmap | 40 |
| 19 | Code | 6-Analysis | Embedding space visualization (UMAP) | 50 |
| 20 | Code | 6-Analysis | Export results to CSV and persist ChromaDB | 30 |
| 21 | Markdown | 7-C# Implications | Implications for C# design | 25 |
| 22 | Markdown | 8-Next Steps | What D-22 should explore | 15 |
| — | — | — | **Total** | **~1,060** |

<!-- Section 3 continues in subsequent cells below -->
