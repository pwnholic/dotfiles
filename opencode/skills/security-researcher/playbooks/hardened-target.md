# Hardened Smart-Contract Target Research Playbook

## Smart-Contract Scope Lock

This playbook belongs to a **smart-contract / DeFi security research stack**. Apply it to on-chain programs, protocols, token systems, vaults, AMMs, lending, staking/restaking, governance, account abstraction, bridges, rollups/L2s, cross-chain systems, and infrastructure only when that infrastructure is causally necessary to an on-chain security property.

Do **not** expand the default search into generic web/backend/database/desktop/cloud security. An off-chain component belongs here only when compromising or mis-modeling it can change an on-chain authorization decision, state transition, message provenance, price, ordering/finality assumption, upgrade/deployment state, or realizable economic impact.

When a concrete exploit hypothesis exists, hand validation to `exploit-validation.md`.

## Purpose

Load this playbook only for targets that are mature, heavily reviewed, repeatedly audited, formally verified, extensively fuzzed, widely deployed, or otherwise expected to have survived ordinary security review.

This is not a generic vulnerability checklist.

The job is to research the **residual attack surface**: behaviors, states, assumptions, variants, integrations, deployment conditions, and failure modes that previous review processes were structurally unlikely to cover.

A hardened target is not assumed safe, and it is not assumed to contain only sophisticated bugs. Prior review changes the research strategy; it does not justify skipping simple logic.

---

## Core Doctrine

Treat every security claim as a hypothesis backed by evidence, not as inherited truth.

Do not ask only:

> Where is the bug?

Ask:

> What has already been searched, what assumptions made that search incomplete, and what parts of the reachable system remain weakly constrained?

Optimize for **new information per unit of research**, not for number of files reviewed, alerts generated, fuzz iterations executed, or hypotheses written.

For hardened targets, prefer evidence-driven research seeded by target-specific facts over open-ended vulnerability brainstorming.

Known bugs, old patches, audit findings, strange code, production incidents, configuration changes, dependency changes, and failed exploit attempts are **research seeds**.

Never treat them merely as historical documentation.

---

# 1. Activation Gate

Before using hardened-target methodology, establish whether the target actually deserves it.

Collect evidence of:

- previous professional audits;
- public audit contests;
- bug-bounty history;
- formal verification;
- invariant or stateful fuzzing campaigns;
- static or symbolic analysis;
- long production exposure;
- significant TVL / value-at-risk / adversarial attention;
- previous incidents or near misses;
- fork lineage from battle-tested software;
- repeated internal security review.

If this evidence is absent, use the normal audit workflow first.

Even when the gate is satisfied, retain a baseline pass for simple bugs. Hardened history is evidence about **prior search pressure**, not evidence that local mistakes no longer exist.

---

# 2. Required Evidence Pack

Do not begin deep hardened-target research from source code alone.

Build a target evidence pack containing as many of the following as are obtainable:

- exact repository and commit under review;
- deployed bytecode and verified source mapping;
- deployment addresses on every supported chain;
- proxy, beacon, implementation, and admin relationships;
- compiler version, optimizer settings, build flags, and build artifacts;
- deployment scripts and migration scripts;
- current production configuration;
- governance proposals and executed payloads;
- privileged roles and current role holders;
- dependency lockfiles and vendored code;
- external protocol and oracle dependencies;
- keeper, relayer, signer, sequencer, and off-chain service assumptions;
- architecture documentation and specifications;
- economic design documentation;
- all previous audit reports;
- contest findings;
- bug-bounty disclosures;
- incident postmortems;
- previously disputed or rejected findings;
- formal specifications and prover configuration;
- invariant/property tests;
- fuzz harnesses and corpora;
- unit and integration tests;
- historical security fixes;
- relevant upstream and downstream forks;
- mainnet or production state required for realistic replay.

Record missing evidence explicitly. Missing evidence is itself residual uncertainty.

---

# 3. Production-Parity Check

Before reasoning about security, prove that the object being researched corresponds to the object actually exposed to attackers.

Verify:

