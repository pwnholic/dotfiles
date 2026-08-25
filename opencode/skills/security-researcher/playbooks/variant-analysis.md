# Smart-Contract Variant Analysis Playbook

## Smart-Contract Scope Lock

This playbook belongs to a **smart-contract / DeFi security research stack**. Apply it to on-chain programs, protocols, token systems, vaults, AMMs, lending, staking/restaking, governance, account abstraction, bridges, rollups/L2s, cross-chain systems, and infrastructure only when that infrastructure is causally necessary to an on-chain security property.

Do **not** expand the default search into generic web/backend/database/desktop/cloud security. An off-chain component belongs here only when compromising or mis-modeling it can change an on-chain authorization decision, state transition, message provenance, price, ordering/finality assumption, upgrade/deployment state, or realizable economic impact.

When a concrete exploit hypothesis exists, hand validation to `exploit-validation.md`.

Load after a concrete root cause, exploit mechanism, historical finding, or remediation seed is available.

Variant analysis is not generic bug hunting. It is a disciplined search for additional manifestations of the same security-relevant causal flaw across code, state, configuration, versions, deployments, dependencies, and architectural equivalents.

Do not declare variant analysis complete because an exact-pattern search is quiet.

---

## 1. Entry Conditions

Use this playbook when at least one of the following exists:

- an independently established root cause;
- a confirmed exploit mechanism;
- a historical vulnerability that is explicitly being used as a seed;
- a security patch whose completeness is being evaluated;
- a regression or incomplete-fix hypothesis;
- a concrete invariant violation that may have sibling implementations.

If the mechanism is still speculative, return to hypothesis search or exploit validation first.

A seed does not automatically imply that every similar-looking construct is vulnerable.

---

## 2. Core Objective

Search for sibling instances of the same underlying security failure.

The unit of equivalence is the causal security mechanism, not syntax.

Model the seed as:

```text
security invariant
+ trust / privilege boundary
+ attacker-controlled or attacker-influenced primitive
+ required preconditions
+ relevant state / lifecycle condition
+ source / entry surface
+ transformations / intermediate representations
+ sensitive operation / sink / state transition
+ expected enforcement
+ actual enforcement gap
+ resulting primitive or property violation
+ reachability constraints
+ configuration / version / deployment constraints
```

Then derive a compact reusable statement such as:

```text
attacker-controlled X
reaches or influences Y
under condition Z
without enforcement G
causing security property P to become false
```

Do not force every vulnerability into source-to-sink form. Some root causes are primarily:

- state-machine violations;
- lifecycle/reference mismatches;
- serialization/deserialization asymmetry;
- inconsistent authorization predicates;
- identity/authority confusion;
- accounting or economic invariant violations;
- temporal/order-dependent races;
- canonicalization/normalization mismatches;
- upgrade/configuration divergence;
- cross-component trust mismatches.

---

## 3. Seed Calibration Gate

Variant search MUST begin with a query or procedure that rediscovers the known seed.

Use:

```text
Q0 = minimally generalized query that matches the known vulnerable instance
```

If Q0 cannot rediscover the seed, the search procedure is not calibrated and MUST NOT be trusted for negative conclusions.

Record:

```text
seed identity
seed location
root-cause statement
query / procedure
expected match
observed match
reason the query is believed equivalent to the root cause
```

A query that cannot find the seed cannot prove the absence of siblings.

---

## 4. Abstraction Ladder

Generalize deliberately. Change one major abstraction axis at a time so loss of precision is visible.

Recommended ladder:

```text
Q0 exact vulnerable construct
Q1 identifier-independent lexical equivalent
Q2 AST / local structural equivalent
Q3 API / helper semantic equivalent
Q4 data-flow equivalent
Q5 control-flow / dominance equivalent
Q6 state / lifecycle equivalent
Q7 invariant-negation equivalent
Q8 architectural / deployment equivalent
Q9 cross-version / cross-repository equivalent
```

At every step:

1. preserve rediscovery of the seed where applicable;
2. record what was generalized;
3. inspect new matches;
4. measure false-positive growth;
5. identify newly reachable implementation families;
6. continue only after understanding what precision was lost.

Do not jump directly from one concrete line to a repository-wide fuzzy search and call the result semantic variant analysis.

---

## 5. Search Families

Use multiple search families because no single representation captures all variants.

### 5.1 Lexical and Symbol Search

Useful for:

- copied code;
- renamed helpers;
- repeated constants;
- duplicated checks;
- repeated call sequences;
- backports and forks.

