---
name: squad-init
description: Install a battle-tested multi-agent dev-squad configuration onto a new Multica project (installer, NOT a generator). Use when the user wants to set up, provision, bootstrap, or install a Multica dev squad on a repo — drives phases P0-P7 with hard gates.
---

# Multica squad-init — the installer

You install a proven Multica dev-squad configuration onto a NEW Multica project. You are an **installer, not a generator**: the machinery ships verbatim from the donor squad, and per-project variation is confined to a fixed set of named holes. You do not write bespoke prompts, invent reviewer content, or "improve" the cards at install time. Bespoke config is measured net-harmful (~-3% success / +20% cost versus none); human-curated verbatim machinery works. Specialization — tuned bug catalogs, worked examples, incident citations, `{{PROJECT_NAME}}`-namespaced skills — is the OUTPUT of the running squad's retro loop, not your input. Your job is to install the machinery and the loop that earns the rest, then hand off a day-0 (untuned) squad.

## The contract every phase obeys

1. **Copy verbatim; fill holes; earn the rest.** STATIC prose is copied byte-for-byte from the templates. PARAM items are verbatim structure with one named hole substituted. EARNED regions ship EMPTY, fence-marked, for the retro loop to fill.
2. **Five hole sources, and only five.** Every `{{HOLE}}` is `scan` (18, from the repo), `probe` (11, from the live account/runtime), `account` (7, minted during init), `interview` (7, owner-answered), or `earned` (1 slot family, shipped empty). The full manifest lives in `manifest/holes.tmpl.json` (values + source + date + verbatim interview answers) — that file is THE canonical store; the seat manifest derives FROM it.
3. **No smuggled specificity.** Anything account- or engine-coupled (model names, wake semantics, ports, seat-name literals inside scripts) is a hole or a manifest lookup, never verbatim prose — enforced by the P4 linter, not by convention.
4. **Probe facts are engine-version-specific.** Every probe hole is stamped **RE-VALIDATE PER ENGINE VERSION**. Never trust the donor's account facts (models, wake semantics, MCP quirks, ports).

## Package layout you drive

```
reference/   engine-probe-checklist.md · capability-classes.md · interview-questions.md · extraction-catalog.md
manifest/    holes.tmpl.json (THE store) · seat-manifest.tmpl.yaml (derived at P4)
templates/   constitution.md.tmpl · squad.md.tmpl · roles/*.md.tmpl
             scripts/lib/{assemble-lib,provision-lib,drift-lib}.sh · scripts/*.sh.tmpl · mcp/*.json
skills/      generic-method skills, tier-gated (ZERO project-namespaced skills ship)
emitted/     PIPELINE.md (generated at P6 by drift-lib) · RUNBOOK.md.tmpl
```

Note on holes: the **44 canonical holes** are the only per-project surface. **Derived tokens** are computed at P4 and never asked: seat names `{{SEAT_PREFIX}}-<RoleSuffix>` (the role suffixes — Techlead, Builder, QA, Reviewer-Security, Reviewer-Contract, Reviewer-Architecture, Validator, Mentor, Coach, Monitor — are STATIC constants from the donor roster), `{{LEAD_MENTION}}`, `{{VALIDATOR_FANOUT}}` (derived strictly BELOW the shared engine pool, never the raw pool value), and `{{AP_DESC}}` (the watchdog description templated on `{{CONTROL_ISSUE_KEY}}`).

---

## P0 — Preflight (probe the live account/runtime)

**Do:**
1. Run `reference/engine-probe-checklist.md` against the target account. Fill the 11 **probe** holes into `manifest/holes.tmpl.json` → `holes.json`: `OWNER_MENTION`, `SEAT_MODELS`, `RUNTIME_UUIDS`, `EFFORT_LEVER`, `MCP_SERVER_CATALOG`, `MEMORY_BACKEND_URL_API`, `RUNTIME_SKILL_AUTOLOAD`, `RUNTIME_MCP_MOUNT`, `ENGINE_WAKE_SEMANTICS`, `ENGINE_CONCURRENCY_AND_TIMING`, `RUNTIME_QUIRKS`. Also run the checklist's **extra P0 probes** (deliberately not among the 44): probe A's platform instruction-size limit is recorded as `extra_probes.PLATFORM_INSTRUCTION_LIMIT` in `holes.json` — `build-and-apply.sh` hard-fails without it.
2. Enumerate the account model catalog and resolve candidate models per capability class using `reference/capability-classes.md` (judgment-class, 1M-coder-class, reviewer-class, validator-class, cheap-watchdog-class).
3. Ship the MCP catalog **broad-then-prune** — record what the account offers, not a pre-pruned subset. The prune sweep happens later (STANDARD+), keyed on measured usage.
4. Stamp every probe hole's value with a **RE-VALIDATE PER ENGINE VERSION** banner and the probe date.

