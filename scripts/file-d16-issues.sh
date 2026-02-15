#!/usr/bin/env bash
# =============================================================================
# file-d16-issues.sh
# =============================================================================
# Purpose:  Files 5 GitHub issues for D-16 open questions (OQ-D16-1 through
#           OQ-D16-5) on the chronicle repo under southpawriter02.
#
# Prerequisites:
#   - gh CLI installed and authenticated (gh auth login)
#   - Write access to southpawriter02/chronicle
#
# Usage:
#   chmod +x file-d16-issues.sh
#   ./file-d16-issues.sh
#
# What it does:
#   1. Creates 5 issues on southpawriter02/chronicle
#   2. Labels them with "D-16", "open-question", and track labels
#   3. Prints issue URLs for each created issue
#
# Idempotency:
#   This script does NOT check for existing issues. Running it twice will
#   create duplicate issues. Check your issue list first if re-running.
#
# Labels:
#   The script attempts to create labels if they don't exist. If label
#   creation fails (e.g., label already exists), it continues silently.
# =============================================================================

set -euo pipefail

REPO="southpawriter02/chronicle"
COMMON_LABELS="D-16,open-question,Track-C"

# ---------------------------------------------------------------------------
# Ensure required labels exist (idempotent — gh label create is a no-op if
# the label already exists, but older gh versions may error, so we || true)
# ---------------------------------------------------------------------------
echo "=== Ensuring labels exist ==="
gh label create "D-16" --repo "$REPO" --description "Related to D-16: Worldbuilding Grammar Profile Spec" --color "0E8A16" 2>/dev/null || true
gh label create "open-question" --repo "$REPO" --description "Design question requiring decision" --color "D93F0B" 2>/dev/null || true
gh label create "Track-C" --repo "$REPO" --description "Track C: Haiku Protocol Integration" --color "1D76DB" 2>/dev/null || true
gh label create "research" --repo "$REPO" --description "Research task" --color "FBCA04" 2>/dev/null || true
echo "Labels ready."
echo ""

# ---------------------------------------------------------------------------
# Issue 1: OQ-D16-1 — contested/speculative canon extension
# ---------------------------------------------------------------------------
echo "=== Filing OQ-D16-1 ==="
gh issue create --repo "$REPO" \
  --title "[D-16] OQ-D16-1: Extend D-10 canon field with contested/speculative levels" \
  --label "$COMMON_LABELS" \
  --body "$(cat <<'EOF'
## Open Question: OQ-D16-1

**Source:** D-16 §13 (Worldbuilding Grammar Profile Specification, v0.1.1-draft)

### Question

Should `contested` and `speculative` be added to D-10's `canon` field?

### Context

The Worldbuilding Profile's CANON operator (WB-004) proposes 6 authority levels:
- `true` — established canon (exists in D-10)
- `false` — draft/uncanonized (exists in D-10)
- `apocryphal` — excluded from canonical queries (exists in D-10)
- `deprecated` — superseded by newer lore (exists in D-10)
- **`contested`** — multiple conflicting accounts (NEW)
- **`speculative`** — unconfirmed theories (NEW)

Currently, D-10 §4.2 defines only the first four. The two new levels exist only at the Grammar Profile level. If they prove useful, they should be proposed as an amendment to D-10 §4.2 and D-11's canon workflow state machine.

### Decision Criteria

- Does Track B prototyping surface use cases for in-corpus authority disagreements?
- Does the Aethelgard corpus contain entries where different in-world factions disagree about facts?
- Would `contested` create a meaningful retrieval distinction (e.g., excluding contested content from authoritative queries)?

### Impact

- **If yes:** Amend D-10 §4.2 (add two enum values), update D-11 state machine (add transitions), update D-12 validation rules
- **If no:** `contested` and `speculative` remain Profile-level extensions only, mapped to `false` when serialized to D-10 format

### Status

Open. Decision depends on Track B prototyping results.

### Dependencies

- D-10 (Lore File Schema Spec)
- D-11 (Canon Workflow Specification)
- D-12 (Validation Rule Catalog)
EOF
)"
echo ""

# ---------------------------------------------------------------------------
# Issue 2: OQ-D16-2 — ENTITY inheritance for parent/child documents
# ---------------------------------------------------------------------------
echo "=== Filing OQ-D16-2 ==="
gh issue create --repo "$REPO" \
  --title "[D-16] OQ-D16-2: ENTITY inheritance for parent/child documents" \
  --label "$COMMON_LABELS" \
  --body "$(cat <<'EOF'
## Open Question: OQ-D16-2

