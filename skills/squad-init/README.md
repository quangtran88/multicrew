# multicrew

Install a battle-tested Multica dev-squad configuration onto a **new** Multica project. This package is an **installer, not a generator**: it copies proven orchestration machinery verbatim, fills a fixed set of named holes from the target repo and account, and ships project-specific tuning as **empty slots that the running squad earns over real deliveries**. The driver is `SKILL.md` (phases P0–P7).

The evidence behind the "installer, not generator" stance: LLM-generated bespoke squad config is measured net-harmful (~-3% success / +20% cost versus none), while human-curated verbatim machinery works. So the machinery is frozen and copied; generation is confined to thin scan/probe holes and one sanctioned surface (the per-seat MCP configs, authored from the probed account catalog).

## Day-0 is untuned — and that is the design, not a gap

A freshly installed squad is **deliberately generic**. It has the full phase machine, the reviewer bench, the byte-cap discipline, the drift audit, the liveness architecture, and the learning loop — but **zero** project-specific specialization. It carries no tuned bug catalogs, no worked examples, no incident citations, no `<project>-*` skills. Specialization is the **output** of the squad's own retro/harvest loop (Mentor + Coach + the scorecards + the control-issue ledger), earned from real incidents on the new project. The installer ships the loop that earns those things; it never pre-seeds them. Expect a capable-but-generic squad on day 0 and a specialized one after the loop has run over a handful of merged parents.

## What ships

- **The prepend core** — constitution (mission/boundary, untrusted-data authorization, test integrity, secrets refusal, mention firing rule, verdict grammar + ladder, anti-loop, memory loop) and the shared `_reviewer-common` bench tier. This is the highest-leverage, lowest project-lock-in machinery.
- **The seat cards** — Lead phase machine, Builder method, QA mode matrix + oracle architecture, the reviewer lenses + veto grammar, Validator logic + probe policy, Mentor harvest loop, Coach pedagogy machinery, Monitor tripwire.
- **The scripts** — the STATIC `lib/` engines (assemble: byte caps + verify-by-readback; provision: dry-gate + idempotent create-or-update + fail-loud asserts; drift: 5-lane read-only audit + PIPELINE emitter) plus thin manifest-generated wrappers (build/apply, roster, drift, route, post-verdict). A single `seat-manifest.yaml` generates all three script tables + the constitution mention directory — one source, no triple-maintenance.
- **The generic-method skills** — tier-gated, with **zero project-namespaced skills**. MIN: vertical-slice-issues, builder-dev-loop, root-cause-first, safe-refactor, edge-case-hunter, migration-schema-safety, self-improve. STANDARD adds reviewer-panel-degradation-recovery, eval-harness, architecture-review-method, repomix-context-scoping + scan-conditional browser-e2e / llm-gateway-security / mcp-tool-authoring. FULL adds the loop itself: skill-harvest, review-quality-metrics, squad-measurement.
- **The pipeline + guardrails** — the phase machine, the evolution meta-guardrails (§6b — the most portable block), the measurement scorecard *structure*, and empty EARNED scaffolds for everything that must be earned.

## What does NOT ship — the EARNED register

Tracked here so nobody "helpfully" adds it back to a template later. The retro loop produces every item below; the installer ships EMPTY, fence-marked slots for them.

