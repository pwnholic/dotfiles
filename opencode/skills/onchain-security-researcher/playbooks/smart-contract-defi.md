# Smart-Contract and DeFi Domain Backbone

Load for a non-trivial on-chain security engagement. This playbook selects the
relevant domain model; it is not a checklist to apply mechanically.

## 1. Execution reality

Start from the exact system:

```text
source/specification
→ build/runtime semantics
→ deployed executable and proxy/program topology
→ initialized state, configuration and authority
→ reachable calls/instructions/messages
→ external protocols, markets and infrastructure
→ temporal/economic constraints
→ security property and impact
```

Bind target identity in the control plane. Escalate mismatches to
`supply-chain.md`, configuration interactions to `configuration-space.md`,
and causal external semantics to `runtime-dependency.md`.

## 2. Security graph

Construct four connected views:

1. **authority graph** — roles, signers, modules, admins, delegates, PDAs,
   capabilities, upgrades, and emergency paths;
2. **state graph** — lifecycle phases, storage owners, cross-contract state,
   pending/claimable/finalized states, and historical interpretation;
3. **value graph** — balances, liabilities, approvals, claims, collateral,
   debt, reserves, fees, and external liquidity;
4. **message/call graph** — calls, delegatecalls, callbacks/hooks, CPI,
   relays, verification, retries, and destination effects.

Mark each edge with actor, checked identity, resource authorized, state/value
delta, dependency, timing, and evidence. Search where a check guards a
different identity or representation than the effect consumes.

## 3. Property families

Derive target-specific invariants from protected claims:

```text
unauthorized actors cannot move assets or increase privilege
claims remain backed under the defined exit/settlement model
accounting conserves value across legal transitions
nonces/messages/effects cannot be consumed twice
prices are accepted only under explicit validity conditions
upgrades preserve storage, authority and required lifecycle state
cross-domain supply and settlement remain globally coherent
users retain intended exit/recovery paths
```

Do not derive the expected result solely from the implementation being tested.

## 4. Architecture-driven surface

Select dimensions with causal leverage:

| Architecture signal                     | Research surface                                                  |
| --------------------------------------- | ----------------------------------------------------------------- |
| proxy, clone, facets, upgrade authority | initialization, selector routing, storage history, migration      |
| tokens, shares, debt, indices           | units, rounding, conservation, approvals, insolvency              |
| callbacks, hooks, external execution    | reentrancy, identity, locks, deferred settlement                  |
| signatures, permits, modules            | domain/nonce/replay, dormant authority, arbitrary target binding  |
| delegated/smart accounts                | EIP-7702, EntryPoint/version, bundler/paymaster, batch state      |
| oracle-dependent market                 | freshness, decimals, fallback, manipulation, sequencer recovery   |
| pools, lending, vaults, derivatives     | economic state transitions and realizable liquidation/exit        |
| bridge/L2/intents                       | source identity, proof/finality, replay, retry, global accounting |
| Solana/SVM                              | account owner/signer/PDA/CPI, loader, Token-2022                  |
| Move/object system                      | resource/capability authority, object state, upgrade/translation  |
| factory/configurable markets            | unsafe tuples, address trust, governance/factory reachability     |

Retain a light baseline for simple local authorization, arithmetic, unchecked
return, initialization, and call-order mistakes even on advanced targets.

## 5. Conditional deep references

Load only what the architecture needs:

- token/accounting, vaults, AMMs, lending, staking, derivatives:
  [../references/defi-accounting-markets.md](../references/defi-accounting-markets.md)
- EVM calls, transient state, signatures, EIP-7702, ERC-4337, upgrades:
  [../references/evm-accounts-upgrades.md](../references/evm-accounts-upgrades.md)
- oracle, MEV, L2, bridge, cross-chain and intent semantics:
  [../references/cross-chain-l2-oracles.md](../references/cross-chain-l2-oracles.md)
- Solana/SVM or Move/object-capability systems:
  [../references/svm-move.md](../references/svm-move.md)

Loading this backbone does not imply loading all four.

## 6. State-machine search

For every high-value lifecycle identify states, legal transitions, actor,
precondition, external call, failure/retry behavior, and newly created
capability. Mutate:

```text
order | repetition | omission | partial completion | callback insertion
same-transaction batching | multi-block preparation | stale/fresh boundary
pause/unpause | upgrade/migration | first/last user | empty/depleted state
epoch/expiry/finality | duplicate/out-of-order/retried delivery
```

Distinguish transient, transaction-persistent, block/slot-persistent,
cross-domain pending, and durable state. A sequence that only works because the
harness preserves an impossible intermediate state is not constructively
reachable.

## 7. Attacker and authority positions

Avoid one generic attacker. Consider, when architectural:

```text
ordinary user | LP/borrower/liquidator | callback contract
permissionless keeper/executor | flash-capital actor | ordering actor
delegated/smart account | solver/relayer/bundler
market/factory creator | compromised signer/operator | governance actor
```

For privileged positions separate intended authority, accidental excess,
compromise assumption, delay, observability, blast radius, and whether a
permissionless path can induce the privileged effect.

## 8. Composition and economics

Local correctness does not prove composed safety. Trace value and authority
through adapters, routers, hooks, strategies, wrappers, oracles, bridges,
messengers, account modules, and external liquidity.

For value-bearing claims model:

```text
capital and collateral | borrow/flash liquidity | fees and gas/compute
slippage and price impact | oracle window | ordering competition
state lifetime | repetitions | unwind risk | realizable proceeds/loss
```

Distinguish:

```text
mathematical discrepancy
→ executable value path
→ feasible capital/time/order region
→ attacker net gain or protocol realized loss
```

## 9. Production-state and blast radius

Inspect balances, approvals, roles, implementations, active markets, queues,
oracle state, liquidity, and historical configuration at a pinned block/slot.
Document archive-node, indexing, simulation, and fork limitations.

Blast radius includes:

- assets directly held;
- claims and debt whose value changes;
- user allowances/permits/delegations;
- sibling markets, chains, proxies, facets and legacy deployments;
- external protocols consuming corrupted price/state;
- governance, upgrade, bridge, or solver authority exposed.

Do not use current TVL alone as the impact ceiling.

## 10. Method selection

Choose the cheapest method that discriminates the active uncertainty:

- static/state-write/call graph for identity and flow;
- traces and state diffs for executed semantics;
- stateful/differential/metamorphic fuzzing for sequences and relations;
- symbolic/formal methods for narrow high-value properties;
- historical replay for old state/new code and incident windows;
- economic simulation for feasible extraction and sensitivity.

Route generator/oracle design to `fuzzing-oracles.md`; discovery portfolio to
`hypothesis-search.md`; hardened assurance differentials to
`hardened-target.md`.

## 11. Promotion and handoff

Do not promote a primitive until it has:

```text
property and protected claim
attacker capability provenance
constructive state path
precise mechanism
causal dependencies
candidate full chain
observable success predicate
initial production/economic relevance
strongest known blocker
```

Then use `exploit-validation.md`. After a root cause exists, use
`variant-analysis.md` for semantic siblings and patch completeness.

## 12. Coverage-bounded output

Report the architecture modeled, property families, attacker positions,
transitions/configurations/deployments exercised, dependencies resolved,
confirmed and blocked hypotheses, and residual blind spots. Do not claim
security from a quiet tool or from exhaustive review of only the source layer.
