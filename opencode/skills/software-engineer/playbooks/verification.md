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

## Evidence Freshness

Record the source/config/environment state for important verification.

After material changes, invalidate stale evidence and rerun only the affected checks.

## Completion

Never describe verification more broadly than what actually ran.
