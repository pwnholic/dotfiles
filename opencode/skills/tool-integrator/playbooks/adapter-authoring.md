# Adapter Authoring Playbook

Load when creating or revising a maintained tool adapter.

Read [adapter-contract.md](../references/adapter-contract.md) before editing an
adapter. The contract is normative for this repository; tool documentation is
evidence used to populate it.

## Preconditions

Before authoring, have:

```text
resolved identity and observed version
canonical source/documentation
relevant help/schema captured
command effect and exposure classification
at least one locally observed calibration path where feasible
known unsupported claims and environment gaps
```

If only documentation is available, write a provisional adapter that clearly
labels unobserved semantics. Do not manufacture a calibration record.

## Adapter Design

Keep the adapter focused on decisions another agent cannot safely infer from a
command name alone:

- when the tool is causally useful;
- when a simpler mechanism is better;
- exact freshness and state prerequisites;
- safe read-only or local-derived-state invocations;
- which actions need separate authorization;
- external data/cost/credential exposure;
- what evidence the output can and cannot establish;
- post-action checks and conflict handling;
- version/configuration changes that reopen calibration.

Do not copy exhaustive help or vendor marketing. Link authoritative references
and retain only concrete examples that prevent likely misuse.

## Command Risk Matrix

Classify commands at the most consequential reachable effect, including default
behavior, flags, hooks, plugins, environment variables, and external providers.

```text
invocation | effect class | target/state | network/data
authority | idempotency | post-check | evidence maturity
```

One command may require multiple rows when a flag changes risk, such as local
versus cloud embeddings, dry-run versus apply, or stdio versus network server.
Unknown defaults remain `UNKNOWN_EFFECT` rather than optimistic read-only.

## Evidence Maturity

Label significant adapter claims:

```text
OBSERVED       executed and resulting state inspected
SOURCE_BOUND   confirmed in version-pinned implementation
DOC_BOUND      stated in version-pinned producer documentation
INFERRED       reasoned from other evidence
UNKNOWN        not established
```

The adapter's `calibration-level` frontmatter records the strongest overall
level, but individual sections preserve weaker claims.

## Change and Review

When updating an adapter:

1. compare observed tool identity/version/configuration with the recorded bind;
2. identify affected commands and claims;
3. invalidate only those calibration records;
4. re-run safe probes for changed causal behavior;
5. update risk, exposure, examples, and reopen triggers;
6. validate repository schema and links.

Do not treat a changelog as sufficient runtime evidence. Do not retain stale
examples that use removed or behavior-changing flags.

## Completion

An adapter is ready when another specialist can select and invoke the tool
without guessing its authority, state, evidence scope, or blind spots. Static
schema validity alone does not establish behavioral accuracy.
