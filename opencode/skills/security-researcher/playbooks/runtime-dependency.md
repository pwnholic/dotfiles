# Smart-Contract Runtime and Dependency Escalation Playbook

Load when smart-contract exploitability depends on VM/runtime, compiler, proxy/storage, token/oracle/bridge behavior, chain/L2 semantics, account abstraction, RPC/client behavior, or another external component that is causal to the on-chain security property.

## Smart-Contract Scope Lock

This playbook belongs to a **smart-contract / DeFi security research stack**. Apply it to on-chain programs, protocols, token systems, vaults, AMMs, lending, staking/restaking, governance, account abstraction, bridges, rollups/L2s, cross-chain systems, and infrastructure only when that infrastructure is causally necessary to an on-chain security property.

Do **not** expand the default search into generic web/backend/database/desktop/cloud security. An off-chain component belongs here only when compromising or mis-modeling it can change an on-chain authorization decision, state transition, message provenance, price, ordering/finality assumption, upgrade/deployment state, or realizable economic impact.

When a concrete exploit hypothesis exists, hand validation to `exploit-validation.md`.

# 1. Escalation Trigger

Escalate when an exploit hypothesis requires a fact not defined by the immediate contract/program source, for example:

```text
"delegatecall uses this storage context"
"the proxy points to this implementation"
"this opcode/precompile behaves this way on this chain"
"the optimizer preserves this assumption"
"this token callback can occur"
"this oracle round/fallback has these semantics"
"this bridge message becomes final here"
"the sequencer can order/delay this"
"EntryPoint/paymaster validation guarantees this"
"this Solana CPI grants these privileges"
```

Do not escalate to unrelated infrastructure merely because it exists.

# 2. Smart-Contract Dependency Graph

Use the causal graph actually relevant to the security property:

```text
protocol logic
  ↔ proxy / dispatcher / module system
  ↔ contract libraries / token implementations
  ↔ compiler / optimizer / ABI
  ↔ VM / runtime / precompiles / syscalls
  ↔ chain client / hardfork / feature activation
  ↔ L2 sequencer / finality / cross-domain messenger
  ↔ oracle / DEX / bridge / external protocol
  ↔ relayer / keeper / bundler / signer set when on-chain result depends on it
```

Edges may skip layers. Follow causality, not a rigid stack.

# 3. Dependency Claim Record

For each causal fact record:

```text
CLAIM ID
required semantic
component
exact version / address / program-id
chain / runtime feature set
configuration
call / message path
source/spec evidence
observed evidence
minimal reproduction
version/config sensitivity
impact on exploit chain
status
```

# 4. Exact Identity Gate

Bind the dependency precisely:

- deployed address/program ID;
- proxy implementation / beacon / facet;
- codehash / bytecode / executable hash;
- compiler and optimizer settings;
- library linking / immutables;
- chain ID / runtime version / hardfork feature set;
- oracle feed / aggregator / wrapper;
- bridge messenger/verifier and source-domain mapping;
- EntryPoint/paymaster/module version;
- Solana loader/programdata/upgrade authority.

Generic docs for “the protocol” are insufficient if the deployed component differs.

# 5. Evidence Classes

Classify dependency semantics:

```text
SPECIFIED
SOURCE_CONFIRMED
DEPLOYMENT_CONFIRMED
OBSERVED_ON_FORK
OBSERVED_ON_LOCAL_RUNTIME
CHAIN_FEATURE_DEPENDENT
VERSION_DEPENDENT
CONFIGURATION_DEPENDENT
IMPLEMENTATION_DEFINED
ASSUMED
UNKNOWN
CONTRADICTED
```

Production-feasible exploit claims cannot rest on a security-critical `UNKNOWN` without explicit downgrade.

# 6. EVM Call-Context Semantics

When causal, verify exact behavior of:

- `call`, `staticcall`, `delegatecall`;
- `msg.sender`, `msg.value`, `tx.origin`;
- code vs storage context;
- returndata/revert bubbling;
- fallback/receive dispatch;
- gas forwarding and griefing assumptions;
- CREATE/CREATE2 address and initialization behavior;
- selfdestruct semantics under the active hardfork;
- EIP-7702 delegated-account behavior;
- transaction-scoped transient storage under EIP-1153.

Do not inherit pre-hardfork folklore.

# 7. Proxy, Dispatcher, and Storage Semantics

For upgradeable/modular systems inspect:

- EIP-1967/UUPS/beacon/diamond/minimal-proxy mechanics as actually implemented;
- admin routing and selector collisions;
- implementation initialization;
- storage layout and packing;
- inherited layout changes;
- ERC-7201 namespace identifiers where used;
- delegatecall context;
- facet/module replacement;
- stale implementation reachability;
- migration/reinitializer ordering.

A source-level function may be safe while proxy state makes another implementation reachable.

# 8. Compiler and Optimizer Escalation

Escalate to compiler semantics when the claim depends on generated code, Yul/assembly, ABI encoding, optimizer transformations, memory safety annotations, immutables, metadata, library linking, or a compiler bug.

Bind exact compiler version and settings. Compare standard-json input/output when possible. Reproduce on the same build configuration and inspect generated IR/bytecode only as deep as needed to resolve the causal question.

# 9. ABI / Encoding / Signature Semantics

Verify:

- `abi.encode` vs packed encodings;
- selector derivation and collisions;
- calldata length/trailing data assumptions;
- returndata decoding;
- EIP-712 domain separator, chain ID, verifying contract;
- nonce/replay scope;
- ERC-1271 semantics;
- permit variants;
- delegated-account signatures under EIP-7702;
- account-abstraction validation data and aggregation when used.

