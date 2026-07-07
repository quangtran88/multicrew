# Skills — tier-gated, generic-method skill set

This directory ships the **generic-method** skills a Multica squad's seats bind to — the portable procedures (how to root-cause a bug, how to review for coupling, how to run a retrospective), never the project-specific instances a squad earns by actually shipping work. Every `SKILL.md` here is copied from a battle-tested donor squad's own skill registry, then de-donored: donor project names, seat-name literals, issue-key citations, ports, and paths are replaced with holes (`{{LIKE_THIS}}`, resolved at install by the P0 probe / P1 scan / P5 account mint), or fenced as `EARNED` slots the retro/harvest loop (`skill-harvest`) fills once the squad has real deliveries behind it. Nothing in this directory is a stub — every file ships complete, ready to bind to a seat once its holes are filled at init.

## Three kinds of file
A `SKILL.md` is imported and bound (lazy — loaded only when its description matches the task at hand); a file under `_eager-snippets/` is appended directly to a seat's `instructions` (eager — always in context); a file under `_fold-ins/` is merged into an existing bound skill's body. Only `SKILL.md` files ship in this package — the eager/fold-in placement decisions for any given clause were made once, upstream, when each card template was written, so this directory carries no loose `_eager-snippets/` or `_fold-ins/` of its own (see "Not shipped" below).

## Contents — tier-gated

| Skill | Tier | Seat(s) | Ships when |
|---|---|---|---|
| `vertical-slice-issues` | MIN | Lead | always |
| `builder-dev-loop` | MIN | Builder | always |
| `root-cause-first` | MIN | Builder, QA | always |
| `safe-refactor` | MIN | Builder | always |
| `edge-case-hunter` | MIN | Contract-floor reviewer | always |
| `migration-schema-safety` | MIN | Contract-floor reviewer (primary), Builder | always |
| `self-improve` | MIN | any seat with a memory backend wired | always |
| `reviewer-panel-degradation-recovery` | STD | Lead | STANDARD+ (a real multi-reviewer panel exists) |
| `eval-harness` | STD | QA | STANDARD+ |
| `architecture-review-method` | STD | Architecture reviewer | STANDARD+ |
| `repomix-context-scoping` | STD | Architecture reviewer | STANDARD+ |
| `browser-e2e` | STD | QA | STANDARD+, **scan-conditional**: only if `{{UI_SURFACE}}` exists |
| `llm-gateway-security` | STD | Security reviewer | STANDARD+, **scan-conditional**: only if the target is an LLM/agent app |
| `mcp-tool-authoring` | STD | Builder | STANDARD+, **scan-conditional**: only if the project builds MCP tool surfaces |
| `skill-harvest` | FULL | Mentor | FULL — this IS the learning loop |
| `review-quality-metrics` | FULL | Mentor | FULL — pairs with skill-harvest |
| `squad-measurement` | FULL | Mentor | FULL — authored at build time from the shared telemetry schemas (a different lane's deliverable; listed here for the tier picture, its directory is untouched by this one) |

The three STANDARD-tier skills marked scan-conditional are never an owner question at init — P1's repo scan detects the surface (a UI, an LLM-app shape, an MCP-tool-authoring surface) and attaches the skill automatically when it's present. Their bodies are unaffected by the condition; only the P5 attach decision is scan-driven, per seat-manifest.

## Not shipped (the EARNED register)

- **`api-wire-oracles`** — demoted to EARNED, never installed. The donor body is wire-surface literals top to bottom (specific HTTP routes, a specific SSE-format module, specific signed-ingress header names) with zero portable structure once those are stripped; the oracle *method* it demonstrates (free 5xx / response-shape / stream / signature-rejection oracles beyond your per-scenario asserts) already ships inside `qa.md`'s Mode-2 guidance. A project-specific wire-oracle skill is something the retro loop earns from this project's own API surface, not something the installer pre-seeds.
- **Donor-project-namespaced skills** — never ship. They are `skill-harvest`'s own output, not its input: the harvest loop is what mines a squad's real incidents into a `{project}-*` skill. A fresh squad starts with zero of these; its own Mentor populates this namespace over real deliveries.
- **`_migration/`, `_fold-ins/`, `_eager-snippets/`** (donor housekeeping dirs) — pure audit trail of the donor's own build history; not shippable content at all. A `_fold-ins/` file's content is already reflected inside the bound skill it was merged into (e.g. the self-improve agentmemory convention lives inside `self-improve/SKILL.md` above); an `_eager-snippets/` file's content is a placement decision already baked into the relevant card template upstream, not a loose file to re-decide here.

## Placement conventions (portable, STATIC)
The eager-vs-lazy-vs-fold-in split above is a convention every card template in this package already follows, not something a new squad re-decides: a clause an agent needs on EVERY run belongs eager in the card; a clause needed only on a matching task-shape belongs in a lazy `SKILL.md`; a clause that only ever augments one existing skill's body belongs as a fold-in into that skill, not a standalone file. Keep this split when the retro loop (`skill-harvest`) proposes a new or improved skill — most proposals are new lazy `SKILL.md`s; a proposal to make something eager is rare and should be justified by "every run needs this," not "it would be nice to have."
