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

## Validate Data Assumptions

Check realistic data for assumptions such as:

- uniqueness;
- nullability;
- referential integrity;
- encoding;
- cardinality;
- size;
- legacy values.

## Rollback

State explicitly:

- what is reversible;
- what is irreversible;
- whether rollback loses data;
- whether backup/restore is required;
- whether old code can read new state.

## Verification

Include, when relevant:

- migration on representative data;
- rollback or restore path;
- mixed-version compatibility;
- idempotency;
- restart behavior;
- performance impact;
- data-integrity checks.
