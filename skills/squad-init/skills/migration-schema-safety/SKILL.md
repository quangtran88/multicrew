---
name: migration-schema-safety
description: Use when a diff adds or changes a data/state migration — reviewing ({{CONTRACT_SEAT_NAME}}) or authoring ({{BUILDER_SEAT_NAME}}) one. Classify the surface first — the {{STACK_DESCRIPTION}} scan tells you which of state/session migrations, relational-DB DDL, or application-level data backfills actually exist here; apply only the iron rules for the surface(s) present. Do not use for ordinary feature diffs with no migration.
---

<!--
Provenance: re-authored (not copied) from ECC .kiro/skills/database-migrations/SKILL.md @ 5b173d2 (affaan-m/ECC, MIT © 2026 Affaan Mustafa). Heavily retargeted: the source is a multi-ORM Postgres/MySQL DDL tour (Prisma/Drizzle/Django/golang-migrate), but most non-DB-backed services have zero Postgres/ORM DDL tooling at all — sending a reviewer hunting for DDL migrations that don't exist wastes a review pass. This draft scopes to whichever migration surface(s) the repo scan actually finds (part of {{STACK_DESCRIPTION}}): a one-way state/session migration, a relational-DB DDL migration, and/or an application-level data backfill are the three archetypal risk shapes; the classic Postgres-DDL nuggets (expand-contract, CREATE INDEX CONCURRENTLY, NOT-NULL rewrite, batched backfill) apply only when a relational DB with DDL migrations is actually part of the stack. Dropped: the per-ORM CLI tours, RLS patterns, and the metadata.origin frontmatter.
-->

# Migration & schema safety

A migration is the one diff that can silently destroy production data, and it bites *after* deploy, not in review-the-happy-path. Scope first — most repos have between zero and three of the surfaces below; do not assume all three exist. This repo's surfaces (scanned at init as part of {{STACK_DESCRIPTION}}) determine which sections below apply.

## 1. One-way state/session migrations (if this surface exists)
A one-way transform of an on-disk session/state directory on a version bump — usually shipped by a runtime/framework dependency, not authored in-repo. You review these during a runtime/dependency version bump; you rarely author them yourself. Danger = irreversibility and data loss. Iron rules:
- **Back up the state dir BEFORE the migration runs.** The deploy runbook should already require this — a review that doesn't confirm the backup step is incomplete.
- **Immutable once it has run in any deployed env.** Fix forward with a *new* migration; never edit a shipped one (that causes env drift).
- **Idempotent.** Re-running on already-migrated state must be a no-op, not a double-apply.

## 2. Application-level data migrations (if this surface exists)
Backfills/transforms over application data, authored in-repo. Rules:
- **Separate the shape change from the data move** — never do both in one irreversible step.
- **Idempotent and restartable** — guard on an "already migrated" marker so a crash mid-run resumes cleanly instead of corrupting or double-counting.
- **Batched** — never load every row/entity into memory at once (a hot per-entity loop is a retention/heap risk). Stream or chunk.
- Keep a reverse, or an explicit "irreversible — backup taken" note.

## 3. Relational-DB DDL (if a relational DB with DDL migrations is part of this stack)
- Add column: nullable, or `NOT NULL DEFAULT {x}` (a *constant* default is instant on modern Postgres / equivalent). A **volatile** default (`now()`, `gen_random_uuid()`) defeats that fast path and rewrites the table; and `ALTER COLUMN ... SET NOT NULL` on a populated column takes an exclusive lock and full-scans to validate — flag both. (A bare `ADD COLUMN ... NOT NULL` with no default simply *fails* on a non-empty table.)
- Index on a populated table: `CREATE INDEX CONCURRENTLY` (cannot run inside a transaction block — the runner must handle that); a bare `CREATE INDEX` blocks writes.
- Rename a column: never in place — **expand-contract** (add new → backfill → app reads/writes both → drop old in a later migration).
- Large backfill: batch with `WHERE id IN (SELECT id ... LIMIT {n} FOR UPDATE SKIP LOCKED)`, commit per batch — never one transaction over the whole table.
- Drop a column only after all code references are removed and deployed.

## Anti-patterns (all surfaces)
| Anti-pattern | Why it bites in prod | Safe approach |
|---|---|---|
| Editing a deployed migration | Env drift, unrepeatable | New forward migration |
| Schema + data in one step | Hard to roll back, long lock | Separate steps |
| Drop before code removed | Runtime errors on missing field | Remove code first, drop next deploy |
| Unbounded backfill | Table lock / OOM | Batch + commit per chunk |
| One-way state migration, no backup | Unrecoverable data loss | Back up state dir first |

## Dual-mode usage
- **Reviewing ({{CONTRACT_SEAT_NAME}}):** when the diff touches a migration, flag each violation in the canonical finding grammar — `[SEVERITY] (confidence: N/10) {file}:{line} — {which rule + why it bites in prod} | Fix: {the safe pattern}` — and emit your verdict **per your own format**; do not restate a verdict token here.
- **Authoring ({{BUILDER_SEAT_NAME}}):** treat the iron rules + anti-pattern table as a pre-PR checklist, and **prove idempotence/restart with a test** ({{TEST_CMD}}, re-running the migration); back up before any one-way state migration.

## Defer
{{TYPECHECK_CMD}} / {{TEST_CMD}} / {{BUILD_VERIFY_CMDS}} verification and PR handoff follow your existing instructions — this skill only names the migration-specific hazards.
