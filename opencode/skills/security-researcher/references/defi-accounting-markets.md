# DeFi Accounting and Markets

Load only when the target contains tokens, vaults, pools, lending, staking,
derivatives, or another value-bearing market.

## Accounting model

Track assets, liabilities, claims, reserves, fees, debt, bad debt, pending
withdrawals, and external balances in explicit units. Derive conservation or
solvency relations independently from implementation formulas.

```text
assets_before + inflows - outflows - realized_losses
  ≈ assets_after + explicitly recognized liabilities

issued_claims × conservative_redemption_value
  ≤ realizable_backing under the stated exit model
```

For every conversion record input/output unit, decimal scale, rounding
direction, fee order, stale index risk, and who receives the rounding
remainder. Test repeated small operations: locally bounded rounding can become
an extraction loop.

## Token and approval semantics

Bind exact token implementations. Consider fee/rebasing/reflection behavior,
missing/false return values, callback-capable transfers, ERC-777-style hooks,
ERC-1363, ERC-20 vs Token-2022, wrappers, bridged variants, deny/freeze logic,
permit/domain/nonces, and decimals.

Exposure includes more than protocol-held balances:

```text
held assets
+ user allowances
+ permit/delegation authority
+ callback or hook reachability
+ upgrade/configuration authority over spenders
```

For each spender trace who can change its code, route calls through it, or
cause it to consume existing approvals. Dormant allowances and
attacker-controllable target selection can create impact far beyond TVL held by
the vulnerable contract.

## Vaults

For ERC-4626-like vaults test:

- first deposit, donation, inflation, dust, decimals offset;
- preview/quote vs actual execution under the same state;
- fee and loss ordering;
- totalAssets inclusion/exclusion and strategy debt;
- deposit/mint and withdraw/redeem rounding duality;
- queued exits, partial liquidity, emergency paths, and insolvency.

For ERC-7540 asynchronous vaults model
`Pending → Claimable → Claimed` independently for deposits and redemptions.
Preview functions may intentionally revert for asynchronous flows; do not
import synchronous ERC-4626 assumptions. Bind request controllers, operators,
claim ownership, request IDs, cancellation, partial fulfillment, and exchange
rate selection time.

For ERC-7575 multi-asset vaults, several asset entry points may share one share
token. Test global supply/backing across vault addresses, asset-specific
pricing, share-token authority, and cross-entry-point donation or loss.

## AMMs, hooks, and temporary accounting

Do not assume a constant-product invariant. Derive the implemented curve and
settlement rules. Test:

- spot vs TWAP vs external-oracle dependencies;
- boundary ticks/prices, fee growth, liquidity activation, and rounding;
- flash liquidity and same-transaction reserve observations;
- hook permissions, callback identity, nested calls, and lock scope;
- temporary deltas that must net to zero before unlock;
- fee-on-transfer/rebasing tokens and balance-vs-accounting divergence.

For hook-based or deferred-settlement systems, map the whole transaction:
`lock → actions/hooks → temporary deltas → settle/take → unlock invariant`.

## Lending and liquidation

Bind collateral/debt units, index timing, oracle freshness, caps, isolation
modes, e-mode correlations, liquidation close factor, bonus, protocol fee, and
bad-debt recognition. A liquidation is safe only if it can actually execute
with available liquidity, gas/compute, slippage, competition, and settlement
timing.

Search:

- threshold ±1 and index/price update ordering;
- self-liquidation or collateral cycling;
- partial liquidation that worsens solvency;
- thin-liquidity oracle manipulation;
- borrow/repay rounding loops;
- liquidation paths blocked exactly during stress;
- bad debt hidden by stale or optimistic valuation.

## Stablecoins, derivatives, staking

For stablecoins separate redemption backing, market peg, oracle accounting,
and governance/custody assumptions. For derivatives bind mark/index prices,
funding, margin, settlement, expiry, ADL/socialized-loss rules, and profitable
unwind. For staking/restaking bind reward indices, slash timing, delegation,
queued withdrawals, validator/operator authority, and cross-system claim
priority.

## Economic feasibility

Keep feasibility and profit as separate objectives:

```text
feasible = legal transitions + available capital/liquidity + timing/finality
profit = realized proceeds - capital cost - fees - gas - slippage
         - competition - unwind loss - attacker loss at risk
```

Optimize over capital, repetitions, route, timing, and market depth. Report
the feasible region and sensitivity, not one favorable point.

## Current research leads

Re-check status and target adoption before use:

- ERC-4626: https://eips.ethereum.org/EIPS/eip-4626
- ERC-7540 asynchronous vaults: https://eips.ethereum.org/EIPS/eip-7540
- ERC-7575 multi-asset vaults: https://eips.ethereum.org/EIPS/eip-7575
- Profit-centric fuzzing (VERITE): https://arxiv.org/abs/2501.08834
