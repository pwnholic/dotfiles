# Multi-Agent Research Playbook

Load only when multiple researchers or agents are explicitly active. The root
researcher owns scope, the shared model, contradiction resolution, and final
claims.

## Decompose by security question

Assign materially different uncertainties rather than duplicate generic
reviews:

```text
accounting/solvency | authority/upgrades | state sequences
oracle/liquidation | callbacks/hooks | signatures/AA/delegation
bridge/L2/finality | runtime/compiler | configuration/deployment
variant/patch analysis | independent falsification
```

Every assignment must include:

```text
question and property
target identity and allowed files/deployments
attacker baseline and forbidden assumptions
required evidence/output
known dependencies and blockers
stop/promotion condition
```

## Parallel execution

When multiple agents are authorized and assignments have no state dependency,
run them concurrently across distinct exploit families, attacker positions,
models, or falsification questions. Sequence work only where one assignment
requires another's evidence. Parallelism never broadens scope, permissions, or
target access.

Reserve capacity for neglected surfaces rather than assigning every agent to
the currently strongest lead. Reallocate an agent only after recording the
coverage or evidence its previous assignment produced.

## Shared model, independent search

Share stable facts—target identity, scope, assets, invariants, deployment map,
and evidence IDs—but do not prime all agents with the same exploit narrative.
Use blind-ish independent review when correlation risk matters.

Track an assumption dependency graph:

```text
claim/hypothesis → semantic/configuration assumptions → evidence owner
```

When a shared assumption changes, invalidate only dependent conclusions and
notify their owners.

## Evidence objects

Agents return structured objects, not confidence prose:

```text
id | property | observation/inference/hypothesis
exact target state | actor/capability | mechanism
reproduction/trace | dependencies | evidence level
counterevidence | blocker/reopen condition | residual unknowns
```

Failed paths remain in the shared ledger.

## Diversity and correlation

Maintain a diversity budget across:

- security question and attacker position;
- code/state/message/economic view;
- static, dynamic, differential, historical, and formal method;
- independent oracle or model;
- target version/configuration/deployment;
- discovery vs adversarial falsification.

Five agents applying the same checklist or shared weak oracle are one
correlated pass. Count independent evidence only when assumptions and failure
modes differ materially.

Calibrate agents with small known-positive, near-miss, and negative tasks when
the engagement is large enough to justify it. Record false-negative and
false-positive patterns; self-reported confidence is not calibration.

## Synthesis

The root researcher continuously:

1. normalizes target identity and claim schema;
2. merges exact duplicates by mechanism and violated property;
3. separates variants that differ in reachability, configuration, or impact;
4. converts contradictions into a discriminator;
5. composes cross-domain edges and checks capability provenance;
6. assigns validation and variant search only after mechanism quality warrants
   them;
7. reports residual coverage without agent-vote arithmetic.

Resolve contradictions by inspecting evidence or running a discriminating
test, never by majority vote.

Run this synthesis loop after any material evidence update, contradiction,
durable blocker, target/configuration change, finding promotion, or search
plateau. At each trigger, invalidate dependent assumptions, reprioritize the
portfolio, redirect or split assignments, and launch a materially different
hypothesis against neglected surface when useful.

## Independent validator

Every concrete finding must receive an independent adversarial validation
before promotion to `PRODUCTION_FEASIBLE` or `IMPACT_CONFIRMED` whenever a
second authorized researcher or agent is available. Give the validator the
target, claim, reproduction, and raw evidence without the desired verdict.
Ask it to attack target identity, capability provenance, reachability, harness
powers, dependency closure, economics, and alternative explanations.

If no independent validator is available, record that limitation, apply the
causal witness bundle and stronger negative controls from
`exploit-validation.md`, and do not imply that independent validation
occurred. Unavailability alone does not falsify otherwise reproducible
evidence.

## Completion

Report:

```text
question-to-owner allocation
shared assumptions and changes
independent vs correlated evidence
contradictions and their discriminators
deduplicated findings/variants
negative evidence and uncovered questions
```

Do not close work merely because every assignment returned.

## Research lead

Use empirical work on the human side of smart-contract fuzzing to design
division of labor and tooling feedback, but validate transfer to the current
team and target rather than turning study observations into universal rules.