Treat as an initial expansion mechanism, not a stopping point.

### 5.2 Structural / AST Search

Search equivalent syntax independent of names, formatting, and local refactors.

Useful for:

- duplicated authorization forms;
- parser/serializer shapes;
- validation-order mistakes;
- unsafe API usage;
- arithmetic or bounds patterns.

### 5.3 API-Semantic Search

Search all operations with equivalent semantics, not only the same function name.

Examples:

- alternate oracle/registry/storage lookup paths;
- equivalent transfer/mint/burn functions;
- different deserialization helpers;
- wrappers around the same privileged primitive;
- framework-specific authorization adapters.

### 5.4 Data-Flow Search

Search attacker-controlled or attacker-influenced values flowing to security-sensitive operations without equivalent sanitization or authorization.

Track transformations, aliases, wrappers, field extraction, implicit conversions, and normalization.

### 5.5 Control-Flow / Dominance Search

Search for sensitive operations that are not dominated by the required guard, validation, state predicate, or authorization decision.

### 5.6 State / Lifecycle Search

Search equivalent invalid transitions across:

- initialization;
- steady state;
- teardown;
- retry;
- rollback;
- recovery;
- migration;
- upgrade;
- partial failure;
- callback/reentrancy windows;
- asynchronous or cross-domain completion.

### 5.7 Invariant-Negation Search

When possible, enumerate the complete set of operations that require a property and subtract the set with proven enforcement.

Prefer:

```text
ALL security-sensitive operation E
MINUS
E instances protected by valid guard G
```

over:

```text
grep the vulnerable function name
```

Examples:

```text
all externally reachable state changes
minus
all paths dominated by authorization predicate P
```

```text
all deserializers for representation family R
minus
all implementations preserving serializer/deserializer invariant I
```

```text
all asset-moving operations
minus
all paths preserving accounting invariant A
```

Invariant-negation search is often the strongest form of variant analysis because it searches for missing protection rather than familiar vulnerable syntax.

---

## 6. Search-Space Expansion Matrix

Systematically expand the seed across relevant dimensions.

### Code Topology

- sibling functions;
- sibling contracts/classes/services;
- callers;
- callees;
- wrappers;
- copied helpers;
- duplicated implementations;
- generated implementations;
- legacy implementations;
- vendored code;
- shared libraries;
- alternate interface implementations.

### Entry Surfaces

- REST/RPC/GraphQL endpoints;
- public/external contract functions;
- admin paths;
- callbacks and hooks;
- fallback/receive paths;
- batch APIs;
- workers/jobs/queues;
- CLI or maintenance paths;
- internal APIs reachable through another component;
- asynchronous completion handlers.

### Authorization and Identity

- read/write variants;
- object-level authorization;
- role variants;
- ownership checks;
- delegated authority;
- meta-transactions;
- impersonation / service identities;
- cross-market / cross-vault / cross-chain domain paths;
- caller vs origin confusion;
- internal-vs-external trust assumptions.

### Data Representation

- alternate serializers/parsers;
- canonical/noncanonical forms;
- signed/unsigned values;
- integer widths;
- precision conversions;
- encoding/decoding boundaries;
- normalization order;
- case-folding;
- path/URL/hostname canonicalization;
- schema-version differences.

### State and Sequence

- initialization order;
- repeated calls;
- partial completion;
- cancellation;
- timeout;
- retry;
- reentrancy/callback;
- stale state;
- state before/after upgrade;
- rollback/recovery;
- concurrent mutation;
- cross-chain/message ordering.

### Configuration

- feature flags;
- optional modules/plugins;
- alternate backends;
- debug/release modes;
- chain / VM / proxy / deployment-architecture differences;
- compiler/build flags;
- network/chain configuration;
- proxy modes;
- authentication modes;
- deployment-specific policy.

### Version and Lineage

- maintained release branches;
- backports;
- forks;
- downstream copies;
- vendored dependency copies;
- cherry-picks;
- release candidates/nightlies;
- code generated by older/newer toolchains;
- versions created before and after the introducing commit.

### Deployment Topology

- alternate services;
- regional deployments;
- chain-specific deployments;
- proxy/implementation combinations;
- old implementations still reachable;
- migration bridges;
- shadow/legacy APIs;
- off-chain relayers/indexers/keepers;
- alternate dependency resolution states.

Only omit a dimension when there is concrete evidence that it is irrelevant to the root cause.

---

