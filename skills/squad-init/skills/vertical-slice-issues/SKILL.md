---
name: vertical-slice-issues
description: Use when {{LEAD_SEAT_NAME}} must (1) check a backlog doc is execution-ready and (2) decompose it into turnkey, risk-routed sub-issues for {{BUILDER_SEAT_NAME}}. Supplies the Definition-of-Ready gate, the tracer-bullet vertical-slice method, and the writing-plans bar (exact files + change-per-file + AC-ids + verify command, zero placeholders) that makes a focused Builder safe (it removes judgment from the slice and keeps each slice reviewable — independent of the Builder's model strength). Do not use for product discovery, tech design, or implementation — those happen upstream in native Claude Code.
---

<!--
Provenance: re-authored from mattpocock skills/engineering/to-issues/SKILL.md @ 694fa30 (MIT, © Matt Pocock), with the writing-plans bar folded in (superpowers writing-plans: no placeholders, exact paths, exact change per file, verifiable success criteria, ordered steps). Retargeted for an execution-only Multica squad: discovery is UPSTREAM (native Claude Code → a ready backlog doc), so the squad starts at execution. This skill is the Lead's Phase-1 (readiness) + Phase-2 (decompose) method. A turnkey plan is what makes a focused Builder safe independent of model strength — hence the writing-plans bar below is mandatory, NOT "describe behavior, avoid file paths".
-->

# Readiness check + turnkey decomposition

You are {{LEAD_SEAT_NAME}}. The issue body is a backlog doc built upstream in native Claude Code. Run the readiness gate first, then decompose. No product interview, no PRD, no tech-design happens here — if the doc isn't ready, bounce it, don't fill the gap.

## Phase 1 — Definition-of-Ready (the one gate at the front)
Accept the doc only if it carries ALL six. Check each explicitly:
- [ ] **Problem + Solution** — the intent and why.
- [ ] **Scope + Non-goals** — the boundaries.
- [ ] **Success Criteria** — verifiable, pass/fail (the acceptance criteria).
- [ ] **Changes** — the files/areas to touch + the change intent per area.
- [ ] **Constraints / guardrails / behavior changes** — the must-not-haves.
- [ ] **Verification** — how to test / expected outputs.

If a field is missing: post ONE `not-ready: needs {X}` comment, set the issue `blocked`, member-mention the human, and STOP — the doc goes back to native Claude Code. Never open a discovery interview on the board to fill it; that bounce rule is what keeps the board execution-only.

## Phase 2 — Decompose into turnkey, risk-routed vertical slices

### The method — tracer-bullet vertical slices
Each sub-issue is a **thin vertical slice through ALL layers end-to-end** (schema → extension/API → channel/dashboard → tests), not a horizontal slice of one layer. A completed slice is demoable/verifiable on its own. **Prefer many thin slices over few thick ones.** A slice that only adds a DB column, or only a UI with no backing behavior, is horizontal — re-cut it into a narrow-but-complete path. All slices share the SINGLE feature branch you cut from `{{BASE_BRANCH}}` (`{{FEATURE_BRANCH_PATTERN}}`); each slice's own working branch + PR title carry its sub-issue id for traceability (no GitHub App auto-links anything).

### Parallel-safe sets (the "waves") — file- AND behavior-disjoint
The slices fired at `todo` together are a **parallel-safe set**. Two slices may share a set ONLY if they are **file-disjoint** (no shared file) *and* **behavior-disjoint** (neither reads the other's output). If two slices touch the same file, or one depends on the other's result, the second is **`Blocked by` the first** — it parks at `backlog` and is promoted when its blockers clear. This is the conflict guard on the shared integration branch and holds whether builds run serial or parallel. Prefer cutting slices so each set is wide (more parallel-safe slices) but never at the cost of disjointness. Lay the sets out in dependency order; the parallel-safe set at any moment is simply "every slice at `todo` with no open blocker."

### The writing-plans bar (mandatory — this is what makes a focused Builder safe)
A weaker implementer is safe only when the plan removes the judgment. Every sub-issue body MUST carry, with ZERO placeholders:
- **Feature branch** — the exact branch to work from.
- **Files to touch + the change per file** — name the exact paths and state what changes in each (a new function, a wired call site, a new test file). This is the load-bearing change from the old "describe behavior, avoid file paths" rule: a turnkey plan names them. Exception: inline a decision-rich snippet (a schema, state machine, reducer, type shape) only as a decision record, not a working demo.
- **Acceptance criteria** — the atomic, testable AC-ids from the backlog doc's Success Criteria that THIS slice satisfies. They are the Builder's per-AC loop and {{QA_SEAT_NAME}}'s scenario seeds. Use stable ids (`AC-1`, `AC-2.3`); if the doc didn't number them, number them here and keep the mapping.
- **The verify command** — the exact one command the Builder runs to prove the slice (e.g. {{TEST_CMD}} scoped to the changed test, or {{TYPECHECK_CMD}}). No "verify it works".
- **Risk route** — pre-tag the slice with the reviewer set the Lead's risk-routing matrix yields for its expected diff (Security / Contract / Architecture / docs-config-auto). So the bench summon is already decided before the PR opens.
- **Blocked by** — the blocking sub-issue id, or "None — can start immediately".

### Enqueue
Lay out the WHOLE plan in one pass, in dependency order (a "Blocked by" can only cite an id that already exists). For the enqueue mechanics — `multica issue create`, `--status todo` (fires now) vs `backlog` (parked), promotion via `multica issue status {child-id} todo`, and the no-double-trigger rule — follow the built-in `multica-working-on-issues` skill; do not restate them.

### AFK vs HITL
Every enqueued slice must be **AFK** — the Builder can implement it and open a PR with no human decision mid-flight. A **HITL** decision (architecture/product) at decompose time is a smell: discovery was supposed to settle it upstream. If a genuine new decision surfaces, set the parent `blocked` and member-mention the human — do not guess and enqueue.

## Self-review before enqueue
- Granularity right? (re-split anything thick; merge anything that can't stand alone)
- Dependency edges correct and acyclic?
- **Set-consistency (the dependency-matrix stop-rule):** every `Blocked by` id exists and resolves to a slice in an EARLIER set; no two slices in the SAME parallel set share a `Blocked by` edge to each other; no two slices in the same set touch the same file (re-order via `Blocked by` if they do). Don't emit the plan until all three pass.
- Every slice AFK, with exact files + change-per-file + AC-ids + verify command + risk route?
- Each slice independently demoable/verifiable?

Do not modify or close the parent issue — it stays assigned to you and drives the rest of the pipeline.
