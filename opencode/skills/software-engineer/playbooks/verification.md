# Verification Playbook

Load for any meaningful behavioral change, bug fix, compatibility-sensitive change, or high-risk implementation.

## Verification Is Claim-Specific

Ask:

> What evidence is capable of establishing the exact claim being made?

A compiler proves syntax/type/build properties, not runtime behavior.

A unit test proves only the exercised unit under its fixtures.

An integration test proves the tested integration, not every deployment.

## Two Required Directions

Where applicable:

```text
fail → pass
```

shows the required new/fixed behavior.

```text
pass → pass
```

shows preservation of existing guarantees.

## Layered Verification

Choose proportionately:

- syntax / type check;
- focused unit tests;
- component tests;
- integration tests;
- end-to-end tests;
- full project suite;
- build/package checks;
- lint/static analysis;
- migration checks;
- rollout checks;
- performance measurement.

Do not mechanically run every layer after every edit.

## Claim-to-Evidence Matrix

For each material claim record:

```text
claim | risk/blast radius | observing oracle
environment/fixture | positive case | negative/counterfactual
compatibility case | evidence state | uncovered dimensions
```

Cover affected contracts across inputs, outputs, errors, side effects, state,
ordering, persistence, performance and compatibility. Line coverage is
telemetry; it does not show that assertions can detect the relevant defect.

## Test-Oracle Quality

Passing tests are not enough when the test itself may be weak.

For medium/high-risk logic, consider:

### Negative Control

Intentionally break the relevant behavior locally and confirm the test fails.

### Mutation Testing

Introduce plausible incorrect variants and check whether the suite detects them.

### Property-Based Testing

Test invariants over generated input/state space.

### Metamorphic Testing

When exact output is hard to specify, verify relationships that must remain true across transformed inputs.

### Differential Testing

Compare against another implementation/version/oracle when appropriate.

### Independent Acceptance Oracle

Use an independently derived expected behavior rather than restating the implementation.

## Causal Witnesses

For a bug fix or behavior change, preserve:

1. **before** — the exact old state fails the intended predicate;
2. **after** — the same state succeeds after the change;
3. **counterfactual** — removing/weakening the fix makes the predicate fail;
4. **preservation** — relevant legitimate behavior remains unchanged.

For refactors and migrations, add a separate completeness check that proves the
old mechanism was actually replaced rather than copied, bypassed, or retained
behind a fallback.

## Nondeterminism and Agent-Generated Changes

Classify a result as deterministic, flaky, probabilistic, or unreproduced.
Record seed, repetition, order, parallelism and environment where material.
Repeated pass/fail counts are evidence; rerunning until green is not.

Do not accept a patch solely because a fixed test suite passes. Inspect whether
the tests exercise the requirement, whether the diff contains accidental
shortcuts, and whether the process relied on stale fixtures, hidden grader
artifacts, broad skips, swallowed errors, or unrelated fallbacks.

## Evidence Freshness

Record the source/config/environment state for important verification.

After material changes, invalidate stale evidence and rerun only the affected checks.

## Completion

Never describe verification more broadly than what actually ran.

Report claims established, environment/state binding, failures, flaky or
skipped checks, stale evidence, and residual uncertainty.
