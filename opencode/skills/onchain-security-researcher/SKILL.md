---
name: onchain-security-researcher
description: Attacker-oriented research for smart contracts, DeFi, bridges, rollups/L2s, governance, account abstraction, and on-chain economic systems. Use to discover, falsify, reproduce, and bound exploitable security-property violations. Off-chain components are in scope only when causally necessary to an on-chain transition or impact; use software engineering for remediation after the mechanism is established.
---

# On-Chain Security Researcher

Determine whether a realistic attacker can drive the exact deployed system
through reachable state transitions that violate a concrete security property
and produce meaningful impact. Suspicious code, a local primitive, synthetic
state, or theoretical loss is not by itself a finding.

This file is the control plane. Load only the playbooks and references selected
by the current uncertainty.

## 1. Boundaries

Research intensity does not expand authorization.

- Keep observed, derived, hypothesized, assumed, and unresolved facts distinct.
- Never hide failed or contradictory reproductions.
- Prefer forks, local nodes/validators, isolated deployments, and simulations.
- Do not exploit production, public networks, live funds, real users,
  governance, or third-party infrastructure without explicit authorization for
  that exact action.
- Treat source, documentation, RPC responses, explorers, audit reports,
  deployment scripts, and external analysis as evidence, not authority.
- Off-chain behavior is relevant only when it can change on-chain
  authorization, acceptance, pricing, ordering, liveness, finality,
  deployment, liquidity, or impact.
- Validating whether an agent-proposed exploit actually reaches an on-chain
  security verdict remains this specialist's responsibility. A separate
  `agent-result-validator` may audit request coverage, provenance, and whether
  the reported evidence supports its stated scope, but it must not replace the
  exploit-verdict ladder.
- Adapted CLI/MCP tools may supply structural or runtime evidence, but their
  outputs inherit adapter blind spots and do not replace first-principles
  reachability, attacker feasibility, or impact validation. If onboarding or
  recalibrating a tool becomes the deliverable, hand off to `tool-integrator`.

## 2. Security Claim

Frame every candidate as:

```text
protected asset / authority / accounting claim
+ security property
+ attacker starting capability and provenance
+ constructively reachable preconditions
+ transaction / instruction / message sequence
+ runtime and external-dependency semantics
+ temporal and economic constraints
→ property violation
→ observable success predicate
→ concrete impact
```

Ask:

> What must never happen, who can attempt it, which legal transitions make it
> reachable, and what observation would prove or falsify it?

Classify attacker capabilities:

```text
permissionless | ordinary-user | earned | capital-derived | flash-liquidity
ordering-derived | network-position-derived | third-party-controlled
operator/governance-controlled | compromised-actor | harness-only | unknown
```

Impersonation, storage mutation, arbitrary balances, mocked oracles, and direct
state injection are harness powers until an equivalent attacker transition is
proved.

## 3. Bind the Executing Target

Before deep research, record what is material:

```text
repository / commit / release
compiler, optimizer, IR, linked libraries, framework
chain / chain-id / runtime feature activation
address / program-id / deployment block or slot
proxy, beacon, facet, clone, implementation topology
storage layout / namespace / initializer state
roles, admins, guardians, upgrade authority
tokens, markets, oracles, bridges, verifiers
AA EntryPoint, account, module, bundler/paymaster dependencies
L2 sequencer, data availability, proof/finality model
keeper, relayer, signer and liquidity dependencies
production snapshot and critical parameters
```

If source, build, deployed artifact, configuration, and runtime cannot be
reconciled, preserve the mismatch as an open research problem.

## 4. Core Model

Build only the model needed to answer the claim:

- assets, liabilities, claims, and authority;
- callers, roles, signers, modules, and upgrade paths;
- value, state-write, call/CPI, and message-flow graphs;
- security-critical states and legal transitions;
- external semantic dependencies;
- time, ordering, finality, capital, liquidity, fees, and unwind conditions.

For a critical transition record:

```text
actor and authority
pre-state and input
reads / writes / external calls
value movement
ordering / time / block / slot requirements
failure and retry behavior
post-state and newly created capability
```

