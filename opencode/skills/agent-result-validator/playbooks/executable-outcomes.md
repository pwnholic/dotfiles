# Executable Outcomes Playbook

Load when the candidate claims a code, filesystem, build, test, database,
migration, deployment, configuration, or other externally observable state
change.

## Bind Candidate and State

Record the exact validation target before running checks:

```text
repository / revision / working tree
candidate diff and generated artifacts
runtime, dependencies, configuration, fixtures
database/schema/data state when relevant
deployment/environment identity when relevant
claimed commands, timestamps, outputs, and exit status
```

Inspect pre-existing and unrelated changes separately. Do not attribute the
entire current state to the candidate agent.

## Outcome First

Translate completion claims into observable predicates:

```text
claim               stronger observation
"file updated"      exact content/metadata at intended path
"tests pass"        relevant assertions pass in bound environment
"bug fixed"         old witness fails before and passes after causal change
"migration done"    target state plus old-path removal/transition completeness
"deployed"          intended artifact/config is active in target environment
"rollback works"    recovery path executed or bounded by explicit evidence
```

An exit code establishes process termination, not the intended state. Logs and
screenshots are secondary when the resulting state can be inspected directly.

## Independent Replay

Choose the smallest safe replay capable of observing each claim:

1. inspect the candidate diff and target state;
2. reconstruct or locate the relevant acceptance oracle;
3. reproduce the claimed positive behavior;
4. test a negative or boundary case that the candidate did not author;
5. verify preservation of affected existing contracts;
6. inspect completeness separately for refactors, migrations, removals, and
   rollouts;
7. bind every result to the environment and candidate state.

Do not rerun destructive, production-impacting, paid, or externally visible
actions without appropriate authorization. Prefer read-only observation,
isolated fixtures, snapshots, local replicas, or dry runs.

## Causal and Oracle Challenge

Where valuable, preserve:

```text
positive       intended predicate holds
counterfactual suspected cause/fix removed or weakened and predicate changes
negative       invalid input/state is rejected or safely handled
preservation   required prior behavior remains true
completeness   obsolete mechanism is absent or disconnected
```

Inspect whether candidate-authored tests merely restate implementation details,
skip critical paths, depend on stale fixtures, swallow errors, or pass through a
fallback. Use mutation, differential, property, metamorphic, or independent
acceptance checks only when they increase defect-detection capability.

## Environment and Freshness

Register material divergence between candidate evidence and validation:

```text
dimension | claimed environment | observed environment
effect on claim | direction of bias | resolution
```

Include versions, flags, platform, network access, credentials/roles, time,
parallelism, seed, external services, and state snapshots when causal. A pass in
one substitute environment does not silently transfer to another.

Classify nondeterministic results and report repetitions rather than rerunning
until green. After any repair or material state change, invalidate the affected
evidence and replay the minimum sufficient checks.

## Completion

Report the exact inspected artifact/state, commands or observation methods,
positive and negative evidence, failures/skips/flakiness, environment
divergence, and residual gaps. Do not modify the candidate during the audit
unless the user separately authorizes repair and the workflow hands off first.