- audited commit versus deployed runtime bytecode;
- source versus compiler configuration;
- implementation addresses behind proxies;
- initialization state;
- storage layout and migrated storage values;
- linked libraries;
- immutable values;
- constructor arguments;
- chain-specific addresses;
- feature flags;
- role assignments;
- oracle configuration;
- risk parameters;
- caps and limits;
- allowlists and denylists;
- emergency modes;
- governance-controlled values;
- post-audit commits;
- post-deployment upgrades;
- deployment scripts versus actual on-chain result.

If parity cannot be established, do not silently audit an abstract version of the target. Mark the mismatch as a first-class research problem.

---

# 4. Historical and Patch Archaeology

For hardened systems, history is attack surface.

## 4.1 Mine prior findings

For every previous security finding, incident, or meaningful bug fix, extract:

- root cause;
- violated security property;
- vulnerable state or precondition;
- attacker-controlled input;
- sensitive sink or effect;
- exploit primitive;
- patch mechanism;
- assumptions made by the patch;
- neighboring code implementing the same concept;
- other components sharing the same helper, abstraction, pattern, or invariant.

Do not search only for textual copies of the old bug.

Search for **semantic variants**.

## 4.2 Patch-diff analysis

Treat security patches as vulnerability descriptions written backwards.

For each important patch:

1. reconstruct the behavior before the patch;
2. identify the exact root cause rather than the PoC-specific symptom;
3. determine what assumption the patch introduces;
4. search for alternate paths that bypass that assumption;
5. search for sibling implementations of the same operation;
6. search for regressions or later refactors that weakened the fix;
7. test whether the old exploit primitive can be recovered through a different state, caller, configuration, or dependency.

A patch that stops one transaction sequence is not evidence that the bug class is dead.

## 4.3 Lineage analysis

If code was forked, copied, ported, translated, or heavily inspired by another system:

- collect upstream security fixes after the fork point;
- collect downstream fixes that did not flow back;
- compare semantic divergence, not only line diffs;
- identify local modifications to previously proven code;
- find assumptions inherited from a different environment;
- search known vulnerabilities in sibling forks;
- examine patches that were intentionally not adopted.

Produce `HISTORY_VARIANTS.md`.

---

# 5. Build the Security Graph

Do not reason about a hardened target as a flat list of files.

Build a graph representing at least:

- external entrypoints;
- internal call edges;
- callbacks;
- fallback/receive paths;
- delegatecalls;
- arbitrary-call facilities;
- asset flows;
- storage read/write dependencies;
- privilege transitions;
- trust boundaries;
- oracle inputs;
- governance control paths;
- upgrade paths;
- cross-chain message paths;
- external protocol calls;
- off-chain actors that can affect on-chain state.

For each sensitive operation, ask:

- Which untrusted entrypoints can reach it?
- Through how many distinct paths?
- Which state must already exist?
- Which components can modify that state?
- Which external call can interrupt the path?
- Which authorization layer is assumed to have already run?
- What is the blast radius if the operation is wrong?

Prioritize graph bottlenecks where several security properties converge.

Examples include:

- common accounting helpers;
- conversion/rate functions;
- shared authorization routers;
- settlement functions;
- hooks and callbacks;
- generic execution functions;
- bridge verification functions;
- storage libraries;
- upgrade dispatchers;
- state synchronization routines.

Produce `ATTACK_GRAPH.md` and `TRUST_BOUNDARIES.md`.

---

# 6. Security Coverage Ledger

Line coverage is not security coverage.

Maintain a semantic coverage ledger.

Track coverage across:

- externally reachable entrypoints;
- asset-moving paths;
- privileged operations;
- state variables and every writer to them;
- trust boundaries;
- callbacks and reentrant edges;
- temporal transitions;
- lifecycle states;
- oracle paths;
- external dependencies;
- configuration variants;
- deployment variants;
- upgrade paths;
- historical bug classes;
- critical invariants;
- economic actions;
- liveness-sensitive loops/data structures;
- compiler/runtime-specific behavior;
- off-chain dependencies where they are security-critical.

For every item record:

