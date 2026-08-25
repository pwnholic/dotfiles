# Smart-Contract Hypothesis Search Playbook

## Smart-Contract Scope Lock

This playbook belongs to a **smart-contract / DeFi security research stack**. Apply it to on-chain programs, protocols, token systems, vaults, AMMs, lending, staking/restaking, governance, account abstraction, bridges, rollups/L2s, cross-chain systems, and infrastructure only when that infrastructure is causally necessary to an on-chain security property.

Do **not** expand the default search into generic web/backend/database/desktop/cloud security. An off-chain component belongs here only when compromising or mis-modeling it can change an on-chain authorization decision, state transition, message provenance, price, ordering/finality assumption, upgrade/deployment state, or realizable economic impact.

When a concrete exploit hypothesis exists, hand validation to `exploit-validation.md`.

Load for broad vulnerability discovery.

This playbook treats vulnerability research as a controlled search over falsifiable security hypotheses.

The objective is not to produce many plausible bug stories. The objective is to maximize useful information about the attack surface until a hypothesis is confirmed, rejected, or closed with defensible evidence.

---

## 1. Search Doctrine

A vulnerability hypothesis is a claim that:

1. names a security property that may fail;
2. names the attacker-controlled or attacker-influenced condition;
3. proposes a concrete path by which the failure could occur;
4. predicts an observable result;
5. can be disproved by evidence.

Do not count vague suspicion as a hypothesis.

Bad:

```text
The accounting may be wrong.
```

Better:

```text
If share minting uses stale totalAssets while withdrawal updates the same backing state later in the transaction sequence,
an attacker may receive more claim on assets than the value contributed.

Trigger candidate:
deposit → external/state transition → second deposit or withdrawal

Observable:
attacker_value_after > attacker_value_before + legitimate_yield
```

Hypothesis search is iterative:

```text
observe
→ hypothesize
→ choose cheapest discriminator
→ test
→ interpret evidence
→ refine / fork / reject / confirm
→ search for siblings
```

Do not confuse thinking longer with searching better.

---

## 2. Build the Search Frame Before Generating Hypotheses

Create a compact model of the target first.

Record:

- externally reachable entry points;
- assets and security-sensitive state;
- privileged identities and authority transitions;
- trust boundaries;
- state writers;
- external calls and callbacks;
- parsers / decoders / serializers;
- arithmetic and accounting boundaries;
- persistent mappings / arrays / indexes / checkpoints / cached on-chain aggregates;
- asynchronous or cross-domain messages;
- upgrade / initialization / migration paths;
- configuration inputs;
- dependency/runtime assumptions;
- observability available to the researcher.

The model does not need to be complete before search starts. It must be sufficient to identify where a security claim is enforced.

Every later discovery should be allowed to update this model.

---

## 3. Start From Security Claims, Not Vulnerability Names

Ask:

- what must never happen?
- what must always eventually happen?
- what asset is protected?
- who may cause the protected transition?
- what mechanism enforces the property?
- what state must agree with what other state?
- what does the system trust but not control?
- what data crosses a trust boundary?
- what operation assumes uniqueness, freshness, ordering, finality, or atomicity?
- what behavior is safe only because another component is expected to behave correctly?

Convert answers into explicit claims.

Examples:

```text
Only an authorized principal can move asset X.

For every issued claim token, sufficient backing remains reachable.

A message accepted in domain A cannot be replayed in domain B.

A failed partial operation cannot leave a privileged intermediate state reachable.

No externally controlled callback can observe or mutate an inconsistent accounting state.
```

A useful claim exposes an enforcement mechanism that can be attacked.

---

## 4. Hypothesis Record

Every ACTIVE hypothesis should have a record.

```text
ID:
Parent:
Seed:

Property at risk:
Attacker capability:
Attacker-controlled variables:
Trusted assumption being challenged:
Candidate sink / sensitive state:

Required preconditions:
Candidate trigger path:
Expected observable:

Known blockers:
Unknowns:
Cheapest next discriminator:

Evidence for:
Evidence against:
Sibling / variant hypotheses:

Status:
Priority:
Confidence:
Reopen condition:
```

If the trigger path and observable cannot be stated yet, keep the item as an `OBSERVATION`, not an `ACTIVE` hypothesis.

---

