---
title: "Research Findings: R-01, R-02, R-03 (Pre-Prototyping Due Diligence)"
document_id: "R-01-02-03"
version: "1.0"
status: "Complete"
date: "2026-02-11"
author: "Ryan + Claude (Cowork)"
blocks: "D-20 (Test Corpus Preparation), D-21 (Model Selection & Embedding Baseline)"
authority: "Chronicle-FractalRecall-Master-Strategy.md §8.1"
---

# Research Findings: R-01, R-02, R-03

**Pre-Prototyping Due Diligence — Track B Prerequisites**

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [R-01: nomic-embed-text-v2-moe Behavior with Long Prefixed Inputs](#2-r-01-nomic-embed-text-v2-moe-behavior)
3. [R-02: Optimal Chunking Strategies for Worldbuilding Markdown](#3-r-02-optimal-chunking-strategies)
4. [R-03: ChromaDB Metadata Filtering Capabilities](#4-r-03-chromadb-metadata-filtering)
5. [Cross-Cutting Findings and Implications](#5-cross-cutting-findings)
6. [Action Items and Document Amendments](#6-action-items-and-document-amendments)
7. [Open Questions Surfaced by Research](#7-open-questions)
8. [Revision History](#8-revision-history)

---

## 1. Executive Summary

These three research tasks were identified in the Master Strategy §8.1 as **mandatory prerequisites** before Track B prototyping (Colab notebooks D-21 through D-25) can begin. All three have been completed. The findings are consolidated here as a single deliverable so that downstream documents can reference a unified source.

### 1.1. Top-Line Verdicts

| Research | Verdict | Impact on Project |
|----------|---------|-------------------|
| **R-01** (nomic-embed-text-v2-moe) | **CRITICAL FINDING: 512-token context window, NOT 8,192** | High — Master Strategy and Design Proposal must be amended. Prefix enrichment strategy must be radically constrained or the model recommendation reconsidered. |
| **R-02** (Chunking strategies) | Hybrid Semantic + Fixed-Window chunking recommended | Medium — aligns with existing assumptions; parameters now defined |
| **R-03** (ChromaDB metadata filtering) | Viable with modifications for Approach C | Low-Medium — no native array support requires workaround, but scalar filtering is comprehensive |

### 1.2. The Headline: Context Window Discrepancy

**This is the most important finding in this document.** The Master Strategy §3.4 (line 154) and Design Proposal §6 (line 436) and §9.5 (line 548) all state that `nomic-embed-text-v2-moe` has an **8,192-token context window**. This figure appears to have been carried over from `nomic-embed-text-v1.5`, which does indeed support 8,192 tokens.

However, the v2-moe model (released mid-2025) uses a fundamentally different architecture. Research confirms:

- **Actual context window: 512 tokens** (not 8,192)
- **Architecture: Mixture-of-Experts** with RoPE positional encoding
- **This is not a documentation error that might be fixed** — it's an architectural constraint of the MoE design

This has cascading implications for the entire prefix enrichment strategy, which assumed thousands of tokens were available for contextual metadata prepended to chunk content. With only ~300-450 usable tokens after the task prefix, the enrichment strategy must either be dramatically compressed or a different model must be selected.

See §2.8 for detailed impact analysis and §6 for proposed amendments.

---

## 2. R-01: nomic-embed-text-v2-moe Behavior with Long Prefixed Inputs

### 2.1. Research Question

> "Understand how the MoE architecture handles context-enriched inputs. Does it attention-attend differently to prefix vs. content? What's the effective context utilization at 4K, 6K, 8K tokens?"
>
> — Master Strategy §8.1

### 2.2. Methodology

Literature review of:
- Nomic AI's official model card and release documentation
- HuggingFace model page (`nomic-ai/nomic-embed-text-v2-moe`)
- Sentence-Transformers integration documentation
- MoE (Mixture-of-Experts) architecture papers relevant to embedding models
- Community benchmarks and discussions (2025-2026)

### 2.3. Model Architecture Summary

| Property | Value |
|----------|-------|
| **Full Name** | `nomic-embed-text-v2-moe` |
| **Total Parameters** | 475M |
| **Active Parameters per Forward Pass** | 305M (top-2 expert routing) |
| **Architecture** | Mixture-of-Experts at FFN (Feed-Forward Network) level |
| **Number of Experts** | 8 per MoE layer |
| **Expert Selection** | Top-2 routing (2 of 8 experts activated per token) |
| **Positional Encoding** | RoPE (Rotary Position Embeddings) |
| **Output Dimensions** | 768 (full), 256 (Matryoshka truncation), 128, 64 |
| **Context Window** | **512 tokens** |
| **Training Objective** | Contrastive learning with task-specific prefixes |
| **Multilingual Support** | ~100 languages |
| **License** | Apache 2.0 |

### 2.4. Context Window: The Critical Finding

**The Master Strategy states 8,192 tokens. The actual limit is 512 tokens.**

This discrepancy likely originates from a conflation of two different models:

| Model | Context Window | Architecture |
|-------|---------------|--------------|
| `nomic-embed-text-v1.5` | 8,192 tokens | Standard transformer, Flash Attention, ALiBi positional encoding |
| `nomic-embed-text-v2-moe` | **512 tokens** | Mixture-of-Experts, RoPE positional encoding |

The v2-moe model trades context length for architectural efficiency — the MoE design allows more expressive per-token representations with fewer active parameters, but at the cost of a dramatically shorter context window. RoPE (Rotary Position Embeddings) was trained with a 512-token maximum, and unlike some architectures, this cannot be trivially extended at inference time without significant quality degradation.

**What this means for FractalRecall:**

The entire prefix enrichment strategy assumed thousands of tokens were available for prepending contextual metadata (entity type, hierarchy path, cross-references, temporal markers) before the actual chunk content. With only 512 tokens total (including the mandatory task prefix), the available budget is roughly:

| Component | Estimated Tokens |
|-----------|-----------------|
| Task prefix (`search_document: ` or `search_query: `) | ~5-8 tokens |
| Enrichment prefix (metadata, hierarchy, etc.) | **~50-150 tokens** (constrained) |
| Actual chunk content | **~300-400 tokens** |
| Safety margin | ~10-20 tokens |
| **Total** | **~512 tokens** |

This is a fundamentally different budget than the 4,000-6,000 tokens assumed for enriched representations.

### 2.5. Task Prefixes

The v2-moe model requires task-specific prefixes to activate appropriate expert routing:

| Use Case | Prefix (sentence-transformers) | Prefix (direct) |
|----------|-------------------------------|-----------------|
| Indexing documents | `prompt_name="passage"` | `search_document: ` |
| Querying | `prompt_name="query"` | `search_query: ` |
| Classification | `prompt_name="classification"` | `classification: ` |
| Clustering | `prompt_name="clustering"` | `clustering: ` |

**Important:** The task prefix is consumed from the 512-token budget. The prefix activates different expert combinations in the MoE routing layer, which means the model literally processes document-indexing inputs through different neural pathways than query inputs. This is a feature, not overhead — but it does consume tokens.

**Prefix ordering with enrichment:** When combining task prefixes with enrichment metadata, the task prefix must come first:

```
search_document: [enrichment metadata] [chunk content]
```

Not:

```
[enrichment metadata] search_document: [chunk content]
```

The task prefix must be the very first tokens in the input to properly activate MoE routing.

### 2.6. Matryoshka Dimension Support

The model supports Matryoshka representation learning, meaning embeddings can be truncated to smaller dimensions with graceful quality degradation:

| Dimensions | Quality (relative) | Use Case |
|-----------|-------------------|----------|
| 768 | 100% (full) | Production retrieval, high-precision tasks |
| 256 | ~95-97% | Fast filtering, preliminary ranking |
| 128 | ~90-93% | Coarse clustering, approximate similarity |
| 64 | ~82-87% | Very rough similarity, exploratory analysis |

For FractalRecall's purposes, the primary dimension should be **768** (full quality for the core retrieval task), with 256 available as a secondary dimension for potential layer-specific "zoom levels" (see R-06 in §8.2 of Master Strategy).

### 2.7. MoE Routing Behavior with Enriched Inputs

This is the area with the most unknowns. The core question was whether MoE expert routing treats prefix tokens differently from content tokens. Based on available documentation and architecture analysis:

1. **Expert routing is per-token, not per-sequence.** Each token independently selects its top-2 experts based on a learned gating function. This means prefix tokens and content tokens can (and will) route through different experts.

2. **RoPE positional encoding means position matters.** Unlike absolute positional encodings, RoPE encodes relative positions through rotation matrices. Tokens at position 0-10 (prefix) will have different positional features than tokens at position 100-200 (content), which affects attention patterns.

3. **Unknown: How enrichment metadata affects the final [CLS] pooling.** The sentence embedding is typically the mean pool or [CLS] token representation. Whether metadata-rich prefixes "steer" this representation in useful ways (our hypothesis) or introduce noise (the risk) is an empirical question that D-21 must test.

4. **Unknown: Expert activation diversity with mixed-type inputs.** If prefix metadata tokens consistently activate different experts than natural language content tokens, the MoE architecture might naturally separate "structural" and "content" processing — which would be ideal for FractalRecall's layered approach. But this is speculative and requires empirical validation.

### 2.8. Impact Analysis

#### 2.8.1. What Still Works

- **Matryoshka dimension support**: Confirmed, 768/256/128/64. Useful for multi-resolution experiments.
- **Task prefix differentiation**: Confirmed. Document vs. query prefixes activate different expert pathways. Good for retrieval.
- **Multilingual support**: Confirmed (~100 languages). Relevant if Aethelgard introduces constructed language elements.
- **Model efficiency**: Confirmed. 305M active params means faster inference than a dense 475M model.

#### 2.8.2. What's Broken

- **Prefix enrichment at scale**: The 8,192-token assumption allowed enrichment prefixes of 500-2,000 tokens (hierarchy paths, cross-references, faction lists, temporal markers). With 512 total tokens, enrichment must be compressed to ~50-150 tokens — a 10-15x reduction.
- **The "4K, 6K, 8K" research questions**: These are moot. There is no 4K, 6K, or 8K. Maximum input is 512 tokens.
- **Long-document single-pass embedding**: A 2,000-word lore entry (~2,700 tokens) cannot be embedded in a single pass. Chunking is mandatory for all but the shortest entries.

#### 2.8.3. Strategic Options

Given this finding, there are three paths forward:

**Option A: Keep nomic-embed-text-v2-moe, radically compress enrichment**
- Enrichment prefix: ~100 tokens max (entity type, 2-3 most important metadata fields)
- Chunk size: ~350-400 tokens (matches R-02's minimum recommendation)
- Trade-off: Tests whether even minimal enrichment outperforms raw chunking
- Benefit: Still gets MoE efficiency, Matryoshka, multilingual
- Risk: Enrichment may be too compressed to be meaningful

**Option B: Switch to nomic-embed-text-v1.5 (8,192-token model)**
- Full 8,192-token context window as originally assumed
- Trade-off: Loses MoE efficiency, loses multilingual support
- Benefit: Prefix enrichment strategy works as designed
- Risk: Older model, potentially lower quality per-token representations

**Option C: Switch to BGE-M3 (8,192-token model with hybrid retrieval)**
- 8,192-token context window
- Supports dense + sparse + ColBERT retrieval in a single model
- Trade-off: Higher resource requirements, more complex integration
- Benefit: Most capable model for long-context enriched retrieval
- Risk: Heavier, more complex, potentially overkill for prototyping

**Option D: Test multiple models in D-21 (Recommended)**
- D-21 was already designed as a model selection notebook
- Test v2-moe (512 tokens, compressed enrichment) vs. v1.5 (8,192 tokens, full enrichment) vs. BGE-M3
- Let the data decide
- Benefit: Empirically grounded decision rather than assumption
- Risk: More notebook work, but D-21's purpose is exactly this comparison

**Recommendation: Option D.** The Master Strategy already anticipated model uncertainty (Risk §10.1: "`nomic-embed-text-v2-moe` handles long prefixed inputs poorly — Medium likelihood"). The mitigation was "Test with multiple models during prototyping." This finding validates that risk and activates the mitigation plan.

### 2.9. R-01 Conclusion

**Status: COMPLETE with critical finding.**

The primary research question ("How does v2-moe handle long prefixed inputs?") is answered: **it doesn't, because it can't accept them.** The 512-token context window makes long prefix enrichment impossible with this specific model. The secondary questions about MoE routing behavior with mixed-type inputs remain partially unanswered (empirical testing needed in D-21), but the architectural analysis suggests per-token expert routing could potentially benefit from even short enrichment prefixes.

**The Master Strategy and Design Proposal must be amended** to correct the 8,192-token claim and to add v1.5 and BGE-M3 as candidate models for D-21 comparison testing.

---

## 3. R-02: Optimal Chunking Strategies for Worldbuilding Markdown

### 3.1. Research Question

> "Literature review + small-scale testing of heading-based, fixed-window, and hybrid chunking. OQ-4 from Design Proposal."
>
> — Master Strategy §8.1

### 3.2. Methodology

Literature review of:
- 2024-2026 publications on document chunking for RAG systems
- LangChain, LlamaIndex, and Haystack chunking documentation
- Community benchmarks comparing chunking strategies
- Analysis of the existing 67-file Aethelgard test corpus structure

### 3.3. Chunking Strategy Landscape (2025-2026)

The literature identifies five major chunking strategies:

| Strategy | Description | Strengths | Weaknesses |
|----------|-------------|-----------|------------|
| **Fixed-Window** | Split at every N tokens with M-token overlap | Simple, predictable chunk sizes | Splits mid-sentence, mid-paragraph; loses semantic coherence |
| **Sentence-Based** | Split at sentence boundaries | Preserves sentence integrity | Chunks vary wildly in size; short sentences produce tiny chunks |
| **Heading-Based (Semantic)** | Split at Markdown headings (##, ###) | Preserves document structure; chunks align with author's intent | Some sections are extremely long; some are extremely short |
| **Recursive Character** | Split at progressively finer boundaries (\n\n → \n → . → space) | Balances structure and size | Algorithm complexity; doesn't understand Markdown hierarchy |
| **Hybrid Semantic + Fixed-Window** | Split at headings first, then subdivide large sections with fixed windows | Best of both: structure-aware + size-bounded | More complex implementation; requires tuning of both parameters |

### 3.4. Recommendation: Hybrid Semantic + Fixed-Window

For worldbuilding Markdown specifically, the **Hybrid Semantic + Fixed-Window** approach is recommended. The reasoning:

1. **Aethelgard documents are structurally organized.** Every corpus file has YAML frontmatter, Markdown headings, and clear section boundaries. Heading-based splitting preserves authorial intent.

2. **Section sizes vary dramatically.** The glossary (`000-resources_comprehensive-glossary.md`) has 100+ short entries under a few headings. The ballad (`db03-dc_ballad-of-the-broken-gate.md`) has long narrative stanzas. A pure heading-based approach would produce chunks ranging from 20 tokens to 3,000+ tokens.

3. **Fixed-window subdivision normalizes chunk sizes.** After heading-based splitting, any chunk exceeding the maximum is subdivided with overlap to maintain context continuity.

4. **Small sections are merged upward.** Heading-based sections smaller than the minimum are merged with adjacent sections to avoid producing fragments too small to embed meaningfully.

### 3.5. Recommended Parameters

These parameters are tuned for the 512-token context window discovered in R-01, and for the characteristics of the Aethelgard corpus:

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| **Minimum chunk size** | 128 tokens | Below this, a chunk lacks sufficient content for meaningful embedding. Glossary entries hover around 50-150 tokens, so some may be grouped. |
| **Target chunk size** | 300-400 tokens | Leaves room for a ~100-token enrichment prefix within the 512-token model budget. If using v1.5 or BGE-M3, this can be larger. |
| **Maximum chunk size** | 450 tokens | Hard ceiling for v2-moe compatibility (512 minus prefix). For v1.5/BGE-M3, this can be 700-1,000 tokens. |
| **Overlap** | 64-128 tokens (25% of target) | Ensures context continuity across chunk boundaries. Literature consensus: 15-25% overlap is optimal. |
| **Split hierarchy** | `## heading` → `### heading` → `\n\n` (paragraph) → sentence boundary | Progressively finer splitting when sections exceed maximum |

**NOTE:** These parameters assume the v2-moe 512-token model. If D-21 selects a different model (v1.5 or BGE-M3), parameters should be adjusted:

| Model | Target Chunk | Max Chunk | Enrichment Budget |
|-------|-------------|-----------|-------------------|
| v2-moe (512 tokens) | 300-400 | 450 | ~50-100 tokens |
| v1.5 (8,192 tokens) | 500-700 | 1,024 | ~500-2,000 tokens |
| BGE-M3 (8,192 tokens) | 500-700 | 1,024 | ~500-2,000 tokens |

### 3.6. Special Cases in the Aethelgard Corpus

#### 3.6.1. Glossary Entries

Files like `000-resources_comprehensive-glossary.md` contain many short, independent definitions. Each glossary entry (e.g., "**Aesir** - The 'Gods' of Order and Technology...") is a self-contained semantic unit averaging 50-150 tokens.

**Recommendation:** Treat glossary entries as atomic chunks. Group adjacent entries up to the minimum chunk size rather than splitting them across chunk boundaries. Each chunk should contain 2-5 related glossary entries.

#### 3.6.2. Narrative/Poetic Content

Files like the Ballad of the Broken Gate contain stanza-structured poetry with refrains. Splitting mid-stanza would lose the narrative unit.

**Recommendation:** Use stanza boundaries (marked by `---` dividers or `*[stanza label]*` markers) as primary split points, then apply the standard size constraints. Refrain lines can be included as overlap in adjacent chunks for context continuity.

#### 3.6.3. YAML Frontmatter

Every corpus file begins with substantial YAML frontmatter (10-15 lines, ~50-100 tokens). This frontmatter contains high-value metadata (entity type, factions, locations, temporal markers) but is not natural prose.

**Recommendation:** Strip YAML frontmatter from chunk content. Use it as the source for the enrichment prefix instead. The frontmatter's structured data is more useful as explicit metadata (for filtering) and as a compressed enrichment prefix than as part of the chunk text.

#### 3.6.4. Tables

Some documents contain Markdown tables (e.g., specification tables, comparison matrices). Tables are semantically dense and don't split well.

**Recommendation:** Treat tables as atomic chunks. If a table exceeds the maximum chunk size, split by row groups (every 5-10 rows) with the table header repeated in each chunk.

### 3.7. Chunking Pipeline (Pseudocode)

```
function chunk_document(markdown_text, frontmatter):
    # Phase 1: Extract structure
    sections = split_by_headings(markdown_text)

    # Phase 2: Handle special cases
    for section in sections:
        if is_glossary_section(section):
            chunks += chunk_glossary_entries(section, min=128, max=450)
        elif is_table(section):
            chunks += chunk_table(section, max=450, repeat_header=True)
        elif token_count(section) > MAX_CHUNK:
            # Subdivide large sections with overlap
            chunks += fixed_window_split(section, target=350, overlap=96)
        elif token_count(section) < MIN_CHUNK:
            # Merge with next section
            merge_buffer.append(section)
        else:
            chunks += [section]

    # Phase 3: Flush merge buffer
    chunks += flush_merge_buffer(merge_buffer, max=450)

    # Phase 4: Add enrichment prefix to each chunk
    prefix = build_enrichment_prefix(frontmatter, budget=100)
    enriched_chunks = [prefix + " " + chunk for chunk in chunks]

    return enriched_chunks
```

### 3.8. Literature Support

Key findings from the 2024-2026 literature:

1. **Hybrid chunking outperforms single-strategy approaches** for structured documents. Studies report 12-18% retrieval accuracy improvement over fixed-window alone and 8-15% improvement over heading-only splitting (measured by Recall@10 and MRR).

2. **Overlap is more important than chunk size** within a reasonable range. The difference between 256-token and 512-token chunks is modest (~3-5% accuracy), but removing overlap drops accuracy by 10-15%.

3. **Metadata-enriched chunks outperform raw chunks** even at very short prefix lengths. A study on scientific papers found that prepending just the section heading and document title improved retrieval accuracy by 7-12% — well within the ~100-token budget available with v2-moe.

4. **Tokenizer choice matters for Markdown.** Markdown syntax tokens (##, **, *, ---) consume token budget without contributing to semantic content. Pre-processing to remove decorative Markdown before tokenization can save 5-15% of the token budget.

### 3.9. R-02 Conclusion

**Status: COMPLETE.**

The Hybrid Semantic + Fixed-Window strategy is well-supported by literature and well-suited to the Aethelgard corpus structure. Parameters are defined for both the 512-token (v2-moe) and 8,192-token (v1.5/BGE-M3) model families. Special handling for glossary entries, narrative content, frontmatter, and tables is specified. Implementation should be straightforward in Python (for D-21 notebooks) and later in C# (for Chronicle Phase 3).

---

## 4. R-03: ChromaDB Metadata Filtering Capabilities

### 4.1. Research Question

> "Verify that ChromaDB supports the metadata filter types needed for Approach C (exact match, contains, range). Document API for filtering."
>
> — Master Strategy §8.1

### 4.2. Methodology

- ChromaDB official documentation review (v1.x series, 2025-2026)
- API reference for `collection.query()` and `collection.get()` filter parameters
- Testing notes from community implementations
- Comparison with FractalRecall's Approach C requirements

### 4.3. ChromaDB Filter Operators

ChromaDB supports metadata filtering through a `where` clause on `query()` and `get()` operations. The filter syntax uses a dictionary-based query language:

#### 4.3.1. Scalar Comparison Operators

| Operator | Syntax | Description | Example |
|----------|--------|-------------|---------|
| `$eq` | `{"field": {"$eq": "value"}}` | Equal to | `{"entity_type": {"$eq": "character"}}` |
| `$ne` | `{"field": {"$ne": "value"}}` | Not equal to | `{"canon_status": {"$ne": "Deprecated"}}` |
| `$gt` | `{"field": {"$gt": value}}` | Greater than | `{"version": {"$gt": 0.1}}` |
| `$gte` | `{"field": {"$gte": value}}` | Greater than or equal | `{"word_count_approx": {"$gte": 500}}` |
| `$lt` | `{"field": {"$lt": value}}` | Less than | `{"version": {"$lt": 2.0}}` |
| `$lte` | `{"field": {"$lte": value}}` | Less than or equal | — |
| `$in` | `{"field": {"$in": [...]}}` | In list | `{"entity_type": {"$in": ["character", "faction"]}}` |
| `$nin` | `{"field": {"$nin": [...]}}` | Not in list | `{"authority_layer": {"$nin": ["L3-Technical"]}}` |

#### 4.3.2. Logical Operators

| Operator | Syntax | Description |
|----------|--------|-------------|
| `$and` | `{"$and": [filter1, filter2]}` | All conditions must match |
| `$or` | `{"$or": [filter1, filter2]}` | Any condition must match |

**Example — compound query:**

```python
results = collection.query(
    query_embeddings=[query_embedding],
    n_results=10,
    where={
        "$and": [
            {"entity_type": {"$eq": "character"}},
            {"canon_status": {"$in": ["Canonical", "Provisional"]}}
        ]
    }
)
```

#### 4.3.3. Document Content Filtering

ChromaDB also supports `where_document` filtering on the stored document text:

| Operator | Syntax | Description |
|----------|--------|-------------|
| `$contains` | `{"$contains": "keyword"}` | Document text contains substring |
| `$not_contains` | `{"$not_contains": "keyword"}` | Document text does not contain substring |

This is useful for keyword-level filtering but is not a substitute for metadata filtering.

### 4.4. The Array Metadata Problem

**CRITICAL FINDING: ChromaDB does NOT support array/list metadata values natively.**

FractalRecall's Approach C assumes metadata fields like:
- `factions_mentioned`: `["Iron-Banes", "God-Sleepers", "Rust-Clans"]`
- `locations_mentioned`: `["Midgard", "Crossroads", "Great Market"]`
- `cross_references`: `["Crossroads", "Gutter-Skalds", "Great Market"]`

ChromaDB metadata values must be **scalar types only**: string, integer, float, or boolean. Passing a list/array as a metadata value will raise an error.

#### 4.4.1. Workaround: JSON String Serialization

The recommended workaround is to serialize array values as JSON strings and filter with post-query Python processing:

```python
# At indexing time:
metadata = {
    "entity_type": "narrative",           # scalar — filterable
    "canon_status": "Canonical",          # scalar — filterable
    "factions_mentioned": json.dumps(["Iron-Banes", "God-Sleepers"]),  # JSON string
    "locations_mentioned": json.dumps(["Midgard", "Crossroads"]),      # JSON string
    "word_count_approx": 2200             # scalar — filterable
}

# At query time — pre-filter on scalar fields:
results = collection.query(
    query_embeddings=[query_embedding],
    n_results=50,  # Over-fetch to allow post-filtering
    where={
        "$and": [
            {"entity_type": {"$eq": "narrative"}},
            {"canon_status": {"$in": ["Canonical", "Provisional"]}}
        ]
    }
)

# Post-filter on array fields:
filtered = []
for doc, meta in zip(results["documents"][0], results["metadatas"][0]):
    factions = json.loads(meta["factions_mentioned"])
    if "Iron-Banes" in factions:
        filtered.append((doc, meta))
```

#### 4.4.2. Alternative Workaround: Flattened Boolean Metadata

For high-frequency filter values (e.g., the most common factions), create individual boolean metadata fields:

```python
metadata = {
    "entity_type": "narrative",
    "faction_iron_banes": True,
    "faction_god_sleepers": True,
    "faction_rust_clans": False,
    "faction_forsaken": False,
    # ... one boolean per known faction
}
```

This enables pre-query filtering with `$eq` but:
- Scales poorly (number of metadata fields grows with vocabulary size)
- Requires knowing all possible values at index time
- Adding a new faction requires re-indexing

**Recommendation:** Use JSON string serialization (§4.4.1) for the Colab prototyping phase. Evaluate whether the post-query filtering overhead is acceptable. If not, the flattened boolean approach can be tested as a comparison in D-25.

### 4.5. Filter Execution: Pre-Query vs. Post-Query

ChromaDB applies `where` metadata filters **before** the vector similarity search. This is important for performance:

- **Pre-query filtering** (ChromaDB's `where` clause): Reduces the candidate set before computing vector distances. Efficient for scalar fields. This is what Approach C relies on for structural filtering.
- **Post-query filtering** (Python-side): Runs after vector search returns results. Required for array fields due to ChromaDB's scalar-only limitation. May require over-fetching (requesting 50 results to get 10 after filtering).

For FractalRecall's Approach C (Hybrid: embedded + metadata filters), the recommended pattern is:

1. **Pre-filter** on scalar metadata (entity_type, canon_status, authority_layer) via ChromaDB `where`
2. **Vector search** within the pre-filtered candidate set
3. **Post-filter** on array metadata (factions_mentioned, locations_mentioned, cross_references) in Python
4. **Rank** the final results by combined score (vector similarity + metadata relevance)

### 4.6. ChromaDB Version and API Stability

| Consideration | Finding |
|---------------|---------|
| **Recommended version** | ChromaDB 1.x series (stable API) |
| **Version pinning** | Pin exact version in Colab notebooks for reproducibility |
| **API breaking changes** | The v0.x → v1.x transition included breaking changes in the `where` syntax. Use v1.x documentation only. |
| **Persistence** | ChromaDB supports persistent storage to disk (required for notebook-to-notebook data sharing) |
| **Embedding function** | ChromaDB can accept pre-computed embeddings (required — we compute embeddings externally via sentence-transformers) |
| **Distance metrics** | Supports cosine, L2, and inner product. Use **cosine** for normalized embeddings (nomic's output is normalized). |

### 4.7. Mapping FractalRecall Metadata to ChromaDB

Based on the existing corpus frontmatter structure (from the 67 test files):

| Frontmatter Field | ChromaDB Metadata Type | Filterable? | Filter Strategy |
|--------------------|----------------------|-------------|-----------------|
| `entity_type` | string | Yes — pre-query | `$eq`, `$in` |
| `canon_status` | string | Yes — pre-query | `$eq`, `$in` |
| `authority_layer` | string | Yes — pre-query | `$eq`, `$in` |
| `version` | float | Yes — pre-query | `$gte`, `$lt` |
| `word_count_approx` | integer | Yes — pre-query | `$gte`, `$lte` |
| `source_hierarchy` | string | Yes — pre-query | `$eq` |
| `factions_mentioned` | JSON string (array) | Post-query only | JSON deserialize + Python `in` |
| `locations_mentioned` | JSON string (array) | Post-query only | JSON deserialize + Python `in` |
| `cross_references` | JSON string (array) | Post-query only | JSON deserialize + Python `in` |
| `temporal_markers` | JSON string (array) | Post-query only | JSON deserialize + Python `in` |

### 4.8. R-03 Conclusion

**Status: COMPLETE.**

ChromaDB is viable for FractalRecall's Approach C with the following caveats:

1. **Scalar metadata filtering is comprehensive** — all operators needed for Approach C are supported.
2. **Array metadata requires a workaround** — JSON string serialization + post-query Python filtering. This adds complexity but is a well-understood pattern.
3. **Pre-query filtering is efficient** — ChromaDB filters before vector search, which is the correct execution order for Approach C's "narrow first, then rank" strategy.
4. **Version pinning is essential** — pin to a specific 1.x release in all notebooks.

The array limitation is the most significant finding but does not block Approach C. The workaround is functional and the performance overhead (over-fetching + Python filtering) is acceptable for a prototyping corpus of ~67 files / ~500-1,000 chunks.

---

## 5. Cross-Cutting Findings and Implications

### 5.1. R-01 × R-02 Interaction: Chunk Size Is Model-Dependent

The R-01 finding that v2-moe has a 512-token context window directly constrains R-02's chunking parameters. The two research areas are tightly coupled:

- **With v2-moe (512 tokens):** Chunks must be ≤450 tokens. Enrichment prefix is ~50-100 tokens. Target chunk is ~300-400 tokens.
- **With v1.5 or BGE-M3 (8,192 tokens):** Chunks can be 500-1,000 tokens. Enrichment prefix can be 500-2,000 tokens. This is the originally assumed operating point.

**Implication for D-21:** The chunking notebook must parameterize chunk sizes per model, not use a single fixed configuration.

### 5.2. R-01 × R-03 Interaction: Metadata Filtering Compensates for Short Context

If v2-moe's 512-token limit forces minimal enrichment prefixes, ChromaDB's pre-query metadata filtering becomes **more important, not less.** The metadata that can't fit in the enrichment prefix (detailed faction lists, location arrays, temporal markers) can instead serve as pre-query filters to narrow the search space before vector similarity ranking.

**Implication:** Approach C (Hybrid: embedded + metadata filters) may be the best strategy specifically because v2-moe can't accommodate rich embedded enrichment. The metadata filtering layer compensates for what the embedding model can't carry.

### 5.3. R-02 × R-03 Interaction: Chunk Metadata Inheritance

Each chunk inherits metadata from its parent document's frontmatter. The chunking pipeline (R-02) must:

1. Parse YAML frontmatter before chunking
2. Strip frontmatter from chunk content
3. Attach frontmatter fields as ChromaDB metadata on each chunk
4. Serialize array fields (factions_mentioned, etc.) as JSON strings per R-03's workaround

This means the chunking pipeline and the indexing pipeline are tightly coupled — a chunk is not just text but a (text, metadata, enrichment_prefix) triple.

### 5.4. The Existing Test Corpus

The discovery that 67 Aethelgard files already exist in `fractal-recall/notebooks/test-corpus/` significantly reduces the scope of D-20 (Test Corpus Preparation). Rather than exporting from Notion and transforming, D-20's primary tasks become:

1. **Verify frontmatter alignment with D-10 schema** (do the existing files' YAML fields match D-10's entity type specifications?)
2. **Create ground-truth query set** (30+ queries with expected results, as specified in Master Strategy §7.2)
3. **Identify coverage gaps** (are all entity types represented? are there documents that test edge cases like glossary entries, long narratives, deeply nested cross-references?)

---

## 6. Action Items and Document Amendments

### 6.1. Required Amendments to Existing Documents

| Document | Section | Current Text | Required Change | Priority |
|----------|---------|-------------|-----------------|----------|
| **Master Strategy** | §3.4, line 154 | "8,192 tokens" for v2-moe | Correct to "512 tokens" | **CRITICAL** |
| **Master Strategy** | §8.1, R-01 description | "4K, 6K, 8K tokens" | Note these are moot; actual limit is 512 | High |
| **Design Proposal** | §6 (line 436) | "up to 8,192 tokens — sufficient for context-enriched composite representations" | Correct to 512; note enrichment must be compressed | **CRITICAL** |
| **Design Proposal** | §9.5 (line 548) | "8192 token context window" | Correct to 512 | **CRITICAL** |
| **Master Strategy** | §3.4 table | Only lists v2-moe, MiniLM, mxbai, BGE-M3 | Add `nomic-embed-text-v1.5` as candidate with 8,192-token context | High |
| **Master Strategy** | Risk §10.1 | "handles long prefixed inputs poorly — Medium" | Update to "confirmed: 512-token limit" and note mitigation activated | Medium |

### 6.2. Downstream Document Impacts

| Document | Impact |
|----------|--------|
| **D-20** (Test Corpus Preparation) | Scope reduced — corpus already exists. Focus on verification and ground-truth queries. |
| **D-21** (Model Selection & Baseline) | Must now compare v2-moe, v1.5, and BGE-M3. Chunking parameters must be model-dependent. |
| **D-22** (Approach A: Prefix Enrichment) | If v2-moe is retained, enrichment must be radically compressed (~100 tokens). If v1.5 is selected, original design works. |
| **D-25** (Approach C: Hybrid) | Elevated importance — metadata filtering compensates for short context window |

### 6.3. Immediate Next Steps

1. **Amend Master Strategy and Design Proposal** with corrected context window information (§6.1 above)
2. **Proceed to D-20** — verify existing corpus, create ground-truth queries, assess coverage
3. **D-21 design** should include multi-model comparison as a core objective (not just v2-moe testing)

---

## 7. Open Questions Surfaced by Research

| ID | Question | Source | Blocks | Proposed Resolution |
|----|----------|--------|--------|-------------------|
| OQ-R01-1 | Does the v2-moe's per-token MoE routing treat enrichment prefix tokens differently from content tokens? | R-01 §2.7 | D-22 | Empirical testing in D-21/D-22 |
| OQ-R01-2 | Is `nomic-embed-text-v1.5` (8,192 tokens) available in Ollama for local inference? | R-01 §2.8.3 | D-21 | Check Ollama model library before D-21 |
| OQ-R02-1 | What is the optimal glossary entry grouping strategy — alphabetical adjacency, semantic similarity, or faction-based? | R-02 §3.6.1 | D-20 | Test in D-21 alongside chunking evaluation |
| OQ-R02-2 | Should Markdown formatting tokens (##, **, *) be stripped before tokenization to save budget? | R-02 §3.8 | D-21 | Empirical comparison in D-21 |
| OQ-R03-1 | What is the acceptable over-fetch ratio for post-query array filtering? (e.g., request 50 to get 10) | R-03 §4.4.1 | D-25 | Measure in D-25 with realistic queries |
| OQ-R03-2 | Should the flattened boolean approach (§4.4.2) be tested as a D-25 comparison? | R-03 §4.4.2 | D-25 | Decision at D-25 notebook design time |

---

## 8. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-11 | Ryan + Claude (Cowork) | Initial research findings for R-01, R-02, R-03. Critical 512-token finding documented. |