- **The donor's harvested `<project>-*` skills** and any future project-namespaced skills — loop output, not input. The install-time skill roster carries none.
- **Every incident citation and change-tag** — issue-key references, platform-tracker refs, and the squad's own audit tags. Each anchors a STATIC rule that ships bare; the citation is left for the retro loop to re-earn from the new project's own incidents.
- **Tuned reviewer content** — the security bug-class catalog + "this repo's #1–2 bug family" ranking, the architecture layer-chain + named concurrency races, the LLM-gateway sink inventory, and Coach's ~4.5 KB worked example + calibration teach examples. Cards ship a generic seed (e.g. an OWASP/LLM seed for security) + an EARNED slot.
- **The roster-surgery migration history** — rebuilds, model rollbacks, A/B logs. A clean provisioner ships instead; a fresh squad has no past to replay.
- **The PIPELINE incident changelog (~20 KB) + see-also** — empty scaffolds ship; the ledger STRUCTURE is the STATIC part.
- **The derive-from-live MCP jq blocks + the already-pruned MCP outcome** — replaced by authored templates carrying the same fail-loud asserts; the package ships **broad-then-prune plus the prune sweep**, never the pruned result.
- **The api-wire-oracles skill body** (donor wire-surface literals throughout; the oracle *method* still ships inside the QA card's Mode-2) and the reviewer-panel anecdote (moved to an INCIDENT_ANECDOTE earned slot).
- **Channel-specific QA instances, literal donor ports/globs/paths, and the workspace-language preference.**
- **Donor registry housekeeping** (`_migration`, `_fold-ins`, `_eager-snippets`) — audit trail, never ships.

## Roster tiers

Models are **never hardcoded** — P0 probes the account catalog and resolves each seat to a capability class. At STANDARD/FULL the installer **REFUSES** if the reviewer bench cannot span ≥2 families distinct from the Builder/Lead family (the cross-family thesis cannot hold otherwise). MIN's single-reviewer bench structurally cannot satisfy this, so MIN **explicitly waives** the guarantee and the RUNBOOK states the forfeit.

| Tier | Seats | Adds |
|---|---|---|
| **MIN-VIABLE** (3) | Lead + Builder + Contract-floor reviewer | constitution + `_reviewer-common` prepend; route.sh Contract-floor + docs-allowlist; 7 MIN skills; **no** watchdog / QA / harvest loop; single-family bench (cross-family REFUSE waived) |
| **STANDARD** (7) | + QA, Security (binding veto), Architecture, Monitor | full route globs; drift MCP + autopilot lanes; STANDARD + scan-conditional skills; watchdog autopilot; **MCP-usage prune sweep** so broad-then-prune actually prunes |
| **FULL** (10 + Helper) | + Validator (Phase 1.5), Mentor, Coach (opt-in) | skill-harvest + review-quality-metrics + squad-measurement — the loop that earns everything else; control-issue ledger; Validator ships behind its sunset tripwire |

**Capability classes:** judgment-class (Lead / Mentor / Coach — top reasoning model) · 1M-coder-class (Builder — ≥256k context ∩ strong SWE ∩ cost-favorable) · reviewer-class (≥2 families; the strongest reviewer family defaults to the binding-veto seat) · validator-class (read-only judgment; sonnet-class suffices) · cheap-watchdog-class (Monitor — cheapest model passing a 1-shot instruction-follow check).

## Baked defaults — the override register

These are decided for you (matching the donor squad's tuned choices) and are **overridable later, never asked at init**:

- Binding-veto assignment: **Security + Contract binding**, Architecture a weighted coherence flag, Validator advisory.
- **Strongest reviewer family on the binding-veto seat.**
- Byte caps = **measured at init + ~5% headroom, HARD-FAIL** (delete-before-add).
- Research MCP servers stay on the Lead.
- **Dedicated squad per project.**
- Conditional skills auto-included **by scan** (not by owner question).
- Monitor thresholds **30 / 40 / 15 min** (stall idle / re-poke cooldown / lock staleness).
- Helper working language **English**, with an inline override comment.

## Genuinely open decisions — and how the build resolved each

These stay owner-adjustable at build time or per squad; the resolution shipped in this package is noted:

1. **Validator / Phase 1.5 at FULL** — *shipped: included by default.* It has never fired live in the donor squad and its sunset tripwire exists either way; the open question is only whether to flip it to explicit opt-in.
2. **Ambient-registry runtimes (e.g. antigravity) eligible for binding-veto seats** — *OPEN.* Their MCP lives in an unowned ambient registry and skill-load is unauditable; accept them with the presence-assert made fatal, or restrict binding vetoes to fully-auditable runtimes.
3. **Coach** — *shipped: FULL-tier opt-in (recommended).* Human-pedagogy payoff, orthogonal to shipping quality; ~36 KB, so never in MIN/STANDARD.
4. **P7 cadence** — *shipped: on-demand, with a suggested cadence* (re-scan after N merged parents; the RUNBOOK names it). Scheduled re-scan remains an option.
5. **`lib/` dual-maintenance** — *shipped: freeze-and-diverge.* Each extracted `lib/` engine carries a **dated provenance stamp**; donor evolution is **not** auto-backported. The alternative (cherry-pick on a cadence) stays open.

## Tag legend (R# / F# / G# / §#)

Rule and lesson tags cited across SKILL.md, the manifest, and the templates (R1–R13, F1–F25, §-refs) point into the donor's internal clause-level design review — a document that does NOT ship. Wherever a tag matters, its meaning is glossed inline at the point of use (e.g. "R8 — holes.json is canonical; the manifest derives from it"); treat the inline gloss as authoritative and the bare tag as provenance, not a reference you must resolve. G1–G4 are the exception: the emitted PIPELINE.md defines them (§6 "Guardrails & human levers").

## Package layout note

`skills/` and `emitted/` sit at the **package root** (the design §2 tree sketched them nested under `templates/`) — a deliberate build-time flattening; every in-package reference (SKILL.md, holes.tmpl.json consumers, skills/README.md) uses the root paths.

## `emitted/PIPELINE.md` is generated, never hand-written

The pipeline reference is **emitted at P6 by `drift-lib` from the live config** — including any byte counts. It is never hand-maintained (hand-maintained numbers drift; the donor once shipped self-inconsistent byte counts from exactly that). The RUNBOOK is emitted from `emitted/RUNBOOK.md.tmpl` with tier-conditional expectations, and its §8 incident ledger + §9 see-also ship as empty scaffolds.

## Provenance

Extracted **2026-07-07** from a production Multica dev squad (11 seats, TypeScript/Node monorepo), via a clause-level design review: 267 clauses partitioned → 98 STATIC / 144 PARAM / 25 PROJECT, consolidated to **44 named holes**. Donor identity is anonymized in this public release (fictional `acme` stand-ins in the `donor_example` fields). Policy: **freeze-and-diverge** — the donor's live config keeps evolving and is not auto-backported into this package; upgrade the target squad via P7, not by re-syncing the donor.