## 5. Hypothesis Seeds

Do not generate hypotheses from one source only.

Maintain multiple seed streams.

### 5.1 Property seed

Start from an invariant or security claim and ask how it could be falsified.

### 5.2 Sensitive-sink seed

Start from a dangerous effect:

- asset movement;
- privilege grant;
- arbitrary call;
- state deletion;
- deserialization;
- memory access;
- signature acceptance;
- price / balance / share update;
- cross-domain message acceptance;
- upgrade or implementation change.

Work backward toward attacker influence.

### 5.3 Attacker-source seed

Start from attacker-controlled data and follow its influence forward until it reaches a security-sensitive decision or state mutation.

### 5.4 State-transition seed

Start from a transition that changes lifecycle, authorization, ownership, accounting mode, initialization status, or finality.

Ask what happens before, during, after, twice, partially, or out of order.

### 5.5 Differential seed

Start from two things expected to behave equivalently:

```text
implementation A vs B
old version vs new version
preview vs execution
local accounting vs external accounting
simulation vs production
EOA vs contract caller
single call vs batched call
```

Search for unexplained divergence.

### 5.6 Historical / patch seed

Start from:

- previous vulnerabilities;
- security patches;
- bug-fix commits;
- reverted fixes;
- audit findings;
- changed validation logic;
- changed bounds or indexes;
- newly added exceptions.

Extract the root cause, not merely the syntax, then search for semantic siblings.

### 5.7 Anomaly seed

Unexpected behavior is a search seed even when impact is unknown:

- surprising revert;
- inconsistent return value;
- unreachable-looking branch reached;
- unexpected state delta;
- gas / resource discontinuity;
- parser disagreement;
- different behavior after restart / upgrade / delay;
- strange error handling.

Do not require a vulnerability story before preserving an anomaly.

### 5.8 Missing-mechanism seed

If a property should require authentication, freshness, bounds, conservation, uniqueness, or synchronization, search for paths where the expected mechanism is absent rather than visibly broken.

---

## 6. Transformations Are Operators, Not a Checklist

Apply transformations to a concrete hypothesis, its preconditions, or its trigger path.

### 6.1 Invert an assumption

```text
"X is trusted"
→ what if X is attacker-influenced?
```

### 6.2 Negate a precondition

```text
requires initialized == true
→ what occurs when initialized is false, partial, stale, or reset?
```

### 6.3 Change order

```text
A → B
→ B → A
```

Also try partial orders rather than one permutation.

### 6.4 Repeat

```text
A
→ A → A → A
```

Test idempotence assumptions and cumulative drift.

### 6.5 Omit

```text
A → B → C
→ A → C
```

Search for optional-looking steps that actually establish safety.

### 6.6 Duplicate

Duplicate a supposedly unique object, message, identifier, claim, registration, callback, or transition.

### 6.7 Delay

Immediate behavior may differ under delayed execution, expiry, epoch/round change, oracle refresh, sequencer downtime, reorg/finality, bridge delay, or stale on-chain observation.

### 6.8 Compress

Move operations that normally happen over separate transactions / requests / blocks / sessions into one atomic or batched context.

### 6.9 Split

Break one expected-atomic operation across multiple calls, identities, domains, transactions, retries, or lifecycle phases.

### 6.10 Change identity

Keep data/state constant while changing:

- caller;
- owner;
- beneficiary;
- signer;
- relayer;
- delegate;
- contract vs EOA;
- privileged vs unprivileged execution context.

### 6.11 Change context

Replay or reuse the same state/message under another:

- domain;
- chain;
- market / pool / vault / chain domain;
- account;
- namespace;
- market;
- pool;
- implementation;
- lifecycle phase;
- configuration.

### 6.12 Change representation

Represent the same semantic value differently:

- encoded differently;
- normalized vs non-normalized;
- alias / canonical identifier;
- zero / empty / absent;
- boundary integer representation;
- duplicate serialization;
- reordered fields.

### 6.13 Push boundaries

Test:

```text
0
1
max-1
max
first
last
empty
single element
full capacity
just below threshold
exact threshold
just above threshold
```

Boundary transformations should include semantic boundaries, not only numeric ones.

### 6.14 Remove a required primitive

If the leading attack requires a strong primitive, search for the same impact without it.