## 7. Tool Escalation Policy

Do not stop at the first convenient tool.

Use the cheapest technique that can answer the current question, then escalate when its model is too weak.

```text
Tier 0  repository / deployment inventory
Tier 1  text, symbol, call-site, history search
Tier 2  AST / structural matching
Tier 3  data-flow / taint analysis
Tier 4  control-flow / dominance analysis
Tier 5  call-graph / state-machine / semantic analysis
Tier 6  targeted dynamic tests / property tests / fuzzing
Tier 7  history + version + configuration differential analysis
Tier 8  cross-repository / downstream / deployment analysis
```

For temporary variant searches, tolerate controlled false-positive growth when narrowing would create significant false-negative risk.

A clean tool result means only:

```text
no matching variant observed under this tool's model,
query, state space, configuration, and coverage
```

It never means:

```text
no variant exists
```

---

## 8. Candidate Ledger and Triage

Every candidate MUST be triaged against the root cause.

Use:

```text
Candidate ID:
Location / component:
Seed relation:
Search query / procedure:
Abstraction level:

Security property:
Same root cause: proven / probable / uncertain / no
Attacker control: proven / conditional / absent / unknown
Reachability: proven / conditional / unreachable / unknown
Required state:
Required configuration:
Missing enforcement: proven / partial / present / unknown
Mitigation before sensitive operation:
Mitigation after sensitive operation:
Resulting primitive:
Affected versions / deployments:

Classification:
  confirmed_variant
  probable_variant
  lookalike_not_variant
  unreachable_variant
  mitigated_variant
  configuration_only_variant
  regression
  incomplete_fix
  needs_dynamic_validation

Evidence:
Residual uncertainty:
Provenance:
```

Pattern similarity is not root-cause equivalence.

Reachability is not exploitability.

A candidate can be structurally vulnerable but practically unreachable in the scoped deployment; preserve that distinction rather than deleting the result.

---

## 9. Reachability Decomposition

Do not use `reachable` as a single vague label.

Resolve as applicable:

```text
compiled?
linked / packaged?
deployed?
feature enabled?
entry surface reachable?
reachable from scoped attacker identity?
attacker controls or influences relevant input/state?
required state attainable?
security boundary crossed?
upstream mitigation present?
downstream mitigation present?
runtime/dependency behavior compatible?
real deployment configuration affected?
```

For every blocker, record:

```text
blocker
where it is enforced
whether enforcement is universal
what assumption it depends on
what alternate path could bypass it
```

Do not convert `unable to prove reachability` into `unreachable`.

---

## 10. Historical Material and Provenance

History is useful, but provenance must remain explicit.

When first-principles discovery is required by the active research mode, do not use target-specific patches/history to manufacture an allegedly independent discovery.

After an independent mechanism is established, or when the task explicitly begins from a historical seed, use:

- patches;
- CVEs/advisories;
- prior audit reports;
- bug trackers;
- security tests;
- version diffs;
- git blame/log;
- introducing commits;
- backports/cherry-picks;
- revert history;
- fork points;
- downstream patches;
- release notes.

Allowed provenance labels include:

```text
independent discovery
history-assisted variant
patch-derived lead
history-confirmed
advisory-derived
regression-derived
upstream-derived
downstream-derived
```

Attach provenance to each individual candidate/finding, not only the overall audit.

Example:

```text
VA-007
origin: patch-derived lead
confirmation: independent code reasoning + controlled reproduction
```

Patch archaeology is evidence and search guidance. It is not proof that the current target is exploitable.

---

## 11. Bug-Introduction and Propagation Analysis

Do not search only for where the bug was fixed.

Identify when practical:

```text
bug-introducing commit
copy/clone provenance
fork point
refactor ancestry
backport history
fix propagation
fix omissions
reverts
fix weakening
```

Then ask:

- which branches inherited the vulnerable logic;
- which copies were created before the fix;
- which copies were created after the fix but missed the remediation;
- which downstreams never received the fix;
- which refactors recreated the original invariant violation;
- which generated artifacts or SDKs preserve the vulnerable semantics.

This converts history from patch lookup into propagation analysis.

---

## 12. Affected-Version / Configuration Analysis

For every confirmed or probable variant, map:

```text
first known affected version
last known affected version
fixed version if any
maintained vulnerable branches
backported fixes
unfixed forks/downstreams
required feature flags
required runtime/dependency versions
required deployment topology
```

Do not report a version range from changelog inference alone when source or artifact evidence can verify it.