An SDK encoding assumption is not evidence of what the contract accepts.

# 10. Token and External Contract Semantics

Inspect the exact implementation when protocol security depends on token behavior. Cover relevant cases such as no/false return values, fee-on-transfer, rebasing, hooks/callbacks, transfer restrictions, mint/burn authority, decimals, wrappers, ERC-4626 shares, ERC-6909, bridged variants, Token-2022 extensions, or upgradeable tokens.

Do not rely on interface conformance as a behavioral guarantee.

# 11. Oracle Runtime Semantics

For causal price facts bind:

- feed/aggregator/wrapper addresses;
- decimals;
- heartbeat/deviation behavior;
- round completeness / stale data checks;
- fallback logic;
- sequencer uptime feed and recovery grace period on L2;
- TWAP observation/window semantics;
- update permissions and liveness.

Separate “oracle can report X” from “attacker can cause/encounter X under production rules.”

# 12. AMM / Hook / Callback Dependencies

For external DEX or hook-based systems verify exact callback points, lock/unlock rules, settlement/accounting deltas, hook permissions, pool identity, fee behavior, and reentrancy/composition semantics. Uniswap v4-style hooks and flash accounting are runtime dependencies when the target composes with them.

# 13. Account Abstraction

For ERC-4337 paths model:

```text
UserOperation
→ bundler simulation
→ EntryPoint
→ account validation
→ paymaster validation
→ execution
→ postOp / settlement
```

Bind EntryPoint version, validation rules, nonce/key semantics, aggregator/module behavior, paymaster stake/deposit and griefing constraints, and EIP-7702 interaction where enabled. Bundler policy and on-chain validity are distinct layers.

# 14. L2 / Rollup Semantics

Bind the target rollup's actual rules for:

- sequencer inclusion/liveness;
- forced inclusion/escape path;
- L1↔L2 address/message mapping;
- block/timestamp semantics;
- deposits/withdrawals;
- proof/challenge/finalization state;
- replay/message identifiers;
- cross-L2 interoperability;
- reorg/finality assumptions.

“EVM-compatible” does not imply Ethereum L1 ordering or finality semantics.

# 15. Bridge / Cross-Chain Dependencies

Trace:

```text
source state
→ message construction
→ source authentication
→ signer/quorum/proof
→ transport/relay
→ destination messenger
→ destination validation
→ replay/order/finality
→ value/state effect
```

Verify domain identifiers, token mappings, finality assumptions, message uniqueness, retry/cancel paths, verifier upgrades, and fast/slow path differences.

# 16. RPC / Node-Client Semantics

RPC is in scope only when protocol or exploit validation depends on what it reports or accepts. Examples:

- `eth_call`/simulation vs transaction execution;
- historical state availability;
- pending/latest/safe/finalized tags;
- trace semantics;
- log/indexing delay;
- client disagreement on chain data;
- transaction replacement/nonce observations.

Never use one RPC response to override canonical on-chain state without resolving the discrepancy.

# 17. Sequencers, Relayers, Keepers, Bundlers, Signers

Off-chain actors enter this playbook only when their behavior changes an on-chain transition. Record whether the attacker controls, influences, races, censors, delays, or merely depends on them. Model alternative paths if the actor disappears. Distinguish protocol-enforced guarantees from operational convention.

# 18. Solana / SVM Runtime Branch

When causal, verify current SVM semantics for:

- caller-supplied account identity;
- owner / signer / writable enforcement;
- PDA seeds and `invoke_signed`;
- CPI privilege propagation;
- arbitrary program substitution;
- duplicate account aliasing;
- Token vs Token-2022 program behavior;
- compute budget and call depth;
- account close/realloc;
- loader/programdata/upgrade authority;
- deployment visibility and runtime feature gates.

Bind to current Solana runtime documentation/source; do not import EVM assumptions.

# 19. Differential Runtime Testing

When equivalence is assumed, compare:

```text
implementation A ↔ B
proxy ↔ direct implementation
old ↔ new compiler
optimizer off ↔ on
L1 ↔ target L2
client/runtime A ↔ B
canonical token ↔ supported variant
old EntryPoint/module ↔ new
pre-upgrade ↔ post-upgrade
```

A divergence is not automatically a vulnerability; it becomes a lead when a security property assumes equivalence.

# 20. Minimal Semantic Reproduction

Isolate the external semantic fact without accidentally proving the whole exploit with test-only power. The reproduction should state exact environment, input/call context, expected semantic, observed semantic, and which exploit edge depends on it. Then re-integrate it into the full chain.

# 21. Dependency Closure

Before handing back to exploit validation, enumerate every external causal fact:

```text
D1 proxy resolves to implementation X
D2 token transfer can callback under condition Y
D3 oracle accepts/stays stale for window Z
D4 sequencer/finality permits ordering W
D5 bridge verifier accepts message M once
```

Label `PROVEN / SUPPORTED / ASSUMED / FALSE / UNKNOWN`. `FALSE` breaks the chain; security-critical `UNKNOWN` blocks a production-feasible verdict.

# 22. Mandatory Artifact

Maintain `DEPENDENCY_ASSUMPTIONS.md`:

```text
environment binding
claim ledger
source/spec evidence
minimal reproductions
version/config sensitivity
differential results
failure/finality semantics
variant leads
residual unknowns
```

# 23. Prohibited Drift

Do not default into generic database, HTTP, Kubernetes, browser, filesystem, desktop, or backend research. Those are relevant only if the concrete protocol delegates an on-chain security decision or transition to such a component. The burden is causal linkage to the on-chain property.

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
