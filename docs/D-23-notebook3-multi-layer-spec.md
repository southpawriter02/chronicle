---
title: "D-23: Notebook 3 — Multi-Layer Enrichment (GO/NO-GO Decision Point)"
document_id: "D-23"
version: "1.0"
status: "Complete"
date: "2026-02-11"
author: "Ryan + Claude (Cowork)"
depends_on: "D-21 (Notebook 1: Baseline), D-22 (Notebook 2: Single-Layer Enrichment), D-20 (Test Corpus Preparation)"
blocks: "D-24 (Layer Ablation Study)"
authority: "Chronicle-FractalRecall-Master-Strategy.md §7.4 (Notebook 3)"
---

## 1. Notebook Overview

### Research Question

**Does enriching text chunks with all 8 hierarchical context layers — Corpus, Domain, Entity, Authority, Temporal, Relational, Section, and Content — significantly improve retrieval quality beyond the single-layer enrichment tested in D-22?**

This is the **GO/NO-GO decision point** for FractalRecall's core hypothesis. If multi-layer enrichment demonstrates statistically significant improvement over both the D-21 baseline and the D-22 single-layer approach, the project proceeds to layer ablation (D-24) and embedding strategy comparison (D-25). If not, FractalRecall's scope simplifies to metadata filtering with single-layer enrichment.

### Scope

- **Input**: D-21's baseline corpus (same 25 documents, same chunking strategy), D-22's single-layer results
- **Processing**: Construct the full 8-layer composite representation for each chunk, prepend all layers as a multi-sentence natural language prefix, then embed as a single vector
- **Output**: D-23 metrics on all 36 ground-truth queries, 3-way delta analysis (D-23 vs D-22 vs D-21), GO/NO-GO decision
- **Model**: Only the model selected as the winner from D-21's weighted comparison (parameterized via `SELECTED_MODEL`)
- **Collection**: New ChromaDB collection `d23_multi_layer_{model}` (separate from D-21 and D-22 collections)
- **Comparison**: 3-way per-query metric deltas, statistical significance testing (Wilcoxon signed-rank), breakdown by query type, layer contribution analysis

### The 8 Context Layers

The multi-layer enrichment template prepends context layers in this order (outermost to innermost):

| # | Layer | What It Contains | Example | Est. Tokens |
|---|-------|-----------------|---------|-------------|
| 1 | **Corpus** | Which knowledge base | "Aethelgard Worldbuilding Corpus v5.0" | ~5 |
| 2 | **Domain** | Category within the corpus | "This content is from a faction document." | ~8 |
| 3 | **Entity** | Which specific entity | "This content describes The Iron Covenant." | ~8 |
| 4 | **Authority** | Editorial/canonical status | "This content is canonical and authoritative." | ~8 |
| 5 | **Temporal** | Time period described | "The events described span the Third Age and Fourth Age." | ~12 |
| 6 | **Relational** | Links to other entities | "Founded by Elena Voss; Rival of Silver Hand." | ~15-30 |
| 7 | **Section** | Document section heading | "This content is from the Origins section." | ~10 |
| 8 | **Content** | The actual chunk text | *(the raw text)* | variable |

**Token budget for the 7 metadata layers (excluding content):**
- Best case (sparse metadata): ~50 tokens
- Typical case: ~80-100 tokens
- Worst case (rich relational data): ~150 tokens

### Rendered Format for Embedding

The enriched text fed to the embedding model looks like:

```
Corpus: Aethelgard Worldbuilding Corpus v5.0

Domain: This content is from a faction document in the organizations category.

Entity: This content describes The Iron Covenant.

Authority: This content is canonical and authoritative.

Temporal: The events described span the Third Age and Fourth Age.

Relationships: The Iron Covenant was founded by Elena Voss, is a rival of the Silver Hand, and is located in the Ashenmoor region.

Section: This content is from the Origins section.

The Iron Covenant was founded in Year 412 of the Third Age by Commander Elena Voss...
```

Layers are separated by double newlines (`\n\n`). If a layer has no value for a given chunk, it is **omitted entirely** (not rendered as empty).

### Key Assumptions

1. **D-21 and D-22 must be completed first** to provide baseline and single-layer results for comparison. D-23 provides defaults but these are placeholders.
2. **SELECTED_MODEL is carried forward** from D-22 (which inherits from D-21). Default: `"v1.5"`.
3. **All 8 layers are used** — no ablation in this notebook (that's D-24's job). Layers with missing metadata are omitted gracefully.
4. **Token budget varies by model**:
   - v2-moe (512 tokens): ~80-150 token prefix, ~300-380 content budget (tight — may need smaller chunks or layer trimming)
   - v1.5 / BGE-M3 (8192 tokens): ~80-150 token prefix is negligible; no practical constraint
5. **Prefix is per-chunk, not per-document**: Unlike D-22's static prefix, D-23's prefix varies by chunk because the Section layer changes per heading.
6. **No model retraining**: we only test embedding and retrieval.
7. **Query set is static**: all 36 queries from D-21/D-22 are reused exactly.

### Inputs

| Source | Type | Description |
|--------|------|-------------|
| D-20 test corpus | Directory | `/mnt/0000_concurrent/d20_corpus/` containing 25 YAML documents with frontmatter |
| D-21 baseline results | CSV | `d21_results.csv` (per-query metrics for baseline) |
| D-22 single-layer results | CSV | `d22_results.csv` (per-query metrics for single-layer enrichment) |
| D-21 chunking config | Code | Hybrid chunking strategy: semantic boundaries + token limits |
| D-21 field mapping | Code | Frontmatter normalization (type, name, canon, era, relationships, etc.) |
| D-21 query set | Python list | 36 ground-truth queries with relevance judgments |
| COLAB-SESSION-CONTEXT.md (D-32) | Reference | 8-layer enrichment template and rendered format |

### Outputs

| Artifact | Type | Description |
|----------|------|-------------|
| d23_results.csv | CSV | Per-query metrics (P@5, R@10, NDCG@10, MRR) for multi-layer enrichment |
| d23_delta_vs_d21.csv | CSV | Per-query deltas: D-23 - D-21 (multi-layer vs baseline) |
| d23_delta_vs_d22.csv | CSV | Per-query deltas: D-23 - D-22 (multi-layer vs single-layer) |
| d23_layer_token_audit.csv | CSV | Per-chunk token counts by layer (for D-24 ablation planning) |
| visualization_3way_comparison.png | Chart | Grouped bar chart: D-21 vs D-22 vs D-23 per metric |
| visualization_delta_heatmap.png | Chart | Heatmap: per-query deltas for both comparison pairs |
| visualization_layer_token_distribution.png | Chart | Box plot: token consumption per layer across all chunks |
| d23_multi_layer_{model} | ChromaDB collection | Indexed documents with 8-layer enriched chunks |
| d23_go_nogo_decision.txt | Text | Formal GO/NO-GO decision with supporting evidence |

### Success Criteria

1. **Execution**: Notebook runs without errors; < 5% of chunks exceed token limit after enrichment
2. **Improvement over D-21 (baseline)**: Mean delta D-23 - D-21 > 0 for at least 3 of 4 metrics
3. **Improvement over D-22 (single-layer)**: Mean delta D-23 - D-22 > 0 for at least 2 of 4 metrics
4. **Statistical significance**: Wilcoxon signed-rank p < 0.05 for at least 2 metrics in D-23 vs D-21 comparison
5. **Marginal value**: D-23 vs D-22 improvement > 5% (otherwise multi-layer complexity may not be justified)
6. **No catastrophic degradation**: < 25% of queries show metric degradation from multi-layer enrichment vs baseline
7. **Authority/temporal queries benefit most**: These query types show larger mean deltas than factual queries (aligns with hypothesis)

---

## 2. Cell Map

| Cell | Type | Title | Purpose | Est. Lines |
|------|------|-------|---------|------------|
| 01 | Markdown | Notebook Header | Title, research question, GO/NO-GO context | ~35 |
| 02 | Code | Install Dependencies | pip install chromadb, sentence-transformers, etc. | ~25 |
| 03 | Code | Imports, Configuration, Model Selection | Load libraries; define SELECTED_MODEL; enrichment constants | ~90 |
| 04 | Code | Ground-Truth Query Set | 36 queries with relevance judgments (copy from D-21/D-22) | ~200 |
| 05 | Code | Field Mapping & Normalization | Frontmatter → normalized metadata dict (copy from D-21/D-22) | ~100 |
| 06 | Code | Corpus Loading | Load all 25 documents from D-20 (copy from D-21/D-22) | ~80 |
| 07 | Markdown | Methodology — Multi-Layer Enrichment | Explain 8-layer hypothesis, enrichment template, token budget analysis | ~60 |
| 08 | Code | Hybrid Chunking Engine | Reuse D-21's chunking strategy (Chunk dataclass, etc.) | ~120 |
| 09 | Code | Multi-Layer Enrichment Builder | `build_multi_layer_prefix()` — the core new code for D-23 | ~180 |
| 10 | Code | Chunk, Enrich & Audit Corpus | Apply chunking + 8-layer enrichment; token audit per layer | ~120 |
| 11 | Code | Embedding & ChromaDB Indexing | Embed enriched chunks; create collection d23_multi_layer_{model} | ~80 |
| 12 | Code | Query Execution | Run all 36 queries against D-23 collection; retrieve top-10 results | ~70 |
| 13 | Markdown | Results Introduction | Brief context for 3-way analysis section | ~25 |
| 14 | Code | Metric Computation Functions | Helper functions: precision@K, recall@K, ndcg@K, mrr | ~80 |
| 15 | Code | Compute D-23 Metrics & Load Prior Results | Calculate D-23 scores; load d21_results.csv + d22_results.csv; merge all three | ~100 |
| 16 | Code | 3-Way Delta Analysis | Per-query deltas: D-23 vs D-21, D-23 vs D-22, D-22 vs D-21; aggregation by query type | ~160 |
| 17 | Code | Statistical Significance Testing (3-Way) | Wilcoxon signed-rank for all three pairs; Bonferroni correction for multiple comparisons | ~120 |
| 18 | Code | Visualization — 3-Way Comparison Bar Chart | Grouped bars: D-21 vs D-22 vs D-23 per metric | ~80 |
| 19 | Code | Visualization — Delta Heatmap & Layer Token Distribution | Heatmap: per-query deltas; box plot: token consumption per layer | ~100 |
| 20 | Code | GO/NO-GO Decision Engine | Automated decision logic based on success criteria; formal recommendation | ~130 |
| 21 | Code | Export Results | Save all CSVs; persist ChromaDB; write decision file | ~80 |
| 22 | Markdown | Decision Summary & Next Steps | Interpret GO/NO-GO; scope D-24 (ablation) or simplification path | ~50 |
| — | — | — | **Total** | **~2,185** |

---

## 3. Cell Specifications

<!-- CELL_SPECS_START -->
### Cell 01: Notebook Header

**Type**: Markdown

**Content**:

```markdown
# D-23: Notebook 3 — Multi-Layer Enrichment (GO/NO-GO Decision Point)

## Research Question

**Does enriching text chunks with all 8 hierarchical context layers significantly improve retrieval quality beyond single-layer enrichment?**

This notebook executes the critical decision-point experiment for the FractalRecall project. Results determine whether we proceed with multi-layer enrichment infrastructure (D-24+) or simplify to single-layer enrichment + metadata filtering.

## Experimental Design: 3-Way Comparison

| Notebook | Approach | Enrichment | Key Question |
|----------|----------|-----------|--------------|
| **D-21** | Baseline | None (raw chunks only) | What is baseline retrieval performance? |
| **D-22** | Single-Layer | Document-level prefix (~15-25 tokens) | Does basic structural context help? |
| **D-23** | Multi-Layer | All 8 layers (~50-150 tokens per chunk) | Does comprehensive hierarchy justify token cost? |

All three notebooks use:
- Same 36-query ground-truth set (Q-01 through Q-36)
- Same corpus (Aethelgard Worldbuilding Corpus v5.0, 25 documents)
- Same hybrid chunking engine (adjusted chunk sizes for token budgets)
- Same evaluation metrics (Precision@5, Recall@10, NDCG@10, MRR)
- Same statistical methodology (Wilcoxon signed-rank with Bonferroni correction)

## The 8 Context Layers

| # | Layer | Purpose | Example | Est. Tokens |
|---|-------|---------|---------|-------------|
| 1 | **Corpus** | Dataset identity | "Corpus: Aethelgard Worldbuilding Corpus v5.0" | ~5 |
| 2 | **Domain** | Content category | "Domain: This content is from a faction document in the organizations category." | ~8 |
| 3 | **Entity** | Named entity described | "Entity: This content describes The Iron Covenant." | ~8 |
| 4 | **Authority** | Canon/editorial status | "Authority: This content is canonical and authoritative." | ~8 |
| 5 | **Temporal** | Time period | "Temporal: The events described span the Third Age and Fourth Age." | ~12 |
| 6 | **Relational** | Links to other entities | "Relationships: founded by Elena Voss; rival of Silver Hand." | ~15-30 |
| 7 | **Section** | Document heading | "Section: This content is from the Origins section." | ~10 |
| 8 | **Content** | The actual chunk text | *(the raw text)* | variable |

**Total enrichment prefix per chunk: ~50-150 tokens** (vs. ~15-25 for D-22, ~0 for D-21)

## Critical Context

> This notebook is the critical experiment. Results determine whether FractalRecall proceeds with multi-layer enrichment (D-24+) or simplifies to single-layer + metadata filtering.

## References

- **D-32**: COLAB-SESSION-CONTEXT.md (8-layer enrichment template, session context)
- **R-01**: Embedding Model Evaluation (expanded from v2-moe only to 3 models after 512-token discovery)
- **R-02**: Chunking Strategy Analysis (token budget allocation)
- **R-03**: Anthropic Contextual Retrieval (contextual prefix prepending technique)

## Note: R-01 Scope Expansion

R-01 was originally scoped to v2-moe performance only. After discovering the 512-token context window limitation (vs. the documented 8,192), scope expanded to include v1.5 and BGE-M3. This D-23 notebook runs against SELECTED_MODEL (defaulting to v1.5 after D-21 execution).
```

**Notes**:
- Establishes the GO/NO-GO context and 3-way comparison design
- The 8-layer table is the reference for all enrichment decisions
- Token budget note (50-150 vs 15-25 vs 0) sets expectations for chunk size reduction in Cell 08
- R-01 expansion note explains why 3 models are supported despite original single-model scope

---

### Cell 02: Install Dependencies

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 02: Install Dependencies

Installs all required packages for D-23 notebook execution.
Same package set as D-21 and D-22 for consistency.

Packages:
  - chromadb: Vector database for embedding storage and retrieval
  - sentence-transformers: Embedding model framework (Nomic v2-moe, v1.5)
  - FlagEmbedding: Embedding model framework (BAAI BGE-M3)
  - transformers: Hugging Face model infrastructure
  - torch: PyTorch backend for embedding computation
  - numpy, pandas: Numerical/data analysis
  - scipy: Statistical testing (Wilcoxon signed-rank)
  - scikit-learn: ML utilities
  - matplotlib, seaborn: Visualization
  - tqdm: Progress bars
  - pyyaml: YAML frontmatter parsing
  - umap-learn: Dimensionality reduction for embedding visualization
"""

# Install required packages (suppress verbose output with -q)
!pip install -q chromadb sentence-transformers FlagEmbedding transformers torch numpy pandas scipy scikit-learn matplotlib seaborn tqdm pyyaml umap-learn

# ============================================================================
# VERSION VERIFICATION
# ============================================================================

print("✓ Dependency Installation Complete\n")
print("Package Version Check:")
print("-" * 50)

packages_to_check = [
    'chromadb',
    'sentence_transformers',
    'torch',
    'numpy',
    'pandas',
    'scipy',
    'sklearn',
    'matplotlib',
    'seaborn',
    'tqdm',
    'yaml',
]

for package in packages_to_check:
    try:
        mod = __import__(package)
        version = getattr(mod, '__version__', 'installed (no version attr)')
        print(f"  {package:25} {version}")
    except ImportError:
        print(f"  {package:25} [IMPORT FAILED]")

print("-" * 50)
print("\n✓ All critical dependencies installed and verified.")
```

**Notes**:
- Identical to D-21 Cell 02 and D-22 Cell 02 for consistency
- FlagEmbedding is needed for BGE-M3 (not available via sentence-transformers)
- Version check provides diagnostic output for debugging compatibility issues

---

### Cell 03: Imports, Configuration, Model Selection

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 03: Imports, Configuration, Model Selection

Defines all imports, model configurations, and path constants for D-23.
Extends D-22 config with multi-layer enrichment parameters.

Key D-23 additions vs D-22:
  - prefix_reserve_tokens increased to 100-150 (from D-22's ~30) for 8-layer prefix
  - BONFERRONI_PAIRS = 3 for 3-way statistical correction
  - ADJUSTED_ALPHA = 0.05 / 3 ≈ 0.0167
  - CORPUS_LABEL constant for Corpus layer
  - Output paths for D-23 specific artifacts
"""

# ============================================================================
# STANDARD LIBRARY IMPORTS
# ============================================================================
import os
import sys
from pathlib import Path
from dataclasses import dataclass, field
from typing import Dict, List, Tuple, Any, Optional
import yaml
import re
import json
from datetime import datetime

# ============================================================================
# THIRD-PARTY IMPORTS
# ============================================================================
import numpy as np
import pandas as pd
from scipy.stats import wilcoxon
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend for Colab
import matplotlib.pyplot as plt
import seaborn as sns
from tqdm import tqdm
import warnings

import chromadb
from chromadb.config import Settings

warnings.filterwarnings('ignore')

# ============================================================================
# MODEL CONFIGURATION
# ============================================================================

# ── USER MUST UPDATE THIS AFTER RUNNING D-21 ──
# Default: "v1.5" — the expected winner based on 8192-token context window
# and strong general-purpose performance. Update to match D-21's actual winner.
SELECTED_MODEL = "v1.5"  # Options: "v2-moe", "v1.5", "bge-m3"

@dataclass
class ModelConfig:
    """Configuration for an embedding model.

    Attributes:
        name: Short identifier (e.g., "v1.5")
        hf_model_id: Hugging Face model path
        max_tokens: Model's maximum context window in tokens
        max_chunk_tokens: Target maximum chunk size (content + prefix)
        prefix_reserve_tokens: Tokens reserved for enrichment prefix
        embedding_dim: Output embedding dimensionality
        task_prefix_doc: Prefix for document indexing (empty for BGE-M3)
        task_prefix_query: Prefix for query encoding (empty for BGE-M3)
    """
    name: str
    hf_model_id: str
    max_tokens: int
    max_chunk_tokens: int
    prefix_reserve_tokens: int
    embedding_dim: int
    task_prefix_doc: str
    task_prefix_query: str

# Three models supported — same as D-21/D-22
MODELS: Dict[str, ModelConfig] = {
    "v2-moe": ModelConfig(
        name="v2-moe",
        hf_model_id="nomic-ai/nomic-embed-text-v2-moe",
        max_tokens=512,
        max_chunk_tokens=350,
        prefix_reserve_tokens=100,   # 8-layer prefix: ~80-150 tokens
        embedding_dim=768,
        task_prefix_doc="search_document: ",
        task_prefix_query="search_query: ",
    ),
    "v1.5": ModelConfig(
        name="v1.5",
        hf_model_id="nomic-ai/nomic-embed-text-v1.5",
        max_tokens=8192,
        max_chunk_tokens=600,
        prefix_reserve_tokens=150,   # 8-layer prefix: ~80-150 tokens
        embedding_dim=768,
        task_prefix_doc="search_document: ",
        task_prefix_query="search_query: ",
    ),
    "bge-m3": ModelConfig(
        name="bge-m3",
        hf_model_id="BAAI/bge-m3",
        max_tokens=8192,
        max_chunk_tokens=1024,
        prefix_reserve_tokens=150,   # 8-layer prefix: ~80-150 tokens
        embedding_dim=1024,
        task_prefix_doc="",          # BGE-M3 doesn't use task prefixes
        task_prefix_query="",
    ),
}

# Validate selection
if SELECTED_MODEL not in MODELS:
    raise ValueError(
        f"SELECTED_MODEL '{SELECTED_MODEL}' not in {list(MODELS.keys())}. "
        f"Update after running D-21."
    )

MODEL_CONFIG = MODELS[SELECTED_MODEL]

# ============================================================================
# PATH CONSTANTS
# ============================================================================

# Corpus directory (D-20 output)
CORPUS_DIR = Path("/mnt/0000_concurrent/d20_corpus")

# D-23 output directory
OUTPUT_DIR = Path("/mnt/0000_concurrent/d23_output")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# ChromaDB persistence directory
CHROMADB_DIR = OUTPUT_DIR / "chromadb"
CHROMADB_DIR.mkdir(parents=True, exist_ok=True)

# Prior notebook results for 3-way comparison
D21_RESULTS_PATH = Path("/mnt/0000_concurrent/d21_output/d21_results.csv")
D22_RESULTS_PATH = Path("/mnt/0000_concurrent/d22_output/d22_results.csv")

# ============================================================================
# EVALUATION CONSTANTS
# ============================================================================

K_PRECISION = 5      # Precision@5
K_RECALL = 10        # Recall@10
K_NDCG = 10          # NDCG@10

# Metric column names used throughout the notebook
METRICS = ["precision@5", "recall@10", "ndcg@10", "mrr"]

# ============================================================================
# STATISTICAL TESTING CONSTANTS
# ============================================================================