**Source:** D-16 §13 (Worldbuilding Grammar Profile Specification, v0.1.1-draft)

### Question

Should ENTITY support inheritance for parent/child documents?

### Context

D-10 §4.7 defines parent/child entity relationships with inheritance semantics — children inherit parent frontmatter unless explicitly overridden. When compressing a child entity to haiku form, should its ENTITY declaration automatically inherit the parent's META, CANON, and TEMPORAL operators?

**Example:** The Forsaken faction has child documents for individual fragments (oral histories, specimen analyses, etc.). If a fragment's haiku omits CANON, should it inherit the parent's `CANON:false:Scriptorium_Compilation`?

### Options

1. **Implicit inheritance:** Child haikus inherit parent operators unless overridden. Pros: fewer tokens, DRY. Cons: haikus aren't self-contained, requires parent resolution at decode time.
2. **Explicit / self-contained:** Every haiku includes all operators. Pros: no resolution needed, works standalone. Cons: more tokens, redundancy.
3. **Hybrid:** Define which operators inherit (META, CANON, TEMPORAL) and which don't (DESC, RELATION). This mirrors D-10's inheritance model.

### Decision Criteria

- Does the enrichment pipeline have access to parent haikus at prefix-generation time?
- How much token overhead does full self-containment add per child haiku?
- Does FractalRecall need parent context when embedding child chunks?

### Status

Open. Deferred to D-15 (Integration Design Document).

### Dependencies

- D-10 §4.7 (Parent/child entity relationships)
- D-15 (Integration Design Document)
EOF
)"
echo ""

# ---------------------------------------------------------------------------
# Issue 3: OQ-D16-3 — Fragment-level compression strategy
# ---------------------------------------------------------------------------
echo "=== Filing OQ-D16-3 ==="
gh issue create --repo "$REPO" \
  --title "[D-16] OQ-D16-3: Fragment-level compression strategy" \
  --label "$COMMON_LABELS" \
  --body "$(cat <<'EOF'
## Open Question: OQ-D16-3

**Source:** D-16 §13 (Worldbuilding Grammar Profile Specification, v0.1.1-draft)

### Question

How should fragment-level compression work?

### Context

