# Fuzzing and Oracle Design Playbook

Load when search quality depends on property/oracle design, reachable state
generation, sequence depth, feedback, differential execution, or failure
minimization.

## Objective

```text
useful fuzzing
= reachable transitions × state depth × composition
× independent oracle × informative feedback × reproducible failure
```

A clean campaign is bounded by its actors, generator, sequence grammar,
environment, dependencies, and oracle.

## Oracle design

Derive properties from security claims, not implementation outputs. Useful
classes:

```text
INVARIANT | POSTCONDITION | DIFFERENTIAL | METAMORPHIC
REFERENCE_MODEL | ECONOMIC_OBJECTIVE | TEMPORAL
CROSS_DOMAIN | LIVENESS
```

Common families include conservation, solvency, privilege non-escalation,
nonce/message uniqueness, legal state transitions, preview/execution
consistency, bounded rounding, no profitable pure cycle, cross-chain supply,
upgrade compatibility, and reachable exit/settlement.

Keep the oracle independent through a specification, conservation law,
simplified model, alternate implementation, or observable balance/state
relation. If target and oracle share the same formula or helper, the campaign
may certify the same bug twice.

Validate every critical oracle with a targeted mutation or negative control:
wrong rounding, missing authorization/freshness/update, duplicate consumption,
or skipped accounting. A surviving security mutation is an oracle blind spot.

## Reachable state generation

Use stateful sequences whenever history matters. Build handlers from legal
attacker transitions and track ghost state for contributed, borrowed, repaid,
received, minted, burned, and protocol-owed value.

Model multiple real positions: user, LP, borrower, liquidator,
permissionless keeper, callback contract, delegated/smart account, and
protocol-visible relayer/bundler. Privileged actors belong in a separate abuse
model. Never use prank/impersonation as proof of unprivileged capability.

Bias generation toward semantic boundaries:

- zero, one, dust, unusual decimals;
- first/last user and empty/depleted markets;
- thresholds, ticks, caps, epochs, expiries and freshness bounds ±1;
- loss/depeg, thin liquidity, imbalanced pools;
- repeated rounding cycles and near-realistic accumulator limits;
- pause, upgrade, retry, cancellation and finality boundaries.

Every `assume`, bound, actor restriction, selector exclusion, and mock removes
part of the state space. Record why it is sound.

## Backward-derived targets and sequence grammar

Start from a violated predicate and derive:

```text
failure predicate
← required bad state
← predecessor state
← legal transition that creates it
← attacker-controlled input and capability
```

Encode these as state targets, not hard-coded exploit scripts. Include
reorder/repeat/omit, split-vs-combined operations, callback insertion,
failed-then-retried actions, same-transaction composition, and multi-block or
cross-domain sequences.

Use real external components when their callbacks or economics matter. With a
mock, enumerate preserved semantics and removed attack surfaces. Pin fork tests
to a reproducible block/slot and retain a production-parity diff; forks still
simplify mempool, sequencer, keeper, bridge, and future-state behavior.

## Multi-signal feedback

Track a vector rather than branch coverage alone:

```text
control-flow novelty
state-write / storage-region novelty
call/CPI/message-edge novelty
state-machine phase and sequence-prefix novelty
security-property distance
economic objective delta
revert-class novelty
dependency/configuration novelty
```

Weight semantic mutations by:

```text
score = reachability_gain × property_proximity × blast_radius
        × novelty / estimated_cost
```

This is a prioritization heuristic, not a probability. Calibrate it against
known-positive, near-miss, and negative seeds.

On a plateau, identify which dimension is flat before changing tactics:

- shallow state → deepen or seed reachable prefixes;
- weak feedback → add property-distance or state-write signals;
- revert dominance → repair handlers and classify reverts;
- narrow composition → add actors/dependencies/configurations;
- weak oracle → mutate and independently re-derive it;
- expensive search → isolate a subsystem, then reintegrate.

Adaptive/multi-feedback fuzzing is a method lead until it outperforms a fixed
baseline on the target.

## Economic search

Track feasibility and objective separately:

```text
feasibility: legal path, capital/liquidity, gas/compute, timing/finality
objective: attacker net value, protocol equity/loss, bad debt, supply drift
```

The harness must count flash-loan repayment, fees, slippage, price impact,
priority costs, unwind inventory, and attacker loss at risk. Optimize the
sequence and parameters only inside the feasible region.

## Failure handling

For each failure preserve:

```text
seed and tool/version | target commit/address/block
actors and initial state | environment/config/dependencies
full sequence | minimized sequence | state/value diff
oracle result | replay count | nondeterminism
synthetic powers | production-parity gaps
```

Classify expected reverts, harness errors, environment divergence, and property
violations separately. Minimize without deleting causal setup. Require stable
replay or explicitly label nondeterminism.

## Coverage and closure

Report coverage by security property, actor, transition, sequence depth,
configuration, dependency, and production-state family. Mutation score,
revert distribution, corpus growth, and time-to-reproduce are useful
calibration metrics; none is a security percentage.

Handoff only the property, generator/grammar, feedback vector, minimized trace,
environment, oracle independence, coverage gaps, and synthetic-state ledger.

For Foundry targets, re-check the current
[invariant-testing semantics](https://getfoundry.sh/forge/invariant-testing).
Maintainer-only empirical method evidence is centralized in
[research-basis.md](../references/research-basis.md).
