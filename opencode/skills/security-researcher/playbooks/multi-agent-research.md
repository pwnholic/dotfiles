# Smart-Contract Multi-Agent Security Research Playbook

Load when multiple researchers or agents are available for a smart-contract / DeFi engagement.

## Smart-Contract Scope Lock

This playbook belongs to a **smart-contract / DeFi security research stack**. Apply it to on-chain programs, protocols, token systems, vaults, AMMs, lending, staking/restaking, governance, account abstraction, bridges, rollups/L2s, cross-chain systems, and infrastructure only when that infrastructure is causally necessary to an on-chain security property.

Do **not** expand the default search into generic web/backend/database/desktop/cloud security. An off-chain component belongs here only when compromising or mis-modeling it can change an on-chain authorization decision, state transition, message provenance, price, ordering/finality assumption, upgrade/deployment state, or realizable economic impact.

When a concrete exploit hypothesis exists, hand validation to `exploit-validation.md`.

# 1. Principle

Parallel research is useful only when it increases **independent attack-surface coverage** or accelerates falsification.

```text
independent exploration
→ structured evidence handoff
→ centralized on-chain model
→ cross-path composition
→ adversarial validation
```

Do not create several agents to read the same contracts with the same vulnerability checklist.

# 2. Decompose by Security Question

Strong smart-contract assignments are orthogonal, for example:

- asset/accounting conservation;
- authorization, roles, governance and upgrade paths;
- state-machine / lifecycle sequences;
- oracle / pricing / liquidation;
- AMM/vault/lending economic composition;
- callbacks, hooks, reentrancy and external calls;
- signatures, permits, EIP-7702, ERC-4337;
- bridge/cross-chain/message provenance;
- L2/sequencer/finality;
- runtime/compiler/proxy semantics;
- deployment/configuration variants;
- SVM account/PDA/CPI branch;
- historical patch/variant analysis;
- independent exploit falsification.

# 3. Assignment Contract

Every agent receives:

```text
TARGET REVISION / DEPLOYMENT
CHAIN / RUNTIME
SURFACE
SECURITY PROPERTY
ATTACKER STARTING CAPABILITY
EXPLOIT FAMILY
PRIMARY HYPOTHESIS
ORTHOGONAL ALTERNATIVE
STATE / CONFIGURATION BOUNDARY
DEPENDENCIES TO VERIFY
REQUIRED EVIDENCE
NON-GOALS
STOP / ESCALATION CONDITION
OUTPUT SCHEMA
```

Assignments must be narrow enough to avoid duplicate prose but broad enough to follow a chain across contracts when the property crosses them.

# 4. Shared On-Chain Model

All agents operate against one reconciled model of:

```text
asset map
contract/program deployment map
proxy/implementation graph
role and authority graph
state-machine transitions
external protocol dependencies
price/oracle graph
bridge/message graph
governance/upgrade graph
configuration matrix
```

An agent may challenge the model, but must state the evidence that changes it.

# 5. Evidence Objects

Agents hand off structured objects, not conclusions only:

```text
OBSERVATION
HYPOTHESIS
PROPERTY
ATTACKER MODEL
REACHABILITY
MECHANISM
DEPENDENCY FACT
BLOCKER
NEGATIVE EVIDENCE
VARIANT LEAD
REPRODUCTION
IMPACT DELTA
RESIDUAL UNKNOWN
```

Every object should identify source file/line, deployed address/state, trace/test, or authoritative runtime/spec evidence when applicable.

# 6. Anti-Convergence

Keep materially different exploit families alive until evidence justifies concentration. A high-severity-looking oracle theory should not cause every agent to abandon authorization, upgrade, bridge, or accounting work.

Track portfolio coverage explicitly and reserve effort for neglected high-blast-radius surfaces.

# 7. Root-Agent Synthesis

The root agent owns cross-agent composition. After each meaningful result ask:

- does this change a global invariant?
- does it invalidate another agent's assumption?
- do two weak primitives compose?
- does one blocker kill several paths?
- did a dependency/configuration fact reopen a path?
- is the same root cause present on another deployment?
- which next experiment has highest information value?

Do not resolve contradictions by voting. Design a discriminator.

# 8. Duplicate Detection

Two agents are duplicates when they test the same security property, attacker model, state region, and mechanism even if they inspect different files. Merge them or split along a real dimension such as configuration, chain, implementation, attacker role, or falsification method.

# 9. Cross-Chain and Multi-Deployment Allocation

For protocols deployed across chains, allocate by **semantic differences**, not one agent per chain by default. Separate agents when chains differ in runtime, bridge path, oracle, token implementation, proxy version, governance, L2 finality, or liquidity enough to change security behavior.

# 10. Independent Validator

For a candidate finding, the validator's mission is to **break the claim**. They should challenge:

- target/deployment binding;
- attacker capability provenance;
- reachable pre-state;
- dependency behavior;
- harness cheats/mocks;
- timing/order/finality;
- capital/liquidity;
- counterfactual root cause;
- impact accounting;
- affected configuration/version scope.

Do not prime the validator with “confirm this.”

# 11. Shared-State Drift

Invalidate or re-check agent conclusions when any of these change during research:

- source revision;
- implementation/proxy target;
- deployed configuration;
- oracle/bridge dependency;
- chain fork/runtime assumption;
- test harness;
- attacker model.

Stale evidence must not silently survive a target change.

# 12. Tool Diversity

Different agents should preferentially use different evidence paths when practical: manual state modelling, invariant fuzzing, fork replay, differential testing, bytecode/deployment verification, runtime/source inspection, historical patch analysis. Tool diversity is valuable only when it reduces correlated blind spots.

# 13. Research Ledger

Maintain one shared ledger:

```text
ID
owner
property
attack family
status: OPEN / ACTIVE / BLOCKED / EXHAUSTED / CONFIRMED / FALSIFIED
evidence
blocker
reopen condition
coverage delta
dependencies
related hypotheses
next discriminator
```

Do not let failed paths disappear.

# 14. Completion

Multi-agent work is complete only when the root synthesis can state which major on-chain properties and exploit families were covered, which findings survived independent challenge, what variants/configurations were checked, which paths are blocked/exhausted, and where residual uncertainty remains.

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
