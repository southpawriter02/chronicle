---
title: "Colab Execution & Results Handoff Guide"
document_id: "D-EX"
version: "1.0"
date: "2026-02-11"
author: "Ryan + Claude (Cowork)"
purpose: "Step-by-step instructions for running D-21, D-22, D-23 notebooks in Google Colab and reporting results back to Claude for analysis"
---

# Colab Execution & Results Handoff Guide

This document tells you exactly how to run each notebook in Google Colab, what to look for while it runs, and what to copy/paste back into our conversation so I can help you interpret results and make the GO/NO-GO decision.

---

## Before You Start: Environment Setup

### One-Time Colab Setup

1. **Open Google Colab**: Go to [colab.research.google.com](https://colab.research.google.com)
2. **Enable GPU**: Go to `Runtime → Change runtime type → T4 GPU` (free tier is fine)
3. **Upload the corpus**: The test corpus files need to be accessible. Two options:
   - **Option A (Google Drive)**: Upload the `test-corpus/` folder to your Google Drive, then mount Drive in the first code cell:
     ```python
     from google.colab import drive
     drive.mount('/content/drive')
     # Then update CORPUS_DIR to point to your Drive location
     ```
   - **Option B (Direct upload)**: Use Colab's file browser (folder icon on left sidebar) to upload the corpus files directly to `/content/test-corpus/`

4. **Upload the notebook**: `File → Upload notebook` and select the `.ipynb` file

### Important: Colab File Persistence

Colab's filesystem is **ephemeral** — files disappear when your runtime disconnects. This matters because D-22 needs D-21's output files, and D-23 needs both. You have two strategies:

- **Strategy A (Recommended): Run all three notebooks in one session.** Keep Colab connected and don't let it time out. D-21 output files persist in `/content/` as long as the runtime is alive. D-22 reads them, then D-23 reads both.

- **Strategy B: Save outputs to Google Drive between notebooks.** After each notebook, copy the output directory to Drive. Before starting the next notebook, copy the files back. This is safer if you need to take breaks.

### Path Adjustments

The notebook code uses paths like `/mnt/0000_concurrent/d21_output/`. In Colab, you'll need to adjust these to `/content/d21-output/` (or wherever your files actually are). The key constants to check are in **Cell 03** of each notebook:

```
CORPUS_DIR  — where the test corpus YAML/MD files live
OUTPUT_DIR  — where this notebook saves its results
D21_RESULTS_PATH  — (D-22, D-23 only) where to find D-21's results CSV
D22_RESULTS_PATH  — (D-23 only) where to find D-22's results CSV
CHROMADB_DIR  — where ChromaDB persists its index
```

Adjust these once in Cell 03 and everything else should work.

---

## Notebook 1: D-21 (Baseline)

**File**: `D21-baseline.ipynb`
**Purpose**: Establish baseline retrieval with no enrichment. Test 3 models. Select the winner.
**Estimated Runtime**: 10–15 minutes on T4 GPU
**Depends On**: Test corpus files only

### Execution Steps

1. Upload `D21-baseline.ipynb` to Colab
2. Upload the test corpus (or mount Google Drive)
3. **Run Cell 01** (Markdown header) — just displays info, nothing to do
4. **Run Cell 02** (pip install) — installs dependencies. Wait for completion. If any install fails, see Troubleshooting below.
5. **Run Cell 03** (Imports & Config) — **CHECK**: Update `CORPUS_DIR` to point to your actual corpus location in Colab. The cell should print a confirmation of all three model configurations.
6. **Run Cells 04–06** sequentially (queries, field mapping, corpus loading). Cell 06 will print how many documents were loaded and any filename mismatches with the ground-truth queries. **If you see filename mismatch warnings**, note them — they mean some queries won't match any chunks and those query results will be zero.
7. **Run Cell 07** (Methodology markdown) — displays info only
8. **Run Cell 08** (Chunking) — should print chunk counts per model. Expect ~200–250 chunks per model for v1.5/bge-m3, and ~400–600 for v2-moe (smaller chunks due to 512-token limit).
9. **Run Cells 09–12** (Embedding, indexing, querying) — this is the heavy computation. Embedding takes 1–5 minutes per model. If you hit an OOM error on bge-m3, see Troubleshooting.
10. **Run Cell 13** (Results markdown) — displays info only
11. **Run Cells 14–19** (Metrics, visualization, model selection) — these compute metrics and generate charts. The model selection cell prints the **weighted decision matrix** and recommends a model.
12. **Run Cells 20–21** (Export, C# implications) — Cell 20 exports all CSVs and persists ChromaDB
13. **Run Cell 22** (Next steps markdown) — displays info only

### What to Report Back After D-21

Copy and paste the following into our conversation:

**1. Model Summary Table** — printed by Cell 20 (the export cell). Looks like:

```
Model Summary (mean across all 36 queries):
           precision@5  recall@10  ndcg@10    mrr
v2-moe       0.XXXX      0.XXXX    0.XXXX   0.XXXX
v1.5         0.XXXX      0.XXXX    0.XXXX   0.XXXX
bge-m3       0.XXXX      0.XXXX    0.XXXX   0.XXXX
```

**2. Weighted Decision Matrix** — printed by the model selection cell. Shows weighted scores and the recommended model.

**3. The winning model name** — whichever model the decision matrix recommends (e.g., "v1.5"). This becomes `SELECTED_MODEL` for D-22 and D-23.

**4. Any errors or warnings** you encountered, especially:
- Filename mismatch warnings from Cell 06
- OOM errors during embedding
- Zero-score queries (queries where no relevant results were found)

**5. Chunk counts** — from Cell 08 output. How many chunks were created per model?

**Optional but helpful:**
- Screenshot of the `d21_query_type_breakdown.png` bar chart (if you can paste images)
- Screenshot of the `d21_model_heatmap.png`

### What I'll Do With This Data

I'll review the model selection, validate it makes sense given the enrichment headroom requirements, and confirm SELECTED_MODEL before you proceed to D-22. If there are any anomalies (e.g., all models scoring nearly identically, or v2-moe surprisingly winning despite the 512-token limit), I'll flag them.

---

## Notebook 2: D-22 (Single-Layer Enrichment)

**File**: `D22-single-layer.ipynb`
**Purpose**: Test whether adding a simple metadata prefix improves retrieval
**Estimated Runtime**: 5–10 minutes on T4 GPU
**Depends On**: D-21's output files must be accessible

### Pre-Flight Checks

Before running D-22, verify:

- [ ] D-21's `d21_results.csv` is accessible at the path D-22 expects (check Cell 03)
- [ ] D-21's ChromaDB directory is accessible (if D-22 reuses it)
- [ ] You know which model won D-21 (you'll set `SELECTED_MODEL` in Cell 03)

### Execution Steps

1. Upload `D22-single-layer.ipynb` to Colab (or open it in the same runtime as D-21)
2. **Run Cells 01–02** (header, pip install) — dependencies should already be installed if same runtime
3. **Run Cell 03** — **CRITICAL**: Set `SELECTED_MODEL` to the winning model from D-21 (e.g., `"v1.5"`). Also verify `D21_RESULTS_PATH` points to where D-21 actually saved its CSV.
4. **Run Cells 04–08** (queries, field mapping, corpus loading, methodology, chunking) — same infrastructure as D-21
5. **Run Cell 09** (Single-layer enrichment builder) — this is the new code. It constructs a prefix like: `"This is a faction document about The Iron Covenant. Canon status: true."` and prepends it to each chunk. Should print sample enriched chunks.
6. **Run Cells 10–12** (Enrich corpus, embed, query) — similar to D-21 but with enriched text
7. **Run Cell 13** (Results markdown) — displays info only
8. **Run Cells 14–15** (Metrics, load D-21 results for comparison) — Cell 15 loads D-21's CSV and builds the comparison DataFrame. **If D-21 results aren't found**, you'll see a warning.
9. **Run Cells 16–17** (Delta analysis, Wilcoxon test) — the core comparison. Delta analysis shows per-metric improvement, and the Wilcoxon test shows statistical significance.
10. **Run Cells 18–19** (Visualizations) — bar chart and heatmaps
11. **Run Cells 20–22** (Export, C# implications, next steps)

### What to Report Back After D-22

Copy and paste:

**1. Delta Analysis Summary** — printed by Cell 16. Shows per-metric improvement:

```
OVERALL STATISTICS (All 36 Queries)
Precision@5:
  Mean delta: +0.XXXX
  Improved: XX queries (XX.X%)
  Degraded: XX queries (XX.X%)

Recall@10:
  Mean delta: +0.XXXX
  ...
```

**2. Wilcoxon Test Results** — printed by Cell 17:

```
Precision@5:
  Statistic: XX.XX
  P-value: 0.XXXX
  Significant (p < 0.05): YES/NO
  Effect size: XX.X%
```

**3. By-Query-Type Breakdown** — also from Cell 16. Shows which query types (authority, temporal, factual) benefited most.

**4. Any warnings or issues**, especially:
- "D-21 results file not found" (means comparison couldn't happen)
- Token overflow warnings from enrichment
- Queries where enrichment made things worse

**Optional but helpful:**
- Screenshot of the improvement distribution bar chart

### What I'll Do With This Data

I'll assess whether single-layer enrichment is working (positive deltas, especially for authority queries) and whether to expect multi-layer to do even better. If single-layer shows no improvement or degradation, that's an early signal that D-23's GO/NO-GO may lean toward NO-GO, and we'll discuss implications before proceeding.

---

## Notebook 3: D-23 (Multi-Layer Enrichment — GO/NO-GO)

**File**: `D23-multi-layer.ipynb`
**Purpose**: Test full 8-layer enrichment. Make the GO/NO-GO decision.
**Estimated Runtime**: 10–15 minutes on T4 GPU
**Depends On**: Both D-21 and D-22 output files

### Pre-Flight Checks

Before running D-23, verify:

- [ ] D-21's `d21_results.csv` is accessible
- [ ] D-22's `d22_results.csv` is accessible
- [ ] `SELECTED_MODEL` matches D-21's winner and D-22's setting
- [ ] Test corpus is still accessible

### Execution Steps

1. Upload `D23-multi-layer.ipynb` (or open in same runtime)
2. **Run Cells 01–02** (header, pip install)
3. **Run Cell 03** — **CRITICAL**: Verify `SELECTED_MODEL`, `D21_RESULTS_PATH`, and `D22_RESULTS_PATH` all match your actual file locations.
4. **Run Cells 04–08** (queries, field mapping, corpus, methodology, chunking) — same infrastructure
5. **Run Cell 09** (Multi-layer enrichment builder — THE CORE NEW CODE) — this builds all 8 layers. Should print sample enriched chunks showing the full prefix. **Look for**: Does it show all layers? Are any layers consistently `None`? This tells us about metadata completeness.
6. **Run Cell 10** (Chunk, enrich, audit) — enriches all chunks and produces the layer token audit. Should print:
   - How many chunks were processed
   - How many exceeded the token limit (overflow count)
   - Layer presence rates (what percentage of chunks have each layer)
   - Token overhead statistics per layer
7. **Run Cell 11–12** (Embed, query) — indexes and queries
8. **Run Cell 13** (Results markdown)
9. **Run Cell 14** (Metric functions)
10. **Run Cell 15** (Compute D-23 metrics, load D-21 + D-22, build comparison) — should print the mean metric values for all three experiments side by side, plus trend arrows.
11. **Run Cell 16** (3-way delta analysis) — **CRITICAL OUTPUT**. Shows deltas for all 3 pairs.
12. **Run Cell 17** (Statistical significance) — **CRITICAL OUTPUT**. Wilcoxon tests with Bonferroni correction.
13. **Run Cells 18–19** (Visualizations)
14. **Run Cell 20** (GO/NO-GO Decision Engine) — **THE DECISION CELL**. Evaluates all 7 criteria and prints the formal decision.
15. **Run Cells 21–22** (Export, summary)

### What to Report Back After D-23

This is the most important handoff. Copy and paste ALL of the following:

**1. Cell 10 Output — Layer Audit Summary**:

```
Layer presence rates:
  corpus:     XXX/XXX (100%)
  domain:     XXX/XXX (XX%)
  entity:     XXX/XXX (XX%)
  ...

Token overflow: X/XXX chunks (X.X%)
```

**2. Cell 15 Output — Mean Metrics Comparison Table**:

```
MEAN METRIC VALUES BY EXPERIMENT
              precision@5  recall@10  ndcg@10    mrr
baseline         0.XXXX     0.XXXX    0.XXXX   0.XXXX
single_layer     0.XXXX     0.XXXX    0.XXXX   0.XXXX
multi_layer      0.XXXX     0.XXXX    0.XXXX   0.XXXX
```

**3. Cell 15 Output — Trend Arrows**:

```
D-23 (Multi-Layer) vs D-22 (Single-Layer):
  Precision@5     ↑/↓/→ 0.XXXX vs 0.XXXX (delta +X.XXXX, +X.X%)
  ...

D-23 (Multi-Layer) vs D-21 (Baseline):
  ...
```

**4. Cell 16 Output — Delta Analysis (all 3 pairs)**:

For each pair (D-23 vs D-21, D-23 vs D-22, D-22 vs D-21), copy the overall statistics and the by-query-type breakdown. The key numbers are:
- Mean delta per metric
- % queries improved vs degraded
- Which query types benefited most

**5. Cell 16 Output — Marginal Value Analysis**:

```
MARGINAL VALUE ANALYSIS: Value Added by Layers 2-8
  Precision@5     ↑/↓ marginal=+X.XXXX (ML improvement=+X.XXXX, SL improvement=+X.XXXX)
  ...
```

**6. Cell 17 Output — Significance Results**:

```
D-23 MULTI-LAYER vs D-21 BASELINE:
  Precision@5     W=XX.X, p=0.XXXXXX, r=+X.XXX (small/medium/large) ***
  Recall@10       W=XX.X, p=0.XXXXXX, r=+X.XXX (small/medium/large)
  ...

D-23 MULTI-LAYER vs D-22 SINGLE-LAYER:
  ...

SIGNIFICANCE SUMMARY:
  Total valid tests: XX
  Significant (p < 0.0167): X (XX.X%)
```

**7. Cell 20 Output — GO/NO-GO Decision** (the whole thing):

```
[1/7] EXECUTION — Token Overflow Rate
  Result: PASS/FAIL

[2/7] IMPROVEMENT OVER D-21
  ...

...

FINAL SCORING & DECISION
  Criteria passed: X/7
  Mandatory conditions (2 + 4): MET/NOT MET

  ╔══════════════════════════════════════════════════════════════════════╗
  ║  DECISION: GO / CONDITIONAL_GO / NO_GO                             ║
  ╚══════════════════════════════════════════════════════════════════════╝
```

**8. Any errors, warnings, or anomalies**, especially:
- Token overflow percentage (from Cell 10)
- Missing layers (layers with low presence rates)
- Queries that degraded significantly
- Runtime errors

**Optional but very helpful:**
- Screenshot of the 3-way comparison bar chart (`visualization_3way_comparison.png`)
- Screenshot of the delta heatmap (`visualization_delta_heatmap.png`)
- Screenshot of the layer token distribution box plot (`visualization_layer_token_distribution.png`)
- The content of `d23_go_nogo_decision.txt` if Cell 21 created it

### What I'll Do With This Data

I'll review the full 7-criterion evaluation, validate the decision logic, check for any anomalies (e.g., degradation in specific query types, borderline p-values that might change under different correction methods), and help you interpret what the results mean for:

1. **If GO**: What D-24 (Layer Ablation) should focus on — which layers to test removing first based on the token audit and marginal value analysis
2. **If CONDITIONAL GO**: What the caveats are and how D-24's scope should be adjusted
3. **If NO-GO**: What simplification path makes sense, and whether D-24 is worth running in a reduced form

---

## Troubleshooting

### "ModuleNotFoundError" after pip install

Cell 02 installs everything, but sometimes Colab's runtime needs a restart after installing packages (especially `chromadb` or `sentence-transformers`). If you see import errors:

1. Go to `Runtime → Restart runtime`
2. Re-run Cell 02 (pip install)
3. Continue from Cell 03

### Out of Memory (OOM) on bge-m3

BGE-M3 is the largest model and may exceed free-tier GPU memory. Options:

1. **Reduce batch size**: In the embedding cell, look for `batch_size` and reduce it (e.g., from 32 to 8)
2. **Skip bge-m3**: If it consistently OOMs, you can skip it in D-21. The model selection would then be between v2-moe and v1.5 only. Report this to me and we'll adjust.

### "File not found" for D-21/D-22 results

The most common issue. Caused by:

- **Path mismatch**: The notebook expects files at `/mnt/0000_concurrent/d21_output/d21_results.csv` but Colab saves to `/content/d21-output/d21_results.csv`. Fix: update the path constants in Cell 03.
- **Runtime disconnected**: Colab cleaned up the files. Fix: re-run the prior notebook, or restore from Google Drive backup.

To check what files exist:

```python
import os
for root, dirs, files in os.walk('/content'):
    for f in files:
        if f.endswith('.csv'):
            print(os.path.join(root, f))
```

### ChromaDB errors

- **"Collection already exists"**: The notebook should handle this with `get_or_create_collection()`. If not, add this before collection creation:
  ```python
  try:
      client.delete_collection(name=collection_name)
  except:
      pass
  ```
- **"No module named chromadb"**: Run `!pip install chromadb` and restart runtime

### Wilcoxon test warning about zeros

```
UserWarning: Exact p-value calculation does not work if there are zeros
```

This is normal and expected. It means some queries had identical scores before and after enrichment. SciPy handles it correctly — the warning is informational, not an error.

### Colab Disconnects / Timeout

Free-tier Colab disconnects after ~90 minutes of inactivity. Strategies:

1. **Keep the browser tab active** while running
2. **Use Colab Pro** for longer sessions (if available)
3. **Save outputs to Drive** after each notebook completes:
   ```python
   !cp -r /content/d21-output /content/drive/MyDrive/fractalrecall/d21-output
   ```

### Corpus Upload Issues

If corpus files aren't loading correctly:

1. Check that files have `.md` or `.yaml` extension
2. Check that files are in the directory pointed to by `CORPUS_DIR`
3. Run a quick check:
   ```python
   import os
   files = os.listdir(CORPUS_DIR)
   print(f"Found {len(files)} files")
   print(files[:5])  # Show first 5
   ```
   You should see ~67 files.

---

## Quick Reference: What to Copy Back (Checklist)

### After D-21:
- [ ] Model Summary table (mean metrics per model)
- [ ] Weighted Decision Matrix (scores and recommended model)
- [ ] The winning model name
- [ ] Any errors or warnings
- [ ] Chunk counts per model

### After D-22:
- [ ] Delta Analysis summary (mean delta per metric, % queries improved)
- [ ] Wilcoxon Test results (statistic, p-value, significant yes/no)
- [ ] By-Query-Type breakdown
- [ ] Any warnings

### After D-23:
- [ ] Layer Audit summary (presence rates, overflow count)
- [ ] Mean Metrics Comparison table (baseline vs single vs multi)
- [ ] Trend Arrows (direction + percentage)
- [ ] Delta Analysis for all 3 pairs + marginal value analysis
- [ ] Significance results (all 12 tests)
- [ ] Full GO/NO-GO Decision Engine output (all 7 criteria + final decision)
- [ ] Any errors or anomalies

---

## Execution Order Summary

```
Step 1:  Upload corpus to Colab
Step 2:  Run D-21 (baseline)              → Report results → Get confirmation
Step 3:  Set SELECTED_MODEL from D-21
Step 4:  Run D-22 (single-layer)           → Report results → Get confirmation
Step 5:  Run D-23 (multi-layer + GO/NO-GO) → Report ALL results
Step 6:  Together, interpret GO/NO-GO and plan D-24
```

You can run all three notebooks in sequence without waiting for my confirmation between each — the notebooks are designed to be self-contained. But if you want a checkpoint between each one (especially if you're unsure about the model selection from D-21), feel free to report back after each notebook and we'll discuss before proceeding.

---

**End of Colab Execution & Results Handoff Guide**
