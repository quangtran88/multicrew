# Engine-probe checklist — P0 recipes for the 11 probe holes

**What this is.** The P0 preflight recipes. Eleven facts about the target Multica *account and engine* are
never assumed — they are probed live against a fresh squad before any template is filled. Every one is
stamped **RE-VALIDATE PER ENGINE VERSION**: an engine or runtime-CLI upgrade can silently change any of
them, and shipping the donor's probed values as if they were STATIC is exactly the "smuggled specificity"
this package forbids (design §1 principle 4, §3 probe list).

**Provenance policy.** This is a method document, so it names the donor (anonymized here as "the donor") and its probed
values as *worked examples* of a valid answer — those donor values are NEVER copied into a filled template;
they only show you what shape a good answer takes. The donor discovered most of these the hard way (the
incident tags below); you re-discover them cheaply by following the recipe.

**Order.** Run P0 before P1 (repo scan). A `<2 reviewer-family` catalog result REFUSES init at
STANDARD/FULL (`reference/capability-classes.md`); everything else feeds the roster proposal at P3.

**Per hole:** *Captures* · *Probe recipe* (concrete steps on a fresh squad) · *Valid answer* · *Re-validate
trigger*.

---

## 1. `{{OWNER_MENTION}}` — the human product-owner mention link

**Captures.** The `[@Name](mention://member/{uuid})` link that notifies the human and spawns no agent run —
the sole authorization identity for merge/deploy/secret-read.

**Probe recipe.**
1. Add the human to the squad as a *member* (not an agent).
2. `multica squad members --output json` (or the member row of `multica agent list --output json`) → read
   the member's UUID and `author_type == member`.
3. Compose `[@{DisplayName}](mention://member/{uuid})`.
4. Verify: post a comment containing the link on a scratch issue → confirm it notifies the human and starts
   NO run (`multica issue runs {id}` shows no new run).

**Valid answer.** A `mention://member/{uuid}` link whose author resolves to `author_type == member`.

**Re-validate.** Member UUID changes if the human is re-added; the `mention://` scheme is engine-native and
version-stable but confirm the member-vs-agent distinction still holds. *(Donor example: `[@Quang Tran]
(mention://member/afce49df-…)`.)*

---

## 2. `{{SEAT_MODELS}}` — each seat's model, resolved by capability class

**Captures.** The concrete model id bound to each seat, resolved from the live catalog against the five
capability classes (§5) — NEVER a hardcoded name.

**Probe recipe.**
1. Enumerate the routable catalog: dispatch a trivial 1-shot to each *candidate* model and confirm it
   returns (the donor found declared-but-unroutable models — e.g. `qwen3.7-max` failed
   `unknown provider` until cliproxy routing was enabled mid-session, §8.12).
2. For each class (judgment / 1M-coder / reviewer / validator / cheap-watchdog) rank candidates by the
   class rule in `reference/capability-classes.md`.
3. Confirm the reviewer bench spans ≥2 model families distinct from the Builder/Lead family — else **REFUSE**
   at STANDARD/FULL (MIN waives, R5).
4. For opencode seats, capture the *provider-prefixed* id (`openai/gpt-5.5`, `openai/qwen3.7-max`).

**Valid answer.** One model id per seat, each tagged with its class and family; reviewer bench ≥2 families.

**Re-validate.** Catalog membership, cliproxy routing, and model deprecations shift constantly; re-probe the
full declared set on any engine/proxy change. *(Donor example: Lead/Mentor `opus-4-8`, Builder `sonnet-5`,
Security `openai/gpt-5.5`, Contract `openai/qwen3.7-max`, Architecture/Coach `Gemini 3.1 Pro`, Monitor
`openai/glm-5.2`.)*

---

## 3. `{{RUNTIME_UUIDS}}` — the runtime ids seats bind to

**Captures.** The UUID per runtime *name* (claude / opencode / antigravity / …) used when creating a seat.

**Probe recipe.**
1. `multica runtime list --output json` → capture `{name → id}`.
2. Confirm each runtime you intend to bind actually launches: create one throwaway seat per runtime and run
   a trivial dispatch.
3. Record which runtimes are RETIRED/absent (do not bind a seat to one).

