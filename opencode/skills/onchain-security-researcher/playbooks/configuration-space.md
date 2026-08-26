# Configuration-Space Playbook

Load when exploitability varies across deployments, roles, parameters, proxy
state, external integrations, runtime features, or governance-reachable future
settings.

## Objective

Treat configuration as versioned security state with provenance and writers:

```text
source + artifact + deployment topology + initialized state
+ roles + parameters + integrations + runtime features
= actual security behavior
```

The current safe tuple does not prove that a historical or reachable future
tuple is safe.

## Configuration record

For every security-relevant variable record:

```text
name and type
current value at block/slot
accepted domain and cross-variable constraints
writer / role-admin / provenance
activation delay and batching behavior
on-chain validation
historical values
reachable future values
properties and deployments affected
```

Useful provenance classes:

```text
IMMUTABLE | CONSTRUCTOR_BOUND | INITIALIZER_BOUND
GOVERNANCE_MUTABLE | ADMIN_MUTABLE | GUARDIAN_MUTABLE
FACTORY_CONTROLLED | USER_SELECTABLE | EXTERNAL_DERIVED
RUNTIME_DERIVED | HISTORICAL_ONLY | UNKNOWN
```

Prefer on-chain state and executed transactions over intended deployment
scripts or documentation.

## Constraint-guided search

Represent constraints separately:

```text
domain       one value is accepted
relational   values remain coherent together
transition   tuple is reachable from current state
temporal     delay/order/finality condition holds
exposure     assets or authority exist while tuple is active
```

Build a transition graph through permissionless setters, roles, governance,
upgrades/migrations, factories, external state, and runtime activation. Record
authority, delay, atomic composition, reversibility, and exposed value for each
edge.

Do not enumerate the Cartesian product blindly. Generate pairwise or higher
`t`-way combinations only after identifying interaction strength. Raise
strength around shared units, writers, fallback paths, migrations, callbacks,
and value sinks. Seed forbidden and boundary tuples from code and deployed
history.

High-value interactions include:

```text
oracle heartbeat × liquidation window × sequencer recovery
LTV × liquidity depth × bonus/caps
token decimals/semantics × legacy scaling
new implementation × old storage × reinitializer
bridge path × verifier/finality × replay window
hook permissions × callback token × temporary accounting
paymaster × module/validator × delegated EOA
pause scope × alternate exit path
```

## Dimension selection

Select only architectural dimensions that can change a protected property:

- implementation/beacon/facets, storage layout, initializer state;
- roles, role-admin graph, multisig/timelock/emergency paths;
- oracle/fallback, heartbeat, decimals, sequencer feed and grace period;
- market caps, factors, fees, indices, queues, hooks, accepted tokens;
- bridge messenger/verifier/domain mapping and finality mode;
- AA EntryPoint, paymaster, module, delegation assumptions;
- chain/runtime feature activation and precompiles;
- SVM loader, executable slot, Token/Token-2022, upgrade authority;
- factory templates, allowlists, registries, adapters.

An address is a trust decision. Check zero/EOA/contract semantics, delegated
EOAs, code at set/use time, proxy or upgrade indirection, interface-vs-behavior,
canonical chain identity, redeployment, and callback capability.

## Differential tests

Replay the same security-relevant sequence across configurations expected to
be equivalent:

```text
old/new implementation | primary/fallback oracle | L1/L2
canonical/wrapped token | feature off/on | hook off/on
legacy/delegated EOA | EntryPoint/module A/B
```

A delta is a lead only when the property assumes equivalence.

## Time-versioned exposure

For a vulnerable tuple report:

```text
first known reachable state
enabling transaction/proposal and writer
last known exposed state
assets/authority exposed during interval
current remediation state
transition that would reopen it
```

Availability is configuration. Verify that the assumed feed, bridge,
verifier, precompile, or EntryPoint version exists and is supported on the
target chain; absence or deprecation must select an explicit failure path.

## Output and handoff

Maintain `CONFIG_MATRIX` with tested tuples, uncovered interactions, negative
evidence, and unknowns. Before handoff establish that the tuple exists or is
reachable, the vulnerable behavior occurs under it, required integrations and
exposure exist, and impact is scoped to affected deployments.

Send to exploit validation:

```text
deployment identity | current/historical/reachable tuple | writer and path
interaction violated | exposure interval | reproduction | residual unknowns
```

Closure is a bounded statement of current, historical, governance/factory, and
runtime tuples tested—not “configuration safe.”

## Current semantic sources

- EIP-7702: https://eips.ethereum.org/EIPS/eip-7702
- ERC-4337 releases: https://github.com/eth-infinitism/account-abstraction/releases
- OpenZeppelin upgrade constraints: https://docs.openzeppelin.com/upgrades-plugins/writing-upgradeable
- Chainlink sequencer-feed availability: https://docs.chain.link/data-feeds/l2-sequencer-feeds

Re-check activation and deployment state before relying on them.
