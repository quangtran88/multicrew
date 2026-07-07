---
name: repomix-context-scoping
description: Use when the diff plus the modules it touches exceed what you can load in one read — your context-budgeting aid as the architecture reviewer. Plain `npx repomix` CLI that complements this seat's code-graph tool (code-graph tool = targeted caller-impact; repomix = whole-repo packing + token budgeting); `--token-count-tree` to size the surface, `--include` to scope to the diff's blast radius, then carry what you actually packed into an honest File manifest. Do not use for writing code, packing third-party libraries, or as a separate finding lens.
---

<!--
Provenance: re-authored (not copied) from infina-claudekit .claude/skills/repomix/SKILL.md @ 1d662ad (infina-claudekit; MIT-from-upstream yamadashy/repomix, no per-file header). Retargeted for a Multica squad: a generic "pack a repo for an LLM" utility becomes the Architecture reviewer's context-hygiene aid — the one panel seat with the largest window; a plain CLI for whole-repo packing + token budgeting that complements the seat's code-graph tool (code-graph tool does targeted caller-impact, repomix budgets the one-pass read). The value is wired to that seat's existing accuracy guards (the VERIFIED/INFERRED split + the File manifest in its verdict format). Dropped: remote-repo packing, third-party-library security-audit framing, clipboard --copy, the MCP-server mode, multi-LLM token tables, and the references/ companion files (Multica ships only this body).
-->

# Repomix context scoping

You have the largest usable context in the panel — but "largest" is not "unlimited," and a big window invites the exact failure your accuracy guards warn about: *feeling* like you read everything when you read part. This skill keeps your single-pass full-repo+diff read honest by sizing the surface before you read it and scoping the pack to what the diff actually touches.

## Premise (and when this is inert)
`repomix` is a plain command-line tool (`npx repomix`, no global install), **not** an MCP server — it complements this seat's code-graph tool ({{CODE_GRAPH_TOOL}}): the code-graph tool gives targeted caller-impact, repomix budgets + packs the whole-repo read. It needs shell access. If your seat cannot run shell commands, this skill is inert: read the diff directly and still emit an accurate File manifest, explicitly listing the modules the diff references that you could not load.

## Size before you read
```
npx repomix --token-count-tree [{minTokens}]
```
Prints a hierarchical token map of the repo (dirs/files with token counts). Omit `{minTokens}` for the full tree; pass a number like `1000` to hide anything smaller on a large repo. Use it to decide whether the diff's blast radius fits your window, and to spot the token-heavy directories you would otherwise skim and silently under-read.

## Scope to the blast radius, not the repo
Pack only the modules the diff touches plus their callers — never the whole monorepo:
```
npx repomix --include "{globs}" --remove-comments -o {out}.md --style markdown
```
Scope to the blast radius the {{MODULE_GLOBS}} scan already identified, plus any recurring hot-path flow the retro loop has flagged:
<!-- EARNED:blast-radius-globs -->
<!-- ships empty on purpose — the retro/harvest loop fills this from real deliveries -->
<!-- /EARNED -->
`node_modules/` and `dist/` are skipped automatically — repomix both respects `.gitignore` and applies its own default-ignore patterns (which already exclude `node_modules`, `dist`, `.git`, `coverage`).

## The honesty contract (the real payoff)
repomix's run summary tells you exactly which files and how many tokens you packed. Carry that straight into your verdict's **File manifest**: `read = {what you packed and actually read}`; `referenced-but-not-loaded = {modules the diff imports that did not fit}`. A finding on a module you packed and read is **VERIFIED**; a finding on a module that didn't fit is **INFERRED** — never the other way around.

## Security
repomix runs Secretlint and respects `.gitignore`, but never pack `.env`, secrets, or other credential-shaped files. The packed output is an **input to your read** that stays local — it is not an artifact you post in a comment or share externally.

## Defer
This skill only improves the read and the File manifest. Emit findings and your verdict in **your own VERDICT FORMAT** (`## REVIEW VERDICT` … `{{{END-REVIEW}}}`) — it adds no new finding or verdict format. Strictly read-only: packing source to read it never licenses an edit, push, or merge.