**Valid answer.** A `{runtime-name → UUID}` map covering every runtime the roster will use.

**Re-validate.** Runtimes are added and removed upstream — the donor lost two (Codex `<id>`, Gemini
`<id>`; Gemini CLI removed upstream PLAT-3617, v0.3.29). *(Donor example: Claude `<id>` · Opencode
`<id>` · Antigravity `<id>`.)*

---

## 4. `{{EFFORT_LEVER}}` — the per-runtime reasoning-effort mechanism

**Captures.** How you dial reasoning effort on each runtime — a different mechanism per runtime, easy to get
silently wrong.

**Probe recipe.** For each runtime you will bind, determine and verify the lever:
- **claude / codex** → `--thinking-level {low|medium|high|xhigh}`. Verify via `multica agent get {id}` that
  the level persisted.
- **opencode** → `--custom-args '-c model_reasoning_effort={low|high}'` (cliproxy; model id is
  provider-prefixed). Verify the custom-args round-tripped through an `agent update` and survived a re-pin
  (the donor lost these on a settings update — F20; the fix re-pins in BOTH branches).
- **antigravity** → the effort is the literal `(High)` token *inside the model-name string*; there is no
  flag. Confirm nothing lowercases it (the donor card warns the `(High)` suffix "IS your only effort lever").

**Valid answer.** The exact flag or token per runtime + a note on how it persists through updates.

**Re-validate.** Runtime CLI upgrades change flag names and defaults; re-verify after any runtime bump.

---

## 5. `{{MCP_SERVER_CATALOG}}` — the account's available MCP servers (broad, to prune later)

**Captures.** The full set of MCP servers available on the account, with transport + args — shipped
BROAD-then-pruned, not the donor's already-pruned outcome.

**Probe recipe.**
1. `multica agent get {any existing seat} --output json | jq .mcp_config.mcpServers` → read the per-agent
   server set + args for claude/opencode seats.
2. For antigravity, read the ambient registry `~/.gemini/config/mcp_config.json` (see hole 8).
3. Assemble the union as the catalog; note each server's transport (stdio local binary vs `npx -y <pkg>`
   remote — matters for hole 11) and any egress-capable tools.
4. Do NOT pre-prune to zero-use servers — ship broad; the STANDARD-tier MCP-usage prune sweep removes
   measured-zero servers later (design F12).

**Valid answer.** A `{server → {transport, args, egress?}}` catalog covering every seat's needs.

**Re-validate.** Servers are added/removed on the account; re-probe before each squad. *(Donor example
catalog: agentmemory, gitnexus, fff, context7, deepwiki, exa, perplexity, playwright — the donor pruned
morph/composio/shadcn by measured zero-use; the skeleton ships broad.)*

---

## 6. `{{MEMORY_BACKEND_URL_API}}` — memory-server endpoint + its tool-call names

**Captures.** The memory MCP endpoint AND the exact tool-call names the constitution MEMORY clause and every
seat's recall/save loop invoke — the tool names are backend-specific (R12).

**Probe recipe.**
1. Read the memory server entry from the catalog (hole 5) → capture its endpoint URL/transport.
2. List its tools: `multica agent get {memory-mounted seat} --output json` or the server's own tool list →
   capture the recall/search/save tool names.