- `unsearched`;
- `partially searched`;
- `searched`;
- evidence produced;
- tools/techniques used;
- hypotheses tested;
- unresolved assumptions;
- reasons the area is believed closed.

Do not convert this into a fake percentage of “security coverage”.

The ledger exists to expose blind spots, not manufacture confidence.

Produce `COVERAGE_LEDGER.md`.

---

# 7. Independent Specification Reconstruction

Do not derive all expected behavior from the implementation. That merely teaches the tests to agree with the code.

Reconstruct security properties independently from:

- protocol documentation;
- economic intent;
- user guarantees;
- interface standards;
- governance constraints;
- asset conservation requirements;
- external integration contracts;
- historical behavior when compatibility is required.

## 7.1 Invariant families

Derive target-specific invariants for applicable families:

### Conservation

- assets cannot be created by accounting drift;
- withdrawals cannot exceed economically owned claims;
- internal credits reconcile with external balances;
- cross-chain minted/burned supply reconciles with locked/released supply.

### Solvency

- liabilities remain bounded by realizable assets under defined assumptions;
- debt cannot disappear without a corresponding economic cost;
- bad debt cannot be shifted invisibly between markets or users.

### Authorization

- every privileged state transition has an enforcing boundary;
- downstream components never rely on authorization that no upstream component guarantees;
- callbacks cannot manufacture an authorized execution context.

### State-machine safety

- forbidden state transitions are unreachable;
- terminal states cannot be revived unexpectedly;
- initialization happens exactly once where intended;
- pause/emergency states preserve required safety properties.

### Temporal

- expiry, epochs, cooldowns, vesting, settlement, rollover, and liquidation preserve correctness immediately before, at, and after boundaries;
- same-block ordering does not invalidate assumptions intended to require elapsed time.

### Arithmetic and dimensions

- units remain consistent across conversions;
- scaling factors and decimals compose correctly;
- rounding direction cannot create repeatable attacker profit;
- monotonic relationships remain monotonic;
- boundary values do not change semantic domains unexpectedly.

### Liveness

- attacker-controlled state cannot make critical maintenance permanently unexecutable;
- loops, trees, queues, withdrawal paths, settlement, and liquidation remain feasible under adversarially shaped state.

### Upgrade compatibility

- old valid state remains valid under new logic;
- new logic does not reinterpret existing storage unexpectedly;
- security guarantees do not weaken through migration.

## 7.2 Anti-invariants

Also write attacker objectives explicitly.

Examples:

- receive more assets than net economic input;
- create debt without adequate collateral;
- make a privileged effect occur from an unprivileged origin;
- make two components disagree about the same balance/state;
- force permanent or economically meaningful denial of service;
- make an oracle/accounting quantity diverge from realizable market value;
- preserve a favorable stale state while updating an unfavorable dependent state.

An anti-invariant often gives fuzzers and researchers a better search objective than a named vulnerability class.

Produce `INVARIANTS.md`.

---

# 8. Audit the Specification and the Test Oracle

Formal verification, fuzzing, and large test suites are evidence. They are not ground truth.

For every security-critical property suite, review:

- whether the property encodes requirements or current implementation behavior;
- omitted public/external methods;
- filtered methods;
- preconditions that exclude attacker-reachable states;
- mocked dependencies;
- summarized external calls;
- assumed-honest contracts;
- bounded loops or state depth;
- artificial balance assumptions;
- environment assumptions;
- revert behavior;
- constructor/initial-state assumptions;
- proxy/delegatecall modeling;
- chain/runtime semantics;
- ignored callbacks;
- ignored configuration variants.

Attempt to make the verification/test system accept an intentionally broken implementation.

If a realistic security mutation survives, the test oracle has demonstrated a blind spot.

Treat harness bugs, weak specifications, and invalid assumptions as findings about the assurance system even when production code is not immediately exploitable.

Produce `ASSURANCE_GAPS.md`.

---

# 9. Mutation-Guided Research

Use mutation testing to ask a hardened-target question that line coverage cannot answer:

> Which security-relevant behavior can change without any existing defense noticing?

Prioritize mutations in:

