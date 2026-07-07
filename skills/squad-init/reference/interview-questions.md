# Interview questions — the 7 blocking questions (P2)

**What this is.** The complete owner interview for `multicrew`, verbatim from design §4. Only
**seven** questions block init — every other per-project value is filled by repo scan (P1), account probe
(P0), or minted at create-time (P5). The adversarial pass trimmed the interview 9→7 and moved everything
cuttable into the defaults register (§10); the cut questions and their replacement defaults are recorded at
the bottom so nobody "helpfully" re-adds them.

**Design contract.** Every question is anchored **"scan says X — confirm/override"**: the interview never
asks for a fact the scan already found, it asks the owner to confirm or override the scanned value. Four
questions are **HARD gates** — a vague answer BLOCKS init (you cannot generate a squad that doesn't know
what it must never touch, who may merge, what its branch model is, or what success looks like). This is a
provenance/method doc, so donor examples appear as illustrations; they never ship.

---

## The 7 questions (verbatim — design §4)

| # | Question | Hole(s) | Gate |
|---|---|---|---|
| 1 | Squad name + seat prefix | `SQUAD_NAME`, `SEAT_PREFIX` | — (role suffixes are STATIC constants) |
| 2 | Roster tier (+ Coach opt-in at full) | `ROSTER_TIER` | — |
| 3 | Execution boundary + irreversible-action class (what must the squad NEVER touch — deploys, VPS/cloud, data) | `EXECUTION_BOUNDARY` (absorbs the partition's IRREVERSIBLE_ACTION_CLASS — R13) | **HARD** — vague answer blocks init |
| 4 | Sole merge authority (the one human) | `MERGE_AUTHORITY` | **HARD** |
| 5 | Branch model: protected branches + merge target (scan-seeded) | `PROTECTED_BRANCHES`, `TARGET_BRANCH` | **HARD** |
| 6 | "Scan says merge→{deploy workflow} fires on {TARGET_BRANCH} — does your `merge` reply double as deploy approval?" | `DEPLOY_ON_MERGE` | confirm (fact half comes from scan — F8) |
| 7 | Success criteria: what work will you feed it and what does a good month look like | (runbook expectations) | **HARD** (report §5's third gate) |

---

## Per-question detail

### Q1 — Squad name + seat prefix `{{SQUAD_NAME}}` · `{{SEAT_PREFIX}}` — *not gated*

Ask the squad's name and the seat-name prefix (the donor's is `AC-`). The **role suffixes are STATIC
constants** taken from the donor roster (`-Techlead`, `-Builder`, `-QA`, `-Reviewer-Security`,
`-Reviewer-Contract`, `-Reviewer-Architecture`, `-Validator`, `-Mentor`, `-Coach`, `-Monitor`), so all the
derived seat names (`{{LEAD_SEAT_NAME}}` = `{{SEAT_PREFIX}}`+`-Techlead`, etc.) come from one decision plus
the UUID directory minted at P5 — you do NOT ask for each seat name. Anchor: "scan found short name `X` —
use prefix `X-`?"

### Q2 — Roster tier `{{ROSTER_TIER}}` — *not gated*

MIN-VIABLE (3) / STANDARD (7) / FULL (10 + Helper), with the Coach opt-in offered only at FULL. Drives which
templates, skills, and script lanes are emitted (`reference/capability-classes.md` §5 ladder). Anchor the
recommendation to the scanned surface (an LLM/agent app with a UI leans STANDARD+; a small library leans
MIN). Not a hard gate — but note that MIN **explicitly waives** the cross-family reviewer guarantee (R5).

### Q3 — Execution boundary + irreversible-action class `{{EXECUTION_BOUNDARY}}` — **HARD**

The single most important gate. Ask what the squad must NEVER touch: deploys, VPS/cloud mutations
(`.env`, terraform, container recreation, deploy-PR merges), production data, etc. This hole **absorbs the
former IRREVERSIBLE_ACTION_CLASS** (R13) — one answer covers both the scope boundary and the irreversible-
action list. A vague answer ("just be careful") **BLOCKS init**: you cannot generate the GUARDRAILS clause,
the Builder STAY-IN-SCOPE gate, or the Lead's no-irreversible delivery gate without a concrete boundary.
Anchor: "scan found deploy/infra surfaces at `{paths}` — confirm the squad may never mutate these + name any
others." *(Donor example: "never push/commit/merge main or staging; no VPS/cloud mutations; diagnostics
read-only.")*

### Q4 — Sole merge authority `{{MERGE_AUTHORITY}}` — **HARD**

The ONE human who authorizes merges/deploys. Filled together with `{{OWNER_MENTION}}` (probed at P0). A vague
or plural answer **BLOCKS init**: the entire untrusted-data authorization rail (mechanism 11) resolves to
"only `author_type == member` for THIS human," so it must be exactly one identity. Anchor: "scan found repo
owner `X` — is `X` the sole merge authority, or someone else?"

### Q5 — Branch model `{{PROTECTED_BRANCHES}}` · `{{TARGET_BRANCH}}` — **HARD**

Protected branches + the merge target. **Scan-seeded**: `{{TARGET_BRANCH}}` is counted ONCE as a scan hole
(R13) — the scan reads the default/integration branch from the repo, and Q5 only asks the owner to CONFIRM
or override it (never a fresh free-text ask). A vague answer **BLOCKS init**: `route.sh`, the Decompose
base, the Delivery target, and the GUARDRAILS "never merge {protected}" clause all key off these. Anchor:
"scan found default branch `X` and integration branch `Y` — confirm protected = `{X,Y}`, merge target = `Y`."

### Q6 — Deploy-on-merge `{{DEPLOY_ON_MERGE}}` — *confirm (fact half is scanned, F8)*

Do NOT ask a bare "does merge deploy?" — that bundles a scannable fact with a judgment (F8). The scan reads
the deploy workflow and finds whether a deploy fires on `{{TARGET_BRANCH}}`; the interview only asks the
**approval-semantics half**: "scan says merging to `{{TARGET_BRANCH}}` triggers `{deploy workflow}` — does
your `merge` reply therefore double as deploy approval?" If there is no deploy workflow, `{{DEPLOY_ON_MERGE}}`
is false and Q6 is skipped entirely. *(Donor example: merging `staging` auto-deploys, so the human's `merge`
reply IS the deploy approval.)*

### Q7 — Success criteria — **HARD** (runbook expectations)

The report's third hard gate: what work will you actually feed this squad, and what does a good month look
like? A vague answer **BLOCKS init** — without concrete success criteria the RUNBOOK's expectations section
is empty and the harvest/measurement loop has no baseline to read against. This does not fill a named hole;
it fills the tier-conditional expectations scaffold in `emitted/RUNBOOK.md.tmpl` and seeds the sunset
tripwire's "acceptable cost" bound. Anchor: "you told the scan this is a `{stack}` repo — what kind of
issues (features / bugfixes / refactors) will you queue, and what's a good throughput?"

---

## Non-question confirms batch (unresolved scan holes → confirms, never guesses)

After the 7 questions, run a **confirms batch**: for every P1 scan hole the scan could NOT resolve (a
`{{TEST_CMD}}` it couldn't infer, a `{{BUILD_VERIFY_CMDS}}` with no obvious target, a `{{CODE_GRAPH_TOOL}}`
it couldn't detect), present the scan's best guess and ask the owner to confirm or correct it. These are
**confirms, not questions** — the skeleton NEVER guesses a command it will bake into a card. This is the
G1-lesson generalized: an unresolved scan value becomes a confirm line, never a silent default. None of
these gate init (they are corrections, not decisions); a still-unresolved command degrades gracefully
(e.g. `{{CODE_GRAPH_TOOL}}` → file-search when absent).

---

## Deleted-questions register (what was cut, and the default that replaced it)

The interview was trimmed 9→7 by the adversarial pass (F4: the real decision surface blew past a "≤12
questions" promise via open-decisions that refused defaults). Each cut question became a **baked default in
the override register (§10)** — overridable later, never asked at init. Do not re-add these.

| Cut question | Finding | Replacement default (design §10) |
|---|---|---|
| Which seats hold binding vetoes (`BINDING_VETO_SEATS`) | **F6** | STATIC default baked in every card: **Security + Contract binding, Architecture weighted coherence flag, Validator advisory** — the donor cards already encode this identically. |
| Workspace language (`WORKSPACE_LANGUAGE`) | **F9** | STATIC **English** + one inline override comment on the Helper `Tone` line. |
| Stakes-inversion (which reviewer family sits on the binding-veto seat) | (P3 default) | Default: **strongest reviewer family → the binding-veto seat** (bakes the P3 stakes-inversion lesson; overridable at the P3 proposal). |
| Byte-cap policy (per-seat cap values + hard-fail?) | **F13 / F3** | Default: caps **measured at init** (assembled + ~5% headroom), keyed by manifest seat-id, unknown seat fails closed, linter **hard-fails**. |
| Conditional-skill inclusion (owner byte-tradeoff?) | **F5** | Default: **scan auto-includes** a conditional skill when its surface exists (browser-e2e ⇐ UI, llm-gateway-security ⇐ LLM/agent app, mcp-tool-authoring ⇐ MCP-tool project); lazy skills cost zero eager bytes, so there is no tradeoff to pose. Runbook notes prune-later. |
| Research-MCP placement | (§10 default) | Default: **research MCP servers stay on the Lead.** |
| Dedicated-vs-shared squad | (§10 default) | Default: **dedicated squad per project.** |
| Monitor thresholds (30/40/15 min) | **F7** | STATIC constants matching the donor card — never interview holes. |

---

## P2 exit checklist

- [ ] All 4 HARD gates (Q3 boundary, Q4 merge authority, Q5 branch model, Q7 success criteria) answered
      concretely — a vague answer on any one BLOCKS init; loop until concrete.
- [ ] Q1/Q2 answered; derived seat names computed from `{{SEAT_PREFIX}}` + STATIC suffixes.
- [ ] Q6 asked only if the scan found a deploy workflow on `{{TARGET_BRANCH}}`; otherwise `{{DEPLOY_ON_MERGE}}`
      = false.
- [ ] Confirms batch cleared — every unresolved scan hole confirmed or corrected, none guessed.
- [ ] No cut question re-litigated — the eight defaults above stand unless the owner explicitly overrides
      one at its later override point.