3. Verify a round-trip: `save` a scratch lesson, then `recall`/`smart_search` it back (verify-by-readback).
   Note any query quirk (see hole 11 — the donor's `smart_search` ignores the `project` arg).

**Valid answer.** `{endpoint, recall-tool, search-tool, save-lesson-tool, save-note-tool}` + the project-slug
argument convention.

**Re-validate.** A memory-backend swap changes both endpoint and tool names; never carry the donor's over.
*(Donor example: agentmemory @ `localhost:3111`; tools `memory_lesson_recall` / `memory_smart_search` /
`memory_lesson_save` / `memory_save`. The `localhost:3111` endpoint NEVER ships — R3.)*

---

## 7. `{{RUNTIME_SKILL_AUTOLOAD}}` — does the runtime auto-load bound skills, or need an imperative Read?

**Captures.** Per runtime, whether a bound skill is auto-loaded into context or must be explicitly `Read`
from disk by the card — the difference between a working skill and a dead one.

**Probe recipe (per runtime).**
1. Bind a test skill to a scratch seat on that runtime.
2. Dispatch a run whose card references the skill WITHOUT an explicit Read line.
3. Inspect `multica issue run-messages {run-id}` → did the run actually read/apply the skill?
   - If NO → the runtime needs an imperative `Read {skills-dir}/<name>/SKILL.md` line in the card.
   - If YES → the runtime auto-loads.
4. Capture the on-disk skill path pattern the runtime exposes.

**Valid answer.** `{runtime → auto-load boolean, skill-dir path pattern}`.

**Re-validate.** Skill-loading is engine-version-specific. *(Donor fact: claude AND antigravity NEVER open a
bound skill without an explicit Read line — the constitution and every claude/antigravity card carry an
imperative "Read …/SKILL.md" directive, 2026-07-02 audit / §8.13/§8.14. Architecture card reads from
`.agents/skills/<name>/SKILL.md`.)*

---

## 8. `{{RUNTIME_MCP_MOUNT}}` — where each runtime's MCP config lives

**Captures.** For each runtime, whether MCP is mounted per-agent (via multica) or via an ambient registry —
because per-agent config is INERT on some runtimes.

**Probe recipe.**
1. **claude / opencode** → per-agent: `multica agent update {id} --mcp-config-file {file}`; verify with
   `multica agent get {id} --output json | jq .mcp_config`.
2. **antigravity** → ambient ONLY: the per-agent `mcp_config` is never wired by the runtime, so the entire
   MCP surface is `~/.gemini/config/mcp_config.json`. Verify by running headless `agy -p '<prompt that calls
   an MCP tool>'` and confirming the ambient servers load AND execute in print mode (the mode multica
   spawns).
3. Record which servers are ambient-owned (unauditable by any per-seat script — relevant to §10.2, whether
   ambient runtimes may hold binding-veto seats).

**Valid answer.** `{runtime → mount-location, ambient?}` + the ambient registry path if any.

**Re-validate.** Ambient-registry ownership and the runtime's wiring are engine-version-specific. *(Donor
fact: antigravity's per-agent block is null; its servers ride `~/.gemini/config/mcp_config.json`;
`agentmemory`/`gitnexus`/`fff` verified loading in headless `agy -p` 2026-06-30 — §8.3.)*

---

## 9. `{{ENGINE_WAKE_SEMANTICS}}` — terminal-run / no-redelivery / mention-is-the-wake / max_attempts

**Captures.** The #1 stall class: whether a completed run is TERMINAL (the engine does NOT redeliver a
self-scheduled wakeup), that a full mention link is the only wake, and how many infra retries the engine
does automatically.

**Probe recipe.**
1. Dispatch a run that self-schedules a wakeup and ends its turn → observe it never re-wakes: a completed
   task run is terminal (the background-park stall). Confirm the "run long commands synchronously in-turn"
   rule is necessary.
2. Confirm the wake is ONLY a *new* comment containing `[@Name](mention://{type}/{uuid})`: a plain `@Name`,
   an edited comment, and a member mention each fire nothing.
3. Read `multica issue runs {id} --output json` after an infra failure → capture the auto-retry count
   (`max_attempts`).

**Valid answer.** "Completed run = terminal, no redelivery of a self-scheduled wakeup; wake = new mention-
link comment only; engine auto-retries infra N times via `max_attempts=N`."

**Re-validate.** Core wake behavior is the most consequential and version-volatile fact — re-probe on EVERY
engine bump. *(Donor example: terminal-completed, no redelivery — the ACM-72 background-park stall;
`max_attempts=2`.)*

---

## 10. `{{ENGINE_CONCURRENCY_AND_TIMING}}` — shared-pool size + timing (fan-outs derived BELOW the pool)

**Captures.** The engine's concurrency limit and stall timings — and the derived per-seat fan-out caps,
which must sit BELOW the shared pool, never equal the raw pool value (R6).

**Probe recipe.**
1. Read `max_concurrent_tasks` for the shared runtime pool (the donor's claude pool = 4, shared by Lead +
   Builder + Mentor + Validator).
2. Observe `queued` durations across a few dispatches → set the "queued > T ⇒ runtime offline" threshold
   (donor ≈ 5 min).
