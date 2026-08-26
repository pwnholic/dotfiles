# EVM Accounts, Execution, and Upgrades

Load only when EVM call context, signatures, delegated/smart accounts,
transient state, factories, governance, or upgradeability is causal.

## Call and state context

For each edge distinguish `call`, `staticcall`, `delegatecall`, creation,
fallback/receive, callback, and self-call. Track:

```text
msg.sender / msg.value / address(this)
code identity / storage owner
memory / returndata / revert propagation
reentrancy and lock domain
authorization context before and after the edge
```

Proxy safety requires binding dispatcher, implementation, admin/beacon/facets,
selector routing, storage ownership, initialization, and current on-chain
slots. Namespaced storage reduces some collisions but does not prove namespace
uniqueness, migration correctness, or historical layout compatibility.

Transient storage is transaction-scoped shared state for the executing
contract context, not ordinary memory. Check key collisions, nested calls,
delegatecall ownership, lock lifetime, multi-operation batches, and whether all
successful/reverting paths restore required state.

## Authorization and signatures

Separate signer validity from authorization validity. Bind:

- domain separator, chain ID, verifying contract, nonce/key, expiry;
- typed-data schema, encoding ambiguity, replay domain;
- contract signatures, counterfactual addresses, aggregators, modules;
- permit spender/value and approval persistence;
- revocation, key rotation, threshold, guardian, and recovery transitions;
- target and calldata binding for arbitrary execution.

Trace dormant authority: an old approval, signature, delegate, module, or
implementation may become exploitable only after code/configuration changes.

## EIP-7702 delegated EOAs

Only apply EIP-7702 semantics on chains where activated. Test three victim
classes separately:

1. the delegated EOA itself;
2. contracts that interact with an EOA whose code/behavior can change;
3. composite delegated-account, smart-account, module, and protocol flows.

Re-derive assumptions about `tx.origin == msg.sender`, `EXTCODESIZE == 0`,
construction, storage initialization, delegation replacement, nonce behavior,
authorization tuples, chain binding, and persistent storage. Search
initialization front-running, malicious delegation targets, migration errors,
storage reuse, approval inheritance, and authorization replay.

## ERC-4337

Trace the full path:

```text
UserOperation
→ bundler simulation/policy
→ EntryPoint validation
→ account and module validation
→ paymaster/aggregator validation
→ execution
→ postOp and settlement
```

Pin EntryPoint address, runtime code hash, release, account/module/paymaster
versions, and bundler rule set. ABI compatibility is not semantic equivalence.
Where v0.9 is deployed, account for its current UserOperation hash during
execution, parallelizable paymaster signatures, and EIP-7702-related behavior.
Keep bundler admission policy distinct from on-chain validity.

Test validation/execution state separation, nonce keys, prefund/deposit/stake,
simulation divergence, paymaster griefing, postOp failure, module install/
uninstall, signature aggregation, batched unrelated UserOperations, and
transaction-scoped state leakage between operations.

## Upgrades, initialization, governance, factories

For each upgrade or deployment transition bind:

```text
authority → delay/proposal → implementation artifact
→ storage interpretation → initializer/migration → active configuration
```

Search uninitialized implementation/proxy/clone, reinitializer omission or
reuse, constructor assumptions under delegatecall, UUPS authorization,
transparent-proxy selector behavior, beacon/facet divergence, rollback paths,
old-state/new-code interpretation, and one-chain deployment drift.

For factories and CREATE/CREATE2, deterministic address does not imply
deterministic behavior unless deployer, salt, init code, constructor values,
libraries, metamorphic/redeployment conditions, and post-deployment
initialization are bound.

Model governance/timelock predecessor, salt, delay, batching, cancellation,
emergency bypass, executor openness, and cross-chain execution. “Governance can
do it” identifies an authority path; it does not establish that the path is
intended, delayed, observable, or safe.

## Current semantic sources

Re-check activation and deployed versions:

- EIP-1153: https://eips.ethereum.org/EIPS/eip-1153
- EIP-7702: https://eips.ethereum.org/EIPS/eip-7702
- ERC-7201: https://eips.ethereum.org/EIPS/eip-7201
- ERC-4337: https://eips.ethereum.org/EIPS/eip-4337
- EntryPoint releases: https://github.com/eth-infinitism/account-abstraction/releases
- OpenZeppelin upgrade constraints: https://docs.openzeppelin.com/upgrades-plugins/writing-upgradeable