Distinguish:

```text
code affected
build affected
deployment affected
exploitably configured
```

These sets may differ.

---

## 13. Patch Completeness Analysis

A remediation review MUST determine what layer was fixed.

Classify the remediation:

```text
instance-only fix
caller-level fix
shared helper fix
central enforcement fix
invariant-owner fix
architectural fix
```

Build a matrix:

```text
                         Before patch   After patch
seed path                     ?             ?
syntactic sibling             ?             ?
semantic sibling              ?             ?
alternate entry               ?             ?
alternate state               ?             ?
alternate configuration       ?             ?
alternate dependency path     ?             ?
legacy implementation         ?             ?
downstream copy               ?             ?
```

Then determine whether the patch changed:

```text
[ ] the vulnerable instance only
[ ] every relevant caller
[ ] the shared security primitive
[ ] the owner of the invariant
[ ] every equivalent implementation
[ ] tests/oracles that encode the actual security property
```

A patch that blocks the published PoC but leaves the causal primitive intact is incomplete.

---

## 14. Adversarial Patch-Bypass Derivation

For every newly introduced check, guard, sanitizer, state transition, or validation rule, attack its assumptions.

Ask:

1. What exact value/state does the patch reject?
2. What equivalent representation could evade it?
3. What alternate entry path avoids the new guard?
4. Can validation and use observe different state?
5. Does normalization happen before or after validation?
6. Can another caller reach the sensitive operation without the guard?
7. Is there an equivalent sensitive operation/sink?
8. Can configuration disable or bypass enforcement?
9. Do boundary values, truncation, sign, width, precision, or overflow alter the result?
10. Can callbacks, retries, races, rollback, or upgrade state invalidate the check?
11. Does a dependency/runtime interpret the validated value differently?
12. Does the patch preserve the security invariant or merely reject the known test case?

Derive explicit bypass hypotheses and test them with the cheapest strong discriminator available.

---

## 15. Regression Analysis

Treat regressions as a first-class variant family.

Search for:

- later removal of a guard;
- weakened predicates;
- new call sites bypassing the fixed API;
- refactors that bypass central enforcement;
- reintroduced vulnerable helpers;
- reverted patches;
- cherry-pick/backport omissions;
- tests removed or weakened;
- newly supported configuration combinations violating the invariant;
- dependency upgrades that restore vulnerable semantics;
- generated code that reintroduces the old behavior.

A regression may reproduce the old syntax, or it may recreate only the old security property violation.

---

## 16. Dynamic Validation and Oracles

When static evidence cannot resolve equivalence or reachability, construct a targeted discriminator.

Prefer:

- minimal reproductions;
- unit/integration tests against the invariant;
- differential tests between patched/unpatched or sibling implementations;
- property-based tests;
- stateful fuzzing;
- metamorphic tests;
- controlled runtime instrumentation;
- forked/sandbox deployment tests.

The oracle should encode the security property, not the known vulnerable output alone.

Bad oracle:

```text
this exact PoC must revert
```

Better oracle:

```text
no attacker-controlled path may cause operation E unless predicate P was valid for the same subject/object/state used by E
```

---

## 17. Coverage Accounting and Negative Evidence

`No variants found` is not an acceptable conclusion by itself.

Record what was actually searched.

At minimum, update the relevant `COVERAGE_LEDGER.md`, `HISTORY_VARIANTS.md`, and `NEGATIVE_EVIDENCE.md` artifacts when the surrounding research system uses them.

Coverage should state:

```text
implementation families enumerated
entry surfaces enumerated
state/lifecycle families checked
configuration families checked
version/branch families checked
dependency/deployment variants checked
query families used
abstraction levels exercised
candidate count by classification
unexamined surfaces
known tool/model blind spots
```

Example bounded conclusion:

```text
No confirmed sibling variants were found across:
- 47/47 externally reachable functions/instructions;
- 12/12 implementations or facets enforcing property X;
- 8 ABI/message/proof encoding and decoding paths;
- all 4 supported chain/bridge adapters;
- maintained protocol releases v2.x, v3.x, and v4.x;
- 3 production-relevant governance/configuration states;

using lexical, AST, call-site, interprocedural-flow, invariant-negation,
and history-based searches.

Not covered:
- private/unverifiable downstream deployments;
- unsupported chain forks;
- deprecated chain adapter, legacy implementation, or old proxy deployment.
```

Negative evidence is useful only when its search boundary is explicit.

---

## 18. Search Closure Gate