- authorization conditions;
- comparison boundaries;
- accounting operators;
- rounding direction;
- scale factors;
- fee calculations;
- debt/share conversions;
- oracle freshness and validity checks;
- lifecycle transitions;
- replay/nullifier logic;
- signature/domain checks;
- external-call success handling;
- pause/emergency checks;
- upgrade authorization;
- storage-slot selection;
- loop termination;
- cross-contract consistency checks.

Triage surviving mutants by:

1. attacker reachability;
2. blast radius;
3. economic sensitivity;
4. privilege sensitivity;
5. whether the changed behavior violates an independently derived property.

Do not automatically add a test that encodes the original behavior. First determine whether the original behavior was actually correct.

---

# 10. Stateful and Sequence Research

Many hardened-target bugs are not input bugs. They are **history bugs**.

Model the target as a state machine.

Enumerate:

- states;
- transitions;
- transition guards;
- state writers;
- cross-contract state dependencies;
- terminal states;
- temporary inconsistent states;
- transitions that yield control externally;
- transitions that depend on time, block number, price, liquidity, governance, or external messages.

Search transaction sequences involving:

- reorderings;
- repetition;
- partial completion;
- failure followed by retry;
- callback insertion;
- cross-contract reentrancy;
- same-block composition;
- multi-block preparation;
- stale data followed by fresh data;
- zero/empty state initialization;
- first depositor / last withdrawer;
- transitions around expiry or epoch boundaries;
- pause/unpause;
- upgrade before/after operations;
- role transfer;
- liquidation and settlement races;
- multiple markets sharing global state.

Use state read/write dependencies to generate meaningful sequences instead of relying only on random call ordering.

For deep targets, explicitly increase sequence depth and preserve interesting intermediate states in the corpus.

Produce `STATE_MACHINE.md`.

---

# 11. Boundary and Extreme-State Research

Normal states are usually the states previous tests cover best.

Actively construct abnormal but reachable states:

- zero liquidity;
- one-wei liquidity;
- near-zero liquidity;
- extreme imbalance;
- extreme price;
- depeg to near zero;
- maximum practical leverage;
- maximum/minimum tick or index;
- near integer boundaries;
- empty vault/market;
- first user;
- last user;
- single remaining share;
- accumulated dust;
- maximum fee growth;
- stale oracle at acceptance boundary;
- conflicting oracle sources;
- oversized but valid data structures;
- long-lived positions;
- long inactivity followed by activity;
- old state carried through several upgrades;
- adversarially fragmented state.

Test not only one extreme operation, but whether small rounding or accounting errors can be **amplified through repetition, inflation, leverage, or composition**.

---

# 12. Economic Exploitability Research

For systems managing value, a crash oracle is insufficient.

Model attacker objectives economically.

For each candidate sequence measure:

- attacker starting capital;
- flash liquidity available;
- required collateral;
- fees;
- slippage;
- gas;
- time exposure;
- inventory risk;
- resulting protocol loss;
- resulting attacker profit;
- bad debt;
- victim value transfer;
- repeatability;
- scalability;
- recoverability.

Search for combinations involving:

- flash liquidity;
- oracle movement;
- temporary liquidity distortion;
- rounding amplification;
- donation/inflation;
- self-trading;
- self-liquidation;
- cross-market collateral effects;
- fee/reward extraction;
- repeated micro-operations;
- empty-market initialization;
- share-price manipulation;
- stale accounting;
- delayed settlement;
- sandwich/order manipulation;
- governance borrowing/voting power;
- cross-protocol leverage;
- liquidation cascades;
- insolvency transfer;
- griefing where attacker cost is far below defender/victim cost.

A behavior that is technically incorrect but economically unreachable is different from a production exploit. Prove which one you have.

Produce `ECONOMIC_ATTACKS.md`.

---

# 13. Adversarial Dependency Modeling

Never model an external dependency as honest merely because it follows an interface.

For each external boundary determine what the target actually verifies.

Test applicable adversarial behaviors such as:

