---
title: "D-22: Notebook 2 — Single-Layer Enrichment"
document_id: "D-22"
version: "1.0"
status: "Complete"
date: "2026-02-11"
author: "Ryan + Claude (Cowork)"
depends_on: "D-21 (Notebook 1: Baseline), D-20 (Test Corpus Preparation)"
blocks: "D-23 (Notebook 3: Multi-Layer Enrichment)"
authority: "Chronicle-FractalRecall-Master-Strategy.md §7.4 (Notebook 2)"
---

## 1. Notebook Overview

### Research Question

**Does adding a single document-level context prefix—derived from YAML frontmatter metadata—improve retrieval quality over the D-21 baseline?**

This notebook tests a minimal, low-cost enrichment strategy inspired by Anthropic's Contextual Retrieval technique (R-03). Rather than using an LLM to generate summaries, we extract structured metadata (document type, name, canonical status) from the corpus and prepend it to each chunk before embedding. The goal is to quantify the contribution of even lightweight contextual information to RAG performance.

### Scope

- **Input**: D-21's baseline corpus (same documents, same chunking strategy)
- **Processing**: Add a single natural language prefix to each chunk: `"This is a {type} document about {name}. Canon status: {canon}."`
- **Output**: D-22 metrics on all 36 ground-truth queries, delta analysis vs. D-21 baseline
- **Model**: Only the model selected as the winner from D-21's weighted comparison
- **Collection**: New ChromaDB collection `d22_single_layer_{model}` (separate from D-21 baseline)
- **Comparison**: Per-query metric deltas, statistical significance testing (Wilcoxon signed-rank), breakdown by query type and relevance tier

### Key Assumptions

1. **D-21 must be completed first** to determine SELECTED_MODEL. D-22 provides a default (`v1.5`) but this is a placeholder.
2. **Prefix is static per document**: all chunks from a single document share the same prefix. No section-level variation is tested here (reserved for D-23).
3. **Token overhead is acceptable**:
   - v2-moe (512 tokens): ~15-25 tokens for prefix, leaves ~300-400 for content (tight but viable)
   - v1.5 / BGE-M3 (8192 tokens): ~15-25 tokens is negligible; no practical constraint
4. **No model retraining**: we only test embedding and retrieval, not fine-tuning.
5. **Query set is static**: all 36 queries from D-21 are reused exactly.

### Inputs

| Source | Type | Description |
|--------|------|-------------|
| D-20 test corpus | Directory | `/mnt/0000_concurrent/d20_corpus/` containing 25 YAML documents with frontmatter |
| D-21 baseline results | CSV | `d21_results.csv` (per-query metrics for baseline model) |
| D-21 chunking config | Code | Hybrid chunking strategy: semantic boundaries + token limits |
| D-21 field mapping | Code | Frontmatter normalization (type, name, canon, etc.) |
| D-21 query set | Python list | 36 ground-truth queries with relevance judgments |

### Outputs

| Artifact | Type | Description |
|----------|------|-------------|
| d22_results.csv | CSV | Per-query metrics (precision@5, recall@10, ndcg@10, mrr) |
| d22_delta.csv | CSV | Per-query metric deltas (D-22 - D-21) and improvement flags |
| d22_single_layer_{model} | ChromaDB collection | Indexed documents with enriched chunks |
| visualization_improvement_distribution.png | Chart | Per-query-type improvement bars |
| visualization_heatmap_comparison.png | Chart | Side-by-side heatmaps (D-21 vs D-22) |
| notebook.ipynb | Jupyter | Executable notebook with all cells |

### Success Criteria

1. **Execution**: Notebook runs without errors using SELECTED_MODEL (default v1.5)
2. **No token overflow**: No chunk exceeds max_chunk_tokens after enrichment prefix is added
3. **Improvement**: Mean metric delta across all 36 queries is positive (D-22 > D-21)
4. **Statistical significance**: Wilcoxon signed-rank test p-value < 0.05 for at least one metric
5. **No degradation**: Fewer than 50% of queries show metric degradation from enrichment

---

## 2. Cell Map

| Cell | Type | Title | Purpose |
|------|------|-------|---------|
| 01 | Markdown | Notebook Header | Title, research question, context |
| 02 | Code | Install Dependencies | pip install chromadb, sentence-transformers, etc. |
| 03 | Code | Imports, Configuration, Model Selection | Load libraries; define SELECTED_MODEL constant |
| 04 | Code | Ground-Truth Query Set | 36 queries with relevance judgments (copy from D-21) |
| 05 | Code | Field Mapping & Normalization | Frontmatter → normalized metadata dict |
| 06 | Code | Corpus Loading | Load all 25 documents from D-20 |
| 07 | Markdown | Methodology | Explain single-layer enrichment concept and hypothesis |
| 08 | Code | Hybrid Chunking Engine | Reuse D-21's chunking strategy |
| 09 | Code | Single-Layer Enrichment Builder | `build_single_layer_prefix()` and `build_enriched_chunk()` |
| 10 | Code | Chunk & Enrich Corpus | Apply chunking + enrichment to all documents |
| 11 | Code | Embedding & ChromaDB Indexing | Embed enriched chunks; create collection d22_single_layer_{model} |
| 12 | Code | Query Execution | Run all 36 queries against D-22 collection; retrieve top-10 results |
| 13 | Markdown | Results Introduction | Brief context for metrics section |
| 14 | Code | Metric Computation Functions | Helper functions: precision@K, recall@K, ndcg@K, mrr |
| 15 | Code | Compute D-22 Metrics & Load D-21 Baseline | Calculate D-22 scores; load d21_results.csv; merge into comparison DF |
| 16 | Code | Delta Analysis — D-22 vs D-21 | Per-query deltas; aggregation by query type; % improved/degraded |
| 17 | Code | Statistical Significance Testing | Wilcoxon signed-rank test on per-query pairs |
| 18 | Code | Visualization — Improvement Distribution | Bar chart: per-query-type delta for each metric |
| 19 | Code | Visualization — Side-by-Side Heatmap | D-21 vs D-22 metrics with delta annotations |
| 20 | Code | Export Results | Save d22_results.csv, d22_delta.csv; persist ChromaDB |
| 21 | Markdown | C# Implementation Implications | Prefix builder in C#; feasibility of D-23 |
| 22 | Markdown | Next Steps for D-23 | Multi-layer enrichment scope and go/no-go decision |

---

## 3. Cell Specifications

### Cell 01: Notebook Header

**Type**: Markdown

**Content**:

```markdown
# D-22: Notebook 2 — Single-Layer Enrichment

## Research Question

**Does adding a single document-level context prefix improve retrieval quality?**

We take D-21's baseline (chunks without enrichment) and add exactly one contextual element: a simple prefix derived from YAML frontmatter metadata. The prefix is a natural language sentence:

```
"This is a {type} document about {name}. Canon status: {canon}."
```

This tests whether even minimal metadata enrichment—inspired by Anthropic's Contextual Retrieval (R-03)—improves retrieval metrics over the raw-chunk baseline.

## Hypothesis

- **Primary**: Single-layer enrichment will improve recall and NDCG due to better semantic grounding in the prefix.
- **Secondary**: Authority-sensitive and temporal queries will benefit more than factual queries.
- **Token efficiency**: The ~15-25 token prefix is negligible for v1.5/BGE-M3 (8192 tokens) and acceptable for v2-moe (512 tokens).

## Execution Notes

- This notebook reuses D-21's entire infrastructure: corpus loader, chunking engine, field mapping, queries, metrics.
- The ONLY change is the addition of the single-layer enrichment prefix before embedding.
- Results are compared against D-21 baseline using per-query deltas and statistical significance testing.
```

---

### Cell 02: Install Dependencies

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Install Dependencies

Installs the same packages as D-21, ensuring compatibility with:
- ChromaDB (vector storage)
- sentence-transformers (embedding models)
- scipy (statistical testing)
- pandas (data wrangling)
"""

import subprocess
import sys

packages = [
    "chromadb==0.4.24",
    "sentence-transformers==2.2.2",
    "scipy>=1.11.0",
    "pandas>=2.0.0",
    "numpy>=1.24.0",
    "pyyaml>=6.0",
    "tqdm>=4.65.0",
]

for package in packages:
    print(f"Installing {package}...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", package])

print("✓ All dependencies installed successfully.")
```

---

### Cell 03: Imports, Configuration, and Model Selection

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Imports, Configuration, Model Selection

Loads all required libraries and defines the SELECTED_MODEL constant.
This constant MUST be updated after running D-21 to reflect the winning model.

Default: v1.5 (placeholder; update with D-21 results)
Options: "v2-moe", "v1.5", "bge-m3"
"""

import os
import json
import yaml
from pathlib import Path
from typing import Dict, List, Tuple, Any, Optional
from dataclasses import dataclass, field, asdict
from collections import defaultdict
import math

import chromadb
from chromadb.config import Settings
import numpy as np
import pandas as pd
from sentence_transformers import SentenceTransformer
from scipy.stats import wilcoxon
from tqdm import tqdm
import warnings

warnings.filterwarnings("ignore")

# ======================================================================
# CONFIGURATION CONSTANTS
# ======================================================================

# Model selection: UPDATE THIS AFTER RUNNING D-21
# Set to the model key that won D-21's weighted comparison.
# Options: "v2-moe", "v1.5", "bge-m3"
# Default: "v1.5" (placeholder — update with actual D-21 winner)
SELECTED_MODEL = "v1.5"

# Paths (same as D-21; see D-20 for corpus setup)
CORPUS_DIR = Path("/mnt/0000_concurrent/d20_corpus")
OUTPUT_DIR = Path("/mnt/0000_concurrent/d22_output")
CHROMADB_DIR = OUTPUT_DIR / "chromadb"
D21_RESULTS_PATH = Path("/mnt/0000_concurrent/d21_output/d21_results.csv")

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
CHROMADB_DIR.mkdir(parents=True, exist_ok=True)

# Model configurations (reused from D-21; see R-01, R-02, R-03)
@dataclass
class ModelConfig:
    """Configuration for a single embedding model.

    This is shared with D-21. We only instantiate the SELECTED_MODEL config.
    Reference: D-21 Cell 03, R-02 (model sizing guide).
    """
    name: str                      # Display name
    model_id: str                  # HuggingFace model ID
    max_tokens: int                # Context window
    expected_dim: int              # Embedding dimension
    batch_size: int                # Embedding batch size

    # Chunking constraints (context-aware)
    max_chunk_tokens: int          # Max content tokens per chunk
    prefix_reserve_tokens: int     # Reserved for enrichment prefix

MODEL_CONFIGS = {
    "v2-moe": ModelConfig(
        name="Nomic Embed Text v2 (MOE)",
        model_id="nomic-ai/nomic-embed-text-1.5-moe-8b",
        max_tokens=512,
        expected_dim=768,
        batch_size=128,
        max_chunk_tokens=400,
        prefix_reserve_tokens=50,  # ~15-25 tokens used; 50 reserved for safety
    ),
    "v1.5": ModelConfig(
        name="Nomic Embed Text v1.5",
        model_id="nomic-ai/nomic-embed-text-1.5",
        max_tokens=8192,
        expected_dim=768,
        batch_size=256,
        max_chunk_tokens=7500,
        prefix_reserve_tokens=100,  # ~15-25 tokens used; 100 reserved for safety
    ),
    "bge-m3": ModelConfig(
        name="BGE-M3",
        model_id="BAAI/bge-m3",
        max_tokens=8192,
        expected_dim=1024,
        batch_size=256,
        max_chunk_tokens=7500,
        prefix_reserve_tokens=100,
    ),
}

# Validate selected model
if SELECTED_MODEL not in MODEL_CONFIGS:
    raise ValueError(
        f"SELECTED_MODEL='{SELECTED_MODEL}' is invalid. "
        f"Must be one of: {list(MODEL_CONFIGS.keys())}"
    )

# Load only the selected model config
MODEL_CONFIG = MODEL_CONFIGS[SELECTED_MODEL]
print(f"✓ Selected model: {MODEL_CONFIG.name}")
print(f"  Model ID: {MODEL_CONFIG.model_id}")
print(f"  Context window: {MODEL_CONFIG.max_tokens} tokens")
print(f"  Max chunk size: {MODEL_CONFIG.max_chunk_tokens} tokens")

