---
name: root-cause-first
description: Use when you are about to fix a bug, a failing test, or unexpected behavior in the target repo. Forces a deterministic repro and ranked falsifiable hypotheses BEFORE any code change. Use this on {{BUILDER_SEAT_NAME}} and {{QA_SEAT_NAME}} debugging work. Do not use for green-field feature authoring with no observed defect.
---

# Root cause first

Iron rule: NO FIXES WITHOUT ROOT-CAUSE FIRST. A patch written before you can reproduce the failure on demand is a guess, and guesses burn the 2.5h cap then roll the task back to todo. Work the phases in order; do not skip ahead because the bug "looks like a one-liner."

## 1. Build a deterministic feedback loop — the loop IS the skill
Pick the cheapest harness that turns the bug red on demand, in this preference order:
1. {{TEST_CMD}} (fastest; also becomes your regression test in phase 5).
2. A request against a locally running instance of the stack ({{STACK_DESCRIPTION}}) — e.g. `curl` for an HTTP service.
3. A CLI snapshot (typecheck {{TYPECHECK_CMD}}, build {{BUILD_VERIFY_CMDS}}).
4. {{E2E_HARNESS}} — {{QA_SEAT_NAME}}'s lane, Mode 1 hermetic mock-first by default. Reach for Mode 2 (the live/real-dependency variant) only when the bug is shaped by a live external system — it is slow, may cost money, and is non-deterministic, so assert outcomes not strings and rerun 2-3x before trusting a FAIL.
5. Replay the saved run trajectory/log, if your runtime keeps one.
6. A throwaway harness script — last resort; delete it when done.

## 2. Reproduce
Run the loop and confirm the failure is red and stable. If you cannot make it fail on demand, you do not yet understand it — keep instrumenting; do not patch.

## 3. Hypothesize before touching code
Write 3-5 ranked, FALSIFIABLE hypotheses — each must name the test that would kill it ("if H2 holds, {component} returns {X}; it returns {Y}, so H2 is dead"). A hypothesis you cannot disprove is not on the list.

## 4. Instrument one variable at a time
Change ONE thing per loop run so the signal is unambiguous. Tag every debug log `[DEBUG-{id}]` with a unique {id} so a single `grep` finds and strips them all before you ship — no orphaned debug lines in the diff.

## 5. Regression test BEFORE the fix
Capture the bug as a failing test (prefer phase-1's {{TEST_CMD}}) that goes green only once the fix lands. Test first, then fix — never the reverse. Linking and `in_review` follow the existing `multica-working-on-issues` convention.

## 6. After 3 failed fixes, question the architecture
Three fix attempts that do not turn the loop green means your root-cause model is wrong, not your patch. STOP. A boundary between two subsystems is the usual suspect — a symptom in one layer often originates at the hop into the previous one. Escalate the broken model rather than burning the cap; a rolled-back task helps no one.

## Escalation note — reuse the finding grammar
When you hand a confirmed root cause to a reviewer or block on architecture, state it in the constitution's VERDICT GRAMMAR section — do not invent a second one: `[SEVERITY] (confidence: N/10) {file}:{line} — {what is wrong} | Fix: {concrete suggestion}`. If a memory backend ({{MEMORY_BACKEND_URL_API}}) is wired on your seat, recall and save the root-cause technique so debugging precision compounds across tasks.