- malicious callbacks;
- reentrancy through unexpected call layers;
- false or malformed return data;
- revert/non-revert differences;
- tokens with fees on transfer;
- rebasing tokens;
- tokens with callbacks/hooks;
- non-standard ERC return values;
- unusual decimals;
- tokens that blacklist/freeze;
- mutable token behavior;
- malicious oracle accounts/contracts;
- stale oracle data;
- extreme but valid oracle values;
- oracle disagreement;
- missing liquidity;
- AMM spot manipulation;
- bridge replay;
- message reordering;
- delayed finality;
- chain reorg assumptions;
- forged/truncated proof inputs;
- domain-separation mistakes;
- address aliasing;
- unexpected caller code;
- EOA assumptions invalidated by account-delegation/account-abstraction features;
- dependency upgrades;
- changed precompile/runtime behavior.

Interfaces describe shape, not trustworthiness.

Produce `DEPENDENCY_ASSUMPTIONS.md`.

---

# 14. Upgrade and Migration Research

Treat every upgrade as a new security boundary.

Do not review only the textual diff.

Analyze:

- semantic behavior before versus after;
- changed reachable paths;
- changed call graph;
- changed privilege graph;
- changed state writers;
- storage layout;
- initialization/reinitialization;
- old state under new code;
- changed external dependencies;
- changed economic parameters;
- changed assumptions in tests/formal specs;
- governance payload encoding;
- upgrade atomicity;
- rollback behavior;
- pause interactions;
- migration partial failure;
- obsolete implementation reachability.

Use differential testing/fuzzing where possible.

Feed identical actions and comparable states into old and new implementations and investigate every unexpected semantic difference.

Expected differences must be documented explicitly; otherwise they remain research candidates.

Produce `UPGRADE_DIFF.md`.

---

# 15. Configuration-Space Research

A secure implementation can be deployed into an insecure system.

Enumerate security-relevant configuration dimensions, for example:

- chain;
- market;
- collateral type;
- oracle type;
- decimals;
- cap values;
- fee values;
- liquidation parameters;
- epoch duration;
- hook configuration;
- feature flags;
- role topology;
- proxy type;
- bridge path;
- sequencer assumptions;
- external integration version.

Do not test only the canonical production configuration if other reachable or governance-creatable configurations can hold value.

Search for **configuration interactions**, not only invalid single parameters.

Important questions:

- Which individually valid settings become unsafe together?
- Which configuration is safe only because of current liquidity or market depth?
- Which values can governance or an operator change without code review?
- Can a new market instantiate an unsafe state that the original deployment never had?

Produce `CONFIG_MATRIX.md`.

---

# 16. Runtime and Semantic Drift

Hardened software can become vulnerable when its execution environment changes.

Track security assumptions tied to:

- compiler version;
- optimizer behavior;
- Yul/assembly;
- VM/client implementation;
- hard forks;
- new opcodes;
- transient storage;
- account abstraction/delegation semantics;
- block gas limits;
- precompile behavior;
- chain-specific opcode differences;
- L2 execution differences;
- sequencer behavior;
- RPC behavior relied upon off-chain.

Ask:

> Was this code proven secure under the semantics that exist today, or under semantics that existed when the assurance was produced?

Where multiple runtimes or clients should behave equivalently, consider differential execution as an oracle.

---

# 17. Cross-Component Consistency Research

For every quantity represented in more than one place, search for divergence.

Examples:

- shares versus assets;
- debt versus debt shares;
- internal accounting versus token balance;
- cached price versus live price;
- local supply versus bridge/global supply;
- position state versus global aggregates;
- reward index versus user checkpoint;
- governance state versus execution state;
- implementation state versus proxy state;
- L1 state versus L2 mirrored state;
- off-chain signed state versus on-chain accepted state.

For each pair define:

- synchronization direction;
- update order;
- failure behavior;
- rounding behavior;
- stale-state tolerance;
- who can update either side;
- whether external control can be yielded between updates.

Then attempt to create a reachable state where both components individually appear valid but disagree in a way that benefits the attacker.

---

# 18. Dimensional and Semantic Arithmetic Analysis

Do not review arithmetic only for overflow/underflow.