# Query configuration (reused from D-21)
QUERIES = [
    # Authority-sensitive queries (should benefit from canon status in prefix)
    {
        "query_id": "Q01",
        "type": "authority",
        "text": "What is the canonical history of the Iron-Banes?",
        "relevant_docs": ["faction_ironbanes.yaml"],
    },
    {
        "query_id": "Q02",
        "type": "authority",
        "text": "Which documents are considered canon in this universe?",
        "relevant_docs": ["faction_ironbanes.yaml", "magic_arcana.yaml"],
    },
    # Temporal queries (should benefit from type/name in prefix)
    {
        "query_id": "Q03",
        "type": "temporal",
        "text": "What major events happened during the Second Era?",
        "relevant_docs": ["timeline_2nd_era.yaml"],
    },
    {
        "query_id": "Q04",
        "type": "temporal",
        "text": "When was the Dragon War?",
        "relevant_docs": ["timeline_wars.yaml"],
    },
    # Factual queries (may not benefit as much from prefix)
    {
        "query_id": "Q05",
        "type": "factual",
        "text": "What is arcane magic?",
        "relevant_docs": ["magic_arcana.yaml"],
    },
    {
        "query_id": "Q06",
        "type": "factual",
        "text": "List all magic types.",
        "relevant_docs": ["magic_arcana.yaml", "magic_divine.yaml"],
    },
    # (... remaining 30 queries; see D-21 Cell 04 for full list ...)
    # For brevity, placeholder shows the structure. In actual implementation,
    # copy the full 36-query set from D-21 Cell 04.
]

print(f"✓ Loaded {len(QUERIES)} ground-truth queries")
print(f"  Query types: authority={len([q for q in QUERIES if q['type']=='authority'])}, "
      f"temporal={len([q for q in QUERIES if q['type']=='temporal'])}, "
      f"factual={len([q for q in QUERIES if q['type']=='factual'])}")
```

**Notes**:
- SELECTED_MODEL defaults to "v1.5" but MUST be updated after D-21 is run.
- All paths and model configs are inherited from D-21.
- The query set is a placeholder; copy the full 36 queries from D-21 Cell 04.

---

### Cell 04: Ground-Truth Query Set

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Ground-Truth Query Set

Defines all 36 ground-truth queries used for evaluation.

This is IDENTICAL to D-21 Cell 04. It includes queries across three types:
- Authority-sensitive: tests ability to surface canon vs. non-canon content
- Temporal: tests understanding of timeline and era information
- Factual: tests basic content retrieval

Each query includes:
  - query_id (Q01-Q36)
  - type (authority | temporal | factual)
  - text (natural language query)
  - relevant_docs (list of document filenames that should be in top results)

Reference: D-21 Cell 04; see R-01 (query design methodology)
"""

QUERIES = [
    # ====================================================================
    # Authority-Sensitive Queries (Q01-Q12)
    # ====================================================================
    {
        "query_id": "Q01",
        "type": "authority",
        "text": "What is the canonical history of the Iron-Banes?",
        "relevant_docs": ["faction_ironbanes.yaml"],
    },
    {
        "query_id": "Q02",
        "type": "authority",
        "text": "Which documents are considered canon in this universe?",
        "relevant_docs": ["faction_ironbanes.yaml", "magic_arcana.yaml"],
    },
    {
        "query_id": "Q03",
        "type": "authority",
        "text": "What is non-canon lore about the Shadowborn?",
        "relevant_docs": ["faction_shadowborn.yaml"],
    },
    {
        "query_id": "Q04",
        "type": "authority",
        "text": "Compare canon and non-canon interpretations of the Void.",
        "relevant_docs": ["entity_void.yaml"],
    },
    {
        "query_id": "Q05",
        "type": "authority",
        "text": "Which factions are canon?",
        "relevant_docs": ["faction_ironbanes.yaml", "faction_shadowborn.yaml"],
    },
    {
        "query_id": "Q06",
        "type": "authority",
        "text": "Are there any non-canon entities?",
        "relevant_docs": ["entity_void.yaml"],
    },
    {
        "query_id": "Q07",
        "type": "authority",
        "text": "Summarize the official stance on magic in this setting.",
        "relevant_docs": ["magic_arcana.yaml", "magic_divine.yaml"],
    },
    {
        "query_id": "Q08",
        "type": "authority",
        "text": "What is the authoritative definition of the Aether?",
        "relevant_docs": ["magic_arcana.yaml"],
    },
    {
        "query_id": "Q09",
        "type": "authority",
        "text": "Which timeline entries are canonical?",
        "relevant_docs": ["timeline_1st_era.yaml", "timeline_wars.yaml"],
    },
    {
        "query_id": "Q10",
        "type": "authority",
        "text": "What does canon status mean in this corpus?",
        "relevant_docs": ["faction_ironbanes.yaml"],
    },
    {
        "query_id": "Q11",
        "type": "authority",
        "text": "Identify all canonical entities.",
        "relevant_docs": ["entity_void.yaml", "entity_phoenix.yaml"],
    },
    {
        "query_id": "Q12",
        "type": "authority",
        "text": "Which magic types are officially recognized?",
        "relevant_docs": ["magic_arcana.yaml", "magic_divine.yaml"],
    },

    # ====================================================================
    # Temporal Queries (Q13-Q24)
    # ====================================================================
    {
        "query_id": "Q13",
        "type": "temporal",
        "text": "What major events happened during the Second Era?",
        "relevant_docs": ["timeline_2nd_era.yaml"],
    },
    {
        "query_id": "Q14",
        "type": "temporal",
        "text": "When was the Dragon War?",
        "relevant_docs": ["timeline_wars.yaml"],
    },
    {
        "query_id": "Q15",
        "type": "temporal",
        "text": "What is the timeline of this world?",
        "relevant_docs": ["timeline_1st_era.yaml", "timeline_2nd_era.yaml"],
    },
    {
        "query_id": "Q16",
        "type": "temporal",
        "text": "Which era saw the rise of the Iron-Banes?",
        "relevant_docs": ["faction_ironbanes.yaml", "timeline_1st_era.yaml"],
    },
    {
        "query_id": "Q17",
        "type": "temporal",
        "text": "What happened in the First Era?",
        "relevant_docs": ["timeline_1st_era.yaml"],
    },
    {
        "query_id": "Q18",
        "type": "temporal",
        "text": "Describe the wars in this setting.",
        "relevant_docs": ["timeline_wars.yaml"],
    },
    {
        "query_id": "Q19",
        "type": "temporal",
        "text": "What is the chronology of magical discovery?",
        "relevant_docs": ["magic_arcana.yaml", "magic_divine.yaml", "timeline_1st_era.yaml"],
    },
    {
        "query_id": "Q20",
        "type": "temporal",
        "text": "When did the Shadowborn appear?",
        "relevant_docs": ["faction_shadowborn.yaml", "timeline_2nd_era.yaml"],
    },
    {
        "query_id": "Q21",
        "type": "temporal",
        "text": "What is the oldest recorded event?",
        "relevant_docs": ["timeline_1st_era.yaml"],
    },
    {
        "query_id": "Q22",
        "type": "temporal",
        "text": "How long did the Dragon War last?",
        "relevant_docs": ["timeline_wars.yaml"],
    },
    {
        "query_id": "Q23",
        "type": "temporal",
        "text": "List all eras in chronological order.",
        "relevant_docs": ["timeline_1st_era.yaml", "timeline_2nd_era.yaml"],
    },
    {
        "query_id": "Q24",
        "type": "temporal",
        "text": "What major change occurred between the First and Second Eras?",
        "relevant_docs": ["timeline_1st_era.yaml", "timeline_2nd_era.yaml"],
    },

    # ====================================================================
    # Factual Queries (Q25-Q36)
    # ====================================================================
    {
        "query_id": "Q25",
        "type": "factual",
        "text": "What is arcane magic?",
        "relevant_docs": ["magic_arcana.yaml"],
    },
    {
        "query_id": "Q26",
        "type": "factual",
        "text": "List all magic types.",
        "relevant_docs": ["magic_arcana.yaml", "magic_divine.yaml"],
    },
    {
        "query_id": "Q27",
        "type": "factual",
        "text": "Describe the Iron-Banes faction.",
        "relevant_docs": ["faction_ironbanes.yaml"],
    },
    {
        "query_id": "Q28",
        "type": "factual",
        "text": "What is the Void?",
        "relevant_docs": ["entity_void.yaml"],
    },
    {
        "query_id": "Q29",
        "type": "factual",
        "text": "Explain divine magic.",
        "relevant_docs": ["magic_divine.yaml"],
    },
    {
        "query_id": "Q30",
        "type": "factual",
        "text": "Who are the Shadowborn?",
        "relevant_docs": ["faction_shadowborn.yaml"],
    },
    {
        "query_id": "Q31",
        "type": "factual",
        "text": "What is the Phoenix?",
        "relevant_docs": ["entity_phoenix.yaml"],
    },
    {
        "query_id": "Q32",
        "type": "factual",
        "text": "What is the Aether?",
        "relevant_docs": ["magic_arcana.yaml"],
    },
    {
        "query_id": "Q33",
        "type": "factual",
        "text": "Describe all factions.",
        "relevant_docs": ["faction_ironbanes.yaml", "faction_shadowborn.yaml"],
    },
    {
        "query_id": "Q34",
        "type": "factual",
        "text": "What are the main characteristics of arcane magic?",
        "relevant_docs": ["magic_arcana.yaml"],
    },
    {
        "query_id": "Q35",
        "type": "factual",
        "text": "List all entities.",
        "relevant_docs": ["entity_void.yaml", "entity_phoenix.yaml"],
    },
    {
        "query_id": "Q36",
        "type": "factual",
        "text": "What is the relationship between factions and magic?",
        "relevant_docs": ["faction_ironbanes.yaml", "faction_shadowborn.yaml", "magic_arcana.yaml"],
    },
]

print(f"✓ Loaded {len(QUERIES)} ground-truth queries")
print(f"  Authority: {len([q for q in QUERIES if q['type']=='authority'])}")
print(f"  Temporal: {len([q for q in QUERIES if q['type']=='temporal'])}")
print(f"  Factual: {len([q for q in QUERIES if q['type']=='factual'])}")
```

**Notes**:
- This is copied verbatim from D-21 Cell 04.
- All 36 queries are included in this version.
- Queries are balanced across three types for comprehensive evaluation.

---

### Cell 05: Field Mapping and Normalization

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Field Mapping & Normalization

Normalizes YAML frontmatter into a consistent metadata dictionary.

This is IDENTICAL to D-21 Cell 05. It extracts and validates:
  - type: document category (faction, timeline, magic, entity)
  - name: document's canonical name
  - canon: boolean flag (true | false)
  - authority_layer: optional authority descriptor
  - domain_layer: optional domain tag
  - related_entities: list of linked entities

Reference: D-21 Cell 05; D-20 (corpus schema)
"""

def map_frontmatter(raw_frontmatter: Dict[str, Any]) -> Dict[str, Any]:
    """Normalize YAML frontmatter to canonical metadata format.

    Extracts and validates key fields. Missing fields get sensible defaults.

    Args:
        raw_frontmatter: Dict parsed from YAML frontmatter block

    Returns:
        Normalized metadata dict with fields: type, name, canon, authority_layer,
        domain_layer, related_entities.

    Raises:
        KeyError: If critical fields (type, name) are missing
    """
    # Required fields
    doc_type = raw_frontmatter.get("type", "").strip().lower()
    doc_name = raw_frontmatter.get("name", "").strip()

    if not doc_type:
        raise KeyError("Frontmatter missing required field: 'type'")
    if not doc_name:
        raise KeyError("Frontmatter missing required field: 'name'")

    # Optional fields with sensible defaults
    canon_str = raw_frontmatter.get("canon", "true").strip().lower()
    canon = canon_str in ("true", "yes", "1", "canonical")

    authority_layer = raw_frontmatter.get("authority_layer", "unknown").strip()
    domain_layer = raw_frontmatter.get("domain_layer", "core").strip()

    # Parse related entities (list or comma-separated string)
    related_raw = raw_frontmatter.get("related_entities", [])
    if isinstance(related_raw, str):
        related_entities = [e.strip() for e in related_raw.split(",") if e.strip()]
    elif isinstance(related_raw, list):
        related_entities = [str(e).strip() for e in related_raw if e]
    else:
        related_entities = []

    return {
        "type": doc_type,
        "name": doc_name,
        "canon": "true" if canon else "false",
        "authority_layer": authority_layer,
        "domain_layer": domain_layer,
        "related_entities": related_entities,
    }


# Test the mapper with a sample frontmatter
sample_frontmatter = {
    "type": "faction",
    "name": "Iron-Banes",
    "canon": "true",
    "authority_layer": "official",
    "domain_layer": "military",
    "related_entities": "Aether, First Era",
}

mapped = map_frontmatter(sample_frontmatter)
print("✓ Sample frontmatter mapping:")
for key, value in mapped.items():
    print(f"  {key}: {value}")
```

---

### Cell 06: Corpus Loading

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Corpus Loading

Loads all 25 YAML documents from the D-20 test corpus.

This is IDENTICAL to D-21 Cell 06. Extracts frontmatter and body from each
document, then applies field mapping to produce normalized metadata.

Reference: D-21 Cell 06; D-20 (corpus directory structure)
"""

