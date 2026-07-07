---
name: eval-harness
description: Use in non-deterministic testing — Mode-2 real-model or Mode-3 real-platform — when exact-string asserts would flake. Supplies the determinism split (mock = assert exact, real-model = assert a predicate over k runs), pass@k vs pass^k reliability metrics, the grader taxonomy (code / model / human), and baseline-SHA regression framing. Do not use for deterministic mock-LLM scenarios (assert exactly) or for scenario generation (your eager QA scenario contract owns that).
---

<!--
Provenance: re-authored (not copied) from ECC .agents/skills/eval-harness/SKILL.md @ 5b173d2 (affaan-m/ECC, MIT © 2026 Affaan Mustafa). Retargeted for a Multica squad: eval-driven-development methodology becomes the QA seat's framing for NON-deterministic test runs only — the orthogonal-to-scenario-generation piece. Wired to the target repo's real test harness (unit tests, mock-LLM vs real-LLM/real-platform) and subordinated to the QA card's scenario contract (qa.md, which owns the scenario list, PASS/FAIL-per-scenario, two-artifacts, smallest-repro). Dropped: the /eval define|check|report slash commands (Multica has none), the .claude/evals/ storage tree, the Claude-Code session framing, and the allowed-tools frontmatter.
-->

# Eval harness

Your scenario list, PASS/FAIL-per-scenario, smallest-repro, and two-artifacts contract live **eager in your QA card (`qa.md`)** — this skill does not restate them. It adds the missing piece for non-deterministic runs: how to assert a flaky LLM behaves without manufacturing a false PASS or a false FAIL.

## The determinism split (the core rule)
- **Mock-LLM (Mode-1, deterministic).** Output is fixed → assert **exactly**: exact strings, exact tool calls, exact counts. One run suffices, and a flaky assert here is a real bug, not noise.
- **Real-LLM (Mode-2) / real-platform (Mode-3), non-deterministic.** The same input yields different phrasings and tool orderings → **never assert exact strings.** Assert a **behavioral predicate** (did it call `{tool}`? did the reply contain `{required fact}`? did it stay within `{N}` turns? did the ACL hold?) across `k` runs, and report the rate.

## Reliability metrics — report both, with k and n stated
- **pass@k** = "succeeded at least once in k attempts" → for **capability** ("can the agent ever do X"); a reasonable target is a high pass@3.
- **pass^k** = "succeeded in all k attempts" → for anything on a **user-facing or safety path** (no double-send, no secret/PII egress, ACL isolation, idempotent dispatch); the bar is **pass^k = 100%**.
- A behavior that is pass@3 but not pass^3 is **not shippable on a critical path** — say so explicitly. Write `pass^5 = 5/5`, never just "passes."

## Grader taxonomy — pick the cheapest that's sound
- **Code-based (preferred, deterministic):** {{TEST_CMD}}, grep over a saved run trajectory, exit codes, DB/state row checks. Use whenever the success condition is mechanically checkable.
- **Model-based (only for open-ended output quality):** an LLM judges "did the reply answer the question / is the tone right." It is itself non-deterministic → give it a fixed rubric and run it pass@k too; never let a model-grader gate something a code-grader could check.
- **Human:** flag to the product owner through the gate when the call is taste or irreversible risk and no automatable check is sound.

## Regression framing
Pin a **baseline SHA** (last green commit / deployed baseline). A change is a regression if a scenario that passed at baseline fails now — re-run the **same** scenario against both and report `X/Y passed (was Y/Y at {sha})`. This is the {{TEST_CMD}} / {{E2E_HARNESS}} lane the squad already gates on.

## Bind to the target repo
Mode-1 mock-LLM = {{E2E_HARNESS}}'s hermetic default; Mode-2 real-model = {{E2E_HARNESS}}'s live/real-dependency variant; Mode-3 real-platform is the human checklist (no mock). **Never assert wall-clock latency as PASS/FAIL** — record latency and judge the SLO in post-eval (the no-hard-timeout rule). Keep model/API secrets in env; never echo one into evidence.

## Defer
Report results in **your QA card's** PASS/FAIL + two-artifacts + smallest-repro format (`qa.md`). This skill changes **what** you assert (a predicate plus a rate) and **how confident** the result is — not how you report it.
