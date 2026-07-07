# Capability classes — model resolution + roster tiers (design §5)

**What this is.** The rules P0/P3 use to resolve each seat to a model, verbatim from design §5. **Models are
NEVER hardcoded.** P0 probes the account catalog (`reference/engine-probe-checklist.md` hole 2) and resolves
each seat to a *class*; P3 proposes the concrete `{{SEAT_MODELS}}` and the owner gives an explicit go. This
is a provenance/method doc, so donor model names appear only as illustrations of a class — they never ship
as a filled value.

---

## The five capability classes

Each seat resolves to exactly one class. The class rule ranks the live catalog; it does not name a model.

- **judgment-class** (Lead, Mentor, Coach) — the **top reasoning model** in the catalog.
- **1M-coder-class** (Builder) — **context ≥ 256k ∩ strong SWE ∩ cost-favorable** (a coding model that can
  hold a large working set without burning the judgment-tier budget).
- **reviewer-class** (Security / Contract / Architecture / QA) — must span **≥ 2 model families**; **default:
  the strongest reviewer family goes to the binding-veto seat** (see below).
- **validator-class** — **read-only judgment** (a sonnet-class model suffices; this seat grounds a doc, it
  doesn't write code).
- **cheap-watchdog-class** (Monitor) — the **cheapest model that passes a 1-shot instruction-follow check**
  (it detects and pokes; it decides nothing, so it must only follow instructions reliably, not reason).

---

## The cross-family reviewer rule (the load-bearing invariant)

At **STANDARD/FULL** init, the installer **REFUSES** if the reviewer bench cannot span **≥ 2 model families
distinct from the Builder/Lead family**. The thesis: Builder and Lead sharing a model family means shared
blind spots, and a single-family bench lets one blind spot pass both binding vetoes. With two binding vetoes
(Security + Contract), keep them in **different families**. Every seat pins an explicit model — the squad has
no `.fast/.default/.ultra` tier routing.

**Strongest-family-to-binding-veto default.** The strongest reviewer family is assigned to the binding-veto
seat by default. This bakes the P3 "stakes-inversion" lesson (don't run your binding veto on your weakest
reviewer) as a default rather than an interview question — **overridable at the P3 proposal**, never asked at
init. *(The donor deliberately runs the inverse — a binding Security veto on the weaker PinchBench model
while the Contract floor runs the stronger `qwen3.7-max` — as a family-diversity choice pending an A/B
window; that inversion is a donor decision, not the skeleton default.)*

**MIN's explicit waiver (R5).** MIN-VIABLE has a single reviewer (the Contract floor), so it **structurally
cannot** satisfy the ≥2-reviewer-family guarantee. Therefore the cross-family REFUSE is **scoped to
STANDARD/FULL only**; MIN **explicitly waives** the cross-family thesis, and the RUNBOOK **states the
forfeit** in plain language (the MIN squad accepts single-family blind-spot risk as the cost of a 3-seat
roster). MIN is not un-instantiable and the guarantee is not vacuous — it simply does not apply where it
cannot hold.

---

## Roster tiers

| Tier | Seats | Adds |
|---|---|---|
| **MIN-VIABLE** (3) | Lead + Builder + Contract-floor reviewer | constitution + `_reviewer-common` prepend still assembled; `route.sh` Contract-floor + docs-allowlist; 7 MIN skills; **NO watchdog seat** (Lead reconciler only), no QA, no harvest loop; single-family bench — **cross-family REFUSE waived** (R5) |
| **STANDARD** (7) | + QA, Security (binding veto), Architecture, Monitor | full route globs; drift MCP + autopilot lanes; STD skills + scan-conditional skills; watchdog autopilot; **+ MCP-usage prune sweep** (so broad-then-prune actually prunes — F12) |
| **FULL** (10 + Helper) | + Validator (Phase 1.5), Mentor, Coach (opt-in) | skill-harvest + review-quality-metrics + squad-measurement — the loop that earns everything else; control-issue ledger; Validator ships behind its §6b sunset tripwire |

---

## Byte caps (adversarial F3)

The donor's cap table is hand-tuned `AC-*` literals with a silent `*)25000` fallback — a `SEAT_PREFIX`
change would route every seat to the generic 25000 cap: silently loosened for the nine smaller seats,
FALSE-FAILING the two above it (Techlead 42000, Coach 38000) (R13 nuance). Template form: caps are
**measured at init** (assembled size + ~5% headroom), written into the manifest, keyed by manifest seat-id;
an unrecognized seat **fails closed**; P4 additionally asserts every assembled card against the platform
instruction-size hard limit (probed at P0, `reference/engine-probe-checklist.md` extra probe A), and the
init linter **hard-fails** by default. The delete-before-add rule ships verbatim in the generated script.

---

## §10.2 — OPEN decision: ambient-registry runtimes on binding-veto seats

Recorded as **OPEN** (owner decides at build time or per-squad), with both options stated. The tension:
ambient-registry runtimes (e.g. antigravity) mount their MCP in `~/.gemini` — a registry owned by no script,
whose skill-load is unauditable by the per-seat provisioning path
(`reference/engine-probe-checklist.md` hole 8). So: is such a runtime eligible for a **binding-veto** seat?

- **Option A — accept, with the presence-assert made fatal.** Allow an ambient-registry runtime on a
  binding-veto seat, but make the ambient-server presence assertion (agentmemory / gitnexus / fff registered)
  a HARD launch gate rather than a warning, so an unconfigured ambient registry refuses to launch instead of
  silently reviewing cold.
- **Option B — restrict binding vetoes to fully-auditable runtimes.** Only runtimes whose MCP + skill load
  is script-auditable (claude / opencode per-agent config) may hold a binding veto; ambient-registry runtimes
  are limited to weighted/advisory seats (e.g. the Architecture coherence flag, which is weighted, not a hard
  veto).

The design does not pick one; it records the decision as owner-owned. *(Donor context: the Architecture seat
runs on antigravity but holds only a WEIGHTED coherence flag, not a binding veto — consistent with Option B,
but the choice is left explicitly open.)*

---

## Resolution flow (where each rule fires)

1. **P0** — probe the catalog; rank candidates per class; **REFUSE** if <2 reviewer families distinct from
   Builder/Lead (STANDARD/FULL; MIN waives). Stamp RE-VALIDATE banners.
2. **P3** — propose `{{SEAT_MODELS}}` by class with the binding-veto-gets-strongest default + a per-run cost
   estimate; owner gives an explicit **go** on tier + models + cost (and may override the strongest-family
   default or resolve §10.2 here).
3. **P4** — measure and assert byte caps; hard-fail on overflow or a card over the platform instruction-size
   limit.