Example:

```text
requires oracle manipulation
→ can accounting desynchronization create the same price effect?
```

### 6.15 Substitute the primitive

Replace an expensive or unrealistic attacker capability with a cheaper equivalent source of influence.

### 6.16 Add composition

Combine individually legitimate components/actions.

Search especially where each component validates only its local assumptions.

### 6.17 Move layers

If application logic looks safe, inspect assumptions supplied by:

- proxy / dispatcher / module system;
- chain runtime / VM;
- compiler / optimizer;
- contract library / token implementation;
- RPC / node client when chain semantics are causal;
- oracle / DEX / bridge / hook / external protocol;
- sequencer / relayer / keeper / bundler when causal;
- governance / upgrade infrastructure.

### 6.18 Change failure mode

Force:

- revert;
- timeout;
- short read/write;
- partial success;
- callback failure;
- dependency unavailable;
- malformed response;
- retry;
- duplicate delivery.

Then inspect residual state.

### 6.19 Preserve effect, mutate cause

Once an impact is reachable, search for alternative trigger families that produce the same effect.

### 6.20 Preserve cause, mutate effect

Once a primitive is found, enumerate every sensitive state or asset it could influence, not only the first observed impact.

---

## 7. Search as a Graph

Do not manage hypotheses as a flat list.

Represent relationships:

```text
seed observation
    ↓
H1
├── variant: different caller
├── variant: different ordering
├── variant: same root cause, different sink
└── composition: H1 + H7
```

A hypothesis may generate children through:

- precondition mutation;
- path mutation;
- context mutation;
- semantic variant search;
- alternate sink;
- alternate source;
- composition with another hypothesis;
- blocker bypass.

Keep parentage. It reveals which root causes are producing productive research branches.

---

## 8. Evidence Ladder

Do not treat all evidence as equal.

Suggested ladder:

```text
E0  intuition only
E1  code pattern / suspicious structure
E2  reachable candidate path established
E3  required state / preconditions demonstrated
E4  observable property violation
E5  deterministic reproduction
E6  attacker-feasible reproduction under realistic constraints
E7  impact quantified and alternate explanations eliminated
```

A hypothesis can become `PROMISING` before full confirmation, but a finding should not become `CONFIRMED` merely because code looks suspicious.

Evidence against a hypothesis should be recorded with the same discipline.

---

## 9. Choose the Cheapest Discriminator

For each hypothesis ask:

> What is the cheapest experiment that would substantially change my belief?

Prefer tests that distinguish competing explanations.

Examples:

- inspect one state writer before building a full exploit;
- set a breakpoint on the candidate sink;
- construct the shortest sequence reaching a suspect state;
- compare two implementations with the same input;
- mutate one assumption while holding the rest constant;
- add one targeted assertion / invariant;
- use symbolic/concolic execution only for the difficult branch constraint;
- build a minimal harness instead of fuzzing the whole application.

Do not spend exploit-development time proving a prerequisite that could have been disproved by a five-minute discriminator.

---

## 10. Strategic Loop vs Tactical Loop

Separate failures of the attack idea from failures of the current experiment.

### Tactical failure

The hypothesis may still be sound, but the current attempt failed because of:

- wrong calldata/input shape;
- environment setup;
- missing extension/dependency;
- incorrect state preparation;
- harness limitation;
- bad timing;
- instrumentation problem;
- solver/fuzzer inability to reach the branch.

Stay on the same hypothesis and repair the experiment.

### Strategic failure

Evidence attacks the hypothesis itself:

- required attacker control does not exist;
- invariant is enforced independently;
- candidate path is unreachable;
- value is authenticated before use;
- effect is reverted atomically;
- alleged state disagreement cannot coexist.

Refine, fork, block, or reject the hypothesis.

Do not enter endless tactical debugging when the strategy is dead.

Do not abandon a sound hypothesis because a harness is weak.

---

## 11. Counterexample-Guided Refinement

Treat failed hypotheses as information about the model.

When an apparent attack fails:

1. identify the exact blocking condition;
2. determine whether the blocker is fundamental or contingent;
3. update the system model;
4. search for paths where the blocker is absent, stale, bypassed, reordered, or supplied by another component;
5. generate sibling hypotheses from the new fact.

Example:

```text
H1: unauthorized withdrawal through entrypoint A

Blocked because A checks owner == caller.

Refinement:
ownership is the real enforcement point.

New search:
- who writes owner?
- can owner become stale?
- can caller identity change through delegate/callback context?
- is owner checked in every alternate withdrawal path?
```

A rejected hypothesis should make the next search better.

---

## 12. Blocker Analysis

Every blocker must be classified.

### Fundamental blocker

Derived from a mechanism that holds across all relevant states/configurations and has supporting evidence.

### Conditional blocker

Holds only under a state, configuration, caller, timing, implementation, or dependency assumption.

### Harness blocker

The experiment cannot currently reach or observe the required condition.

### Economic blocker

Technically reachable but requires unrealistic capital, cost, timing, or market depth.

### Unknown-strength blocker

Observed once but not understood well enough to close the path.

Only a strong fundamental blocker can directly justify rejection.

Conditional and harness blockers normally generate reopen conditions or variants.

---

## 13. Oracle Construction

Many security failures do not crash.

For each hypothesis define how failure will be recognized.

Possible oracles:

- invariant violation;
- unauthorized state transition;
- conservation failure;
- monotonicity failure;
- unexpected privilege increase;
- inconsistent equivalent executions;
- differential output/state;
- metamorphic relation violation;
- impossible state reached;
- liveness/resource threshold exceeded;
- economic profit / bad debt / value extraction;
- signature/message accepted outside intended domain;
- state survives a failed operation when it should not.

If no direct oracle exists, construct a relation between executions.

Example:

```text
Changing only the caller from owner to unrelated attacker
must not increase the attacker's authority over the same resource.
```

Or:

```text
Splitting an operation into two equivalent calls should not create more total assets than the atomic version.
```

Treat oracle quality as part of hypothesis quality.

---

## 14. Differential and Metamorphic Search

Use comparison when expected output is difficult to specify directly.

### Differential

Compare implementations, versions, modes, or replicas expected to agree.

Unexpected divergence becomes a new observation.

### Metamorphic

Transform the input/context while preserving a semantic relation.

Examples:

```text
same authorization state + different irrelevant metadata
→ permission result should be unchanged

same economic action split into equivalent chunks
→ aggregate value should remain equivalent within defined rounding bounds

serialize → parse → serialize
→ canonical semantics should be preserved
```

A relation violation is evidence, not automatically a vulnerability. Explain why the relation should hold.

---

## 15. Stateful and Sequence Search

Single-call reasoning is insufficient for stateful systems.

For sensitive state transitions search:

```text
A
A → A
A → B
B → A
A → fail(B) → C
A → delay → B
A(user1) → B(user2)
A(old implementation) → upgrade → B(new implementation)
A → callback → B → return to A
```

Track the smallest state variables needed to distinguish security-relevant states.

When the state space is too large, constrain search around:

- privilege transitions;
- asset ownership;
- accounting checkpoints;
- lifecycle boundaries;
- queue/head/tail changes;
- message acceptance;
- initialization;
- upgrade/migration;
- error recovery.

---

## 16. Variant Search

Once one concrete bug, anomaly, or broken assumption exists, stop treating it as an isolated event.

Extract:

```text
root cause
required semantic conditions
missing or incorrect enforcement
sensitive effect
```

Then search for variants across:

- sibling functions;
- alternate entry points;
- duplicated implementations;
- old/new code paths;
- chain/runtime-specific branches;
- ABI / message / proof decoders for related on-chain formats;
- other state writers;
- other consumers of the same trusted value;
- incomplete patches;
- backports and downstream forks.

Search semantic similarity, not textual similarity only.

A patch is a hypothesis generator.

---

## 17. Directed Tool Escalation

Tools should answer a hypothesis question.

Use broad static/search tools for localization.

Use taint/data-flow analysis when the question is whether attacker influence reaches a sink.

Use dynamic tracing/debugging when the question is what state/path actually occurs.

Use coverage-guided fuzzing for broad executable exploration when a useful oracle and harness exist.

Use directed fuzzing when the hypothesis already identifies target locations/constraints.

Use symbolic/concolic execution when a small number of hard predicates block reachability.

Use stateful/model-based fuzzing when sequence/state is the dominant uncertainty.

