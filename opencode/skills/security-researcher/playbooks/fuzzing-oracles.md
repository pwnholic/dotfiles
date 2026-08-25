# Smart-Contract Fuzzing and Oracle Design Playbook

Load for property-based, invariant, stateful, differential, metamorphic, fork-based, or economic fuzzing of smart contracts and on-chain protocols.

## Smart-Contract Scope Lock

This playbook belongs to a **smart-contract / DeFi security research stack**. Apply it to on-chain programs, protocols, token systems, vaults, AMMs, lending, staking/restaking, governance, account abstraction, bridges, rollups/L2s, cross-chain systems, and infrastructure only when that infrastructure is causally necessary to an on-chain security property.

Do **not** expand the default search into generic web/backend/database/desktop/cloud security. An off-chain component belongs here only when compromising or mis-modeling it can change an on-chain authorization decision, state transition, message provenance, price, ordering/finality assumption, upgrade/deployment state, or realizable economic impact.

When a concrete exploit hypothesis exists, hand validation to `exploit-validation.md`.

# 1. Fuzzing Doctrine

Smart-contract fuzzing is a search over **reachable state transitions** evaluated by security oracles. A clean campaign means only that the selected generators, sequences, environment, and properties did not expose a violation.

```text
useful fuzzing = reachable generator × state depth × composition × strong oracle × reproducible failure
```

Do not optimize for raw executions before checking whether the harness can reach the security-relevant state.

# 2. Derive Oracles From Security Properties

Prefer properties that would remain meaningful if implementation details changed. Families include:

- conservation of assets/shares/debt/supply;
- solvency and collateralization;
- authorization / privilege non-escalation;
- replay/nonce/message uniqueness;
- state-machine legality;
- monotonic indices/checkpoints where required;
- preview/quote/execution consistency;
- bounded rounding loss;
- no value creation by pure cycling;
- bridge source/destination supply consistency;
- governance execution only after required state/delay;
- upgrade state compatibility;
- withdrawal/liveness reachability;
- oracle freshness and bounded-use rules;
- account/PDA ownership and signer invariants on SVM.

# 3. Oracle Taxonomy

Use multiple oracle classes where useful:

```text
INVARIANT           property after arbitrary legal sequences
POSTCONDITION       property after one transition
DIFFERENTIAL        two implementations/configs should agree
METAMORPHIC         transformed input/sequence should preserve a relation
REFERENCE_MODEL     implementation vs independent model
ECONOMIC_OBJECTIVE  maximize attacker value / protocol loss / insolvency
TEMPORAL             property across block/slot/time progression
CROSS-DOMAIN         source/destination accounting or message relation
LIVENESS             reachable exit/settlement/recovery condition
```

# 4. Oracle Independence

Do not copy the production formula into the test and call equality a proof. Derive expected behavior independently from:

- protocol-level conservation laws;
- economic definitions;
- specification;
- simplified reference model;
- alternate implementation;
- externally observable balance/state relation.

If the oracle and target share the same bug, fuzzing can certify the defect.

# 5. Validate the Oracle

Attack the harness before trusting it.

Required questions:

- Can the oracle detect a deliberately broken authorization check?
- Can it detect wrong rounding direction?
- Can it detect missing oracle freshness validation?
- Can it detect duplicate bridge/message consumption?
- Can it detect a skipped accounting update?
- Does it fail if a known-bad historical behavior is reintroduced?

Use mutation testing, negative controls, and known-invalid safe fixtures. A security mutation that survives proves an oracle blind spot.

# 6. Stateful Sequence Design

Stateful is the default for protocols whose risk depends on history. Generate sequences around lifecycle transitions, not only random ABI calls.

Examples:

```text
deposit → donate → mint → redeem
borrow → price move → partial liquidate → repay
queue withdrawal → loss → finalize
create proposal → vote → queue → upgrade → execute
bridge send → delay → retry → finalize
permit/delegate → transfer → revoke → replay
initialize → upgrade → reinitialize → legacy call
```

Foundry invariant testing and Medusa/Echidna all expose sequence depth as a meaningful search dimension; insufficient depth is a coverage limitation, not evidence of safety.

# 7. Handler Design

Handlers should encode **attacker-achievable transitions**, not idealized happy paths. Track ghost state for what the actor contributed, borrowed, received, repaid, minted, burned, or caused the protocol to owe.

Avoid over-constraining handlers until the campaign cannot reach invalid-but-real states. Every `assume`, bound, selector exclusion, sender restriction, and precondition can remove an exploit path.

# 8. Sender and Capability Modeling

Fuzz multiple roles intentionally:

```text
ordinary user
liquidity provider
borrower
liquidator
keeper/permissionless executor
malicious callback contract
delegated EOA / smart account
relayer/bundler where protocol-visible
privileged actor only when testing privilege abuse separately
```

Do not use privileged prank/impersonation to prove an unprivileged exploit.

# 9. State and Value Generation

Bias toward semantic boundaries:

- zero / one / dust;
- first depositor / last withdrawer;
- empty or near-empty vault;
- exact collateral/liquidation thresholds ±1;
- min/max ticks and price boundaries;
- unusual decimals;
- stale-at-boundary oracle timestamps;
- cap saturation;
- epoch/round boundaries;
- near-overflow realistic accumulators;
- loss/depeg states;
- repeated rounding cycles;
- thin-liquidity and imbalanced pools.

