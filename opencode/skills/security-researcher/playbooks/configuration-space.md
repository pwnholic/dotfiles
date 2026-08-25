# Smart-Contract Configuration-Space Playbook

Load when on-chain behavior or exploitability varies by deployment parameters, roles, proxy state, chain/runtime features, market configuration, oracle/bridge selection, token semantics, or governance-reachable future settings.

## Smart-Contract Scope Lock

This playbook belongs to a **smart-contract / DeFi security research stack**. Apply it to on-chain programs, protocols, token systems, vaults, AMMs, lending, staking/restaking, governance, account abstraction, bridges, rollups/L2s, cross-chain systems, and infrastructure only when that infrastructure is causally necessary to an on-chain security property.

Do **not** expand the default search into generic web/backend/database/desktop/cloud security. An off-chain component belongs here only when compromising or mis-modeling it can change an on-chain authorization decision, state transition, message provenance, price, ordering/finality assumption, upgrade/deployment state, or realizable economic impact.

When a concrete exploit hypothesis exists, hand validation to `exploit-validation.md`.

# 1. Configuration Is Part of the Security Boundary

A contract source tree does not define one security behavior. Model the deployed instance as:

```text
source + compiler/runtime feature set
+ deployment topology
+ proxy/implementation state
+ role topology
+ market/token/oracle parameters
+ chain/L2 semantics
+ external integration addresses
+ governance-reachable future states
= actual security behavior
```

Treat configuration as state with provenance and writers. A value is not safe merely because the current production value is safe.

# 2. Bind the Current Deployment

For every production-relevant instance record:

```text
chain / chain-id / rollup
address / program-id
implementation / beacon / facet set
admin / upgrade authority
initializer / reinitializer status
roles and role admins
pauser / guardian / emergency authority
fee recipient / treasury
oracle and fallback oracle
bridge / messenger / verifier
market / pool / vault parameters
accepted token contracts
account-abstraction entry point / modules when used
feature/runtime gates
deployment block or slot
last configuration change
```

Prefer on-chain evidence. Documentation and deployment scripts are hypotheses until reconciled with current state.

# 3. Configuration Provenance

Classify every security-critical setting:

```text
IMMUTABLE
CONSTRUCTOR_BOUND
INITIALIZER_BOUND
GOVERNANCE_MUTABLE
ADMIN_MUTABLE
GUARDIAN_MUTABLE
MARKET_CREATOR_CONTROLLED
USER_SELECTABLE
EXTERNAL_PROTOCOL_DERIVED
CHAIN_RUNTIME_DERIVED
HISTORICAL_ONLY
UNKNOWN
```

Record the writer, delay/timelock, bounds, validation, and whether the change can be batched atomically with another action.

# 4. Security-Relevant Dimensions

Select dimensions from architecture, not a universal checklist. Common smart-contract axes include:

- proxy kind: transparent / UUPS / beacon / diamond / clone / immutable;
- implementation version and reachable legacy implementations;
- initializer/reinitializer state;
- storage namespace/layout version;
- role membership and role-admin graph;
- multisig threshold and signer set;
- timelock delay, predecessor/salt semantics, cancellation authority;
- pause scope and bypass paths;
- oracle source, heartbeat, deviation bounds, decimals, fallback;
- sequencer uptime feed and recovery grace period;
- collateral/borrow factor, liquidation threshold/bonus, caps;
- interest model and utilization kink;
- vault decimals offset, fees, strategy adapters, loss handling;
- AMM fee tier, hook address/permissions, tick spacing, pool parameters;
- token address, decimals, transfer semantics, wrapper/bridged variant;
- bridge messenger/verifier, source/destination mapping, finality mode;
- chain-specific precompiles/opcodes/runtime features;
- ERC-4337 EntryPoint, paymaster, validator/module configuration;
- EIP-7702-compatible authorization assumptions;
- Solana program upgrade authority, token program choice, PDA derivations;
- emission/reward schedules, epochs, cooldowns, withdrawal queues;
- allowlists/denylists and market-creation templates.

# 5. Reachable Configuration Space

Do not enumerate Cartesian products blindly. Build a graph:

```text
current config
  ├─ permissionless transition
  ├─ operator transition
  ├─ governance proposal + delay
  ├─ upgrade + migration
  ├─ market/factory instantiation
  └─ chain/runtime activation
       ↓
reachable future configuration
```

