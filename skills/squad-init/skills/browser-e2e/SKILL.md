---
name: browser-e2e
description: Use when {{QA_SEAT_NAME}} must drive a real browser against the target repo's web surface ({{UI_SURFACE}}) with the playwright MCP — supplies hybrid DOM+screenshot grounding, the tiered-locator order, a self-heal loop that ESCALATES instead of weakening assertions, a step cap, and the headless no-clarifying-question contract. Do NOT use for native-channel rendering (that is un-automatable), for API/contract testing (qa.md HTTP oracles), or for scenario-shape / non-determinism metrics (your eager QA scenario contract + eval-harness own those).
---

<!--
Provenance: SYNTHESIZED (not re-authored from one external repo) for a Multica squad from
research/2026-06-27-ai-agents-for-qa-and-testing.md §5D + findings #7/#8, which rest on WebArena
(arXiv:2307.13854), VisualWebArena (2401.13649), SeeAct (2401.01614), Online-Mind2Web (2504.01382),
WebTestPilot (2602.11724), and Practical Limits of Autonomous Test Repair (2605.01471). Wired to the
target repo's real surfaces: the playwright MCP already mounted on the QA seat and the project's own
UI bring-up harness. Subordinated to the QA card's scenario contract (qa.md — scenario shape, PASS/FAIL, two
artifacts, smallest-repro) and eval-harness (determinism split, pass@k/pass^k).
-->

# Browser E2E (grounding + locators + escalate-don't-weaken)

Your scenario list, PASS/FAIL-per-scenario, two-artifacts, and smallest-repro live **eager in your QA card (`qa.md`)**; your non-determinism handling (assert a predicate over k runs, pass@k vs pass^k) lives in **`eval-harness`**. This skill adds only the missing piece: **how to drive a browser reliably** so a UI verdict is grounded, not guessed. Expect a real human-vs-agent gap (web agents sit ~30–50 pts below humans, and *grounding* — intent→correct element — is the wall, not reasoning) → keep the human / strong-judge gate; never claim autonomous full-coverage regression.

## When this mode applies
The target repo's **web surface** ({{UI_SURFACE}}) — NOT native-channel rendering. Drive it with the **playwright** MCP already on your runtime.
- **Mode-1 mock-LLM (DEFAULT).** UI behavior over the harness (routing, state render, ACL-gated views, form→request plumbing). Deterministic → assert exactly.
  - **Bring-up (REQUIRED).** Use {{E2E_HARNESS}}'s dedicated UI bring-up target — the base stack (gateway + mocks) is a separate lane from the UI stack on purpose, so a UI boot failure never gates the non-UI suite. Drive the browser at whatever URL the bring-up reports, and tear down with the matching teardown target.
  - **Identity (REQUIRED for any RBAC assertion).** Dashboard identity is resolved by whatever mechanism {{UI_SURFACE}} names (e.g. a proxy-injected header, a session cookie, a bearer token). A headless browser carries no real identity unless you set it explicitly: seed the target role/identity via the admin-side mechanism your bring-up exposes, then attach that identity to every navigation + XHR the same way the mechanism expects. Without this, "viewer sees X but not Y" — and even a plain authenticated-render assertion — silently passes against the WRONG identity. Do NOT build a browser RBAC deny-matrix if the repo already has one: check whether {{UI_SURFACE}} names an existing RBAC policy test first — a static/fail-closed test there is stricter than a browser can be.
- **Mode-2 real-model** only when the UI's correctness depends on model reasoning (e.g. an agent reply rendered in the UI): {{E2E_HARNESS}}'s live/real-dependency variant. Real cost, non-deterministic → defer to `eval-harness` (predicate over k runs, pass^k=100% on user-facing paths). Keep these suites small.
- This is **distinct from native-channel rendering** (a native messaging surface's own client), which stays un-automatable — a browser does not test a native channel.

## Grounding — feed BOTH channels, never screenshot-only
Give the model the **accessibility tree / DOM snapshot AND a screenshot** for each decision. Screenshot-only grounding collapses on real tasks (≈5–6% on hard sets); the DOM gives stable identity, the screenshot gives layout/visual state. When marking elements for the model, use a **Set-of-Marks** overlay (numbered boxes) so "click element 7" is unambiguous. Assert on **observable DOM/state** (text content, `aria`, a mock-outbound field, a row count), never on pixels.

## Locators — tiered, role-first; LLM only on the break
Resolve every target in this order, stopping at the first that's stable:
`get_by_role` (name/role) → `data-testid` → ARIA (`aria-label`/`role`) → CSS → visible text.
Role/test-id locators survive restyles; text/CSS are last resorts. **Only invoke the LLM to re-ground a locator that actually broke** — cache the healed selector for the rest of the run so you don't re-pay per step.

## Self-heal that ESCALATES, never weakens (the load-bearing rule)
A bounded heal loop is allowed for a *broken locator* (the page changed, the intent didn't). It is NOT allowed to make a red test green by changing what the test checks. **If convergence would require weakening an assertion, broadening a predicate, deleting a step, or dropping a scenario — STOP and escalate, do not weaken.** That is the documented reward-hack anti-pattern (an enterprise self-healing study hit 70% "convergence" but only 10% first-attempt success, with 38% producing no test, via assertion-weakening + test-deletion). This also binds via the constitution's TEST INTEGRITY clause.
- Heal attempts count against your **2-cycle FAIL budget** (your only fuse).
- Escalate through the **existing** paths: a code verdict → {{LEAD_SEAT_NAME}} mention; an environment blocker → the human-MEMBER mention + the one-line unblock command. Invent no new channel (anti-loop).

## Bounds for a headless run
- **Step cap 15–50** per scenario — your runtime has no per-run turn fuse, so cap explicitly and report partial state if you hit it.
- **No-clarifying-question contract.** You are headless; there is no human to answer mid-run. Never pause to ask — make the safe assumption and note it, or escalate via the MEMBER mention.

## Oracle inference
Derive the expected result from the **NL spec + the symbolized GUI elements** (the WebTestPilot pattern): name the elements, state each scenario's expected post-condition as a binary observable per **your QA card's scenario contract (`qa.md`)**. A flaky UI assert is real noise → quarantine per `eval-harness` (rerun, report FAIL only when it reproduces) before counting it.

## Defer
Report in **your QA card's** PASS/FAIL + two-artifacts + smallest-repro format (`qa.md`); take all non-determinism / reliability-metric rules from `eval-harness`. This skill changes only **how you reach the element and the verdict**, not how you list scenarios or report them.