Use differential/metamorphic testing when the oracle is the dominant uncertainty.

Use mutation testing when the uncertainty is whether existing tests/specifications actually detect security-relevant behavioral changes.

Do not run tools ritualistically. Record which uncertainty each tool invocation is intended to reduce.

---

## 18. Coverage Is Multi-Dimensional

Do not reduce search coverage to lines or branches.

Track relevant dimensions:

```text
entrypoint coverage
state-writer coverage
security-claim coverage
trust-boundary coverage
identity/role coverage
state-transition coverage
sequence coverage
configuration coverage
dependency/runtime coverage
historical/variant coverage
oracle coverage
hypothesis-family coverage
```

Code coverage may reveal reachability gaps, but it does not prove security behavior was tested.

A search path can execute every line that matters while still missing the specific state relation required for exploitation.

---

## 19. Hypothesis Portfolio

Maintain materially different active families.

Example portfolio:

```text
authorization / identity
state-machine / lifecycle
accounting / arithmetic
parser / representation
cross-component consistency
timing / concurrency / ordering
dependency / runtime
configuration / deployment
historical variants
error handling / partial failure
resource / liveness
economic composition
```

Do not let one promising family consume all search budget.

Diversity is a search primitive, not administrative neatness.

---

## 20. Priority and Budget Allocation

Priority should answer:

> Which experiment gives the best expected security information for its cost right now?

Consider:

- potential impact;
- attacker reachability;
- evidence already accumulated;
- novelty relative to active paths;
- probability that the next test is discriminative;
- cost of the next test;
- unexploredness of the hypothesis family;
- whether the hypothesis unlocks many variants if confirmed.

Avoid fake numerical precision. Ordinal levels are usually enough:

```text
P0 immediate discriminator / high impact
P1 strong evidence / cheap next step
P2 useful but uncertain
P3 expensive or weakly grounded
P4 parking lot
```

Re-score after meaningful evidence.

---

## 21. Exploration vs Exploitation

The search process needs both.

### Exploration

Generate new hypothesis families, inspect untouched trust boundaries, sample new states, and test alternative mental models.

### Exploitation

Deepen a promising path, solve its blockers, build reproduction, and quantify impact.

If all effort is exploration, nothing gets proven.

If all effort is exploitation, the first plausible theory creates tunnel vision.

Periodically force exploration when:

- the active path has produced no new evidence;
- tactical debugging dominates;
- several hypotheses share the same assumptions;
- large coverage dimensions remain untouched.

---

## 22. Anti-Convergence Rules

For multi-agent or multi-researcher search:

- do not seed every worker with the same leading theory;
- assign different hypothesis families or different transformations;
- preserve independent observations before sharing conclusions;
- share hard facts, traces, and blockers more aggressively than speculative narratives;
- require at least one challenger to attack the assumptions of a promising hypothesis;
- periodically spawn a fresh search branch without the current dominant story.

Correlated reasoning creates correlated blind spots.

---

## 23. Merge, Fork, and Deduplicate

### Merge

Merge hypotheses when they share the same root cause and discriminator even if their wording differs.

### Fork

Fork when one unresolved assumption leads to materially different trigger paths or attacker capabilities.

### Deduplicate

Do not waste budget proving the same semantic claim through multiple cosmetic formulations.

Preserve distinct impacts even when root cause is shared.

---

## 24. Promising-Path Gate

A hypothesis becomes `PROMISING` when most of the following are true:

- the sensitive sink/state is identified;
- attacker influence is plausible or demonstrated;
- a candidate trigger path exists;
- at least one important prerequisite has been validated;
- the hypothesized property failure has a usable oracle;
- remaining blockers are concrete.

`PROMISING` means invest more search budget, not report a finding.

---

## 25. Confirmation Gate

A hypothesis becomes `CONFIRMED` only when evidence establishes:

1. the relevant path/state is reachable;
2. the security property actually fails;
3. the failure is attributable to the hypothesized mechanism;
4. attacker prerequisites are realistic for the target model;
5. the behavior is reproducible or otherwise strongly evidenced;
6. compensating controls do not eliminate the claimed impact.

A crash, revert, assertion, strange log, or static warning is not automatically a security vulnerability.

---

## 26. Rejection Gate

Reject a hypothesis only when the central mechanism has been falsified.