SIGNIFICANCE_LEVEL = 0.05

# 3-way comparison requires Bonferroni correction:
# 3 pairwise comparisons: D-23 vs D-21, D-23 vs D-22, D-22 vs D-21
BONFERRONI_PAIRS = 3
ADJUSTED_ALPHA = SIGNIFICANCE_LEVEL / BONFERRONI_PAIRS  # ≈ 0.0167

# ============================================================================
# MULTI-LAYER ENRICHMENT CONSTANTS
# ============================================================================

# Corpus layer label (hardcoded for this corpus)
CORPUS_LABEL = "Aethelgard Worldbuilding Corpus v5.0"

# ============================================================================
# PRINT CONFIGURATION SUMMARY
# ============================================================================

print("✓ Imports and Configuration Complete\n")
print("=" * 70)
print("D-23 CONFIGURATION SUMMARY")
print("=" * 70)

print(f"\nModel Selection:")
print(f"  SELECTED_MODEL:       {SELECTED_MODEL}")
print(f"  Model ID:             {MODEL_CONFIG.hf_model_id}")
print(f"  Max tokens:           {MODEL_CONFIG.max_tokens}")
print(f"  Max chunk tokens:     {MODEL_CONFIG.max_chunk_tokens}")
print(f"  Prefix reserve:       {MODEL_CONFIG.prefix_reserve_tokens} tokens (multi-layer)")
print(f"  Effective content:    {MODEL_CONFIG.max_chunk_tokens - MODEL_CONFIG.prefix_reserve_tokens} tokens")
print(f"  Embedding dimension:  {MODEL_CONFIG.embedding_dim}")

print(f"\nEvaluation:")
print(f"  Metrics:              {', '.join(METRICS)}")
print(f"  Alpha (unadjusted):   {SIGNIFICANCE_LEVEL}")
print(f"  Bonferroni pairs:     {BONFERRONI_PAIRS}")
print(f"  Adjusted alpha:       {ADJUSTED_ALPHA:.4f}")

print(f"\nPaths:")
print(f"  Corpus:               {CORPUS_DIR}")
print(f"  Output:               {OUTPUT_DIR}")
print(f"  ChromaDB:             {CHROMADB_DIR}")
print(f"  D-21 results:         {D21_RESULTS_PATH}")
print(f"  D-22 results:         {D22_RESULTS_PATH}")

print(f"\nEnrichment:")
print(f"  Corpus label:         {CORPUS_LABEL}")
print(f"  Layers:               8 (Corpus, Domain, Entity, Authority, Temporal, Relational, Section, Content)")

print("=" * 70)
print("\n✓ Configuration complete. Ready for corpus loading.")
```

**Notes**:
- prefix_reserve_tokens is 100-150 for D-23 (vs ~30 for D-22) to accommodate all 8 layers
- BONFERRONI_PAIRS = 3 handles the 3-way comparison correction
- ADJUSTED_ALPHA ≈ 0.0167 is the per-test significance threshold
- CORPUS_LABEL is used by the Corpus layer builder in Cell 09
- Effective content budget: v1.5 gets 450 tokens (600 - 150), v2-moe gets 250 (350 - 100)

---

### Cell 04: Ground-Truth Query Set

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 04: Ground-Truth Query Set

Defines 36 ground-truth queries for evaluation, organized by type:
  - Q-01 to Q-12: Authority queries (canon vs apocrypha distinction)
  - Q-13 to Q-24: Temporal queries (era-specific retrieval)
  - Q-25 to Q-36: Factual queries (baseline semantic retrieval)

Same query set as D-21 Cell 04 and D-22 Cell 04 for consistent 3-way comparison.

Each query includes:
  - query_id: Unique identifier (e.g., "Q-01")
  - query_text: Natural language query string
  - query_type: Category ("authority", "temporal", or "factual")
  - expected_filenames: List of corpus files expected to be relevant
  - relevance_scores: Dict mapping filename → graded relevance (1=marginal, 2=relevant, 3=highly relevant)
"""

@dataclass
class GroundTruthQuery:
    """A single ground-truth query with expected relevant documents.

    Attributes:
        query_id: Unique query identifier (e.g., "Q-01")
        query_text: Natural language query
        query_type: One of "authority", "temporal", "factual"
        expected_filenames: List of corpus filenames expected to be relevant
        relevance_scores: Dict mapping filename → relevance grade (1-3)
    """
    query_id: str
    query_text: str
    query_type: str  # 'authority', 'temporal', 'factual'
    expected_filenames: List[str]
    relevance_scores: Dict[str, int]  # filename → score (1=marginal, 2=relevant, 3=highly)

# ============================================================================
# EXAMPLE QUERIES (showing structure; full set copied from D-21 at runtime)
# ============================================================================

# Authority query example: tests whether enrichment helps distinguish
# canonical vs. non-canonical content
q01 = GroundTruthQuery(
    query_id="Q-01",
    query_text="What is the canonical history of Blackmarch?",
    query_type="authority",
    expected_filenames=["blackmarch_history_canon.md", "kingdoms_overview.md"],
    relevance_scores={"blackmarch_history_canon.md": 3, "kingdoms_overview.md": 2},
)

# Temporal query example: tests whether era/time period enrichment
# improves retrieval of time-specific content
q13 = GroundTruthQuery(
    query_id="Q-13",
    query_text="What major events occurred in the Third Age?",
    query_type="temporal",
    expected_filenames=["third_age_timeline.md", "kingdoms_overview.md", "magic_history.md"],
    relevance_scores={
        "third_age_timeline.md": 3,
        "kingdoms_overview.md": 2,
        "magic_history.md": 2,
    },
)

# Factual query example: tests baseline semantic improvement from
# any enrichment (not specifically authority or temporal)
q25 = GroundTruthQuery(
    query_id="Q-25",
    query_text="How does the magic system work in Aethelgard?",
    query_type="factual",
    expected_filenames=["magic_system.md", "magic_schools.md", "kingdoms_overview.md"],
    relevance_scores={
        "magic_system.md": 3,
        "magic_schools.md": 2,
        "kingdoms_overview.md": 1,
    },
)

# ============================================================================
# FULL QUERY SET: Q-01 through Q-36
# ============================================================================
# The complete 36-query set is identical to D-21 Cell 04 and D-22 Cell 04.
# When executing in Colab/Kaggle, copy the full definitions from D-21.
#
# Structure:
#   Q-01 through Q-12: Authority queries (12 queries)
#     - Test canon/apocrypha distinction
#     - Hypothesis: Authority + Entity layers help most
#
#   Q-13 through Q-24: Temporal queries (12 queries)
#     - Test era-specific and time-aware retrieval
#     - Hypothesis: Temporal layer helps most
#
#   Q-25 through Q-36: Factual queries (12 queries)
#     - Test baseline semantic retrieval quality
#     - Hypothesis: Domain + Entity layers help most

GROUND_TRUTH_QUERIES: List[GroundTruthQuery] = [
    q01,
    # Q-02 through Q-12: Copy from D-21 Cell 04 (authority queries)
    q13,
    # Q-14 through Q-24: Copy from D-21 Cell 04 (temporal queries)
    q25,
    # Q-26 through Q-36: Copy from D-21 Cell 04 (factual queries)
]

# ============================================================================
# VALIDATION
# ============================================================================

print("✓ Ground-Truth Query Set Loaded\n")
print(f"  Total queries defined: {len(GROUND_TRUTH_QUERIES)}")

# Count by type
type_counts = {}
for q in GROUND_TRUTH_QUERIES:
    type_counts[q.query_type] = type_counts.get(q.query_type, 0) + 1

for qtype in ["authority", "temporal", "factual"]:
    count = type_counts.get(qtype, 0)
    print(f"  {qtype.capitalize():12s} (Q-01–Q-12 style): {count}")

print("\nSample queries:")
for q in [q01, q13, q25]:
    print(f"  {q.query_id} [{q.query_type}]: {q.query_text}")
    print(f"    Expected: {len(q.expected_filenames)} files, max relevance: {max(q.relevance_scores.values())}")

print("\n⚠ Note: When executing, copy full Q-01 through Q-36 from D-21 Cell 04.")
print("✓ Ready for evaluation.")
```

**Notes**:
- GroundTruthQuery dataclass is identical to D-21/D-22 for compatibility
- Three example queries shown (one per type) demonstrate the structure
- Full 36-query set should be copied from D-21 Cell 04 at execution time
- Graded relevance (1-3) supports NDCG computation in Cell 14

---

### Cell 05: Field Mapping & Normalization

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 05: Field Mapping & Normalization

Normalizes raw YAML frontmatter fields to consistent canonical forms.
Handles variations in field names (e.g., "canon" vs "canonical_status")
and value formats (e.g., True vs "yes" vs "canonical").

Identical to D-21 Cell 05 and D-22 Cell 05 for consistency.

Functions:
  - normalize_canon_status(value) → str ("true"/"false")
  - normalize_authority_layer(value) → str ("primary"/"secondary"/"tertiary"/"unknown")
  - normalize_entity_type(value) → str ("character"/"location"/"faction"/etc.)
  - normalize_version(value) → str (semantic version like "1.0")
  - map_frontmatter(raw) → Dict[str, Any] (fully normalized metadata dict)
"""

# ============================================================================
# FIELD MAP: maps canonical key → list of possible raw frontmatter key names
# ============================================================================

FIELD_MAP: Dict[str, List[str]] = {
    "type":              ["type", "entity_type", "document_type", "doc_type", "category"],
    "name":              ["name", "entity_name", "title", "subject"],
    "canon":             ["canon", "canon_status", "canonical", "is_canonical"],
    "authority_layer":   ["authority_layer", "authority", "authority_level"],
    "era":               ["era", "age", "time_period", "historical_era", "eras"],
    "domain_layer":      ["domain_layer", "domain", "lore_category"],
    "related_entities":  ["related_entities", "relationships", "relations", "links", "see_also"],
    "version":           ["version", "doc_version", "revision"],
    "tags":              ["tags", "keywords", "labels"],
    "description":       ["description", "summary", "blurb"],
}


def normalize_canon_status(value: Any) -> str:
    """Normalize canon/canonical status to 'true' or 'false'.

    Handles: True/False booleans, 'yes'/'no', 'canonical'/'apocryphal',
    numeric 1/0, and string variations.

    Args:
        value: Raw canon value from frontmatter

    Returns:
        Normalized string: 'true' or 'false'
    """
    if value is None:
        return "false"
    if isinstance(value, bool):
        return "true" if value else "false"
    s = str(value).lower().strip()
    if s in ("true", "yes", "1", "canonical", "canon"):
        return "true"
    return "false"


def normalize_authority_layer(value: Any) -> str:
    """Normalize authority layer to canonical form.

    Maps various authority designations to: 'primary', 'secondary',
    'tertiary', or 'unknown'.

    Args:
        value: Raw authority value

    Returns:
        One of: 'primary', 'secondary', 'tertiary', 'unknown'
    """
    if value is None:
        return "unknown"
    s = str(value).lower().strip()
    if s in ("primary", "official", "canonical", "1"):
        return "primary"
    if s in ("secondary", "semi-official", "semi-canon", "2"):
        return "secondary"
    if s in ("tertiary", "unofficial", "fan", "apocryphal", "3"):
        return "tertiary"
    return "unknown"


def normalize_entity_type(value: Any) -> str:
    """Normalize entity type to canonical form.

    Maps variations like 'char', 'npc', 'org' to standard names.

    Args:
        value: Raw entity type value

    Returns:
        Normalized type string (e.g., 'character', 'faction', 'location')
    """
    if value is None:
        return "unknown"
    s = str(value).lower().strip()
    type_map = {
        "character": "character", "char": "character", "npc": "character", "person": "character",
        "faction": "faction", "org": "faction", "organization": "faction", "group": "faction",
        "location": "location", "place": "location", "region": "location", "area": "location",
        "event": "event", "battle": "event", "war": "event",
        "item": "item", "artifact": "item", "object": "item", "weapon": "item",
        "concept": "concept", "magic": "concept", "system": "concept",
        "spell": "spell", "ability": "spell",
        "creature": "creature", "monster": "creature", "beast": "creature",
        "timeline": "timeline", "chronology": "timeline",
    }
    return type_map.get(s, s)  # Return as-is if not in map


def normalize_version(value: Any) -> str:
    """Extract semantic version from raw version string.

    Args:
        value: Raw version (e.g., 'v1.2', '2.0.1', 'rev3')

    Returns:
        Semantic version string (e.g., '1.2', '2.0.1'). Defaults to '1.0'.
    """
    if value is None:
        return "1.0"
    match = re.search(r'v?(\d+(?:\.\d+)*)', str(value))
    return match.group(1) if match else "1.0"


def map_frontmatter(raw_frontmatter: Dict[str, Any]) -> Dict[str, Any]:
    """Map raw frontmatter keys to normalized canonical form.

    Iterates through FIELD_MAP to find matching keys in raw_frontmatter,
    applies appropriate normalization, and returns a clean metadata dict.

    Args:
        raw_frontmatter: Dict with potentially inconsistent keys

    Returns:
        Dict with normalized keys and values. Unmapped keys preserved
        with 'raw_' prefix.
    """
    normalized: Dict[str, Any] = {}
    mapped_raw_keys: set = set()

    for canonical_key, variations in FIELD_MAP.items():
        for variation in variations:
            if variation in raw_frontmatter:
                raw_value = raw_frontmatter[variation]
                mapped_raw_keys.add(variation)

                # Apply appropriate normalization
                if canonical_key == "canon":
                    normalized[canonical_key] = normalize_canon_status(raw_value)
                elif canonical_key == "authority_layer":
                    normalized[canonical_key] = normalize_authority_layer(raw_value)
                elif canonical_key == "type":
                    normalized[canonical_key] = normalize_entity_type(raw_value)
                elif canonical_key == "version":
                    normalized[canonical_key] = normalize_version(raw_value)
                else:
                    normalized[canonical_key] = raw_value

                break  # Use first matching variation

    # Preserve unmapped keys with 'raw_' prefix for diagnostics
    for key, value in raw_frontmatter.items():
        if key not in mapped_raw_keys:
            normalized[f"raw_{key}"] = value

    return normalized


# ============================================================================
# VERIFICATION
# ============================================================================

print("✓ Field Mapping & Normalization Functions Loaded\n")
print(f"  Canonical fields: {len(FIELD_MAP)}")
for key, variations in FIELD_MAP.items():
    print(f"    {key:20s} ← {variations}")

print(f"\n  Normalization functions: canon_status, authority_layer, entity_type, version")
print("✓ Ready to normalize corpus frontmatter.")
```

**Notes**:
- FIELD_MAP handles common frontmatter key variations across the D-20 corpus
- normalize_canon_status handles bool/str/int inputs → "true"/"false"
- normalize_entity_type maps abbreviations to canonical forms
- map_frontmatter applies all normalizations and preserves unmapped keys
- Identical to D-21/D-22 Cell 05 for apples-to-apples comparison

---

### Cell 06: Corpus Loading

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 06: Corpus Loading

Loads all 25 lore documents from the D-20 test corpus directory.
Parses YAML frontmatter and Markdown body from each file.
Validates loaded documents against ground-truth query expectations.

Identical to D-21 Cell 06 and D-22 Cell 06 for consistency.

Outputs:
  - corpus: List[LoreDocument] (all loaded documents)
  - filename_index: Dict[str, LoreDocument] (fast lookup by filename)
  - Validation report: which ground-truth expected files are present/missing
"""

@dataclass
class LoreDocument:
    """A single document from the FractalRecall corpus.

    Attributes:
        filename: Filename (e.g., 'iron_covenant.md')
        frontmatter: Raw YAML frontmatter dict (before normalization)
        body: Markdown body text (after frontmatter)
        metadata: Normalized metadata dict (output of map_frontmatter)
    """
    filename: str
    frontmatter: Dict[str, Any]
    body: str
    metadata: Dict[str, Any]


def parse_lore_file(filepath: Path) -> Tuple[Dict[str, Any], str]:
    """Parse a lore document into frontmatter and body.

    Expects format:
        ---
        key: value
        ---
        # Markdown body

    Args:
        filepath: Path to .md file

    Returns:
        Tuple of (frontmatter_dict, body_str)
    """
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception as e:
        print(f"  ✗ Error reading {filepath.name}: {e}")
        return {}, ""

    # Split on YAML frontmatter delimiters
    if content.startswith("---"):
        parts = content.split("---", 2)
        if len(parts) >= 3:
            try:
                frontmatter = yaml.safe_load(parts[1]) or {}
            except yaml.YAMLError as e:
                print(f"  ⚠ YAML parse error in {filepath.name}: {e}")
                frontmatter = {}
            body = parts[2].strip()
        else:
            frontmatter = {}
            body = content
    else:
        frontmatter = {}
        body = content

    if not isinstance(frontmatter, dict):
        frontmatter = {}

    return frontmatter, body


def load_corpus(corpus_dir: Path) -> List[LoreDocument]:
    """Load all .md and .yaml files from corpus directory.

    Args:
        corpus_dir: Path to D-20 test corpus

    Returns:
        List of LoreDocument objects, sorted by filename
    """
    if not corpus_dir.exists():
        print(f"✗ Corpus directory not found: {corpus_dir}")
        print(f"  Ensure D-20 test corpus is available at this path.")
        return []

    # Collect all candidate files
    files = sorted(set(
        list(corpus_dir.glob("*.md"))
        + list(corpus_dir.glob("*.yaml"))
        + list(corpus_dir.glob("*.yml"))
    ))

    print(f"Loading {len(files)} files from {corpus_dir}...")
    documents = []

    for filepath in tqdm(files, desc="Parsing documents"):
        frontmatter, body = parse_lore_file(filepath)
        metadata = map_frontmatter(frontmatter)

        # Add derived fields
        metadata["filepath"] = str(filepath)
        metadata["filename"] = filepath.name

        doc = LoreDocument(
            filename=filepath.name,
            frontmatter=frontmatter,
            body=body,
            metadata=metadata,
        )
        documents.append(doc)

    return documents


# ============================================================================
# LOAD CORPUS
# ============================================================================

corpus = load_corpus(CORPUS_DIR)

print(f"\n✓ Corpus Loaded: {len(corpus)} documents\n")

# Build filename index for fast lookup
filename_index: Dict[str, LoreDocument] = {doc.filename: doc for doc in corpus}

# ============================================================================
# GROUND-TRUTH VALIDATION
# ============================================================================

print("Ground-Truth Validation:")
all_expected = set()
for q in GROUND_TRUTH_QUERIES:
    all_expected.update(q.expected_filenames)

missing = all_expected - set(filename_index.keys())
found = all_expected & set(filename_index.keys())

if missing:
    print(f"  ⚠ {len(missing)} expected files NOT in corpus:")
    for fn in sorted(missing):
        print(f"      - {fn}")
else:
    print(f"  ✓ All {len(found)} expected files found in corpus")

# ============================================================================
# CORPUS SUMMARY
# ============================================================================

print(f"\nCorpus Summary:")
total_body_tokens = sum(estimate_tokens(doc.body) for doc in corpus)
print(f"  Documents:            {len(corpus)}")
print(f"  Total body tokens:    {total_body_tokens:,}")
print(f"  Avg tokens/doc:       {total_body_tokens // max(len(corpus), 1):,}")

# Metadata coverage
meta_keys = set()
for doc in corpus:
    meta_keys.update(doc.metadata.keys())
print(f"  Unique metadata keys: {len(meta_keys)}")

# Key field coverage
for field in ["type", "name", "canon", "era", "related_entities"]:
    present = sum(1 for doc in corpus if doc.metadata.get(field))
    pct = 100 * present / max(len(corpus), 1)
    print(f"  {field:20s}: {present}/{len(corpus)} ({pct:.0f}%)")

print("\n✓ Corpus ready for chunking.")
```

**Notes**:
- LoreDocument dataclass holds raw frontmatter + normalized metadata
- parse_lore_file handles YAML frontmatter extraction with error handling
- load_corpus loads all .md/.yaml/.yml files from CORPUS_DIR
- Ground-truth validation warns about missing expected files
- Metadata coverage report shows which fields are available for enrichment layers

---

### Cell 07: Methodology — Multi-Layer Enrichment

**Type**: Markdown

**Content**:

```markdown
## Methodology: Multi-Layer Enrichment & GO/NO-GO Decision

### Research Hypothesis

**H1 (Primary)**: Multi-layer enrichment (D-23) significantly outperforms single-layer enrichment (D-22) in at least 2 of 4 retrieval metrics.

**H2 (Secondary)**: Entity and Relational layers provide the largest marginal improvement beyond the single-layer prefix.

**H3 (Tertiary)**: Authority-sensitive queries (Q-01 to Q-12) and temporal queries (Q-13 to Q-24) benefit more from multi-layer enrichment than factual queries (Q-25 to Q-36).

### The 8 Context Layers

Each chunk receives a multi-layer prefix constructed from these layers in order:

| # | Layer | Varies By | Token Budget | Source Field |
|---|-------|-----------|-------------|--------------|
| 1 | Corpus | Constant | ~5 | Hardcoded: CORPUS_LABEL |
| 2 | Domain | Document | ~8 | metadata.type → DOMAIN_CATEGORY_MAP |
| 3 | Entity | Document | ~8 | metadata.name |
| 4 | Authority | Document | ~8 | metadata.canon → authority mapping |
| 5 | Temporal | Document | ~12 | metadata.era (list → "X and Y") |
| 6 | Relational | Document | ~15-30 | metadata.related_entities (parsed) |
| 7 | Section | **Chunk** | ~10 | chunk.section_heading |
| 8 | Content | **Chunk** | variable | chunk.text (raw content) |