Annotate economically meaningful values with semantic units, such as:

- token amount;
- shares;
- debt shares;
- price;
- price-per-share;
- basis points;
- fixed-point scale;
- time;
- rate-per-time;
- liquidity;
- quote/base orientation.

Trace units across:

- assignments;
- arithmetic;
- function boundaries;
- return values;
- external calls;
- storage;
- conversions.

Flag cases where an expression is type-correct but dimensionally suspicious.

Separately test:

- scale mismatch;
- inverse price confusion;
- double scaling;
- missing scaling;
- precision truncation;
- rounding direction;
- signed/unsigned semantic mismatch;
- cached scale assumptions;
- decimals changed by configuration or token choice.

---

# 19. Liveness and Adversarial State Growth

A hardened target can lose funds because an attacker makes necessary operations impossible rather than directly stealing them.

Identify operations required for safety:

- liquidation;
- withdrawal;
- settlement;
- checkpointing;
- oracle update;
- rollover;
- reward distribution;
- governance execution;
- bridge processing;
- emergency pause/recovery.

For each operation ask whether attackers can inflate or shape:

- arrays;
- queues;
- trees;
- mappings indirectly iterated over;
- position count;
- market count;
- dust entries;
- pending messages;
- callback depth;
- gas consumption;
- proof size;
- storage fragmentation.

Model attacker cost versus resulting liveness damage.

---

# 20. Off-Chain and Operational Boundary

If off-chain infrastructure can violate an on-chain security assumption, it belongs in the security model even when it is outside the code-review scope.

Map only off-chain actors whose behavior can change an on-chain result:

- multisigs / signer sets controlling upgrade, governance, mint, pause, or bridge authority;
- keeper/executor infrastructure when liveness or ordering is protocol-critical;
- oracle publishers / reporters;
- bridge relayers / attesters / validator sets;
- bundlers and paymasters when account-abstraction semantics are causal;
- governance proposal construction/execution when calldata or target binding is security-critical;
- RPC/node providers only when the protocol or exploit depends on their chain-state semantics;
- sequencers and forced-inclusion/finality paths;
- build/deployment pipeline facts only when source-to-bytecode or upgrade provenance is in question (route to `supply-chain.md`).

Distinguish clearly between:

- code vulnerability;
- deployment/configuration vulnerability;
- operational vulnerability;
- trust assumption;
- explicit out-of-scope dependency.

Do not let “out of scope” silently become “safe”.

---

# 21. Hypothesis Portfolio

Do not launch researchers with generic prompts such as “look for oracle bugs” or “find reentrancy”.

Every hypothesis must be rooted in target evidence.

Use this structure:

```text
Hypothesis ID:
Seed evidence:
Security claim being challenged:
Relevant graph path:
Required attacker capabilities:
Required state/preparation:
Expected violated invariant:
Candidate exploit sequence:
Economic/privilege/liveness impact:
Primary blocker:
How the blocker will be attacked:
Experiment / PoC plan:
Evidence produced:
Status:
Confidence:
Reopen condition:
Related variants:
```

Good seeds include:

- previous findings;
- security patches;
- surviving mutants;
- high-blast-radius graph nodes;
- weakly specified invariants;
- difficult-to-reach state transitions;
- deployment mismatches;
- integration assumptions;
- recent code changes;
- unusual production configuration;
- unexplained historical behavior;
- tool coverage gaps.

---

# 22. Anti-Convergence

Maintain materially different research lines.

Researchers may share factual artifacts such as call graphs, state maps, and deployment facts, but avoid forcing everyone to inherit the same vulnerability theory too early.

Useful independent lanes include:

- historical/variant researcher;
- graph/reachability researcher;
- invariant/specification researcher;
- state-machine researcher;
- economic researcher;
- integration/runtime researcher;
- upgrade/deployment researcher;
- adversarial reviewer trying to falsify other researchers' conclusions.

Do not count five agents repeating the same pattern search as five independent security passes.

Duplicate effort is valuable only when it provides independent confirmation or a different analysis technique.

---

# 23. Negative Evidence and Blocker Attacks

