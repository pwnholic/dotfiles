# Fuzzing and Oracle Design Playbook

Load for fuzzing, property-based testing, differential testing, or when exploit discovery depends on test-oracle quality.

## Rule

Fuzzing is only as good as:

```text
input/state generator
+ reachable state space
+ oracle/property
```

A clean fuzz run proves only that the chosen oracle did not observe a violation in the explored space.

## Strong Oracles

Prefer security properties/invariants over crash-only oracles.

Examples:

- conservation/accounting invariants;
- authorization invariants;
- nonce/replay uniqueness;
- message provenance;
- monotonic state;
- collateralization;
- privilege non-escalation.

## Oracle Validation

Challenge the oracle itself.

Use when appropriate:

- mutation testing;
- negative controls;
- differential testing;
- metamorphic relations;
- known-invalid state injection in safe environments;
- cross-implementation comparison.

Ask:

> Would this harness detect a plausible wrong implementation?

## Stateful Fuzzing

For stateful systems, fuzz sequences, not only individual calls.

Vary:

- ordering;
- repetition;
- callbacks;
- retries;
- delayed execution;
- concurrent/interleaved actions.

## Coverage

Treat code coverage as search telemetry, not evidence of security.
