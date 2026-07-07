---
name: safe-refactor
description: Use when a sub-issue is a refactor/restructure/extract/rename — a tool-agnostic safety discipline: map the blast radius with grep, gate on test coverage (NONE blocks an aggressive refactor — add characterization tests first), change in small steps, verify after each ({{TYPECHECK_CMD}} + {{TEST_CMD}} + {{BUILD_VERIFY_CMDS}}), never commit a broken tree. Do not use for new features or any behavior change.
---

<!--
Provenance: re-authored (not copied) from oh-my-openagent packages/shared-skills/skills/refactor/SKILL.md @ 6ca975e (code-yeongyu/oh-my-openagent). LICENSE NOTE: OmO ships under a restrictive "Sustainable Use License" (internal-business / non-commercial use permitted; redistribution restricted) — NOT MIT. This draft re-authors the *method* in its own words for internal squad tooling (permitted internal use); no source text is copied. Trimmed to a tool-agnostic discipline (grep for impact, tests for safety) since not every seat has a code-graph tool mounted — that tool hook is noted as optional-if-present, never required. Dropped: the entire team-mode addendum (~140 lines, team_create/refactor-squad), call_omo_agent/explore/plan/oracle/librarian subagents, AskUser clarifying-question menus, and the TodoWrite/6-phase ceremony.
-->

# Safe refactor

A refactor changes structure **without changing behavior** — so the entire discipline is proving behavior is preserved at every step. Stay surgical: every changed line traces to the refactor's stated target; don't "improve" adjacent code, comments, or formatting.

## Tooling
Your tool inventory lives in your seat card's MCP paragraph. For blast radius, lean on your code-graph tool ({{CODE_GRAPH_TOOL}}) `impact`/`context` (pass `repo: "{{REPO_ABS_PATH}}"`; the index is a baseline commit, not your worktree — confirm exact lines against your files), cross-checked with a repo-wide grep; tests still prove safety. If no code-graph tool is mounted, this discipline degrades to grep-only blast-radius mapping — same rigor, no shortcuts.

## The loop
1. **Map the blast radius.** Enumerate every reference to the symbol/module you're touching — {{CODE_GRAPH_TOOL}} `impact({target, direction:"upstream"})` + `context({name})` for the call graph, cross-checked with a repo-wide grep — plus the import paths that resolve to it. Note callers **outside** the slice's files; a rename that misses one is the classic find-and-replace bug. The "never rename with find-and-replace" rule means doing this enumeration *deliberately* — not blindly `sed`-ing.
2. **Gate on coverage — BEFORE editing.** Run the existing tests for the blast radius ({{TEST_CMD}} scoped to the touched paths). Classify: solid coverage → proceed; thin or none → **STOP and add characterization tests that pin the CURRENT behavior first.** This is the iron rule — an aggressive refactor with no tests is reckless. Lock behavior green, *then* change. No "I'll add tests after."
3. **Change in small, independently-verifiable steps.** One structural move at a time — extract one function; rename one symbol everywhere; collapse one duplication. Never a big-bang rewrite.
4. **Verify after EACH step** — the typecheck + tests covering your blast radius: {{TYPECHECK_CMD}} and {{TEST_CMD}} always (plus the project's e2e lane where behavior changed). Add {{BUILD_VERIFY_CMDS}} **only** if the touched module has its own build step, and lint/format only where that module defines one — most modules gate on typecheck + tests, not a build. Green before the next step. A red step is reverted and diagnosed, not patched over.
5. **Never commit a broken tree.** Size each commit to one logical move with a clear message.

## Stop conditions
- Zero coverage on the target and you cannot characterize it safely.
- The change would alter a public contract or observable behavior — that's a **feature, not a refactor**; kick it back to the spec.
- Three consecutive verification failures → STOP, report with evidence, don't thrash.

## Deprecated APIs found mid-refactor
Don't auto-upgrade libraries. Confirm the modern replacement via `context7` first, and migrate only if the slice asked for it.

## Defer
PR handoff (post the PR + `pr_url` metadata + `in_review` + the leader mention link, then STOP) follows your eager instructions. This skill only governs how you make the change safely.