Record:

```text
rejected claim:
strongest attempted trigger:
decisive blocker/evidence:
why variants do not survive this blocker:
```

If only the current trigger failed, prefer `BLOCKED` or fork a variant.

---

## 27. Path Ledger

Use:

```text
OBSERVATION
OPEN
ACTIVE
PROMISING
BLOCKED
CONFIRMED
REJECTED
EXHAUSTED
MERGED
```

Definitions:

### OBSERVATION

Interesting fact/anomaly without a falsifiable attack hypothesis yet.

### OPEN

Valid hypothesis record exists but no active work is assigned.

### ACTIVE

A concrete discriminator is currently being pursued.

### PROMISING

Evidence has crossed the promising-path gate.

### BLOCKED

Progress requires bypassing or resolving a concrete blocker.

Must include blocker classification and reopen condition.

### CONFIRMED

Passed the confirmation gate.

### REJECTED

Core hypothesis falsified by evidence.

### EXHAUSTED

A hypothesis family has been searched to its defined coverage boundary without confirmation.

Requires documented coverage and remaining uncertainty.

### MERGED

Semantically subsumed by another path.

---

## 28. Blocked Path Reopen Conditions

Examples:

```text
reopen if another entry point writes owner without the same authorization check

reopen if configuration X is deployed in production

reopen if callback can execute before checkpoint Y

reopen if a different parser accepts non-canonical representation Z

reopen if the upgrade changes storage slot/layout assumption
```

A reopen condition should be searchable or testable.

"Maybe later" is not a reopen condition.

---

## 29. Stuck Recovery

When an ACTIVE path produces no useful evidence:

1. state the exact unknown blocking progress;
2. reduce it to the smallest discriminator;
3. inspect whether the obstacle is strategic or tactical;
4. mutate one precondition at a time;
5. search for an alternate path to the same sink;
6. search for an alternate sink from the same primitive;
7. use a different analysis modality;
8. inspect historical changes around the blocker;
9. hand the evidence to an independent challenger;
10. if information gain remains near zero, park or exhaust the path.

Do not repeat nearly identical attempts without recording what new information they are expected to produce.

---

## 30. Search for Chains After Local Primitives

Weak primitives often become severe only in composition.

When a primitive is confirmed, ask:

```text
What does this let the attacker read?
What does this let the attacker write?
What authority does it alter?
What assumption does another component make about this value?
Can the effect persist?
Can it be repeated?
Can it be amplified?
Can it bypass a later check?
Can it become economically meaningful?
```

Build chains from proven primitives rather than speculative chains of unproven steps.

---

## 31. Search Quality Metrics

Do not measure productivity by number of hypotheses generated.

Useful metrics include:

- hypotheses with explicit trigger paths;
- hypotheses with usable oracles;
- percentage reaching a decisive discriminator;
- confirmed findings per hypothesis family;
- rejected hypotheses with strong negative evidence;
- unique security claims tested;
- trust boundaries tested;
- state transitions tested;
- variant yield from confirmed root causes;
- time/budget spent in repeated tactical failure;
- number of dominant assumptions challenged independently;
- coverage gaps remaining at close.

High rejection rate can indicate excellent search if rejection evidence is strong and diverse search space is being covered.

---

## 32. Exhaustion Is Scoped

Never claim that "the target is exhausted."

Exhaustion must name its boundary.

Example:

```text
EXHAUSTED:
unauthorized direct-withdrawal hypotheses through externally reachable withdrawal entry points
under production configuration C
for caller/owner identity substitutions and callback reordering tested in sequences up to depth 4.

Remaining uncertainty:
upgrade path and cross-domain withdrawal adapter not covered.
```

Exhaustion requires:

- explicit hypothesis family;
- search boundary;
- transformations attempted;
- relevant states/configurations covered;
- evidence collected;
- blockers tested;
- unresolved uncertainty.

"Nothing found" is not evidence of exhaustion.

---

## 33. Global Stop Condition

Broad hypothesis search may stop when all are true:

1. high-impact security claims have active or closed coverage;
2. major trust boundaries and sensitive sinks have been seeded from more than one direction;
3. no high-value `PROMISING` path remains unresolved;
4. `BLOCKED` paths have concrete reopen conditions;
5. dominant hypothesis families have been challenged by independent alternatives;
6. historical/variant search has been performed where applicable;
7. stateful, differential, and cross-layer hypotheses have not been omitted merely because local review looked clean;
8. remaining uncertainty is documented explicitly.