3. Derive `{{VALIDATOR_FANOUT}}` (and any per-seat fan-out) strictly BELOW the pool so the Lead/Builder/
   Mentor aren't starved — the donor uses fan-out 2 against a 4-slot pool. Never fill a fan-out with the raw
   pool number.

**Valid answer.** `{pool-size, queued-offline-threshold, max_attempts}` + derived per-seat caps < pool.

**Re-validate.** Engine concurrency and timings change per version. *(Donor example: pool 4, fan-out 2,
queued>~5min = offline, round cap 2, ceiling 6.)*

---

## 11. `{{RUNTIME_QUIRKS}}` — per-runtime failure shapes + detection oracles

**Captures.** The runtime-specific bugs the squad must design around — `--max-turns` ignored, empty-output
completed runs, npx-hang, and their detection oracles. NEVER ship the donor's instances as STATIC.

**Probe recipe (per runtime).**
1. **`--max-turns` honored?** Dispatch with a low `--max-turns` and see if it's respected. (Donor:
   antigravity IGNORES it — the card's PASS BUDGET is the only run fuse.)
2. **Empty-output completed runs?** Look for runs marked `completed` with `run-messages` literally `[]` —
   `max_attempts` auto-retry never fires on these. Detection oracle: a reviewer/QA run marked `completed`
   with ZERO new comments is this failure by definition. (Donor: both opencode/gpt-5.5 seats, §8.9;
   3-strike → model A/B tripwire.)
3. **npx-hang?** Register an `npx -y <pkg>` MCP server and run headless `agy -p` → does it block until an
   interactive restart primes the download cache? Local-binary stdio servers do NOT hang. (Donor: §8.3.)

**Valid answer.** A per-runtime quirk list, each paired with a detection oracle and the interim ops rule.

**Re-validate.** Quirks are the most version-volatile facts of all — re-probe every engine/runtime bump;
these are probe/earned, never STATIC. *(Donor examples above.)*

---

## Extra P0 probes (not among the 44 holes, but required at P0)

### A. Platform instruction-size hard limit

**Captures.** The maximum instruction-body size an `agent update --instructions` accepts before it truncates
or times out — the ceiling every assembled card is asserted against at P4.

**Probe recipe.**
1. `agent update --instructions` a scratch seat with progressively larger bodies until it fails with a
   backend error (the donor hit "context deadline exceeded" / "request timed out" on a ~21 KB Techlead body;
   the backend degrades on long uptime / large writes — §8.7).
2. Record the largest size that reliably lands; if the backend is flaky on big bodies, apply seats
   INDIVIDUALLY rather than via the batch script.
3. Feed this limit into P4: every assembled card must be ≤ limit (asserted alongside the measured byte
   caps); the linter hard-fails otherwise.

**Valid answer.** A byte ceiling for a single seat's instructions + a note on batch-vs-individual apply.

**Re-validate.** Backend limits and timeout behavior change per engine version and under load.

### B. Skill-autoload confirmation per runtime (paired with hole 7)

**Captures.** A per-runtime green/red on whether bound skills actually reach the run — the same probe as
hole 7, called out separately because a false "auto-loads" here silently disables every skill on that
runtime.

**Probe recipe.** Exactly hole 7's recipe, but run it for EVERY runtime you bind and record a per-runtime
result table; any runtime that does NOT auto-load gets an imperative `Read {path}/SKILL.md` line injected
into every card on that runtime at P4.

**Valid answer.** A `{runtime → auto-load?}` table with the Read-line requirement flagged per runtime.

**Re-validate.** Same as hole 7 — skill-loading is engine-version-specific; re-run on any runtime bump.

---

## P0 exit checklist

- [ ] All 11 probe holes filled with live-verified values (not donor values).
- [ ] Platform instruction-size limit recorded; feeds the P4 assert.
- [ ] Skill-autoload table complete per runtime; Read-line requirement flagged.
- [ ] Reviewer bench spans ≥2 model families distinct from Builder/Lead (STANDARD/FULL) — else REFUSE.
- [ ] Every filled value stamped with today's date + engine version — the **RE-VALIDATE PER ENGINE VERSION**
      banner travels with each into `manifest/holes.tmpl.json` (source + date + engine version).
