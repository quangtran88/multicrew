---
name: builder-dev-loop
description: Use while implementing a sub-issue at a judgment point — a repeatedly failing build/test, a needed dependency, a wrong-looking AC (HALT vs push through), or metabolizing the three-panel review. Not for reviewing others' code or spec/planning.
---

# Builder dev loop

Your standing instructions carry the CORE loop (one AC at a time, smallest change, {{TEST_CMD}} green per AC, search-before-adding, the Definition-of-Done gate, and the four-state completion report) plus branch/PR/mention/no-VPS/secrets — do not restate those. This skill is the deep reference for the things that need judgment: WHEN to halt, HOW to metabolize the three-panel review, and WHY the bugfix DoD gate is strict. (The HALT triggers and the panel-metabolization checklist are now also eager in your builder card's steps 5 and 2, so they hold even if this skill is never opened; here they carry their full rationale.) For PR linking, flipping to `in_review`, and serial-vs-parallel sub-issue enqueue, follow the built-in `multica-working-on-issues` skill.

## HALT triggers — set the sub-issue blocked + @mention {{LEAD_SEAT_NAME}}, never push through
Stop and escalate the moment any of these fire: a NEW dependency is genuinely required; the spec is ambiguous and a wrong guess would waste the work; the SAME test or build has failed 3 times in a row (do not flail a 4th); or a pre-existing regression surfaces that your change did not cause. Iron line: if an AC itself looks wrong, comment your reasoning and HALT — never silently mutate the spec, weaken an assertion, or skip a test so your code goes green.

## Receiving the three-panel review — rigor, not sycophancy
When the panel returns verdicts (their grammar and the close marker are defined in the constitution's VERDICT GRAMMAR section — read findings as `[SEVERITY] (confidence: N/10) {file}:{line} — {desc} | Fix: {…}`), metabolize all three independently:
- No "you're absolutely right", no thanks, no agreeing to look agreeable. Re-grep each suggestion against the ACTUAL code before you touch anything.
- When a reviewer is wrong, push back with a quoted `{file}:{line}` showing why — do not implement a fix the code does not need.
- YAGNI-check every "harden this" / "add a check" suggestion against the AC scope before adding it; scope creep fails the surgical-diff gate.
- If a finding is unclear, ask the reviewer before implementing — never guess at what they meant.
- After fixes, re-run the full Definition-of-Done gate before flipping back to in_review.

## Why the bugfix DoD gate is strict (the rationale behind your builder card's gate 3)
- **Committed repro + RED→GREEN paste.** A test that only ever passed is not a fix proof. SWT-Bench shows a test that fails-before / passes-after roughly DOUBLES patch precision over one that only passes-after — so the gate demands the reproducing test be committed in the diff and both runs pasted.
- **Test discrimination.** A new/changed test counts toward an AC only if it would FAIL when the behavior regresses. To check discrimination, reason about it or use a THROWAWAY SCRATCH edit — do NOT mutate-and-restore the working tree (that risks leaving the tree dirty and corrupting the reported count).
- **Test-count fidelity.** Report the pass/fail count from a clean run on the exact PUSHED branch state, never your in-progress tree or a remembered run.
<!-- EARNED:incident-anecdote -->
<!-- ships empty on purpose — the retro/harvest loop fills this from real deliveries -->
<!-- /EARNED -->
If you cannot stand behind the count surviving a fresh clone + {{TEST_CMD}}, it is not DONE.
