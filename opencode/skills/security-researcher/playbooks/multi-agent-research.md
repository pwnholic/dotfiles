# Multi-Agent Security Research Playbook

Load when multiple agents/researchers are available.

## Principle

Parallel discovery can improve hypothesis diversity, but collaboration also creates expectation, communication, and duplicated-work failures.

Use:

```text
parallel independent exploration
→ centralized synthesis
```

## Good Assignment Diversity

Examples:

- authorization / privilege;
- state-machine / sequence;
- oracle / accounting;
- economic / MEV;
- cross-contract/protocol;
- cross-chain / message provenance;
- runtime/dependency;
- configuration variants.

## Avoid

Do not assign every agent the same leading hypothesis unless they have explicitly different roles such as:

- exploit constructor;
- falsifier;
- environment reproducer;
- independent validator.

## Assignment Contract

Each agent receives:

```text
SURFACE
EXPLOIT FAMILY
STARTING PRIVILEGE
PROPERTY
PRIMARY HYPOTHESIS
ALTERNATIVE HYPOTHESIS
ASSUMPTIONS TO CHALLENGE
EVIDENCE REQUIRED
NON-GOALS
OUTPUT FORMAT
```

## Root-Agent Duties

The root agent:

- detects duplicate exploration;
- preserves portfolio diversity;
- combines cross-surface findings;
- identifies contradictions between agents;
- marks blocked/exhausted paths;
- decides when concentration is justified;
- invalidates stale evidence after target state changes.

Composition across agents remains the root agent's responsibility.