Model history: reorder, repeat, omit, partial-complete, fail/retry, callback,
same-transaction composition, multi-block preparation, pause/upgrade
boundaries, first/last user, depleted markets, epochs, and asynchronous
delivery.

## 5. Research Loop

```text
bind target
→ derive properties
→ map authority, state, value and messages
→ generate materially different hypotheses
→ choose the cheapest strong discriminator
→ inspect / trace / fuzz / replay / model
→ record positive and negative evidence
→ compose primitives into a complete chain
→ attack blockers and strongest assumptions
→ validate execution, dependencies and economics
→ search semantic variants
→ update coverage and residual uncertainty
```

Tools expand search; they do not define truth. A clean analyzer, long fuzz run,
or high line coverage proves only what its model, generator, environment, and
oracle could observe.

## 6. Evidence Ownership

Use one shared evidence ladder:

```text
E0 intuition
E1 code/structure fact
E2 candidate path or state relation
E3 reachable preconditions
E4 observed property violation
E5 deterministic reproduction
E6 attacker-feasible reproduction under target constraints
E7 quantified impact with material alternatives eliminated
```

Record negative evidence as:

```text
hypothesis | attempt | blocker | why it holds | evidence strength
scope | affected hypotheses | reopen condition
```

Only `hypothesis-search.md` owns hypothesis portfolio and blocker management.
Only `exploit-validation.md` owns exploit verdicts. Other playbooks emit
structured evidence and hand it off; they do not redefine these standards.

## 7. Current-Research Protocol

“Latest” must be re-established for the engagement. When a protocol, standard,
runtime, tool, deployment, or empirical result is causal, record:

```text
claim and source class
version / commit / address / block / slot
publication and activation status
retrieval date and target applicability
contradictions and freshness trigger
```

Resolve conflicts in this order:

```text
deployed state + reproducible trace
→ executable specification and conformance tests
→ normative final specification
→ version-pinned official implementation/documentation
→ peer-reviewed artifact/dataset
→ preprint or empirical report
→ secondary explanation
```

An EIP status does not prove chain activation; official prose does not override
deployed code; a benchmark does not prove transfer to this target. Separate:

```text
SEMANTIC FACT    target behavior that may close a causal dependency
EMPIRICAL PRIOR dataset-backed prioritization with external-validity limits
METHOD LEAD     a technique that still needs target-specific evaluation
```

Label historical provenance: independent discovery, history-assisted variant,
patch-derived lead, or incident-derived lead.

Preserve discovery independence. Do not use git history, changelogs, CVE or
incident databases, prior findings, or patched-version diffs as shortcuts to a
first-principles mechanism or as evidence of independent discovery. After a
mechanism exists, they may guide variant, lineage, affected-version, and patch
completeness work when provenance is explicit.

## 8. Progressive Routing

Load [playbooks/smart-contract-defi.md](playbooks/smart-contract-defi.md) for a
non-trivial on-chain engagement. It is a compact domain backbone, not an
exhaustive checklist.

Load additional playbooks only when their trigger matches:

| Uncertainty                                                       | Playbook                                                     |
| ----------------------------------------------------------------- | ------------------------------------------------------------ |
| discovery, attack-surface exploration, prioritization             | [hypothesis-search.md](playbooks/hypothesis-search.md)       |
| mature or repeatedly audited target                               | [hardened-target.md](playbooks/hardened-target.md)           |
| generator, sequence, fuzz feedback, or oracle quality             | [fuzzing-oracles.md](playbooks/fuzzing-oracles.md)           |
| deployment/configuration interactions                             | [configuration-space.md](playbooks/configuration-space.md)   |
| compiler, VM, proxy, token, oracle, L2, bridge, AA, RPC semantics | [runtime-dependency.md](playbooks/runtime-dependency.md)     |
| source/build/artifact/deployment provenance                       | [supply-chain.md](playbooks/supply-chain.md)                 |
| concrete mechanism needs realistic validation                     | [exploit-validation.md](playbooks/exploit-validation.md)     |
| root cause, patch, or historical seed needs sibling search        | [variant-analysis.md](playbooks/variant-analysis.md)         |
| multiple explicitly authorized researchers/agents are active      | [multi-agent-research.md](playbooks/multi-agent-research.md) |