**Gate — cross-family refusal:** at **STANDARD/FULL**, **REFUSE to proceed** if the reviewer bench cannot span **≥2 model families distinct from the Builder/Lead family** — the cross-family thesis cannot hold otherwise and a shared-family blind spot passes both binding vetoes. **MIN explicitly waives** this (its single-reviewer bench structurally cannot satisfy it); the RUNBOOK states the forfeit (R5).

**STOP** if the account exposes fewer than two distinct reviewer-capable families at STANDARD/FULL. Do not silently downgrade the tier — report and let the owner choose MIN or a different account.

## P1 — Repo scan (derive from the target repo)

**Do:**
1. Fill the 18 **scan** holes into the `repo-profile` section of `holes.json`: `PROJECT_NAME`, `MEMORY_PROJECT_SLUG`, `ISSUE_KEY_PREFIX`, `STACK_DESCRIPTION`, `MODULE_GLOBS`, `TEST_CMD`, `TYPECHECK_CMD`, `BUILD_VERIFY_CMDS`, `VCS_CLI`, `REPO_ABS_PATH`, `BASE_BRANCH`, `FEATURE_BRANCH_PATTERN`, `TARGET_BRANCH`, `CODE_GRAPH_TOOL`, `CI_BASELINE_REVIEWER`, `ROUTE_GLOBS`, `E2E_HARNESS`, `UI_SURFACE`.
2. **Conditional-skill surface detection:** decide whether the scan detects a UI surface (`UI_SURFACE` — also gates the playwright MCP grant), an LLM/agent surface (gates `llm-gateway-security` + the LLM-app FP guard), and an MCP-tool surface (gates `mcp-tool-authoring`). These are scan-auto-included — never an owner question.
3. `CI_BASELINE_REVIEWER`: scan the actual CI check names. **Never guess a check name** (the G1 lesson). `CODE_GRAPH_TOOL`: degrade to file-search when absent.

**Gate:** any command the scan cannot resolve (test/typecheck/build/e2e) becomes a **P2 interview CONFIRM** — never a guess. Record the unresolved holes so P2 surfaces them.

## P2 — Interview (7 blocking questions, each anchored "scan says X — confirm/override")

Run `reference/interview-questions.md`. The 7 holes: `SQUAD_NAME`+`SEAT_PREFIX`, `ROSTER_TIER` (+ Coach opt-in at FULL), `EXECUTION_BOUNDARY`, `MERGE_AUTHORITY`, `PROTECTED_BRANCHES`+`TARGET_BRANCH`, `DEPLOY_ON_MERGE`, and a success-criteria answer for the RUNBOOK.

**HARD gates block init on a vague answer to:**
- **Q3 execution boundary** — what the squad must NEVER touch (deploys, VPS/cloud, data). Absorbs the irreversible-action class.
- **Q4 sole merge authority** — the one human.
- **Q5 branch model** — protected branches + merge target (scan-seeded; the question only confirms/overrides).
- **Q7 success criteria** — what work you will feed it and what a good month looks like.

Q6 (`DEPLOY_ON_MERGE`) is a confirm: the scan already found whether a deploy workflow fires on `{{TARGET_BRANCH}}`; you only ask whether the human's `merge` reply doubles as deploy approval.

