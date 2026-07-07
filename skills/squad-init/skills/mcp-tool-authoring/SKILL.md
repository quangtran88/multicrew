---
name: mcp-tool-authoring
description: Use when a sub-issue adds or changes an MCP tool/server surface — the agent-centric tool-design rules plus the Zod-strict validation and tool-annotation checklist. Always defer current @modelcontextprotocol/sdk signatures to context7 (don't trust memory). Do not use for non-MCP code, or for merely consuming an existing MCP tool.
---

<!--
Provenance: re-authored (not copied) from infina-claudekit .claude/skills/mcp-builder/SKILL.md @ 1d662ad (infina-claudekit; frontmatter declares "Complete terms in LICENSE.txt"; absorbs Anthropic MCP best-practices). This is the EXTRACTED nugget — the design rules + validation/annotation checklist — not the 4-phase from-scratch server tutorial. Retargeted for the Builder seat: fires only when a feature adds an MCP surface; the "verify SDK vs docs" value is delegated to the eager context7 rule (the seat HAS context7). Dropped: the Python/FastMCP track, the WebFetch-the-spec steps (context7 replaces them), the XML eval-file ceremony (kept the read-only-question principle), and all reference/*.md companion pointers (Multica ships only this body — nuggets inlined).
-->

# MCP tool authoring

You're adding an MCP surface. This is the nugget — the design rules and the validation/annotation checklist — not a from-scratch server tutorial. For the **current** SDK shape (`registerTool`, transport setup, types), use **context7** on `@modelcontextprotocol/sdk`; your memory of the API is likely stale, so the eager context7 habit applies here especially.

## Design tools for an agent, not as raw API wrappers
- **Build for workflows, not endpoints.** Consolidate related calls into one tool that completes a task (e.g. check-availability-and-create) instead of mirroring every REST endpoint.
- **Optimize for a small context window.** Return high-signal results; prefer human-readable names over opaque IDs; offer a concise vs detailed mode; cap and truncate large outputs.
- **Make errors actionable.** An error should tell the agent the next move ("no results — retry with `filter={x}`"), not just report failure.
- **Name by how a human thinks about the task;** group related tools with a consistent prefix for discoverability.

## Validate strictly ({{STACK_DESCRIPTION}})
This skill assumes a TypeScript stack; adapt the validation idiom to your stack's equivalent (e.g. Pydantic for Python) if different.
- Define every tool's input with a **Zod schema using `.strict()`** (reject unknown keys); add real constraints (min/max, regex, enums) and a clear description + example per field.
- TypeScript strict mode, **no `any`**, explicit typed `Promise` return values (type the resolved value, never leave it implicit); `async/await` for all I/O; share request/format/error helpers across tools (DRY).

## Annotate honestly — the four hints drive how the host treats the tool
- `readOnlyHint: true` iff the tool only reads. `destructiveHint` (false = additive-only) and `idempotentHint` (true = repeated same-arg calls have no further effect) are meaningful **only when `readOnlyHint` is false** — omit them on a read-only tool. `openWorldHint: true` if it reaches an external system.
- Annotations that don't match behavior (a destructive tool marked read-only) are a **real defect** — set them to the tool's actual behavior.

## Acceptance check before PR
Write ~10 realistic, **read-only**, independently-answerable questions an agent should be able to solve with the tool, and confirm the tool actually answers them — the cheapest signal the surface is *usable*, not merely *present*. Wire the build/test into {{BUILD_VERIFY_CMDS}} + {{TEST_CMD}}; never hardcode API keys or endpoints (env only).

## Defer
PR handoff and the verification gate follow your eager instructions. This skill only covers MCP-surface design and validation.
