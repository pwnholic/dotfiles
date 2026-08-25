# Smart Contract and DeFi Playbook

Load for smart contracts, DeFi, cross-chain, bridges, governance, or on-chain economic systems.

## Think Beyond Single Functions

Model:

```text
contract state
+ cross-contract calls
+ external protocols
+ transaction ordering
+ chain semantics
+ economic incentives
```

## High-Value Dimensions

Use only as architecture-driven priors:

- authorization / roles;
- initialization / upgradeability;
- proxy / delegatecall / storage layout;
- accounting / rounding / share conversion;
- token hooks / fee-on-transfer / rebasing;
- oracle freshness/manipulation;
- callbacks / reentrancy;
- signatures / nonce / replay / domain separation;
- bridge/message provenance;
- async execution / retries;
- finality / reorg assumptions;
- governance / emergency controls;
- flash liquidity;
- liquidation and incentive mechanics;
- cross-protocol composition;
- cross-chain state synchronization.

## Economic Exploitability

Record:

- required capital;
- available liquidity;
- slippage/fees;
- transaction ordering requirements;
- price impact;
- liquidation/settlement constraints;
- whether profit or impact survives realistic execution costs.

A mathematically possible manipulation is not automatically economically exploitable.

## Cross-Chain

Track:

```text
source state
→ message construction
→ authentication/provenance
→ transport/relayer
→ destination validation
→ replay/order semantics
→ final state
```

Do not treat each chain-side contract as an isolated security boundary.

## Safe Validation

Prefer forks, local nodes, simulations, and testnets.

Do not execute against real funds or mainnet without explicit authorization for that action.