For each transition record authority, delay, validation, dependencies, reversibility, and whether funds can already be present when the new configuration becomes active.

# 6. Interaction Search

Most serious configuration failures are interactions between individually valid values. Search pairs and triples such as:

```text
low oracle heartbeat + short liquidation window
high LTV + thin liquidity + generous liquidation bonus
new token decimals + old scale assumption
new implementation + old storage + missed reinitializer
bridge fast path + weak finality + replay window
hook enabled + callback-capable token + unlocked accounting
paymaster sponsorship + validator module + delegated EOA
paused core + unpaused alternate withdrawal path
```

Prioritize combinations that alter authority, solvency, price integrity, state synchronization, or irreversible value movement.

# 7. Bounds Are Code

For every mutable numeric parameter, distinguish:

- hard-coded protocol bound;
- setter validation;
- governance policy only;
- UI recommendation;
- no bound.

Test exact minimum/maximum, zero, one, near-unit scale, threshold ±1, and cross-parameter constraints. A governance-only convention is not an on-chain invariant.

# 8. Address Configuration

An address field is a trust decision. Verify:

- zero-address semantics;
- EOA vs contract assumptions under EIP-7702;
- code existence at set time and use time;
- proxy indirection and upgradeability of the dependency;
- interface support vs actual semantics;
- chain-specific canonical addresses;
- CREATE2/redeployment assumptions where applicable;
- allowlist membership lifecycle;
- whether a malicious callback-capable implementation is reachable.

# 9. Oracle Configuration

Record source, decimals, heartbeat, deviation rules, staleness checks, round completeness, fallback hierarchy, sequencer checks, grace period, TWAP window, quote asset, and accepted failure modes.

Search for disagreement between:

```text
configured freshness bound vs actual feed heartbeat
feed decimals vs protocol scale
fallback source vs primary source semantics
L2 sequencer recovery vs immediate liquidation
TWAP window vs manipulation capital window
```

# 10. Upgrade / Governance Configuration

Model upgradeability as configuration reachability. Verify:

- proxy implementation slots / beacon / facets;
- admin and upgrade authorization path;
- timelock delay and bypass/emergency path;
- initializer/reinitializer calls coupled to upgrade;
- storage compatibility and ERC-7201 namespace uniqueness where used;
- rollback or old-implementation reachability;
- batched upgrade + parameter change effects;
- Solana upgrade authority and immutability state for SVM programs.

# 11. Chain and Runtime Feature Configuration

Bind analysis to the actual runtime feature set. Examples:

- hardfork activation;
- EIP-1153 transient storage availability;
- EIP-7702 delegated-account semantics;
- chain-specific precompiles/opcodes;
- L2 timestamp/block-number semantics;
- sequencer/finality model;
- gas/compute limits;
- Solana loader/runtime feature gates and program deployment slot behavior.

A finding dependent on a runtime feature must state where that feature is active.

# 12. Configuration Differential Testing

For high-risk axes, replay the same sequence under A/B configurations and compare security-relevant state.

Useful deltas:

```text
old implementation ↔ new implementation
primary oracle ↔ fallback oracle
canonical token ↔ bridged/wrapper token
L1 ↔ L2 deployment
pre-feature ↔ post-feature runtime
hook disabled ↔ enabled
normal EOA ↔ delegated EOA
EntryPoint/module version A ↔ B
```

A difference is a lead when the protocol assumes equivalence.

# 13. Configuration Matrix

Maintain `CONFIG_MATRIX.md`:

```text
ID
dimension
current value
allowed values / bounds
writer / authority
activation delay
on-chain validation
production instances
security properties affected
interaction partners
tested states
negative evidence
open questions
```

Do not reconstruct this at the end from memory.

# 14. Configuration Exploitability Gate

Before promoting a configuration-specific finding, prove:

1. the configuration exists or is reachable under the stated attacker/governance model;
2. the vulnerable behavior is present under that exact configuration;
3. required external integrations exist there;
4. value/authority is exposed there;
5. the exploit does not rely on a synthetic combination unavailable in production;
6. impact is scoped to affected deployments rather than generalized across all deployments.

Route the resulting candidate through `exploit-validation.md`.

# 15. Closure

Do not conclude “configuration safe.” Conclude with bounded coverage:

```text
current production configurations tested
governance-reachable configurations tested
factory-created variants tested
chain/runtime variants tested
interaction pairs/triples tested
unreachable configurations excluded with evidence
residual configuration uncertainty
```

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