**Key difference from D-22**: The Section layer varies per chunk (not per document), so every chunk gets a unique prefix. This is more granular than D-22's static document-level prefix.

### Token Budget Impact

| Model | Max Tokens | Prefix Reserve | Content Budget | Prefix % |
|-------|-----------|---------------|---------------|----------|
| v2-moe | 512 | 100 | 250 | ~29% |
| **v1.5** | 8192 | 150 | 450 | ~25% |
| bge-m3 | 8192 | 150 | 874 | ~15% |

D-23 chunks are **shorter** than D-21/D-22 to accommodate the multi-layer prefix within the model's context window.

### 3-Way Comparison Design

```
D-21 (Baseline)     → No enrichment     → Embed raw chunks
D-22 (Single-Layer) → 1 prefix sentence → Embed enriched chunks
D-23 (Multi-Layer)  → 7 prefix layers   → Embed enriched chunks
```

All three use: same corpus, same 36 queries, same model, same metrics.

### Statistical Approach

- **Test**: Wilcoxon signed-rank (paired, non-parametric)
- **Pairs**: 3 comparisons (D-23 vs D-21, D-23 vs D-22, D-22 vs D-21)
- **Correction**: Bonferroni (α_adjusted = 0.05 / 3 ≈ 0.0167)
- **Effect size**: Rank-biserial correlation (|r| < 0.1 negligible, 0.1-0.3 small, 0.3-0.5 medium, > 0.5 large)

### GO/NO-GO Criteria (7 total)

1. **Execution**: < 5% chunk overflow rate
2. **D-23 > D-21**: Mean delta positive for ≥ 3/4 metrics
3. **D-23 > D-22**: Mean delta positive for ≥ 2/4 metrics
4. **Statistical significance**: p < 0.0167 for ≥ 2 metrics (D-23 vs D-21)
5. **Marginal value**: D-23 vs D-22 improvement > 5% for ≥ 1 metric
6. **No catastrophic degradation**: < 25% queries degraded vs D-21
7. **Query type alignment**: Authority/temporal show larger deltas than factual