Do NOT ask about: veto assignment, workspace language, Monitor thresholds, byte-cap policy, conditional-skill inclusion, research-MCP placement, dedicated-vs-shared. All are baked defaults (see README's override register). Record every answer verbatim into `holes.json`.

**STOP** on any vague HARD-gate answer. Re-ask; do not proceed to P3 with an unresolved boundary, merge authority, branch model, or success criterion.

## P3 — Roster proposal (owner GO before anything is created)

**Do:**
1. Propose seats by the chosen tier (§ tier table in the RUNBOOK / capability-classes.md).
2. Resolve `SEAT_MODELS` by capability class. **Default: the strongest reviewer family goes to the binding-veto seat** (bakes the stakes-inversion lesson as a default, not a question). Overridable here.
3. Produce a **per-run cost estimate** from the proposed models and expected fan-outs.
4. Draft the seat manifest **without UUIDs** (they don't exist until P5).

**Gate:** explicit owner **GO** on tier + models + cost. **STOP** and do not mint anything until the owner approves the proposal.

## P4 — Generate (the one place generation is sanctioned, and it is fenced)

**Do:**
1. **Derive `seat-manifest.yaml` FROM `holes.json`** (R8 write direction — holes.json is canonical; the manifest is downstream). Do not hand-maintain the manifest as a second source of truth.
2. Substitute holes into every template (`constitution.md.tmpl`, `squad.md.tmpl`, `roles/*.md.tmpl`, `scripts/*.tmpl`, `mcp/*.json`) **and the bundled skill payload** (`skills/*/SKILL.md` — the manifest's `consumers` lists name them; an installed skill must carry zero unfilled tokens).
3. **Expand `{{FOREACH:seat}} … {{/FOREACH}}` regions** from `seat-manifest.yaml` — the per-seat rows in the 3 script tables, the constitution MENTION DIRECTORY, and the `seat_configs` list in `mcp/seat-mcp.tmpl.json`. Each expanded region is marked "generated from seat-manifest.yaml at P4 — do not hand-edit".
4. **Compute derived tokens:** seat names (`{{SEAT_PREFIX}}-<RoleSuffix>`), `{{LEAD_MENTION}}`, `{{VALIDATOR_FANOUT}}` (strictly below the pool from `ENGINE_CONCURRENCY_AND_TIMING` — R6), `{{AP_DESC}}` (templated on `{{CONTROL_ISSUE_KEY}}` — R4).
5. **Strip breadcrumbs:** remove the maintainer provenance/legend HTML comment blocks (the `<!-- multicrew · … -->` headers atop the reviewer card templates — the only cards that carry one — and the `$`-prefixed documentation blocks in the MCP JSON) from the emitted output. They are package documentation, not seat instructions — and their `{{…}}` legend text would false-trip linter (1) below.
6. **Leave every EARNED fence EMPTY** — fence-marked `<!-- EARNED:name -->` / `<!-- /EARNED -->` (shell files use `# EARNED:name` / `# /EARNED`). Never leave donor project content inside a fence.
7. **Author the MCP outputs** (`mcp/seat-mcp.tmpl.json`, `mcp/deny-profiles.tmpl.json`) from the P0 catalog. This is the **ONE sanctioned generation surface** (R9) — constrained to P0-catalog lookups + the baked patterns (agentmemory mask, exa egress-restriction), and explicitly in P4.5's review scope. Do NOT derive-from-live here; a fresh squad has nothing to derive from.

**Gate — three linters, all must pass:**
- **Byte linter:** measured caps = assembled size + ~5% headroom, keyed by manifest seat-id, unknown seat **fails closed**. **HARD-FAIL by default** (the delete-before-add rule ships in the generated script).
- **Platform-limit assert:** every assembled card checked against the platform instruction-size hard limit probed at P0.
- **No-smuggled-specificity linter** (below): any hit **BLOCKS**.

```bash
#!/usr/bin/env bash
# P4 no-smuggled-specificity linter — run against the EMITTED config only.
# Scope: filled constitution/squad/role cards, the FILLED skills/*/SKILL.md payload, the 3
# manifest-generated scripts, route.sh/post-verdict.sh, seat-mcp.json + deny profiles,
# emitted/PIPELINE.md + RUNBOOK.
# NOT scoped: manifest/holes.json (its donor_example fields are documentation) or reference/.
# bash-3.2-safe (stock macOS): no mapfile / associative arrays. Requires jq.
set -uo pipefail
EMITTED_DIR="${1:?usage: lint <emitted-config-dir> [<holes.tmpl.json>]}"
MANIFEST="${2:-manifest/holes.tmpl.json}"
# Fail LOUD if the manifest is unreadable — otherwise checks (2)/(3b) silently degrade to no-ops
# and the lint false-greens. Run from skills/squad-init/, or pass the manifest path explicitly.
[[ -r "$MANIFEST" ]] || { echo "BLOCK: cannot read $MANIFEST — run from the package root or pass its path"; exit 1; }
fail=0; note(){ echo "  ✗ $1"; fail=1; }

# 1. No unfilled holes survived substitution (incl. FOREACH tokens). The second grep
#    drops the literal triple-brace verdict-grammar markers {{{END-REVIEW}}}/{{{END-VALIDATION}}}
#    (they ship verbatim and are NOT holes) so the {{..}} nested inside them is not a
#    false positive that would block EVERY install before a real unfilled hole is reached.
grep -rnE '\{\{[/A-Za-z_][A-Za-z0-9_.:-]*\}\}' "$EMITTED_DIR" | grep -vE '\{\{\{END-(REVIEW|VALIDATION)\}\}\}' && note "unfilled {{HOLE}} token(s)"

# 2. No DONOR literal leaked. The blocklist is NOT hardcoded here — it is every
#    donor_example value the package records in holes.tmpl.json (project name, seat
#    prefix, issue-key prefix, protected/target branches, memory-backend URL, ports,
#    home paths). This keeps the installer itself free of donor specificity. The manifest
#    records prefix-shaped examples WITH their trailing separator (the seat prefix and
#    issue-key prefix carry their "-") so these fixed-string greps never match common words.
while IFS= read -r lit; do
  [[ -n "$lit" ]] || continue
  grep -rnF -- "$lit" "$EMITTED_DIR" && note "donor literal leaked: '$lit'"
done < <(jq -r '.. | .donor_example? // empty | select(type=="string") | select(length>1)' "$MANIFEST" | sort -u)

# 3. Machine-coupling shapes that are dangerous regardless of donor identity.
grep -rnE '/Users/[A-Za-z]|/home/[A-Za-z]' "$EMITTED_DIR" && note "home-dir path in emitted output"
grep -rnE '(localhost|127\.0\.0\.1):[0-9]{2,5}' "$EMITTED_DIR" && note "localhost:<port> in emitted output"
# 3b. Bare donor BRANCH word-tokens (R12). Mechanism (2) greps each donor_example as ONE
#      whole fixed string, so a lone "staging"/"main" leaking from a template that should
#      have been holed slips right past it. Derive the donor branch tokens from the branch
#      holes themselves (keeps this linter free of a hardcoded donor blocklist) and word-match.
while IFS= read -r b; do
  [[ -n "$b" ]] || continue
  grep -rnwF -- "$b" "$EMITTED_DIR" && note "bare donor branch token leaked: '$b'"
done < <(
  { jq -r '.holes.TARGET_BRANCH.donor_example, .holes.BASE_BRANCH.donor_example' "$MANIFEST" | sed 's/ (.*//'
    jq -r '.holes.PROTECTED_BRANCHES.donor_example' "$MANIFEST" | sed -n 's/.*Donor: //p' | tr -d '.'; } \
  | tr ',/ ' '\n' | grep -E '^[A-Za-z][A-Za-z0-9._-]+$' | grep -vixE 'origin|refs|heads' | sort -u)

((fail)) && { echo "BLOCK: P4 found smuggled specificity — fix before P4.5."; exit 1; }
echo "✓ P4: no smuggled specificity, no unfilled holes, caps within budget"
```

**STOP** on any linter hit. Do not advance to P4.5 with an unfilled hole, a leaked donor literal, an over-budget card, or a card over the platform limit.

## P4.5 — Review pass (independent, before anything is applied)

**Do:** an **independent fresh-context review** (F14) of the filled templates + the roster proposal, BEFORE any account object is created. Check: hole-consistency across files, leftover donor literals the linter's fixed-string pass could miss, veto/tier coherence (binding-veto seat has the strongest reviewer family; tier matches the seat set), and that the authored MCP configs match the P0 catalog and the baked security patterns.

**Gate:** a **REQUEST_CHANGES verdict blocks P5**. Owner GO at P3 is self-approval-shaped and is NOT a substitute for this pass. **STOP** and loop back to P4 on REQUEST_CHANGES.

## P5 — Create → backfill → apply → verify

Order matters — several steps are chicken-and-egg on a fresh squad.

**Do, in order:**
1. **Author MCP FIRST.** Derive-from-live inverts on a fresh squad (there is no live config to mutate), so the seat MCP configs and deny profiles are authored from the P0 catalog (done at P4) and applied via `--mcp-config-file`. The fail-loud jq asserts (all-servers-non-null; exa restricted to `web_search_exa`) validate the AUTHORED file — that assert is the crown jewel, kept verbatim.
2. **Mint account objects:** squad, project board, control issue, watchdog autopilot, skills (bodies = the P4-filled `skills/*/SKILL.md`, zero unfilled tokens). Capture `SQUAD_UUID`, `PROJECT_BOARD_UUID`, `CONTROL_ISSUE_KEY`, `WATCHDOG_AUTOPILOT_UUID`, `SKILL_UUIDS`, `SETTINGS_PROFILE_PATHS` into `holes.json`.
3. **Create the seats.** Capture `SEAT_UUIDS`.
4. **UUID BACKFILL — mandatory two-pass.** The MENTION DIRECTORY, the reviewer Handoff lines, and the script seat tables all reference UUIDs that do not exist until the seats do. Pass 1 creates; pass 2 backfills the captured UUIDs into the directory + Handoff lines + script tables. This is what breaks the UUID↔mention-directory cycle.
5. **Regenerate the 3 scripts from the manifest** (build/apply, roster, drift) now that UUIDs exist.
6. **Apply per-seat** via the assembly script (constitution → optional `_reviewer-common` tier → card), respecting the backend timeout class (one seat failing must not abort the batch — the assembly lib uses `set -uo`, not `-e`).
7. **Verify-by-readback:** re-fetch each seat and confirm live instructions equal the assembled expectation.
8. **Run `audit-drift`** (read-only, zero paid runs): instructions / model+runtime / skills / MCP set + per-seat value-asserts / autopilot description.
9. **Commit.**

**Gate:** **clean readback + clean drift.** **STOP** and reconcile (via the apply scripts, never `agent update --instructions` directly) on any readback mismatch or drift finding.

## P6 — Shakedown (prove the pipeline before real traffic)

**Do:**
1. **Planted-bug review shakedown:** feed a deliberately broken diff and confirm the reviewer bench catches it (a false-green means the fill is wrong, not that the squad is ready).
2. **One trivial end-to-end intake:** run a single small, real-shaped request through readiness → build → review → (QA) → delivery.
3. **Emit `emitted/PIPELINE.md`** from the LIVE config via `drift-lib` — never hand-written, no hand-maintained byte counts.
4. **Emit the RUNBOOK** from `emitted/RUNBOOK.md.tmpl` with tier-conditional expectations (the learning loop is FULL-tier-only; the runbook must not promise it generically at MIN/STANDARD). Fill its two **P6-fill tokens** — `{{RUNBOOK_EXPECTATIONS}}` (the owner's verbatim Q7 answer) and `{{P7_CADENCE_NOTE}}` — per their inline comments; they are deliberately NOT among the 44 holes.

**STOP condition:** do **NOT** arm the watchdog for real traffic or declare the squad live until the planted bug is caught **AND** the trivial intake completes. Both gates, not either.

## P7 — Re-scan / upgrade (the anti-fossilization loop)

**Do (on demand or on the RUNBOOK's cadence):**
1. Re-run the P1 scan.
2. Diff fresh values against `holes.json` (globs, CI check names, ports, branches drift as the repo evolves — the stale-refs tax).
3. **Owner confirms** each drifted value.
4. **Re-emit affected artifacts THROUGH the earned-content merge:** extract the live fenced EARNED regions, re-emit the artifact from the updated holes, then re-inject the extracted EARNED regions. Earned content is not a hole, so `holes.json` cannot restore it — the fence-and-reinject is the only safe path.

**Gate:** a re-emit that would **shrink or drop a non-empty EARNED region HARD-FAILS** (R1). The retro loop's harvested catalogs and worked examples must survive every upgrade.

---

## What this skill will NEVER do

- **Write bespoke prose at init.** No hand-authored reviewer content, cards, or prompts. Machinery copies verbatim; only holes and the P0-catalog MCP configs are produced.
- **Ship donor incident content.** No `{{ISSUE_KEY_PREFIX}}`-style change tags, tuned bug-class catalogs, layer-chains, named races, worked examples, or migration history. Those ship as EMPTY EARNED fences the retro loop fills.
- **Guess an unresolved scan value.** An unresolvable command, CI name, or port becomes an interview CONFIRM — never a fabricated default.
- **Apply without P4.5 + owner GO.** No account object is created before the P3 GO; nothing is applied before the P4.5 fresh-context review passes.
- **Trust donor account facts.** Every probe hole is re-established at P0 and stamped RE-VALIDATE PER ENGINE VERSION.
- **Arm the watchdog before the P6 gates pass.** Not live until the planted bug is caught and the trivial intake completes.
- **Clobber earned content on upgrade.** A P7 re-emit that would shrink a non-empty EARNED region hard-fails.
