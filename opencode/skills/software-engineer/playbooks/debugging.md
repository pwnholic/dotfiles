# Debugging Playbook

Load for crashes, incorrect behavior, flaky failures, unexpected state, build/runtime errors, or unclear root cause.

## Goal

Find the actual mechanism, not the most plausible story.

## Loop

```text
symptom
→ reproduce
→ localize
→ competing hypotheses
→ discriminate with evidence
→ root cause
→ minimal fix
→ regression verification
```

## Rules

- Reproduce before fixing when practical.
- Preserve multiple plausible causes early.
- Check cheap explanations when cheap to falsify:
  - typo/syntax;
  - configuration;
  - environment;
  - inputs/state;
  - local logic;
  - dependency/runtime behavior;
  - concurrency/timing;
  - architecture.
- Treat surprising logs/tests as evidence, not noise.
- Check whether multiple signals share the same fixture, mock, config, or assumption.
- Trace callers and state transitions around the failure.
- If behavior depends on a library/runtime/framework, inspect its actual version and reproduce the dependency behavior directly when material.
- After roughly 2–3 focused attempts with the same theory, stop repeating and change the hypothesis or design.

## Evidence Packet

Capture enough state to discriminate causes:

```text
expected vs observed behavior
first/last known good state
source revision and dirty state
inputs, configuration, environment and dependency versions
timeline and correlation/request/job identifiers
logs, traces, metrics, state diffs and stack/error data
reproduction frequency and nondeterminism
hypotheses tested, evidence against, and remaining uncertainty
```

Correlate signals by identity and time before inferring causality. A log,
metric spike, trace, or recent change can share a cause without causing the
failure.

## Flaky and Environment-Sensitive Failures

Flakiness is an execution property, not necessarily visible in test code.
Vary and record:

- order, seed, repetition and parallelism;
- clock/time zone, filesystem, locale and network;
- CPU/memory pressure and scheduler timing;
- dependency/service versions and external state;
- isolation, cleanup, leaked processes/resources and shared fixtures.

Preserve at least one passing and failing execution with the same source state
when possible. Quarantine may protect CI throughput, but it is not a fix and
must retain owner, evidence, impact, and exit condition.

## Causal Root-Cause Gate

Before claiming root cause, require:

1. the mechanism explains the observation;
2. a discriminator separates it from serious alternatives;
3. changing or removing the cause changes the outcome;
4. the explanation covers timing/state/environment conditions;
5. the proposed fix prevents recurrence without masking the signal.

## Bug-Fix Proof

Prefer:

```text
before fix → reliable failure
after fix  → same scenario succeeds
existing relevant behavior → still succeeds
```

If reproduction is impossible, state the environment gap and do not invent a root cause.

## Current research leads

- Google SRE troubleshooting methodology: https://sre.google/sre-book/effective-troubleshooting/
- OpenTelemetry trace/log correlation: https://opentelemetry.io/docs/specs/otel/logs/
- Limits of code-only flaky-test detection (preprint):
  https://arxiv.org/abs/2607.09345
- Reproducible flaky-failure dataset (preprint):
  https://arxiv.org/abs/2605.21677

Treat empirical papers as priorities and method leads, not project-specific
facts.