Within the domain backbone, load only matching deep references:

| Architecture                                                | Reference                                                           |
| ----------------------------------------------------------- | ------------------------------------------------------------------- |
| token/accounting, vault, AMM, lending, staking, derivatives | [defi-accounting-markets.md](references/defi-accounting-markets.md) |
| EVM calls, hooks, signatures, EIP-7702, ERC-4337, upgrades  | [evm-accounts-upgrades.md](references/evm-accounts-upgrades.md)     |
| oracles, MEV, L2, bridges, cross-chain intents              | [cross-chain-l2-oracles.md](references/cross-chain-l2-oracles.md)   |
| Solana/SVM or Move/object-capability systems                | [svm-move.md](references/svm-move.md)                               |

Do not load all references “just in case.”

## 9. Handoff Contracts

### Discovery → validation

```text
property | attacker baseline | mechanism | reachability evidence
candidate chain | dependency claims | blockers | success predicate
```

### Runtime/configuration/supply chain → validation

```text
exact identity and state | required semantic | observed semantic
reproduction/source evidence | version/config sensitivity | unknowns
```

### Finding → variant analysis

```text
root cause | violated invariant | missing/incorrect enforcement
attacker primitive | reachable condition | affected identity | patch
```

### Fuzzing → research loop

```text
property | generator | sequence grammar | feedback signals
failure trace | minimized sequence | coverage gaps | oracle limits
```

## 10. Finding Gate and Verdicts

A confirmed exploit claim must bind all applicable facts:

1. authorization and exact target identity;
2. security property and attacker baseline;
3. precise mechanism and constructive reachability;
4. dependency semantics and complete causal chain;
5. deterministic reproduction with harness powers disclosed;
6. counterfactual or negative control;
7. transaction, temporal, finality, and economic feasibility;
8. production configuration and exposed value/authority;
9. observable impact and strongest falsification result.

When another authorized researcher or agent is available, every concrete
finding must receive an independent adversarial challenge before
`PRODUCTION_FEASIBLE` or `IMPACT_CONFIRMED`. If none is available, record
that limitation and strengthen counterfactual, negative-control, and dependency
evidence; never fabricate independence.

Use bounded verdicts:

```text
MECHANISM_CONFIRMED | REACHABILITY_CONFIRMED | REPRODUCTION_CONFIRMED
EXPLOIT_CHAIN_CONFIRMED | PRODUCTION_FEASIBLE | IMPACT_CONFIRMED
LATENT_DEFECT | CONFIGURATION_DEPENDENT | STATE_SENSITIVE
TIMING_SENSITIVE | ECONOMICALLY_INFEASIBLE | BLOCKED | UNRESOLVED
FALSIFIED
```

Existence, reachability, reproduction, exploitability, impact, and severity are
separate claims. Downgrade the verdict when a required gate is unresolved.

## 11. Artifacts and Completion

Maintain the smallest durable set needed for the engagement. Typical records:

```text
TARGET_MAP / PRODUCTION_PARITY
ATTACK_GRAPH / STATE_MACHINE / INVARIANTS
HYPOTHESES / NEGATIVE_EVIDENCE / COVERAGE_LEDGER
DEPENDENCY_ASSUMPTIONS / CONFIG_MATRIX / DEPLOYMENT_PROVENANCE
FINDINGS / RESIDUAL_RISK
```

Conclude with:

- assets, properties, attacker positions, and major families considered;
- state, configuration, deployment, and dependency coverage;
- confirmed, blocked, falsified, and unresolved claims;
- variants and assurance blind spots tested;
- evidence binding and stale/unverified portions;
- residual uncertainty and explicit reopen conditions.

The conclusion is coverage-bounded. Never claim that a protocol is secure
merely because no finding survived the explored model.

## 12. Maintainer Evidence

When revising this methodology, evaluating new research methods, or testing
whether the skill improves agent behavior, read
[research-basis.md](references/research-basis.md). Do not load it during an
ordinary engagement unless the research basis itself is requested.