@dataclass
class Document:
    """Represents a single document from the corpus.

    Attributes:
        filename: Name of the YAML file (e.g., "faction_ironbanes.yaml")
        metadata: Normalized frontmatter dict (output of map_frontmatter)
        body: Text content after the frontmatter block
    """
    filename: str
    metadata: Dict[str, Any]
    body: str


def load_corpus(corpus_path: Path) -> List[Document]:
    """Load all YAML documents from corpus directory.

    Parses frontmatter (YAML between --- delimiters) and body (remaining text).
    Applies field_mapping normalization.

    Args:
        corpus_path: Path to corpus directory containing .yaml files

    Returns:
        List of Document objects, one per file

    Raises:
        FileNotFoundError: If corpus_path does not exist
        yaml.YAMLError: If frontmatter is malformed YAML
    """
    if not corpus_path.exists():
        raise FileNotFoundError(f"Corpus directory not found: {corpus_path}")

    documents = []
    yaml_files = sorted(corpus_path.glob("*.yaml"))

    for yaml_file in tqdm(yaml_files, desc="Loading corpus"):
        with open(yaml_file, "r", encoding="utf-8") as f:
            content = f.read()

        # Parse YAML frontmatter (---...---)
        lines = content.split("\n")
        if lines[0].strip() != "---":
            print(f"⚠ Warning: {yaml_file.name} does not start with ---")
            continue

        # Find closing ---
        try:
            end_idx = lines.index("---", 1)
        except ValueError:
            print(f"⚠ Warning: {yaml_file.name} missing closing ---")
            continue

        # Extract and parse frontmatter
        frontmatter_text = "\n".join(lines[1:end_idx])
        body_text = "\n".join(lines[end_idx + 1:]).strip()

        try:
            frontmatter = yaml.safe_load(frontmatter_text) or {}
            metadata = map_frontmatter(frontmatter)
        except yaml.YAMLError as e:
            print(f"✗ YAML parse error in {yaml_file.name}: {e}")
            continue

        doc = Document(
            filename=yaml_file.name,
            metadata=metadata,
            body=body_text,
        )
        documents.append(doc)

    return documents


# Load corpus
corpus = load_corpus(CORPUS_DIR)
print(f"✓ Loaded {len(corpus)} documents from {CORPUS_DIR}")

# Summary statistics
type_counts = defaultdict(int)
canon_counts = {"true": 0, "false": 0}

for doc in corpus:
    type_counts[doc.metadata["type"]] += 1
    canon_counts[doc.metadata["canon"]] += 1

print(f"  Document types:")
for doc_type, count in sorted(type_counts.items()):
    print(f"    {doc_type}: {count}")
print(f"  Canon breakdown:")
print(f"    canonical: {canon_counts['true']}")
print(f"    non-canonical: {canon_counts['false']}")
```

---

### Cell 07: Methodology

**Type**: Markdown

**Content**:

```markdown
## Methodology: Single-Layer Enrichment

### Concept

D-21 established a baseline: documents chunked without enrichment, embedded directly.
D-22 adds exactly **one contextual layer** derived from document metadata.

Before embedding each chunk, we prepend a short natural language sentence:

```
"This is a {type} document about {name}. Canon status: {canon}."
```

For example:
```
This is a faction document about Iron-Banes. Canon status: true.

[Original chunk content...]
```

### Theoretical Justification

This approach is inspired by **Anthropic's Contextual Retrieval** (see R-03), which
demonstrates that adding semantic context to chunks significantly improves retrieval
accuracy. Unlike Anthropic's method (which uses LLM-generated summaries), we use
**static metadata extracted from the document's YAML frontmatter**.

Benefits:
1. **No LLM cost**: Metadata is already available; no summary generation needed.
2. **Deterministic**: Same input always produces the same prefix (reproducible).
3. **Lightweight**: ~15-25 tokens, minimal token budget impact even on constrained models.
4. **Testable**: Simple prefix allows us to measure the contribution of structured context.

### Hypothesis

**Primary**: Single-layer enrichment will improve recall@10 and NDCG@10 compared to D-21 baseline.

**Secondary (by query type)**:
- **Authority-sensitive queries** (Q01-Q12) should benefit most because the canon status
  in the prefix helps discriminate canonical vs. non-canonical content.
- **Temporal queries** (Q13-Q24) should benefit from the document type and name being
  foregrounded in the prefix.
- **Factual queries** (Q25-Q36) may benefit least, since they rely more on content
  semantics than metadata.

### Execution Plan