A failed exploit attempt is research output.

For every failed hypothesis record:

- what exact path was attempted;
- what assumption held;
- what state was reached;
- what prevented exploitation;
- whether the blocker is enforced by code, economics, configuration, timing, or an external assumption;
- whether the blocker is universal or conditional;
- evidence that the blocker actually held;
- alternate routes around the blocker;
- what future code/config/runtime change would reopen the path.

Classify blockers:

### Hard blocker

Enforced across all reachable states by a well-supported property.

### Conditional blocker

Holds only for particular configuration, liquidity, timing, role assignment, or external behavior.

### Assumed blocker

Depends on documentation, honest external behavior, operational practice, or an unverified claim.

Do not close a hypothesis because one exploit sequence failed.

Attack the blocker itself using:

- alternate entrypoints;
- alternate ordering;
- alternate caller identity;
- callbacks;
- reentrancy;
- different configuration;
- boundary values;
- stale state;
- old state after upgrade;
- adversarial external contracts;
- economic amplification;
- chain/runtime differences.

Produce `NEGATIVE_EVIDENCE.md`.

---

# 24. Tool-Assisted Falsification Stack

Tools are used to falsify claims, not to decorate the audit report.

Choose techniques based on the hypothesis:

## Static / graph analysis

Use for:

- reachability;
- state writers;
- privilege paths;
- external-call surfaces;
- variant patterns;
- blast radius;
- taint-like flows;
- architectural change.

## Stateful property fuzzing

Use for:

- transaction sequences;
- invariant violation;
- deep state;
- repeated-operation amplification;
- callback/reentrancy state exploration.

## Differential fuzzing/testing

Use for:

- upgrades;
- refactors;
- reference implementations;
- chain/runtime/client equivalence;
- optimized versus unoptimized implementations.

## Mutation testing

Use for:

- measuring whether tests/specifications actually constrain security-relevant behavior;
- finding weakly defended code regions;
- generating targeted fuzzing goals.

## Symbolic execution / formal verification

Use for:

- high-value properties where exhaustive reasoning is tractable;
- bounded but difficult path conditions;
- proving or falsifying narrow security claims.

Always audit the model and assumptions used by the prover.

## Fork-based simulation

Use for:

- production state;
- real external integrations;
- actual liquidity;
- deployed roles/configuration;
- economically realistic exploit validation.

## Custom instrumentation

Track security-relevant deltas such as:

- attacker net worth;
- protocol solvency;
- share/asset drift;
- debt drift;
- aggregate accounting divergence;
- stale-versus-live price divergence;
- privilege changes;
- unreachable-to-reachable state transitions.

Tool disagreement is research evidence. Investigate it.

---

# 25. Exploitability Gate

Do not promote a candidate to a vulnerability finding until the security claim survives adversarial validation.

A serious finding should establish, where applicable:

1. **Reachability** — attacker can reach the vulnerable behavior in the relevant deployment.
2. **Control** — attacker controls the required input/state/order/caller condition.
3. **Security property violation** — identify the exact invariant or trust assumption broken.
4. **Impact path** — show how the violation becomes loss, privilege gain, insolvency, permanent DoS, censorship, or another concrete impact.
5. **Reproduction** — provide a deterministic PoC, fork test, trace, or equivalent evidence.
6. **Economic feasibility** — account for capital, liquidity, fees, slippage, gas, timing, and repeatability when relevant.
7. **Production relevance** — distinguish current exploitability from hypothetical future configuration.
8. **Root cause** — describe why the system permitted the behavior.
9. **Variant scope** — identify sibling paths affected by the same root cause.
10. **Counterargument** — state the strongest reason the finding might be invalid and test it.

Interesting behavior is not automatically a vulnerability.

---

# 26. Research Exhaustion

“No bugs found” is not an exit criterion.

A hardened-target pass may stop only when the remaining uncertainty is explicitly documented.

Before stopping, require evidence that:

