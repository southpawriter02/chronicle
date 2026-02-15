# Chronicle + FractalRecall: Session Bootstrap Context

**Last Updated:** 2026-02-09  
**Session Origin:** Extended design and architecture brainstorming session  
**Primary Documents Produced:** Two comprehensive Markdown specifications (see Section 7)

---

## 1. What These Projects Are

We are designing and building two concurrent, related open-source projects in C#/.NET.

**Chronicle** is a CLI tool that treats worldbuilding lore like a software codebase. It layers on top of Git to add domain-specific intelligence: canon status management, YAML frontmatter validation, cross-reference integrity checking, timeline consistency enforcement, semantic search, and LLM-powered advisory features (contradiction detection, lore gap analysis, draft stub generation). The first integration target is Ryan's own worldbuilding project, Aethelgard — a post-apocalyptic fantasy TTRPG setting at version 5.0, currently maintained in Notion. The fundamental insight driving Chronicle is that worldbuilding has the exact same structural challenges as software development (versioning, consistency, collaboration, review, quality assurance) and deserves the same caliber of tooling.

**FractalRecall** is a .NET class library (to be distributed as a NuGet package) that improves embedding-based retrieval by encoding hierarchical structural context into the embedding representation. Where standard RAG treats every text chunk as a context-free fragment, FractalRecall ensures each chunk carries its full "structural DNA" — a layered set of metadata encoding corpus identity, entity type, authority status, temporal position, relationships, section context, and more. It is domain-agnostic by design: Chronicle is the first consumer, but the library works for technical documentation, legal corpora, medical knowledge bases, or any domain where content has meaningful structure beyond raw semantics. The name reflects the core insight that well-organized knowledge bases have meaningful structure at every level of granularity, like a fractal.