1. Load D-21's baseline corpus (25 documents)
2. Apply D-21's chunking strategy (hybrid: semantic boundaries + token limits)
3. **NEW**: For each chunk, prepend the single-layer enrichment prefix
4. Embed enriched chunks using SELECTED_MODEL (from D-21's winner)
5. Index in ChromaDB collection: `d22_single_layer_{model}`
6. Run all 36 queries; compute metrics (precision@5, recall@10, ndcg@10, mrr)
7. Compare against D-21 baseline using per-query deltas and Wilcoxon signed-rank test
8. Identify which query types benefit most from enrichment

### Token Budget Implications

- **v2-moe (512 tokens)**:
  - Prefix: ~15-25 tokens
  - Reserved: 50 tokens (safety margin)
  - Content budget: 512 - 25 - 50 = 437 tokens (tight but viable)
  - D-21 max chunk was 400 tokens; after enrichment ~425 tokens (no overflow expected)

- **v1.5 / BGE-M3 (8192 tokens)**:
  - Prefix: ~15-25 tokens
  - Content budget: 8192 - 25 - 100 = 8067 tokens
  - Negligible impact on token efficiency

### Collection Management

- D-21 uses collection name: `d21_baseline_{model}`
- D-22 uses collection name: `d22_single_layer_{model}`
- Both collections coexist in the same ChromaDB instance, allowing direct comparison
- No data is deleted or overwritten

### Success Metrics

1. **No token overflow**: All enriched chunks fit within max_chunk_tokens
2. **Positive mean delta**: Average metric improvement across all 36 queries > 0
3. **Statistical significance**: Wilcoxon p-value < 0.05 for at least one metric
4. **Query type breakdown**: Identify which types benefit most

---

**References**:
- D-21 Cell 07 (baseline methodology)
- R-03 (Anthropic Contextual Retrieval)
- R-02 (model configurations and token budgeting)
```

---

### Cell 08: Hybrid Chunking Engine

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Hybrid Chunking Engine

Implements the same chunking strategy as D-21 Cell 08.

Uses semantic boundaries (section headings, blank lines) as primary segmentation,
then splits further if token count exceeds max_chunk_tokens.

This is reused unchanged from D-21. See D-21 Cell 08 and R-02 for full details.
"""

@dataclass
class Chunk:
    """Represents a single chunk of text, ready for embedding.

    Attributes:
        chunk_id: Unique identifier (e.g., "faction_ironbanes.yaml#chunk_003")
        doc_filename: Source document filename
        section_heading: Optional section heading for context
        text: The actual text to embed (may include enrichment prefix)
        token_count_approx: Approximate token count of self.text
        metadata: Normalized document metadata dict
    """
    chunk_id: str
    doc_filename: str
    section_heading: Optional[str]
    text: str
    token_count_approx: int
    metadata: Dict[str, Any]


def estimate_tokens(text: str) -> int:
    """Estimate token count using a simple heuristic.

    This approximation is consistent with D-21's approach:
    - ~4 characters per token (average English word ~5 chars + space)
    - Used for chunking decisions, not for accurate token counting

    Args:
        text: String to estimate token count for

    Returns:
        Approximate token count
    """
    # Simple heuristic: count words and add ~20% for subword tokenization overhead
    words = len(text.split())
    return int(words * 1.3)


def split_by_semantic_boundaries(text: str, section_heading: Optional[str] = None) -> List[str]:
    """Split text by semantic boundaries (headings, blank lines).

    Preserves structure within sections; prefers semantic breaks over arbitrary
    token limits (see D-21 Cell 08).

    Args:
        text: Full document body
        section_heading: Optional heading for context

    Returns:
        List of paragraphs/sections
    """
    # Split by multiple blank lines (paragraph boundaries)
    segments = re.split(r"\n\n+", text)
    return [s.strip() for s in segments if s.strip()]


def chunk_document(doc: Document, max_chunk_tokens: int) -> List[Chunk]:
    """Chunk a single document using hybrid semantic+token strategy.

    Algorithm:
    1. Split body by semantic boundaries (sections, paragraphs)
    2. Group segments into chunks, respecting token limit
    3. If a single segment exceeds limit, split by sentences
    4. Assign chunk_id, estimate token count, preserve metadata

    Args:
        doc: Document object (filename, metadata, body)
        max_chunk_tokens: Maximum tokens per chunk

    Returns:
        List of Chunk objects
    """
    chunks = []
    chunk_counter = 0

    # Split by semantic boundaries
    segments = split_by_semantic_boundaries(doc.body)

    current_chunk_text = ""
    current_chunk_tokens = 0

    for segment in segments:
        segment_tokens = estimate_tokens(segment)

        # If adding this segment would exceed limit, finalize current chunk
        if current_chunk_tokens + segment_tokens > max_chunk_tokens and current_chunk_text:
            chunk_counter += 1
            chunk_id = f"{doc.filename}#chunk_{chunk_counter:03d}"
            chunks.append(Chunk(
                chunk_id=chunk_id,
                doc_filename=doc.filename,
                section_heading=None,  # Not extracted in baseline
                text=current_chunk_text.strip(),
                token_count_approx=current_chunk_tokens,
                metadata=doc.metadata,
            ))
            current_chunk_text = ""
            current_chunk_tokens = 0

        # Add segment to current chunk
        current_chunk_text += (segment + "\n\n")
        current_chunk_tokens += segment_tokens

        # If single segment is very large, split by sentences
        if segment_tokens > max_chunk_tokens * 0.8:
            # Emergency split by sentences
            sentences = re.split(r"(?<=[.!?])\s+", segment)
            for sentence in sentences:
                sent_tokens = estimate_tokens(sentence)
                if current_chunk_tokens + sent_tokens > max_chunk_tokens and current_chunk_text:
                    chunk_counter += 1
                    chunk_id = f"{doc.filename}#chunk_{chunk_counter:03d}"
                    chunks.append(Chunk(
                        chunk_id=chunk_id,
                        doc_filename=doc.filename,
                        section_heading=None,
                        text=current_chunk_text.strip(),
                        token_count_approx=current_chunk_tokens,
                        metadata=doc.metadata,
                    ))
                    current_chunk_text = ""
                    current_chunk_tokens = 0

                current_chunk_text += (sentence + " ")
                current_chunk_tokens += sent_tokens

    # Finalize last chunk
    if current_chunk_text.strip():
        chunk_counter += 1
        chunk_id = f"{doc.filename}#chunk_{chunk_counter:03d}"
        chunks.append(Chunk(
            chunk_id=chunk_id,
            doc_filename=doc.filename,
            section_heading=None,
            text=current_chunk_text.strip(),
            token_count_approx=current_chunk_tokens,
            metadata=doc.metadata,
        ))

    return chunks


# Test chunking on a sample document
sample_doc = corpus[0]
sample_chunks = chunk_document(sample_doc, MODEL_CONFIG.max_chunk_tokens)
print(f"✓ Sample chunking: {sample_doc.filename} -> {len(sample_chunks)} chunks")
for chunk in sample_chunks[:3]:
    print(f"  {chunk.chunk_id}: {chunk.token_count_approx} tokens, {len(chunk.text)} chars")
```

**Notes**:
- Identical to D-21 Cell 08; reused without modification.
- Uses regex for semantic boundary detection.
- Fallback to sentence splitting for large segments.

---

### Cell 09: Single-Layer Enrichment Builder

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Single-Layer Enrichment Builder

NEW CODE — This is the key difference from D-21.

Implements:
  1. build_single_layer_prefix(): Constructs the enrichment prefix from metadata
  2. build_enriched_chunk(): Prepends the prefix to a chunk's text

The prefix is a simple natural language sentence:
  "This is a {type} document about {name}. Canon status: {canon}."

Example:
  "This is a faction document about Iron-Banes. Canon status: true."

Token budget:
  - ~15-25 tokens per prefix (verified with estimate_tokens)
  - Minimal impact on context window utilization
  - Well within budget for all three tested models

Reference: R-03 (Anthropic Contextual Retrieval); D-21 Cell 09 (comparison baseline)
"""

def build_single_layer_prefix(metadata: Dict[str, Any]) -> str:
    """Build a single-layer enrichment prefix from document metadata.

    This produces a short natural language sentence that describes the document's
    type, name, and canonical status. The prefix is prepended to each chunk
    before embedding.

    The design is intentionally simple:
    - One sentence (easy to parse and understand)
    - Covers three key dimensions: type, identity, canonicity
    - Invariant across all chunks from the same document (static context)

    Token budget: ~15-25 tokens (well within any model's context window).
    See R-03 for comparison with other contextual retrieval approaches.

    Args:
        metadata: Normalized frontmatter dict (output of map_frontmatter).
                 Expected keys: type, name, canon

    Returns:
        Prefix string like "This is a faction document about Iron-Banes. Canon status: true."

    Example:
        >>> metadata = {"type": "faction", "name": "Iron-Banes", "canon": "true"}
        >>> prefix = build_single_layer_prefix(metadata)
        >>> prefix
        'This is a faction document about Iron-Banes. Canon status: true.'
    """
    doc_type = metadata.get("type", "unknown").lower().strip()
    doc_name = metadata.get("name", "Unknown").strip()
    canon = metadata.get("canon", "false").lower().strip()

    # Normalize canon to "true" or "false"
    canon_normalized = "true" if canon in ("true", "yes", "canonical") else "false"

    return f"This is a {doc_type} document about {doc_name}. Canon status: {canon_normalized}."


def build_enriched_chunk(chunk: Chunk, enrichment_type: str = "single_layer") -> Chunk:
    """Prepend the single-layer enrichment prefix to a chunk.

    Creates a new Chunk object with the enriched text. The prefix is separated
    from the content by a double newline (\n\n) to create a clear semantic
    boundary that the embedding model can use.

    The enriched text becomes:
    ```
    [PREFIX]

    [ORIGINAL CHUNK TEXT]
    ```

    After enrichment, the chunk's token count is updated.

    Args:
        chunk: Original Chunk object
        enrichment_type: Label for enrichment method (currently "single_layer")

    Returns:
        New Chunk object with enriched text and updated token count

    Raises:
        ValueError: If enriched chunk exceeds max_chunk_tokens (should not happen
                   with proper prefix budgeting, but flagged for safety)
    """
    prefix = build_single_layer_prefix(chunk.metadata)
    prefix_tokens = estimate_tokens(prefix)

    # Combine prefix + original text with clear separator
    enriched_text = f"{prefix}\n\n{chunk.text}"
    enriched_tokens = estimate_tokens(enriched_text)

    # Safety check: enriched chunk should not exceed max budget
    # (This should rarely fire if prefix_reserve_tokens is set correctly)
    if enriched_tokens > MODEL_CONFIG.max_chunk_tokens:
        raise ValueError(
            f"Enriched chunk {chunk.chunk_id} exceeds token limit: "
            f"{enriched_tokens} > {MODEL_CONFIG.max_chunk_tokens} tokens. "
            f"Consider reducing max_chunk_tokens or prefix length."
        )

    # Create enriched chunk (same metadata, updated text and token count)
    enriched_chunk = Chunk(
        chunk_id=chunk.chunk_id,
        doc_filename=chunk.doc_filename,
        section_heading=chunk.section_heading,
        text=enriched_text,  # Now includes prefix
        token_count_approx=enriched_tokens,
        metadata=chunk.metadata,
    )

    return enriched_chunk, prefix_tokens


# Test enrichment on a sample chunk
test_chunk = Chunk(
    chunk_id="test#chunk_001",
    doc_filename="test.yaml",
    section_heading=None,
    text="This is some test content about Iron-Banes and their history.",
    token_count_approx=15,
    metadata={"type": "faction", "name": "Iron-Banes", "canon": "true"},
)

enriched, prefix_tok = build_enriched_chunk(test_chunk)
print("✓ Sample single-layer enrichment:")
print(f"  Original: {test_chunk.token_count_approx} tokens")
print(f"  Prefix: {prefix_tok} tokens")
print(f"  Enriched: {enriched.token_count_approx} tokens")
print(f"  Prefix text: {enriched.text.split(chr(10))[0]}")
print(f"  Content preview: {enriched.text[enriched.text.index(chr(10)*2):enriched.text.index(chr(10)*2)+50]}...")
```

**Notes**:
- This is the key difference from D-21.
- Prefix is deterministic and derived from metadata only.
- Token counting uses the same approximation heuristic as D-21.
- Safety check prevents token overflow.

---

### Cell 10: Chunk and Enrich Corpus

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Chunk and Enrich Corpus

Applies chunking to all documents, then applies single-layer enrichment to each chunk.

Workflow:
1. For each document in corpus:
   - Apply D-21's chunking strategy (hybrid semantic+token)
   - For each chunk, prepend the single-layer enrichment prefix
   - Track statistics: original vs. enriched token counts, overflow warnings

2. Summary statistics:
   - Total chunks created
   - Average token count (before/after enrichment)
   - Max token count (before/after enrichment)
   - Chunks that exceed max_chunk_tokens (should be zero)

Reference: D-21 Cell 09 (baseline chunking); D-22 Cell 09 (enrichment builder)
"""

import re

enriched_chunks = []
chunk_stats = []

print(f"Chunking and enriching {len(corpus)} documents...")
print(f"  Model: {MODEL_CONFIG.name}")
print(f"  Max chunk tokens: {MODEL_CONFIG.max_chunk_tokens}")
print()

overflow_count = 0

for doc in tqdm(corpus, desc="Chunk & enrich"):
    # Step 1: Apply chunking (D-21 strategy)
    baseline_chunks = chunk_document(doc, MODEL_CONFIG.max_chunk_tokens)

    # Step 2: Apply single-layer enrichment to each chunk
    for chunk in baseline_chunks:
        try:
            enriched_chunk, prefix_tokens = build_enriched_chunk(chunk)
            enriched_chunks.append(enriched_chunk)

            chunk_stats.append({
                "doc_filename": chunk.doc_filename,
                "chunk_id": chunk.chunk_id,
                "original_tokens": chunk.token_count_approx,
                "prefix_tokens": prefix_tokens,
                "enriched_tokens": enriched_chunk.token_count_approx,
                "overflow": enriched_chunk.token_count_approx > MODEL_CONFIG.max_chunk_tokens,
            })

        except ValueError as e:
            print(f"✗ Error enriching {chunk.chunk_id}: {e}")
            overflow_count += 1

# Compute statistics
stats_df = pd.DataFrame(chunk_stats)

print()
print("=" * 70)
print("CHUNK & ENRICHMENT STATISTICS")
print("=" * 70)
print(f"Total chunks created: {len(enriched_chunks)}")
print()
print("Token counts:")
print(f"  Original chunks:")
print(f"    Mean: {stats_df['original_tokens'].mean():.1f} tokens")
print(f"    Median: {stats_df['original_tokens'].median():.1f} tokens")
print(f"    Max: {stats_df['original_tokens'].max():.1f} tokens")
print()
print(f"  Enrichment prefixes:")
print(f"    Mean: {stats_df['prefix_tokens'].mean():.1f} tokens")
print(f"    Median: {stats_df['prefix_tokens'].median():.1f} tokens")
print(f"    Max: {stats_df['prefix_tokens'].max():.1f} tokens")
print()
print(f"  Enriched chunks:")
print(f"    Mean: {stats_df['enriched_tokens'].mean():.1f} tokens")
print(f"    Median: {stats_df['enriched_tokens'].median():.1f} tokens")
print(f"    Max: {stats_df['enriched_tokens'].max():.1f} tokens")
print()
print(f"Overflow check:")
print(f"  Chunks exceeding max ({MODEL_CONFIG.max_chunk_tokens} tokens): {stats_df['overflow'].sum()}")
if overflow_count > 0:
    print(f"  ⚠ WARNING: {overflow_count} chunks exceeded token limit. Increase max_chunk_tokens.")
else:
    print(f"  ✓ All chunks within budget")
print()

# Show examples
print("Sample enriched chunks:")
for i, chunk in enumerate(enriched_chunks[:3]):
    print()
    print(f"  [{i+1}] {chunk.chunk_id}")
    print(f"      Tokens: {chunk.token_count_approx}")
    print(f"      Text preview (first 150 chars):")
    print(f"        {chunk.text[:150]}...")
```

---

### Cell 11: Embedding & ChromaDB Indexing

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Embedding & ChromaDB Indexing

Embeds all enriched chunks using SELECTED_MODEL and indexes them in ChromaDB.

Key differences from D-21:
- Only one model (SELECTED_MODEL, not three models)
- Collection name: d22_single_layer_{model}
- Text to embed includes the enrichment prefix

Workflow:
1. Load embedding model from HuggingFace
2. Batch embed all chunks
3. Create ChromaDB collection with unique name
4. Store embeddings and metadata
5. Track timing

Reference: D-21 Cell 10 (baseline indexing); R-02 (model configuration)
"""

import time

print(f"Loading embedding model: {MODEL_CONFIG.model_id}")
print(f"  (This may take a minute the first time...)")

start_load_time = time.time()
embedding_model = SentenceTransformer(MODEL_CONFIG.model_id)
load_time = time.time() - start_load_time

print(f"✓ Model loaded in {load_time:.1f} seconds")
print(f"  Embedding dimension: {embedding_model.get_sentence_embedding_dimension()}")
print()

# Verify embedding dimension matches config
actual_dim = embedding_model.get_sentence_embedding_dimension()
if actual_dim != MODEL_CONFIG.expected_dim:
    print(f"⚠ WARNING: Expected dimension {MODEL_CONFIG.expected_dim}, got {actual_dim}")

# Prepare embeddings
print(f"Embedding {len(enriched_chunks)} chunks...")
chunk_texts = [chunk.text for chunk in enriched_chunks]

start_embed_time = time.time()
embeddings = embedding_model.encode(
    chunk_texts,
    batch_size=MODEL_CONFIG.batch_size,
    show_progress_bar=True,
)
embed_time = time.time() - start_embed_time

print(f"✓ Embedding completed in {embed_time:.1f} seconds ({len(enriched_chunks)/embed_time:.1f} chunks/sec)")
print(f"  Shape: {embeddings.shape}")
print()

# Set up ChromaDB
collection_name = f"d22_single_layer_{SELECTED_MODEL}"

print(f"Setting up ChromaDB collection: {collection_name}")
client = chromadb.PersistentClient(path=str(CHROMADB_DIR))

# Delete collection if it exists (allow re-runs)
try:
    client.delete_collection(name=collection_name)
    print(f"  (Deleted existing collection for re-run)")
except Exception:
    pass

# Create new collection
collection = client.create_collection(
    name=collection_name,
    metadata={"hnsw:space": "cosine"},  # Cosine similarity (standard for embeddings)
)

print(f"✓ Collection created: {collection_name}")
print()

# Insert embeddings and metadata
print(f"Indexing {len(enriched_chunks)} chunks into ChromaDB...")

for i, (chunk, embedding) in enumerate(tqdm(zip(enriched_chunks, embeddings), total=len(enriched_chunks))):
    # Prepare metadata (exclude large text to save storage)
    metadata = {
        "doc_filename": chunk.doc_filename,
        "doc_type": chunk.metadata.get("type", "unknown"),
        "doc_name": chunk.metadata.get("name", "unknown"),
        "doc_canon": chunk.metadata.get("canon", "false"),
        "chunk_id": chunk.chunk_id,
        "section_heading": chunk.section_heading or "none",
        "token_count": chunk.token_count_approx,
    }

    # Add to collection
    collection.add(
        ids=[chunk.chunk_id],
        embeddings=[embedding.tolist()],
        documents=[chunk.text],  # Store full text (including prefix) for verification
        metadatas=[metadata],
    )

print(f"✓ Indexed {len(enriched_chunks)} chunks")
print()

# Verify collection
collection_stats = collection.count()
print(f"Collection statistics:")
print(f"  Total documents: {collection_stats}")
print(f"  Expected: {len(enriched_chunks)}")
print(f"  ✓ Match!" if collection_stats == len(enriched_chunks) else "✗ Mismatch!")
```

---

### Cell 12: Query Execution

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Query Execution

Runs all 36 ground-truth queries against the D-22 ChromaDB collection.

For each query:
1. Embed the query text using SELECTED_MODEL (same model as chunks)
2. Retrieve top-10 chunks from the collection
3. Store results: chunk_ids, distances, documents, metadata
4. Map retrieved chunks back to source documents for relevance evaluation

Output: query_results dict with structure:
{
  "Q01": {
    "query_text": "...",
    "retrieved_docs": [
      {"chunk_id": "...", "doc_filename": "...", "distance": 0.15, ...},
      ...
    ]
  },
  ...
}

Reference: D-21 Cell 11-12 (baseline query execution)
"""

print(f"Running {len(QUERIES)} queries against collection: {collection_name}")
print()

# Embed all queries at once
query_texts = [q["text"] for q in QUERIES]
query_embeddings = embedding_model.encode(query_texts, batch_size=MODEL_CONFIG.batch_size)

# Run queries
query_results = {}

for query, query_embedding in tqdm(zip(QUERIES, query_embeddings), total=len(QUERIES)):
    query_id = query["query_id"]

    # Retrieve top-10 results
    results = collection.query(
        query_embeddings=[query_embedding.tolist()],
        n_results=10,
    )

    # Unpack results (ChromaDB returns lists because it supports batch queries)
    distances = results["distances"][0]
    doc_ids = results["ids"][0]
    documents = results["documents"][0]
    metadatas = results["metadatas"][0]

    # Combine into structured format
    retrieved_docs = []
    for i, (doc_id, distance, doc_text, metadata) in enumerate(
        zip(doc_ids, distances, documents, metadatas)
    ):
        # Map chunk back to source document
        source_filename = metadata.get("doc_filename", "unknown")

        retrieved_docs.append({
            "rank": i + 1,
            "chunk_id": doc_id,
            "distance": float(distance),
            "doc_filename": source_filename,
            "doc_type": metadata.get("doc_type", "unknown"),
            "doc_name": metadata.get("doc_name", "unknown"),
            "doc_canon": metadata.get("doc_canon", "false"),
            "text_preview": doc_text[:100] + "..." if len(doc_text) > 100 else doc_text,
        })

    query_results[query_id] = {
        "query_text": query["text"],
        "query_type": query["type"],
        "relevant_docs": query.get("relevant_docs", []),
        "retrieved_docs": retrieved_docs,
    }

print(f"✓ Completed {len(query_results)} queries")
print()

# Show sample results
print("Sample query results (Q01 - authority):")
sample_query = query_results["Q01"]
print(f"  Query: {sample_query['query_text']}")
print(f"  Expected relevant docs: {sample_query['relevant_docs']}")
print(f"  Retrieved (top-3):")
for i, doc in enumerate(sample_query["retrieved_docs"][:3]):
    match = "✓" if doc["doc_filename"] in sample_query["relevant_docs"] else "✗"
    print(f"    {match} Rank {doc['rank']}: {doc['doc_filename']} (distance: {doc['distance']:.3f})")
```

---

### Cell 13: Results Introduction

**Type**: Markdown

**Content**:

```markdown
## Results: Single-Layer Enrichment Performance

In this section, we evaluate the impact of single-layer enrichment on retrieval metrics.

### Evaluation Methodology

For each of the 36 ground-truth queries, we compute four metrics:

1. **Precision@5**: Fraction of top-5 retrieved documents that are relevant
2. **Recall@10**: Fraction of all relevant documents that appear in top-10 results
3. **NDCG@10**: Normalized Discounted Cumulative Gain (penalizes ranking; relevance at top ranks counts more)
4. **MRR**: Mean Reciprocal Rank (position of first relevant result)

We then compare D-22 metrics against D-21 baseline:
- **Per-query delta**: D-22 metric - D-21 metric (positive = improvement)
- **Aggregation**: Mean, median, % improved, % degraded
- **Statistical significance**: Wilcoxon signed-rank test (paired, non-parametric)
- **Query type breakdown**: Which types (authority/temporal/factual) benefit most?

### Hypothesis Revisited

- **Primary**: Single-layer enrichment improves recall@10 and NDCG@10
- **Secondary**: Authority-sensitive queries benefit most from canon status in prefix

Let's compute the metrics and see what the data shows.
```

---

### Cell 14: Metric Computation Functions

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Metric Computation Functions

Defines helper functions for computing retrieval metrics:
  - precision@K
  - recall@K
  - ndcg@K
  - mrr (mean reciprocal rank)

These are identical to D-21 Cell 14 and reused without modification.

Reference: D-21 Cell 14; TREC evaluation standards
"""

def precision_at_k(retrieved_docs: List[Dict[str, Any]], relevant_docs: List[str], k: int) -> float:
    """Compute precision@K.

    Precision@K = |{relevant docs in top-K}| / K

    Args:
        retrieved_docs: List of dicts with 'doc_filename' key (in rank order)
        relevant_docs: List of relevant document filenames
        k: Cutoff (compute precision@5, precision@10, etc.)

    Returns:
        Precision@K in range [0, 1]
    """
    if k <= 0 or len(retrieved_docs) == 0:
        return 0.0

    top_k = retrieved_docs[:k]
    relevant_in_top_k = sum(
        1 for doc in top_k if doc["doc_filename"] in relevant_docs
    )

    return relevant_in_top_k / k


def recall_at_k(retrieved_docs: List[Dict[str, Any]], relevant_docs: List[str], k: int) -> float:
    """Compute recall@K.

    Recall@K = |{relevant docs in top-K}| / |{all relevant docs}|

    Args:
        retrieved_docs: List of dicts with 'doc_filename' key (in rank order)
        relevant_docs: List of relevant document filenames
        k: Cutoff

    Returns:
        Recall@K in range [0, 1]
    """
    if len(relevant_docs) == 0:
        return 1.0  # Vacuous truth: if no relevant docs, recall is undefined (treat as 1.0)

    top_k = retrieved_docs[:k]
    relevant_in_top_k = sum(
        1 for doc in top_k if doc["doc_filename"] in relevant_docs
    )

    return relevant_in_top_k / len(relevant_docs)


def ndcg_at_k(retrieved_docs: List[Dict[str, Any]], relevant_docs: List[str], k: int) -> float:
    """Compute normalized discounted cumulative gain (NDCG@K).

    NDCG measures ranking quality, giving exponentially higher weight to
    relevant documents ranked higher.

    Formula:
      DCG@K = sum_{i=1}^{K} rel(i) / log2(i+1)
      where rel(i) = 1 if rank-i doc is relevant, else 0

      IDCG@K = optimal DCG (all relevant docs ranked first)
      NDCG@K = DCG@K / IDCG@K

    Args:
        retrieved_docs: List of dicts with 'doc_filename' key (in rank order)
        relevant_docs: List of relevant document filenames
        k: Cutoff

    Returns:
        NDCG@K in range [0, 1]
    """
    # Compute DCG@K
    dcg = 0.0
    for i, doc in enumerate(retrieved_docs[:k]):
        if doc["doc_filename"] in relevant_docs:
            # Discount by log2(i+2) to match standard TREC formula
            discount = 1.0 / math.log2(i + 2)
            dcg += discount

    # Compute ideal DCG@K (if all relevant docs were ranked first)
    idcg = 0.0
    num_relevant = min(len(relevant_docs), k)
    for i in range(num_relevant):
        discount = 1.0 / math.log2(i + 2)
        idcg += discount

    # Normalize
    if idcg == 0:
        return 0.0

    return dcg / idcg


def mrr(retrieved_docs: List[Dict[str, Any]], relevant_docs: List[str]) -> float:
    """Compute mean reciprocal rank (MRR).

    MRR = 1 / (rank of first relevant document)

    If no relevant document is retrieved, MRR = 0.

    Args:
        retrieved_docs: List of dicts with 'doc_filename' key (in rank order)
        relevant_docs: List of relevant document filenames

    Returns:
        MRR in range [0, 1]
    """
    for i, doc in enumerate(retrieved_docs):
        if doc["doc_filename"] in relevant_docs:
            return 1.0 / (i + 1)

    return 0.0


# Test metrics on a sample query result
sample_retrieved = [
    {"doc_filename": "faction_ironbanes.yaml", "rank": 1},
    {"doc_filename": "faction_shadowborn.yaml", "rank": 2},
    {"doc_filename": "magic_arcana.yaml", "rank": 3},
    {"doc_filename": "entity_void.yaml", "rank": 4},
    {"doc_filename": "faction_ironbanes.yaml", "rank": 5},  # Duplicate (shouldn't happen, but test)
]
sample_relevant = ["faction_ironbanes.yaml"]

p5 = precision_at_k(sample_retrieved, sample_relevant, 5)
r10 = recall_at_k(sample_retrieved, sample_relevant, 10)
ndcg = ndcg_at_k(sample_retrieved, sample_relevant, 10)
mrr_val = mrr(sample_retrieved, sample_relevant)

print("✓ Sample metric computation:")
print(f"  Precision@5: {p5:.3f}")
print(f"  Recall@10: {r10:.3f}")
print(f"  NDCG@10: {ndcg:.3f}")
print(f"  MRR: {mrr_val:.3f}")
```

---

### Cell 15: Compute D-22 Metrics & Load D-21 Baseline

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Compute Metrics & Load D-21 Baseline for Comparison

Workflow:
1. Compute D-22 metrics for all 36 queries using the metric functions from Cell 14
2. Load D-21 baseline results from d21_results.csv
3. Merge into a single comparison DataFrame:
   - columns: model, experiment, query_id, query_type, precision@5, recall@10, ndcg@10, mrr
   - rows: 72 total (36 D-21 baseline + 36 D-22 enriched)
4. Display comparison table

This enables per-query delta analysis in Cell 16.

Reference: D-21 Cell 13 (baseline metrics computation)
"""

# Compute D-22 metrics
d22_metrics = []

print("Computing D-22 metrics for all 36 queries...")

for query_id, result in query_results.items():
    p5 = precision_at_k(result["retrieved_docs"], result["relevant_docs"], 5)
    r10 = recall_at_k(result["retrieved_docs"], result["relevant_docs"], 10)
    ndcg = ndcg_at_k(result["retrieved_docs"], result["relevant_docs"], 10)
    mrr_val = mrr(result["retrieved_docs"], result["relevant_docs"])

    d22_metrics.append({
        "model": SELECTED_MODEL,
        "experiment": "single_layer",
        "query_id": query_id,
        "query_type": result["query_type"],
        "precision@5": p5,
        "recall@10": r10,
        "ndcg@10": ndcg,
        "mrr": mrr_val,
    })

d22_df = pd.DataFrame(d22_metrics)
print(f"✓ Computed {len(d22_df)} D-22 metrics")
print()

# Load D-21 baseline
print(f"Loading D-21 baseline from: {D21_RESULTS_PATH}")
if not D21_RESULTS_PATH.exists():
    print(f"⚠ WARNING: D-21 results file not found: {D21_RESULTS_PATH}")
    print(f"  (This is expected if D-21 has not been run yet)")
    d21_df = pd.DataFrame()  # Empty; no comparison possible
else:
    d21_df = pd.read_csv(D21_RESULTS_PATH)
    print(f"✓ Loaded {len(d21_df)} D-21 baseline metrics")

# Filter D-21 results to selected model only (D-21 tests three models; we compare to winner)
if not d21_df.empty:
    d21_df = d21_df[d21_df["model"] == SELECTED_MODEL].copy()
    print(f"  Filtered to SELECTED_MODEL={SELECTED_MODEL}: {len(d21_df)} rows")

print()

# Combine
comparison_df = pd.concat([d21_df, d22_df], ignore_index=True)

print("=" * 90)
print("D-22 vs D-21 COMPARISON TABLE (Selected Model: {})".format(SELECTED_MODEL))
print("=" * 90)
print()

# Display by query type
for query_type in ["authority", "temporal", "factual"]:
    type_df = comparison_df[comparison_df["query_type"] == query_type].sort_values("query_id")
    print(f"\n{query_type.upper()} QUERIES")
    print("-" * 90)

    # Pivot for side-by-side comparison
    pivot_data = []
    for query_id in type_df["query_id"].unique():
        rows = type_df[type_df["query_id"] == query_id]

        d21_row = rows[rows["experiment"] == "baseline"]
        d22_row = rows[rows["experiment"] == "single_layer"]

        if not d21_row.empty and not d22_row.empty:
            d21 = d21_row.iloc[0]
            d22 = d22_row.iloc[0]

            pivot_data.append({
                "query_id": query_id,
                "P@5 (D21)": f"{d21['precision@5']:.3f}",
                "P@5 (D22)": f"{d22['precision@5']:.3f}",
                "R@10 (D21)": f"{d21['recall@10']:.3f}",
                "R@10 (D22)": f"{d22['recall@10']:.3f}",
                "NDCG@10 (D21)": f"{d21['ndcg@10']:.3f}",
                "NDCG@10 (D22)": f"{d22['ndcg@10']:.3f}",
            })

    if pivot_data:
        pivot_df = pd.DataFrame(pivot_data)
        print(pivot_df.to_string(index=False))

print()
print("✓ Comparison DataFrame ready for delta analysis")
```

---

### Cell 16: Delta Analysis — D-22 vs D-21

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Delta Analysis — Measure Improvement from Single-Layer Enrichment

Computes per-query metric deltas (D-22 - D-21) and aggregates by query type.

Outputs:
  - Mean delta, median delta, std dev for each metric
  - % queries improved, % queries degraded
  - Per-query-type breakdown (hypothesis: authority/temporal queries benefit more)
  - Delta summary table for export to CSV

Reference: R-01 (evaluation methodology); comparison methodology in this notebook's Cell 07
"""

if d21_df.empty:
    print("⚠ Cannot compute delta analysis: D-21 baseline data not found")
    print("  Please run D-21 first and ensure d21_results.csv is available")
else:
    # Build merged DataFrame for delta computation
    # Strategy: for each query, get D-21 and D-22 metrics; compute delta

    delta_rows = []

    for query_id in comparison_df["query_id"].unique():
        query_rows = comparison_df[comparison_df["query_id"] == query_id]

        d21_row = query_rows[query_rows["experiment"] == "baseline"]
        d22_row = query_rows[query_rows["experiment"] == "single_layer"]

        if d21_row.empty or d22_row.empty:
            continue

        d21 = d21_row.iloc[0]
        d22 = d22_row.iloc[0]

        # Compute deltas (positive = improvement)
        delta_p5 = d22["precision@5"] - d21["precision@5"]
        delta_r10 = d22["recall@10"] - d21["recall@10"]
        delta_ndcg = d22["ndcg@10"] - d21["ndcg@10"]
        delta_mrr = d22["mrr"] - d21["mrr"]

        # Flag improvement/degradation
        improved = (delta_p5 > 0) or (delta_r10 > 0) or (delta_ndcg > 0) or (delta_mrr > 0)
        degraded = (delta_p5 < 0) or (delta_r10 < 0) or (delta_ndcg < 0) or (delta_mrr < 0)

        delta_rows.append({
            "query_id": query_id,
            "query_type": d22["query_type"],
            "delta_p5": delta_p5,
            "delta_r10": delta_r10,
            "delta_ndcg": delta_ndcg,
            "delta_mrr": delta_mrr,
            "improved": improved,
            "degraded": degraded,
            "all_metrics_improved": all([delta_p5 >= 0, delta_r10 >= 0, delta_ndcg >= 0, delta_mrr >= 0]),
        })

    delta_df = pd.DataFrame(delta_rows)

    print("=" * 90)
    print("DELTA ANALYSIS: D-22 vs D-21 (Single-Layer Enrichment Impact)")
    print("=" * 90)
    print()

    # Overall statistics
    print("OVERALL STATISTICS (All 36 Queries)")
    print("-" * 90)
    metrics = ["delta_p5", "delta_r10", "delta_ndcg", "delta_mrr"]
    metric_labels = ["Precision@5", "Recall@10", "NDCG@10", "MRR"]

    for metric, label in zip(metrics, metric_labels):
        mean_delta = delta_df[metric].mean()
        median_delta = delta_df[metric].median()
        std_delta = delta_df[metric].std()

        improved_count = (delta_df[metric] > 0).sum()
        degraded_count = (delta_df[metric] < 0).sum()
        unchanged_count = (delta_df[metric] == 0).sum()

        print(f"\n{label}:")
        print(f"  Mean delta: {mean_delta:+.4f}")
        print(f"  Median delta: {median_delta:+.4f}")
        print(f"  Std dev: {std_delta:.4f}")
        print(f"  Improved: {improved_count} queries ({improved_count/len(delta_df)*100:.1f}%)")
        print(f"  Degraded: {degraded_count} queries ({degraded_count/len(delta_df)*100:.1f}%)")
        print(f"  Unchanged: {unchanged_count} queries ({unchanged_count/len(delta_df)*100:.1f}%)")

    print()
    print()

    # Per-query-type breakdown
    print("BY QUERY TYPE")
    print("-" * 90)

    for query_type in ["authority", "temporal", "factual"]:
        type_data = delta_df[delta_df["query_type"] == query_type]

        print(f"\n{query_type.upper()} ({len(type_data)} queries)")

        for metric, label in zip(metrics, metric_labels):
            mean_delta = type_data[metric].mean()
            improved_count = (type_data[metric] > 0).sum()

            print(f"  {label}: mean delta {mean_delta:+.4f}, {improved_count}/{len(type_data)} improved")

    print()
    print()

    # Detailed table
    print("DETAILED DELTA TABLE")
    print("-" * 90)
    display_df = delta_df[[
        "query_id", "query_type", "delta_p5", "delta_r10", "delta_ndcg", "delta_mrr"
    ]].copy()

    # Format numbers
    for col in ["delta_p5", "delta_r10", "delta_ndcg", "delta_mrr"]:
        display_df[col] = display_df[col].apply(lambda x: f"{x:+.4f}")

    print(display_df.to_string(index=False))

    # Export to CSV for later use
    export_df = delta_df[[
        "query_id", "query_type", "delta_p5", "delta_r10", "delta_ndcg", "delta_mrr",
        "improved", "degraded", "all_metrics_improved"
    ]].copy()

    delta_csv_path = OUTPUT_DIR / "d22_delta.csv"
    export_df.to_csv(delta_csv_path, index=False)
    print(f"\n✓ Delta analysis exported to {delta_csv_path}")
```

---

### Cell 17: Statistical Significance Testing

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Statistical Significance Testing

Performs Wilcoxon signed-rank test on per-query metric pairs (D-21 vs D-22).

The Wilcoxon test is appropriate for:
- Paired comparisons (each query has D-21 and D-22 scores)
- Non-parametric (doesn't assume normal distribution)
- Small samples (36 queries)

Null hypothesis: D-22 metrics come from the same distribution as D-21 metrics
Alternative: D-22 metrics are different (two-tailed test)

Significance level: alpha = 0.05

Interpretation:
- p < 0.05: Significant difference (reject null hypothesis)
- p >= 0.05: No significant difference at alpha=0.05

Reference: scipy.stats.wilcoxon documentation; TREC evaluation standards
"""

if delta_df.empty:
    print("⚠ Cannot perform statistical testing: no delta data available")
else:
    print("=" * 90)
    print("WILCOXON SIGNED-RANK TEST: Statistical Significance of Improvement")
    print("=" * 90)
    print()
    print("Test setup:")
    print("  - Null hypothesis: D-22 and D-21 come from same distribution")
    print("  - Alternative: Two-tailed (D-22 != D-21)")
    print("  - Sample: 36 paired queries")
    print("  - Significance level (alpha): 0.05")
    print()

    metrics = ["delta_p5", "delta_r10", "delta_ndcg", "delta_mrr"]
    metric_labels = ["Precision@5", "Recall@10", "NDCG@10", "MRR"]

    results_table = []
    significant_count = 0

    for metric, label in zip(metrics, metric_labels):
        deltas = delta_df[metric].values

        # Wilcoxon test (paired; two-tailed)
        # Note: wilcoxon expects the delta values directly
        stat, p_value = wilcoxon(deltas)

        significant = p_value < 0.05
        significant_count += (1 if significant else 0)

        # Effect size: percentage of positive deltas (as a simple effect measure)
        positive_count = (deltas > 0).sum()
        effect_pct = positive_count / len(deltas) * 100

        results_table.append({
            "metric": label,
            "statistic": f"{stat:.2f}",
            "p_value": f"{p_value:.4f}",
            "significant": "YES" if significant else "NO",
            "effect_pct": f"{effect_pct:.1f}%",
        })

        print(f"{label}:")
        print(f"  Statistic: {stat:.2f}")
        print(f"  P-value: {p_value:.4f}")
        print(f"  Significant (p < 0.05): {'YES ✓' if significant else 'NO ✗'}")
        print(f"  Effect size (% queries improved): {effect_pct:.1f}%")
        print()

    print()

    # Summary
    print("SIGNIFICANCE SUMMARY")
    print("-" * 90)
    if significant_count > 0:
        print(f"✓ {significant_count}/{len(metrics)} metrics show statistically significant improvement (p < 0.05)")
    else:
        print(f"✗ No metrics show statistically significant improvement (p < 0.05)")
    print()

    # Interpretation
    if significant_count == 0:
        print("⚠ INTERPRETATION:")
        print("  Single-layer enrichment does not show statistically significant improvement.")
        print("  However, examine the effect sizes and per-query-type results—practical")
        print("  improvement may still be present even without statistical significance.")
    else:
        print("✓ INTERPRETATION:")
        print("  Single-layer enrichment shows statistically significant improvement.")
        print("  Continue to D-23 (multi-layer enrichment) with confidence.")

    # Results table
    print()
    print("Results table:")
    print(pd.DataFrame(results_table).to_string(index=False))
```

---

### Cell 18: Visualization — Improvement Distribution

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Visualization — Improvement Distribution by Query Type

Creates bar chart showing per-query-type improvement (D-22 - D-21) for each metric.

Chart layout:
  - X-axis: Query type (authority, temporal, factual)
  - Y-axis: Mean metric delta
  - Color: Metric (precision@5, recall@10, ndcg@10, mrr)
  - Positive bars = enrichment helped; negative = enrichment hurt

This helps answer: "Which query types benefit most from single-layer enrichment?"

Reference: Cell 07 hypothesis (authority/temporal expected to benefit more)
"""

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

if delta_df.empty:
    print("⚠ Cannot generate visualization: no delta data available")
else:
    # Aggregate by query type
    agg_data = []

    for query_type in ["authority", "temporal", "factual"]:
        type_data = delta_df[delta_df["query_type"] == query_type]

        for metric, label in zip(
            ["delta_p5", "delta_r10", "delta_ndcg", "delta_mrr"],
            ["P@5", "R@10", "NDCG@10", "MRR"]
        ):
            mean_delta = type_data[metric].mean()
            agg_data.append({
                "query_type": query_type.capitalize(),
                "metric": label,
                "mean_delta": mean_delta,
            })

    agg_df = pd.DataFrame(agg_data)

    # Create figure
    fig, ax = plt.subplots(figsize=(12, 6))

    # Prepare data for grouped bar chart
    query_types = ["Authority", "Temporal", "Factual"]
    metrics = ["P@5", "R@10", "NDCG@10", "MRR"]
    colors = ["#1f77b4", "#ff7f0e", "#2ca02c", "#d62728"]

    bar_width = 0.2
    x_pos = np.arange(len(query_types))

    for i, metric in enumerate(metrics):
        values = []
        for query_type in query_types:
            val = agg_df[
                (agg_df["query_type"] == query_type) & (agg_df["metric"] == metric)
            ]["mean_delta"].values
            values.append(val[0] if len(val) > 0 else 0)

        offset = bar_width * (i - 1.5)
        ax.bar(x_pos + offset, values, bar_width, label=metric, color=colors[i], alpha=0.8)

    # Styling
    ax.axhline(y=0, color="black", linestyle="-", linewidth=0.5)
    ax.set_xlabel("Query Type", fontsize=12, fontweight="bold")
    ax.set_ylabel("Mean Metric Delta (D-22 - D-21)", fontsize=12, fontweight="bold")
    ax.set_title("Single-Layer Enrichment: Improvement by Query Type", fontsize=14, fontweight="bold")
    ax.set_xticks(x_pos)
    ax.set_xticklabels(query_types)
    ax.legend(loc="best", fontsize=10)
    ax.grid(axis="y", alpha=0.3)

    # Save
    viz_path = OUTPUT_DIR / "visualization_improvement_distribution.png"
    plt.tight_layout()
    plt.savefig(viz_path, dpi=150, bbox_inches="tight")
    print(f"✓ Saved improvement distribution chart to {viz_path}")
    plt.close()
```

---

### Cell 19: Visualization — Side-by-Side Heatmap

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Visualization — Side-by-Side Heatmap (D-21 vs D-22)

Creates two heatmaps side by side:
  - Left: D-21 baseline metrics for all 36 queries
  - Right: D-22 enriched metrics for all 36 queries
  - Delta values annotated in cells

Heatmap layout:
  - Rows: queries (Q01-Q36, grouped by type)
  - Columns: metrics (precision@5, recall@10, ndcg@10, mrr)
  - Color intensity: metric value (dark = low, bright = high)

This provides a visual overview of which queries improved/degraded.

Reference: TREC visualization standards
"""

import matplotlib.pyplot as plt
import seaborn as sns

if comparison_df.empty:
    print("⚠ Cannot generate heatmap: no comparison data available")
else:
    # Prepare data for heatmaps
    query_order = [q["query_id"] for q in QUERIES]  # Q01-Q36
    metrics_cols = ["precision@5", "recall@10", "ndcg@10", "mrr"]

    # Extract D-21 and D-22 matrices
    d21_data = comparison_df[comparison_df["experiment"] == "baseline"].set_index("query_id")
    d22_data = comparison_df[comparison_df["experiment"] == "single_layer"].set_index("query_id")

    d21_matrix = d21_data.loc[query_order, metrics_cols].values
    d22_matrix = d22_data.loc[query_order, metrics_cols].values
    delta_matrix = d22_matrix - d21_matrix

    # Create figure with two heatmaps
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 12))

    # Heatmap 1: D-21 baseline
    sns.heatmap(
        d21_matrix,
        annot=True,
        fmt=".2f",
        cmap="RdYlGn",
        vmin=0,
        vmax=1,
        ax=ax1,
        cbar_kws={"label": "Metric Value"},
        xticklabels=metrics_cols,
        yticklabels=query_order,
    )
    ax1.set_title("D-21: Baseline (Raw Chunks)", fontsize=14, fontweight="bold")
    ax1.set_ylabel("Query ID", fontsize=12, fontweight="bold")

    # Heatmap 2: D-22 enriched
    sns.heatmap(
        d22_matrix,
        annot=True,
        fmt=".2f",
        cmap="RdYlGn",
        vmin=0,
        vmax=1,
        ax=ax2,
        cbar_kws={"label": "Metric Value"},
        xticklabels=metrics_cols,
        yticklabels=query_order,
    )
    ax2.set_title("D-22: Single-Layer Enrichment", fontsize=14, fontweight="bold")
    ax2.set_ylabel("Query ID", fontsize=12, fontweight="bold")

    plt.suptitle("D-22 vs D-21 Comparison: Metric Heatmaps", fontsize=16, fontweight="bold", y=0.995)

    # Save
    viz_path = OUTPUT_DIR / "visualization_heatmap_comparison.png"
    plt.tight_layout()
    plt.savefig(viz_path, dpi=150, bbox_inches="tight")
    print(f"✓ Saved heatmap comparison to {viz_path}")
    plt.close()

    # Also export delta matrix as CSV for inspection
    delta_export_df = pd.DataFrame(
        delta_matrix,
        index=query_order,
        columns=metrics_cols,
    )
    delta_matrix_path = OUTPUT_DIR / "d22_delta_matrix.csv"
    delta_export_df.to_csv(delta_matrix_path)
    print(f"✓ Saved delta matrix to {delta_matrix_path}")
```

---

### Cell 20: Export Results

**Type**: Code

**Content**:

```python
#!/usr/bin/env python3
"""
D-22: Export Results

Exports all results to CSV files and persists ChromaDB collection.

Output files:
  1. d22_results.csv: Per-query metrics (same format as D-21)
  2. d22_delta.csv: Per-query deltas (D-22 - D-21)
  3. d22_delta_matrix.csv: Delta matrix (queries x metrics)
  4. chromadb/: Persisted ChromaDB with d22_single_layer_{model} collection

These files enable:
  - Comparison with D-21 baseline
  - Re-use in D-23 without re-running D-22
  - Integration with downstream analysis

Reference: D-21 Cell 15 (baseline export format)
"""

# Export D-22 metrics
d22_export = d22_df[[
    "model", "experiment", "query_id", "query_type",
    "precision@5", "recall@10", "ndcg@10", "mrr"
]].copy()

results_csv_path = OUTPUT_DIR / "d22_results.csv"
d22_export.to_csv(results_csv_path, index=False)
print(f"✓ Exported D-22 metrics to {results_csv_path}")
print(f"  {len(d22_export)} rows (36 queries)")
print()

# Display sample
print("Sample exported metrics (first 5 rows):")
print(d22_export.head().to_string(index=False))
print()

# ChromaDB is already persisted (created in Cell 11)
print(f"✓ ChromaDB collection persisted at {CHROMADB_DIR}")
print(f"  Collection: {collection_name}")
print(f"  Documents indexed: {collection.count()}")
print()

# Summary
print("=" * 90)
print("EXPORT SUMMARY")
print("=" * 90)
print()
print(f"Output directory: {OUTPUT_DIR}")
print()
print("Files created:")
print(f"  ✓ d22_results.csv ({len(d22_export)} queries)")
print(f"  ✓ d22_delta.csv (delta analysis)")
print(f"  ✓ d22_delta_matrix.csv (delta matrix)")
print(f"  ✓ visualization_improvement_distribution.png")
print(f"  ✓ visualization_heatmap_comparison.png")
print(f"  ✓ chromadb/ (ChromaDB index)")
print()
print("Next steps:")
print("  1. Review d22_results.csv for metric values")
print("  2. Compare d22_delta.csv against D-21 baseline")
print("  3. Check visualizations for patterns by query type")
print("  4. Run statistical tests (Cell 17) to determine go/no-go for D-23")
```

---

### Cell 21: C# Implementation Implications

**Type**: Markdown

**Content**:

```markdown
## C# Implementation Implications

### Feasibility Assessment

The single-layer enrichment prefix is **trivially implementable in C#**:

```csharp
public static string BuildSingleLayerPrefix(DocumentMetadata metadata)
{
    var docType = metadata.Type?.ToLower() ?? "unknown";
    var docName = metadata.Name?.Trim() ?? "Unknown";
    var canon = metadata.Canon?.ToLower() == "true" ? "true" : "false";

    return $"This is a {docType} document about {docName}. Canon status: {canon}.";
}

public static string BuildEnrichedChunk(string originalText, DocumentMetadata metadata)
{
    var prefix = BuildSingleLayerPrefix(metadata);
    return $"{prefix}\n\n{originalText}";
}
```

### Token Budget Implications

- **Single layer prefix**: ~15-25 tokens
- **Embed this overhead in the chunking logic** when splitting documents
- **No performance impact**: String operations are negligible vs. embedding latency

### Design Decisions for C# Implementation

1. **Metadata source**: Parse document YAML frontmatter at load time (same as D-20/D-21)
2. **Prefix format**: Keep identical to D-22 for consistency
3. **Embedding workflow**: Enrich chunks before passing to embedding model
4. **Token estimation**: Use same heuristic (word count × 1.3) for decision-making

### Validation Checklist

- [ ] Single-layer enrichment shows positive mean delta across metrics
- [ ] At least one metric reaches statistical significance (p < 0.05)
- [ ] No chunk exceeds token limits after enrichment
- [ ] Authority-sensitive queries show expected improvement
- [ ] C# implementation matches Python output exactly

### Cost-Benefit Summary

| Factor | Impact |
|--------|--------|
| Implementation cost | Minimal (20 lines of code) |
| Runtime overhead | Negligible (<1% latency increase) |
| Token budget | ~2.5% for v2-moe, <1% for v1.5/BGE-M3 |
| Expected benefit | Measurable improvement in retrieval metrics |
| Risk | Low (simple deterministic prefix) |

**Recommendation**: Include single-layer enrichment as a baseline feature in all future C# implementations. This is a "free" improvement with no practical downside.
```

---

### Cell 22: Next Steps for D-23

**Type**: Markdown

**Content**:

```markdown
## Next Steps: D-23 (Notebook 3: Multi-Layer Enrichment)

### Go/No-Go Decision Point

D-22's results determine the direction of D-23:

**GO conditions**:
- Mean metric improvement across queries > 0% (enrichment helps)
- At least one metric shows statistical significance (p < 0.05)
- No major token overflow issues

**NO-GO conditions**:
- Mean metric improvement < 0% (enrichment hurts)
- No statistical significance and effect sizes < 5%
- Token constraints become binding (even single layer problematic)

### D-23 Scope

If GO: D-23 will add **all 8 context layers** (vs. the single layer tested in D-22):

| Layer | Content | Token Budget |
|-------|---------|--------------|
| Corpus | "Part of FractalRecall corpus" | ~5 tokens |
| Domain | "Domain: {domain_layer}" | ~5 tokens |
| Entity | "Entities: {related_entities}" | ~15-30 tokens |
| Authority | "Authority: {authority_layer}" | ~5 tokens |
| Temporal | "Time period: {era}" | ~10 tokens |
| Relational | "Related to: {links}" | ~20 tokens |
| Section | "{section_heading}" | ~5 tokens |
| Content | (same as D-22) | ~15-25 tokens |
| **TOTAL** | | ~50-150 tokens |

### Token Budget Analysis

- **v2-moe (512 tokens)**:
  - 8-layer prefix: ~80-120 tokens (worst case 150)
  - Content budget: 512 - 150 = 362 tokens (tight; may require smaller chunks)
  - **Decision**: Consider dropping lowest-value layers (Corpus, Domain) if overflow occurs

- **v1.5 / BGE-M3 (8192 tokens)**:
  - 8-layer prefix: ~100 tokens (negligible relative to window)
  - Content budget: 8192 - 100 = 8092 tokens (ample)
  - **Decision**: Include all 8 layers with full verbosity

### Success Criteria for D-23

1. **Execution**: Notebook runs without token overflow (< 5% of chunks exceed limit)
2. **Improvement over D-22**: Mean metric delta (D-23 - D-22) > 0 for at least 2 metrics
3. **Marginal returns**: If D-23 improvement < 10% over D-22, question whether layers 5-8 are worth the complexity
4. **Statistical significance**: Wilcoxon p < 0.05 for at least 2 metrics
5. **Practical usefulness**: All query types show positive mean delta (enrichment is universally beneficial)

### Hypothesis for D-23

**Primary**: Multi-layer enrichment will improve recall@10 and NDCG@10 more than single-layer.

**Secondary**:
- Entity and relational layers will provide the most marginal value
- Temporal layer will particularly benefit temporal queries (Q13-Q24)
- Authority layer will amplify D-22's improvement for authority-sensitive queries (Q01-Q12)

### Critical Dependencies

- **D-21**: Must be completed; SELECTED_MODEL constant must be set
- **D-22**: Must be completed; results provide baseline for delta analysis
- **R-01, R-02, R-03**: References for methodology and theory

### Timeline Estimate

- **D-23 development**: 4-6 hours (designing 8-layer prefix format, testing overflows)
- **D-23 execution**: 2-3 hours (embedding and querying)
- **Analysis**: 2-3 hours (comparison, visualization, statistics)
- **Total**: ~10 hours

### Known Risks for D-23

1. **Token overflow for v2-moe**: May need to reduce chunk size below D-21 baseline
2. **Diminishing returns**: Each additional layer has smaller marginal impact
3. **Complexity vs. benefit**: 8 layers is significantly more complex than 1 layer
4. **Metadata availability**: Some fields (era, related_entities) may be missing/incomplete in corpus
5. **Parameter explosion**: Testing all layer combinations would be intractable; D-23 uses all 8 by default

### Success Threshold for Production Deployment

FractalRecall's multi-layer enrichment approach is justified by D-23 if:

1. **D-23 shows > 20% improvement over D-21 baseline** (not just vs. D-22)
2. **All three models (v2-moe, v1.5, BGE-M3) reach significance**
3. **Authority and temporal query types benefit most** (aligns with hypothesis)
4. **C# implementation is straightforward** (no model-specific tricks)
5. **Token overhead is acceptable** (< 15% of budget on smallest model)

---

**Questions to revisit before D-23**:
- Should we test layer ablations (e.g., D-23a without Entity layer, D-23b without Relational)?
- Or commit fully to all 8 layers and measure their combined effect?
```

---

## 4. Expected Outputs

| Filename | Format | Rows | Purpose |
|----------|--------|------|---------|
| d22_results.csv | CSV | 36 | Per-query metrics (P@5, R@10, NDCG@10, MRR) |
| d22_delta.csv | CSV | 36 | Per-query deltas (D-22 - D-21); improvement flags |
| d22_delta_matrix.csv | CSV | 36 x 4 | Delta matrix (queries × metrics) for visualization |
| visualization_improvement_distribution.png | PNG | 1 | Bar chart: improvement by query type and metric |
| visualization_heatmap_comparison.png | PNG | 1 | Side-by-side heatmaps (D-21 vs D-22) |
| notebook.ipynb | Jupyter | 22 cells | Executable notebook with all cells and outputs |
| chromadb/d22_single_layer_{model} | ChromaDB | 200-250 | Indexed enriched chunks |

---

## 5. Comparison Methodology

### Overview

D-22 vs. D-21 comparison uses a **paired evaluation design**:
- Same 36 queries
- Same model (SELECTED_MODEL from D-21)
- Same corpus, same chunks, same evaluation metrics
- **Only difference**: presence/absence of single-layer enrichment prefix

### Metrics

Four retrieval metrics computed for each query:

1. **Precision@5**: `P@5 = |relevant ∩ top-5| / 5`
   - Sensitivity to ranking quality within top-5
   - High precision = few irrelevant results at the top

2. **Recall@10**: `R@10 = |relevant ∩ top-10| / |relevant|`
   - Sensitivity to completeness of retrieval
   - High recall = most relevant documents retrieved

3. **NDCG@10**: Normalized Discounted Cumulative Gain
   - Penalizes ranking (relevant at top-1 better than top-10)
   - Formula: `DCG@10 / IDCG@10` where `DCG = Σ(rel(i) / log2(i+1))`

4. **MRR**: Mean Reciprocal Rank
   - `MRR = 1 / rank_of_first_relevant`
   - Sensitivity to speed of finding first relevant result

### Delta Analysis

For each query and metric:

```
Delta = D-22 metric - D-21 metric

Positive delta = enrichment improved retrieval
Negative delta = enrichment degraded retrieval
Zero delta = no change
```

### Aggregation Strategy

1. **Per-metric aggregation**:
   - Mean delta across all 36 queries
   - Median delta (robust to outliers)
   - Standard deviation
   - % queries improved / degraded

2. **Per-query-type aggregation**:
   - Authority (Q01-Q12): Test if canon status helps
   - Temporal (Q13-Q24): Test if type/name helps
   - Factual (Q25-Q36): Test baseline semantic improvement

3. **Statistical aggregation**:
   - Wilcoxon signed-rank test (paired, non-parametric)
   - Null hypothesis: D-22 and D-21 from same distribution
   - p < 0.05 = significant difference

### Relevance Tier Breakdown (Optional)

If corpus includes relevance scores (e.g., "highly relevant" vs. "marginally relevant"), also analyze:
- Does enrichment help retrieve high-relevance documents more effectively?
- Are low-relevance documents suppressed or promoted?

---

## 6. Known Limitations

### 1. Model Selection Dependency

- D-22 uses SELECTED_MODEL from D-21 (default v1.5)
- If D-21 has not been run, D-22 cannot execute
- Mitigation: Default provided; user must update constant after D-21

### 2. Static Prefix per Document

- All chunks from the same document share one prefix
- No section-level variation (reserved for D-23)
- Limitation: Fine-grained contextual information is lost
- Mitigation: D-23 will test multiple layers; may identify value of section-level context

### 3. Token Counting Approximation

- Uses heuristic (word count × 1.3) instead of actual tokenization
- May underestimate or overestimate true token count
- Limitation: Possible token overflow on constrained models (v2-moe)
- Mitigation: Safety margin (prefix_reserve_tokens) built into chunking

### 4. Small Query Sample

- 36 queries may not reach statistical significance for small effects (< 5% improvement)
- Limitation: Query-type subgroups (12 queries each) are even smaller
- Mitigation: Report effect sizes in addition to p-values; interpret practically

### 5. Limited Metadata Coverage

- Assumes all documents have complete frontmatter (type, name, canon)
- Some fields (authority_layer, related_entities) may be missing
- Limitation: Incomplete metadata results in less informative prefix
- Mitigation: Use sensible defaults (unknown, false); don't fail on missing fields

### 6. No Cross-Validation

- Single train/test split (all 25 documents used)
- No holdout test set; all queries use corpus as retrieval target
- Limitation: Cannot estimate generalization to new documents
- Mitigation: D-23 may include cross-validation; D-22 focuses on within-corpus retrieval

### 7. Embedding Model Assumptions

- Assumes selected model is suitable for corpus (English, 768-1024 dims)
- No multi-lingual or specialized domain testing
- Limitation: Results may not generalize to other domains
- Mitigation: Select model based on D-21 results (which tested three options)

---

## 7. Amendments to Upstream Documents

### D-21 (Notebook 1: Baseline)

**Addition to D-21 Cell 13 (Metric Export)**:

```markdown
## Export Instructions for D-22 Comparison

To enable D-22 to load D-21's baseline for comparison, ensure:

1. Export results to: `/mnt/0000_concurrent/d21_output/d21_results.csv`
2. Format: columns = [model, experiment, query_id, query_type, precision@5, recall@10, ndcg@10, mrr]
3. Update SELECTED_MODEL in D-22 Cell 03 to match D-21's winning model
```

### D-20 (Test Corpus Preparation)

**No amendments needed**. D-22 reuses D-20 corpus as-is.

### R-03 (Anthropic Contextual Retrieval)

**Cross-reference in D-22 Cell 07**:

```markdown
This notebook implements a lightweight variant of Contextual Retrieval (R-03).
- R-03 uses LLM-generated summaries
- D-22 uses static metadata from frontmatter
- Both prepend context before embedding
- Comparison: D-22 is cheaper (no LLM), but may be less nuanced
```

---

## 8. Open Questions

### OQ-D22-1: Should the prefix include authority_layer?

**Question**: D-22's prefix currently includes only canon status. Should it also include authority_layer (e.g., "official", "fan", "fanon")?

**Rationale**: Authority-sensitive queries (Q01-Q12) might benefit more from explicit authority information.

**Approach**: Post-hoc analysis—compute prefix with/without authority_layer using D-22's indexed chunks; measure delta in retrieval metrics.

**Expected resolution**: D-23 will test this as part of multi-layer design.

### OQ-D22-2: Would a more verbose prefix improve results further?

**Question**: Current prefix is one sentence (~15-25 tokens). Would 2-3 sentences (e.g., including purpose/domain) improve retrieval?

**Rationale**: Richer context might better ground chunk semantics.

**Approach**: A/B test longer prefixes post-hoc using D-22's indexed chunks.

**Expected resolution**: D-23 will test multi-sentence prefixes (8 layers, ~50-150 tokens total).

### OQ-D22-3: Does the prefix help more for short chunks or long chunks?

**Question**: Is enrichment more beneficial for short chunks (where prefix is proportionally larger) or long chunks (where semantic density might be lower)?

**Rationale**: Token budget implications differ; shorter chunks are more common in constrained models.

**Approach**: Stratify delta analysis by chunk length (short/medium/long); compute per-stratum improvement.

**Expected resolution**: D-23 analysis will examine layer-by-layer contributions, implicitly testing this.

### OQ-D22-4: Can we predict which queries will benefit from enrichment?

**Question**: Are there query properties (length, specificity, query_type) that predict whether enrichment helps?

**Rationale**: Might inform adaptive enrichment strategies.

**Approach**: Logistic regression (features: query properties; target: improved vs. degraded).

**Expected resolution**: D-23+ analysis.

---

## 9. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-11 | Ryan + Claude | Initial complete specification (22 cells, all sections) |

---

## Appendix A: References

### Documents

- **D-20**: Test Corpus Preparation (25 YAML documents, frontmatter schema)
- **D-21**: Notebook 1: Baseline (3-model comparison; chunking strategy; query set)
- **D-23**: Notebook 3: Multi-Layer Enrichment (planned; 8 context layers)

### Research Papers & Methods

- **R-01**: Retrieval Evaluation Methodology (TREC standards; metric definitions)
- **R-02**: Embedding Model Sizing & Token Budgeting (model configurations; context windows)
- **R-03**: Anthropic Contextual Retrieval (contextual prefix prepending; LLM-based summaries)

### External References

- Sentence-Transformers Documentation: https://www.sbert.net/
- ChromaDB API: https://docs.trychroma.com/
- SciPy Wilcoxon Test: https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.wilcoxon.html
- NDCG Definition: https://en.wikipedia.org/wiki/Discounted_cumulative_gain

---

## Appendix B: Configuration Constants Quick Reference

```python
# Model selection (update after D-21)
SELECTED_MODEL = "v1.5"  # Options: "v2-moe", "v1.5", "bge-m3"

# Paths
CORPUS_DIR = Path("/mnt/0000_concurrent/d20_corpus")
OUTPUT_DIR = Path("/mnt/0000_concurrent/d22_output")
D21_RESULTS_PATH = Path("/mnt/0000_concurrent/d21_output/d21_results.csv")

# Queries: 36 total
# - Authority: Q01-Q12 (12 queries)
# - Temporal: Q13-Q24 (12 queries)
# - Factual: Q25-Q36 (12 queries)

# Metrics computed per query
METRICS = ["precision@5", "recall@10", "ndcg@10", "mrr"]

# Statistical testing
SIGNIFICANCE_LEVEL = 0.05  # alpha for Wilcoxon test
TEST_TYPE = "wilcoxon"     # signed-rank test (paired, non-parametric)
```

---

## Appendix C: Troubleshooting

### Issue: D-21 results not found

**Message**: `⚠ D-21 results file not found: /mnt/0000_concurrent/d21_output/d21_results.csv`

**Cause**: D-21 has not been run yet.

**Solution**:
1. Run D-21 notebook first
2. Ensure d21_results.csv is exported to the correct path
3. Update SELECTED_MODEL in D-22 Cell 03 with D-21's winning model

### Issue: Enriched chunks exceed token limit

**Message**: `✗ Enriched chunk faction_ironbanes.yaml#chunk_001 exceeds token limit: 450 > 400 tokens`

**Cause**: prefix_reserve_tokens is set too low.

**Solution**:
1. Increase prefix_reserve_tokens in ModelConfig
2. Reduce max_chunk_tokens (trade-off: fewer, longer chunks)
3. Check that corpus doesn't contain unusually long chunks

### Issue: ChromaDB collection already exists

**Message**: `chromadb.errors.InvalidCollectionException: Collection d22_single_layer_v1.5 already exists`

**Cause**: D-22 was run before; collection persists.

**Solution**: Cell 11 includes deletion logic. If it fails, manually delete the collection:

```python
client = chromadb.PersistentClient(path=str(CHROMADB_DIR))
client.delete_collection(name="d22_single_layer_v1.5")
```

---

**End of D-22 Specification Document**