- production parity was checked;
- every high-value entrypoint appears in the coverage ledger;
- every asset-moving path has at least one security property attached to it;
- every privileged effect has its authorization chain traced;
- every critical state variable has its writers mapped;
- every external dependency has explicit adversarial assumptions;
- every major lifecycle transition has boundary-state analysis;
- historical critical/high findings have undergone semantic variant search;
- important security patches have undergone patch-bypass analysis;
- upgrade/configuration surfaces have been explored;
- high-blast-radius components received more than one independent analysis mode;
- critical invariants were challenged dynamically or formally where practical;
- assurance tooling itself was tested for blind spots;
- failed hypotheses have recorded blockers and reopen conditions;
- unresolved blind spots are listed rather than silently ignored.

The final statement is not “the target is safe”.

The final statement should describe **what security claims were challenged, what evidence survived, and what residual uncertainty remains**.

Produce `RESIDUAL_RISK.md`.

---

# 27. Priority Model

Do not rank research areas by aesthetic complexity.

Increase priority when several of these factors overlap:

- attacker reachability;
- asset/privilege blast radius;
- historical bug density;
- recent change;
- weak prior coverage;
- assumption density;
- cross-component fan-in/fan-out;
- external control;
- deep state dependence;
- temporal dependence;
- configuration variability;
- arithmetic/economic sensitivity;
- prior patch history;
- surviving security mutations;
- discrepancy between documentation, tests, and production behavior.

A short simple function with enormous blast radius can outrank a complicated subsystem.

---

# 28. Mandatory Research Artifacts

A hardened-target engagement should leave structured evidence, not only findings.

At minimum maintain:

```text
TARGET_MAP.md
PRODUCTION_PARITY.md
HISTORY_VARIANTS.md
ATTACK_GRAPH.md
TRUST_BOUNDARIES.md
COVERAGE_LEDGER.md
INVARIANTS.md
ASSURANCE_GAPS.md
STATE_MACHINE.md
DEPENDENCY_ASSUMPTIONS.md
CONFIG_MATRIX.md
UPGRADE_DIFF.md
ECONOMIC_ATTACKS.md
HYPOTHESES.md
NEGATIVE_EVIDENCE.md
FINDINGS.md
RESIDUAL_RISK.md
```

These artifacts should be updated during research, not reconstructed at the end from memory.

---

# 29. Prohibited Shortcuts

Do not:

- infer safety from number of previous audits;
- infer correctness from formal verification without auditing the specification and assumptions;
- infer security from line/branch coverage;
- assume a simple bug would already have been found;
- repeat generic vulnerability checklists and call that hardened research;
- treat previous findings as closed topics rather than variant seeds;
- trust external contracts because they implement the expected interface;
- trust current configuration to represent all reachable future configurations;
- review upgrades as text diffs only;
- ignore deployed state while auditing source;
- allow all researchers to converge on the first plausible theory;
- discard failed hypotheses without recording blockers;
- claim a candidate exploit without testing production reachability;
- encode implementation behavior into tests before proving the behavior is intended;
- use tool output as evidence without understanding the tool's blind spots;
- stop because fuzzing ran for a long time;
- stop because no high-severity finding appeared quickly;
- equate rarity with impossibility;
- equate complexity with severity;
- equate “out of scope” with “not security relevant”.

---

# 30. Hardened Research Loop

Run this loop repeatedly:

```text
establish production reality
        ↓
reconstruct security claims independently
        ↓
build graph + state model + trust boundaries
        ↓
mine history / patches / lineage for concrete seeds
        ↓
generate target-specific hypotheses
        ↓
choose the cheapest strong falsification experiment
        ↓
run manual + tool-assisted analysis
        ↓
validate reachability and economic/privilege impact
        ↓
record negative evidence and attack the blocker
        ↓
perform semantic variant search around every useful result
        ↓
update coverage + residual uncertainty
        ↓
select the next highest-information hypothesis
```

A finding is useful.

A disproven hypothesis with a strong blocker is useful.

A new invariant is useful.

A surviving security mutation is useful.

A deployment mismatch is useful.

A newly discovered blind spot in prior assurance is useful.

The hardened-target process succeeds when it systematically converts unknown security assumptions into tested claims and makes the remaining unknowns explicit.

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
