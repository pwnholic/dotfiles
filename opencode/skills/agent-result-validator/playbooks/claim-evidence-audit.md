# Claim and Evidence Audit Playbook

Load when the candidate is primarily a report, research synthesis,
documentation set, architecture, plan, recommendation, or other claim-heavy
artifact rather than an executable state change.

## Reconstruct the Intended Claims

Do not grade prose quality before reconstructing what the artifact must
establish.

```text
required question or decision
→ material claims and conclusions
→ evidence each claim would require
→ coverage, contradiction, and applicability checks
```

Separate:

```text
source observation
candidate interpretation
causal inference
forecast or recommendation
value judgment
unknown or assumption
```

A cited claim can still be unsupported if the source is irrelevant, outdated,
misread, too narrow, or incapable of supporting the conclusion.

## Source Audit

For each causal external claim, record:

```text
claim | source | source class | publication/retrieval date
exact supporting location | version/state | applicability boundary
contradiction | freshness trigger | status
```

Prefer primary, version-pinned, and authoritative sources. Inspect the source,
not merely a search snippet, title, citation count, or another agent's summary.
Verify that links, identifiers, dates, quoted text, and attributed findings
exist and mean what the candidate says.

Respect copyright and access constraints. A source that cannot be inspected is
not independently verified; classify it accordingly.

## Reasoning Audit

For every material conclusion ask:

- Does it follow from the cited observations without an unstated bridge?
- Are correlation, mechanism, prediction, and recommendation kept distinct?
- Were transfer limits from a benchmark, population, organization, or version
  preserved?
- Were contradictory sources or counterexamples omitted?
- Does the conclusion survive the strongest plausible alternative explanation?
- Is a qualitative uncertainty disguised by a precise score or number?

Use counterfactual claims to expose weak reasoning: what source finding, if
reversed or removed, would change the conclusion? If no evidence could change
it, the statement is a preference or unfalsifiable assertion, not a validated
empirical conclusion.

## Coverage and Omission

Trace every original requirement to an artifact location and status:

```text
requirement | artifact section | evidence | status | omission impact
```

Check non-goals, exceptions, failure cases, stakeholder concerns, alternatives,
and operational consequences only when required by the frozen contract. Do not
reward length or punish concision independently of required coverage.

For architecture and plans, validate internal coherence and traceability, not
future execution. A plausible design is not proof that capacity, reliability,
security, migration, or rollout outcomes will hold.

## Adversarial Controls

When risk warrants, try:

- a source with the same keywords but opposing applicability;
- removal of the strongest citation to see which conclusions collapse;
- verification from an independently located primary source;
- a boundary case outside the candidate's favored examples;
- date/version substitution to reveal freshness dependence;
- blinded review of substance without author identity or stylistic packaging.

Do not manufacture disagreement for balance. Record negative searches and
unresolved contradictions when they materially bound the verdict.

## Completion

Return claim-level support, source provenance, reasoning gaps, requirement
coverage, contradictions, and a scoped verdict. Do not label a document
factually correct merely because its citations resolve or its prose is
professional.
