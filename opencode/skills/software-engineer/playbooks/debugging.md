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

## Bug-Fix Proof

Prefer:

```text
before fix → reliable failure
after fix  → same scenario succeeds
existing relevant behavior → still succeeds
```

If reproduction is impossible, state the environment gap and do not invent a root cause.
