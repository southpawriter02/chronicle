# D-14: LLM Integration Specification

**Document ID:** D-14
**Version:** 0.1.0-draft
**Status:** Draft
**Author:** Ryan (with specification guidance from Claude)
**Created:** 2026-02-10
**Last Updated:** 2026-02-10
**Dependencies:** D-01 (§6 — LLM Integration Architecture), D-12 (§7 — Tier 3 Semantic Validation, §9 — Assertion Rule Types), D-13 (§5.3 `validate --deep`, §7.1 `suggest`, §7.2 `stub`)
**Downstream Consumers:** D-13 (Phase 4 command finalization), Phase 4 implementation

---

## Table of Contents

- [1. Document Purpose and Scope](#1-document-purpose-and-scope)
- [2. Conventions and Terminology](#2-conventions-and-terminology)
- [3. Architectural Principles](#3-architectural-principles)
  - [3.1. Advisory, Never Authoritative](#31-advisory-never-authoritative)
  - [3.2. LLM Provider Abstraction](#32-llm-provider-abstraction)
  - [3.3. Deterministic-First Pipeline](#33-deterministic-first-pipeline)
  - [3.4. Report-Oriented Output](#34-report-oriented-output)
  - [3.5. Graceful Degradation](#35-graceful-degradation)
- [4. LLM Provider Interface](#4-llm-provider-interface)
  - [4.1. Provider Configuration](#41-provider-configuration)
  - [4.2. `ILlmProvider` Interface Contract](#42-illmprovider-interface-contract)
  - [4.3. Request and Response Types](#43-request-and-response-types)
  - [4.4. Supported Providers](#44-supported-providers)
  - [4.5. Provider Selection and Fallback](#45-provider-selection-and-fallback)
- [5. Feature 1: Semantic Contradiction Detection (`validate --deep`)](#5-feature-1-semantic-contradiction-detection-validate---deep)
  - [5.1. Purpose and Scope](#51-purpose-and-scope)
  - [5.2. Document Clustering Strategy](#52-document-clustering-strategy)
  - [5.3. System Prompt Template](#53-system-prompt-template)
  - [5.4. User Prompt Template](#54-user-prompt-template)
  - [5.5. Expected Response Schema](#55-expected-response-schema)
  - [5.6. Response Parsing Logic](#56-response-parsing-logic)
  - [5.7. Report Output Format](#57-report-output-format)
  - [5.8. Error Handling](#58-error-handling)
  - [5.9. Performance Characteristics](#59-performance-characteristics)
- [6. Feature 2: Merge Conflict Narrative Resolution](#6-feature-2-merge-conflict-narrative-resolution)
  - [6.1. Purpose and Scope](#61-purpose-and-scope)
  - [6.2. Change Detection Strategy](#62-change-detection-strategy)
  - [6.3. System Prompt Template](#63-system-prompt-template)
  - [6.4. User Prompt Template](#64-user-prompt-template)
  - [6.5. Expected Response Schema](#65-expected-response-schema)
  - [6.6. Response Parsing Logic](#66-response-parsing-logic)
  - [6.7. Report Output Format](#67-report-output-format)
  - [6.8. Error Handling](#68-error-handling)
  - [6.9. Performance Characteristics](#69-performance-characteristics)
- [7. Feature 3: Lore Expansion Suggestions (`chronicle suggest`)](#7-feature-3-lore-expansion-suggestions-chronicle-suggest)
  - [7.1. Purpose and Scope](#71-purpose-and-scope)
  - [7.2. Deterministic Gap Analysis (Pre-LLM)](#72-deterministic-gap-analysis-pre-llm)
  - [7.3. System Prompt Template](#73-system-prompt-template)
  - [7.4. User Prompt Template](#74-user-prompt-template)
  - [7.5. Expected Response Schema](#75-expected-response-schema)
  - [7.6. Response Parsing Logic](#76-response-parsing-logic)
  - [7.7. Report Output Format](#77-report-output-format)
  - [7.8. Error Handling](#78-error-handling)
  - [7.9. Performance Characteristics](#79-performance-characteristics)
- [8. Feature 4: Draft Stub Generation (`chronicle stub`)](#8-feature-4-draft-stub-generation-chronicle-stub)
  - [8.1. Purpose and Scope](#81-purpose-and-scope)
  - [8.2. Reference Extraction Strategy](#82-reference-extraction-strategy)
  - [8.3. System Prompt Template](#83-system-prompt-template)
  - [8.4. User Prompt Template](#84-user-prompt-template)
  - [8.5. Expected Response Schema](#85-expected-response-schema)
  - [8.6. Response Parsing Logic](#86-response-parsing-logic)
  - [8.7. Report Output Format](#87-report-output-format)
  - [8.8. Error Handling](#88-error-handling)
  - [8.9. Performance Characteristics](#89-performance-characteristics)
- [9. Soft Axiom Deep Validation](#9-soft-axiom-deep-validation)
  - [9.1. Purpose and Scope](#91-purpose-and-scope)
  - [9.2. Axiom Context Extraction](#92-axiom-context-extraction)
  - [9.3. System Prompt Template](#93-system-prompt-template)
  - [9.4. User Prompt Template](#94-user-prompt-template)
  - [9.5. Expected Response Schema](#95-expected-response-schema)
  - [9.6. Integration with VAL-AXM-002](#96-integration-with-val-axm-002)
- [10. Prose-vs-Frontmatter Consistency Checking](#10-prose-vs-frontmatter-consistency-checking)
  - [10.1. Design Decision: OQ-5 Resolution](#101-design-decision-oq-5-resolution)
  - [10.2. System Prompt Template](#102-system-prompt-template)
  - [10.3. User Prompt Template](#103-user-prompt-template)
  - [10.4. Expected Response Schema](#104-expected-response-schema)
- [11. Common Infrastructure](#11-common-infrastructure)
  - [11.1. Token Budget Management](#111-token-budget-management)
  - [11.2. Batch Processing Strategy](#112-batch-processing-strategy)
  - [11.3. Response Validation Pipeline](#113-response-validation-pipeline)
  - [11.4. Retry and Timeout Policy](#114-retry-and-timeout-policy)
  - [11.5. Logging and Diagnostics](#115-logging-and-diagnostics)
- [12. Configuration Reference](#12-configuration-reference)
- [13. Open Questions Resolved](#13-open-questions-resolved)
- [14. Dependencies and Cross-References](#14-dependencies-and-cross-references)
- [15. Document Revision History](#15-document-revision-history)

---

## 1. Document Purpose and Scope

This document formally specifies the **LLM integration layer** for Chronicle's Phase 4 features. It defines exactly how Chronicle communicates with language models — what prompts it sends, what responses it expects, how it parses those responses, and what reports it produces for human review.

Chronicle uses LLMs for four distinct features, each producing advisory output for human review:

1. **Semantic Contradiction Detection** — The `--deep` flag on `chronicle validate`. Identifies contradictions in prose content that deterministic rules cannot catch.
2. **Merge Conflict Narrative Resolution** — Cross-file contradiction analysis during branch merges. Detects semantic conflicts that Git's line-level merge doesn't surface.
3. **Lore Expansion Suggestions** — The `chronicle suggest` command. Combines deterministic graph analysis with LLM interpretation to identify worldbuilding gaps and narrative opportunities.
4. **Draft Stub Generation** — The `chronicle stub` command. Generates starter documents for referenced-but-undefined entities using context from existing references.

Additionally, this document specifies two supporting LLM capabilities that integrate into the features above:

5. **Soft Axiom Deep Validation** — LLM-powered semantic checking of axioms with `enforcement: "soft"`, triggered by D-12's VAL-AXM-002 rule during `--deep` validation.
6. **Prose-vs-Frontmatter Consistency Checking** — Validates that Markdown body text is consistent with YAML frontmatter metadata. This resolves OQ-5 from D-01.

**What this document covers:**

- The `ILlmProvider` abstraction interface and provider configuration
- Complete system prompt and user prompt templates for each feature
- Expected response schemas (the structured format the LLM should produce)
- Response parsing logic (how Chronicle interprets and validates LLM output)
- Report output formats (the Markdown reports generated for the human)
- Error handling strategies (what happens when the LLM produces unparseable, incomplete, or hallucinated output)
- Performance characteristics (expected token counts, batching strategies, latency budgets)
- Token budget management for large corpora

**What this document does NOT cover:**

- CLI command syntax and flags (see D-13: CLI Command Reference)
- Deterministic validation rules (see D-12: Validation Rule Catalog)
- FractalRecall embedding or semantic search integration (see D-15: Integration Design Document, blocked on Track B results)
- The specific LLM models to use (see D-01 §6.7 for recommendations; model choice is a deployment-time decision, not a specification concern)

**Relationship to D-13:** D-13 provides preliminary specifications for `chronicle suggest` (§7.1) and `chronicle stub` (§7.2) and defers prompt templates and response parsing to this document. D-14 fills those gaps and provides the behavioral details that make those commands implementable. D-13's `--deep` flag (§5.3) similarly defers to D-14 for the LLM interaction mechanics.

---

## 2. Conventions and Terminology

| Term | Definition |
|------|------------|
| **LLM** | Large Language Model. A neural network trained on text that generates text responses given a prompt. Chronicle uses LLMs for analysis and generation, never for authoritative decision-making. |
| **System prompt** | Instructions given to the LLM that define its role, constraints, and output format. Persists across the interaction. |
| **User prompt** | The specific content submitted to the LLM for analysis. Contains the lore file content, context, and the specific question or task. |
| **Response schema** | The structured format that the LLM's output should conform to. Chronicle uses YAML-in-Markdown fenced blocks for structured responses. |
| **Parsing** | The process of extracting structured data from the LLM's free-text response. Includes validation, fallback heuristics, and error handling. |
| **Report** | A Markdown file produced by Chronicle summarizing LLM findings for human review. Reports are the primary output artifact of every LLM feature. |
| **Document cluster** | A set of related lore files grouped for analysis. Clusters are formed by shared tags, relationships, entity references, or entity type proximity. |
| **Token** | The basic unit of text processed by an LLM. Roughly 4 characters or 0.75 words in English. Token counts determine context window usage and inference cost. |
| **Context window** | The maximum number of tokens an LLM can process in a single request (system prompt + user prompt + response). Typical ranges: 8K–128K tokens depending on the model. |
| **Provider** | An LLM inference backend. Ollama and LM Studio are local providers; OpenAI-compatible APIs and Anthropic are cloud providers. |
| **Advisory output** | Information produced by the LLM for human review. Never applied automatically to lore files. |
| **Deterministic-first** | The principle that all deterministic checks run before LLM checks. LLM features supplement, not replace, the D-12 validation pipeline. |
| **Soft axiom** | An axiom with `enforcement: "soft"` in its frontmatter. Cannot be checked deterministically; requires LLM semantic analysis (D-12 VAL-AXM-002). |
| **Hard axiom** | An axiom with `enforcement: "hard"` in its frontmatter. Checked deterministically by D-12 VAL-AXM-001 using the three assertion rule types (`temporal_bound`, `value_constraint`, `pattern_match`). |

**Prompt template notation:** Throughout this document, prompt templates use `{{variable}}` syntax for values that Chronicle substitutes at runtime. For example, `{{entity_name}}` is replaced with the actual entity name from the lore file's frontmatter.

**Severity levels for LLM findings:** LLM-powered checks use a parallel severity system that does not map directly to D-12's ERROR/WARNING/INFORMATIONAL levels (because LLM findings carry inherent uncertainty). The LLM severity levels are:

| Level | Meaning | Human Action |
|-------|---------|-------------|
| `CONTRADICTION` | The LLM identified a direct factual conflict between two assertions. High confidence that the content is inconsistent. | Should be reviewed and resolved. |
| `TENSION` | The LLM identified a potential inconsistency, ambiguity, or narrative friction. May be intentional (e.g., character complexity) or an oversight. | Should be reviewed; may be intentionally accepted. |
| `SUGGESTION` | The LLM identified a gap, opportunity, or area for improvement. No inconsistency detected. | Optional; author decides whether to act. |
| `NOTE` | Contextual observation that may inform the author's decisions. Lowest confidence. | Informational only. |

---

## 3. Architectural Principles

### 3.1. Advisory, Never Authoritative

This is the foundational principle of all LLM integration in Chronicle, established in D-01 §6.1. Every LLM-powered feature produces a **report** for human review. The LLM never modifies lore files directly, never changes canon status, and never makes creative decisions on behalf of the author.

The only exception is `chronicle stub` (§8), which creates new files — but those files are always created with `canon: false`, include a `machine-generated` tag, and display a prominent warning banner in the Markdown body. The human must explicitly review, revise, and promote the stub before it enters the canonical record.

**Implementation rule:** No code path should exist where LLM output is written to an existing lore file without an intervening human approval step. This invariant must be enforced architecturally, not just by convention.

### 3.2. LLM Provider Abstraction

Chronicle accesses LLMs through an abstracted provider interface (`ILlmProvider`). This decouples the prompt engineering and response parsing logic from the specific inference backend. The same prompts work with Ollama, LM Studio, OpenAI-compatible APIs, and Anthropic — the provider handles the transport and API-specific formatting.

This mirrors FractalRecall's `IEmbeddingProvider` pattern (D-02) and aligns with the `Microsoft.Extensions.AI.Abstractions` ecosystem (D-04 §9.5, R-07).

### 3.3. Deterministic-First Pipeline

LLM validation is always preceded by the full deterministic validation pipeline (D-12 Tiers 1-3). The `--deep` flag adds LLM checks **on top of** deterministic checks — it never replaces them. This means:

- If Tier 1 fails for a file, that file never reaches the LLM.
- If Tier 2 fails for a file, structural issues should be fixed before asking the LLM for semantic analysis (the LLM would likely flag the same issues, wasting tokens and time).
- Tier 3 deterministic checks (canon consistency, temporal ordering, hard axiom enforcement) run before LLM checks. The LLM handles what Tier 3 cannot: prose contradictions, soft axiom violations, and narrative tensions.

**Rationale:** Deterministic checks are fast, free, and deterministic. LLM checks are slow, potentially costly (if using cloud providers), and non-deterministic. Running deterministic checks first ensures that the LLM's token budget is spent on problems that actually require semantic understanding.

### 3.4. Report-Oriented Output

Every LLM feature produces a structured Markdown report. Reports are designed to be:

- **Self-contained:** A reader should understand each finding without needing to open other files. Reports include file paths, entity names, relevant excerpts, and the LLM's reasoning.
- **Actionable:** Each finding includes enough context for the human to decide whether to act on it and how.
- **Archivable:** Reports can be saved to disk (`--output`) for historical tracking, team review, or CI/CD integration.
- **Machine-parseable:** Reports use consistent Markdown structure (headers, code blocks, severity markers) so that tooling can extract findings programmatically if needed.

### 3.5. Graceful Degradation

LLM features must fail gracefully. If the LLM endpoint is unavailable, returns an error, or produces unparseable output, Chronicle should:

1. Complete all deterministic checks normally.
2. Report the LLM failure clearly in the output (not silently swallow it).
3. Exit with code 4 (`LLM_ERROR`) per D-13 §4 exit code conventions.
4. Never crash or corrupt the validation report due to an LLM failure.

For individual findings within a batch: if the LLM response for one document cluster is unparseable, Chronicle logs the failure for that cluster, continues processing other clusters, and includes a "partial results" warning in the final report.

---

## 4. LLM Provider Interface

### 4.1. Provider Configuration

LLM providers are configured in `.chronicle/config.yaml` under the `llm` section. The configuration schema:

```yaml
# .chronicle/config.yaml — LLM section

llm:
  # --- Provider Selection ---
  provider: "ollama"                   # Required. One of: "ollama", "lmstudio", "openai", "anthropic"

  # --- Endpoint Configuration ---
  endpoint: "http://localhost:11434"   # Required. Base URL for the provider's API.
  model: "llama3.1:70b"               # Required. The model identifier to use.

  # --- Authentication (cloud providers only) ---
  api_key_env: "CHRONICLE_LLM_API_KEY"  # Optional. Environment variable name containing the API key.
                                          # Chronicle never stores API keys directly in config.

  # --- Token Budget ---
  max_input_tokens: 8192               # Optional. Maximum tokens per request (prompt + context).
                                        # Default: 8192. Increase for models with larger context windows.
  max_output_tokens: 2048              # Optional. Maximum tokens for the LLM response.
                                        # Default: 2048.

  # --- Performance Tuning ---
  timeout_seconds: 120                 # Optional. Per-request timeout. Default: 120.
  max_retries: 2                       # Optional. Retry count for transient failures. Default: 2.
  temperature: 0.1                     # Optional. Sampling temperature. Default: 0.1 (low for consistency).
                                        # Range: 0.0–1.0. Lower values produce more deterministic output.

  # --- Batch Processing ---
  max_concurrent_requests: 1           # Optional. Parallel request limit. Default: 1 (sequential).
                                        # Local inference: keep at 1 (single GPU). Cloud: can increase.
  batch_delay_ms: 100                  # Optional. Delay between sequential requests in ms. Default: 100.
                                        # Prevents overwhelming local inference servers.
```

**Environment variable resolution:** The `api_key_env` field specifies the name of an environment variable, not the key itself. Chronicle reads the key from the environment at runtime. This prevents API keys from being committed to version control. If `api_key_env` is set but the environment variable is not defined, Chronicle exits with code 2 (config error).

**Validation on load:** Chronicle validates the `llm` configuration section when any LLM-dependent command is invoked (`validate --deep`, `suggest`, `stub`). If the section is missing or malformed, Chronicle exits with code 2 and a message directing the user to configure the LLM endpoint.

### 4.2. `ILlmProvider` Interface Contract

The `ILlmProvider` interface abstracts LLM inference for Chronicle's features. This is a C# interface that all provider implementations must satisfy.

```csharp
/// <summary>
/// Abstraction for LLM text generation providers.
/// Implementations handle transport, authentication, and API-specific formatting.
/// Chronicle's prompt templates and response parsing are provider-agnostic.
/// </summary>
public interface ILlmProvider : IDisposable
{
    /// <summary>
    /// Send a prompt to the LLM and receive a text response.
    /// </summary>
    /// <param name="request">The structured request containing system prompt,
    /// user prompt, and generation parameters.</param>
    /// <param name="cancellationToken">Cancellation token for timeout/abort.</param>
    /// <returns>The LLM's text response with metadata.</returns>
    /// <exception cref="LlmConnectionException">
    /// Thrown when the LLM endpoint is unreachable.
    /// </exception>
    /// <exception cref="LlmTimeoutException">
    /// Thrown when the request exceeds the configured timeout.
    /// </exception>
    /// <exception cref="LlmAuthenticationException">
    /// Thrown when API key authentication fails (cloud providers).
    /// </exception>
    Task<LlmResponse> GenerateAsync(
        LlmRequest request,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Verify that the provider can reach its endpoint and the configured
    /// model is available. Called once at the start of LLM-dependent commands.
    /// </summary>
    /// <returns>True if the endpoint is reachable and the model is loaded.</returns>
    Task<bool> HealthCheckAsync(
        CancellationToken cancellationToken = default);

    /// <summary>
    /// The provider's name for logging and diagnostics (e.g., "Ollama", "OpenAI").
    /// </summary>
    string ProviderName { get; }

    /// <summary>
    /// The configured model identifier (e.g., "llama3.1:70b", "gpt-4o").
    /// </summary>
    string ModelId { get; }
}
```

### 4.3. Request and Response Types

```csharp
/// <summary>
/// A structured request to the LLM provider.
/// </summary>
public sealed class LlmRequest
{
    /// <summary>
    /// The system prompt defining the LLM's role and output constraints.
    /// </summary>
    public required string SystemPrompt { get; init; }

    /// <summary>
    /// The user prompt containing the specific content for analysis.
    /// </summary>
    public required string UserPrompt { get; init; }

    /// <summary>
    /// Sampling temperature override. If null, uses the provider's configured default.
    /// </summary>
    public double? Temperature { get; init; }

    /// <summary>
    /// Maximum response tokens override. If null, uses the provider's configured default.
    /// </summary>
    public int? MaxOutputTokens { get; init; }

    /// <summary>
    /// A human-readable label for this request, used in logging.
    /// Example: "deep-validation/cluster-3", "stub/marcus-thane"
    /// </summary>
    public string? RequestLabel { get; init; }
}

/// <summary>
/// The LLM's response with metadata for diagnostics and token tracking.
/// </summary>
public sealed class LlmResponse
{
    /// <summary>
    /// The raw text content of the LLM's response.
    /// </summary>
    public required string Content { get; init; }

    /// <summary>
    /// Number of tokens in the input (system + user prompt).
    /// May be null if the provider doesn't report token counts.
    /// </summary>
    public int? InputTokens { get; init; }

    /// <summary>
    /// Number of tokens in the output (response).
    /// May be null if the provider doesn't report token counts.
    /// </summary>
    public int? OutputTokens { get; init; }

    /// <summary>
    /// Wall-clock time for the inference request.
    /// </summary>
    public TimeSpan Duration { get; init; }

    /// <summary>
    /// Whether the response was truncated due to max_output_tokens.
    /// If true, the response may be incomplete and should be treated with caution.
    /// </summary>
    public bool Truncated { get; init; }
}
```

### 4.4. Supported Providers

| Provider | Transport | Authentication | Local/Cloud | Notes |
|----------|-----------|---------------|-------------|-------|
| **Ollama** | HTTP REST (`/api/generate`) | None (local) | Local | Primary target. Supports model management, GPU acceleration. Default endpoint: `http://localhost:11434`. |
| **LM Studio** | OpenAI-compatible HTTP REST (`/v1/chat/completions`) | None (local) | Local | Alternative local provider. Uses OpenAI-compatible API format. Default endpoint: `http://localhost:1234`. |
| **OpenAI-compatible** | HTTP REST (`/v1/chat/completions`) | Bearer token via `api_key_env` | Cloud | Any OpenAI-compatible API (OpenAI, Together, Groq, etc.). Requires API key. |
| **Anthropic** | HTTP REST (`/v1/messages`) | `x-api-key` header via `api_key_env` | Cloud | Anthropic's Claude API. Uses Messages API format. Requires API key. |

**Provider implementation responsibility:** Each provider implementation translates Chronicle's `LlmRequest` into the provider's native API format, handles authentication, and translates the native response back into `LlmResponse`. The prompt templates and response parsing logic (§5–§10) are provider-agnostic.

### 4.5. Provider Selection and Fallback

Chronicle uses a single configured provider per invocation. There is no automatic fallback chain (switching from one provider to another on failure), because:

1. Different providers/models produce different output quality. Prompt templates are tuned for a general quality baseline but not for specific model quirks.
2. Automatic failover to a cloud provider could surprise the user with unexpected API costs or data transmission.
3. The user should make an explicit decision about which inference backend to use.

If the configured provider fails its health check, Chronicle exits with code 4 and a message identifying the failure. The user can reconfigure and retry.

**Embedding models vs. generation models:** This document specifies LLM **text generation** for analysis and content creation. Embedding model selection (used by FractalRecall for semantic search, `chronicle index`, and `chronicle search`) is a separate concern governed by D-15 (Integration Design Document) and the Master Strategy technology stack section. The Master Strategy recommends `nomic-embed-text-v2-moe` for embeddings (upgraded from v1.x per D-04 §9.3). Generation model recommendations (Llama, Mistral, Qwen families at 7B–70B scale per D-01 §6.7) are deployment-time decisions and are not prescribed by D-14 — the `ILlmProvider` abstraction accommodates any model the user configures.

---

## 5. Feature 1: Semantic Contradiction Detection (`validate --deep`)

### 5.1. Purpose and Scope

Semantic contradiction detection is Chronicle's most critical LLM feature. It catches inconsistencies that live in **prose** — the Markdown body text of lore files — which deterministic rules cannot parse. D-12's Tier 1-3 rules validate structured frontmatter (field presence, types, cross-references, temporal ordering, axiom assertions). But a worldbuilding corpus can be internally consistent at the structural level while harboring semantic contradictions in its narrative text.

**Example** (from D-01 §6.2): Document A states "The Iron Covenant never practiced magic; they viewed it as an abomination." Document B describes "Iron Covenant ritualists channeling arcane energy." No frontmatter field captures this contradiction — it lives entirely in prose. Only a language model (or a very attentive human reader) can catch it.

**What `--deep` validates:**

- Prose-to-prose contradictions between related documents
- Prose-to-frontmatter inconsistencies within a single document (see §10)
- Soft axiom violations flagged by VAL-AXM-002 (see §9)
- Narrative tensions that may or may not be intentional

**What `--deep` does NOT validate:**

- Anything that D-12 Tiers 1-3 already check. If Tier 3 detects a hard axiom violation, that's a deterministic finding — the LLM doesn't re-check it.
- Writing quality, style, or grammar. Chronicle is a continuity tool, not an editor.

### 5.2. Document Clustering Strategy

Sending every possible pair of documents to the LLM would be combinatorially explosive. A corpus of 100 files would produce 4,950 pairs. Instead, Chronicle uses a **clustering strategy** that groups related documents and only analyzes within-cluster relationships.

**Clustering algorithm:**

1. **Build the entity relationship graph** from frontmatter (this is already computed during `chronicle validate`).
2. **Form initial clusters** using connected components in the relationship graph. Two files are in the same cluster if they share a direct relationship (via the `relationships` frontmatter block) or both reference a common third entity.
3. **Merge tag-based overlaps.** If two files share 2 or more tags (from the `tags` frontmatter field), they are merged into the same cluster even if no direct relationship exists. This catches thematic connections that aren't modeled as explicit relationships.
4. **Split oversized clusters.** If a cluster exceeds the token budget for a single LLM request (see §5.9), split it into sub-clusters using a priority order:
   a. Highest priority: pairs connected by direct relationships.
   b. Medium priority: pairs sharing tags.
   c. Lowest priority: pairs connected only through a shared third entity.

   Sub-clusters are sized to fit within the token budget with room for the system prompt and expected response.

5. **Include entity type context.** For each cluster, identify any axiom entries (D-10 `type: axiom`) that are relevant to the entities in the cluster (same tags, same era, same domain). Include these axioms as context so the LLM can check for axiom-related tensions.

**Cluster metadata** (included in the prompt):

```yaml
cluster_id: 3
files:
  - path: "factions/iron-covenant.md"
    type: faction
    canon: true
    name: "The Iron Covenant"
  - path: "events/arcane-purge.md"
    type: event
    canon: true
    name: "The Arcane Purge"
  - path: "characters/elena-voss.md"
    type: character
    canon: true
    name: "Elena Voss"
shared_tags: ["iron-covenant", "magic", "third-age"]
shared_relationships:
  - "Elena Voss" → member_of → "The Iron Covenant"
  - "The Iron Covenant" → participant → "The Arcane Purge"
relevant_axioms:
  - "No Mortal Can Survive Direct Aetherium Exposure" (hard, physical)
```

### 5.3. System Prompt Template

```
You are a continuity editor for a worldbuilding project called "{{world_name}}". Your role is to identify semantic contradictions, tensions, and inconsistencies in the lore documents provided to you.

## Your Task

Analyze the provided cluster of related lore documents and identify:

1. **CONTRADICTIONS**: Direct factual conflicts where two documents make mutually exclusive assertions. These are high-confidence findings where both statements cannot be simultaneously true within the world's established rules.

2. **TENSIONS**: Potential inconsistencies or narrative friction where two documents seem to pull in different directions, but the conflict might be intentional (e.g., an unreliable narrator, character complexity, or deliberate ambiguity). Flag these for human review.

3. **NOTES**: Contextual observations that do not rise to the level of contradiction or tension, but that the author should be aware of (e.g., vague temporal references that could become problematic as more lore is added).

## Rules

- Analyze both the YAML frontmatter metadata AND the Markdown body text of each document.
- When citing evidence, quote specific passages and identify the source file.
- Do NOT flag differences that are explained by canon status differences (e.g., a draft document contradicting a canonical one is expected — drafts are works in progress).
- Do NOT flag apocryphal content (`canon: "apocryphal"`) contradicting canonical content — apocryphal entries are explicitly allowed to diverge from canon.
- Do NOT flag deprecated content (`canon: "deprecated"`) — it has been intentionally superseded.
- Only flag contradictions between documents of the SAME canon status, or where a canonical document internally contradicts itself.
- Be conservative. Only flag CONTRADICTION for clear, unambiguous conflicts. Use TENSION for anything that might be intentional.
- If no issues are found, explicitly state "No contradictions, tensions, or notes identified for this cluster."

## Relevant Axioms

The following world axioms apply to the entities in this cluster. Consider whether any document content violates these axioms:

{{axiom_context}}

## Output Format

Respond with ONLY a YAML block inside a Markdown fenced code block. Do not include any text outside the code block.

```yaml
findings:
  - severity: "CONTRADICTION" | "TENSION" | "NOTE"
    summary: "<One-sentence summary of the finding>"
    evidence:
      - file: "<file path>"
        passage: "<Exact quote from the document>"
        location: "frontmatter" | "body"
      - file: "<file path>"
        passage: "<Exact quote from the contradicting document>"
        location: "frontmatter" | "body"
    reasoning: "<Explanation of why this is a contradiction/tension/note>"
    suggested_resolution: "<Brief suggestion for how the author might resolve this>"
```

If no findings, respond with:

```yaml
findings: []
```
```

### 5.4. User Prompt Template

```
## Document Cluster {{cluster_id}}

### Cluster Context

{{cluster_metadata_yaml}}

### Documents

{{#each documents}}
---
#### File: {{this.path}}
**Type:** {{this.type}} | **Canon:** {{this.canon}} | **Name:** {{this.name}}

**Frontmatter:**
```yaml
{{this.frontmatter}}
```

**Body:**
{{this.body}}

{{/each}}
---

Analyze this cluster for contradictions, tensions, and notes. Remember:
- Only flag issues between documents of the same canon status.
- Apocryphal and deprecated content is excluded from contradiction checks.
- Cite specific passages with file paths.
- Use the YAML output format specified in your instructions.
```

**Template variable resolution:** The `{{#each documents}}` block iterates over each document in the cluster. For each document, Chronicle extracts the raw YAML frontmatter and the Markdown body text. The body text is included in full unless it would exceed the token budget, in which case it is truncated with a `[TRUNCATED — body exceeds token budget. First {{n}} characters shown.]` marker.

### 5.5. Expected Response Schema

The LLM is instructed to respond with a YAML block inside a Markdown fenced code block. The expected schema:

```yaml
# Expected response from the LLM for contradiction detection
findings:
  - severity: string          # Required. One of: "CONTRADICTION", "TENSION", "NOTE"
    summary: string            # Required. One-sentence human-readable summary.
    evidence:                  # Required. At least one evidence entry.
      - file: string           # Required. File path relative to repository root.
        passage: string        # Required. Exact quote from the document.
        location: string       # Required. "frontmatter" or "body".
      - file: string           # Second evidence entry (usually the contradicting doc).
        passage: string
        location: string
    reasoning: string          # Required. Explanation of the finding.
    suggested_resolution: string  # Optional. Brief suggestion for resolution.
```

**Schema invariants:**

- `findings` must be a list (may be empty).
- Each finding must have `severity`, `summary`, `evidence`, and `reasoning`.
- `evidence` must contain at least one entry; contradictions should have at least two (one from each conflicting document).
- `severity` must be one of the three allowed values. Unknown values are treated as `NOTE`.
- `file` paths must match paths that were provided in the prompt. If the LLM fabricates a file path not in the cluster, the finding is flagged as potentially hallucinated.

### 5.6. Response Parsing Logic

Chronicle parses the LLM response through a multi-stage pipeline:

**Stage 1 — Extract YAML block.** Search the response for a Markdown fenced code block tagged `yaml`. If found, extract its contents. If not found, attempt to parse the entire response as YAML (some models omit the code fence). If neither works, the response is unparseable — log a warning and skip this cluster.

**Stage 2 — Parse YAML.** Deserialize the extracted text using YamlDotNet. If deserialization fails (malformed YAML), log the raw response for diagnostics and skip this cluster.

**Stage 3 — Validate schema.** Check that the parsed object conforms to the expected schema (§5.5). Specifically:
- `findings` key exists and is a list.
- Each finding has all required fields.
- `severity` is a recognized value (unknown values downgrade to `NOTE`).
- `file` paths reference documents that were actually in the cluster.

**Stage 4 — Cross-reference validation.** For each finding:
- Verify that cited file paths exist in the cluster.
- Verify that quoted passages appear in the actual document content (fuzzy match with a threshold of 80% character similarity to account for minor LLM paraphrasing). If a passage doesn't match anything in the cited file, flag the evidence entry as `[UNVERIFIED — passage not found in source]`.
- If all evidence entries for a finding are unverified, downgrade the finding to `NOTE` with a `[LOW CONFIDENCE — evidence could not be verified]` annotation.

**Stage 5 — Deduplication.** If the same pair of documents appears in multiple clusters (due to overlapping cluster membership), deduplicate findings by comparing `summary` fields with a similarity threshold. Keep the finding with the most detailed evidence.

### 5.7. Report Output Format

Deep validation findings are appended to the standard validation report (D-13 §8.1) under a dedicated section:

```markdown
## Deep Validation (LLM-Powered)

**Provider:** Ollama (llama3.1:70b)
**Clusters analyzed:** {{cluster_count}}
**Total LLM requests:** {{request_count}}
**Total tokens consumed:** {{total_input_tokens}} input / {{total_output_tokens}} output
**Duration:** {{total_duration}}

### Summary

| Severity | Count |
|----------|-------|
| CONTRADICTION | {{contradiction_count}} |
| TENSION | {{tension_count}} |
| NOTE | {{note_count}} |

{{#if has_partial_failures}}
> ⚠ **Partial Results:** {{failure_count}} cluster(s) could not be analyzed due to LLM errors. See diagnostics below.
{{/if}}

### Findings

{{#each findings}}
#### {{this.severity}}: {{this.summary}}

**Evidence:**

{{#each this.evidence}}
- **{{this.file}}** ({{this.location}}): "{{this.passage}}"
{{/each}}

**Reasoning:** {{this.reasoning}}

{{#if this.suggested_resolution}}
**Suggested Resolution:** {{this.suggested_resolution}}
{{/if}}

---
{{/each}}

{{#if has_partial_failures}}
### Diagnostics

The following clusters could not be analyzed:

{{#each failures}}
- **Cluster {{this.cluster_id}}** ({{this.file_count}} files): {{this.error_message}}
{{/each}}
{{/if}}
```

### 5.8. Error Handling

| Error Condition | Behavior |
|----------------|----------|
| LLM endpoint unreachable | Exit code 4. Skip all deep validation. Deterministic results still reported. |
| LLM returns empty response | Log warning for the cluster. Continue with remaining clusters. Include in diagnostics section. |
| LLM response is not parseable YAML | Log the raw response (first 500 characters) for diagnostics. Skip the cluster. Continue with remaining clusters. |
| LLM fabricates file paths | Flag evidence entries with `[UNVERIFIED]`. Downgrade finding if all evidence is unverified. |
| LLM response is truncated (`Truncated: true`) | Log a warning. Attempt to parse whatever was received. If the YAML is incomplete, skip the cluster. |
| LLM request timeout | Retry up to `max_retries` times. If all retries fail, log the cluster as failed and continue. |
| Token budget exceeded for cluster | Split the cluster into smaller sub-clusters (§5.2, step 4) and process individually. |

### 5.9. Performance Characteristics

| Metric | Estimate | Notes |
|--------|----------|-------|
| **System prompt size** | ~800 tokens | Stable across invocations. |
| **Per-document tokens** (frontmatter) | ~100–300 tokens | Depends on relationship count and tag count. |
| **Per-document tokens** (body) | ~200–2000 tokens | Highly variable. Average worldbuilding entry is ~500 words (~670 tokens). |
| **Cluster size target** | 3–8 documents | Balances context quality with token budget. |
| **Tokens per cluster request** | ~2,000–8,000 input | System prompt + cluster metadata + document contents. |
| **Expected response size** | ~200–800 tokens | Depends on finding count. |
| **Latency per cluster** (local 70B model) | 15–60 seconds | Dependent on model size, hardware, and response length. |
| **Latency per cluster** (cloud API) | 3–15 seconds | Dependent on provider and model. |
| **Corpus of 100 files, ~15 clusters** | ~15–30 minutes (local) | Sequential processing with `max_concurrent_requests: 1`. |

**Token budget management:** For a model with an 8K context window, the effective budget per cluster is approximately:

```
8,192 total tokens
  -800 system prompt
  -200 cluster metadata
-2,048 reserved for response
------
5,144 tokens available for document content
```

At an average of ~400 tokens per document (frontmatter + truncated body), this fits approximately 12 documents per cluster — well above the target cluster size of 3–8. For models with 32K or 128K context windows, the budget scales proportionally, allowing larger clusters or full untruncated document bodies.

---

## 6. Feature 2: Merge Conflict Narrative Resolution

### 6.1. Purpose and Scope

Git detects merge conflicts when two branches modify the **same lines** of the same file. But worldbuilding contradictions often arise when two branches modify **different files** in contradictory ways. Branch A establishes that a city was destroyed; Branch B (developed concurrently) describes that city as thriving. Git merges these without complaint because no file-level conflict exists.

Chronicle's merge analysis uses the LLM to compare incoming branch changes against the existing canonical content and flag semantic conflicts that Git's merge mechanism wouldn't catch.

**Trigger:** This feature is invoked manually by the user when preparing a branch for merge. It is not automatically triggered during `git merge`. The recommended workflow is:

1. User finishes their branch work.
2. User runs `chronicle validate --deep` on their branch to catch within-branch issues.
3. User runs `chronicle merge-check <target-branch>` (a Phase 4 command extension) to compare their branch changes against the target branch.
4. Review the merge analysis report before merging.

> **Note:** D-13 does not define a `chronicle merge-check` command — this feature was described in D-01 §6.4 but not surfaced as a named CLI command. This document specifies the LLM interaction mechanics. The CLI command specification will be added to D-13 as an amendment once D-14 is reviewed and approved.

### 6.2. Change Detection Strategy

Before invoking the LLM, Chronicle performs deterministic change detection:

1. **Identify changed files.** Compare the source branch against the target branch using `git diff --name-only`. Filter to only lore files (Markdown files with YAML frontmatter in tracked directories).
2. **Identify changed content.** For each changed file, extract the specific frontmatter fields and body sections that differ between branches.
3. **Identify potentially affected files.** For each changed file, find all files in the target branch that have direct relationships to the changed file (incoming references, outgoing references, shared tags). These are the "context files" that might be contradicted by the changes.
4. **Form analysis pairs.** Each analysis request pairs a changed file (from the source branch) with its context files (from the target branch). This is similar to the clustering strategy in §5.2 but scoped to the change set.

### 6.3. System Prompt Template

```
You are a continuity editor for a worldbuilding project called "{{world_name}}". A contributor is preparing to merge changes from branch "{{source_branch}}" into "{{target_branch}}". Your role is to identify whether the incoming changes introduce any contradictions or tensions with the existing canonical content.

## Your Task

Analyze the incoming changes against the existing canonical documents and identify:

1. **CONTRADICTIONS**: The incoming changes directly conflict with assertions in existing canonical documents. These would introduce inconsistencies if merged.

2. **TENSIONS**: The incoming changes might conflict with existing content, but the conflict could be intentional (e.g., the changes are meant to revise or extend existing lore).

3. **NOTES**: Observations about the incoming changes that the contributor should be aware of before merging (e.g., the changes affect an entity that is referenced by many other documents).

## Rules

- Focus on the CHANGES, not on pre-existing issues in the target branch. If the target branch already has contradictions, do not flag them here — that's what `chronicle validate --deep` is for.
- Compare the changed content (marked with "INCOMING CHANGE") against the existing content (marked with "EXISTING CANONICAL").
- Be conservative with CONTRADICTION severity. Only flag it when the incoming change makes an assertion that directly conflicts with an existing assertion.
- Consider whether the incoming change might be an intentional revision. If a character's backstory is being rewritten, that's not a contradiction — it's a revision. Flag it as a NOTE with context.

## Output Format

Respond with ONLY a YAML block inside a Markdown fenced code block.

```yaml
findings:
  - severity: "CONTRADICTION" | "TENSION" | "NOTE"
    summary: "<One-sentence summary>"
    incoming_file: "<Path to the changed file>"
    existing_file: "<Path to the existing file that is contradicted>"
    incoming_passage: "<Quote from the changed content>"
    existing_passage: "<Quote from the existing content>"
    reasoning: "<Explanation>"
    merge_recommendation: "block" | "review" | "safe"
      # block: Should not merge until resolved.
      # review: Human should review before merging.
      # safe: Merge is likely safe; noting for awareness.
```

If no findings, respond with:

```yaml
findings: []
```
```

### 6.4. User Prompt Template

```
## Merge Analysis: {{source_branch}} → {{target_branch}}

### Incoming Changes (from {{source_branch}})

{{#each changed_files}}
---
#### INCOMING CHANGE: {{this.path}}
**Type:** {{this.type}} | **Canon:** {{this.canon}} | **Name:** {{this.name}}
**Change Summary:** {{this.change_summary}}

**Changed Frontmatter (diff):**
```diff
{{this.frontmatter_diff}}
```

**Changed Body Sections:**
{{this.body_diff}}

{{/each}}

### Existing Canonical Documents (from {{target_branch}})

These documents are related to the changed files and may be affected by the incoming changes:

{{#each context_files}}
---
#### EXISTING CANONICAL: {{this.path}}
**Type:** {{this.type}} | **Canon:** {{this.canon}} | **Name:** {{this.name}}

**Frontmatter:**
```yaml
{{this.frontmatter}}
```

**Body:**
{{this.body}}

{{/each}}

---

Analyze whether the incoming changes contradict, create tensions with, or affect the existing canonical documents. Use the YAML output format specified in your instructions.
```

### 6.5. Expected Response Schema

```yaml
findings:
  - severity: string              # "CONTRADICTION", "TENSION", or "NOTE"
    summary: string                # One-sentence summary
    incoming_file: string          # Path to the changed file
    existing_file: string          # Path to the existing canonical file
    incoming_passage: string       # Quote from the incoming change
    existing_passage: string       # Quote from the existing content
    reasoning: string              # Explanation
    merge_recommendation: string   # "block", "review", or "safe"
```

### 6.6. Response Parsing Logic

Identical to §5.6 (Extract YAML → Parse → Validate schema → Cross-reference → Deduplicate), with the following additions:

- **File path validation:** `incoming_file` must be in the changed files list. `existing_file` must be in the context files list.
- **Merge recommendation validation:** Must be one of `"block"`, `"review"`, or `"safe"`. Unknown values default to `"review"`.
- **Passage verification:** Incoming passages are verified against the source branch version of the file. Existing passages are verified against the target branch version.

### 6.7. Report Output Format

```markdown
## Merge Analysis Report

**Source Branch:** {{source_branch}}
**Target Branch:** {{target_branch}}
**Changed Files:** {{changed_file_count}}
**Context Files Analyzed:** {{context_file_count}}
**Provider:** {{provider_name}} ({{model_id}})

### Summary

| Recommendation | Count |
|---------------|-------|
| Block (do not merge) | {{block_count}} |
| Review before merge | {{review_count}} |
| Safe (noting for awareness) | {{safe_count}} |

{{#if block_count > 0}}
> ⛔ **Merge Blocked:** {{block_count}} finding(s) should be resolved before merging.
{{/if}}

### Findings

{{#each findings}}
#### {{this.severity}}: {{this.summary}}

| | |
|---|---|
| **Incoming** | {{this.incoming_file}} |
| **Existing** | {{this.existing_file}} |
| **Recommendation** | {{this.merge_recommendation}} |

**Incoming passage:** "{{this.incoming_passage}}"

**Existing passage:** "{{this.existing_passage}}"

**Reasoning:** {{this.reasoning}}

---
{{/each}}
```

### 6.8. Error Handling

Identical to §5.8, with the additional case:

| Error Condition | Behavior |
|----------------|----------|
| No changed lore files between branches | Exit code 0. Message: `"No lore file changes detected between {source} and {target}. Nothing to analyze."` |
| Source or target branch does not exist | Exit code 3 (`GIT_ERROR`). Message: `"Branch '{branch}' does not exist."` |

### 6.9. Performance Characteristics

| Metric | Estimate | Notes |
|--------|----------|-------|
| **Typical change set** | 1–10 files | Most branches touch a focused subset of the corpus. |
| **Context files per changed file** | 2–8 files | Direct relationships + shared tags from the target branch. |
| **Tokens per analysis request** | ~3,000–10,000 input | Changed content + context files. |
| **Total requests for typical merge** | 1–5 | One per changed file (or grouped if changes are related). |
| **Latency** (local 70B model) | 1–5 minutes total | Dominated by inference time. |
| **Latency** (cloud API) | 15–60 seconds total | Much faster but incurs API costs. |

---

## 7. Feature 3: Lore Expansion Suggestions (`chronicle suggest`)

### 7.1. Purpose and Scope

The `chronicle suggest` command identifies **gaps and opportunities** in the worldbuilding corpus. It combines two analysis layers:

1. **Deterministic graph analysis** (cheap, precise): Analyzes the entity relationship graph to identify structural patterns like orphaned entities, sparsely connected regions, referenced-but-undefined entities, and entity types with low coverage.
2. **LLM interpretation** (expensive, creative): Takes the deterministic findings and adds narrative framing, suggesting *why* a gap might matter and *what* the author might do about it.

The deterministic layer always runs. The LLM layer adds narrative interpretation. If the LLM is unavailable, the command still produces useful output from the deterministic analysis alone (graceful degradation).

### 7.2. Deterministic Gap Analysis (Pre-LLM)

Before invoking the LLM, Chronicle performs the following deterministic analyses on the entity relationship graph:

**Analysis 1 — Referenced-but-undefined entities.** Scan all `relationships[].target` fields and body text for entity references. Identify targets that don't resolve to existing lore files. Rank by reference count (more references = higher priority).

**Analysis 2 — Orphaned entities.** Find entities with zero inbound relationships (no other entity references them). Exclude `meta` type entities and axioms (which are inherently standalone).

**Analysis 3 — Low-connectivity entities.** Find entities with fewer than 2 total relationships (inbound + outbound). These may be insufficiently connected to the broader world.

**Analysis 4 — Entity type coverage gaps.** Count entities per type. Flag entity types with fewer than 3 entries (sparse coverage may indicate underdeveloped areas of the world).

**Analysis 5 — Relationship asymmetry.** Identify entities with many outbound relationships but few inbound (they reference many things but nothing references them), or vice versa.

**Analysis 6 — Tag cluster isolation.** Identify tag-based topic clusters that are disconnected from each other. If the world has a "magic" cluster and a "politics" cluster with no entities bridging them, that may indicate a gap.

These analyses produce a structured gap report that is passed to the LLM for narrative interpretation.

### 7.3. System Prompt Template

```
You are a worldbuilding consultant for a project called "{{world_name}}". You have been given a structural analysis of the worldbuilding corpus — a set of patterns identified by analyzing the entity relationship graph. Your role is to interpret these patterns and suggest narrative opportunities.

## Your Task

For each structural finding, provide:

1. **Narrative interpretation:** Why might this pattern exist? Is it likely intentional or an oversight?
2. **Suggestion:** What could the author consider adding, expanding, or connecting? Be specific but not prescriptive — offer possibilities, not mandates.
3. **Priority:** How important is this gap? "high" if it could cause confusion for readers, "medium" if it enriches the world, "low" if it's a nice-to-have.

## Rules

- Be respectful of the author's creative vision. Frame suggestions as possibilities, not requirements.
- Do NOT suggest fundamental changes to the world's established rules or tone.
- Do NOT suggest removing or deprecating existing content.
- Focus on gaps, connections, and enrichment opportunities.
- Consider the world's genre, tone, and existing patterns when making suggestions.
- If a finding is likely intentional (e.g., a lone wolf character with no faction), say so and explain why it might still benefit from documentation.

## Output Format

Respond with ONLY a YAML block inside a Markdown fenced code block.

```yaml
suggestions:
  - finding_id: "<ID from the structural analysis>"
    interpretation: "<Why this pattern might exist>"
    suggestion: "<Specific narrative suggestion>"
    priority: "high" | "medium" | "low"
    entity_types_involved: ["<type1>", "<type2>"]
    effort_estimate: "stub" | "short_entry" | "full_entry" | "multiple_entries"
      # stub: A quick placeholder would suffice.
      # short_entry: A brief 1-2 paragraph entry.
      # full_entry: A complete entity file with relationships.
      # multiple_entries: Requires creating several interconnected entries.
```
```

### 7.4. User Prompt Template

```
## Structural Analysis Results for "{{world_name}}"

**Corpus Statistics:**
- Total lore files: {{total_files}}
- Entity types represented: {{type_count}} of {{total_types}}
- Total relationships: {{total_relationships}}
- Average relationships per entity: {{avg_relationships}}

### Finding 1: Referenced-but-Undefined Entities

{{#each undefined_refs}}
- **{{this.target_path}}** — Referenced by {{this.reference_count}} file(s):
  {{#each this.referencing_files}}
  - {{this}} ({{this.relationship_type}})
  {{/each}}
{{/each}}

### Finding 2: Orphaned Entities (No Inbound References)

{{#each orphaned}}
- **{{this.name}}** ({{this.type}}) — {{this.path}}
  Outbound relationships: {{this.outbound_count}}
{{/each}}

### Finding 3: Low-Connectivity Entities

{{#each low_connectivity}}
- **{{this.name}}** ({{this.type}}) — {{this.total_relationships}} relationships
{{/each}}

### Finding 4: Entity Type Coverage

| Entity Type | Count | Status |
|------------|-------|--------|
{{#each type_coverage}}
| {{this.type}} | {{this.count}} | {{this.status}} |
{{/each}}

### Finding 5: Relationship Asymmetry

{{#each asymmetric}}
- **{{this.name}}** ({{this.type}}) — {{this.outbound}} outbound, {{this.inbound}} inbound
{{/each}}

### Finding 6: Disconnected Topic Clusters

{{#each isolated_clusters}}
- **Cluster:** {{this.tags}} — {{this.entity_count}} entities, no connections to other clusters
{{/each}}

---

Interpret these findings and provide narrative suggestions. Use the YAML output format specified in your instructions.
```

### 7.5. Expected Response Schema

```yaml
suggestions:
  - finding_id: string        # References one of the six analysis categories (e.g., "undefined_ref_1")
    interpretation: string     # Why this pattern might exist
    suggestion: string         # Specific narrative suggestion
    priority: string           # "high", "medium", or "low"
    entity_types_involved: list  # List of entity type strings
    effort_estimate: string    # "stub", "short_entry", "full_entry", or "multiple_entries"
```

### 7.6. Response Parsing Logic

Identical to the general pipeline (§5.6, stages 1-3), with the following additions:

- **Finding ID validation:** Each `finding_id` should reference a finding category from the deterministic analysis. If the LLM invents a finding ID not in the input, it is still included but annotated with `[LLM-IDENTIFIED]` to distinguish it from structurally grounded suggestions.
- **Priority validation:** Must be one of `"high"`, `"medium"`, `"low"`. Unknown values default to `"medium"`.
- **Effort estimate validation:** Must be one of the four allowed values. Unknown values default to `"full_entry"`.
- **Deduplication:** If the LLM suggests the same entity or action in multiple suggestions, merge them into a single suggestion with combined reasoning.

### 7.7. Report Output Format

```markdown
# Chronicle Suggestion Report

**World:** {{world_name}}
**Date:** {{date}}
**Corpus:** {{total_files}} lore files across {{type_count}} entity types
**Provider:** {{provider_name}} ({{model_id}})

---

## Structural Gaps (Deterministic)

### Referenced-but-Undefined Entities

{{#each undefined_refs}}
| Entity | Referenced By | Count |
|--------|-------------|-------|
| `{{this.target_path}}` | {{this.top_referencing_files}} | {{this.reference_count}} |
{{/each}}

### Orphaned Entities

{{#each orphaned}}
- **{{this.name}}** ({{this.type}}) — has {{this.outbound_count}} outbound relationships but nothing references it.
{{/each}}

### Entity Type Coverage

| Type | Count | Status |
|------|-------|--------|
{{#each type_coverage}}
| {{this.type}} | {{this.count}} | {{this.status}} |
{{/each}}

---

## Narrative Suggestions (LLM-Powered)

{{#each suggestions}}
### {{this.priority | uppercase}}: {{this.suggestion | truncate(80)}}

**Finding:** {{this.finding_id}}
**Interpretation:** {{this.interpretation}}
**Suggestion:** {{this.suggestion}}
**Entity Types:** {{this.entity_types_involved | join(", ")}}
**Estimated Effort:** {{this.effort_estimate}}

---
{{/each}}

## Summary

| Priority | Count |
|----------|-------|
| High | {{high_count}} |
| Medium | {{medium_count}} |
| Low | {{low_count}} |

**Total suggestions:** {{total_suggestions}}
```

### 7.8. Error Handling

| Error Condition | Behavior |
|----------------|----------|
| LLM unavailable | Produce the deterministic gap report only (structural gaps section). Append a note: `"LLM unavailable — narrative suggestions omitted. Structural analysis is complete."` Exit code 0 (deterministic analysis succeeded). |
| LLM response unparseable | Include deterministic gaps. Append a note about the LLM failure. Exit code 0 (partial success). |
| Empty corpus (no lore files) | Exit code 2. Message: `"No lore files found. Run 'chronicle init' and add lore files."` |

**Graceful degradation rationale:** Unlike `validate --deep` (which exits with code 4 on LLM failure because the user explicitly requested LLM validation), `suggest` can produce meaningful output from deterministic analysis alone. The LLM adds narrative interpretation but is not essential to the command's core value proposition. Therefore, LLM failure in `suggest` is a degraded experience, not a command failure.

### 7.9. Performance Characteristics

| Metric | Estimate | Notes |
|--------|----------|-------|
| **Deterministic analysis** | < 2 seconds | Graph traversal, pure computation. |
| **LLM input tokens** | ~2,000–5,000 | Depends on corpus size and number of findings. |
| **LLM output tokens** | ~500–2,000 | Depends on number of suggestions generated. |
| **Total LLM requests** | 1 | Single request with all deterministic findings. May split into 2 if findings exceed token budget. |
| **Latency** (local 70B model) | 30–90 seconds | Single inference pass. |
| **Latency** (cloud API) | 5–20 seconds | Faster but incurs cost. |

---

## 8. Feature 4: Draft Stub Generation (`chronicle stub`)

### 8.1. Purpose and Scope

The `chronicle stub` command generates a starter document for a referenced-but-undefined entity. It collects all existing references to the entity across the corpus, sends them to the LLM with context about the entity type and the world's conventions, and produces a draft file with:

- YAML frontmatter pre-populated from existing references (entity type, inferred relationships, tags)
- Markdown body text drafted by the LLM based on reference context
- `canon: false` status (mandatory for all stubs)
- A `machine-generated` tag and a prominent warning banner

Stubs are starting points, not finished products. The human reviews, revises, and promotes the stub when it's ready (D-01 §6.6).

### 8.2. Reference Extraction Strategy

Before invoking the LLM, Chronicle collects all references to the target entity:

1. **Frontmatter references.** Scan all lore files for `relationships[].target` values that match the target entity path. Extract the relationship type, direction, and the referencing entity's metadata.
2. **Body text references.** Scan Markdown body text of all lore files for mentions of the entity name (or likely aliases). Use the entity's expected name (derived from the file path, e.g., `characters/marcus-thane.md` → "Marcus Thane") as the search term. This is a keyword search, not semantic — it catches explicit mentions but may miss indirect references.
3. **Context entities.** For each referencing file, extract its metadata (type, name, canon status, summary) to provide the LLM with context about the neighborhood of the entity graph where the stub will live.

**Reference context object** (passed to the LLM):

```yaml
target:
  path: "characters/marcus-thane.md"
  inferred_name: "Marcus Thane"
  inferred_type: "character"
references:
  - source_file: "factions/iron-covenant.md"
    source_name: "The Iron Covenant"
    source_type: "faction"
    relationship_type: "member"
    relationship_direction: "inbound"    # Iron Covenant lists Marcus as a member
    context_passage: "Marcus Thane, one of the founding members..."
  - source_file: "characters/elena-voss.md"
    source_name: "Elena Voss"
    source_type: "character"
    relationship_type: "ally"
    relationship_direction: "outbound"   # Elena lists Marcus as an ally
    context_passage: "Her longtime ally Marcus Thane helped establish..."
  - source_file: "events/founding-covenant.md"
    source_name: "The Founding of the Iron Covenant"
    source_type: "event"
    relationship_type: null              # Body text mention, not a frontmatter relationship
    relationship_direction: null
    context_passage: "...led by Marcus Thane and two other veterans..."
  - source_file: "locales/thornhaven.md"
    source_name: "Thornhaven"
    source_type: "locale"
    relationship_type: null
    relationship_direction: null
    context_passage: "The district is home to Marcus Thane's workshop..."
```

### 8.3. System Prompt Template

```
You are a worldbuilding assistant for a project called "{{world_name}}". You are generating a draft stub document for an entity that is referenced in existing lore but does not yet have its own dedicated file. The stub will be created as a draft (canon: false) and clearly marked as machine-generated for human review.

## Your Task

Based on the reference context provided, generate:

1. **YAML frontmatter** for the entity, following the schema for the "{{entity_type}}" type as defined below.
2. **Markdown body text** that synthesizes what is known about the entity from existing references into a coherent introductory description.

## Entity Type Schema

The "{{entity_type}}" entity type has the following fields:

**Required fields (all entity types):**
- type: "{{entity_type}}"
- name: string (the entity's canonical name)
- canon: false (always false for stubs)
- summary: string (one-sentence description, prefixed with "[STUB]")
- tags: list (must include "stub" and "machine-generated")

**Type-specific fields for "{{entity_type}}":**
{{entity_type_schema}}

## Rules

- Set `canon: false` — this is non-negotiable for machine-generated content.
- Include "stub" and "machine-generated" in the tags array.
- Prefix the summary with "[STUB]" to make it visually obvious in listings.
- Only assert facts that are directly supported by the reference context. Do NOT invent details, backstory, or characteristics that aren't grounded in existing references.
- Where information is incomplete, use placeholder markers: `"[UNKNOWN]"` for text fields, `null` for optional fields.
- For the body text, write 2-4 paragraphs synthesizing the known information. End with a "## Known References" section listing where this entity is mentioned.
- Include a machine-generated warning banner at the top of the body.

## Output Format

Respond with the complete file content (frontmatter + body) ready to be written to disk. Use standard YAML frontmatter delimiters (---).

Do NOT wrap the output in a code block — respond with the raw file content directly.
```

### 8.4. User Prompt Template

```
## Stub Generation Request

**Target File:** {{target_path}}
**Inferred Name:** {{inferred_name}}
**Inferred Type:** {{entity_type}}

### Reference Context

{{#each references}}
---
**Source:** {{this.source_name}} ({{this.source_type}}) — `{{this.source_file}}`
{{#if this.relationship_type}}
**Relationship:** {{this.relationship_type}} ({{this.relationship_direction}})
{{/if}}
**Context:** "{{this.context_passage}}"

{{/each}}

### Additional World Context

**Entity types in this world:** {{entity_types_list}}
**Tags used in related entities:** {{related_tags}}
**Era/period context:** {{era_context}}

---

Generate the complete stub file (frontmatter + body) for {{inferred_name}}. Follow the schema and rules in your instructions. Remember: only assert facts supported by the reference context.
```

### 8.5. Expected Response Schema

The LLM response for stub generation is not YAML-in-a-code-block — it's the raw file content. The expected format:

```markdown
---
type: {{entity_type}}
name: "{{name}}"
canon: false
summary: "[STUB] {{summary}}"
tags:
  - stub
  - machine-generated
  {{additional_tags}}
relationships:
  {{inferred_relationships}}
{{type_specific_fields}}
---

> **⚠ Machine-Generated Stub** — This entry was generated by Chronicle from existing references. Review, revise, and promote when ready.

# {{name}}

{{body_paragraphs}}

## Known References

{{#each references}}
- **{{this.source_name}}** (`{{this.source_file}}`): "{{this.context_passage}}"
{{/each}}
```

### 8.6. Response Parsing Logic

Stub response parsing is different from the YAML-extraction approach used for other features, because the response IS the file content:

**Stage 1 — Extract frontmatter.** Find the YAML frontmatter block (delimited by `---` on its own line). Parse it with YamlDotNet.

**Stage 2 — Validate required fields.**
- `type` must match the inferred entity type. If it doesn't, override it.
- `canon` must be `false`. If the LLM set it to anything else, override it to `false`.
- `tags` must include `"stub"` and `"machine-generated"`. If missing, add them.
- `name` must be present. If missing, use the inferred name.
- `summary` must start with `"[STUB]"`. If not, prepend it.

**Stage 3 — Validate relationships.** Each relationship in the frontmatter should reference a file that exists in the repository (since the relationship was inferred from existing references). If the LLM fabricates a relationship target that doesn't exist, remove it and log a warning.

**Stage 4 — Validate body text.** Check for the machine-generated warning banner. If missing, prepend it. Check for the "Known References" section. If missing, append it from the reference context.

**Stage 5 — Schema compliance check.** Run D-12 Tier 1 schema validation on the generated frontmatter. If any required fields for the entity type are missing, add them with `null` or `"[UNKNOWN]"` placeholder values. This ensures the stub will pass `chronicle validate` at Tier 1 (though it will still flag as draft content in Tier 3).

**Overrides are non-negotiable:** The `canon: false`, `machine-generated` tag, and warning banner are always enforced regardless of what the LLM produces. These are safety invariants, not suggestions.

### 8.7. Report Output Format

Stub generation output goes to the console (and optionally to the specified file path). The format follows D-13 §7.2's preliminary specification:

```
Chronicle Stub Generator
========================
Entity: {{name}} ({{entity_type}})
References found: {{reference_count}} files reference this entity
{{#each references}}
  - {{this.source_file}} ({{this.relationship_description}})
{{/each}}

Generating stub from context...

{{#if dry_run}}
Preview (--dry-run, file not created):
{{else}}
✓ Stub created: {{target_path}}
{{/if}}
  Type: {{entity_type}}
  Canon: false (draft)
  Status: ⚠ Machine-generated stub. Review and revise before promotion.
  Relationships: {{relationship_count}} inferred
  Tags: {{tags}}

{{#if dry_run}}
--- Begin Preview ---
{{stub_content}}
--- End Preview ---
{{/if}}

{{#if validation_warnings}}
Warnings:
{{#each validation_warnings}}
  - {{this}}
{{/each}}
{{/if}}
```

### 8.8. Error Handling

| Error Condition | Behavior |
|----------------|----------|
| Target file already exists | Exit code 1. Message: `"File already exists: '{{path}}'. Use 'chronicle validate' to check it, or delete and re-run stub."` |
| No references found | Exit code 0, but warn: `"No references to '{{name}}' found in the corpus. Creating minimal stub with placeholder content."` Generate a minimal stub with only required fields and no LLM-generated body. |
| Entity type cannot be inferred | Exit code 2 if `--type` not provided. Message: `"Cannot infer entity type from path '{{path}}'. Use --type to specify."` |
| LLM produces empty response | Generate minimal stub with frontmatter only (from reference context) and `[Content to be written]` as body text. Log a warning. |
| LLM produces content that fails Tier 1 validation | Auto-fix the frontmatter (add missing required fields as placeholders). Log warnings. |

### 8.9. Performance Characteristics

| Metric | Estimate | Notes |
|--------|----------|-------|
| **Reference collection** | < 1 second | File scanning and keyword matching. |
| **LLM input tokens** | ~1,000–3,000 | System prompt + reference context + schema. |
| **LLM output tokens** | ~500–1,500 | Frontmatter + body text + references section. |
| **Total LLM requests** | 1 | Single generation request per stub. |
| **Latency** (local 70B model) | 15–45 seconds | Dominated by text generation time. |
| **Latency** (cloud API) | 3–10 seconds | Faster but incurs cost. |

---

## 9. Soft Axiom Deep Validation

### 9.1. Purpose and Scope

D-12's VAL-AXM-002 rule identifies axiom entries with `enforcement: "soft"` and flags entities that may violate them, but it cannot perform the semantic analysis needed to determine whether a violation actually occurs. That determination requires the LLM.

Soft axioms are the worldbuilding equivalent of guidelines — they state something that is generally true but may have exceptions (e.g., "The Glitch occurred at Year 0 PG" is soft because pre-Glitch artifacts exist as historical relics). The LLM evaluates whether a flagged entity genuinely violates the axiom's intent or falls within an acceptable exception.

**Integration point:** Soft axiom validation runs as part of `chronicle validate --deep`. It is not a standalone command. When VAL-AXM-002 flags entries during Tier 3, those flagged entries are queued for LLM analysis during the `--deep` phase.

### 9.2. Axiom Context Extraction

For each soft axiom flagged by VAL-AXM-002, Chronicle extracts:

1. **The axiom itself.** Full frontmatter (including `assertion_rule` and `note`) and body text.
2. **The flagged entity.** Full frontmatter and body text of the entity that may violate the axiom.
3. **Related context.** Other entities in the same era, with the same tags, or with direct relationships to the flagged entity. These provide the LLM with enough context to assess whether the apparent violation is narratively justified.

### 9.3. System Prompt Template

```
You are a worldbuilding continuity editor for "{{world_name}}". You are evaluating whether a lore entry violates a soft axiom. Soft axioms are guidelines that are generally true but may have legitimate exceptions.

## Your Task

Determine whether the flagged entity violates the soft axiom's intent. Consider:

1. Does the entity directly contradict the axiom?
2. Is the apparent contradiction explainable within the world's narrative (e.g., a historical exception, a deliberate mystery, an unreliable source)?
3. Should the author be alerted to this potential violation?

## Output Format

Respond with ONLY a YAML block inside a Markdown fenced code block.

```yaml
verdict: "violation" | "exception" | "no_violation"
  # violation: The entity genuinely contradicts the axiom.
  # exception: The entity appears to violate the axiom but there is
  #            a plausible narrative explanation.
  # no_violation: The entity does not actually violate the axiom.
confidence: "high" | "medium" | "low"
reasoning: "<Detailed explanation of the verdict>"
narrative_justification: "<If exception: what narrative explanation makes this acceptable?>"
recommendation: "<What the author should consider doing>"
```
```

### 9.4. User Prompt Template

```
## Soft Axiom Evaluation

### The Axiom

**Name:** {{axiom_name}}
**Type:** {{axiom_type}} | **Enforcement:** soft
**Assertion Rule:**
```yaml
{{assertion_rule_yaml}}
```

**Body:**
{{axiom_body}}

### The Flagged Entity

**Name:** {{entity_name}} | **Type:** {{entity_type}} | **Canon:** {{entity_canon}}
**File:** {{entity_path}}

**Frontmatter:**
```yaml
{{entity_frontmatter}}
```

**Body:**
{{entity_body}}

### Related Context

{{#each context_entities}}
- **{{this.name}}** ({{this.type}}): {{this.summary}}
{{/each}}

---

Evaluate whether "{{entity_name}}" violates the soft axiom "{{axiom_name}}". Use the YAML output format specified in your instructions.
```

### 9.5. Expected Response Schema

```yaml
verdict: string              # "violation", "exception", or "no_violation"
confidence: string           # "high", "medium", or "low"
reasoning: string            # Detailed explanation
narrative_justification: string  # Present only if verdict is "exception"
recommendation: string       # Suggested action for the author
```

### 9.6. Integration with VAL-AXM-002

Soft axiom deep validation results are integrated into the deep validation report (§5.7) as findings with the following mapping:

| Verdict | Report Severity | Description |
|---------|----------------|-------------|
| `violation` | `CONTRADICTION` | The entity violates the soft axiom. The author should resolve this. |
| `exception` | `NOTE` | The entity appears to violate the axiom but has a plausible narrative justification. The author should confirm this is intentional. |
| `no_violation` | (omitted) | No finding is generated. The entity passes deep validation. |

---

## 10. Prose-vs-Frontmatter Consistency Checking

### 10.1. Design Decision: OQ-5 Resolution

**Open Question (from D-01):** "Should Chronicle validate the prose content of lore files against the frontmatter metadata, or only the frontmatter?"

**Resolution:** Yes, Chronicle should validate prose-vs-frontmatter consistency as part of `--deep` validation. This is an LLM-powered check that runs alongside contradiction detection (§5).

**Rationale:** Frontmatter and body text are written by the same author but may drift apart over time. A character's frontmatter might say `alignment: "neutral"` while their body text describes them as "a fierce loyalist to the crown." This kind of drift is invisible to deterministic validation (which only checks frontmatter) and invisible to prose-only contradiction detection (which compares between documents). Prose-vs-frontmatter checking fills a gap that neither other approach covers.

**Scope:** This check is performed **per-file** (not cross-file) during `--deep` validation. For each file in the validation scope, the LLM is given the frontmatter and the body text and asked whether they are internally consistent.

**Cost mitigation:** This check can be batched with the contradiction detection requests. When a document is included in a cluster for cross-file analysis (§5), the same LLM request can be extended to include a per-file consistency check, amortizing the request overhead.

### 10.2. System Prompt Template

This check is integrated into the contradiction detection system prompt (§5.3) by appending the following section:

```
## Additional Check: Prose-vs-Frontmatter Consistency

For EACH document in the cluster, also check whether the Markdown body text is consistent with the YAML frontmatter metadata. Common inconsistencies include:

- A character's described behavior contradicting their `alignment` or `faction` fields
- Events described in the body occurring at times that contradict `established_date` or temporal fields
- Relationships described in prose that are missing from or contradict the `relationships` block
- Summaries (`summary` field) that don't accurately reflect the body content
- Entity names or aliases mentioned in prose that differ from the `name` or `aliases` fields

Flag these as:
- CONTRADICTION if the body clearly states something that conflicts with a frontmatter field
- TENSION if the body implies something that seems inconsistent but could be intentional
- NOTE if a frontmatter field could be enriched based on body content (e.g., a relationship described in prose but not in frontmatter)

Use the same output format as cross-file findings, but set both `evidence` entries to the same file (one from frontmatter, one from body).
```

### 10.3. User Prompt Template

No separate user prompt is needed — the prose-vs-frontmatter check is performed using the same document content already provided in the contradiction detection user prompt (§5.4). The system prompt extension (§10.2) instructs the LLM to perform this additional analysis.

### 10.4. Expected Response Schema

Identical to §5.5. Prose-vs-frontmatter findings use the same `findings` list, with `evidence` entries pointing to the same file (one with `location: "frontmatter"`, one with `location: "body"`).

---

## 11. Common Infrastructure

### 11.1. Token Budget Management

Token budgets are managed at two levels:

**Per-request level:** Each LLM request must fit within the model's context window. Chronicle calculates the token count for the system prompt + user prompt and ensures it doesn't exceed `max_input_tokens - max_output_tokens` (reserving space for the response). If the content exceeds the budget, Chronicle applies truncation strategies:

1. **Body truncation:** Reduce Markdown body text length. Preserve the first and last paragraphs (which often contain the most important information) and truncate the middle.
2. **Cluster splitting:** Split large clusters into smaller sub-clusters (§5.2, step 4).
3. **Context reduction:** Remove lower-priority context entities from the prompt.

**Session level:** Track cumulative token usage across all requests in a single command invocation. Log the total token count in the report's metadata section for the user's awareness (especially important for cloud providers where tokens have a monetary cost).

**Token estimation:** Chronicle uses a character-based heuristic for token estimation: approximately 4 characters per token for English text. This is a conservative estimate (actual tokenization is model-dependent) and is used only for budget calculations, not for precise token counting. The actual token counts reported in `LlmResponse` are used for session-level tracking.

### 11.2. Batch Processing Strategy

For features that process multiple clusters or analysis units (contradiction detection, merge analysis), Chronicle uses a sequential batch processing strategy:

1. **Queue all requests.** Build the list of LLM requests (one per cluster, per analysis pair, etc.).
2. **Process sequentially.** Send one request at a time. Wait for the response before sending the next request.
3. **Apply batch delay.** Wait `batch_delay_ms` between requests to avoid overwhelming local inference servers.
4. **Track progress.** Log progress updates to the console: `"Analyzing cluster 3 of 15..."`.

**Why not parallel processing (by default)?** Local inference servers typically run on a single GPU and don't benefit from concurrent requests — they queue internally anyway. Parallel requests would only help with cloud providers, and even then, the user should explicitly opt in via `max_concurrent_requests > 1`.

**Parallel mode (cloud providers):** When `max_concurrent_requests > 1`, Chronicle sends up to that many requests concurrently using `Task.WhenAll` with a SemaphoreSlim. Results are collected and ordered by cluster ID for deterministic report generation.

### 11.3. Response Validation Pipeline

All LLM responses pass through a common validation pipeline before being incorporated into reports:

```
Raw LLM Response
       │
       ▼
┌──────────────┐     ┌─────────────────────────────────────┐
│ Stage 1:     │ NO  │ Log warning. Mark cluster as failed. │
│ Extract YAML ├────→│ Continue with remaining clusters.    │
│ block?       │     └─────────────────────────────────────┘
└──────┬───────┘
       │ YES
       ▼
┌──────────────┐     ┌─────────────────────────────────────┐
│ Stage 2:     │ NO  │ Log raw response (first 500 chars). │
│ Parse YAML?  ├────→│ Mark cluster as failed. Continue.    │
└──────┬───────┘     └─────────────────────────────────────┘
       │ YES
       ▼
┌──────────────┐     ┌─────────────────────────────────────┐
│ Stage 3:     │ NO  │ Apply schema fixups:                 │
│ Valid schema?├────→│  - Default unknown severities to NOTE│
│              │     │  - Add missing optional fields       │
└──────┬───────┘     │  - Log schema deviations             │
       │ YES         └───────────────┬─────────────────────┘
       │                             │
       ▼◄───────────────────────────┘
┌──────────────┐
│ Stage 4:     │
│ Cross-ref    │──→ Flag unverified evidence entries
│ validation   │    Downgrade findings with all-unverified evidence
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Stage 5:     │
│ Deduplicate  │──→ Merge duplicate findings across clusters
└──────┬───────┘
       │
       ▼
  Validated Findings
```

### 11.4. Retry and Timeout Policy

| Parameter | Default | Configurable | Notes |
|-----------|---------|-------------|-------|
| **Request timeout** | 120 seconds | Yes (`timeout_seconds`) | Per-request wall-clock timeout. |
| **Max retries** | 2 | Yes (`max_retries`) | Retries on transient failures only (timeout, connection reset). |
| **Retry backoff** | 1s, 2s, 4s | No | Exponential backoff. |
| **Health check timeout** | 10 seconds | No | Quick check before starting batch. |
| **Total batch timeout** | None | No | No global timeout — individual requests are bounded. |

**Transient vs. permanent failures:**
- **Transient** (retryable): Connection timeout, connection reset, HTTP 429 (rate limited), HTTP 503 (service unavailable).
- **Permanent** (not retryable): HTTP 401/403 (authentication), HTTP 404 (model not found), malformed response (parsing failure).

### 11.5. Logging and Diagnostics

Chronicle logs LLM interactions at the `Debug` log level. When `--verbose` is specified, the following diagnostic information is included in the output:

```
[DEBUG] LLM Health Check: Ollama at http://localhost:11434 — OK (model: llama3.1:70b)
[DEBUG] Deep Validation: 89 files → 15 clusters
[DEBUG] Cluster 1 (3 files, ~2,400 tokens): Sending request...
[DEBUG] Cluster 1: Response received (340 tokens, 18.3s). 1 finding(s).
[DEBUG] Cluster 1: Finding 1 — TENSION: "Elena Voss loyalty inconsistency" (evidence verified: 2/2)
...
[DEBUG] Session totals: 15 requests, 42,000 input tokens, 6,200 output tokens, 4m 12s
```

**Log file:** When `--output` is specified for validation, a companion `.log` file is created alongside the report (e.g., `report.md` → `report.llm-diagnostics.log`) containing the full debug trace including raw LLM responses. This is invaluable for diagnosing unexpected findings or prompt tuning.

---

## 12. Configuration Reference

Complete LLM configuration section for `.chronicle/config.yaml`:

```yaml
# --- LLM Configuration (Phase 4) ---
# Required for: chronicle validate --deep, chronicle suggest, chronicle stub

llm:
  # Provider selection (required for LLM features)
  provider: "ollama"                     # "ollama" | "lmstudio" | "openai" | "anthropic"
  endpoint: "http://localhost:11434"     # Provider API endpoint
  model: "llama3.1:70b"                 # Model identifier

  # Authentication (cloud providers only)
  api_key_env: "CHRONICLE_LLM_API_KEY"  # Env var name (not the key itself!)

  # Token budget
  max_input_tokens: 8192                # Max tokens per request (default: 8192)
  max_output_tokens: 2048               # Max response tokens (default: 2048)

  # Performance tuning
  timeout_seconds: 120                  # Per-request timeout (default: 120)
  max_retries: 2                        # Retry count for transient failures (default: 2)
  temperature: 0.1                      # Sampling temperature (default: 0.1)
  max_concurrent_requests: 1            # Parallel request limit (default: 1)
  batch_delay_ms: 100                   # Delay between sequential requests (default: 100)

  # Deep validation tuning
  deep:
    min_cluster_size: 2                 # Minimum documents per cluster (default: 2)
    max_cluster_size: 8                 # Maximum documents per cluster (default: 8)
    tag_overlap_threshold: 2            # Min shared tags to merge clusters (default: 2)
    include_prose_check: true           # Run prose-vs-frontmatter check (default: true)
    evidence_similarity_threshold: 0.8  # Fuzzy match threshold for passage verification (default: 0.8)
```

**Configuration precedence:** CLI flags > config file > defaults. If the user passes `--llm-endpoint http://localhost:1234` on the command line, it overrides the `endpoint` value in the config file.

---

## 13. Open Questions Resolved

### OQ-5: Should Chronicle Validate Prose Content Against Frontmatter?

**Resolution:** Yes. Prose-vs-frontmatter consistency checking is included as part of `--deep` validation. See §10 for the full specification.

**Rationale:** Frontmatter and body text can drift apart over time. This type of inconsistency is invisible to both deterministic validation (frontmatter-only) and cross-file contradiction detection (between documents). Per-file prose-frontmatter checking fills this gap.

**Scope decision:** This check runs only during `--deep` validation (not during standard `chronicle validate`), because it requires LLM inference. It is enabled by default but can be disabled via the `llm.deep.include_prose_check` configuration flag.

### OQ-D14-1: Should LLM Findings Affect Exit Codes?

**Resolution:** No. LLM findings do not cause exit code 1 (validation failure). The exit code reflects deterministic validation results only. LLM findings are reported separately in the "Deep Validation" section and carry their own severity system (CONTRADICTION/TENSION/NOTE/SUGGESTION) that is distinct from D-12's ERROR/WARNING/INFORMATIONAL.

**Rationale:** LLM findings are inherently uncertain. Making them affect exit codes would mean that non-deterministic, potentially hallucinated findings could block CI/CD pipelines or promotion workflows. The deterministic pipeline (Tiers 1-3) remains the authoritative quality gate. Deep validation is advisory.

### OQ-D14-2: Should `chronicle merge-check` Be a Standalone Command?

**Resolution:** Yes, the merge conflict narrative resolution feature (§6) should be exposed as `chronicle merge-check <target-branch>`. D-13 should be amended to include this command in Phase 4.

**Rationale:** D-01 §6.4 describes this feature but D-13 did not surface it as a named command. The feature is distinct enough from `validate --deep` (which analyzes within a single branch) to warrant its own command.

### OQ-D14-3: What Happens When `suggest` Cannot Reach the LLM?

**Resolution:** Graceful degradation. The deterministic gap analysis runs successfully, and the LLM-powered narrative suggestions are omitted with a note. See §7.8 for details.

**Rationale:** The deterministic graph analysis (§7.2) provides substantial value on its own. Unlike `validate --deep` (where the user explicitly requested LLM analysis), `suggest` has a useful deterministic baseline that shouldn't be blocked by LLM unavailability.

---

## 14. Dependencies and Cross-References

### Upstream Dependencies

| Document | What D-14 Uses |
|----------|---------------|
| **D-01** (Design Proposal) | §6 — LLM Integration Architecture. D-14 implements the four features described in D-01 §6.2–§6.6 and the infrastructure described in §6.7. |
| **D-10** (Lore Schema) | Entity type schemas used in stub generation (§8). Field definitions used in prose-vs-frontmatter checking (§10). |
| **D-11** (Canon Workflow) | Canon status values and their semantics. Apocryphal/deprecated exclusion rules for contradiction detection (§5.3). |
| **D-12** (Validation Rules) | §7 — Tier 3 semantic rules, especially VAL-AXM-002 (soft axiom flag). §9 — Assertion rule types. D-14's soft axiom validation (§9) picks up where VAL-AXM-002 leaves off. |
| **D-13** (CLI Reference) | §5.3 `validate --deep`, §7.1 `suggest`, §7.2 `stub`. D-14 fills the prompt templates and response parsing that D-13 defers. |

### Downstream Consumers

| Consumer | What It Uses from D-14 |
|----------|----------------------|
| **D-13 Amendment** | `chronicle merge-check` command specification (§6), finalized `suggest` and `stub` behavioral details. |
| **Phase 4 Implementation** | All prompt templates, response schemas, parsing logic, and report formats. This is the primary implementation reference for Phase 4 code. |

### Open Question Resolution Traceability

| Question | Origin | Resolution | Section |
|----------|--------|------------|---------|
| OQ-5 | D-01 §10 | Prose-vs-frontmatter checking included in `--deep` | §10, §13 |
| OQ-D14-1 | D-14 (internal) | LLM findings do not affect exit codes | §13 |
| OQ-D14-2 | D-01 §6.4 | `merge-check` is a standalone Phase 4 command | §6, §13 |
| OQ-D14-3 | D-14 (internal) | `suggest` degrades gracefully without LLM | §7.8, §13 |

---

## 15. Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1.0-draft | 2026-02-10 | Ryan + Claude | Initial LLM Integration Specification. Four LLM features (contradiction detection, merge analysis, lore suggestions, stub generation) with complete prompt templates, response schemas, parsing logic, report formats, error handling, and performance characteristics. Soft axiom deep validation. Prose-vs-frontmatter consistency checking (resolves OQ-5). Provider abstraction interface (`ILlmProvider`). Configuration reference. Three design decisions (OQ-D14-1 through OQ-D14-3). |
