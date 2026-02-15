# Chronicle + FractalRecall: Unified Design Proposal

**Version:** 0.1.0-draft  
**Status:** Initial Design Proposal — Pre-Implementation  
**Author:** Ryan (with architectural guidance from Claude)  
**Created:** 2026-02-09  
**Last Updated:** 2026-02-09  
**Companion Document:** `FractalRecall-Conceptual-Architecture.md` (detailed FractalRecall specification)

---

## Table of Contents

- [1. Document Purpose and Audience](#1-document-purpose-and-audience)
- [2. Project Overview](#2-project-overview)
  - [2.1. Chronicle: What It Is](#21-chronicle-what-it-is)
  - [2.2. FractalRecall: What It Is](#22-fractalrecall-what-it-is)
  - [2.3. Why Two Projects, Not One](#23-why-two-projects-not-one)
  - [2.4. How They Relate](#24-how-they-relate)
- [3. The Problem Space](#3-the-problem-space)
  - [3.1. Problems Chronicle Solves](#31-problems-chronicle-solves)
  - [3.2. Problems FractalRecall Solves](#32-problems-fractalrecall-solves)
  - [3.3. The Intersection: Why Both Are Needed](#33-the-intersection-why-both-are-needed)
- [4. Chronicle: Detailed Design](#4-chronicle-detailed-design)
  - [4.1. The Core Metaphor: Lore as Source Code](#41-the-core-metaphor-lore-as-source-code)
  - [4.2. The Lore Repository Structure](#42-the-lore-repository-structure)
  - [4.3. YAML Frontmatter Schema](#43-yaml-frontmatter-schema)
  - [4.4. Canon Management Workflow](#44-canon-management-workflow)
  - [4.5. Deterministic Validation and Linting](#45-deterministic-validation-and-linting)
  - [4.6. Changelog Generation](#46-changelog-generation)
  - [4.7. CLI Command Surface (Proposed)](#47-cli-command-surface-proposed)
- [5. FractalRecall: Summary of Conceptual Architecture](#5-fractalrecall-summary-of-conceptual-architecture)
  - [5.1. The Core Concept: Embeddings with Structural DNA](#51-the-core-concept-embeddings-with-structural-dna)
  - [5.2. Context Layers](#52-context-layers)
  - [5.3. Standard Layer Types](#53-standard-layer-types)
  - [5.4. Embedding Strategies Under Evaluation](#54-embedding-strategies-under-evaluation)
  - [5.5. Domain-Agnostic Design](#55-domain-agnostic-design)
- [6. LLM Integration Architecture](#6-llm-integration-architecture)
  - [6.1. Design Principle: Advisory, Never Authoritative](#61-design-principle-advisory-never-authoritative)
  - [6.2. Semantic Contradiction Detection](#62-semantic-contradiction-detection)
  - [6.3. Semantic Search via FractalRecall](#63-semantic-search-via-fractalrecall)
  - [6.4. Merge Conflict Narrative Resolution](#64-merge-conflict-narrative-resolution)
  - [6.5. Lore Expansion Suggestions](#65-lore-expansion-suggestions)
  - [6.6. Draft Stub Generation](#66-draft-stub-generation)
  - [6.7. Local LLM Infrastructure](#67-local-llm-infrastructure)
- [7. Concurrent Development Strategy](#7-concurrent-development-strategy)
  - [7.1. Why Concurrent, Not Sequential](#71-why-concurrent-not-sequential)
  - [7.2. Direction of Influence: Chronicle Drives FractalRecall's API](#72-direction-of-influence-chronicle-drives-fractalrecalls-api)
  - [7.3. The Extract and Generalize Pattern](#73-the-extract-and-generalize-pattern)
  - [7.4. Repository and Package Structure](#74-repository-and-package-structure)
- [8. Development Phases](#8-development-phases)
  - [8.1. Phase 0: Google Colab Prototyping (FractalRecall Validation)](#81-phase-0-google-colab-prototyping-fractalrecall-validation)
  - [8.2. Phase 1: Documentation (Both Projects)](#82-phase-1-documentation-both-projects)
  - [8.3. Phase 2: Foundational Implementation (Both Projects)](#83-phase-2-foundational-implementation-both-projects)
  - [8.4. Phase 3: Integration (Connecting Chronicle to FractalRecall)](#84-phase-3-integration-connecting-chronicle-to-fractalrecall)
  - [8.5. Phase 4: LLM-Powered Features (Chronicle)](#85-phase-4-llm-powered-features-chronicle)
- [9. Technology Stack](#9-technology-stack)
  - [9.1. C# / .NET (Production)](#91-c--net-production)
  - [9.2. Python / Google Colab (Prototyping)](#92-python--google-colab-prototyping)
  - [9.3. Embedding Models](#93-embedding-models)
  - [9.4. Vector Storage](#94-vector-storage)
  - [9.5. LLM Inference](#95-llm-inference)
- [10. Broader Applications Beyond Worldbuilding](#10-broader-applications-beyond-worldbuilding)
- [11. Portfolio and Open-Source Strategy](#11-portfolio-and-open-source-strategy)
  - [11.1. Two Entry Points for Discovery](#111-two-entry-points-for-discovery)
  - [11.2. Portfolio Narrative](#112-portfolio-narrative)
  - [11.3. Licensing Considerations](#113-licensing-considerations)
- [12. Documents Roadmap: What Needs to Be Written](#12-documents-roadmap-what-needs-to-be-written)
  - [12.1. Completed Documents](#121-completed-documents)
  - [12.2. Phase 1 Documents (Pre-Implementation)](#122-phase-1-documents-pre-implementation)
  - [12.3. Phase 2+ Documents (During Implementation)](#123-phase-2-documents-during-implementation)
- [13. Key Design Decisions and Rationale](#13-key-design-decisions-and-rationale)
- [14. Open Questions](#14-open-questions)
- [15. Glossary](#15-glossary)
- [16. Document Revision History](#16-document-revision-history)

---

## 1. Document Purpose and Audience

This document serves as the **authoritative design proposal** for two concurrent, related open-source projects: **Chronicle** (a version-controlled worldbuilding system) and **FractalRecall** (a hierarchical context-aware embedding retrieval library). Its primary purpose is to capture the full design context — the problems being solved, the architectural decisions, the development strategy, the LLM integration plans, and the relationship between the two projects — in sufficient detail that any future collaborator (human or AI) can read this document and be fully oriented on the project's goals, constraints, and current state.

This document is intentionally comprehensive. It was produced during an extended brainstorming and design session, and it captures decisions, rationale, and context that would otherwise be lost between sessions. It is meant to be the "single source of truth" that all future work references.

The companion document, `FractalRecall-Conceptual-Architecture.md`, provides the deep technical specification for FractalRecall specifically (context layers, embedding strategies, API design, evaluation framework, prototyping plan). This document provides the broader context that FractalRecall exists within, including Chronicle's full design and the strategy for developing both projects concurrently.

---

## 2. Project Overview

### 2.1. Chronicle: What It Is

Chronicle is a **C# CLI tool that treats worldbuilding lore like a software codebase**. It sits on top of Git and extends it with domain-specific concepts that Git doesn't natively understand: canon status, lore entities, cross-references between documents, timeline consistency, and semantic validation.

In practical terms, a Chronicle-managed worldbuilding project is a Git repository containing Markdown files organized in a conventional directory structure. Each Markdown file represents a discrete "lore entry" — a faction, a character, a location, an event, a timeline, a game mechanic — and each file has YAML frontmatter that provides structured metadata the tool can parse, validate, and reason about. Chronicle's CLI commands operate on this repository: scanning for consistency errors, enforcing canon workflow rules, generating changelogs, performing semantic search (via FractalRecall), and running LLM-powered analysis (contradiction detection, lore gap identification, draft generation).

The fundamental insight is that **worldbuilding has the same structural challenges as software development** — versioning, consistency, collaboration, review, and quality assurance — and it deserves the same caliber of tooling. Chronicle is what you'd get if you designed a documentation quality tool specifically for fiction writers and game designers, built on the same principles that make modern software development manageable.

The first integration target is the author's own worldbuilding project, **Aethelgard** (a post-apocalyptic fantasy TTRPG setting currently at version 5.0), which provides both the motivating use case and the primary test corpus.

### 2.2. FractalRecall: What It Is

FractalRecall is a **.NET class library** (distributed as a NuGet package) that improves embedding-based retrieval by encoding **hierarchical structural context** — what we call "context layers" — directly into the embedding representation. Where standard RAG (Retrieval-Augmented Generation) systems treat every text chunk as a context-free fragment, FractalRecall ensures that each chunk carries its full structural identity: where it came from, what kind of content it is, how authoritative it is, what other entities it relates to, and where it sits in the temporal and categorical hierarchy of the knowledge base.

The name reflects the core insight: just as a fractal exhibits self-similar structure at every level of magnification, a well-organized knowledge base has meaningful structure at every level of granularity. FractalRecall ensures that retrieval is aware of structure at *every* level, not just the leaf-node level where the actual text lives.

FractalRecall is **domain-agnostic by design**. It provides the *mechanism* for defining, composing, and querying hierarchical context layers. The consuming application provides the *content* of those layers. Chronicle is the first consumer, but the library is deliberately general enough to support technical documentation, legal corpora, game design knowledge bases, medical records, and any other domain where content has meaningful structure beyond its raw semantic meaning.

The detailed technical specification for FractalRecall — including the problem statement, research foundations, layer specification, embedding strategies, API design, evaluation framework, and prototyping plan — is documented in the companion `FractalRecall-Conceptual-Architecture.md` document. This section provides a summary; that document provides the full specification.

### 2.3. Why Two Projects, Not One

The decision to implement Chronicle and FractalRecall as **separate projects** (separate repositories, separate NuGet packages) is deliberate and has several motivations.

**Reusability:** FractalRecall's hierarchical context-aware retrieval technique is not inherently about worldbuilding. It's a general-purpose approach applicable to legal document retrieval, technical documentation search, medical knowledge bases, codebase navigation, and many other domains. If built as a tightly coupled component *inside* Chronicle, the technique would only be available to worldbuilders. As a standalone library, any .NET developer can use it for their own domain.

**Separation of Concerns:** Chronicle's responsibility is worldbuilding domain logic — the lore file schema, the canon workflow, the validation rules, the Git integration, the LLM-powered advisory features. FractalRecall's responsibility is retrieval intelligence — how to compose context layers into embeddings, how to index them, how to query them efficiently. Each project has a clear, distinct responsibility. Mixing them would produce a monolith that's harder to test, harder to document, and harder to contribute to.

**Portfolio Value:** Two well-documented, well-tested open-source projects look better on a GitHub profile than one monolithic project, especially when one (FractalRecall) has broad applicability that a hiring manager or collaborator can immediately appreciate regardless of whether they care about tabletop RPGs. FractalRecall says "I understand AI retrieval patterns and can build reusable tooling." Chronicle says "I can design and build a complex, domain-specific application with rigorous documentation." Together, they tell a more complete story.

**Independent Evolution:** FractalRecall could gain traction in the .NET AI community independent of Chronicle. Chronicle could switch to a different retrieval library if something better emerges. Neither project's roadmap is held hostage to the other's.

### 2.4. How They Relate

Chronicle **depends on** FractalRecall as a NuGet package reference. When Chronicle needs to build embeddings or perform semantic search, it constructs `ContextLayer` instances using its domain knowledge (it knows that "canon status" is a layer, that "entity type" is a layer, that "era" is a layer) and passes them to FractalRecall for embedding and retrieval.

Think of it like the relationship between a web application and its ORM (Object-Relational Mapper). The ORM doesn't know anything about the application's business logic — it just knows how to map objects to a database. The application provides the domain objects and the ORM handles the persistence mechanics. Similarly, Chronicle provides the domain knowledge (what layers matter, how they're derived from frontmatter, how they should be weighted) and FractalRecall provides the retrieval mechanics (how to compose layers into embeddings, how to index them, how to query them).

The projects also share an **Integration Design Document** (to be written during Phase 1) that lives in Chronicle's repository and describes exactly how Chronicle consumes FractalRecall's API. This document keeps the two projects aligned as they develop concurrently.

---

## 3. The Problem Space

### 3.1. Problems Chronicle Solves

Chronicle addresses five specific, recurring problems that worldbuilders face when managing large, evolving fictional universes.

**Continuity Drift:** Over months or years of worldbuilding, documents subtly contradict each other. A faction's founding date in one file doesn't match the timeline in another. A character's allegiance in their own document doesn't match their listing in a faction document. These contradictions accumulate silently because there's no automated way to check for them. Chronicle's deterministic validation layer catches structural contradictions (date mismatches, broken references, schema violations), and its LLM-powered deep validation layer catches semantic contradictions that live in the prose itself.

**Fear of Revision:** Worldbuilders hesitate to revise established content because they can't easily assess the downstream impact. "If I change the founding date of this faction, what other documents break?" Chronicle's cross-reference integrity checking and dependency tracking answer this question before the change is made.

**Canon Confusion:** When worldbuilders explore "what if" scenarios, draft new content, or collaborate with others, it's easy for speculative or unfinished content to get confused with established canon. Chronicle introduces formal canon status management — canonical, draft, apocryphal, deprecated — as a first-class workflow concept, ensuring that the authority status of every piece of content is explicit, tracked, and enforceable.

**Collaboration Friction:** Multiple contributors to a shared world have no structured way to review each other's work before it becomes "official." Chronicle models the contribution workflow after software pull requests: new lore is developed on branches, validated by automated checks, reviewed (either by another person or by the LLM advisory layer), and merged into the canonical branch only when it passes all checks.

**Discoverability:** In a large lore corpus, finding relevant information requires either perfect memory or exhaustive keyword search. Chronicle's semantic search (powered by FractalRecall) lets worldbuilders ask natural language questions ("What factions have a presence in the northern territories?") and get relevant results even when the exact terminology doesn't match.

### 3.2. Problems FractalRecall Solves

FractalRecall addresses three documented deficiencies in standard embedding-based retrieval systems (RAG). These are described in full detail in the companion `FractalRecall-Conceptual-Architecture.md` document (Section 2). A brief summary is provided here.

**The Semantic Proximity Trap:** Standard embeddings know *what* content is about, but not *which version* of that content is authoritative. A canonical document and a speculative "what if" document about the same topic produce nearly identical embeddings, but only one is the right answer. FractalRecall's Authority context layer enables the retrieval system to distinguish between them.

**Chunking Amnesia:** When documents are broken into chunks for embedding, each chunk loses its structural context — its parent document, its section, its position in the hierarchy. FractalRecall's multi-layer composite representation ensures that each chunk retains its full "structural address" through the embedding process.

**Authority Blindness:** Standard retrieval systems treat all content as equally authoritative. In any knowledge base with drafts, versions, or editorial approval stages, this is dangerously incorrect. FractalRecall's authority-aware context layers and layer-weighted retrieval enable structurally informed ranking.

### 3.3. The Intersection: Why Both Are Needed

Chronicle without FractalRecall would have deterministic validation (schema checks, cross-reference integrity, timeline consistency) but no semantic search or LLM-powered analysis. It would be a useful linting tool, but it wouldn't be able to answer natural language questions about the lore or detect semantic contradictions that live in prose rather than in structured metadata.

FractalRecall without Chronicle would be a general-purpose embedding library with no real-world application to drive its API design. Library APIs designed in a vacuum tend to miss the needs of actual consumers. Chronicle provides the "real-world pressure" that shapes FractalRecall's interface into something genuinely useful.

Together, they form a system where Chronicle provides the domain intelligence (understanding worldbuilding structure) and FractalRecall provides the retrieval intelligence (understanding how to embed and search that structure effectively).

---

## 4. Chronicle: Detailed Design

### 4.1. The Core Metaphor: Lore as Source Code

Chronicle's design is built on the observation that worldbuilding lore is structurally identical to a software codebase. Both consist of interconnected documents that reference each other, both evolve over time through revisions, both have quality standards that can be automatically checked, both benefit from version control, both require collaboration workflows when multiple contributors are involved, and both need a clear distinction between "work in progress" and "released/canonical."

The mapping is as follows. Source code files correspond to lore entry Markdown files. The `main` branch corresponds to the canonical record of the world. Feature branches correspond to branches where new lore is developed. Pull requests correspond to "canon review" (the process of validating and merging new lore). CI/CD checks correspond to Chronicle's deterministic validation rules. Compiler errors correspond to schema violations and broken cross-references. Linter warnings correspond to LLM-detected semantic tensions. API documentation corresponds to the lore's structural metadata (YAML frontmatter). Semantic versioning corresponds to world version tracking (Aethelgard v4.0 → v5.0).

### 4.2. The Lore Repository Structure

A Chronicle-managed repository follows a conventional directory structure. The tool understands these directories as **entity type categories** and expects files within them to conform to the corresponding frontmatter schema.

```
aethelgard/
├── .chronicle/              # Chronicle configuration and index files
│   ├── config.yaml          # Repository-level configuration
│   ├── schema/              # Frontmatter schema definitions per entity type
│   │   ├── faction.yaml
│   │   ├── character.yaml
│   │   ├── location.yaml
│   │   ├── event.yaml
│   │   ├── timeline.yaml
│   │   └── system.yaml      # Game mechanics
│   └── index/               # FractalRecall embedding index (gitignored)
│       └── fractal.db       # SQLite vector database
├── factions/
│   ├── iron-covenant.md
│   ├── silver-hand.md
│   └── ...
├── characters/
│   ├── elena-voss.md
│   └── ...
├── locations/
│   ├── ashenmoor/
│   │   ├── overview.md
│   │   ├── thornhaven.md
│   │   └── ...
│   └── ...
├── events/
│   ├── arcane-purges.md
│   ├── siege-of-thornhaven.md
│   └── ...
├── timeline/
│   ├── ages-overview.md
│   ├── third-age.md
│   └── ...
├── systems/                  # Game mechanics (rules, classes, etc.)
│   └── ...
├── apocrypha/                # Explicitly non-canonical explorations
│   ├── what-if-covenant-never-fell.md
│   └── ...
├── CHANGELOG.md              # Auto-generated by Chronicle
└── README.md
```

The `.chronicle/index/` directory is `.gitignore`'d because it contains derived data (the FractalRecall embedding index) that can be regenerated from the source files at any time. The `.chronicle/schema/` directory is version-controlled because the schemas *are* the specification — they define what a valid lore file looks like, and changes to them should be tracked and reviewed.

### 4.3. YAML Frontmatter Schema

Every lore entry Markdown file begins with YAML frontmatter that provides structured metadata. The required and optional fields depend on the entity type (faction, character, location, etc.), as defined in the schema files under `.chronicle/schema/`. The following is a representative example of a faction document's frontmatter.

```yaml
---
# Required fields for type: faction
type: faction
name: The Iron Covenant
canon: true                     # Canon status: true, false (draft), "apocryphal", "deprecated"

# Temporal context
era: [Third Age, Fourth Age]    # Which eras this entity is active in
founded: "Third Age, Year 412"  # Specific founding date (free text, validated against timeline)
dissolved: "Fourth Age, Year 88"

# Spatial context
region: Ashenmoor               # Primary region of activity

# Relationships (machine-readable links to other entities)
relationships:
  - target: "characters/elena-voss.md"  # Relative path within the repository
    type: founded_by
    since: "Third Age, Year 412"
  - target: "factions/silver-hand.md"
    type: rivalry
    since: "Third Age, Year 450"
    note: "Territorial dispute over Ashenmoor border regions"
  - target: "events/arcane-purges.md"
    type: catalyzed_by

# Metadata
tags: [military, expansionist, fallen, anti-magic]
aliases: ["The Covenant", "Voss's Legion"]  # Alternative names for cross-reference matching
superseded_by: null             # If deprecated, points to replacement document
last_validated: 2026-02-09      # Date of last Chronicle validation pass
---
```

The schemas are designed to be **extensible by the user**. Chronicle ships with default schemas for common entity types, but the user can define custom entity types and schemas for their specific world. A sci-fi setting might have `starship`, `planet`, and `species` entity types with their own required fields. A historical fiction setting might have `historical_figure`, `battle`, and `treaty` types.

### 4.4. Canon Management Workflow

Chronicle introduces four canon statuses, each with defined workflow rules.

**Canonical (`canon: true`):** The content is part of the official, established world. Canonical content lives on the `main` branch and has passed all validation checks. Changing canonical content requires a branch, a validation pass, and a merge (analogous to a pull request in software development). This ensures that canon is never modified carelessly.

**Draft (`canon: false`):** The content is work-in-progress. It exists on a working branch and has not yet been validated or approved for canon. Draft content may contain placeholder references, incomplete sections, or speculative elements. Chronicle's search results can optionally include draft content (with clear labeling), but draft content is excluded from canon-scoped queries by default.

**Apocryphal (`canon: "apocryphal"`):** The content is explicitly non-canonical. It represents "what if" explorations, alternate timelines, cut content, or creative exercises that the author wants to preserve but never intends to merge into canon. Apocryphal content lives in the `apocrypha/` directory (by convention) or on branches tagged as apocryphal. Chronicle's validation rules are relaxed for apocryphal content — it's allowed to contradict canon, because that's the whole point.

**Deprecated (`canon: "deprecated"`):** The content was formerly canonical but has been superseded by newer content. Deprecated files are not deleted; they remain in the repository with a `superseded_by` reference pointing to the replacement document. This preserves the world's editorial history and allows the author to see how the world has evolved over time. Chronicle's search excludes deprecated content by default but can include it with an explicit flag.

The workflow for promoting content from draft to canonical follows this process: the author creates a branch, writes or modifies lore files with `canon: false`, runs `chronicle validate` on the branch (which performs all deterministic checks), optionally runs `chronicle validate --deep` (which performs LLM-powered semantic checks), reviews the validation report, fixes any issues, and then merges the branch into `main`. Upon merge, Chronicle automatically updates `canon: false` to `canon: true` on the merged files and generates a changelog entry.

### 4.5. Deterministic Validation and Linting

Chronicle's deterministic validation layer performs rule-based checks that require no AI involvement. These checks are fast, deterministic, and trustworthy — they either pass or fail, with no ambiguity. They are organized into the following categories.

**Schema Validation:** Every file's YAML frontmatter is validated against the schema for its declared entity type. Missing required fields, incorrect data types, and unknown fields are flagged as errors.

**Cross-Reference Integrity:** Every `target` in a `relationships` block is checked to ensure the referenced file actually exists in the repository. Broken references (pointing to files that have been renamed, moved, or deleted) are flagged as errors. Circular references (A references B, B references C, C references A) are detected and flagged as warnings (they may be intentional but should be reviewed).

**Timeline Consistency:** If entity files declare temporal metadata (eras, dates) and timeline files define the boundaries of those eras, Chronicle cross-references them to ensure that declared events fall within their declared eras. Example: if the Third Age is defined as Years 1-500, and a faction claims to be "founded in Year 412 of the Third Age," that's valid. If the timeline is later revised to end the Third Age at Year 400, the faction's founding date is flagged as inconsistent.

**Uniqueness Constraints:** Certain attributes should be unique across the corpus. Two characters shouldn't both be listed as "the founder of the Iron Covenant" (unless the relationship is explicitly marked as a disputed claim). Two locations shouldn't share the same geographic coordinates. Chronicle flags these violations as warnings for the author to review.

**Alias Collision Detection:** If two entities have overlapping aliases (alternative names), Chronicle flags this as a potential source of confusion for both human readers and the LLM advisory layer. Example: if both a character and a location are aliased as "The Beacon," Chronicle warns that cross-reference matching may be ambiguous.

**Canon Status Consistency:** Canonical documents should not reference draft or apocryphal documents in their `relationships` blocks (because that would create a dependency from stable content on unstable content). Chronicle flags these as warnings. The reverse (draft documents referencing canonical documents) is fine and expected.

### 4.6. Changelog Generation

After every merge into the `main` branch, Chronicle automatically generates a changelog entry that summarizes what changed. The changelog is written in Markdown and appended to `CHANGELOG.md` at the repository root.

The changelog is generated by combining Git's diff information (which files were added, modified, or deleted) with Chronicle's semantic understanding of what those files *are*. Instead of saying "Modified `factions/iron-covenant.md`," the changelog says "Revised the founding date of The Iron Covenant from Year 415 to Year 412 of the Third Age." This semantic awareness comes from comparing the old and new YAML frontmatter and identifying which fields changed.

A sample changelog entry might look like this:

```markdown
## Canon Update — 2026-02-09

### New Entries
- **Character:** [Thorne Ashwick](/characters/thorne-ashwick.md) — A disgraced
  alchemist operating in the Frostmarch provinces.
- **Event:** [The Ashwick Incident](/events/ashwick-incident.md) — The explosion
  that destroyed the Thornhaven Academy of Sciences.

### Revised Entries
- **Faction:** [The Iron Covenant](/factions/iron-covenant.md) — Founding date
  corrected from Year 415 to Year 412 of the Third Age.
- **Location:** [Thornhaven](/locations/ashenmoor/thornhaven.md) — Added reference
  to the Ashwick Incident; status updated from "thriving trade hub" to "partially
  destroyed."

### Deprecated Entries
- **Location:** [The Wastelands](/locations/wastelands.md) — Superseded by
  [The Blighted Expanse](/locations/blighted-expanse.md).

### Validation Summary
- 47 total lore files checked.
- 0 schema errors, 0 broken references, 1 timeline warning (under review).
```

### 4.7. CLI Command Surface (Proposed)

The following commands represent Chronicle's proposed CLI interface. This is not a final specification — commands will be refined during implementation. The purpose here is to establish the scope and shape of the tool's user-facing functionality.

**`chronicle init`** — Initialize a new Chronicle repository in the current directory. Creates the `.chronicle/` configuration directory, default schema files, and a starter `README.md`.

**`chronicle scan`** — Scan the repository and build/update the internal entity model (the in-memory graph of all entities and their relationships). This is a prerequisite for most other commands.

**`chronicle validate`** — Run all deterministic validation checks (schema, cross-references, timeline, uniqueness, alias collisions, canon status consistency). Outputs a validation report to the console and optionally to a Markdown file.

**`chronicle validate --deep`** — Run deterministic validation AND LLM-powered semantic validation (contradiction detection, narrative tension identification). Requires a configured LLM endpoint (local via Ollama/LM Studio or remote via API). Outputs an extended validation report.

**`chronicle search <query>`** — Perform a semantic search across the lore corpus using FractalRecall. Returns ranked results with source file paths, structural metadata, and relevance scores. Supports flags for filtering by canon status (`--canon-only`, `--include-apocrypha`), era (`--era "Third Age"`), entity type (`--type faction`), and result count (`--top 10`).

**`chronicle changelog`** — Generate a changelog entry for the current branch's changes compared to `main`. Useful for previewing what the changelog will say before merging.

**`chronicle index`** — Build or rebuild the FractalRecall embedding index from the current repository state. This processes all lore files, constructs composite representations, generates embeddings, and stores them in the index database.

**`chronicle index --incremental`** — Update the embedding index for only the files that have changed since the last indexing run, using structural fingerprint comparison.

**`chronicle graph`** — Output a visualization of the entity relationship graph. Supports output formats: Mermaid diagram (for embedding in Markdown), DOT (for Graphviz rendering), and JSON (for programmatic consumption).

**`chronicle suggest`** — Run the LLM-powered lore expansion analysis. Identifies gaps in the worldbuilding corpus (entities with few or no relationships, sparsely documented regions, referenced-but-undefined entities) and generates a suggestion report.

**`chronicle stub <entity-path>`** — Generate a draft stub document for a referenced-but-undefined entity. Uses LLM to infer initial content from existing references. The stub is created with `canon: false` and clearly marked as machine-generated.

---

## 5. FractalRecall: Summary of Conceptual Architecture

This section provides a condensed summary of FractalRecall's architecture. The full specification, including research foundations, detailed layer anatomy, embedding strategy analysis, API design, evaluation framework, and prototyping plan, is documented in the companion `FractalRecall-Conceptual-Architecture.md` document. That document should be treated as the authoritative reference for FractalRecall's technical design.

### 5.1. The Core Concept: Embeddings with Structural DNA

Standard RAG systems embed text chunks as context-free fragments. Each chunk knows *what it means* (semantic content) but not *what it is* (structural identity). FractalRecall enriches each chunk with its full "structural DNA" — a hierarchical set of context layers that encode provenance, authority, entity type, temporal position, relationships, and structural location — before embedding. The result is an embedding that captures both meaning and identity, enabling retrieval that is both semantically relevant and structurally appropriate.

The concept was inspired by the observation that this problem is analogous to gene function in biology: a gene's behavior depends not only on its nucleotide sequence (content) but also on its chromosomal position (structure), its regulatory elements (authority), and its pathway membership (relationships). The "fractal" in FractalRecall reflects the self-similar, hierarchical nature of this structural context — meaningful at every level of granularity from corpus to sentence.

### 5.2. Context Layers

A Context Layer is the fundamental building block. It represents one level of structural context with a defined type, value, hierarchy position, embedding behavior, and filter behavior. Layers are ordered from outermost (most general, like "which corpus") to innermost (most specific, which is the content itself). A Composite Representation is the assembled collection of all context layers for a given chunk — the full "DNA strand."

### 5.3. Standard Layer Types

FractalRecall ships with eight standard layer types (detailed in the companion document, Section 6.2). In summary, from outermost to innermost: Corpus (which knowledge base), Domain (categorical area), Entity (specific entity described), Authority (canonical status), Temporal (time period), Relational (connections to other entities), Section (document subdivision), Content (the actual text).

### 5.4. Embedding Strategies Under Evaluation

Three candidate approaches for incorporating context layers into embeddings are under evaluation (detailed in the companion document, Section 7). Approach A (Prefix Enrichment) renders all layers as a text prefix before the content and embeds as a single vector — simplest to implement and the recommended starting point for prototyping. Approach B (Multi-Vector Composition) embeds each layer separately and combines scores at query time — most precise but most expensive. Approach C (Hybrid with Metadata Sidecar) embeds high-impact layers as prefixes and stores the rest as metadata for filtering — the likely production recommendation. The Google Colab prototyping phase will empirically determine which approach performs best.

### 5.5. Domain-Agnostic Design

FractalRecall's API is designed so that the library never references worldbuilding, factions, eras, or any other Chronicle-specific concept. The standard layer types (Corpus, Domain, Entity, Authority, Temporal, Relational, Section, Content) are named generically. The consuming application populates these layers with domain-specific values. This is demonstrated in the companion document through three worked examples: a worldbuilding faction document, a REST API endpoint reference, and a federal regulatory filing — all using the same layer types with different values.

---

## 6. LLM Integration Architecture

### 6.1. Design Principle: Advisory, Never Authoritative

The most important architectural principle governing LLM integration in Chronicle is that **LLMs are advisory, never authoritative**. They suggest, analyze, and draft — but they never make changes to the canonical record without explicit human approval. The deterministic validation layer (Section 4.5) is what actually enforces canon integrity. The LLM layer provides *insights* that help the human make better decisions, but it does not make decisions itself.

This principle exists for two reasons. First, LLMs produce plausible-sounding but sometimes incorrect output (hallucination), and a worldbuilding tool that silently introduces hallucinated "facts" into a canonical record would be worse than useless — it would actively undermine the trust that the entire system is built to provide. Second, creative decisions about a fictional world should remain with the human author. The LLM can identify gaps and suggest possibilities, but the author decides what's true in their world.

In practical terms, this means that every LLM-powered feature produces a **report** (a Markdown file) rather than making direct changes to lore files. The human reviews the report and takes action (or doesn't) based on its contents. The only exception is stub generation (Section 6.6), which creates new files — but those files are always created with `canon: false` and are clearly marked as machine-generated, requiring explicit human review before they can be promoted to canonical status.

### 6.2. Semantic Contradiction Detection

The deterministic linter catches *structural* contradictions (broken references, date mismatches, schema violations). But it cannot catch *semantic* contradictions that live in prose. This is where the LLM becomes invaluable.

The workflow: the user runs `chronicle validate --deep`. Chronicle identifies clusters of related documents (by shared tags, relationships, or entity references) and sends pairs or clusters to the local LLM with a system prompt that says, essentially, "You are a continuity editor. Identify any assertions in Document B that appear to contradict assertions in Document A. Cite specific passages. If no contradictions exist, say so." The results are written to a Markdown validation report.

Example contradiction the LLM might catch: Document A states "The Iron Covenant never practiced magic; they viewed it as an abomination." Document B, written months later, describes an Iron Covenant ritual involving arcane channeling. No keyword overlap flags this — it's a semantic tension that only a language model (or a very attentive human reader) would catch.

### 6.3. Semantic Search via FractalRecall

Chronicle's `search` command delegates to FractalRecall for semantic retrieval. Chronicle's role is to construct the context-enriched query (adding layer constraints based on the user's flags, like `--canon-only` or `--era "Third Age"`) and then interpret the results (displaying source file paths, structural metadata, relevance scores, and optionally the layer score breakdown from FractalRecall).

This is described in detail in the FractalRecall companion document (Sections 5.2 and 5.3 on data flow).

### 6.4. Merge Conflict Narrative Resolution

When a branch is being merged into `main`, Chronicle's LLM layer can analyze the incoming changes against the existing canon to detect **cross-file contradictions** that Git's merge mechanism wouldn't catch. Git detects conflicts when two branches modify the *same file*. Chronicle detects conflicts when two branches modify *different files* in contradictory ways — for example, one branch establishes that a city was destroyed, and another branch (developed concurrently) describes that city as thriving.

The LLM produces a report identifying the conflicting assertions, citing the specific documents and passages, and presenting the options for resolution. It does not attempt to resolve the conflict itself.

### 6.5. Lore Expansion Suggestions

Chronicle can analyze the entity relationship graph — the web of factions, characters, locations, events, and their interconnections — and identify **gaps or opportunities** in the worldbuilding. This combines deterministic graph analysis (which is cheap and precise) with LLM interpretation (which adds narrative framing).

The graph analysis identifies factual patterns: "Region X has only one faction while similar regions have three to five." "Character Y is referenced in nine documents but has no dedicated file." "Trade routes are defined for western provinces but not eastern provinces, despite eastern port cities being established." The LLM interprets these patterns and suggests narrative possibilities: "Consider whether Region X is intentionally isolated, or whether missing factions represent an oversight." "Character Y appears to be important enough to warrant a full character document."

The output is a Markdown suggestion report. The human decides which suggestions (if any) to act on.

### 6.6. Draft Stub Generation

When Chronicle identifies a referenced-but-undefined entity (e.g., a character mentioned in multiple documents who doesn't have their own character file), it can generate a **stub document** with YAML frontmatter pre-populated from existing references and body text drafted by the LLM based on those references.

The stub is always created with `canon: false` and includes a metadata marker indicating it was machine-generated. It lives on a working branch and requires explicit human review, revision, and approval before it can be promoted to canonical status. The human might use 80% of the generated stub and rewrite the rest, or they might discard it entirely and write from scratch. The stub is a starting point, not a finished product.

### 6.7. Local LLM Infrastructure

All LLM features are designed to work with **local inference** via Ollama or LM Studio. This is architecturally important for three reasons. First, worldbuilding content is personal creative work, and many worldbuilders are (rightly) reluctant to send their unpublished lore to cloud APIs. Local inference keeps everything on the user's machine. Second, the author's hardware (Mac Studio M3 Ultra with 512GB RAM) is exceptionally well-suited for local LLM inference, making this a practical choice rather than a compromise. Third, local inference eliminates per-query API costs, which matters for operations like deep validation that may send dozens of document pairs to the model in a single run.

Chronicle's LLM integration uses an abstracted provider interface (similar to FractalRecall's `IEmbeddingProvider`), so cloud API providers can be used as an alternative if the user prefers or if their hardware doesn't support local inference.

For embedding generation specifically, the recommended local model is `nomic-embed-text` (via Ollama), which produces 768-dimensional embeddings and supports inputs up to 8,192 tokens — sufficient for context-enriched composite representations.

For text generation (contradiction detection, stub generation, suggestions), the recommended local models are in the Llama, Mistral, or Qwen families at 7B-70B parameter scales, depending on the user's hardware. The Mac Studio M3 Ultra with 512GB RAM can comfortably run 70B+ parameter models, which provide excellent results for these analytical and creative tasks.

---

## 7. Concurrent Development Strategy

### 7.1. Why Concurrent, Not Sequential

Building FractalRecall in isolation, publishing it, and then starting Chronicle would risk building a library API that doesn't fit its primary consumer's needs. Library APIs designed in a vacuum tend to miss the real-world requirements that only emerge when you build an actual application on top of them. The result is either a frustrating integration experience or an API rewrite after the fact.

Conversely, building Chronicle first and extracting FractalRecall later would produce a library that's too tightly shaped by Chronicle's specific needs, potentially limiting its usefulness for other domains.

The better approach is **concurrent development, with Chronicle as the primary integration target** that drives FractalRecall's API design. The projects develop side by side, and the direction of influence is clear: Chronicle's needs inform FractalRecall's interface, not the other way around.

### 7.2. Direction of Influence: Chronicle Drives FractalRecall's API

When building Chronicle's semantic search feature, the developer discovers what FractalRecall's query API needs to look like. When building Chronicle's contradiction detection feature, the developer discovers what kinds of structural metadata the embedding library needs to accept. When building Chronicle's incremental indexing feature, the developer discovers what cache invalidation mechanisms the library needs to support.

Chronicle is the **laboratory** where real-world requirements are discovered. FractalRecall is the **distilled, generalized knowledge** that comes out of those discoveries.

### 7.3. The Extract and Generalize Pattern

This development pattern is sometimes called "extract and generalize." You build the specific thing (Chronicle's retrieval features) and as you do, you identify which parts are domain-agnostic and extract them into a reusable library (FractalRecall). The library's API is *discovered through use*, not designed in a vacuum.

At every decision point during development, the question is: "Is this piece of logic specific to worldbuilding, or is it general-purpose retrieval intelligence?" If it's worldbuilding-specific, it stays in Chronicle. If it's general-purpose, it goes in FractalRecall. The boundary between the two projects is defined by this question, asked repeatedly.

### 7.4. Repository and Package Structure

**Repository 1: `FractalRecall`**

A .NET class library solution, published as a NuGet package. Contains no worldbuilding concepts. The solution structure would include the core library project (`FractalRecall`), reference implementations for common embedding providers (`FractalRecall.Providers.Ollama`, `FractalRecall.Providers.OpenAI`), reference implementations for common index backends (`FractalRecall.Index.Sqlite`, `FractalRecall.Index.InMemory`), a test project (`FractalRecall.Tests`), and the Colab notebooks (in a `notebooks/` directory) that serve as executable research documentation.

**Repository 2: `Chronicle`**

A .NET CLI application solution that depends on FractalRecall as a NuGet package reference. Contains all worldbuilding-specific logic. The solution structure would include the CLI application project (`Chronicle.Cli`), the core domain library (`Chronicle.Core`, containing the entity model, schema validation, canon workflow, Git integration), the FractalRecall integration layer (`Chronicle.Search`, which constructs context layers from Chronicle's domain model and delegates to FractalRecall), a test project (`Chronicle.Tests`), and documentation (the specification documents, schema definitions, and user guides).

---

## 8. Development Phases

### 8.1. Phase 0: Google Colab Prototyping (FractalRecall Validation)

**Goal:** Empirically validate that FractalRecall's multi-layer embedding enrichment technique actually improves retrieval quality compared to standard RAG and single-layer enrichment.

**Why Python:** The ML and embedding ecosystem in Python is substantially more mature than .NET. Libraries like `sentence-transformers`, `numpy`, `chromadb`, and `scikit-learn` enable rapid prototyping without fighting tooling friction. The Colab notebooks are not throwaway work — they become permanent documentation of the research findings that inform the C# implementation.

**Deliverables:** Six Colab notebooks (detailed in the companion FractalRecall document, Section 10.2): (1) Baseline establishment with standard RAG, (2) Single-layer enrichment replicating Anthropic's Contextual Retrieval, (3) Multi-layer enrichment testing the FractalRecall core hypothesis, (4) Layer ablation study to determine which layers matter most, (5) Embedding strategy comparison across the three candidate approaches, (6) Cross-domain validation on a non-worldbuilding corpus.

**Test Corpus:** A subset of the Aethelgard lore files, containing at least 50 documents spanning multiple entity types, authority levels, eras, and with established cross-references. A secondary corpus from a different domain (recommended: technical documentation) for Notebook 6.

**Exit Criteria:** Phase 0 is complete when the prototyping results demonstrate a statistically meaningful improvement from multi-layer enrichment, the layer configuration is stabilized, the embedding strategy is selected, and the findings are documented in a "Prototyping Findings" summary document.

**Risk Acknowledgment:** It is possible that multi-layer enrichment does not meaningfully improve over simpler approaches. This is a valid outcome, and discovering it during Phase 0 (before significant C# implementation effort) is exactly the purpose of prototyping. If this occurs, the project scope would be reconsidered — possibly simplifying FractalRecall to a thin wrapper over Anthropic-style single-layer enrichment, or pivoting to a different retrieval strategy entirely.

### 8.2. Phase 1: Documentation (Both Projects)

**Goal:** Write all specification documents that must exist before code is written. This is the docs-first phase.

**FractalRecall Deliverables:**
- Conceptual Architecture Document ✅ **(completed — see companion document)**
- API Design Specification (refined from the conceptual API sketch based on Phase 0 findings)
- Prototyping Findings Document (summarizing Colab results)

**Chronicle Deliverables:**
- This Design Proposal Document ✅ **(this document)**
- Lore File Schema Specification (the formal definition of valid YAML frontmatter per entity type)
- Canon Workflow Specification (the rules governing content lifecycle and promotion)
- Validation Rule Catalog (every deterministic check, documented as testable behaviors)
- LLM Integration Specification (prompt templates, response parsing, report formats)
- CLI Command Reference (every command with usage examples and expected output)
- Integration Design Document (how Chronicle consumes FractalRecall's API)

### 8.3. Phase 2: Foundational Implementation (Both Projects)

**Goal:** Implement the core components of both projects that do not require LLM integration.

**FractalRecall:** Core abstractions (`ContextLayer`, `CompositeRepresentationBuilder`, `IEmbeddingProvider` interface, `IFractalIndex` interface), reference implementations (Ollama embedding provider, SQLite index backend, in-memory index for testing), and comprehensive unit tests.

**Chronicle:** Markdown+YAML parser, directory scanner, frontmatter schema validator, entity graph builder (constructing the relationship graph from frontmatter links), deterministic validation engine (all rule-based checks from Section 4.5), and comprehensive unit tests.

At the end of Phase 2, Chronicle can scan a repository and produce a deterministic validation report, and FractalRecall can construct and store composite embeddings. They haven't been connected yet.

### 8.4. Phase 3: Integration (Connecting Chronicle to FractalRecall)

**Goal:** Wire Chronicle's entity model into FractalRecall's context layer system and implement semantic search.

**Key Work:** Chronicle's `index` and `search` commands are implemented. Chronicle extracts structural metadata from lore files and constructs FractalRecall context layers. The FractalRecall query pipeline is integrated with Chronicle's CLI search experience. The evaluation framework (from the FractalRecall companion document, Section 11) is run against the Aethelgard corpus to validate retrieval quality in the integrated system.

At the end of Phase 3, a worldbuilder can run `chronicle search "What factions have a presence in the northern territories?"` and get structurally-aware, semantically-relevant results.

### 8.5. Phase 4: LLM-Powered Features (Chronicle)

**Goal:** Implement the advisory LLM features described in Section 6: deep semantic contradiction detection, merge conflict narrative resolution, lore expansion suggestions, and draft stub generation.

These features consume the FractalRecall retrieval system (they need to find relevant context before they can reason about it) and layer additional LLM-powered analysis on top. Each feature produces a Markdown report for human review, following the "advisory, never authoritative" principle.

---

## 9. Technology Stack

### 9.1. C# / .NET (Production)

Both projects target **.NET 8+** (or the latest LTS version available at implementation time). The CLI framework for Chronicle is **System.CommandLine** or **Spectre.Console.Cli**. The YAML parsing library is **YamlDotNet**. The Markdown parsing library is **Markdig**. The Git integration library is **LibGit2Sharp**. Unit testing uses **xUnit** with **FluentAssertions**.

### 9.2. Python / Google Colab (Prototyping)

Phase 0 uses Python in Google Colab with the following libraries: `sentence-transformers` (embedding generation), `chromadb` (vector storage), `numpy` and `scikit-learn` (vector operations and evaluation metrics), `matplotlib` and `seaborn` (visualization), and `pyyaml` (YAML frontmatter parsing for the test corpus).

### 9.3. Embedding Models

The recommended local embedding model is `nomic-embed-text` (768 dimensions, 8192 token context window), available through Ollama. This model supports Matryoshka-style variable-dimension embeddings and is well-suited for context-enriched inputs. Alternative models to test during Phase 0 include `all-MiniLM-L6-v2` (384 dimensions, 256 token window — smaller and faster but less capable with long enriched inputs) and `mxbai-embed-large` (1024 dimensions, 512 token window).

### 9.4. Vector Storage

The recommended production storage backend is **SQLite with a vector extension** (`sqlite-vec` or `sqlite-vss`). This keeps the embedding index as a single portable file within the Chronicle repository (`.chronicle/index/fractal.db`) with no external service dependencies. For higher-performance use cases, **Qdrant** (a dedicated vector database) is a supported alternative via FractalRecall's pluggable index backend.

### 9.5. LLM Inference

Local inference via **Ollama** or **LM Studio** is the primary target. The LLM provider interface is abstracted, so cloud APIs (OpenAI-compatible, Anthropic, etc.) can be used as alternatives. The recommended local models for text generation are in the 7B-70B parameter range from the Llama, Mistral, or Qwen families. The author's Mac Studio M3 Ultra (512GB RAM) can comfortably run 70B+ models.

---

## 10. Broader Applications Beyond Worldbuilding

While Chronicle is designed for worldbuilding, its architecture is applicable to several adjacent domains, and this potential should be kept in mind during design to avoid unnecessarily limiting the tool's future scope.

**Collaborative Fiction Projects:** Writing rooms, shared universes, and anthology series have the same canon management problem at a larger scale. Multiple authors contributing to a shared universe need branching, review, validation, and changelog generation.

**Game Development Studios:** Game studios maintain "lore bibles" that frequently fall out of sync with shipped content. Chronicle could serve as the canonical source of truth for a game's narrative content, with validation checks that run in CI/CD alongside code builds.

**Tabletop RPG Publishers:** Publishers producing campaign settings across multiple sourcebooks and editions face massive continuity management challenges. Chronicle's architecture could track lore evolution across publications.

**Technical Documentation Teams:** Large documentation corpora have cross-references, versioning, deprecation, and consistency requirements that are structurally identical to worldbuilding lore management. Chronicle's architecture could be adapted into a documentation quality tool — connecting directly to the author's professional identity as a technical writer.

FractalRecall's domain-agnostic design already supports all of these use cases at the retrieval layer. The question of whether Chronicle itself should be generalized (or whether a separate tool should be built for each domain using the same architectural patterns) is an open question for the future.

---

## 11. Portfolio and Open-Source Strategy

### 11.1. Two Entry Points for Discovery

The two-project structure creates two distinct entry points for discovery. A .NET developer interested in AI retrieval techniques finds FractalRecall and sees "used by Chronicle" as an example consumer. A worldbuilder or RPG designer finds Chronicle and sees FractalRecall as a dependency. Each project drives discovery of the other, but each stands on its own merits independently.

### 11.2. Portfolio Narrative

For the author's job-hunting portfolio, the two projects tell a complementary story. FractalRecall demonstrates competence in AI/ML integration, library architecture, NuGet package design, interface-driven development, and empirical evaluation methodology. Chronicle demonstrates competence in CLI tool development, domain modeling, Git integration, validation engine design, documentation-first development practices, and practical LLM application architecture. Together, they demonstrate the ability to decompose a complex system into well-bounded, well-documented components — a skill that is directly relevant to the author's identity as a technical writer and C#/.NET developer.

### 11.3. Licensing Considerations

Both projects should use a permissive open-source license (MIT or Apache 2.0 recommended) to maximize adoption and contribution potential. The choice between MIT and Apache 2.0 has minor implications for patent protection (Apache 2.0 includes an explicit patent grant), but for projects at this scale, either is appropriate. The decision should be made before first public release and documented in each repository's `LICENSE` file.

---

## 12. Documents Roadmap: What Needs to Be Written

### 12.1. Completed Documents

| Document | Project | Status | Description |
|----------|---------|--------|-------------|
| Unified Design Proposal | Both | ✅ Draft Complete | This document. Captures the full design context for both projects. |
| FractalRecall Conceptual Architecture | FractalRecall | ✅ Draft Complete | Detailed technical spec: problem statement, research foundations, layers, embedding strategies, API design, eval framework, Colab plan. |

### 12.2. Phase 1 Documents (Pre-Implementation)

| Document | Project | Status | Description |
|----------|---------|--------|-------------|
| Lore File Schema Specification | Chronicle | ❌ Not Started | Formal definition of valid YAML frontmatter per entity type. Defines required/optional fields, data types, and validation rules. |
| Canon Workflow Specification | Chronicle | ❌ Not Started | Rules governing content lifecycle: draft → canonical, deprecation, apocryphal branching, merge validation. |
| Validation Rule Catalog | Chronicle | ❌ Not Started | Every deterministic check documented as a testable behavior with examples of passing and failing cases. |
| LLM Integration Specification | Chronicle | ❌ Not Started | Prompt templates for each LLM feature, expected response formats, report output schemas. |
| CLI Command Reference | Chronicle | ❌ Not Started | Every CLI command with syntax, flags, usage examples, and expected output. |
| Integration Design Document | Chronicle | ❌ Not Started | How Chronicle consumes FractalRecall's API. Defines which layers Chronicle constructs and how. |
| FractalRecall API Design Spec | FractalRecall | ❌ Not Started | Refined API specification based on Phase 0 prototyping findings. Extends the conceptual sketch in the architecture doc. |
| Prototyping Findings Document | FractalRecall | ❌ Not Started | Summary of Colab experiment results, conclusions, and design implications. |

### 12.3. Phase 2+ Documents (During Implementation)

| Document | Project | Status | Description |
|----------|---------|--------|-------------|
| FractalRecall README | FractalRecall | ❌ Not Started | NuGet package README with quick-start example. |
| FractalRecall Contributing Guide | FractalRecall | ❌ Not Started | How to contribute: setup, coding standards, PR process, testing requirements. |
| Chronicle README | Chronicle | ❌ Not Started | Repository README with installation, quick-start, and feature overview. |
| Chronicle Contributing Guide | Chronicle | ❌ Not Started | How to contribute: setup, coding standards, PR process, testing requirements. |
| Chronicle User Guide | Chronicle | ❌ Not Started | End-user documentation: setting up a lore repository, writing valid lore files, using CLI commands. |

---

## 13. Key Design Decisions and Rationale

This section documents the major design decisions made during the initial brainstorming session, along with the reasoning behind each one. Future sessions should treat these as established decisions unless there is a compelling reason to revisit them.

**Decision 1: Two separate repositories and NuGet packages, not a monolith.**
Rationale: Reusability of FractalRecall across domains, separation of concerns, independent portfolio value, independent evolution. See Section 2.3 for full reasoning.

**Decision 2: Concurrent development with Chronicle driving FractalRecall's API.**
Rationale: Avoids the "library designed in a vacuum" problem. Chronicle provides real-world pressure that shapes FractalRecall's interface. See Section 7 for full reasoning.

**Decision 3: Python prototyping (Colab) before C# implementation for FractalRecall.**
Rationale: The Python ML ecosystem is dramatically more mature for embedding experimentation. Prototyping validates the technique before investing in production implementation. The notebooks become permanent research documentation. See FractalRecall companion document, Section 10 for full reasoning.

**Decision 4: LLMs are advisory, never authoritative.**
Rationale: LLMs hallucinate, and a tool that silently introduces hallucinated facts into canonical records would undermine the trust the system is designed to provide. Creative decisions belong to the human author. See Section 6.1 for full reasoning.

**Decision 5: Deterministic validation is separate from LLM-powered validation.**
Rationale: Deterministic checks (schema, cross-references, timeline) are fast, trustworthy, and sufficient for most day-to-day use. LLM-powered checks (semantic contradiction detection) are slower, more expensive, and occasionally wrong — they should be opt-in via `--deep` flag. Separating them ensures the baseline tool is usable without any LLM infrastructure.

**Decision 6: Local LLM inference is the primary target, not cloud APIs.**
Rationale: Worldbuilding content is personal creative work. Local inference keeps lore private. The author's hardware (Mac Studio M3 Ultra, 512GB RAM) makes this practical. Local inference eliminates per-query costs for bulk operations. Cloud APIs are supported as an alternative via abstracted provider interfaces.

**Decision 7: YAML frontmatter in Markdown files, not a database.**
Rationale: Markdown+YAML is human-readable, version-controllable (Git diffs are meaningful), editable with any text editor, and doesn't require specialized tooling to view or modify. A database would be faster for queries but would be opaque in version control, harder to edit manually, and create a dependency on specific database software. The trade-off favors human-readability and simplicity for the expected corpus sizes (hundreds to low thousands of documents).

**Decision 8: Git as the underlying version control system, not a custom solution.**
Rationale: Git is ubiquitous, well-understood, and provides proven branching, merging, and history capabilities. Building custom version control would be a massive, unnecessary engineering effort. Chronicle extends Git with domain-specific semantics rather than replacing it.

**Decision 9: The FractalRecall embedding index is a derived artifact (`.gitignore`'d).**
Rationale: The index can be regenerated from the source files at any time. Storing it in Git would bloat the repository with binary data that changes frequently. Treating it as a build artifact (generated by `chronicle index`) keeps the repository clean.

**Decision 10: FractalRecall provides three embedding strategies (Prefix, Multi-Vector, Hybrid) behind a pluggable architecture.**
Rationale: Different use cases have different trade-offs between simplicity, precision, and storage efficiency. Rather than choosing one strategy and locking all consumers into it, the library supports multiple strategies and lets the consumer choose. The Colab prototyping phase determines the recommended default.

---

## 14. Open Questions

The following questions remain unresolved and should be addressed during prototyping or early implementation.

**OQ-1: How should Chronicle handle entities that span multiple files?** A faction might have a main overview document plus separate documents for its military structure, its history, its key members, and its territories. Should these be separate lore entries (each with their own frontmatter and entity identity) or child documents of a parent entity? The answer affects how FractalRecall constructs the Entity context layer.

**OQ-2: Should Chronicle support custom entity types from day one, or start with a fixed set?** Starting with a fixed set (faction, character, location, event, timeline, system) is simpler but limits the tool to the author's specific needs. Supporting custom types from the start is more work but makes the tool immediately useful for other worldbuilding traditions (sci-fi, historical fiction, etc.).

**OQ-3: How should the relationship `type` field be constrained?** Should Chronicle define a fixed vocabulary of relationship types (founded_by, rivalry, located_in, participated_in, etc.) or allow free-form relationship types? A fixed vocabulary enables stronger validation; free-form enables flexibility.

**OQ-4: What is the right chunking strategy for worldbuilding Markdown documents?** Heading-based chunking (each section becomes a chunk) preserves document structure but may produce very uneven chunk sizes. Fixed-size window chunking produces uniform sizes but breaks document structure. Hybrid approaches (heading-based with a maximum chunk size and overflow splitting) are more complex but may be optimal. This should be tested during Phase 0.

**OQ-5: Should Chronicle validate the *prose content* of lore files (e.g., checking that the body text is consistent with the frontmatter metadata), or only the frontmatter?** Prose validation is where LLM integration becomes most valuable, but it also raises the bar for what the tool is expected to catch. The answer affects user expectations and the scope of the `--deep` validation flag.

**OQ-6: What is the migration path for existing Aethelgard content?** The author has an existing Notion-based worldbuilding project. How does that content get migrated into a Chronicle-managed Git repository? Is there an import tool, or is it a manual process? This affects onboarding experience for the first (and most important) user.

**OQ-7: All open questions from the FractalRecall companion document (Section 14)** also apply. These cover layer ordering, relationship rendering format, versioned corpora handling, minimum corpus size thresholds, multi-language support, and Late Chunking interaction.

---

## 15. Glossary

**Apocryphal:** Content that is explicitly non-canonical — "what if" explorations, alternate timelines, or creative experiments preserved in the repository but never intended as established truth.

**Canon:** The official, established state of a fictional world. In Chronicle, canonical content lives on the `main` branch and has passed all validation checks.

**Chronicle:** The C# CLI tool for version-controlled worldbuilding. The domain-specific application that consumes FractalRecall.

**Composite Representation:** The assembled collection of context layers for a chunk, including raw content and all structural context. The "DNA strand" in FractalRecall's terminology.

**Context Layer:** A single level of structural metadata (e.g., authority status, entity type, temporal position) associated with a text chunk in FractalRecall.

**Deterministic Validation:** Rule-based checks that require no AI: schema validation, cross-reference integrity, timeline consistency, uniqueness constraints. Fast, trustworthy, always consistent.

**Embedding:** A vector (array of numbers) representation of text that captures semantic meaning. Texts about similar topics produce vectors that are close together in the embedding space.

**Entity:** A discrete "thing" in the worldbuilding corpus: a faction, a character, a location, an event, etc. Each entity has a dedicated Markdown file with YAML frontmatter.

**FractalRecall:** The .NET class library for hierarchical context-aware retrieval. The domain-agnostic library that Chronicle depends on.

**Frontmatter:** The YAML metadata block at the top of a Markdown file (between `---` delimiters) that provides structured, machine-readable information about the document.

**Lore Entry:** A single Markdown file in a Chronicle-managed repository, representing one entity or concept in the worldbuilding corpus.

**RAG (Retrieval-Augmented Generation):** A technique where an LLM's responses are grounded in retrieved information from an external knowledge base, rather than relying solely on training data.

**Semantic Validation:** LLM-powered checks that detect contradictions, tensions, and inconsistencies in prose content that deterministic rules cannot catch. Opt-in via `--deep` flag.

**Structural Fingerprint:** A hash of a chunk's non-content context layers, used for change detection and cache invalidation in FractalRecall.

---

## 16. Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1.0-draft | 2026-02-09 | Ryan | Initial draft capturing complete design context from brainstorming session. Covers Chronicle design, FractalRecall summary, LLM integration, development strategy, technology stack, open questions. |

---

*This document is a living specification and the authoritative reference for both projects' design intent. It should be updated as decisions are made, prototyping results come in, and implementation proceeds. Any future AI session working on these projects should read this document and the companion FractalRecall Conceptual Architecture document before beginning work.*
