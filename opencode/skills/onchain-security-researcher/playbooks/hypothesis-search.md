# Hypothesis Search Playbook

Load when the main uncertainty is where an exploitable security-property
violation may exist and how to search without collapsing onto one familiar bug
class.

## Objective

A useful hypothesis is falsifiable and causal:

```text
Given attacker capability A and reachable state S,
sequence Q causes mechanism M because assumption/check C fails,
violating property P and producing observable effect O.
```

Record what would support, falsify, or materially reprioritize it. “Function X
looks suspicious” is an anomaly, not yet a hypothesis.

## Search inputs

Begin with the control-plane target binding and domain backbone. Extract:

- assets, liabilities, claims, authority, and exit rights;
- state/value/call/message graphs;
- legal lifecycle transitions and asynchronous phases;
- privileged and permissionless writers;
- external semantic dependencies and deployment/configuration variants;
- trust assumptions stated by specifications, tests, or integrations;
- production concentrations of value, approvals, or authority.

Preserve anomalies even before an exploit story exists:

```text
unexpected state delta | asymmetric validation | unit mismatch
identity translation | stale/pending state | odd failure/retry
check-effect distance | dormant authority | deployment divergence
```

## Hypothesis generators

Use several materially different generators.

### Invariant negation

Negate each property and ask which transition could make it true:

```text
unauthorized value movement
unbacked or duplicated claim
privilege increase without intended transition
consumed message/nonce used twice
invalid price accepted
exit/settlement becomes unreachable
old state interpreted unsafely by new code
```

### Transition mutation

Reorder, repeat, omit, partially complete, fail/retry, callback between phases,
batch in one transaction, prepare across blocks, cross pause/upgrade/epoch/
finality boundaries, and use first/last/depleted states.

### Authority and dormant capability

Trace role-admin edges, upgrade/emergency paths, modules, delegates, approvals,
permits, old signers, solver targets, PDAs/capabilities, and indirect calls.
Ask whether a capability that was safe when granted becomes dangerous after
code, configuration, price, or integration changes.

### Resource–check–effect graph

For every protected resource connect:

```text
resource/authority
→ identity or state check
→ representation/domain conversion
→ call/message path
→ state/value effect
```

Search missing checks, checks on the wrong identity/domain/version, paths that
bypass a check, and effects that outlive the condition checked. This is
especially effective across bridges, routers, hooks, modules, and proxy layers.

### Accounting and economic contradiction

Search unit/scale/rounding differences, preview/execution drift, local vs
global accounting, balance vs internal ledger, stale index/price, and
individually safe operations whose composition creates a profitable cycle.

### Differential assumptions

Compare configurations, versions, runtimes, proxy/direct execution,
canonical/wrapped assets, primary/fallback paths, synchronous/asynchronous
flows, and source/deployed artifacts wherever the protocol assumes
equivalence.

### Assurance inversion

For previously tested or formally verified areas, ask what their model excluded:
actors, state depth, configuration, external semantics, historical state,
economic realization, or oracle independence.

## Portfolio structure

Organize hypotheses by property and causal mechanism, not file name or generic
vulnerability label. Maintain diversity across:

```text
authority | accounting | lifecycle | callbacks/composition
signatures/accounts | oracle/economics | bridge/L2
runtime/build/deployment | configuration/history
```

Keep at least one simple-local baseline, several compositional candidates, and
a small allocation to anomalies that do not fit the current model. One
promising family must not consume the entire search budget.

Refresh the portfolio after a material evidence update, durable blocker,
search plateau, target/configuration change, finding promotion, or coverage
review. At each trigger, reconsider ranking and add or activate a materially
different hypothesis against a neglected property, actor, state depth,
configuration, dependency, or deployment when useful. Do not generate novelty
after the declared search space is genuinely exhausted merely to keep work
running.

## Hypothesis record

```text
ID and provenance
property / protected claim
attacker baseline
mechanism and candidate sequence
required preconditions and dependency claims
supporting and contradicting evidence
cheapest strong discriminator
evidence level
blockers and reopen conditions
related/competing hypotheses
next decision
```

Provenance is one of independent, history-assisted, patch-derived,
incident-derived, or research-method-derived. A paper or incident supplies a
lead, not target evidence.

Use distinct lifecycle states:

```text
OPEN            not yet discriminated
ACTIVE          currently being tested
FAILED_ATTEMPT  one tactic failed; hypothesis may remain live
BLOCKED         a required edge is unavailable or unresolved
EXHAUSTED       declared transformations/discriminators were completed
FALSIFIED       a necessary fact was disproved
PROMOTED        handed to exploit validation
```

Never convert a failed attempt or exhausted search into `BLOCKED` without an
actual blocking dependency. Every non-active state retains its evidence and
reopen condition.

## Prioritization

Use explicit, revisable factors:

```text
priority ∝ property importance × architecture fit × reachability
           × composition leverage × exposure × information gain
           / validation cost
```

This is ranking, not exploit probability. Avoid false precision. Increase
priority for shared value/authority sinks, weakly bound identities,
history-dependent states, high-blast approvals/delegations, and contradictions
between independent models.

Choose the cheapest discriminator that can kill or advance a major dependency:
read a slot, trace one transaction, query deployed config, construct a minimal
call, run an A/B test, or solve a narrow constraint before building a full PoC.

## Evidence and blocker attacks

Use the shared E0–E7 ladder from `SKILL.md`. For each blocker determine:

```text
what exact fact blocks the chain?
is it protocol-enforced, configuration-only, economic, temporal, or harness?
what evidence proves its scope?
can another actor/path/state/version bypass it?
which hypotheses does it prune?
what change would reopen it?
```

Do not equate “one sequence failed” with “mechanism impossible,” or “unable to
prove reachability” with “unreachable.” Conversely, stop tactical debugging
when a protocol-enforced blocker falsifies the strategy.

## Search escalation

Escalate only to reduce a named uncertainty:

- static/data-flow analysis for candidate edges;
- trace/state diff for executed effects;
- stateful fuzzing for sequence/state exploration;
- symbolic or formal analysis for narrow path/property questions;
- historical state/configuration diff for time-dependent exposure;
- runtime/dependency reproduction for semantic disputes;
- economic optimization for feasible realization.

Record what each tool could not model. Tool silence is negative evidence only
within that boundary.

## Promotion, merging, and pruning

Promote to exploit validation when mechanism, candidate constructive
reachability, causal dependencies, a complete-enough chain, and success
predicate exist. Merge hypotheses only when root mechanism and violated
property match; keep separate variants when attacker, configuration,
reachability, or impact differs.

Prune when a strong blocker falsifies a necessary edge. Preserve the evidence
and reopen condition. Exhausted means the stated search transformations and
discriminators were applied within the recorded model—not that the target has
no vulnerability.

## Coverage and closure

Report:

```text
properties and mechanisms searched
actors and sequence/state families
configuration/deployment/runtime families
high-priority hypotheses and evidence levels
blocked/falsified paths and reopen conditions
tool/model blind spots
unsearched or weakly searched regions
```

Do not measure productivity by hypothesis count or claim that the target is
exhausted.

## Research-method leads

When useful, evaluate recent state-targeted, profit-centric, adaptive
multi-feedback, approval-exposure, cross-chain graph, and historical-storage
methods against known-positive/near-miss/negative target seeds. Retain method,
dataset, artifact, date, and transfer limits; adopt only what improves
target-specific discrimination.