These are **separate repositories and separate NuGet packages**, not a monolith. Chronicle depends on FractalRecall as a package reference. FractalRecall knows nothing about worldbuilding. This separation exists for reusability (FractalRecall is useful beyond worldbuilding), separation of concerns, independent portfolio value (Ryan is actively job-hunting as a technical writer and C#/.NET developer), and independent evolution.

---

## 2. Key Architecture Decisions (Settled)

The following decisions were made during the design session and should be treated as established unless there's a compelling reason to revisit them.

**Two repos, not one.** FractalRecall is a general-purpose library; Chronicle is a domain-specific application. Coupling them would limit FractalRecall's adoption and produce a monolith that's harder to test and document.

**Concurrent development, with Chronicle driving FractalRecall's API.** Chronicle provides real-world pressure that shapes FractalRecall's interface. This follows the "extract and generalize" pattern: build the specific thing (Chronicle's retrieval needs), identify domain-agnostic parts, extract them to the library.

**Python prototyping (Google Colab) before C# implementation for FractalRecall.** The ML/embedding ecosystem in Python is years ahead of .NET. Six Colab notebooks will empirically validate whether multi-layer embedding enrichment actually improves retrieval quality before committing to C# production implementation. The notebooks become permanent research documentation, not throwaway work.

**LLMs are advisory, never authoritative.** LLM features produce Markdown reports for human review. They never modify canonical content directly. Deterministic validation (schema checks, cross-reference integrity, timeline consistency) is the authoritative enforcement layer. This prevents hallucinated "facts" from entering the canonical record.

**Deterministic validation is separate from LLM validation.** Basic checks run fast with no AI dependency via `chronicle validate`. LLM-powered semantic checks are opt-in via `chronicle validate --deep`. This ensures the tool is useful even without LLM infrastructure.

**Local LLM inference is the primary target.** Worldbuilding content is personal creative work that shouldn't be sent to cloud APIs by default. Ryan's Mac Studio M3 Ultra (512GB RAM) makes local inference practical. Cloud APIs are supported as alternatives via abstracted provider interfaces.

**YAML frontmatter in Markdown files, not a database.** Human-readable, version-controllable, editable with any text editor, no specialized tooling required. Git diffs are meaningful. The FractalRecall embedding index is a derived artifact (`.gitignore`'d), regenerable from source files via `chronicle index`.

**Git as the underlying VCS, not a custom solution.** Chronicle extends Git with domain semantics (canon branches, validation hooks, semantic changelogs) rather than replacing it.

---

## 3. Chronicle Design Summary

A Chronicle-managed worldbuilding project is a Git repository of Markdown files with YAML frontmatter, organized by entity type (`factions/`, `characters/`, `locations/`, `events/`, `timeline/`, `systems/`, `apocrypha/`). A `.chronicle/` directory holds configuration, schema definitions, and the embedding index.

**Canon Workflow:** Four statuses — canonical (`canon: true`, lives on `main`, passed all checks), draft (`canon: false`, working branch, not yet validated), apocryphal (`canon: "apocryphal"`, explicitly non-canonical "what if" content, never merged to canon), and deprecated (`canon: "deprecated"`, superseded by newer content, preserved for history with `superseded_by` reference). Promotion from draft to canonical requires branch → validate → merge workflow analogous to pull requests.

**Deterministic Validation:** Schema validation (frontmatter conforms to entity type requirements), cross-reference integrity (all relationship targets point to existing files), timeline consistency (dates/eras align across documents), uniqueness constraints (no duplicate claims for unique attributes), alias collision detection (overlapping alternative names), and canon status consistency (canonical docs shouldn't reference draft/apocryphal docs).

**LLM Features (All Advisory):** Semantic contradiction detection (sends related document clusters to local LLM, produces Markdown report of prose-level contradictions). Semantic search via FractalRecall (natural language queries with structural filtering by canon status, era, entity type). Merge conflict narrative resolution (detects cross-file contradictions during merges that Git can't catch). Lore expansion suggestions (graph analysis identifies sparse regions and structural gaps, LLM adds narrative framing). Draft stub generation (creates `canon: false` machine-generated files for referenced-but-undefined entities).

**Changelog Generation:** Auto-generated Markdown changelogs that combine Git diff information with semantic understanding of what the files *are*, producing entries like "Revised the founding date of The Iron Covenant from Year 415 to Year 412 of the Third Age" rather than just "Modified iron-covenant.md."

**Proposed CLI Commands:** `init`, `scan`, `validate` (with optional `--deep` for LLM checks), `search <query>` (with `--canon-only`, `--era`, `--type` flags), `changelog`, `index` (with `--incremental`), `graph` (Mermaid/DOT/JSON output), `suggest`, `stub <entity-path>`.

---

## 4. FractalRecall Design Summary

FractalRecall addresses three documented deficiencies in standard RAG: the semantic proximity trap (canonical and speculative content about the same topic produce identical embeddings), chunking amnesia (chunks lose structural context when extracted from documents), and authority blindness (all content is treated as equally authoritative regardless of editorial status).

**Core Mechanism — Context Layers:** A Context Layer is one level of structural metadata (e.g., authority status, entity type, temporal position). Layers are ordered from outermost (most general) to innermost (most specific, which is the raw content). A Composite Representation is the assembled collection of all layers for a chunk — the "DNA strand." Eight standard layer types ship with the library: Corpus (hierarchy 100), Domain (90), Entity (80), Authority (70), Temporal (60), Relational (50), Section (20), Content (0). Consuming applications can define custom layer types.

**Embedding Strategies Under Evaluation:** Three candidate approaches. Approach A (Prefix Enrichment) renders all layers as a text prefix and embeds as a single vector — simplest, recommended for prototyping. Approach B (Multi-Vector Composition) embeds each layer separately and combines scores at query time — most precise, most expensive. Approach C (Hybrid with Metadata Sidecar) embeds high-impact layers as prefixes, stores others as metadata for filtering — likely production recommendation. Colab prototyping will determine which performs best.

**Key Interfaces:** `IEmbeddingProvider` (abstraction over embedding model — Ollama, OpenAI, etc.), `IFractalIndex` (abstraction over vector storage — SQLite, Qdrant, in-memory for testing), `CompositeRepresentationBuilder` (fluent builder for assembling context layers), `FractalQueryBuilder` (constructs queries with layer-weighted constraints and metadata filters), `EvaluationHarness` (benchmarking tool for comparing retrieval strategies).

**Research Foundations:** The design synthesizes insights from Anthropic's Contextual Retrieval (2024), Matryoshka Representation Learning (2022), Microsoft GraphRAG (2024), RAPTOR (2024), and Jina AI's Late Chunking (2024). FractalRecall's novel contribution is unifying these approaches into a single, domain-agnostic, developer-friendly .NET library.

---

## 5. Development Phases

**Phase 0 — Google Colab Prototyping (FractalRecall Validation).** Six notebooks: (1) baseline standard RAG, (2) single-layer enrichment replicating Anthropic's approach, (3) multi-layer enrichment testing FractalRecall's core hypothesis, (4) layer ablation study (which layers matter most), (5) embedding strategy comparison across three approaches, (6) cross-domain validation on non-worldbuilding corpus. Exit criteria: statistically meaningful improvement demonstrated, layer configuration stabilized, embedding strategy selected, findings documented. Risk acknowledged: multi-layer may not beat single-layer, which is a valid outcome that saves implementation effort.

**Phase 1 — Documentation (Both Projects, No Code).** Docs-first methodology. Write all specification documents before any C# implementation. See Section 7 below for document status.

**Phase 2 — Foundational Implementation (Both Projects).** FractalRecall: core abstractions, reference implementations, unit tests. Chronicle: YAML parser, directory scanner, schema validator, entity graph builder, deterministic validation engine, unit tests. End state: Chronicle can validate a repo; FractalRecall can build/store embeddings. Not yet connected.

**Phase 3 — Integration.** Wire Chronicle's entity model into FractalRecall's context layers. Implement `chronicle index` and `chronicle search`. Run evaluation framework against Aethelgard corpus. End state: semantic search works end-to-end.

**Phase 4 — LLM-Powered Features.** Contradiction detection, merge conflict analysis, lore expansion suggestions, stub generation. All consume FractalRecall retrieval and add LLM reasoning. All produce advisory reports, not direct modifications.

---

## 6. Technology Stack

**Production:** C# / .NET 8+. System.CommandLine or Spectre.Console.Cli for CLI. YamlDotNet for YAML. Markdig for Markdown. LibGit2Sharp for Git. xUnit + FluentAssertions for testing.

**Prototyping:** Python / Google Colab. sentence-transformers, chromadb, numpy, scikit-learn, matplotlib, seaborn, pyyaml.

**Embedding Models:** Primary recommendation: `nomic-embed-text` (768 dims, 8192 token window, via Ollama). Alternatives to test: `all-MiniLM-L6-v2`, `mxbai-embed-large`.

**Vector Storage:** SQLite with vector extension (`sqlite-vec` or `sqlite-vss`) for production. Qdrant as a supported alternative via pluggable backend.

**LLM Inference:** Local via Ollama or LM Studio (primary). Cloud APIs supported via abstracted provider. Recommended local models: Llama/Mistral/Qwen families, 7B-70B scale. Ryan's Mac Studio M3 Ultra (512GB RAM) can run 70B+ comfortably.

---

## 7. Documents Produced and Remaining

**Completed:**

| Document | ~Length | Purpose |
|----------|---------|---------|
| `Chronicle-FractalRecall-Design-Proposal.md` | ~8,500 words | Unified design proposal covering both projects, all architecture decisions, Chronicle's full design, LLM integration, development strategy, tech stack, open questions. The "single source of truth" for project intent. |
| `FractalRecall-Conceptual-Architecture.md` | ~7,000 words | Deep technical spec for FractalRecall: problem statement with research citations, research foundations (6 prior works), core concepts, architecture components, layer specification with 3 cross-domain worked examples, 3 embedding strategies with comparison table, 15 user stories with acceptance criteria, conceptual C# API design, 6-notebook Colab prototyping plan, evaluation framework with metrics and protocol, risk register, glossary, open questions. |

**Not Yet Started (Phase 1 Backlog):** Lore File Schema Specification, Canon Workflow Specification, Validation Rule Catalog, LLM Integration Specification, CLI Command Reference, Integration Design Document (Chronicle→FractalRecall), FractalRecall API Design Spec (refined post-Colab), Prototyping Findings Document.

---

## 8. Open Questions to Be Aware Of

Key unresolved questions that may come up in future sessions: How should Chronicle handle entities spanning multiple files (parent/child documents vs. separate entities)? Should custom entity types be supported from day one or start with a fixed set? Should relationship types use a fixed vocabulary or allow free-form? What chunking strategy works best for worldbuilding Markdown (heading-based, fixed-window, hybrid)? What's the migration path from the existing Notion-based Aethelgard content? Does the optimal layer ordering in embedded text go outermost-first or innermost-first? Should relationship metadata be rendered as natural language or structured tokens for embedding? What is the minimum corpus size where FractalRecall provides meaningful improvement?

---

## 9. Ryan's Context

Ryan is a technical writer and C#/.NET developer who is actively job-hunting. He's building these as open-source GitHub portfolio projects. He has a Mac Studio M3 Ultra with 512GB RAM (ideal for local LLM inference). He prefers C# and Markdown, follows a docs-first methodology, and values extensive documentation (inline comments, specs, design docs, user stories, unit tests). He has deep expertise in his Aethelgard worldbuilding setting, which provides both the motivating use case and the ground-truth evaluation corpus. He is not a Python developer by nature but recognizes the practical advantage of Colab for ML prototyping.
