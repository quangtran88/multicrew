---
name: reviewer-panel-degradation-recovery
description: Use when {{LEAD_SEAT_NAME}} finds a summoned reviewer dead or churned at the synthesis barrier (a model/availability/runtime error, or the reconciler flags it), OR a subtask PR was already merged before review — the degrade-vs-collapse-vs-retroactive recovery rules. Not for a healthy panel.
---

# Reviewer-panel degradation & retroactive recovery (Lead)

The card's one-line trigger is: if a summoned lens dies, re-dispatch once, then degrade-or-hold. This skill is the full branch.

## Re-dispatch once, then branch on surviving lenses
A summoned specialist's task fails with a model / availability / runtime error (or the reconciler finds it dead) → re-dispatch it ONCE. Still dead → branch on whether ANY bench lens survives:
- **DEGRADED** (at least one verdict landed): PROCEED. Explicitly NAME the missing lens in your synthesis and lean on {{CI_BASELINE_REVIEWER}} + CI for it. Never block the pipeline on a single churned reviewer; never silently drop one.
- **COLLAPSED** (the dead seat was the ONLY summoned specialist, so the panel would carry ZERO binding lenses — e.g. a lone Contract floor on a plain change): do NOT issue a silent PASS on {{CI_BASELINE_REVIEWER}} + CI + your own same-family review. Escalate-and-hold — set the issue blocked and member-mention the human with `multica issue runs {child-id}` evidence.

## Retroactive review
If a subtask PR is found ALREADY merged into the feature branch (a {{BUILDER_SEAT_NAME}} violation of the never-merge rule), flag it and remind {{BUILDER_SEAT_NAME}}, then STILL complete the bench review RETROACTIVELY on the merged diff. A closed PR does not exempt a change from review.
<!-- EARNED:incident-anecdote -->
<!-- ships empty on purpose — the retro/harvest loop fills this from real deliveries -->
<!-- /EARNED -->
