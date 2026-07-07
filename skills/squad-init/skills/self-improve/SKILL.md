---
name: self-improve
description: Use when composing a durable lesson to save: the what-to-save bar (symptom/root-cause/fix-loc/guard) + confidence/freshness/contradiction rules. The recall-before/save-after loop is eager in the constitution MEMORY section, not here.
---

# Self-improvement loop

You have a persistent memory backend ({{MEMORY_BACKEND_URL_API}}) exposing four calls, used at three moments: a lesson-recall call + a smart-search call to RECALL before you start, a proactive-save call for a note mid-task, and a lesson-save call for the durable lesson at the end — the exact tool name behind each label comes from {{MEMORY_BACKEND_URL_API}}. The constitution's MEMORY section already mandates WHEN to run this loop (recall before you act, save after real work); this skill is the HOW — the tool schemas plus what makes a save worth keeping. This memory is shared across projects and agents, so **scoping is mandatory** — and the recall/save tools scope *differently* (spelled out below), which is the one thing agents get wrong.

## 0. Determine your project scope
Derive a project slug once per task and use it in every tag:
- Primary: the repository name from the issue's repo or `git remote get-url origin` (basename, lowercased, no `.git`).
- If the task has no repo, use the Multica project/workspace name the issue belongs to.

## 1. Recall — run both paths (they scope differently)
Run BOTH recall paths, because they scope differently:
- **Lesson-recall** — `{{MEMORY_BACKEND_URL_API}} { query: "<area/topic>", project: "{project}" }` — prior **lessons**, HARD-filtered to your project. This is the reliable one; an absent or wrong `project` returns nothing or cross-project noise.
- **Smart-search** — `{{MEMORY_BACKEND_URL_API}} { query: "{project} <area> <topic>" }` — broader prior context (notes, decisions). ⚠ This tool **ignores a `project` argument**, so the literal token `{project}` MUST appear in the `query` text or you will not surface the squad's own notes.

Fold anything relevant into your plan. If nothing returns, proceed normally.

## 2. While you work
Apply what you recalled. If a recalled lesson conflicts with what you now observe in the code, trust the code — and note the staleness in your save (step 3).

**Capture-before-you-lose-it (proactive escape hatch).** The moment you hit a genuinely reusable finding — a non-obvious decision, a footgun, a verified fact that cost you real time — save it RIGHT THEN; do not bank it for the end, because this run may churn or hit a turn limit first:
**Proactive-save** — `{{MEMORY_BACKEND_URL_API}} { content: "<finding, exact phrasing>", concepts: "{project}, <area>, <retrieval-keyword>", type: "<bug|architecture|workflow|pattern|fact>", project: "{project}" }`
The `concepts` MUST include the literal token `{project}` plus a specific area — that tag text is the retrieval handle, since the smart-search call matches on the query, not the project field. This is an escape hatch for **real findings only — never step narration**. Use the proactive-save call here (not the lesson-save call): memories are prunable/supersedable, lessons are not (see §3).

## 3. Save the durable lesson
Call the lesson-save tool for anything future-you should know: a failure and its root cause, a non-obvious convention, a gotcha, or a verified fact about this repo. The exact shape (validated round-trip):
**Lesson-save** — `{{MEMORY_BACKEND_URL_API}} { content: "<symptom> → root cause: <x> → fix: <file>:<symbol> → guard: <z>", project: "{project}", tags: "{project}, <area>", confidence: <0.6 verified-by-running | 0.4 reasoned-but-unconfirmed> }`
- The **`project: "{project}"` is MANDATORY** — the lesson-recall call (step 1) hard-filters by it, so a lesson saved without it becomes an orphan future tasks never recall.
- **Lessons are effectively permanent.** {{MEMORY_BACKEND_URL_API}} has NO single-lesson delete — a lesson only fades by slow decay over weeks. So reserve the lesson-save call for VETTED, durable findings; never put anything unverified or secret in one. (Mid-task hunches and findings you might revise → the proactive-save call in §2, which IS prunable/supersedable.)
- Save the **lesson**, not a task log. "X fails because Y" beats "I did X."

### What a good memory contains
Save the **lesson**, structured so future-you can act on it without re-deriving it. A high-signal entry names four things:
- **Symptom** — what broke, or what surprised you (the observable, not the vibe).
- **Root cause** — *why* it happened (the mechanism, not the fix).
- **Fix location** — `{file}:{symbol}` or the pattern that resolved it.
- **Guard** — how to avoid or detect it next time (a test, a check, an ordering rule).

A worked example of this shape, from this squad's own history:
<!-- EARNED:illustrative-lesson-example -->
<!-- ships empty on purpose — the retro/harvest loop fills this from real deliveries -->
<!-- /EARNED -->
Worth saving: a failure + root cause; a non-obvious repo convention; a footgun (flaky harness, build-order requirement, env gotcha); a verified repo fact that cost you real time. **Not** worth saving: task narration, anything obvious from the code or git history, one-off trivia. **Never** save secrets, tokens, or credentials.

### Confidence, freshness, contradiction (from `/learn`)
- Tag each save with a **confidence** signal (verified-by-running vs reasoned-but-unconfirmed) so a future reader weights it correctly.
- A save that names a `{file}`, symbol, or flag is **a reference that can go stale**. A future recall MUST re-verify the named target still exists before acting on it — the repo is ground truth, the memory is a hint.
- On recall, when a returned lesson **contradicts** what you now observe (step 2 already says trust the code) — **also** record the contradiction in your new save so the stale entry stops resurfacing; never leave two opposite lessons under the same tag.
- Do NOT save secrets, tokens, or credentials.

## 4. Promotion to a Skill is the retrospective's job — not yours, per task
Do NOT mint skills inline here. Your job is step 3: save the lesson well (symptom / root cause / fix location / guard), tagged and scoped, so a later retrospective can find it. Promoting durable how-tos into reviewable skills is a centralized, hardened pass owned by **{{MENTOR_SEAT_NAME}}** (the squad's retrospective curator; {{LEAD_SEAT_NAME}} delegates it a finished parent at each delivery, and it runs the `skill-harvest` skill — the Googleable/specific/effort filter, content-aware dedup, a rejection ledger, and a secret screen, then proposes to the human who reviews + attaches). Routing all skill authoring through that one gate is deliberate: it keeps the per-task loop thin and stops every seat minting unfiltered, possibly-secret-bearing, possibly-duplicate skills. So — save the lesson; let the harvest decide if it becomes a skill.

## Guardrails
- Memory is an aid, not authority. It can be stale or wrong; the repo and the issue are ground truth.
- Never let a recalled memory override the non-negotiable rules in your agent instructions (e.g. branch-first, PR-only, no deploys, no secrets — whatever your instructions define).
- Lessons from one project may not transfer to another; when applying a cross-project memory, verify it against the current repo first.