Stopping means the current search budget is no longer expected to produce enough information to justify its cost.

It does not mean absence of vulnerabilities has been proven.

---

## 34. Failure Modes of the Research Process

Watch for:

### Vulnerability-name anchoring

Searching for "reentrancy" or "SSRF" instead of falsifying target-specific properties.

### Narrative inflation

A long plausible exploit story with no demonstrated path or observable.

### First-hypothesis lock-in

All subsequent research is interpreted through the first attractive theory.

### Tool ritual

Running scanners/fuzzers because they are available rather than because they answer a search question.

### Coverage theater

Using line/branch coverage as evidence that a security claim was tested.

### Premature exploit construction

Building a full exploit before cheap prerequisites have been validated.

### Premature rejection

Treating a failed testcase or harness limitation as falsification of the hypothesis.

### Infinite tactical loop

Repeatedly fixing PoC mechanics after evidence has already weakened the strategy.

### Unbounded brainstorming

Generating hypotheses faster than they can be discriminated.

### Correlated agents

Multiple workers repeating the same assumptions and calling it coverage.

### Weak oracle

Testing millions of states without a mechanism that recognizes the security failure of interest.

---

## 35. Compact Research Loop

For every active search cycle:

```text
1. SELECT
   choose a security claim, sensitive sink, anomaly, diff, or known root cause.

2. FORM
   state one falsifiable hypothesis with attacker capability, preconditions,
   trigger path, and expected observable.

3. DISCRIMINATE
   choose the cheapest experiment that can materially update belief.

4. EXECUTE
   inspect, trace, test, fuzz, solve, compare, or simulate.

5. INTERPRET
   separate tactical failure from strategic evidence.

6. UPDATE
   record evidence, blocker strength, model changes, and status.

7. TRANSFORM
   generate only the strongest semantic siblings/variants justified by new evidence.

8. SCHEDULE
   decide whether to deepen, fork, challenge, park, reject, confirm, or exhaust.

9. COMPOSE
   if a primitive is real, search for downstream impact and chains.

10. CLOSE WITH EVIDENCE
    never close with "nothing found."
```

---

## 36. Core Principle

The unit of progress is not a hypothesis generated.

The unit of progress is **uncertainty removed**.

A good hypothesis search system repeatedly converts:

```text
unknown attack surface
→ explicit security claim
→ falsifiable hypothesis
→ discriminating experiment
→ evidence
→ refined model
→ better next hypothesis
```

Confirmed vulnerabilities are one valuable outcome.

Strong negative evidence, discovered invariants, disproven assumptions, and sharply bounded unknowns are also progress because they change where the next unit of research effort should go.

## 2026 Calibration Anchors

Re-check these before an engagement when their semantics are material:

- Ethereum account delegation: https://eips.ethereum.org/EIPS/eip-7702
- Transient storage: https://eips.ethereum.org/EIPS/eip-1153
- Namespaced storage: https://eips.ethereum.org/EIPS/eip-7201
- Account abstraction: https://docs.erc4337.io/core-standards/erc-4337
- OpenZeppelin upgrade safety: https://docs.openzeppelin.com/upgrades-plugins/writing-upgradeable
- Foundry invariant testing: https://getfoundry.sh/forge/invariant-testing
- Medusa/Echidna smart-contract fuzzing: https://secure-contracts.com/program-analysis/medusa/docs/src/testing/overview.html and https://secure-contracts.com/program-analysis/echidna/basic/testing-modes.html
- L2 sequencer risk: https://docs.chain.link/data-feeds/l2-sequencer-feeds
- OP Stack withdrawal lifecycle: https://docs.optimism.io/op-stack/bridging/withdrawal-flow
- Solana program/runtime/deployment semantics: https://solana.com/docs/core/programs and https://solana.com/docs/core/programs/program-deployment
- Source/build correspondence: https://docs.sourcify.dev/docs/exact-match-vs-match/ and https://solana.com/docs/programs/verified-builds

Calibration sources are evidence about current semantics, not substitutes for target-specific source, deployment, and state verification.