Variant analysis MUST NOT be closed merely because a query returned zero new findings.

Closure requires, as applicable:

1. the seed was successfully rediscovered by the calibrated search procedure;
2. the root cause was modeled at the security-invariant level;
3. relevant abstraction levels were exercised;
4. relevant implementation families were enumerated;
5. relevant entry surfaces were considered;
6. state/lifecycle equivalents were considered;
7. supported configuration/version/deployment families were mapped;
8. candidate matches were triaged against root-cause equivalence;
9. patch-bypass hypotheses were tested when remediation exists;
10. history/regression propagation was examined when history is in scope;
11. negative evidence and blockers were recorded;
12. unexamined surfaces and tool blind spots were explicitly listed;
13. residual uncertainty was reported.

If one of these cannot be completed, state the missing coverage rather than silently treating the search as exhaustive.

Preferred conclusion vocabulary:

```text
confirmed variant found
probable variant requires validation
no variant found within defined coverage
search blocked by missing state/artifact
search locally exhausted for defined family
residual uncertainty remains in <surface>
```

Avoid:

```text
secure
no other bugs
fully patched
all variants eliminated
```

unless the claim is literally supported by the defined evidence boundary.

---

## 19. Variant Analysis Output

A complete variant-analysis result should contain:

```text
Seed
Root-cause model
Security invariant
Attacker model
Seed calibration result
Abstraction ladder exercised
Search-space matrix
Queries / analyses performed
Candidate ledger
Confirmed / probable variants
Lookalikes rejected and why
Reachability blockers
Affected versions/configurations
Patch completeness result
Patch-bypass hypotheses and outcomes
Regression/history propagation result
Coverage accounting
Negative evidence
Unexamined surfaces
Residual uncertainty
Per-finding provenance
```

The objective is not a large list of matches.

The objective is a coverage-bounded statement about where the same security failure does and does not survive.

---

## 20. Failure Modes

### Syntax Lock-In

Only identical code is searched.

### Seed-Blind Query

The search rule cannot rediscover the known vulnerable instance.

### Abstraction Jump

The query is generalized too aggressively, producing noise without knowing which semantic dimension was lost.

### Source-to-Sink Overfitting

State, lifecycle, authority, serialization, or economic flaws are forced into an unsuitable taint model.

### Reachability Flattening

`compiled`, `deployed`, `feature enabled`, and `attacker reachable` are treated as the same property.

### Patch-as-Proof

Presence of a security patch is treated as evidence that the root cause is closed.

### PoC Fixation

The remediation is tested only against the disclosed exploit input.

### History Laundering

Patch-derived discoveries are presented as independent findings.

### False-Positive Panic

Queries are narrowed prematurely until useful semantic variants disappear.

### Quiet-Tool Closure

A clean static-analysis result is treated as search exhaustion.

### Coverage Theater

Large scan counts are reported without enumerating the security-relevant implementation/configuration families actually covered.

### Variant Deletion

Unreachable or mitigated siblings are discarded instead of preserved as evidence about root-cause propagation and deployment dependence.

---

## 21. Compact Execution Loop

```text
ESTABLISH SEED
      ↓
MODEL ROOT CAUSE + INVARIANT
      ↓
CALIBRATE Q0 — MUST REDISCOVER SEED
      ↓
GENERALIZE ONE AXIS AT A TIME
      ↓
ENUMERATE IMPLEMENTATION / ENTRY / STATE / CONFIG FAMILIES
      ↓
SEARCH LEXICAL → STRUCTURAL → SEMANTIC → INVARIANT
      ↓
TRIAGE ROOT-CAUSE EQUIVALENCE
      ↓
PROVE / BOUND ATTACKER REACHABILITY
      ↓
MAP VERSION + DEPLOYMENT + LINEAGE
      ↓
ATTACK PATCH ASSUMPTIONS
      ↓
SEARCH REGRESSIONS / INCOMPLETE FIXES
      ↓
VALIDATE AMBIGUOUS CANDIDATES
      ↓
RECORD NEGATIVE EVIDENCE + COVERAGE
      ↓
CLOSE ONLY WITH EXPLICIT RESIDUAL UNCERTAINTY
```

---

## 22. Core Principle

A variant is not "code that looks like the original bug."

A variant is another reachable manifestation of the same security-relevant causal failure.

The strongest variant analysis therefore searches not only for what the vulnerable code _looks like_, but for every place where the violated invariant is expected to hold and may not actually be enforced.

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
