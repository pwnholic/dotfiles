# Runtime and Dependency Playbook

Load when a security claim depends on compiler/VM semantics, call context,
proxy/storage resolution, token/oracle/bridge behavior, L2/AA infrastructure,
RPC/client behavior, or another external component that is causal to an
on-chain transition.

## Escalation rule

State the dependency as a falsifiable claim:

```text
exploit edge
requires component identity/version/configuration
to exhibit semantic S
under context C
observable as O
```

Do not investigate unrelated infrastructure merely because it exists.

## Versioned semantic stack

Resolve claims against:

```text
chain and chain-id
fork/runtime feature activation
client/program/compiler version and code hash
executable spec/conformance test
deployed dependency/proxy/configuration
transaction/block/slot and call context
trace or minimal reproduction
```

An EIP/ERC status does not prove activation. A product name or ABI does not
prove semantic equivalence.

## Dependency claim ledger

For every external fact record:

```text
ID | required semantic | exact identity
expected observation | observed result
source/spec/test/trace | version/config sensitivity
PROVEN / SUPPORTED / ASSUMED / FALSE / UNKNOWN
exploit edges affected | freshness trigger
```

`FALSE` breaks dependent chains. A security-critical `UNKNOWN` prevents a
production-feasible verdict.

## Evidence resolution

Prefer target observation plus a reproducible trace, then executable
specifications/tests, normative specification, version-pinned official
implementation/docs, and finally research evidence. Preserve contradictions
and investigate fork, proxy, version, RPC, configuration, or context mismatch.

Build the smallest semantic reproduction that states:

```text
environment and version
input and call/instruction context
expected semantic
observed semantic
which exploit edge depends on it
```

Then re-integrate that fact into the full chain. Do not accidentally prove the
edge through test-only state or authority.

## Direct causal implementation inspection

When an exploit edge depends on implementation detail, inspect the exact
deployed executable and the corresponding versioned source when available.
Follow calls into the relevant runtime, framework, compiler, client, library,
precompile, proxy, external contract, bundler/relayer, or other dependency
until the causal semantic is resolved. Documentation, interface conformance,
package names, and mocks are not substitutes for implementation evidence.

Inspect a database, indexer, cache, API, or other off-chain component only when
its actual behavior can change an on-chain authorization, accepted
transaction/message, price, ordering/finality decision, deployment state, or
realizable impact. Bind its version/configuration and reproduce the causal
input-to-on-chain-effect path; do not broaden into a generic infrastructure
audit.

## Runtime branches

Load matching domain references rather than duplicating their rules:

- EVM call/proxy/transient/signature/AA/upgrade semantics:
  [../references/evm-accounts-upgrades.md](../references/evm-accounts-upgrades.md)
- oracle/L2/bridge/finality semantics:
  [../references/cross-chain-l2-oracles.md](../references/cross-chain-l2-oracles.md)
- SVM or Move semantics:
  [../references/svm-move.md](../references/svm-move.md)

For compilers and optimizers, reduce the suspected semantic delta, bind exact
flags/IR/target, compare generated code and runtime behavior, and determine
whether the target artifact actually contains it.

For encoding/signatures, bind raw bytes, schema, domain, chain, contract,
nonce, normalization, malleability rules, and the exact consumer. A library
call's name is weaker evidence than its versioned behavior.

For token or external-contract dependencies, inspect the deployed
implementation, proxy, configuration, and reachable callbacks. Interface
conformance is not a behavioral guarantee.

## RPC and operational actors

RPC is causal only when the protocol or validation relies on what it reports or
accepts. Distinguish simulation from execution, pending/latest/safe/finalized,
historical availability, traces, indexing delay, and client disagreement. One
RPC response does not override canonical state without reconciliation.

Sequencers, relayers, keepers, bundlers, and signers enter the model only when
they can control, influence, race, censor, delay, or enable an on-chain
transition. Separate protocol-enforced guarantees from operational convention
and model disappearance/failure paths.

## Differential tests

Use A/B execution when the claim assumes equivalence:

```text
compiler/optimizer A ↔ B
client/runtime A ↔ B
proxy ↔ implementation
old ↔ new implementation
L1 ↔ target L2
canonical ↔ supported token
EntryPoint/module A ↔ B
pre-upgrade ↔ post-upgrade
```

A divergence becomes security-relevant only when it reaches a protected
property.

## High-risk current semantics

- For ERC-4337 pin EntryPoint address, runtime code hash, release—including
  v0.9 where deployed—bundler validation rules, account, module, and paymaster.
  ABI compatibility is not semantic equivalence.
- For EIP-7702 test the delegated EOA, contracts interacting with it, and
  composite account/contract flows separately.
- For L2 use a finality state vector, not one boolean; verify sequencer-feed
  availability rather than assuming it.
- For SVM pin loader, effective slot, runtime feature set, and executable hash;
  a program upgrade may have a one-slot visibility boundary.
- For Move compilation targets, verify preservation of resource/capability
  semantics rather than inheriting source-language guarantees.

## Output and closure

Maintain `DEPENDENCY_ASSUMPTIONS` with the claim ledger, exact identities,
minimal reproductions, differential results, failure/finality semantics, and
unknowns.

Handoff:

```text
component/version | required and observed semantic | reproduction
source/spec evidence | chain/config sensitivity | affected edge | unknowns
```

Close only when every causal dependency is proven, falsified, or explicitly
left unresolved with the exploit verdict downgraded.

## Current semantic sources

- Ethereum execution specs/tests: https://github.com/ethereum/execution-specs
  and https://github.com/ethereum/execution-spec-tests
- EntryPoint releases: https://github.com/eth-infinitism/account-abstraction/releases
- OP Stack differences/finality: https://docs.optimism.io/op-stack/protocol/differences
- Chainlink sequencer feeds: https://docs.chain.link/data-feeds/l2-sequencer-feeds
- Solana program execution: https://solana.com/docs/core/programs/program-execution
- zkEVM verification case study: https://www.usenix.org/conference/usenixsecurity25/presentation/peng-xinghao
- Move-to-EVM case study: https://www.usenix.org/conference/usenixsecurity25/presentation/benetollo
