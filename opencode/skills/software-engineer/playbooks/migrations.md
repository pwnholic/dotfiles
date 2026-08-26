# Migration Playbook

Load for schema migrations, data migrations, persistent-state format changes, or compatibility transitions.

## Model First

Understand:

```text
current schema/state
→ readers
→ writers
→ constraints
→ indexes
→ data distribution
→ deployment order
→ rollback properties
```

## Prefer Expand / Migrate / Contract

When availability and compatibility require it:

```text
expand
→ deploy compatible readers/writers
→ migrate data
→ switch behavior
→ verify
→ contract/cleanup
```

Do not assume all processes update simultaneously unless the system guarantees it.

## Migration Contract and Audit

Define separately:

```text
structural completion   old schema/format/tooling was actually replaced
behavioral preservation readers/writers still satisfy their contracts
data correctness        every eligible record is transformed exactly as intended
operational safety      locks/load/availability remain within bounds
cleanup completion      obsolete paths and compatibility debt are removed
```

Passing application tests does not prove the migration occurred. Inspect
schema/artifact/config state and prove that forbidden legacy mechanisms or
fallbacks are absent after contraction.

For each phase record compatible old/new readers and writers, feature/config
state, entry/exit criteria, observability, rollback/roll-forward action, and
the earliest point of irreversibility.

## Validate Data Assumptions

Check realistic data for assumptions such as:

- uniqueness;
- nullability;
- referential integrity;
- encoding;
- cardinality;
- size;
- legacy values.

Run preflight queries against representative production-shaped data. Preserve
counts and samples for invalid rows rather than silently coercing or dropping
them.

## Resumable Data Movement

For non-trivial backfills define:

```text
stable cursor/chunk boundary
idempotent transformation
checkpoint and ownership
rate/load limit
retry and dead-letter behavior
source changes during the run
per-chunk and global reconciliation
```

Avoid offset-based progress when concurrent writes can shift the data set.
Make restart behavior explicit and distinguish processed, committed, verified,
skipped and failed records.

During dual-read/write periods, measure divergence rather than assuming both
paths agree. Define source of truth, conflict resolution, shadow comparison,
cutover threshold, and how late writes are reconciled.

## Rollback

State explicitly:

- what is reversible;
- what is irreversible;
- whether rollback loses data;
- whether backup/restore is required;
- whether old code can read new state.

Rollback may be less safe than roll-forward after destructive writes or
external side effects. Maintain a phase-by-phase recovery matrix covering code,
schema, data, configuration, queues/events, and generated artifacts. Verify
backup restoration when it is part of the claimed recovery path.

## Verification

Include, when relevant:

- migration on representative data;
- rollback or restore path;
- mixed-version compatibility;
- idempotency;
- restart behavior;
- performance impact;
- data-integrity checks.

For online DDL, inspect the exact database/version semantics. “Concurrent” or
“online” can still require waits, additional scans, CPU/I/O, cleanup of invalid
artifacts, or restrictions outside a transaction.

## Current research leads

- PostgreSQL current CREATE INDEX/CONCURRENTLY semantics:
  https://www.postgresql.org/docs/current/sql-createindex.html
- SWE Refactor Bench migration-completeness evaluation (preprint):
  https://arxiv.org/abs/2608.23564

Treat benchmark results as an empirical warning to verify both completion and
behavior, not as a universal agent success rate.
