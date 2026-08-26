# Oracles, L2, and Cross-Chain Systems

Load only when price/data feeds, ordering, rollup semantics, cross-domain
messages, bridges, or intents are causal to a protected property.

## Oracle dependency

Record source, quote/base units, decimals, heartbeat, deviation rules, update
authority, round completeness, staleness check, fallback hierarchy, TWAP
window, and accepted failure modes.

Test:

- stale-at-boundary, zero/negative/invalid rounds, decimal mismatch;
- primary/fallback disagreement and failure ordering;
- manipulable observation window vs available capital/liquidity;
- protocol state change between preview and consumption;
- sequencer downtime and recovery grace periods;
- missing or unsupported feeds on the target chain.

Do not assume a sequencer uptime feed exists on every L2. Verify current feed
support, initialization, update path, and what the protocol does when no feed
is available.

## Ordering and MEV

State the ordering capability precisely:

```text
public-mempool observation | priority bidding | bundle ordering
sequencer position | proposer/builder control | censorship/delay
ordinary same-block composition | unavailable/unknown
```

Model competition, failed bundles, gas/priority fees, private order flow,
sequencer policy, reorg/finality risk, and victim transaction dependence. Do
not silently grant arbitrary ordering.

## L2 state vector

“Finalized” is not one portable boolean. Track:

```text
sequencer/preconfirmation status
unsafe / safe / finalized L2 head
data-availability inclusion
L1 inclusion and finality
state-root/proposal status
challenge/proof status
message proven/finalized/executed status
escape or forced-inclusion availability
guardian/security-council intervention state
```

Bind the target rollup's timestamp/block semantics, deposits, withdrawals,
forced inclusion, proof/challenge periods, replay identifiers, reorg behavior,
and upgrade authority. “EVM-compatible” does not imply Ethereum L1 ordering or
finality.

## Bridge and cross-domain graph

Trace every security check and resource across:

```text
source state/effect
→ message construction and field binding
→ source authentication
→ proof, quorum, signer or verifier
→ relay/transport
→ destination messenger and caller mapping
→ replay/order/finality checks
→ destination effect
→ global accounting
```

Bind source/destination domains, sender/receiver, nonce/message ID, payload,
value/token mapping, fee, deadline, route, verifier version, and consumed
state. Compare the field authenticated on one side with the field consumed on
the other. A local check is ineffective if it protects a different identity or
representation.

Test duplicate, out-of-order, delayed, failed-then-retried, partial, cancelled,
reorged, fast-path/slow-path, and verifier-upgrade sequences. Define a global
invariant such as canonical escrow plus authorized remote supply covering all
outstanding claims.

Resource–check–effect graphs are useful for cross-chain review: trace the
resource that authorizes value, the exact check that guards it, and the effect
it reaches across every contract/domain boundary. This avoids flattening a
multi-stage message into one trusted edge.

## Intents and resolvers

Treat cross-chain intent standards as versioned and possibly draft semantics.
For ERC-7683-like systems bind order origin, fill instruction, settlement
contract, solver/resolver authorization, exclusivity, quote expiry, partial
fills, cancellation, replay, destination execution, and final settlement.

The exposure window spans creation through every possible fill, proof, refund,
and settlement transition. Verify that the party delivering destination value
cannot alter authenticated order fields or settle twice through heterogeneous
routes.

## Current semantic sources

Re-check current specifications and deployed implementations:

- Chainlink L2 sequencer feeds: https://docs.chain.link/data-feeds/l2-sequencer-feeds
- OP Stack finality: https://docs.optimism.io/op-stack/transactions/transaction-finality
- OP Stack withdrawal lifecycle: https://docs.optimism.io/op-stack/bridging/withdrawal-flow
- OP Stack runtime differences: https://docs.optimism.io/op-stack/protocol/differences
- ERC-7683 status and semantics: https://eips.ethereum.org/EIPS/eip-7683