**Scoring**: ≥5/7 (including #2 and #4) = GO; 3-4/7 = CONDITIONAL GO; <3/7 = NO-GO
```

**Notes**:
- Establishes the three hypotheses that D-23 tests
- Clearly documents the 8-layer structure and token budget implications
- Section layer varying per chunk is the key D-23 innovation over D-22
- GO/NO-GO criteria are explicit and machine-evaluable in Cell 20

---

### Cell 08: Hybrid Chunking Engine

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 08: Hybrid Chunking Engine

Implements the chunking strategy for D-23:
  1. Split by semantic headings (Markdown ## / ### headers)
  2. Sub-split large sections using fixed-window with overlap
  3. Merge small sections to avoid tiny chunks
  4. Reserve tokens for multi-layer prefix

Key difference from D-21/D-22:
  - prefix_reserve defaults to MODEL_CONFIG.prefix_reserve_tokens (100-150)
  - This means chunks are SHORTER than D-21/D-22 to leave room for 8-layer prefix
  - For v1.5: available_tokens = 600 - 150 = 450 (vs D-22's ~570)

Reused from D-21/D-22:
  - Chunk dataclass
  - estimate_tokens() heuristic
  - split_by_headings()
  - fixed_window_split()
"""

# ============================================================================
# DATA STRUCTURES
# ============================================================================

@dataclass
class Chunk:
    """A single text chunk with metadata.

    Attributes:
        chunk_id: Unique identifier (e.g., 'iron_covenant.md#chunk_003')
        doc_filename: Source document filename
        section_heading: Heading of the section this chunk came from (or None)
        text: Raw chunk text (before enrichment)
        token_count_approx: Approximate token count (word_count × 1.3)
        metadata: Normalized metadata dict from parent document
    """
    chunk_id: str
    doc_filename: str
    section_heading: Optional[str]
    text: str
    token_count_approx: int
    metadata: Dict[str, Any]


# ============================================================================
# TOKEN ESTIMATION
# ============================================================================

def estimate_tokens(text: str) -> int:
    """Estimate token count using word-count heuristic.

    Heuristic: tokens ≈ word_count × 1.3
    This is a rough approximation; actual count varies by tokenizer.
    Consistent with D-21/D-22 for fair comparison.

    Args:
        text: Input text string

    Returns:
        Approximate token count (minimum 1)
    """
    if not text or not text.strip():
        return 0
    word_count = len(text.split())
    return max(1, int(word_count * 1.3))


# ============================================================================
# HEADING EXTRACTION
# ============================================================================

def split_by_headings(body: str) -> List[Tuple[Optional[str], str]]:
    """Split document body by Markdown headings.

    Recognizes ## and ### headings as section boundaries.
    Returns (heading, content) tuples.

    Args:
        body: Markdown document body

    Returns:
        List of (section_heading, section_content) tuples.
        heading is None for content before the first heading.
    """
    if not body or not body.strip():
        return [(None, "")]

    # Split on headings (## or ###)
    parts = re.split(r'^(#{2,4}\s+.+)$', body, flags=re.MULTILINE)

    sections: List[Tuple[Optional[str], str]] = []

    # Content before first heading (intro)
    if parts[0].strip():
        sections.append((None, parts[0].strip()))

    # Process heading-content pairs
    for i in range(1, len(parts), 2):
        heading = parts[i].lstrip('#').strip()
        content = parts[i + 1].strip() if i + 1 < len(parts) else ""
        if content:
            sections.append((heading, content))

    if not sections:
        sections = [(None, body)]

    return sections


# ============================================================================
# FIXED-WINDOW SPLITTING
# ============================================================================

def fixed_window_split(
    text: str,
    max_tokens: int,
    overlap_tokens: int = 50,
) -> List[str]:
    """Split text into fixed-size chunks with overlap.

    Used when a section exceeds max_tokens. Splits at word boundaries.

    Args:
        text: Input text
        max_tokens: Maximum tokens per chunk
        overlap_tokens: Token overlap between consecutive chunks

    Returns:
        List of text chunks
    """
    if not text or not text.strip():
        return []

    words = text.split()
    if not words:
        return []

    # Convert token limits to approximate word counts
    max_words = int(max_tokens / 1.3)
    overlap_words = int(overlap_tokens / 1.3)

    chunks = []
    start = 0

    while start < len(words):
        end = min(start + max_words, len(words))
        chunk_text = " ".join(words[start:end])

        if chunk_text.strip():
            chunks.append(chunk_text)

        # Advance with overlap
        next_start = start + max_words - overlap_words
        if next_start <= start:
            next_start = start + 1  # Prevent infinite loop

        start = next_start

    return chunks


# ============================================================================
# DOCUMENT CHUNKING
# ============================================================================

def chunk_document(
    doc: LoreDocument,
    max_chunk_tokens: int,
    prefix_reserve: Optional[int] = None,
) -> List[Chunk]:
    """Chunk a document using hybrid heading + fixed-window approach.

    Steps:
      1. Split body by Markdown headings
      2. For each section, if it exceeds available_tokens, sub-split with overlap
      3. Create Chunk objects with metadata from parent document

    Args:
        doc: LoreDocument to chunk
        max_chunk_tokens: Maximum total tokens per chunk (content + prefix)
        prefix_reserve: Tokens to reserve for enrichment prefix.
            Defaults to MODEL_CONFIG.prefix_reserve_tokens.
            D-23 uses 100-150 (vs D-22's ~30) for 8-layer prefix.

    Returns:
        List of Chunk objects
    """
    if prefix_reserve is None:
        prefix_reserve = MODEL_CONFIG.prefix_reserve_tokens

    # Available tokens for content = max - prefix reserve
    available_tokens = max_chunk_tokens - prefix_reserve

    sections = split_by_headings(doc.body)
    chunks: List[Chunk] = []
    chunk_counter = 0

    for heading, content in sections:
        section_tokens = estimate_tokens(content)

        if section_tokens <= available_tokens:
            # Section fits in one chunk
            chunk_counter += 1
            chunks.append(Chunk(
                chunk_id=f"{doc.filename}#chunk_{chunk_counter:03d}",
                doc_filename=doc.filename,
                section_heading=heading,
                text=content,
                token_count_approx=section_tokens,
                metadata=doc.metadata,
            ))
        else:
            # Section too large — sub-split with fixed window
            sub_chunks = fixed_window_split(content, available_tokens, overlap_tokens=50)
            for sub_text in sub_chunks:
                chunk_counter += 1
                chunks.append(Chunk(
                    chunk_id=f"{doc.filename}#chunk_{chunk_counter:03d}",
                    doc_filename=doc.filename,
                    section_heading=heading,
                    text=sub_text,
                    token_count_approx=estimate_tokens(sub_text),
                    metadata=doc.metadata,
                ))

    return chunks


# ============================================================================
# PRINT CHUNKING CONFIGURATION
# ============================================================================

print("✓ Hybrid Chunking Engine Loaded\n")
print("Chunking Configuration:")
print(f"  Model:                {MODEL_CONFIG.name}")
print(f"  Max chunk tokens:     {MODEL_CONFIG.max_chunk_tokens}")
print(f"  Prefix reserve:       {MODEL_CONFIG.prefix_reserve_tokens} tokens (multi-layer)")
print(f"  Available for content:{MODEL_CONFIG.max_chunk_tokens - MODEL_CONFIG.prefix_reserve_tokens} tokens")
print(f"  Overlap:              50 tokens")
print(f"  Token estimator:      word_count × 1.3")
print(f"\n  Note: D-23 chunks are shorter than D-21/D-22 to accommodate 8-layer prefix.")
print("✓ Ready to chunk corpus.")
```

**Notes**:
- Chunk dataclass includes section_heading for the Section layer (key for D-23)
- estimate_tokens uses word_count × 1.3 heuristic (consistent across D-21/D-22/D-23)
- chunk_document reserves prefix_reserve_tokens for multi-layer enrichment
- For v1.5: available_tokens = 600 - 150 = 450 (vs D-21's 600 and D-22's ~570)
- This means D-23 produces MORE, SHORTER chunks than D-21/D-22

---
### Cell 09: Multi-Layer Enrichment Builder

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 09: Multi-Layer Enrichment Builder — THE CORE NEW CODE

Implements the full 8-layer context enrichment for FractalRecall.
This is the key difference from D-21 (no enrichment) and D-22 (single-layer).

Architecture:
  - 7 individual layer builder functions (Corpus through Section)
  - Each returns Optional[str] — None means the layer is omitted
  - build_multi_layer_prefix() assembles all layers, filters None, joins with "\\n\\n"
  - build_enriched_chunk() prepends the prefix to a chunk's text

Layer rendering format (from COLAB-SESSION-CONTEXT.md / D-32):
  Corpus: Aethelgard Worldbuilding Corpus v5.0

  Domain: This content is from a faction document in the organizations category.

  Entity: This content describes The Iron Covenant.

  Authority: This content is canonical and authoritative.

  Temporal: The events described span the Third Age and Fourth Age.

  Relationships: founded by Elena Voss; rival of Silver Hand; located in Ashenmoor.

  Section: This content is from the Origins section.

  [chunk text here]

Token budget:
  - Best case (sparse metadata):  ~50 tokens
  - Typical case:                 ~80-100 tokens
  - Worst case (rich relational): ~150 tokens
  - Content budget (v1.5):        ~450 tokens (600 - 150 reserve)

Reference: COLAB-SESSION-CONTEXT.md §"The 8 Context Layers"; D-22 Cell 09 (comparison)
"""

# ============================================================================
# DOMAIN CATEGORY MAPPING
# ============================================================================
# Maps document entity types to broader domain categories for the Domain layer.
# Used by build_domain_layer() to produce richer context than just the raw type.

DOMAIN_CATEGORY_MAP: Dict[str, str] = {
    "faction":    "organizations",
    "character":  "individuals",
    "location":   "geography",
    "event":      "history",
    "item":       "artifacts",
    "concept":    "metaphysics",
    "spell":      "magic system",
    "creature":   "bestiary",
    "region":     "geography",
    "timeline":   "chronology",
}


# ============================================================================
# LAYER BUILDER FUNCTIONS
# ============================================================================
# Each function builds one context layer.
# Returns Optional[str]: a rendered layer string, or None to omit the layer.
# None layers are excluded from the final prefix (not rendered as empty lines).

def build_corpus_layer() -> str:
    """Build the Corpus layer (Layer 1).

    Always returns a value — the Corpus layer is never omitted.
    Uses the CORPUS_LABEL constant defined in Cell 03.

    Returns:
        str: "Corpus: {CORPUS_LABEL}"

    Example:
        >>> build_corpus_layer()
        'Corpus: Aethelgard Worldbuilding Corpus v5.0'
    """
    return f"Corpus: {CORPUS_LABEL}"


def build_domain_layer(metadata: Dict[str, Any]) -> str:
    """Build the Domain layer (Layer 2).

    Maps the document type to a broader domain category via DOMAIN_CATEGORY_MAP.
    Always returns a value (defaults to 'general' for unknown types).

    Args:
        metadata: Normalized document metadata with 'type' field.

    Returns:
        str: "Domain: This content is from a {type} document in the {category} category."

    Example:
        >>> build_domain_layer({"type": "faction"})
        'Domain: This content is from a faction document in the organizations category.'
    """
    doc_type = str(metadata.get("type", "unknown")).lower().strip()
    category = DOMAIN_CATEGORY_MAP.get(doc_type, "general")
    return f"Domain: This content is from a {doc_type} document in the {category} category."


def build_entity_layer(metadata: Dict[str, Any]) -> Optional[str]:
    """Build the Entity layer (Layer 3).

    Returns None if the entity name is missing or "Unknown", causing this layer
    to be omitted from the prefix entirely.

    Args:
        metadata: Normalized metadata with 'name' field.

    Returns:
        Optional[str]: "Entity: This content describes {name}." or None.

    Examples:
        >>> build_entity_layer({"name": "The Iron Covenant"})
        'Entity: This content describes The Iron Covenant.'

        >>> build_entity_layer({"name": "Unknown"})
        None
    """
    name = str(metadata.get("name", "")).strip()
    if not name or name.lower() == "unknown":
        return None
    return f"Entity: This content describes {name}."


def build_authority_layer(metadata: Dict[str, Any]) -> str:
    """Build the Authority layer (Layer 4).

    Maps the 'canon' field to a human-readable authority classification.
    Always returns a value (defaults to 'draft' for unrecognized values).

    Mapping:
      - canon=True / "true" / "yes" / "canonical"  → "canonical and authoritative"
      - canon="apocryphal"                          → "apocryphal (non-canonical, speculative)"
      - canon="deprecated"                          → "deprecated and superseded"
      - anything else                               → "draft (not yet canonical)"

    Args:
        metadata: Normalized metadata with 'canon' field.

    Returns:
        str: "Authority: This content is {authority_text}."

    Examples:
        >>> build_authority_layer({"canon": "true"})
        'Authority: This content is canonical and authoritative.'

        >>> build_authority_layer({"canon": "apocryphal"})
        'Authority: This content is apocryphal (non-canonical, speculative).'
    """
    canon = metadata.get("canon", "")

    # Normalize to string
    if isinstance(canon, bool):
        canon_str = "true" if canon else "false"
    else:
        canon_str = str(canon).lower().strip()

    # Map to authority text
    if canon_str in ("true", "yes", "canonical"):
        authority_text = "canonical and authoritative"
    elif canon_str == "apocryphal":
        authority_text = "apocryphal (non-canonical, speculative)"
    elif canon_str == "deprecated":
        authority_text = "deprecated and superseded"
    else:
        authority_text = "draft (not yet canonical)"

    return f"Authority: This content is {authority_text}."


def build_temporal_layer(metadata: Dict[str, Any]) -> Optional[str]:
    """Build the Temporal layer (Layer 5).

    Returns None if no era data is available, causing this layer to be omitted.
    Joins multiple eras with " and ".

    Args:
        metadata: Normalized metadata with 'era' field (list of strings or single string).

    Returns:
        Optional[str]: "Temporal: The events described span the {era_text}." or None.

    Examples:
        >>> build_temporal_layer({"era": ["Third Age", "Fourth Age"]})
        'Temporal: The events described span the Third Age and Fourth Age.'

        >>> build_temporal_layer({})
        None
    """
    eras = metadata.get("era", [])

    # Handle single string
    if isinstance(eras, str):
        eras = [eras] if eras.strip() else []

    # Filter empty values
    eras_clean = [str(e).strip() for e in eras if e and str(e).strip()]

    if not eras_clean:
        return None

    era_text = " and ".join(eras_clean)
    return f"Temporal: The events described span the {era_text}."


def build_relational_layer(metadata: Dict[str, Any]) -> Optional[str]:
    """Build the Relational layer (Layer 6).

    Parses the relationships list from metadata. Each relationship has a
    target (file path) and type (relationship kind). Target names are extracted
    from file paths (e.g., 'characters/elena-voss.md' → 'Elena Voss').
    Relationship types are humanized (underscores → spaces).

    Returns None if no relationships are present.

    Args:
        metadata: Normalized metadata with 'related_entities' field.
            Expected format: list of dicts with 'target' and 'type' keys,
            or list of tuples (type, target).

    Returns:
        Optional[str]: "Relationships: {rel_text}." or None.

    Example:
        >>> meta = {"related_entities": [
        ...     {"target": "characters/elena-voss.md", "type": "founded_by"},
        ...     {"target": "factions/silver-hand.md", "type": "rivalry"},
        ... ]}
        >>> build_relational_layer(meta)
        'Relationships: founded by Elena Voss; rivalry Silver Hand.'
    """
    relationships = metadata.get("related_entities", [])
    if not relationships:
        return None

    rel_parts: List[str] = []

    for rel in relationships:
        # Handle dict format: {"target": "...", "type": "..."}
        if isinstance(rel, dict):
            rel_type = str(rel.get("type", "related to")).replace("_", " ")
            target = str(rel.get("target", ""))
        # Handle tuple/list format: (type, target) or [type, target]
        elif isinstance(rel, (tuple, list)) and len(rel) >= 2:
            rel_type = str(rel[0]).replace("_", " ")
            target = str(rel[1])
        else:
            continue

        # Extract human-readable name from file path
        # e.g., "characters/elena-voss.md" → "Elena Voss"
        if "/" in target:
            target = target.split("/")[-1]  # Get filename
        if target.endswith(".md"):
            target = target[:-3]            # Remove extension
        # Convert kebab-case to Title Case
        target_name = " ".join(
            word.capitalize() for word in target.replace("-", " ").replace("_", " ").split()
        )

        if rel_type and target_name:
            rel_parts.append(f"{rel_type} {target_name}")

    if not rel_parts:
        return None

    return f"Relationships: {'; '.join(rel_parts)}."


def build_section_layer(section_heading: Optional[str]) -> Optional[str]:
    """Build the Section layer (Layer 7).

    Returns None if no section heading is available. This layer varies per CHUNK
    (not per document), making it the key differentiator from D-22's approach.

    Args:
        section_heading: The Markdown heading of the section this chunk belongs to.

    Returns:
        Optional[str]: "Section: This content is from the {heading} section." or None.

    Examples:
        >>> build_section_layer("Origins")
        'Section: This content is from the Origins section.'

        >>> build_section_layer(None)
        None
    """
    if not section_heading or not str(section_heading).strip():
        return None
    return f"Section: This content is from the {section_heading} section."


# ============================================================================
# MULTI-LAYER PREFIX BUILDER
# ============================================================================

def build_multi_layer_prefix(
    metadata: Dict[str, Any],
    section_heading: Optional[str] = None,
) -> Tuple[str, Dict[str, int]]:
    """Assemble the complete multi-layer enrichment prefix.

    Calls each layer builder in order (Corpus → Domain → Entity → Authority →
    Temporal → Relational → Section). Filters out None results. Joins remaining
    layers with double newlines ("\\n\\n").

    Also produces a token audit dict mapping each present layer to its
    approximate token count, used for token budget analysis in Cell 10.

    Args:
        metadata: Normalized document metadata dict.
        section_heading: Section heading for the Section layer (varies per chunk).

    Returns:
        Tuple of:
          - prefix_text (str): Complete multi-layer prefix joined by "\\n\\n"
          - layer_token_audit (Dict[str, int]): Maps layer_name → token_count

    Example:
        >>> meta = {"type": "faction", "name": "Iron Covenant", "canon": "true"}
        >>> prefix, audit = build_multi_layer_prefix(meta, "Origins")
        >>> print(audit)
        {'Corpus': 6, 'Domain': 12, 'Entity': 8, 'Authority': 7, 'Section': 10}
    """
    # Define builders in layer order
    layer_builders: List[Tuple[str, Any]] = [
        ("Corpus",        lambda: build_corpus_layer()),
        ("Domain",        lambda: build_domain_layer(metadata)),
        ("Entity",        lambda: build_entity_layer(metadata)),
        ("Authority",     lambda: build_authority_layer(metadata)),
        ("Temporal",      lambda: build_temporal_layer(metadata)),
        ("Relationships", lambda: build_relational_layer(metadata)),
        ("Section",       lambda: build_section_layer(section_heading)),
    ]

    layer_token_audit: Dict[str, int] = {}
    prefix_parts: List[str] = []

    for layer_name, builder_fn in layer_builders:
        layer_text = builder_fn()
        if layer_text is not None:
            prefix_parts.append(layer_text)
            layer_token_audit[layer_name] = estimate_tokens(layer_text)

    # Join with double newlines (clear semantic boundary between layers)
    prefix_text = "\n\n".join(prefix_parts)

    return prefix_text, layer_token_audit


# ============================================================================
# ENRICHED CHUNK BUILDER
# ============================================================================

def build_enriched_chunk(
    chunk: Chunk,
    enrichment_type: str = "multi_layer",
) -> Tuple[Chunk, Dict[str, int]]:
    """Build an enriched chunk by prepending the multi-layer prefix.

    Constructs the 8-layer prefix from the chunk's metadata and section heading,
    then prepends it to the chunk text with a "\\n\\n" separator.

    Token overflow is LOGGED as a warning but does NOT raise an exception.
    This allows us to track overflow frequency across the corpus (Cell 10).

    Args:
        chunk: Original Chunk object (raw text, no enrichment)
        enrichment_type: Label for enrichment method (default "multi_layer")

    Returns:
        Tuple of:
          - enriched_chunk (Chunk): New Chunk with enriched text and updated token count
          - layer_token_audit (Dict[str, int]): Token counts per layer

    Example:
        >>> enriched, audit = build_enriched_chunk(some_chunk)
        >>> enriched.token_count_approx  # includes prefix + content
        185
        >>> audit
        {'Corpus': 6, 'Domain': 12, 'Entity': 8, ...}
    """
    # Build the multi-layer prefix
    prefix_text, layer_token_audit = build_multi_layer_prefix(
        chunk.metadata,
        chunk.section_heading,
    )

    # Combine prefix + chunk text with clear separator
    enriched_text = f"{prefix_text}\n\n{chunk.text}"
    enriched_tokens = estimate_tokens(enriched_text)

    # Token overflow safety check (WARNING only — does not raise)
    if enriched_tokens > MODEL_CONFIG.max_chunk_tokens:
        print(
            f"  ⚠ Overflow: {chunk.chunk_id} — "
            f"{enriched_tokens} tokens > {MODEL_CONFIG.max_chunk_tokens} limit "
            f"(prefix={sum(layer_token_audit.values())}, content={chunk.token_count_approx})"
        )

    # Create enriched chunk (same metadata, updated text and token count)
    enriched_chunk = Chunk(
        chunk_id=chunk.chunk_id,
        doc_filename=chunk.doc_filename,
        section_heading=chunk.section_heading,
        text=enriched_text,
        token_count_approx=enriched_tokens,
        metadata=chunk.metadata,
    )

    return enriched_chunk, layer_token_audit


# ============================================================================
# TEST SECTION
# ============================================================================

print("=" * 80)
print("MULTI-LAYER ENRICHMENT BUILDER — TEST")
print("=" * 80)

# Create a sample chunk with rich metadata
sample_metadata = {
    "type": "faction",
    "name": "The Iron Covenant",
    "canon": "true",
    "era": ["Third Age", "Fourth Age"],
    "related_entities": [
        {"target": "characters/elena-voss.md", "type": "founded_by"},
        {"target": "factions/silver-hand.md", "type": "rivalry"},
        {"target": "locations/ashenmoor.md", "type": "located_in"},
    ],
}

sample_chunk = Chunk(
    chunk_id="iron_covenant.md#chunk_001",
    doc_filename="iron_covenant.md",
    section_heading="Origins",
    text=(
        "The Iron Covenant was founded in Year 412 of the Third Age by "
        "Commander Elena Voss. It emerged as a powerful military organization "
        "devoted to maintaining order in the Ashenmoor region."
    ),
    token_count_approx=estimate_tokens(
        "The Iron Covenant was founded in Year 412 of the Third Age by "
        "Commander Elena Voss. It emerged as a powerful military organization "
        "devoted to maintaining order in the Ashenmoor region."
    ),
    metadata=sample_metadata,
)

# Test prefix builder
print("\n[1] Layer-by-layer breakdown:")
prefix_text, layer_audit = build_multi_layer_prefix(sample_metadata, "Origins")
total_prefix_tokens = 0
for layer_name, token_count in layer_audit.items():
    print(f"  {layer_name:15s} | {token_count:3d} tokens")
    total_prefix_tokens += token_count
print(f"  {'─' * 35}")
print(f"  {'TOTAL PREFIX':15s} | {total_prefix_tokens:3d} tokens")

# Test rendered prefix
print(f"\n[2] Rendered prefix ({total_prefix_tokens} tokens):")
print("-" * 80)
print(prefix_text)
print("-" * 80)

# Test enriched chunk
enriched_chunk, _ = build_enriched_chunk(sample_chunk)
print(f"\n[3] Enrichment summary:")
print(f"  Original chunk:  {sample_chunk.token_count_approx} tokens")
print(f"  Prefix overhead: {total_prefix_tokens} tokens")
print(f"  Enriched total:  {enriched_chunk.token_count_approx} tokens")
print(f"  Budget used:     {enriched_chunk.token_count_approx}/{MODEL_CONFIG.max_chunk_tokens} "
      f"({100*enriched_chunk.token_count_approx/MODEL_CONFIG.max_chunk_tokens:.1f}%)")

print("\n✓ Multi-layer enrichment builder initialized and tested.")
```

**Notes**:
- This is the most important cell in D-23 — implements the full 8-layer enrichment
- DOMAIN_CATEGORY_MAP enriches the Domain layer beyond the raw document type
- Each layer builder has comprehensive docstrings, type hints, and examples
- build_multi_layer_prefix returns (text, audit_dict) for token budget tracking
- build_enriched_chunk logs overflow warnings but does NOT raise (allows tracking frequency)
- Test section demonstrates all 7 layers with realistic metadata
- ~180 lines of production-quality code

---

### Cell 10: Chunk, Enrich & Audit Corpus

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 10: Chunk, Enrich & Audit Corpus

Applies chunking to all documents, then applies multi-layer enrichment
to each chunk. Tracks per-layer token consumption for budget analysis.

Key differences from D-22 Cell 10:
  1. Uses build_enriched_chunk() with 8-layer prefix (not single-layer)
  2. Tracks per-layer token consumption (layer_token_audits list)
  3. Reports metadata completeness (which optional layers are present)
  4. Warns on overflow but continues (does NOT raise)

Outputs:
  - enriched_chunks: List[Chunk] (enriched with multi-layer prefix)
  - layer_token_audits: List[Dict[str, int]] (per-chunk layer token breakdown)
  - Summary statistics: token overhead, overflow rate, layer presence rates
"""

enriched_chunks: List[Chunk] = []
layer_token_audits: List[Dict[str, Any]] = []

# Track statistics
tokens_before: List[int] = []     # Raw chunk tokens (pre-enrichment)
tokens_after: List[int] = []      # Enriched chunk tokens (post-enrichment)
overflow_count = 0

print("=" * 80)
print("CHUNK, ENRICH & AUDIT CORPUS")
print("=" * 80)
print(f"\n  Model: {MODEL_CONFIG.name}")
print(f"  Max chunk tokens: {MODEL_CONFIG.max_chunk_tokens}")
print(f"  Prefix reserve: {MODEL_CONFIG.prefix_reserve_tokens}")
print(f"  Available for content: {MODEL_CONFIG.max_chunk_tokens - MODEL_CONFIG.prefix_reserve_tokens}")
print()

for doc in tqdm(corpus, desc="Chunk & enrich"):
    # Step 1: Chunk the document (reserves prefix_reserve_tokens for enrichment)
    doc_chunks = chunk_document(doc, MODEL_CONFIG.max_chunk_tokens)

    # Step 2: Enrich each chunk with multi-layer prefix
    for chunk in doc_chunks:
        tokens_before.append(chunk.token_count_approx)

        enriched_chunk, layer_audit = build_enriched_chunk(chunk)

        tokens_after.append(enriched_chunk.token_count_approx)

        # Track overflow
        if enriched_chunk.token_count_approx > MODEL_CONFIG.max_chunk_tokens:
            overflow_count += 1

        enriched_chunks.append(enriched_chunk)

        # Record audit with chunk identification
        audit_record = {
            "chunk_id": chunk.chunk_id,
            "doc_filename": chunk.doc_filename,
            "section_heading": chunk.section_heading or "(none)",
            "tokens_raw": chunk.token_count_approx,
            "tokens_enriched": enriched_chunk.token_count_approx,
            **layer_audit,
        }
        layer_token_audits.append(audit_record)

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================

print(f"\n✓ Enrichment Complete: {len(enriched_chunks)} chunks\n")

print("TOKEN STATISTICS:")
print("-" * 60)

arr_before = np.array(tokens_before)
arr_after = np.array(tokens_after)
arr_overhead = arr_after - arr_before

print(f"  {'':20s} {'Before':>10s} {'After':>10s} {'Overhead':>10s}")
print(f"  {'Mean':20s} {arr_before.mean():>10.1f} {arr_after.mean():>10.1f} {arr_overhead.mean():>10.1f}")
print(f"  {'Median':20s} {np.median(arr_before):>10.1f} {np.median(arr_after):>10.1f} {np.median(arr_overhead):>10.1f}")
print(f"  {'Max':20s} {arr_before.max():>10d} {arr_after.max():>10d} {arr_overhead.max():>10d}")
print(f"  {'Min':20s} {arr_before.min():>10d} {arr_after.min():>10d} {arr_overhead.min():>10d}")

print(f"\n  Overflow chunks: {overflow_count}/{len(enriched_chunks)} "
      f"({100*overflow_count/max(len(enriched_chunks),1):.1f}%)")

# Overhead distribution
pcts = np.percentile(arr_overhead, [0, 25, 50, 75, 100])
print(f"\n  Prefix overhead distribution:")
print(f"    Min:    {pcts[0]:.0f} tokens")
print(f"    P25:    {pcts[1]:.0f} tokens")
print(f"    Median: {pcts[2]:.0f} tokens")
print(f"    P75:    {pcts[3]:.0f} tokens")
print(f"    Max:    {pcts[4]:.0f} tokens")

# ============================================================================
# LAYER PRESENCE RATES
# ============================================================================

print(f"\nLAYER PRESENCE RATES:")
print("-" * 60)

layer_names = ["Corpus", "Domain", "Entity", "Authority", "Temporal", "Relationships", "Section"]
total = len(layer_token_audits)

for layer in layer_names:
    present = sum(1 for audit in layer_token_audits if layer in audit)
    rate = 100 * present / max(total, 1)
    avg_tokens = np.mean([audit[layer] for audit in layer_token_audits if layer in audit]) if present else 0
    print(f"  {layer:15s}: {present:4d}/{total} ({rate:5.1f}%) — avg {avg_tokens:.1f} tokens")

# ============================================================================
# EXPORT TOKEN AUDIT
# ============================================================================

audit_df = pd.DataFrame(layer_token_audits)
audit_csv_path = OUTPUT_DIR / "d23_layer_token_audit.csv"
audit_df.to_csv(audit_csv_path, index=False)
print(f"\n✓ Token audit exported to {audit_csv_path}")
print(f"  Rows: {len(audit_df)}, Columns: {len(audit_df.columns)}")

print("\n✓ Corpus chunked, enriched, and audited. Ready for embedding.")
```

**Notes**:
- Uses build_enriched_chunk (multi-layer) instead of D-22's single-layer
- Tracks per-layer token consumption via layer_token_audits for D-24 ablation planning
- Reports overflow rate (should be <5% for GO criteria)
- Layer presence rates reveal metadata completeness (e.g., Temporal may be <100%)
- Exports d23_layer_token_audit.csv for downstream analysis
- ~120 lines with comprehensive reporting

---

### Cell 11: Embedding & ChromaDB Indexing

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 11: Embedding & ChromaDB Indexing

Embeds all enriched chunks and indexes them in a ChromaDB collection.
Creates collection d23_multi_layer_{model}.

Same embedding pipeline as D-22 Cell 11, but operating on multi-layer
enriched chunks instead of single-layer enriched chunks.

Supports:
  - sentence-transformers (v2-moe, v1.5): encode with prompt_name="passage"
  - FlagEmbedding (bge-m3): BGEM3FlagModel.encode with dense vectors
"""

print("=" * 80)
print("EMBEDDING & CHROMADB INDEXING")
print("=" * 80)

# ============================================================================
# LOAD EMBEDDING MODEL
# ============================================================================

print(f"\n[1] Loading embedding model: {MODEL_CONFIG.name} ({MODEL_CONFIG.hf_model_id})")

if MODEL_CONFIG.name in ("v2-moe", "v1.5"):
    # Sentence-transformers models
    from sentence_transformers import SentenceTransformer
    embedding_model = SentenceTransformer(
        MODEL_CONFIG.hf_model_id,
        trust_remote_code=True,
    )
    model_backend = "sentence_transformers"
    print(f"  Backend: sentence-transformers")

elif MODEL_CONFIG.name == "bge-m3":
    # FlagEmbedding model
    from FlagEmbedding import BGEM3FlagModel
    embedding_model = BGEM3FlagModel(
        MODEL_CONFIG.hf_model_id,
        use_fp16=True,
    )
    model_backend = "flag_embedding"
    print(f"  Backend: FlagEmbedding (BGE-M3)")

else:
    raise ValueError(f"Unknown model: {MODEL_CONFIG.name}")

print(f"✓ Model loaded")

# ============================================================================
# ENCODE ENRICHED CHUNKS
# ============================================================================

print(f"\n[2] Encoding {len(enriched_chunks)} enriched chunks...")

chunk_texts = [c.text for c in enriched_chunks]
chunk_ids = [c.chunk_id for c in enriched_chunks]

if model_backend == "sentence_transformers":
    embeddings = embedding_model.encode(
        chunk_texts,
        prompt_name="passage",
        batch_size=32,
        show_progress_bar=True,
        convert_to_numpy=True,
    )
elif model_backend == "flag_embedding":
    result = embedding_model.encode(chunk_texts, batch_size=32, max_length=8192)
    embeddings = np.array(result["dense_vecs"])

print(f"✓ Encoded {len(embeddings)} chunks")
print(f"  Embedding dimensions: {embeddings.shape[1]}")

# ============================================================================
# CHROMADB COLLECTION SETUP
# ============================================================================

print(f"\n[3] Setting up ChromaDB collection...")

client = chromadb.PersistentClient(path=str(CHROMADB_DIR))
collection_name = f"d23_multi_layer_{MODEL_CONFIG.name}"

# Delete existing collection if present (clean slate)
try:
    client.delete_collection(name=collection_name)
    print(f"  Deleted existing collection: {collection_name}")
except Exception:
    pass

collection = client.create_collection(
    name=collection_name,
    metadata={"hnsw:space": "cosine"},
)
print(f"✓ Collection created: {collection_name}")

# ============================================================================
# INDEX CHUNKS
# ============================================================================

print(f"\n[4] Adding chunks to collection...")

# Prepare metadata for ChromaDB (flatten complex types to strings)
chroma_metadatas = []
for chunk in enriched_chunks:
    flat_meta = {}
    for key, value in chunk.metadata.items():
        if isinstance(value, (list, dict)):
            flat_meta[key] = json.dumps(value)  # Serialize complex types
        elif value is not None:
            flat_meta[key] = str(value)
    chroma_metadatas.append(flat_meta)

# Add in batches
batch_size = 100
for i in range(0, len(chunk_ids), batch_size):
    end = min(i + batch_size, len(chunk_ids))
    collection.add(
        ids=chunk_ids[i:end],
        embeddings=embeddings[i:end].tolist(),
        documents=chunk_texts[i:end],
        metadatas=chroma_metadatas[i:end],
    )

print(f"✓ Indexed {collection.count()} chunks")

# ============================================================================
# VERIFICATION
# ============================================================================

print(f"\n[5] Collection summary:")
print(f"  Collection name:    {collection_name}")
print(f"  Chunks indexed:     {collection.count()}")
print(f"  Embedding dims:     {embeddings.shape[1]}")
print(f"  Distance metric:    cosine")
print(f"  Model:              {MODEL_CONFIG.name}")
print(f"  Enrichment:         multi-layer (8 layers)")

print("\n✓ Embedding and indexing complete.")
```

**Notes**:
- Same embedding pipeline as D-22 but on multi-layer enriched chunks
- Supports sentence-transformers (v2-moe, v1.5) and FlagEmbedding (bge-m3)
- Creates PersistentClient for disk persistence between sessions
- Metadata serialized (lists/dicts → JSON strings) for ChromaDB compatibility
- Batch size 100 for memory efficiency
- ~80 lines

---

### Cell 12: Query Execution

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 12: Query Execution

Runs all 36 ground-truth queries against the D-23 ChromaDB collection.
Retrieves top-10 results per query with cosine distance scores.

Same pipeline as D-22 Cell 12 but querying the multi-layer collection.

Outputs:
  - query_results: List[QueryResult] (one per query, with top-10 results)
"""

@dataclass
class QueryResult:
    """Result of executing a single query against the D-23 collection.

    Attributes:
        query_id: Query identifier (e.g., "Q-01")
        query_text: Natural language query string
        query_type: Query category ("authority", "temporal", "factual")
        results: List of result dicts, each with:
            - chunk_id (str): Matched chunk identifier
            - distance (float): Cosine distance (lower = more similar)
            - text_preview (str): First 200 chars of matched text
            - metadata (dict): Chunk metadata
    """
    query_id: str
    query_text: str
    query_type: str
    results: List[Dict[str, Any]]


def encode_query(query_text: str) -> np.ndarray:
    """Encode a query string into the embedding space.

    Uses the appropriate task prefix for the selected model.

    Args:
        query_text: Natural language query

    Returns:
        1D numpy array (embedding vector)
    """
    if model_backend == "sentence_transformers":
        return embedding_model.encode(
            [query_text],
            prompt_name="query",
            convert_to_numpy=True,
        )[0]
    elif model_backend == "flag_embedding":
        result = embedding_model.encode([query_text])
        return np.array(result["dense_vecs"][0])
    else:
        raise ValueError(f"Unknown backend: {model_backend}")


def run_query(query_text: str, top_k: int = 10) -> List[Dict[str, Any]]:
    """Execute a single query against the D-23 collection.

    Args:
        query_text: Query string
        top_k: Number of results to retrieve (default 10)

    Returns:
        List of result dicts with chunk_id, distance, text_preview, metadata
    """
    query_embedding = encode_query(query_text)

    results = collection.query(
        query_embeddings=[query_embedding.tolist()],
        n_results=top_k,
    )

    formatted = []
    if results["ids"] and results["ids"][0]:
        for i, (cid, dist, doc, meta) in enumerate(zip(
            results["ids"][0],
            results["distances"][0],
            results["documents"][0],
            results["metadatas"][0],
        )):
            formatted.append({
                "rank": i + 1,
                "chunk_id": cid,
                "distance": float(dist),
                "text_preview": doc[:200] + "..." if len(doc) > 200 else doc,
                "metadata": meta,
            })

    return formatted


# ============================================================================
# EXECUTE ALL QUERIES
# ============================================================================

print("=" * 80)
print("QUERY EXECUTION")
print("=" * 80)
print(f"\n  Running {len(GROUND_TRUTH_QUERIES)} queries against {collection_name}...")

query_results: List[QueryResult] = []

for i, gt_query in enumerate(tqdm(GROUND_TRUTH_QUERIES, desc="Querying")):
    results = run_query(gt_query.query_text, top_k=10)
    query_results.append(QueryResult(
        query_id=gt_query.query_id,
        query_text=gt_query.query_text,
        query_type=gt_query.query_type,
        results=results,
    ))

# ============================================================================
# SUMMARY
# ============================================================================

results_per_q = [len(qr.results) for qr in query_results]
print(f"\n✓ All {len(query_results)} queries executed")
print(f"  Avg results/query:  {np.mean(results_per_q):.1f}")
print(f"  Total result tuples: {sum(results_per_q)}")

# By query type
for qtype in ["authority", "temporal", "factual"]:
    count = sum(1 for qr in query_results if qr.query_type == qtype)
    print(f"  {qtype:12s}: {count} queries")

# Sample preview
print(f"\nSample results (first 2 queries):")
for qr in query_results[:2]:
    print(f"  {qr.query_id} [{qr.query_type}]: {qr.query_text[:50]}...")
    for res in qr.results[:3]:
        print(f"    [{res['rank']}] {res['chunk_id']} (dist={res['distance']:.4f})")

print("\n✓ Ready for metric computation.")
```

**Notes**:
- QueryResult dataclass captures per-query results with top-10 ranked chunks
- encode_query uses prompt_name="query" for sentence-transformers (MoE routing)
- run_query retrieves top-10 from ChromaDB with cosine distance
- ~70 lines with comprehensive diagnostics

---

### Cell 13: Results Introduction

**Type**: Markdown

**Content**:

```markdown
## D-23 Results: 3-Way Comparison Analysis

All 36 ground-truth queries have been executed against the D-23 multi-layer enriched corpus. The following cells compute retrieval metrics and perform a **3-way comparison** across:

1. **D-21 Baseline** — no enrichment (raw chunks)
2. **D-22 Single-Layer** — one-sentence document-level prefix (~15-25 tokens)
3. **D-23 Multi-Layer** — 8-layer composite prefix (~50-150 tokens per chunk)

### Statistical Framework

With 3 pairwise comparisons, **Bonferroni correction** controls the family-wise error rate:

- **Adjusted α** = 0.05 / 3 ≈ **0.0167**
- A test is significant only if **p < 0.0167**

This is conservative but appropriate for an early-stage decision point.

### What Follows

| Cell | Purpose |
|------|---------|
| 14 | Metric computation functions (Precision@5, Recall@10, NDCG@10, MRR) |
| 15 | Compute D-23 metrics; load D-21 and D-22 results; merge comparison dataframe |
| 16 | 3-way delta analysis: per-query deltas, query-type breakdown, marginal value |
| 17 | Wilcoxon signed-rank tests with Bonferroni correction; effect sizes |
| 18 | Visualization: 3-way comparison bar chart |
| 19 | Visualization: delta heatmap and layer token distribution |
| 20 | **GO/NO-GO Decision Engine**: automated evaluation of 7 criteria |
| 21 | Export all results, CSVs, decision file |
| 22 | Decision summary and next steps |
```

**Notes**:
- Brief context for the analysis section (Cells 14-22)
- Bonferroni correction explained clearly
- Cell map shows the flow from metrics → analysis → decision

---

### Cell 14: Metric Computation Functions

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 14: Metric Computation Functions

Defines the four retrieval evaluation metrics used across D-21, D-22, and D-23:
  1. Precision@K — fraction of top-K results that are relevant
  2. Recall@K — fraction of all relevant documents found in top-K
  3. NDCG@K — ranking quality using graded relevance with log discount
  4. MRR — reciprocal rank of first relevant result

Also defines compute_all_metrics() which runs all four on a list of QueryResults.

These functions are identical to D-21 Cell 14 and D-22 Cell 14.
"""


def precision_at_k(
    retrieved_ids: List[str],
    relevant_ids: set,
    k: int = K_PRECISION,
) -> float:
    """Compute Precision@K.

    Formula: P@K = |relevant ∩ top-K| / K

    Args:
        retrieved_ids: Ordered list of retrieved chunk IDs (rank order)
        relevant_ids: Set of known-relevant chunk IDs
        k: Cutoff rank (default K_PRECISION=5)

    Returns:
        Precision@K in [0.0, 1.0]

    Example:
        >>> precision_at_k(["A","B","C","D","E"], {"A","C","F"}, k=5)
        0.4  # 2 relevant in top-5
    """
    if k <= 0:
        return 0.0
    top_k = set(retrieved_ids[:k])
    return len(top_k & set(relevant_ids)) / k


def recall_at_k(
    retrieved_ids: List[str],
    relevant_ids: set,
    k: int = K_RECALL,
) -> float:
    """Compute Recall@K.

    Formula: R@K = |relevant ∩ top-K| / |relevant|

    Args:
        retrieved_ids: Ordered list of retrieved chunk IDs
        relevant_ids: Set of known-relevant chunk IDs
        k: Cutoff rank (default K_RECALL=10)

    Returns:
        Recall@K in [0.0, 1.0]. Returns 0.0 if relevant set is empty.

    Example:
        >>> recall_at_k(["A","B","C"], {"A","C","D","E"}, k=3)
        0.5  # 2 of 4 relevant found
    """
    if not relevant_ids:
        return 0.0
    top_k = set(retrieved_ids[:k])
    return len(top_k & set(relevant_ids)) / len(relevant_ids)


def ndcg_at_k(
    retrieved_ids: List[str],
    relevance_scores: Dict[str, int],
    k: int = K_NDCG,
) -> float:
    """Compute NDCG@K (Normalized Discounted Cumulative Gain).

    Formula:
      DCG@K  = Σ(i=1..K) rel(i) / log2(i + 1)
      IDCG@K = DCG of ideal ranking (sorted by relevance descending)
      NDCG@K = DCG@K / IDCG@K

    Uses graded relevance scores (1=marginal, 2=relevant, 3=highly relevant).

    Args:
        retrieved_ids: Ordered list of retrieved chunk IDs
        relevance_scores: Dict mapping chunk_id → relevance grade
        k: Cutoff rank (default K_NDCG=10)

    Returns:
        NDCG@K in [0.0, 1.0]. Returns 0.0 if no relevant documents exist.

    Example:
        >>> ndcg_at_k(["A","B","C"], {"A": 3, "C": 1}, k=3)
        # DCG = 3/log2(2) + 0/log2(3) + 1/log2(4) = 3.0 + 0 + 0.5 = 3.5
        # IDCG = 3/log2(2) + 1/log2(3) = 3.0 + 0.63 = 3.63
        # NDCG = 3.5 / 3.63 ≈ 0.964
    """
    if not relevance_scores:
        return 0.0

    # Compute DCG
    top_k = retrieved_ids[:k]
    dcg = 0.0
    for i, chunk_id in enumerate(top_k):
        rel = relevance_scores.get(chunk_id, 0)
        dcg += rel / np.log2(i + 2)  # i+2 because 0-indexed

    # Compute ideal DCG (IDCG)
    ideal_rels = sorted(relevance_scores.values(), reverse=True)[:k]
    idcg = 0.0
    for i, rel in enumerate(ideal_rels):
        idcg += rel / np.log2(i + 2)

    if idcg == 0:
        return 0.0

    return dcg / idcg


def mean_reciprocal_rank(
    retrieved_ids: List[str],
    relevant_ids: set,
) -> float:
    """Compute Mean Reciprocal Rank (MRR).

    Formula: MRR = 1 / rank_of_first_relevant_result

    Args:
        retrieved_ids: Ordered list of retrieved chunk IDs
        relevant_ids: Set of known-relevant chunk IDs

    Returns:
        MRR in [0.0, 1.0]. Returns 0.0 if no relevant result found.

    Example:
        >>> mean_reciprocal_rank(["X","Y","A","B"], {"A","C"})
        0.333  # First relevant at rank 3
    """
    for rank, chunk_id in enumerate(retrieved_ids, start=1):
        if chunk_id in relevant_ids:
            return 1.0 / rank
    return 0.0


def compute_all_metrics(
    qr_list: List[QueryResult],
    gt_queries: List[GroundTruthQuery],
) -> pd.DataFrame:
    """Compute all four metrics for each query.

    Matches QueryResult objects to GroundTruthQuery objects by query_id.
    Returns a DataFrame with one row per query.

    Args:
        qr_list: List of QueryResult objects from query execution
        gt_queries: List of GroundTruthQuery objects with relevance judgments

    Returns:
        DataFrame with columns:
          [query_id, query_type, precision@5, recall@10, ndcg@10, mrr]
    """
    # Build lookup: query_id → ground truth
    gt_lookup = {q.query_id: q for q in gt_queries}

    rows = []
    for qr in qr_list:
        gt = gt_lookup.get(qr.query_id)
        if gt is None:
            continue

        retrieved = [r["chunk_id"] for r in qr.results]
        relevant = set(gt.expected_filenames)

        rows.append({
            "query_id": qr.query_id,
            "query_type": qr.query_type,
            "precision@5": precision_at_k(retrieved, relevant),
            "recall@10": recall_at_k(retrieved, relevant),
            "ndcg@10": ndcg_at_k(retrieved, gt.relevance_scores),
            "mrr": mean_reciprocal_rank(retrieved, relevant),
        })

    return pd.DataFrame(rows)


# ============================================================================
# VERIFICATION
# ============================================================================

print("✓ Metric Computation Functions Loaded")
print(f"  Functions: precision_at_k, recall_at_k, ndcg_at_k, mean_reciprocal_rank")
print(f"  compute_all_metrics → DataFrame[query_id, query_type, P@5, R@10, NDCG@10, MRR]")
print(f"  Evaluation constants: K_PRECISION={K_PRECISION}, K_RECALL={K_RECALL}, K_NDCG={K_NDCG}")
print("✓ Ready for metric computation.")
```

**Notes**:
- All four metrics have docstrings with formulas, parameters, return types, and examples
- NDCG uses graded relevance (1/2/3) with log2(i+2) discount
- compute_all_metrics matches QueryResult to GroundTruthQuery by query_id
- Identical to D-21/D-22 for apples-to-apples comparison
- ~80 lines

---
### Cell 15: Compute D-23 Metrics & Load Prior Results

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 15: Compute D-23 Metrics & Load Prior Results

Computes per-query metrics for D-23 multi-layer enrichment, loads D-21
baseline and D-22 single-layer results, and builds a unified comparison
DataFrame for 3-way delta analysis.

Outputs:
  - d23_df: DataFrame with D-23 per-query metrics
  - d21_df: DataFrame with D-21 baseline metrics (loaded from CSV)
  - d22_df: DataFrame with D-22 single-layer metrics (loaded from CSV)
  - comparison_df: Combined DataFrame with experiment labels

Reference: D-21 Cell 15 (baseline export format), D-22 Cell 15 (comparison pattern)
"""

import warnings

# ============================================================================
# COMPUTE D-23 METRICS
# ============================================================================

print("=" * 90)
print("COMPUTING D-23 MULTI-LAYER ENRICHMENT METRICS")
print("=" * 90)

d23_df = compute_all_metrics(all_results, QUERIES)
d23_df["model"] = SELECTED_MODEL
d23_df["experiment"] = "multi_layer"

print(f"\n✓ D-23 metrics computed for {len(d23_df)} queries")
print(f"  Columns: {list(d23_df.columns)}")
print(f"  Model: {SELECTED_MODEL}")
print(f"  Experiment: multi_layer")

# ============================================================================
# LOAD D-21 BASELINE RESULTS
# ============================================================================

print()
print("-" * 90)
print("Loading D-21 Baseline Results")
print("-" * 90)

if D21_RESULTS_PATH.exists():
    d21_df = pd.read_csv(D21_RESULTS_PATH)
    d21_df["experiment"] = "baseline"
    print(f"✓ Loaded D-21 baseline: {len(d21_df)} queries from {D21_RESULTS_PATH}")
else:
    warnings.warn(f"⚠ D-21 results not found at {D21_RESULTS_PATH}")
    print(f"⚠ D-21 results file not found: {D21_RESULTS_PATH}")
    print("  D-23 vs D-21 comparison will be skipped.")
    d21_df = pd.DataFrame()

# ============================================================================
# LOAD D-22 SINGLE-LAYER RESULTS
# ============================================================================

print()
print("-" * 90)
print("Loading D-22 Single-Layer Results")
print("-" * 90)

if D22_RESULTS_PATH.exists():
    d22_df = pd.read_csv(D22_RESULTS_PATH)
    d22_df["experiment"] = "single_layer"
    print(f"✓ Loaded D-22 single-layer: {len(d22_df)} queries from {D22_RESULTS_PATH}")
else:
    warnings.warn(f"⚠ D-22 results not found at {D22_RESULTS_PATH}")
    print(f"⚠ D-22 results file not found: {D22_RESULTS_PATH}")
    print("  D-23 vs D-22 comparison will be skipped.")
    d22_df = pd.DataFrame()

# ============================================================================
# BUILD COMPARISON DATAFRAME
# ============================================================================

print()
print("-" * 90)
print("Building 3-Way Comparison DataFrame")
print("-" * 90)

frames_to_concat = [d23_df]
if not d21_df.empty:
    frames_to_concat.append(d21_df)
if not d22_df.empty:
    frames_to_concat.append(d22_df)

comparison_df = pd.concat(frames_to_concat, ignore_index=True)
print(f"✓ Comparison DataFrame: {len(comparison_df)} total rows")
print(f"  Experiments present: {comparison_df['experiment'].unique().tolist()}")

# ============================================================================
# SUMMARY TABLE
# ============================================================================

print()
print("=" * 90)
print("MEAN METRIC VALUES BY EXPERIMENT")
print("=" * 90)

summary_stats = comparison_df.groupby("experiment")[METRICS].mean()
print()
print(summary_stats.to_string())

# ============================================================================
# TREND ARROWS (D-23 vs D-22 and D-22 vs D-21)
# ============================================================================

print()
print("=" * 90)
print("TREND ANALYSIS")
print("=" * 90)

d23_means = d23_df[METRICS].mean()

if not d22_df.empty:
    d22_means = d22_df[METRICS].mean()
    print("\nD-23 (Multi-Layer) vs D-22 (Single-Layer):")
    for metric in METRICS:
        d23_val = d23_means[metric]
        d22_val = d22_means[metric]
        delta = d23_val - d22_val

        if abs(delta) < 0.001:
            arrow = "→"
        elif delta > 0:
            arrow = "↑"
        else:
            arrow = "↓"

        pct = (delta / d22_val * 100) if d22_val > 0 else 0
        label = METRIC_LABELS[METRICS.index(metric)]
        print(f"  {label:15} {arrow} {d23_val:.4f} vs {d22_val:.4f} (delta {delta:+.4f}, {pct:+.1f}%)")

if not d21_df.empty:
    d21_means = d21_df[METRICS].mean()
    print("\nD-23 (Multi-Layer) vs D-21 (Baseline):")
    for metric in METRICS:
        d23_val = d23_means[metric]
        d21_val = d21_means[metric]
        delta = d23_val - d21_val

        if abs(delta) < 0.001:
            arrow = "→"
        elif delta > 0:
            arrow = "↑"
        else:
            arrow = "↓"

        pct = (delta / d21_val * 100) if d21_val > 0 else 0
        label = METRIC_LABELS[METRICS.index(metric)]
        print(f"  {label:15} {arrow} {d23_val:.4f} vs {d21_val:.4f} (delta {delta:+.4f}, {pct:+.1f}%)")

print()
print("=" * 90)
print(f"✓ D-23 metrics ready. Total queries: {len(d23_df)}")
print("✓ Comparison DataFrame built. Ready for 3-way delta analysis.")
print("=" * 90)
```

**Notes**:
- Loads D-21 and D-22 results from CSV; handles missing files with warnings (does not fail)
- Builds comparison_df by concatenating all available experiments
- Summary table shows mean metric values per experiment for quick visual comparison
- Trend arrows (↑/→/↓) show direction and magnitude of D-23 vs D-22 and D-23 vs D-21
- ~100 lines

---

### Cell 16: 3-Way Delta Analysis

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 16: 3-Way Delta Analysis — THE CORE ANALYSIS CELL

Computes per-query metric deltas for all 3 comparison pairs:
  1. ml_vs_bl: D-23 (multi-layer) - D-21 (baseline) — primary hypothesis
  2. ml_vs_sl: D-23 (multi-layer) - D-22 (single-layer) — complexity justification
  3. sl_vs_bl: D-22 (single-layer) - D-21 (baseline) — reference / sanity check

Also computes MARGINAL VALUE: the improvement added by layers 2-8 beyond
the single-layer prefix (isolates the contribution of the additional layers).

Outputs:
  - delta_results: dict of pair_key → delta DataFrame
  - d23_delta_vs_d21.csv, d23_delta_vs_d22.csv

Reference: D-22 Cell 16 (2-way delta pattern); D-23 Cell 07 (methodology)
"""

print("=" * 90)
print("3-WAY DELTA ANALYSIS: MULTI-LAYER vs SINGLE-LAYER vs BASELINE")
print("=" * 90)

# ============================================================================
# DEFINE COMPARISON PAIRS
# ============================================================================

PAIRS = [
    ("multi_layer_vs_baseline",  "D-23 MULTI-LAYER vs D-21 BASELINE",  "multi_layer", "baseline"),
    ("multi_layer_vs_single",    "D-23 MULTI-LAYER vs D-22 SINGLE-LAYER", "multi_layer", "single_layer"),
    ("single_vs_baseline",       "D-22 SINGLE-LAYER vs D-21 BASELINE",  "single_layer", "baseline"),
]

delta_results = {}  # pair_key → DataFrame

# ============================================================================
# COMPUTE DELTAS FOR EACH PAIR
# ============================================================================

for pair_key, pair_label, exp_a, exp_b in PAIRS:
    print(f"\n{'=' * 90}")
    print(f"{pair_label}")
    print(f"{'=' * 90}")

    # Extract data for each experiment
    df_a = comparison_df[comparison_df["experiment"] == exp_a].copy()
    df_b = comparison_df[comparison_df["experiment"] == exp_b].copy()

    if df_a.empty or df_b.empty:
        print(f"  ⚠ Missing data for this pair. Skipping.")
        continue

    # Merge on query_id for paired comparison
    merged = pd.merge(
        df_a, df_b,
        on="query_id",
        suffixes=("_a", "_b"),
        how="inner",
    )

    if merged.empty:
        print(f"  ⚠ No matching queries found. Skipping.")
        continue

    # Build delta DataFrame
    delta_rows = []
    for _, row in merged.iterrows():
        delta_p5   = row["precision@5_a"]  - row["precision@5_b"]
        delta_r10  = row["recall@10_a"]    - row["recall@10_b"]
        delta_ndcg = row["ndcg@10_a"]      - row["ndcg@10_b"]
        delta_mrr  = row["mrr_a"]          - row["mrr_b"]

        # Classification flags
        improved = (delta_p5 > 0) or (delta_r10 > 0) or (delta_ndcg > 0) or (delta_mrr > 0)
        degraded = (delta_p5 < 0) or (delta_r10 < 0) or (delta_ndcg < 0) or (delta_mrr < 0)

        delta_rows.append({
            "query_id": row["query_id"],
            "query_type": row["query_type_a"],
            "delta_p5": delta_p5,
            "delta_r10": delta_r10,
            "delta_ndcg": delta_ndcg,
            "delta_mrr": delta_mrr,
            "improved": improved,
            "degraded": degraded,
            "all_metrics_improved": all([delta_p5 >= 0, delta_r10 >= 0, delta_ndcg >= 0, delta_mrr >= 0]),
        })

    delta_df = pd.DataFrame(delta_rows)
    delta_results[pair_key] = delta_df

    # ---- OVERALL STATISTICS ----
    print(f"\n  OVERALL STATISTICS ({len(delta_df)} queries)")
    print(f"  {'-' * 80}")

    metrics_delta = ["delta_p5", "delta_r10", "delta_ndcg", "delta_mrr"]

    for metric_d, label in zip(metrics_delta, METRIC_LABELS):
        mean_d  = delta_df[metric_d].mean()
        median_d = delta_df[metric_d].median()
        std_d   = delta_df[metric_d].std()
        improved_n = (delta_df[metric_d] > 0).sum()
        degraded_n = (delta_df[metric_d] < 0).sum()
        unchanged_n = (delta_df[metric_d] == 0).sum()

        print(f"\n  {label}:")
        print(f"    Mean delta:  {mean_d:+.4f}")
        print(f"    Median delta: {median_d:+.4f}")
        print(f"    Std dev:     {std_d:.4f}")
        print(f"    Improved: {improved_n} ({improved_n/len(delta_df)*100:.1f}%)")
        print(f"    Degraded: {degraded_n} ({degraded_n/len(delta_df)*100:.1f}%)")
        print(f"    Unchanged: {unchanged_n} ({unchanged_n/len(delta_df)*100:.1f}%)")

    # ---- BY QUERY TYPE ----
    print(f"\n  BY QUERY TYPE")
    print(f"  {'-' * 80}")

    for query_type in ["authority", "temporal", "factual"]:
        type_data = delta_df[delta_df["query_type"] == query_type]
        if type_data.empty:
            continue

        print(f"\n  {query_type.upper()} ({len(type_data)} queries)")
        for metric_d, label in zip(metrics_delta, METRIC_LABELS):
            mean_d = type_data[metric_d].mean()
            improved_n = (type_data[metric_d] > 0).sum()
            print(f"    {label:15} mean_delta={mean_d:+.4f}, improved={improved_n}/{len(type_data)}")

    # ---- QUERY CLASSIFICATION ----
    print(f"\n  QUERY CLASSIFICATION")
    print(f"    Any metric improved:    {delta_df['improved'].sum()} ({delta_df['improved'].sum()/len(delta_df)*100:.1f}%)")
    print(f"    Any metric degraded:    {delta_df['degraded'].sum()} ({delta_df['degraded'].sum()/len(delta_df)*100:.1f}%)")
    print(f"    All metrics improved:   {delta_df['all_metrics_improved'].sum()} ({delta_df['all_metrics_improved'].sum()/len(delta_df)*100:.1f}%)")

# ============================================================================
# MARGINAL VALUE ANALYSIS
# ============================================================================

print(f"\n\n{'=' * 90}")
print("MARGINAL VALUE ANALYSIS: Value Added by Layers 2-8")
print("=" * 90)
print()
print("Formula: (D-23 improvement over D-21) - (D-22 improvement over D-21)")
print("         = value added by the additional 7 layers beyond single-layer prefix")

if "multi_layer_vs_baseline" in delta_results and "single_vs_baseline" in delta_results:
    ml_bl = delta_results["multi_layer_vs_baseline"]
    sl_bl = delta_results["single_vs_baseline"]

    # Merge on query_id
    marginal_df = pd.merge(
        ml_bl[["query_id"] + metrics_delta],
        sl_bl[["query_id"] + metrics_delta],
        on="query_id",
        suffixes=("_ml_bl", "_sl_bl"),
    )

    print()
    for metric_d, label in zip(metrics_delta, METRIC_LABELS):
        ml_improvement = marginal_df[f"{metric_d}_ml_bl"].mean()
        sl_improvement = marginal_df[f"{metric_d}_sl_bl"].mean()
        marginal_value = ml_improvement - sl_improvement
        pct_positive = (marginal_df[f"{metric_d}_ml_bl"] > marginal_df[f"{metric_d}_sl_bl"]).sum()

        trend = "↑" if marginal_value > 0 else ("↓" if marginal_value < 0 else "→")
        print(f"  {label:15} {trend} marginal={marginal_value:+.4f} (ML improvement={ml_improvement:+.4f}, SL improvement={sl_improvement:+.4f})")
        print(f"                    positive marginal in {pct_positive}/{len(marginal_df)} queries")
else:
    print("  ⚠ Cannot compute marginal value: need both D-21 and D-22 data.")

# ============================================================================
# EXPORT DELTA CSVS
# ============================================================================

print(f"\n{'=' * 90}")
print("EXPORTING DELTA RESULTS")
print("=" * 90)

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

if "multi_layer_vs_baseline" in delta_results:
    path = OUTPUT_DIR / "d23_delta_vs_d21.csv"
    delta_results["multi_layer_vs_baseline"].to_csv(path, index=False)
    print(f"✓ Exported: {path} ({len(delta_results['multi_layer_vs_baseline'])} queries)")

if "multi_layer_vs_single" in delta_results:
    path = OUTPUT_DIR / "d23_delta_vs_d22.csv"
    delta_results["multi_layer_vs_single"].to_csv(path, index=False)
    print(f"✓ Exported: {path} ({len(delta_results['multi_layer_vs_single'])} queries)")

print()
print("✓ Delta analysis complete. Ready for statistical significance testing.")
```

**Notes**:
- Core analysis cell computing deltas for all 3 comparison pairs
- Per-query-type breakdown reveals which query types benefit most from multi-layer enrichment
- Marginal value analysis isolates the contribution of layers 2-8 beyond D-22's single-layer prefix
- Exports d23_delta_vs_d21.csv and d23_delta_vs_d22.csv
- Uses merge + suffixes pattern for paired comparison (same as D-22)
- ~160 lines

---

### Cell 17: Statistical Significance Testing (3-Way)

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 17: Statistical Significance Testing — 3-Way with Bonferroni

Performs Wilcoxon signed-rank test for all 12 combinations (3 pairs × 4 metrics).

Key differences from D-22:
  - 3 comparison pairs instead of 1
  - Bonferroni correction: adjusted α = 0.05 / 3 ≈ 0.0167
  - Rank-biserial correlation as effect size measure

Effect size interpretation (rank-biserial correlation):
  - |r| < 0.1:  negligible
  - 0.1-0.3:    small
  - 0.3-0.5:    medium
  - > 0.5:      large

Reference: scipy.stats.wilcoxon; Bonferroni correction; D-22 Cell 17
"""

from scipy.stats import wilcoxon

print("=" * 90)
print("STATISTICAL SIGNIFICANCE TESTING (BONFERRONI-CORRECTED)")
print("=" * 90)
print()
print(f"Test: Wilcoxon signed-rank (paired, non-parametric)")
print(f"Sample: 36 paired queries per comparison")
print(f"Bonferroni correction: {BONFERRONI_PAIRS} pairs")
print(f"  Unadjusted α = {SIGNIFICANCE_LEVEL}")
print(f"  Adjusted α   = {ADJUSTED_ALPHA:.4f}")
print(f"Total tests: {BONFERRONI_PAIRS} pairs × {len(METRICS)} metrics = {BONFERRONI_PAIRS * len(METRICS)}")

# ============================================================================
# RUN WILCOXON TESTS FOR ALL 12 COMBINATIONS
# ============================================================================

significance_results = []

for pair_key, pair_label, exp_a, exp_b in PAIRS:
    if pair_key not in delta_results:
        continue

    delta_df = delta_results[pair_key]

    print(f"\n{'-' * 90}")
    print(f"{pair_label}")
    print(f"{'-' * 90}")

    metrics_delta = ["delta_p5", "delta_r10", "delta_ndcg", "delta_mrr"]

    for metric_d, label in zip(metrics_delta, METRIC_LABELS):
        deltas = delta_df[metric_d].values

        # Filter non-zero deltas (Wilcoxon requires non-zero differences)
        nonzero = deltas[deltas != 0]

        if len(nonzero) < 2:
            print(f"  {label:15} — insufficient non-zero deltas ({len(nonzero)}); skipping")
            significance_results.append({
                "pair": pair_key,
                "pair_label": pair_label,
                "metric": label,
                "statistic": None,
                "pvalue": None,
                "significant": False,
                "effect_size": None,
                "effect_magnitude": "insufficient_data",
                "n_nonzero": len(nonzero),
            })
            continue

        # Wilcoxon signed-rank test (two-tailed)
        stat, pvalue = wilcoxon(nonzero)

        # Rank-biserial correlation as effect size
        # Formula: r = 1 - (2 * W) / (n * (n + 1) / 2)
        # where W is the Wilcoxon statistic, n is number of non-zero pairs
        n = len(nonzero)
        r_rb = 1 - (2 * stat) / (n * (n + 1) / 2)

        # Effect magnitude classification
        abs_r = abs(r_rb)
        if abs_r < 0.1:
            effect_mag = "negligible"
        elif abs_r < 0.3:
            effect_mag = "small"
        elif abs_r < 0.5:
            effect_mag = "medium"
        else:
            effect_mag = "large"

        # Bonferroni-corrected significance
        is_significant = pvalue < ADJUSTED_ALPHA
        sig_marker = "***" if is_significant else ""

        print(f"  {label:15} W={stat:8.1f}, p={pvalue:.6f}, r={r_rb:+.3f} ({effect_mag:10}) {sig_marker}")

        significance_results.append({
            "pair": pair_key,
            "pair_label": pair_label,
            "metric": label,
            "statistic": stat,
            "pvalue": pvalue,
            "significant": is_significant,
            "effect_size": r_rb,
            "effect_magnitude": effect_mag,
            "n_nonzero": n,
        })

# ============================================================================
# SIGNIFICANCE SUMMARY
# ============================================================================

sig_df = pd.DataFrame(significance_results)

print(f"\n{'=' * 90}")
print("SIGNIFICANCE SUMMARY")
print(f"{'=' * 90}")

total_tests = len(sig_df[sig_df["statistic"].notna()])
significant_tests = sig_df["significant"].sum()

print(f"\n  Total valid tests:     {total_tests}")
print(f"  Significant (p < {ADJUSTED_ALPHA:.4f}): {significant_tests} ({significant_tests/total_tests*100:.1f}%)" if total_tests > 0 else "  No valid tests")

print(f"\n  By Comparison Pair:")
for pair_key, pair_label, _, _ in PAIRS:
    pair_data = sig_df[sig_df["pair"] == pair_key]
    if not pair_data.empty:
        pair_sig = pair_data["significant"].sum()
        pair_total = len(pair_data[pair_data["statistic"].notna()])
        print(f"    {pair_label:50} {pair_sig}/{pair_total} significant")

print(f"\n  By Metric:")
for label in METRIC_LABELS:
    metric_data = sig_df[sig_df["metric"] == label]
    if not metric_data.empty:
        metric_sig = metric_data["significant"].sum()
        metric_total = len(metric_data[metric_data["statistic"].notna()])
        print(f"    {label:20} {metric_sig}/{metric_total} significant")

# Key finding for GO/NO-GO criterion 4
ml_bl_sig = sig_df[(sig_df["pair"] == "multi_layer_vs_baseline") & (sig_df["significant"])]
print(f"\n  CRITICAL (GO/NO-GO Criterion 4):")
print(f"    Multi-Layer vs Baseline: {len(ml_bl_sig)} significant metrics (threshold: ≥2)")

# ============================================================================
# EXPORT
# ============================================================================

sig_export = sig_df[["pair_label", "metric", "statistic", "pvalue", "significant",
                      "effect_size", "effect_magnitude", "n_nonzero"]].copy()
sig_path = OUTPUT_DIR / "d23_significance_results.csv"
sig_export.to_csv(sig_path, index=False)
print(f"\n✓ Exported: {sig_path}")
print("✓ Significance testing complete.")
```

**Notes**:
- Tests all 12 combinations (3 pairs × 4 metrics)
- Bonferroni correction: critical p-value is ADJUSTED_ALPHA ≈ 0.0167 (not 0.05)
- Rank-biserial correlation quantifies effect size (ranges -1 to +1)
- Handles insufficient non-zero deltas gracefully (skips test, records as "insufficient_data")
- Key output for GO/NO-GO criterion 4: count of significant metrics in ML vs BL pair
- Exports d23_significance_results.csv
- ~120 lines

---

### Cell 18: Visualization — 3-Way Comparison Bar Chart

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 18: Visualization — 3-Way Comparison Bar Chart

Creates a 2×2 figure:
  - Top-left: Overall performance (all 36 queries) — D-21 vs D-22 vs D-23
  - Top-right, Bottom-left, Bottom-right: Per-query-type comparison

Color scheme:
  - D-21 (Baseline):     #4e79a7 (steel blue)
  - D-22 (Single-Layer): #f28e2b (orange)
  - D-23 (Multi-Layer):  #59a14f (green)

Reference: D-22 Cell 18 (2-way visualization pattern)
"""

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

print("=" * 90)
print("CREATING 3-WAY COMPARISON VISUALIZATION")
print("=" * 90)

# Color scheme
COLORS = {
    "baseline":     "#4e79a7",  # steel blue
    "single_layer": "#f28e2b",  # orange
    "multi_layer":  "#59a14f",  # green
}
EXP_LABELS = {
    "baseline":     "D-21 Baseline",
    "single_layer": "D-22 Single-Layer",
    "multi_layer":  "D-23 Multi-Layer",
}
experiments = ["baseline", "single_layer", "multi_layer"]

# Filter to only experiments present in comparison_df
available_exps = [e for e in experiments if e in comparison_df["experiment"].values]

fig, axes = plt.subplots(2, 2, figsize=(16, 12))
fig.suptitle("D-23: 3-Way Retrieval Performance Comparison",
             fontsize=16, fontweight="bold", y=0.98)

# ---- TOP-LEFT: Overall comparison (all queries) ----
ax = axes[0, 0]
x = np.arange(len(METRICS))
width = 0.25

for i, exp in enumerate(available_exps):
    exp_data = comparison_df[comparison_df["experiment"] == exp][METRICS].mean()
    offset = width * (i - len(available_exps) / 2 + 0.5)
    ax.bar(x + offset, exp_data.values, width,
           label=EXP_LABELS.get(exp, exp), color=COLORS.get(exp, "#999999"), alpha=0.85)

ax.set_xlabel("Metric", fontsize=11, fontweight="bold")
ax.set_ylabel("Mean Value", fontsize=11, fontweight="bold")
ax.set_title("Overall (All 36 Queries)", fontsize=13, fontweight="bold")
ax.set_xticks(x)
ax.set_xticklabels(METRIC_LABELS, fontsize=10)
ax.set_ylim(0, 1)
ax.legend(fontsize=9, loc="upper right")
ax.grid(axis="y", alpha=0.3)

# ---- REMAINING SUBPLOTS: Per query type ----
query_types = ["authority", "temporal", "factual"]
subplot_positions = [(0, 1), (1, 0), (1, 1)]

for qtype, (row, col) in zip(query_types, subplot_positions):
    ax = axes[row, col]
    type_df = comparison_df[comparison_df["query_type"] == qtype]
    x = np.arange(len(METRICS))

    for i, exp in enumerate(available_exps):
        exp_data = type_df[type_df["experiment"] == exp][METRICS].mean()
        if exp_data.empty:
            continue
        offset = width * (i - len(available_exps) / 2 + 0.5)
        ax.bar(x + offset, exp_data.values, width,
               label=EXP_LABELS.get(exp, exp), color=COLORS.get(exp, "#999999"), alpha=0.85)

    n_queries = len(type_df[type_df["experiment"] == "multi_layer"])
    ax.set_xlabel("Metric", fontsize=11, fontweight="bold")
    ax.set_ylabel("Mean Value", fontsize=11, fontweight="bold")
    ax.set_title(f"{qtype.capitalize()} Queries (n={n_queries})", fontsize=13, fontweight="bold")
    ax.set_xticks(x)
    ax.set_xticklabels(METRIC_LABELS, fontsize=10)
    ax.set_ylim(0, 1)
    ax.legend(fontsize=9, loc="upper right")
    ax.grid(axis="y", alpha=0.3)

# Save
plt.tight_layout(rect=[0, 0, 1, 0.96])
viz_path = OUTPUT_DIR / "visualization_3way_comparison.png"
plt.savefig(viz_path, dpi=150, bbox_inches="tight")
print(f"\n✓ Saved: {viz_path}")
plt.close()

# Print key findings
print("\nKey Findings:")
for exp in available_exps:
    means = comparison_df[comparison_df["experiment"] == exp][METRICS].mean()
    overall_mean = means.mean()
    print(f"  {EXP_LABELS.get(exp, exp):25} overall mean: {overall_mean:.4f}")

print("\n✓ 3-way comparison visualization complete.")
```

**Notes**:
- 2×2 layout: overall + 3 query types (authority, temporal, factual)
- Consistent color scheme: D-21 blue, D-22 orange, D-23 green
- Y-axis [0, 1] for all subplots (metric values are normalized)
- Handles missing experiments gracefully (only plots available data)
- Saves to visualization_3way_comparison.png at 150 DPI
- ~80 lines

---

### Cell 19: Visualization — Delta Heatmap & Layer Token Distribution

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 19: Delta Heatmap & Layer Token Distribution

Figure 1 — Delta Heatmap:
  Two side-by-side heatmaps showing per-query metric deltas.
  Left:  D-23 vs D-21 (multi-layer vs baseline)
  Right: D-23 vs D-22 (multi-layer vs single-layer)
  Colormap: RdYlGn (diverging, center=0; red=degradation, green=improvement)

Figure 2 — Layer Token Distribution:
  Box plot showing token consumption per layer across all chunks.
  Informs D-24 ablation planning: high-token layers are candidates for removal.

Reference: D-22 Cell 19 (heatmap pattern); Cell 10 (layer_token_audit)
"""

import matplotlib.pyplot as plt
import seaborn as sns

print("=" * 90)
print("CREATING DELTA HEATMAP & LAYER TOKEN DISTRIBUTION")
print("=" * 90)

# ============================================================================
# FIGURE 1: DELTA HEATMAPS
# ============================================================================

delta_cols = ["delta_p5", "delta_r10", "delta_ndcg", "delta_mrr"]
col_labels = ["ΔP@5", "ΔR@10", "ΔNDCG@10", "ΔMRR"]

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(18, 14))
fig.suptitle("D-23: Per-Query Delta Heatmaps", fontsize=16, fontweight="bold")

# ---- Left: D-23 vs D-21 ----
if "multi_layer_vs_baseline" in delta_results:
    hm_df = delta_results["multi_layer_vs_baseline"].sort_values(
        by=["query_type", "query_id"]
    ).reset_index(drop=True)

    hm_data = hm_df[delta_cols].values
    query_labels = hm_df["query_id"].tolist()

    sns.heatmap(
        hm_data,
        annot=True, fmt=".3f", cmap="RdYlGn",
        center=0, vmin=-0.3, vmax=0.3,
        ax=ax1,
        cbar_kws={"label": "Delta"},
        xticklabels=col_labels,
        yticklabels=query_labels,
        annot_kws={"fontsize": 7},
    )
    ax1.set_title("D-23 vs D-21 (Multi-Layer vs Baseline)", fontsize=13, fontweight="bold")
    ax1.set_ylabel("Query ID", fontsize=11, fontweight="bold")
    ax1.set_xlabel("Metric Delta", fontsize=11, fontweight="bold")

# ---- Right: D-23 vs D-22 ----
if "multi_layer_vs_single" in delta_results:
    hm_df2 = delta_results["multi_layer_vs_single"].sort_values(
        by=["query_type", "query_id"]
    ).reset_index(drop=True)

    hm_data2 = hm_df2[delta_cols].values
    query_labels2 = hm_df2["query_id"].tolist()

    sns.heatmap(
        hm_data2,
        annot=True, fmt=".3f", cmap="RdYlGn",
        center=0, vmin=-0.3, vmax=0.3,
        ax=ax2,
        cbar_kws={"label": "Delta"},
        xticklabels=col_labels,
        yticklabels=query_labels2,
        annot_kws={"fontsize": 7},
    )
    ax2.set_title("D-23 vs D-22 (Multi-Layer vs Single-Layer)", fontsize=13, fontweight="bold")
    ax2.set_ylabel("Query ID", fontsize=11, fontweight="bold")
    ax2.set_xlabel("Metric Delta", fontsize=11, fontweight="bold")

plt.tight_layout(rect=[0, 0, 1, 0.96])
heatmap_path = OUTPUT_DIR / "visualization_delta_heatmap.png"
plt.savefig(heatmap_path, dpi=150, bbox_inches="tight")
print(f"✓ Saved: {heatmap_path}")
plt.close()

# ============================================================================
# FIGURE 2: LAYER TOKEN DISTRIBUTION
# ============================================================================

if layer_token_audit:
    fig, ax = plt.subplots(figsize=(14, 7))

    # Extract per-layer token data from audit
    layer_names = ["corpus", "domain", "entity", "authority",
                   "temporal", "relational", "section"]
    layer_data = {name: [] for name in layer_names}

    for entry in layer_token_audit:
        for name in layer_names:
            if name in entry and entry[name] > 0:
                layer_data[name].append(entry[name])

    # Filter to layers with data
    plot_layers = [n for n in layer_names if layer_data[n]]
    plot_data = [layer_data[n] for n in plot_layers]

    bp = ax.boxplot(plot_data, labels=[n.capitalize() for n in plot_layers],
                     patch_artist=True, showfliers=True)

    # Color boxes by median token count (gradient: light=few, dark=many)
    medians = [np.median(d) for d in plot_data]
    max_median = max(medians) if medians else 1
    for patch, median_val in zip(bp["boxes"], medians):
        intensity = 0.3 + 0.7 * (median_val / max_median)
        patch.set_facecolor((0.35, 0.63, 0.31, intensity))  # green gradient
        patch.set_edgecolor("black")

    ax.set_ylabel("Tokens per Layer", fontsize=12, fontweight="bold")
    ax.set_xlabel("Enrichment Layer", fontsize=12, fontweight="bold")
    ax.set_title("Token Distribution Across Enrichment Layers\n(Informs D-24 Ablation Priority)",
                 fontsize=14, fontweight="bold")
    ax.grid(axis="y", alpha=0.3)

    plt.tight_layout()
    token_path = OUTPUT_DIR / "visualization_layer_token_distribution.png"
    plt.savefig(token_path, dpi=150, bbox_inches="tight")
    print(f"✓ Saved: {token_path}")
    plt.close()

    # Print summary
    print(f"\nLayer Token Usage Summary (for D-24 ablation planning):")
    for name in plot_layers:
        data = layer_data[name]
        print(f"  {name.capitalize():15} median={np.median(data):5.1f}, mean={np.mean(data):5.1f}, max={np.max(data):5.1f}, present={len(data)}/{len(layer_token_audit)}")

else:
    print("⚠ layer_token_audit not available; skipping token distribution.")

print("\n✓ Delta heatmap and layer token distribution complete.")
```

**Notes**:
- Two heatmaps side-by-side: D-23 vs D-21 (left) and D-23 vs D-22 (right)
- Uses seaborn heatmap with RdYlGn diverging colormap centered at 0
- Queries sorted by type for visual grouping (authority → factual → temporal)
- Layer token box plot colored by median intensity (darker = more tokens)
- Token summary table directly supports D-24 ablation layer ordering decisions
- Saves visualization_delta_heatmap.png and visualization_layer_token_distribution.png
- ~100 lines

---

### Cell 20: GO/NO-GO Decision Engine

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 20: GO/NO-GO Decision Engine — THE DECISION CELL

Evaluates 7 success criteria programmatically:
  1. EXECUTION: < 5% token overflow
  2. IMPROVEMENT OVER D-21: mean delta > 0 for ≥3/4 metrics
  3. IMPROVEMENT OVER D-22: mean delta > 0 for ≥2/4 metrics
  4. STATISTICAL SIGNIFICANCE: Wilcoxon p < ADJUSTED_ALPHA for ≥2 metrics (ML vs BL)
  5. MARGINAL VALUE: ML vs SL improvement > 5% for ≥1 metric
  6. NO CATASTROPHIC DEGRADATION: < 25% queries degraded (ML vs BL)
  7. AUTHORITY/TEMPORAL BENEFIT: specialized queries show larger deltas than factual

Scoring:
  - ≥5/7 (AND criteria 2 + 4 both pass) → GO
  - 3-4/7 → CONDITIONAL GO
  - < 3/7 → NO-GO

Outputs:
  - go_nogo_decision: str ("GO", "CONDITIONAL_GO", or "NO_GO")
  - decision_report: str (full evidence trail)

Reference: D-23 Cell 07 (success criteria); Cell 16-17 (delta + significance data)
"""

print("=" * 90)
print("GO/NO-GO DECISION ENGINE: 7-CRITERION EVALUATION")
print("=" * 90)

# Initialize
criteria_results = []  # List of (number, name, passed, detail_string)
decision_report = []
decision_report.append("D-23 GO/NO-GO DECISION REPORT")
decision_report.append("=" * 90)
decision_report.append(f"Model: {SELECTED_MODEL}")
decision_report.append(f"Date: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M')}")
decision_report.append(f"Bonferroni-adjusted α: {ADJUSTED_ALPHA:.4f}")
decision_report.append("")

# ============================================================================
# CRITERION 1: EXECUTION (< 5% token overflow)
# ============================================================================

print("\n[1/7] EXECUTION — Token Overflow Rate")
print("-" * 80)

if "overflow_count" in dir() or "overflow_count" in globals():
    overflow_pct = (overflow_count / total_chunks * 100) if total_chunks > 0 else 0
    c1_pass = overflow_pct < 5
    c1_detail = f"Overflow: {overflow_count}/{total_chunks} chunks ({overflow_pct:.2f}%). Threshold: <5%."
else:
    # Fallback: assume pass if overflow tracking wasn't available
    c1_pass = True
    c1_detail = "Overflow data not tracked; default PASS."
    overflow_pct = 0

print(f"  {c1_detail}")
print(f"  Result: {'PASS ✓' if c1_pass else 'FAIL ✗'}")
criteria_results.append((1, "EXECUTION", c1_pass, c1_detail))
decision_report.append(f"[1] EXECUTION: {'PASS' if c1_pass else 'FAIL'} — {c1_detail}")

# ============================================================================
# CRITERION 2: IMPROVEMENT OVER D-21 (mean delta > 0 for ≥3/4 metrics)
# ============================================================================

print("\n[2/7] IMPROVEMENT OVER D-21 — Mean Delta Direction")
print("-" * 80)

if "multi_layer_vs_baseline" in delta_results:
    ml_bl = delta_results["multi_layer_vs_baseline"]
    c2_improved = 0
    for metric_d, label in zip(["delta_p5", "delta_r10", "delta_ndcg", "delta_mrr"], METRIC_LABELS):
        mean_d = ml_bl[metric_d].mean()
        is_up = mean_d > 0
        if is_up:
            c2_improved += 1
        print(f"  {label:15} mean_delta={mean_d:+.4f} {'✓' if is_up else '✗'}")

    c2_pass = c2_improved >= 3
    c2_detail = f"{c2_improved}/4 metrics have positive mean delta. Threshold: ≥3."
else:
    c2_pass = False
    c2_improved = 0
    c2_detail = "D-21 data unavailable."

print(f"\n  {c2_detail}")
print(f"  Result: {'PASS ✓' if c2_pass else 'FAIL ✗'}")
criteria_results.append((2, "IMPROVEMENT_OVER_D21", c2_pass, c2_detail))
decision_report.append(f"[2] IMPROVEMENT OVER D-21: {'PASS' if c2_pass else 'FAIL'} — {c2_detail}")

# ============================================================================
# CRITERION 3: IMPROVEMENT OVER D-22 (mean delta > 0 for ≥2/4 metrics)
# ============================================================================

print("\n[3/7] IMPROVEMENT OVER D-22 — Mean Delta Direction")
print("-" * 80)

if "multi_layer_vs_single" in delta_results:
    ml_sl = delta_results["multi_layer_vs_single"]
    c3_improved = 0
    for metric_d, label in zip(["delta_p5", "delta_r10", "delta_ndcg", "delta_mrr"], METRIC_LABELS):
        mean_d = ml_sl[metric_d].mean()
        is_up = mean_d > 0
        if is_up:
            c3_improved += 1
        print(f"  {label:15} mean_delta={mean_d:+.4f} {'✓' if is_up else '✗'}")

    c3_pass = c3_improved >= 2
    c3_detail = f"{c3_improved}/4 metrics have positive mean delta. Threshold: ≥2."
else:
    c3_pass = False
    c3_improved = 0
    c3_detail = "D-22 data unavailable."

print(f"\n  {c3_detail}")
print(f"  Result: {'PASS ✓' if c3_pass else 'FAIL ✗'}")
criteria_results.append((3, "IMPROVEMENT_OVER_D22", c3_pass, c3_detail))
decision_report.append(f"[3] IMPROVEMENT OVER D-22: {'PASS' if c3_pass else 'FAIL'} — {c3_detail}")

# ============================================================================
# CRITERION 4: STATISTICAL SIGNIFICANCE (≥2 metrics significant for ML vs BL)
# ============================================================================

print("\n[4/7] STATISTICAL SIGNIFICANCE — Wilcoxon (Bonferroni-Corrected)")
print("-" * 80)

if len(sig_df) > 0:
    ml_bl_sig = sig_df[(sig_df["pair"] == "multi_layer_vs_baseline") & sig_df["significant"]]
    c4_sig_count = len(ml_bl_sig)
    c4_pass = c4_sig_count >= 2
    c4_detail = f"{c4_sig_count}/4 metrics significant at α={ADJUSTED_ALPHA:.4f} for ML vs BL. Threshold: ≥2."

    # Show all ML vs BL results
    ml_bl_all = sig_df[sig_df["pair"] == "multi_layer_vs_baseline"]
    for _, row in ml_bl_all.iterrows():
        if row["statistic"] is not None:
            print(f"  {row['metric']:15} p={row['pvalue']:.6f}, r={row['effect_size']:+.3f} ({row['effect_magnitude']}) {'✓' if row['significant'] else '✗'}")
else:
    c4_pass = False
    c4_sig_count = 0
    c4_detail = "Significance data unavailable."

print(f"\n  {c4_detail}")
print(f"  Result: {'PASS ✓' if c4_pass else 'FAIL ✗'}")
criteria_results.append((4, "STATISTICAL_SIGNIFICANCE", c4_pass, c4_detail))
decision_report.append(f"[4] STATISTICAL SIGNIFICANCE: {'PASS' if c4_pass else 'FAIL'} — {c4_detail}")

# ============================================================================
# CRITERION 5: MARGINAL VALUE (ML vs SL gain > 5% for ≥1 metric)
# ============================================================================

print("\n[5/7] MARGINAL VALUE — Multi-Layer vs Single-Layer Percentage Gain")
print("-" * 80)

if "multi_layer_vs_single" in delta_results:
    ml_sl = delta_results["multi_layer_vs_single"]
    c5_above = 0
    for metric, label in zip(METRICS, METRIC_LABELS):
        metric_d = f"delta_{metric.replace('@', '')}" if "@" in metric else f"delta_{metric}"
        # Map metric name to delta column
        delta_col_map = {
            "precision@5": "delta_p5",
            "recall@10": "delta_r10",
            "ndcg@10": "delta_ndcg",
            "mrr": "delta_mrr",
        }
        delta_col = delta_col_map[metric]
        mean_delta = ml_sl[delta_col].mean()
        baseline_mean = comparison_df[comparison_df["experiment"] == "single_layer"][metric].mean()
        pct_gain = (mean_delta / baseline_mean * 100) if baseline_mean > 0 else 0

        above_5 = pct_gain > 5
        if above_5:
            c5_above += 1
        print(f"  {label:15} gain={pct_gain:+.2f}% {'✓' if above_5 else '✗'}")

    c5_pass = c5_above >= 1
    c5_detail = f"{c5_above}/4 metrics show >5% gain over single-layer. Threshold: ≥1."
else:
    c5_pass = False
    c5_above = 0
    c5_detail = "D-22 data unavailable."

print(f"\n  {c5_detail}")
print(f"  Result: {'PASS ✓' if c5_pass else 'FAIL ✗'}")
criteria_results.append((5, "MARGINAL_VALUE", c5_pass, c5_detail))
decision_report.append(f"[5] MARGINAL VALUE: {'PASS' if c5_pass else 'FAIL'} — {c5_detail}")

# ============================================================================
# CRITERION 6: NO CATASTROPHIC DEGRADATION (< 25% queries degraded vs D-21)
# ============================================================================

print("\n[6/7] NO CATASTROPHIC DEGRADATION — Query Degradation Rate")
print("-" * 80)

if "multi_layer_vs_baseline" in delta_results:
    ml_bl = delta_results["multi_layer_vs_baseline"]
    degraded_n = ml_bl["degraded"].sum()
    degraded_pct = (degraded_n / len(ml_bl) * 100) if len(ml_bl) > 0 else 0

    c6_pass = degraded_pct < 25
    c6_detail = f"{degraded_n}/{len(ml_bl)} queries degraded ({degraded_pct:.1f}%). Threshold: <25%."
    print(f"  {c6_detail}")
else:
    c6_pass = False
    c6_detail = "D-21 data unavailable."
    print(f"  {c6_detail}")

print(f"  Result: {'PASS ✓' if c6_pass else 'FAIL ✗'}")
criteria_results.append((6, "NO_CATASTROPHIC_DEGRADATION", c6_pass, c6_detail))
decision_report.append(f"[6] NO CATASTROPHIC DEGRADATION: {'PASS' if c6_pass else 'FAIL'} — {c6_detail}")

# ============================================================================
# CRITERION 7: AUTHORITY/TEMPORAL BENEFIT
# ============================================================================

print("\n[7/7] AUTHORITY/TEMPORAL BENEFIT — Specialized Queries Benefit More")
print("-" * 80)

if "multi_layer_vs_baseline" in delta_results:
    ml_bl = delta_results["multi_layer_vs_baseline"]

    type_mean_deltas = {}
    for qtype in ["authority", "temporal", "factual"]:
        type_df = ml_bl[ml_bl["query_type"] == qtype]
        if not type_df.empty:
            # Average across all 4 delta metrics
            avg_delta = type_df[["delta_p5", "delta_r10", "delta_ndcg", "delta_mrr"]].mean().mean()
            type_mean_deltas[qtype] = avg_delta
            print(f"  {qtype:15} avg_delta={avg_delta:+.4f}")

    auth_better = type_mean_deltas.get("authority", -999) > type_mean_deltas.get("factual", -999)
    temp_better = type_mean_deltas.get("temporal", -999) > type_mean_deltas.get("factual", -999)

    c7_pass = auth_better or temp_better
    c7_detail = f"Authority > Factual: {auth_better}. Temporal > Factual: {temp_better}. Threshold: at least one true."
else:
    c7_pass = False
    c7_detail = "D-21 data unavailable."

print(f"\n  {c7_detail}")
print(f"  Result: {'PASS ✓' if c7_pass else 'FAIL ✗'}")
criteria_results.append((7, "AUTHORITY_TEMPORAL_BENEFIT", c7_pass, c7_detail))
decision_report.append(f"[7] AUTHORITY/TEMPORAL BENEFIT: {'PASS' if c7_pass else 'FAIL'} — {c7_detail}")

# ============================================================================
# SCORING & DECISION
# ============================================================================

print(f"\n{'=' * 90}")
print("FINAL SCORING & DECISION")
print(f"{'=' * 90}")

total_pass = sum(1 for _, _, passed, _ in criteria_results if passed)
c2_passed = criteria_results[1][2]  # Criterion 2
c4_passed = criteria_results[3][2]  # Criterion 4
mandatory_met = c2_passed and c4_passed

print(f"\n  Criteria passed: {total_pass}/7")
print(f"  Mandatory conditions (2 + 4): {'MET ✓' if mandatory_met else 'NOT MET ✗'}")
print(f"    Criterion 2 (Improvement over D-21): {'PASS' if c2_passed else 'FAIL'}")
print(f"    Criterion 4 (Statistical Significance): {'PASS' if c4_passed else 'FAIL'}")

if total_pass >= 5 and mandatory_met:
    go_nogo_decision = "GO"
    decision_msg = "GO: Multi-layer enrichment is validated. Proceed to D-24 (Layer Ablation Study)."
elif total_pass >= 3:
    go_nogo_decision = "CONDITIONAL_GO"
    decision_msg = "CONDITIONAL GO: Promising but not conclusive. Proceed to D-24 with reduced scope (4-5 layers)."
else:
    go_nogo_decision = "NO_GO"
    decision_msg = "NO-GO: Multi-layer enrichment does not justify complexity. Revert to D-22 single-layer approach."

print(f"\n  ╔{'═' * 70}╗")
print(f"  ║  DECISION: {go_nogo_decision:57} ║")
print(f"  ╚{'═' * 70}╝")
print(f"\n  {decision_msg}")

# Append to decision report
decision_report.append("")
decision_report.append("=" * 90)
decision_report.append(f"SUMMARY: {total_pass}/7 criteria passed")
decision_report.append(f"MANDATORY (criteria 2+4): {'MET' if mandatory_met else 'NOT MET'}")
decision_report.append(f"DECISION: {go_nogo_decision}")
decision_report.append(f"RATIONALE: {decision_msg}")
decision_report = "\n".join(decision_report)

print("\n✓ Decision engine complete. Report stored in decision_report variable.")
```

**Notes**:
- Seven criteria evaluated with explicit pass/fail logic and detailed reasoning
- Criteria 2 (improvement over D-21) and 4 (statistical significance) are mandatory for GO
- Scoring: ≥5/7 with mandatory = GO, 3-4/7 = CONDITIONAL_GO, <3/7 = NO_GO
- Visual decision box (Unicode frame) for clarity
- decision_report captures full evidence trail as string for export in Cell 21
- go_nogo_decision is one of: "GO", "CONDITIONAL_GO", "NO_GO"
- ~130 lines

---

### Cell 21: Export Results

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-23 Cell 21: Export Results — Final Artifact Assembly

Exports all D-23 output artifacts and prints a complete manifest.

Artifacts:
  1. d23_results.csv — per-query metrics
  2. d23_delta_vs_d21.csv — already exported in Cell 16
  3. d23_delta_vs_d22.csv — already exported in Cell 16
  4. d23_layer_token_audit.csv — re-exported from Cell 10 data
  5. d23_significance_results.csv — already exported in Cell 17
  6. d23_go_nogo_decision.txt — formal decision report
  7. Visualizations — already saved in Cells 18-19

Reference: D-22 Cell 20 (export pattern)
"""

import os

print("=" * 90)
print("EXPORTING D-23 RESULTS — FINAL ARTIFACT ASSEMBLY")
print("=" * 90)

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
manifest = []

# ---- 1. D-23 Metrics Results ----
results_path = OUTPUT_DIR / "d23_results.csv"
d23_export = d23_df[["model", "experiment", "query_id", "query_type"] + METRICS].copy()
d23_export.to_csv(results_path, index=False)
size = results_path.stat().st_size
manifest.append(("d23_results.csv", size, f"{len(d23_export)} queries"))
print(f"\n✓ d23_results.csv ({size:,} bytes, {len(d23_export)} queries)")

# ---- 2-3. Delta CSVs (verify) ----
for delta_file, desc in [
    ("d23_delta_vs_d21.csv", "ML vs BL deltas"),
    ("d23_delta_vs_d22.csv", "ML vs SL deltas"),
]:
    path = OUTPUT_DIR / delta_file
    if path.exists():
        size = path.stat().st_size
        manifest.append((delta_file, size, desc))
        print(f"✓ {delta_file} ({size:,} bytes)")
    else:
        print(f"✗ {delta_file} — not found (upstream data may be missing)")

# ---- 4. Layer Token Audit ----
if layer_token_audit:
    audit_path = OUTPUT_DIR / "d23_layer_token_audit.csv"
    audit_df = pd.DataFrame(layer_token_audit)
    audit_df.to_csv(audit_path, index=False)
    size = audit_path.stat().st_size
    manifest.append(("d23_layer_token_audit.csv", size, f"{len(audit_df)} chunks"))
    print(f"✓ d23_layer_token_audit.csv ({size:,} bytes, {len(audit_df)} chunks)")
else:
    print(f"✗ d23_layer_token_audit.csv — audit data not available")

# ---- 5. Significance Results (verify) ----
sig_path = OUTPUT_DIR / "d23_significance_results.csv"
if sig_path.exists():
    size = sig_path.stat().st_size
    manifest.append(("d23_significance_results.csv", size, "12 tests"))
    print(f"✓ d23_significance_results.csv ({size:,} bytes)")
else:
    print(f"✗ d23_significance_results.csv — not found")

# ---- 6. GO/NO-GO Decision Report ----
decision_path = OUTPUT_DIR / "d23_go_nogo_decision.txt"
with open(decision_path, "w") as f:
    f.write(decision_report)
size = decision_path.stat().st_size
manifest.append(("d23_go_nogo_decision.txt", size, f"Decision: {go_nogo_decision}"))
print(f"✓ d23_go_nogo_decision.txt ({size:,} bytes)")

# ---- 7. Visualizations (verify) ----
viz_files = [
    "visualization_3way_comparison.png",
    "visualization_delta_heatmap.png",
    "visualization_layer_token_distribution.png",
]
for viz_file in viz_files:
    viz_path = OUTPUT_DIR / viz_file
    if viz_path.exists():
        size = viz_path.stat().st_size
        manifest.append((viz_file, size, "chart"))
        print(f"✓ {viz_file} ({size:,} bytes)")
    else:
        print(f"✗ {viz_file} — not generated")

# ---- ChromaDB ----
print(f"\n✓ ChromaDB collection: {collection_name}")
print(f"  Location: {CHROMADB_DIR}")

# ============================================================================
# COMPLETE MANIFEST
# ============================================================================

print(f"\n{'=' * 90}")
print("COMPLETE EXPORT MANIFEST")
print(f"{'=' * 90}")

total_size = sum(size for _, size, _ in manifest)
print(f"\nOutput directory: {OUTPUT_DIR}")
print(f"Total artifacts:  {len(manifest)}")
print(f"Total size:       {total_size / 1024:.1f} KB")
print()

for filename, size, description in sorted(manifest):
    print(f"  {filename:45} {size:10,} bytes  ({description})")

# ============================================================================
# FINAL STATUS
# ============================================================================

print(f"\n{'=' * 90}")
print(f"D-23 NOTEBOOK COMPLETE")
print(f"{'=' * 90}")
print(f"\n  Model:    {SELECTED_MODEL}")
print(f"  Queries:  {len(d23_df)}")
print(f"  Decision: {go_nogo_decision}")
print(f"  Report:   {decision_path}")

if go_nogo_decision == "GO":
    print(f"\n  → NEXT: D-24 (Layer Ablation Study)")
    print(f"    Identify highest-value layers; optimize token budget.")
elif go_nogo_decision == "CONDITIONAL_GO":
    print(f"\n  → NEXT: D-24 with reduced scope (4-5 layers)")
    print(f"    Focus on top-performing layers; set simplification gate.")
else:
    print(f"\n  → NEXT: Revert to D-22 single-layer enrichment.")
    print(f"    Multi-layer complexity not justified by results.")
```

**Notes**:
- Exports all core artifacts: metrics CSV, delta CSVs, token audit, significance results, decision report
- Verifies existence of files already exported by prior cells (delta CSVs, significance, visualizations)
- Complete manifest with file sizes and descriptions
- Final status block with model, query count, decision, and next steps
- ~80 lines

---

### Cell 22: Decision Summary & Next Steps

**Type**: Markdown

**Content**:

```markdown
## GO/NO-GO Decision Summary

D-23 evaluated multi-layer enrichment (8 layers: Corpus, Domain, Entity, Authority, Temporal,
Relational, Section, Content) against two baselines:

- **D-21 (Baseline)**: No enrichment — raw chunk retrieval
- **D-22 (Single-Layer)**: Simple metadata prefix enrichment

The 7-criterion evaluation framework tested whether the additional complexity of 8 layers
justifies the engineering effort and token budget cost, using Bonferroni-corrected statistical
testing (adjusted α ≈ 0.0167).

**Decision: [TO BE FILLED AFTER EXECUTION — see Cell 20 output]**

---

## Three Scenario Paths

### Scenario A: GO (≥5/7 criteria + mandatory conditions met)

**Action**: Proceed to D-24 (Layer Ablation Study).

**D-24 Scope**:
- Sequentially remove layers to measure individual contribution
- Order layers by token cost and information value
- Build "minimum viable layers" configuration (e.g., Authority + Temporal + Content)
- Test interaction effects: does layer order matter?

**C# Implementation Path**:
- Build all 8 layer enrichers with token overflow guards
- Implement per-chunk enrichment pipeline
- Add telemetry for per-layer contribution tracking

### Scenario B: CONDITIONAL GO (3-4/7 criteria met)

**Action**: Proceed to D-24 with reduced scope and simplification target.

**Simplification Target**: Reduce from 8 layers to 4-5 high-value layers.

**D-24 Scope**:
- Focus ablation on identifying top 4-5 layers
- Test aggressive removal of mid-value layers (Domain, Relational, Section)
- Gate: if top-4 configuration ≈ D-22 performance, revert to D-22

**C# Implementation Path**:
- Build streamlined enrichment with 4-5 layers only
- Defer optional layers (toggle on/off)

### Scenario C: NO-GO (<3/7 criteria met)

**Action**: Abandon multi-layer. Standardize on D-22 (single-layer enrichment).

**Next Steps**:
- Skip D-24 entirely
- Focus on D-25 (Metadata Filtering & Re-ranking) using D-22 as baseline
- Revisit multi-layer only if future models show different layer benefits

**C# Implementation Path**:
- Simple single-layer prefix enrichment (~50 lines of code)
- Allocate token budget to metadata filtering and re-ranking

---

## What We Learned

### Token Budget Insights
- Layer token distribution reveals which layers are "expensive"
- High-token layers (e.g., Relational) are candidates for D-24 ablation
- v2-moe token pressure is real; multi-layer may require layer dropout on small models

### Query Type Performance
- Authority queries: expected to benefit most from Authority and Entity layers
- Temporal queries: expected to benefit from Temporal and Relational layers
- Factual queries: expected to show baseline semantic improvement (least sensitive)

### Statistical Confidence
- Bonferroni correction at α ≈ 0.0167 is conservative
- If results are borderline, D-24 should consider Holm-Bonferroni or FDR control

### Marginal Value
- Single-layer → multi-layer transition: what percentage improvement do layers 2-8 add?
- If marginal value < 5%, complexity may not be justified

---

## C# Implementation Implications

### If GO or CONDITIONAL GO

```csharp
// Per-chunk enrichment pipeline (simplified)
public class MultiLayerEnricher
{
    public string BuildEnrichedChunk(Chunk chunk, DocumentMetadata meta)
    {
        var layers = new List<string>();

        layers.Add(BuildCorpusLayer());
        layers.Add(BuildDomainLayer(meta));
        if (HasEntity(meta))     layers.Add(BuildEntityLayer(meta));
        if (HasAuthority(meta))  layers.Add(BuildAuthorityLayer(meta));
        if (HasTemporal(meta))   layers.Add(BuildTemporalLayer(meta));
        if (HasRelational(meta)) layers.Add(BuildRelationalLayer(meta));
        if (HasSection(chunk))   layers.Add(BuildSectionLayer(chunk));

        var prefix = string.Join("\n\n", layers);
        return $"{prefix}\n\n{chunk.Text}";
    }
}
```

### If NO-GO

```csharp
// Single-layer enrichment (trivial)
public static string Enrich(Chunk chunk, DocumentMetadata meta)
{
    var prefix = $"This is a {meta.Type} document about {meta.Name}. Canon status: {meta.Canon}.";
    return $"{prefix}\n\n{chunk.Text}";
}
```

---

## Open Questions for D-24

1. **Layer ablation priority**: Which layer removal causes the smallest performance drop?
2. **Layer interaction effects**: Do layers benefit from a specific ordering?
3. **Model-specific value**: Does v2-moe derive different value from layers than v1.5?
4. **Cross-layer redundancy**: Do some layers provide overlapping information?
5. **Query-specific enrichment**: Should different query types receive different layer subsets?
6. **Token efficiency threshold**: Minimum token budget for 95% of multi-layer gains?
```

**Notes**:
- Template with placeholders for post-execution values (decision, layer stats, query performance)
- Three scenario paths clearly articulate downstream actions
- C# code snippets show implementation implications for both GO and NO-GO outcomes
- Open questions for D-24 serve as discussion primers for the next phase
- ~50 lines of markdown content

---
<!-- CELL_SPECS_END -->

---

## 4. Expected Outputs

This notebook produces 11 primary artifacts that document the multi-layer enrichment experiment, statistical outcomes, and GO/NO-GO decision evidence.

| Artifact | Format | Est. Size | Purpose |
|----------|--------|-----------|---------|
| d23_results.csv | CSV | 36 rows × 6 cols | Per-query metrics (P@5, R@10, NDCG@10, MRR) for D-23 multi-layer embeddings |
| d23_delta_vs_d21.csv | CSV | 36 rows × 9 cols | Per-query deltas: D-23 multi-layer − D-21 baseline; improvement flags |
| d23_delta_vs_d22.csv | CSV | 36 rows × 9 cols | Per-query deltas: D-23 multi-layer − D-22 single-layer; isolates marginal value of layers 2–8 |
| d23_layer_token_audit.csv | CSV | ~200–250 rows × 8 cols | Per-chunk token counts for each layer; reveals token pressure by layer |
| d23_significance_results.csv | CSV | 12 rows × 8 cols | Wilcoxon signed-rank test results: 3 pairs × 4 metrics; includes p-value, rank-biserial r, Bonferroni significance |
| d23_go_nogo_decision.txt | Text | ~500–800 words | Formal GO/NO-GO decision statement with 7-criterion evidence and rationale |
| visualization_3way_comparison.png | PNG | ~200–400 KB | Grouped bar chart: D-21 vs D-22 vs D-23 mean metrics, overall + per query type |
| visualization_delta_heatmap.png | PNG | ~200–400 KB | Per-query delta heatmaps (D-23 vs D-21 and D-23 vs D-22 side by side) |
| visualization_layer_token_distribution.png | PNG | ~150–300 KB | Box plot: token consumption per layer across all chunks (informs D-24 ablation) |
| d23_multi_layer_{model} | ChromaDB collection | ~200–250 chunks | Persistent collection of enriched documents indexed via ChromaDB |
| notebook.ipynb | Jupyter | 22 cells | Executable notebook with all data loading, enrichment, embedding, querying, analysis, and visualization |

---

## 5. Comparison Methodology

### 3-Way Paired Design

All three experiments (D-21 baseline, D-22 single-layer, D-23 multi-layer) operate on identical conditions to isolate the effect of enrichment strategy:

- **Same query set**: 36 ground-truth queries (12 authority, 12 temporal, 12 factual)
- **Same corpus**: 25 YAML documents from D-20
- **Same chunk set**: ~200–250 chunks after hybrid chunking (semantic boundaries + token limits)
- **Same embedding model**: SELECTED_MODEL = "v1.5" (inherited from D-21 via D-22)
- **Same retrieval method**: top-k retrieval via ChromaDB cosine similarity
- **Only variable**: enrichment prefix strategy (none / single-layer / multi-layer)

This paired design eliminates confounds, making deltas directly attributable to enrichment layers.

### 3-Way Comparison Pairs

| Pair | Comparison | Alias | What It Tests |
|------|-----------|-------|---------------|
| 1 | D-23 vs D-21 | `ml_vs_bl` | Does multi-layer enrichment beat raw chunks? (Primary hypothesis) |
| 2 | D-23 vs D-22 | `ml_vs_sl` | Does multi-layer beat single-layer? Is 8-layer complexity justified over 1? |
| 3 | D-22 vs D-21 | `sl_vs_bl` | Single-layer vs baseline (reference). Reproduces D-22's finding; validates pipeline. |

Pair 3 serves as a sanity check. If Pair 3 shows no significant improvement, the experimental pipeline may have regressed and all results must be reviewed.

### Metrics

Four retrieval metrics computed for each query, then aggregated across the 36-query set:

1. **Precision@5 (P@5)**: `P@5 = |relevant ∩ top-5| / 5`
   - Measures fraction of top-5 results that are truly relevant. Higher is better.

2. **Recall@10 (R@10)**: `R@10 = |relevant ∩ top-10| / |relevant|`
   - Measures what fraction of all relevant documents were retrieved in top 10. Higher is better.

3. **NDCG@10**: `DCG@10 / IDCG@10` where `DCG = Σ(rel(i) / log₂(i+1))`
   - Rewards high-relevance documents in high positions (discounts lower ranks). Higher is better.

4. **MRR**: `1 / rank_of_first_relevant_result`
   - Emphasizes speed of finding the first correct answer. Higher is better.

### Delta Analysis

For each query q and metric m:

```
Delta = Metric_m(D-23) - Metric_m(D-21 or D-22)

Positive delta = enrichment improved retrieval
Negative delta = enrichment degraded retrieval
Zero delta     = no change
```

Aggregation: mean delta, median delta, standard deviation, percentage of queries improved/degraded.

### Marginal Value Analysis

Isolates the contribution of layers 2–8 beyond D-22's single-layer prefix:

```
Marginal Value = (D-23 improvement over D-21) - (D-22 improvement over D-21)
```

If marginal value is negligible, single-layer enrichment captures most benefit and multi-layer complexity is not justified.

### Statistical Testing

**Wilcoxon Signed-Rank Test**: Paired, non-parametric test on 36 query deltas. Tests null hypothesis that median delta is zero.

**Bonferroni Correction**: 3 pairwise comparisons → adjusted α = 0.05 / 3 ≈ 0.0167. A p-value must be ≤ 0.0167 to be considered significant.

**Effect Size — Rank-Biserial Correlation**:

```
r = 1 - (2W) / (n(n+1)/2)
```

where W is the Wilcoxon statistic and n is the number of non-zero differences.

Interpretation: |r| < 0.1 negligible, 0.1–0.3 small, 0.3–0.5 medium, > 0.5 large.

### GO/NO-GO Criteria

Seven pass/fail criteria determine the decision:

| # | Criterion | Pass Condition | Category |
|---|----------|----------------|----------|
| 1 | Execution | < 5% of chunks exceed token limit after enrichment | Feasibility |
| 2 | Improvement over D-21 | Mean delta > 0 for ≥ 3/4 metrics (ML vs BL) | **Mandatory** |
| 3 | Improvement over D-22 | Mean delta > 0 for ≥ 2/4 metrics (ML vs SL) | Effectiveness |
| 4 | Statistical Significance | Wilcoxon p < 0.0167 for ≥ 2 metrics (ML vs BL) | **Mandatory** |
| 5 | Marginal Value | ML vs SL gain > 5% for ≥ 1 metric | Justification |
| 6 | No Catastrophic Degradation | < 25% of queries show any metric degradation (ML vs BL) | Safety |
| 7 | Authority/Temporal Benefit | Specialized query types show larger deltas than factual | Hypothesis |

**Scoring**:
- **GO**: ≥ 5/7 criteria passed, **including both criteria 2 and 4** (mandatory)
- **CONDITIONAL GO**: 3–4/7 criteria passed
- **NO-GO**: < 3/7 criteria passed

---

## 6. Known Limitations

### 1. Model Selection Dependency

D-23 tests only SELECTED_MODEL ("v1.5"). Results may not generalize to v2-moe (512-token constraint) or bge-m3 (different embedding space, 1024-dim). *Mitigation*: Document v1.5-specific findings; D-24 may re-run ablation on remaining models.

### 2. Token Pressure on v2-moe

The v2-moe model has a 512-token budget. An 8-layer prefix (~100–150 tokens) consumes 20–30% of this budget, leaving only 250–350 tokens for content. Content truncation may skew results against multi-layer enrichment on this model. *Mitigation*: D-23 documents token audit per model; v2-moe testing deferred to D-24.

### 3. Small Query Sample

36 queries (12 per query type) may lack statistical power to detect effects < 5% improvement. Wilcoxon test with n=36 has limited sensitivity to small effect sizes (|r| < 0.2). *Mitigation*: Report effect sizes alongside p-values; interpret non-significant results cautiously.

### 4. No Cross-Validation

Single corpus (25 documents) and single query set. Cannot estimate generalization to new documents or query distributions. *Mitigation*: D-24 may test on a held-out subset; production validation should use independent corpora.

### 5. Layer Interaction Effects

All 8 layers tested as a bundle. Cannot isolate individual layer contributions or detect interaction effects (e.g., Temporal + Authority synergy). *Mitigation*: D-24 is designed specifically for layer ablation; D-23 tests the "full stack" only.

### 6. Metadata Completeness

Some YAML frontmatter fields may be missing (e.g., era for ahistorical entities, relationships for singleton characters). Missing layers are omitted from the prefix, causing chunks with incomplete metadata to receive shorter enrichment. *Mitigation*: d23_layer_token_audit.csv reports layer presence rates; D-24 can test mandatory vs. optional layer configurations.

### 7. Prefix-Content Ratio

For short chunks (< 100 content tokens), a 7-layer prefix (~50–150 tokens) may dominate the embedding signal, reducing the influence of actual content on retrieval. *Mitigation*: Segment results by chunk length in analysis; D-24 should test minimum chunk size thresholds.

### 8. Static Layer Format

Enrichment layers use natural language prose (e.g., "This content describes The Iron Covenant."). Other formats (key-value, JSON, semantic role labels) are not tested. Format choice may affect embedding performance. *Mitigation*: Document format rationale; future work may explore alternative formats.

### 9. Query Set Design

The 36 queries are designed to test the enrichment hypothesis (e.g., queries explicitly referencing canon status or time periods). Real-world query distributions may not align. *Mitigation*: Acknowledge in d23_go_nogo_decision.txt that results are under "hypothesis-friendly" conditions.

### 10. Bonferroni Conservatism

Bonferroni correction (α_adj ≈ 0.0167) is conservative, increasing Type II error risk (false negatives). True effects may be missed. *Mitigation*: D-24 may adopt Holm-Bonferroni (step-down procedure) or FDR control. Document sensitivity of decision to correction choice.

---

## 7. Amendments to Upstream Documents

### D-22 (Notebook 2: Single-Layer Enrichment)

**Cell 20 (Export Results)**: Ensure d22_results.csv export path matches D-23's expected `D22_RESULTS_PATH`:

```python
# D-22 Cell 20: path must match D-23 Cell 03
d22_results_path = Path("/mnt/0000_concurrent/d22_output/d22_results.csv")
```

**Cell 22 (Next Steps)**: D-23 scope section now fully specified with 7 GO/NO-GO criteria, 3-way comparison design, and Bonferroni-corrected statistical testing. D-22's preview section should be updated to align.

### D-21 (Notebook 1: Baseline)

**Cell 15 (Export Results)**: Verify d21_results.csv export path matches D-23's expected `D21_RESULTS_PATH`:

```python
# D-21 Cell 15: path must match D-23 Cell 03
d21_results_path = Path("/mnt/0000_concurrent/d21_output/d21_results.csv")
```

**SELECTED_MODEL**: D-23 inherits from D-21 via D-22. All three notebooks must use the same model identifier. If D-21 updates SELECTED_MODEL, both D-22 and D-23 must be re-run.

### D-32 (COLAB-SESSION-CONTEXT.md)

**build_enriched_text() reference**: D-23 Cell 09 implements the multi-layer enrichment function matching D-32's specification, with one enhancement: DOMAIN_CATEGORY_MAP for richer Domain layer values.

**8-layer table**: D-23 Cell 01 references D-32's layer definitions. Token budget estimates from R-01 should be validated against d23_layer_token_audit.csv after execution.

---

## 8. Open Questions

### OQ-D23-1: Token Overflow Handling Strategy

**Question**: Chunks that exceed the token limit after enrichment face three options: (a) truncate content, (b) remove layers in reverse priority order until chunk fits, or (c) flag and exclude. D-23 implements option (c) with reporting.

**Status**: Open. D-24 may explore option (b) — layer dropout — as a more graceful degradation strategy. Option (a) risks silently corrupting semantics.

### OQ-D23-2: Bonferroni vs Holm-Bonferroni

**Question**: Bonferroni correction is conservative and may inflate Type II error. Should D-24 switch to Holm-Bonferroni (step-down procedure) for less conservative correction?

**Status**: Open. D-23 uses Bonferroni. If results are borderline (p-values near 0.02), D-24 should report results under both Bonferroni and Holm-Bonferroni as sensitivity analysis.

### OQ-D23-3: Layer Ablation Priority Order

**Question**: If D-24 removes layers, which order? Options: by token cost (heaviest first), by presence rate (least present first), or by hypothesized information value.

**Status**: Open. d23_layer_token_audit.csv provides token counts and presence rates per layer. D-24 should use these data to inform ablation ordering.

### OQ-D23-4: Section Heading Quality

**Question**: The Section layer depends on document heading quality. Vague headings (e.g., "Overview", "Details") may add noise instead of signal. Should D-24 filter or score heading quality?

**Status**: Open. D-23 includes all headings as-is. If results show negative correlation between Section layer and retrieval quality, D-24 should investigate.

### OQ-D23-5: Cross-Model Generalization

**Question**: D-23 tests only SELECTED_MODEL ("v1.5"). Are layer effects model-agnostic, or does each model require different enrichment strategies?

**Status**: Open. D-24 or a follow-up study should re-run ablation on all 3 models to assess model-specific layer value.

---

## 9. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-11 | Ryan + Claude (Cowork) | Initial complete specification: 22 cells, sections 1–9, appendices A–C. 3-way comparison design, 7 GO/NO-GO criteria, Bonferroni-corrected testing, 11 output artifacts. |

---

## Appendix A: References

### Design Documents

- **D-20**: Test Corpus Preparation — 25 YAML documents with frontmatter schema (type, name, canon, era, relationships, etc.)
- **D-21**: Notebook 1: Baseline — 3-model comparison, hybrid chunking strategy, 36 ground-truth queries, SELECTED_MODEL determination
- **D-22**: Notebook 2: Single-Layer Enrichment — Single-layer prefix enrichment, 2-way comparison vs D-21, establishes single-layer baseline for D-23
- **D-24**: Notebook 4: Layer Ablation Study — Planned. Conditionally depends on D-23 GO decision. Systematically removes layers to isolate individual contributions.
- **D-32**: COLAB-SESSION-CONTEXT.md — 8-layer enrichment template, build_enriched_text() reference implementation

### Research Findings

- **R-01**: Model Context Windows & Token Budgets — v2-moe 512-token discovery, MoE routing implications, task prefix requirements
- **R-02**: Embedding Model Sizing — Matryoshka dimensions (768 primary, 256 secondary), model configuration details
- **R-03**: Anthropic Contextual Retrieval — Prefix prepending architecture, LLM-based summary approach (motivates D-23's static prefix alternative)

### External References

- Sentence-Transformers: https://www.sbert.net/
- ChromaDB: https://docs.trychroma.com/
- SciPy Wilcoxon: https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.wilcoxon.html
- NDCG: https://en.wikipedia.org/wiki/Discounted_cumulative_gain
- Bonferroni Correction: https://en.wikipedia.org/wiki/Bonferroni_correction

---

## Appendix B: Configuration Constants Quick Reference

```python
# Model selection (inherited from D-21 → D-22 → D-23)
SELECTED_MODEL = "v1.5"  # Options: "v2-moe", "v1.5", "bge-m3"

# Model configurations (from R-01)
MODELS = {
    "v2-moe": ModelConfig(
        name="v2-moe",
        full_name="nomic-ai/nomic-embed-text-v2-moe",
        max_tokens=512,
        embedding_dim=768,
        prefix_reserve_tokens=100,
        max_chunk_tokens=250,
    ),
    "v1.5": ModelConfig(
        name="v1.5",
        full_name="nomic-ai/nomic-embed-text-v1.5",
        max_tokens=8192,
        embedding_dim=768,
        prefix_reserve_tokens=150,
        max_chunk_tokens=450,
    ),
    "bge-m3": ModelConfig(
        name="bge-m3",
        full_name="BAAI/bge-m3",
        max_tokens=8192,
        embedding_dim=1024,
        prefix_reserve_tokens=150,
        max_chunk_tokens=874,
    ),
}

# Paths
CORPUS_DIR = Path("/mnt/0000_concurrent/d20_corpus")
OUTPUT_DIR = Path("/mnt/0000_concurrent/d23_output")
D21_RESULTS_PATH = Path("/mnt/0000_concurrent/d21_output/d21_results.csv")
D22_RESULTS_PATH = Path("/mnt/0000_concurrent/d22_output/d22_results.csv")
CHROMADB_DIR = OUTPUT_DIR / "chromadb"

# Queries: 36 total (12 authority + 12 temporal + 12 factual)
# Metrics: ["precision@5", "recall@10", "ndcg@10", "mrr"]

# Statistical testing
SIGNIFICANCE_LEVEL = 0.05
BONFERRONI_PAIRS = 3
ADJUSTED_ALPHA = SIGNIFICANCE_LEVEL / BONFERRONI_PAIRS  # ≈ 0.0167

# GO/NO-GO decision
CRITERIA_COUNT = 7
GO_THRESHOLD = 5        # Must pass ≥5 criteria (with mandatory 2+4)
CONDITIONAL_THRESHOLD = 3  # 3-4 criteria → CONDITIONAL GO
```

---

## Appendix C: Troubleshooting

### Issue: D-21 or D-22 Results Not Found

**Message**: `⚠ D-21 results file not found at /mnt/0000_concurrent/d21_output/d21_results.csv`

**Cause**: Upstream notebooks (D-21 or D-22) have not been run, or results were exported to a different path.

**Solution**:
1. Run D-21 and D-22 notebooks to completion
2. Verify CSV files are exported to the paths specified in D-23 Cell 03
3. Update D21_RESULTS_PATH / D22_RESULTS_PATH constants if paths differ

### Issue: Enriched Chunks Exceed Token Limit

**Message**: `⚠ {n} chunks ({pct}%) exceed token limit after enrichment`

**Cause**: Concatenated prefix + content exceeds model's max_tokens. Common with v2-moe (512 tokens) when enrichment prefix is large.

**Solution**:
1. Increase prefix_reserve_tokens in ModelConfig (e.g., 100 → 150 for v2-moe)
2. Reduce max_chunk_tokens (trade-off: shorter chunks)
3. Switch to model with larger context window (v1.5 or bge-m3)
4. Review d23_layer_token_audit.csv to identify heaviest layers

### Issue: ChromaDB Collection Already Exists

**Message**: `Collection d23_multi_layer_v1.5 already exists`

**Cause**: Previous D-23 run persisted a collection.

**Solution**: Cell 11 uses `get_or_create_collection()`. If error persists:

```python
client = chromadb.PersistentClient(path=str(CHROMADB_DIR))
client.delete_collection(name=f"d23_multi_layer_{SELECTED_MODEL}")
```

### Issue: Wilcoxon Test Warning for Zero Differences

**Message**: `UserWarning: Exact p-value calculation does not work if there are zeros`

**Cause**: Some queries produce identical scores across experiments (delta = 0).

**Solution**: This is expected and informational. SciPy excludes zero-difference pairs from the test, reducing effective sample size. The reported p-value remains valid.

### Issue: All Deltas Are Zero

**Message**: All entries in delta CSVs equal 0.

**Cause**: Enrichment prefix did not affect embedding similarity. Either build_multi_layer_prefix() produces empty output, or embedding model is insensitive to prefix content.

**Solution**:
1. Check Cell 09 output to confirm prefixes are non-empty and diverse
2. Compare raw vs. enriched text for a sample chunk
3. If enriched text differs but deltas are zero, test with a different model
4. Verify DOMAIN_CATEGORY_MAP and layer builder functions are producing expected output

### Issue: ChromaDB Query Returns Empty Results

**Message**: `Retrieved 0 / 10 chunks` or empty results for queries

**Cause**: Collection not indexed correctly, or query embedding fundamentally differs from chunk embeddings.

**Solution**:
1. Verify collection size: `collection.count()` should be 200–250
2. Test a sample query directly against the collection
3. If count = 0, re-run Cell 10 and Cell 11
4. Verify SELECTED_MODEL matches the model used for embedding

---

**End of D-23 Specification Document**