Mine protocol constants and deployed parameters, not only language integer boundaries.

# 10. Composition-Aware Fuzzing

Include reachable external contracts that materially change callbacks or economics. Useful targets include:

- real token variants;
- vault adapters;
- DEX pools / hooks;
- oracle wrappers;
- bridge messengers/verifiers;
- account-abstraction EntryPoint/modules;
- proxy + implementation combinations.

When using mocks, document which semantics are preserved and which attack surfaces disappear.

# 11. Fork and Production-State Fuzzing

Use forked state when current balances, liquidity, approvals, roles, oracle config, or external protocol state are necessary. Pin the fork to a reproducible block/transaction boundary.

Never confuse a fork with full production realism: mempool ordering, sequencer behavior, external keeper actions, bridge finality, and future blocks may still be simplified.

# 12. Differential Testing

Compare states or outputs that should be equivalent:

```text
old ↔ new implementation
preview ↔ execution
reference math ↔ optimized math
direct call ↔ proxy call
canonical token ↔ supported wrapper
L1 adapter ↔ L2 adapter
legacy account ↔ delegated account where property should hold
model ↔ protocol
```

Investigate every unexpected semantic delta before suppressing it.

# 13. Metamorphic Relations

Useful relations include:

- split deposit vs combined deposit;
- repeated small operations vs one aggregate operation;
- deposit then withdraw round trip should not create attacker value beyond defined fees;
- reordering independent users should preserve aggregate accounting where intended;
- adding unrelated liquidity should not change authorization;
- equivalent signature/domain encodings should either both be rejected or both bind the same authority as specified;
- retry of an already-consumed message should not create a second effect.

Metamorphic tests are powerful when an exact expected numeric output is difficult to model.

# 14. Economic Oracles

For financial protocols track objectives, not only booleans:

```text
attacker_net_value
protocol_equity
bad_debt
unbacked_supply
share_price_drift
cumulative_rounding_extraction
liquidator_profit
value_locked_in_unexit-able_state
```

Maximization/optimization harnesses can identify economically interesting sequences even before a crisp invariant is known. Validate any discovered profit with `exploit-validation.md`.

# 15. Temporal and Ordering Fuzzing

Vary block/slot/timestamp progression within chain rules. Search:

- same-block composition;
- multi-block preparation;
- oracle heartbeat boundaries;
- cooldown/epoch transitions;
- governance delays;
- withdrawal challenge windows;
- sequencer-down / recovery grace periods;
- bridge retry/finality states.

Do not let the harness jump time into a state that cannot be reached while preserving required market/dependency state.

# 16. Revert Semantics

A revert is not automatically “safe.” Track whether reverted calls:

- consume sequence depth and starve exploration;
- hide a reachable partial effect in an external component;
- indicate an over-constrained handler;
- create liveness/griefing impact;
- prevent a required cleanup/finalization path.

Foundry exposes call metrics; use them to identify handlers that mostly revert and therefore provide poor search coverage.

# 17. Coverage That Matters

Track more than line coverage:

```text
entrypoints reached
state transitions reached
role/caller classes reached
callback edges reached
proxy/implementation variants reached
market/token/oracle configurations reached
sequence depths reached
critical branches / error paths reached
economic boundary states reached
```

Coverage is search telemetry. It is never the oracle.

# 18. Corpus and Counterexample Quality

Preserve sequences that increase semantic coverage, not only code coverage. For failures:

1. save the original sequence and environment;
2. shrink while preserving the same root mechanism;
3. verify the shrinker did not replace a real precondition with harness magic;
4. replay deterministically;
5. export the minimal chain to `exploit-validation.md`.

# 19. Cross-Tool Confirmation

When stakes are high, use tool diversity to expose harness-specific blind spots:

- Foundry invariant/fork testing;
- Echidna;
- Medusa;
- symbolic/model tools where appropriate;
- manual state-transition replay.

Agreement is useful only if the tools do not share the same flawed oracle or synthetic assumptions.

# 20. SVM / Non-EVM Branch

For Solana/SVM fuzzing, model instruction account lists, ownership, signer/writable flags, PDA derivation, CPI targets, Token vs Token-2022 behavior, compute budget, and upgrade authority. Do not translate EVM `msg.sender`/storage/reentrancy assumptions mechanically.

For Move/object runtimes, derive generators and invariants from ownership, capabilities, object versions, shared-object access, and package-upgrade semantics.

# 21. Campaign Record

Maintain `FUZZ_CAMPAIGN.md` with:

```text
target revision / deployment snapshot
tool + version
compiler/runtime config
contracts/programs and selectors targeted
senders/actors
sequence depth / runs / timeout
state/time generation rules
assumptions and exclusions
invariants/oracles
mutation/negative-control results
coverage dimensions
corpus reuse
failures and minimized repros
blind spots / residual uncertainty
```

# 22. Fuzzing Closure

A campaign is not closed because it ran for hours. Close only when critical properties have meaningful oracles, relevant state/role/configuration dimensions were reached, the oracle survived mutation/negative controls, important failures were minimized and replayed, and remaining blind spots are explicit.

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