The Forsaken entry (used as D-16's worked example) contains 10 fragments, each with its own metadata, perspective, and evidence type:
- Oral histories (e.g., Echo-Mother Syl's account)
- Specimen analyses (CPS resistance study)
- Linguistic studies (Fimbul-Cant analysis)
- Economic analyses (Ice-Debt system)
- Echo recordings (emergency broadcasts)
- Visual surveys (Dreadnought hold demographics)

Each fragment has distinct metadata (fragment_type, evidence_type, perspective, confidence_level) that differs from the parent entity's metadata.

### Options

1. **Separate haikus per fragment:** Each fragment gets its own complete haiku with REF links to the parent entity. Mirrors D-10's file-per-entity model. Best for retrieval granularity.
2. **Sub-blocks within parent haiku:** Fragments encoded as labeled sub-blocks inside the parent entity's haiku (e.g., `-- Fragment: Echo-Mother Account --`). More compact but less granular for retrieval.
3. **Hybrid:** Parent haiku covers the assembled narrative entry; fragments get separate haikus only if they contain unique information not in the assembly.

### Recommendation

Option 1 (separate haikus per fragment with REF links to parent). This:
- Mirrors D-10's one-file-per-entity model
- Maximizes retrieval granularity (each fragment is independently searchable)
- Avoids bloating parent haikus beyond the 512-token embedding window
- Aligns with FractalRecall's chunk-level enrichment architecture

### Status

Open. Recommendation provided; awaiting confirmation during D-15 design.

### Dependencies

- D-10 (Lore File Schema — fragment structure)
- D-15 (Integration Design Document)
- FractalRecall chunking strategy
EOF
)"
echo ""

# ---------------------------------------------------------------------------
# Issue 4: OQ-D16-4 — DESC compression quality metrics
# ---------------------------------------------------------------------------
echo "=== Filing OQ-D16-4 ==="
gh issue create --repo "$REPO" \
  --title "[D-16] OQ-D16-4: Define DESC compression quality metrics" \
  --label "$COMMON_LABELS,research" \
  --body "$(cat <<'EOF'
## Open Question: OQ-D16-4

**Source:** D-16 §13 (Worldbuilding Grammar Profile Specification, v0.1.1-draft)

### Question

How do we measure DESC compression quality?

### Context

DESC operators (WB-005) contain compressed natural language — the loosest operator in the Worldbuilding Profile. Unlike structured operators (ENTITY, RELATION, TEMPORAL) where correctness is binary (either the entity name is right or it isn't), DESC quality is a spectrum. The same source text could be compressed multiple ways with varying fidelity.

**Example — source text:**
> "The Forsaken are not a people. They are a condition — the terminal status of those who have fallen through every other social safety net post-Glitch Aethelgard provides."

**High-quality compression:**
`DESC:identity:Status_class_not_ethnic_group; terminal_social_category; bound_by_circumstance_not_blood`

**Low-quality compression:**
`DESC:identity:Forsaken_group_info`

Both are syntactically valid. The first preserves the key semantic distinctions (not ethnic, terminal, circumstantial). The second loses almost everything.

### Proposed Metrics

1. **Semantic similarity:** Cosine similarity between embedding of source text and embedding of expanded DESC (using the same model FractalRecall uses — nomic-embed-text-v2-moe)
2. **Information retention rate:** Percentage of named entities, quantitative values, and causal relationships preserved from source to compressed form
3. **Retrieval effectiveness:** Does searching for terms in the source text still surface the haiku-compressed version? (A/B test: natural language prefix vs. haiku prefix)
4. **Round-trip fidelity:** Can an LLM expand the DESC back to prose that preserves the original's key facts? (LLM-as-judge evaluation)

### Proposed Action

File as R-11 research task if the Worldbuilding Profile advances to implementation. This would be a Track B Colab notebook measuring compression quality empirically.

### Status

Open. Potentially implementation-blocking — without quality metrics, we can't validate that DESC compression is "good enough" for retrieval.

### Dependencies

- Track B Colab results (D-21 through D-25)
- FractalRecall embedding model selection
- Haiku Protocol Phase 2 encoder (worldbuilding profile)
EOF
)"
echo ""

# ---------------------------------------------------------------------------
# Issue 5: OQ-D16-5 — Grammar profile switching
# ---------------------------------------------------------------------------
echo "=== Filing OQ-D16-5 ==="
gh issue create --repo "$REPO" \
  --title "[D-16] OQ-D16-5: Grammar profile switching in mixed documents" \
  --label "$COMMON_LABELS" \
  --body "$(cat <<'EOF'
## Open Question: OQ-D16-5

**Source:** D-16 §13 (Worldbuilding Grammar Profile Specification, v0.1.1-draft)

### Question

Can a single document contain both the Procedural and Worldbuilding profiles?

### Context

Some documents might contain both procedural and narrative content. For example:
- A Chronicle CLI guide that references worldbuilding examples
- A deployment runbook for a system that manages lore data
- A notebook spec (like D-23) that contains both code procedures and entity descriptions

Currently, a haiku is assumed to be entirely one profile. If mixed content exists, should the grammar support inline profile switching?

### Options

1. **No mixing:** Documents are classified as one profile. Mixed documents are split into profile-specific sections before compression. Simple, no grammar changes needed.
2. **Inline switching:** A `META:profile=worldbuilding` / `META:profile=procedural` operator signals a profile change mid-haiku. The decoder switches operator sets at that point.
3. **Profile annotations per block:** Each composition block (Entity Declaration, Narrative, Action Sequence, etc.) carries an implicit profile based on its structure. No explicit switching needed — the parser infers profile from operator usage.

### Recommendation

Option 1 (no mixing) for now. Most documents are clearly one profile or the other. The complexity of inline profile switching isn't justified until we have concrete mixed-profile use cases.

### Status

Open. Low priority — defer to v0.0.2c or later if the need arises.

### Dependencies

- v0.0.2b (Procedural Grammar)
- D-16 (Worldbuilding Grammar Profile)
- Future: v0.0.2c (Unified CNL Specification, if pursued)
EOF
)"
echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "============================================="
echo "All 5 D-16 open question issues filed."
echo "============================================="
echo ""
echo "To add these issues to the Chronicle Initiative project board:"
echo "  gh project item-add <PROJECT_NUMBER> --owner southpawriter02 --url <ISSUE_URL>"
echo ""
echo "To set custom fields on the project board:"
echo "  gh project item-edit --project-id <PROJECT_ID> --id <ITEM_ID> --field-id <FIELD_ID> --single-select-option-id <OPTION_ID>"
echo ""
echo "Suggested field values for all 5 issues:"
echo "  Status:      Backlog"
echo "  Priority:    P2"
echo "  Size:        S (small — each is a design decision, not implementation)"
echo "  Type:        Research"
echo "  Track:       Cross-Cutting"
echo "  Document ID: D-16"
