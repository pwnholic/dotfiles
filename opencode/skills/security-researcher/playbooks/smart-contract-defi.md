# Smart Contract and DeFi Research Playbook

## Stack Role

This is the domain backbone for the smart-contract research stack. Other playbooks may specialize search, validation, fuzzing, configuration, runtime, supply-chain, variant, or multi-agent behavior, but they must not broaden the default domain beyond smart contracts / DeFi.

Load for smart contracts, DeFi, on-chain markets, vaults, lending, AMMs, staking/restaking, stablecoins, derivatives, governance, account-abstraction systems, bridges, rollups, cross-chain applications, and other systems whose security depends on blockchain execution or economic state.

This is not a generic Solidity checklist.

Its job is to force research across the **actual execution system**:

```text
contract/program logic
+ persistent state
+ transaction semantics
+ cross-program composition
+ assets and liabilities
+ market state
+ oracle state
+ ordering / inclusion
+ governance / upgrades
+ chain runtime
+ cross-chain messaging
+ off-chain actors
+ production configuration
```

Use architecture to select relevant sections. Do not mechanically enumerate every item against every target.

When a concrete exploit hypothesis exists, route validation through `exploit-validation.md` rather than weakening the exploitability standard inside this playbook.

---

# 0. Core Doctrine

A DeFi system is not a collection of isolated functions.

Model it as a **state-transition and value-transfer network** exposed to adversarial composition.

The primary research question is:

> Which sequence of actions available to a realistic actor can make assets, liabilities, authority, messages, prices, or claims diverge from the security properties the system intends to preserve?

Use:

```text
protected property
+ attacker capability
+ reachable state
+ transaction / message sequence
+ external dependency behavior
+ economic condition
→ security-relevant violation
```

Do not assume that:

- a call is harmless because its local function is correct;
- a token behaves like the reference ERC-20 implementation;
- an EOA has no code or cannot be called like a contract;
- `tx.origin == msg.sender` means “top-level EOA only” on modern Ethereum;
- a callback can only occur through the obvious external call;
- a price is safe because it came from an oracle contract;
- an oracle is usable because its latest value is non-zero;
- a bridge message is safe because the destination contract authenticated the messenger address;
- L2 execution has L1 ordering, liveness, or finality semantics;
- a mathematical profit exists in executable market conditions;
- the current proxy implementation is the only reachable implementation;
- governance, relayers, keepers, bundlers, paymasters, signers, frontends, or operators are outside the attack surface merely because their code lives outside the repository.

For mature targets, pair this playbook with `hardened-target.md`.

---

# 1. Bind the Target to an Execution Reality

Before deep research, establish what actually executes.

Record:

```text
CHAIN / VM
  chain id / network id
  execution environment
  relevant hardfork / runtime feature set
  consensus / finality model
  block / slot model

DEPLOYMENT
  addresses / program ids
  proxy / implementation / beacon relations
  deployment block / slot
  initialized configuration
  active roles
  supported assets / markets

BUILD
  source revision
  compiler
  optimization / IR settings
  linked libraries
  runtime / framework versions

DEPENDENCIES
  token implementations
  oracle contracts
  AMMs / lending protocols
  bridges / messaging layers
  keepers / relayers
  sequencers / bundlers / paymasters
  off-chain signers / services
```

A security claim about source code is insufficient when production behavior depends on a different runtime, deployment, configuration, dependency, or upgrade state.

## 1.1 Runtime feature activation matters

Do not reason from language syntax alone.

Determine which protocol features are active on the target chain.

Examples of semantics that may materially change security reasoning include:

- EVM hardfork-specific opcode behavior;
- EIP-7702 delegated EOAs;
- transient storage (`TLOAD` / `TSTORE`);
- post-Cancun `SELFDESTRUCT` behavior;
- chain-specific precompiles;
- L2-specific system contracts / predeploys;
- alternative gas metering;
- transaction type support;
- native account abstraction;
- runtime feature gates;
- Solana SIMD/runtime changes;
- chain-specific token programs;
- Move VM object / capability semantics.

Do not infer semantics from “EVM-compatible” or “Solana-compatible” alone.

Produce or update `CHAIN_RUNTIME.md` when runtime behavior is security-relevant.

---

# 2. Build the On-Chain Security Graph

Construct a graph before attempting broad vulnerability enumeration.

Nodes should include, where relevant:

- user entrypoints;
- privileged entrypoints;
- routers;
- vaults;
- market contracts;
- pools;
- hooks;
- callbacks;
- adapters;
- token contracts;
- price sources;
- bridge endpoints;
- governance executors;
- timelocks;
- proxies / implementations;
- factories;
- settlement components;
- off-chain signers;
- keepers;
- relayers;
- sequencers;
- bundlers / EntryPoints / paymasters;
- external protocols;
- L1/L2 messengers;
- cross-chain verifier sets.

Edges should include more than calls:

```text
CALL
DELEGATECALL / equivalent delegated execution
CPI / cross-program invocation
TOKEN FLOW
SHARE / CLAIM FLOW
DEBT FLOW
PRICE DEPENDENCY
ROLE / AUTHORITY TRANSITION
UPGRADE CONTROL
MESSAGE FLOW
STATE READ DEPENDENCY
STATE WRITE DEPENDENCY
ORDERING DEPENDENCY
OFF-CHAIN ATTESTATION
```

Prioritize high-fan-in and high-fan-out nodes.

A small conversion helper used by every market may be more security-critical than a large standalone contract.

---

# 3. Asset, Liability, Claim, and Authority Map

Do not model only balances.

Track all security-relevant economic objects:

```text
assets
shares
LP positions
collateral
principal
accrued interest
fees
protocol reserves
debt
bad debt
pending withdrawals
claim tickets
escrowed funds
reward entitlements
bridged representations
mint / burn authority
oracle authority
governance voting power
upgrade authority
operator authority
```

For each object answer:

- who creates it?
- who can destroy it?
- who can transfer it?
- which state determines its value?
- which external system can change that state?
- what must remain conserved?
- what can be delayed?
- what can be duplicated?
- what can become stale?
- what can become unbacked?

## 3.1 Conservation laws

Derive explicit conservation properties where applicable.

Examples:

```text
total claims <= realizable backing

minted cross-chain representation
<=
assets escrowed or canonically burned on source

withdrawable assets
<=
liquid assets + realizable receivables

user debt + protocol bad debt
≈
borrowed principal + accrued interest - repayments
```

Treat unexplained drift as a research seed.

---

# 4. Attacker Position Matrix

Do not use one generic “attacker”.

Model realistic starting positions separately.

Possible positions include:

- arbitrary externally owned account;
- smart contract caller;
- callback-capable contract;
- normal depositor;
- borrower;
- lender;
- LP;
- liquidator;
- trader;
- validator / builder / searcher position where relevant;
- keeper competitor;
- governance participant;
- token holder;
- bridge user;
- message recipient;
- account-abstraction user;
- bundler;
- paymaster client;
- relayer client;
- Solana program caller supplying arbitrary accounts;
- malicious token / market integration;
- compromised actor assumption only when explicitly part of the hypothesis.

For every hypothesis separate:

```text
attacker-controlled
attacker-influenced
third-party-controlled
protocol-controlled
chain-controlled
unavailable
```

Do not silently grant privileged roles because test tooling can impersonate them.

---

# 5. State-Machine Research

Many DeFi failures are sequence failures.

Enumerate lifecycle states and transitions.

Examples:

```text
uninitialized → initialized → active → paused → resumed → upgraded

empty vault → first deposit → active vault → loss state → depleted vault

healthy loan → near threshold → liquidatable → partially liquidated → bad debt

message created → observed → proven → queued → relayed → failed → retried → finalized

proposal → voting → queued → executable → executed / canceled / expired
```

For every transition record:

- caller authority;
- state read;
- state written;
- external interaction;
- value moved;
- temporal condition;
- ordering condition;
- reversible vs irreversible effect;
- sibling transitions that touch the same state.

Search for:

- skipped transitions;
- duplicate transitions;
- stale-state transitions;
- partial transitions;
- retry after partial side effect;
- cancellation races;
- reordering;
- repeated application;
- first-user / last-user boundaries;
- pause / unpause boundaries;
- upgrade boundaries;
- epoch / round boundaries;
- zero-liquidity / depleted states.

---

# 6. Accounting and Numerical Semantics

Never reduce numerical review to overflow checks.

Model units and directionality.

For each critical quantity record:

```text
semantic unit
storage scale
external scale
rounding direction
conversion path
source of precision
maximum realistic magnitude
minimum meaningful magnitude
```

Research:

- asset/share conversion;
- decimal mismatches;
- fixed-point scale mismatch;
- rounding direction;
- truncation;
- accumulated dust;
- repeated rounding amplification;
- fee ordering;
- interest-index drift;
- debt-share conversion;
- donation effects;
- virtual shares/assets;
- rebasing effects;
- loss socialization;
- partial liquidation rounding;
- extreme utilization;
- negative or signed-value boundaries where supported;
- stale cached totals;
- asynchronous accounting windows.

## 6.1 Rounding is an economic transfer

For every division ask:

> Who receives the rounding residual?

Then test whether repetition, leverage, batching, or composition amplifies it.

A one-unit local error can become economically meaningful when the same actor can repeat the transition cheaply.

## 6.2 Preview / quote / execute consistency

Where systems expose preview or quote functions, compare them to execution.

Check:

```text
previewDeposit ↔ deposit
previewMint ↔ mint
previewWithdraw ↔ withdraw
previewRedeem ↔ redeem
quote ↔ swap
expected collateral ↔ actual collateral
simulation ↔ execution
```

Divergence may create slippage, accounting, or integration vulnerabilities even if each function is locally correct.

---

# 7. Token Semantics Matrix

Never assume “ERC-20” means one behavior.

For each supported or reachable token class determine whether the system safely handles:

- no-return-value transfers;
- false-return transfers;
- fee-on-transfer;
- rebasing;
- callback / hook-enabled transfers;
- transfer restrictions;
- blacklists / freezes;
- pausable transfers;
- mintable supply;
- burn-on-transfer;
- unusual decimals;
- changing decimals or metadata where possible;
- permit / signature authorization;
- approval race behavior;
- ERC-777 style callbacks;
- ERC-1363 style callbacks;
- ERC-4626 share tokens;
- ERC-6909 / multi-token accounting where relevant;
- native wrapped assets;
- token wrappers with separate accounting;
- Solana Token Program vs Token-2022 extension behavior;
- bridged token variants.

For every integration ask:

```text
expected amount
vs
actual balance delta
```

Balance-delta reasoning often reveals assumptions hidden by trusting function parameters or return values.

---

# 8. Vaults, ERC-4626, and Asynchronous Vault Semantics

For tokenized vaults derive explicit share-price properties.

Track:

```text
totalAssets
totalSupply
share price
pending assets
pending shares
realized losses
unrealized gains
fees
virtual assets / shares
external strategy debt
```

Research:

- empty-vault behavior;
- first depositor;
- direct donations;
- share inflation;
- loss before first / last exit;
- rounding asymmetry;
- fee effects;
- stale strategy valuation;
- asset recovery functions;
- share-token transfer effects;
- strategy debt limits;
- withdraw queues;
- asynchronous deposit / redemption requests;
- request cancellation / replay;
- claim ownership changes;
- preview-function assumptions in asynchronous systems;
- interactions between pending accounting and callback-capable assets.

OpenZeppelin's current ERC-4626 guidance explicitly treats empty/nearly-empty vault share inflation as a security concern and uses virtual assets/shares plus configurable decimal offset as a mitigation. Treat inherited implementations as evidence—not a substitute for checking overrides and composition.

---

# 9. External Calls, Callbacks, Hooks, and Reentrancy

Reentrancy is a state-consistency problem, not an opcode keyword.

Map every point where control leaves the trusted component while a security-relevant invariant is temporarily false.

Include:

- token transfers;
- receiver hooks;
- arbitrary callbacks;
- DEX callbacks;
- flash-loan callbacks;
- bridge callbacks;
- hooks attached to pools;
- fallback / receive functions;
- delegated execution;
- account-abstraction execution;
- Solana CPI;
- external strategy calls.

Classify:

```text
same-function reentrancy
cross-function reentrancy
cross-contract reentrancy
read-only reentrancy
callback-state manipulation
hook-induced state transition
```

Ask:

- which invariant is temporarily broken?
- which other entrypoint observes the intermediate state?
- can the callback change price, balance, debt, shares, or authority?
- can the callback enter through a sibling contract rather than the original one?
- does the guard cover all state coupled to the operation?

## 9.1 Hook-based protocols

Modern protocols may deliberately expose lifecycle interception points.

For hook-enabled systems map:

```text
hook selection / registration
hook permissions
before-* state
hook call
hook-returned data / deltas
after-* state
settlement
```

Uniswap v4, for example, permits external hook contracts at initialization, liquidity modification, swap, and donation lifecycle points. Treat hook behavior as part of the pool's security model, not an accessory integration.

## 9.2 Flash accounting / deferred settlement

When accounting permits temporary imbalance within a transaction, derive the **end-of-transaction settlement invariant** and all ways control can move before it is checked.

Research:

- temporary debt / credit deltas;
- nested locks / unlocks;
- callbacks during unsettled state;
- transient-storage lifetime;
- multi-pool netting;
- hook-returned deltas;
- token settlement order;
- revert behavior;
- assumptions about who can reenter within the same transaction.

---

# 10. Transient Storage and Transaction-Scoped State

On EVMs supporting EIP-1153, transient storage survives across call frames for the owning contract during the transaction and is cleared only at transaction end.

Do not model it as memory.

Review:

- lock lifetime;
- cleanup assumptions;
- nested invocation behavior;
- delegatecall ownership semantics;
- revert semantics;
- same-transaction repeated calls;
- reentrancy guards implemented with transient storage;
- transient approvals / temporary authorization;
- collisions between libraries or delegated implementations.

A lock that is intentionally left set after one call may block or distort a later call in the same transaction even though persistent storage is untouched.

---

# 11. Authorization, Signatures, Permits, and Delegation

For every privileged effect derive the entire authorization chain.

```text
identity
→ signed / asserted intent
→ domain binding
→ nonce / replay protection
→ validation
→ authority resolution
→ effect
```

Research:

- signer identity;
- chain ID binding;
- verifying-contract binding;
- nonce scope;
- deadline semantics;
- replay across chains;
- replay across contracts;
- replay across versions;
- replay after cancellation;
- EIP-712 domain changes;
- EIP-1271 contract-signature behavior;
- counterfactual / undeployed account signatures where relevant;
- permit scope;
- spender confusion;
- target / calldata binding;
- value / gas binding;
- signature malleability assumptions;
- signer rotation;
- session keys;
- delegated authorization;
- permit routers / approval managers.

Never equate “valid signature” with “valid authorization”.

The signature must bind every field whose alteration would change the security meaning of the action.

---

# 12. EIP-7702 Delegated EOAs

On networks with EIP-7702, do not preserve legacy assumptions that an EOA is permanently code-less or only acts as the outer transaction sender.

EIP-7702 explicitly changes several old invariants.

Research:

- delegation target authorization;
- replay protection;
- chain binding;
- initialization ordering;
- front-running of initial delegated state;
- storage layout across delegation changes;
- migration between delegate implementations;
- arbitrary target / calldata authorization;
- value and gas binding;
- revocation / replacement behavior;
- interactions with `tx.origin` assumptions;
- interactions with codehash / code-existence checks;
- relayer griefing;
- pending-transaction invalidation;
- delegated account balance movement;
- compatibility with protocols that classify EOAs/contracts differently.

Do not use these as security assumptions without re-derivation:

```text
address.code.length == 0 ⇒ cannot execute contract logic

tx.origin == msg.sender ⇒ only a simple top-level EOA flow

EOA balance only decreases when that EOA originates a transaction
```

EIP-7702 makes these assumptions unsafe in general.

---

# 13. ERC-4337 and Account-Abstraction Flows

When ERC-4337 or similar AA infrastructure is present, map the full validation-execution pipeline.

```text
UserOperation
→ bundler policy / simulation
→ EntryPoint
→ account validation
→ paymaster validation (optional)
→ execution
→ postOp / gas settlement
```

Security research must include:

- EntryPoint version and trust;
- account validation logic;
- nonce model;
- signature aggregation;
- account deployment / initCode;
- bundler simulation assumptions;
- ERC-7562 validation constraints;
- paymaster deposits / stakes;
- sponsorship authorization;
- gas griefing;
- paymaster replay;
- `postOp` behavior;
- execution reverting after successful validation;
- alt-mempool policy divergence;
- modular account plugins;
- upgrade / module authorization;
- session keys;
- EIP-7702 + UserOperation composition;
- version migration between EntryPoints.

A flow rejected by one bundler but accepted by another is not necessarily an on-chain impossibility.

Separate:

```text
protocol validity
bundler policy
mempool admissibility
on-chain execution
```

---

# 14. Upgradeability, Initialization, and Storage

Treat upgradeability as a state machine with authority.

Map:

```text
proxy
implementation
admin / upgrade authority
initializer state
storage layout
upgrade path
migration calls
rollback / emergency path
```

Research:

- uninitialized implementations;
- reinitializers;
- initializer ordering;
- proxy type assumptions;
- transparent/UUPS/beacon semantics;
- implementation self-calls;
- delegated storage;
- slot collisions;
- namespaced storage;
- function selector collisions;
- immutable variables vs proxy storage;
- upgrade authorization;
- timelocked vs immediate upgrades;
- upgrade-and-call behavior;
- partial migration;
- legacy state carried through upgrades;
- downgrade paths;
- emergency implementation switching;
- chain-specific deployment differences.

Always compare deployed storage layout across versions, not only source diffs.

---

# 15. Oracle and Data-Dependency Research

An oracle read is a multi-layer trust dependency.

Record:

```text
source
aggregation
update trigger
heartbeat
staleness behavior
deviation threshold
round semantics
decimals / units
fallback
consumer validation
L2 availability dependency
```

Research:

- stale price acceptance;
- future timestamps;
- missing round validation;
- decimal mismatch;
- inverted pairs;
- zero / negative values;
- bounded vs unbounded values;
- fallback divergence;
- source correlation;
- thin-market manipulation;
- AMM spot-price use;
- TWAP window assumptions;
- low-liquidity windows;
- rate oracle vs price oracle confusion;
- share-price oracle circularity;
- read-only reentrancy affecting oracle-visible state;
- delayed off-chain updates;
- deprecated feeds;
- chain migration / address changes.

## 15.1 L2 sequencer dependence

On L2s with sequencers, price validity and transaction accessibility can diverge during downtime.

Chainlink's current L2 guidance explicitly recommends checking sequencer status and a post-recovery grace period before consuming dependent data.

Research whether the protocol handles:

```text
sequencer down
→ users cannot access normal L2 path
→ privileged / technically capable actors may have alternative paths
→ sequencer returns
→ queued transactions process
→ oracle / market state catches up
→ grace period
```

For liquidation systems, this is a market-fairness and solvency issue, not merely oracle freshness.

---

# 16. AMMs, Pools, and Liquidity Accounting

Do not assume every AMM preserves `x*y=k`.

Derive the actual invariant and settlement mechanism.

Track:

- reserves / virtual reserves;
- concentrated-liquidity ticks;
- liquidity positions;
- fees;
- fee growth accumulators;
- donation accounting;
- dynamic fees;
- hooks;
- protocol fees;
- flash liquidity;
- pool initialization;
- price limits;
- token ordering;
- decimal normalization;
- settlement deltas.

Research extreme states:

- zero liquidity;
- one-sided liquidity;
- tick boundaries;
- minimum / maximum price;
- first liquidity;
- last liquidity;
- fee growth near limits;
- donation before / after liquidity change;
- hook-controlled fee or curve changes;
- multi-hop composition;
- same-transaction pool manipulation.

Ask whether the protocol consuming an AMM price understands the AMM's actual manipulation cost and observation window.

---

# 17. Lending and Credit Protocols

Build a balance sheet, not just a call graph.

Track:

```text
supplied assets
borrowed assets
collateral value
debt value
interest index
reserves
bad debt
liquidation incentive
close factor
borrow caps
supply caps
```

Research:

- collateral enable/disable transitions;
- stale interest accrual;
- index rounding;
- borrow / repay ordering;
- self-liquidation;
- partial liquidation;
- bad debt creation;
- bad debt socialization;
- oracle failure;
- collateral decimals;
- isolated / siloed market assumptions;
- cross-collateral coupling;
- flash liquidity;
- liquidation profitability;
- liquidation race conditions;
- first / last market liquidity;
- debt ceilings;
- cap changes;
- paused-market edge cases;
- seized collateral transfer semantics;
- reserve withdrawal during stress;
- interest-rate model discontinuities.

## 17.1 Liquidation must be executable

Model:

```text
liquidatable value
− acquisition cost
− swap slippage
− gas / priority fee
− price movement
− inventory risk
= liquidator realizable margin
```

A liquidation mechanism that is mathematically available but economically unattractive can turn normal volatility into protocol bad debt.

---

# 18. Stablecoins and Pegged Assets

Model both accounting solvency and market peg mechanics.

Track:

- mint authority;
- redemption path;
- collateral composition;
- collateral liquidity;
- reserve accounting;
- debt ceilings;
- peg-stabilization mechanisms;
- liquidation path;
- oracle source;
- cross-chain supply;
- emergency controls;
- mint / burn adapters.

Research:

- unbacked minting;
- double-counted collateral;
- stale reserve value;
- redemption queue failure;
- peg defense exhaustion;
- cross-chain supply divergence;
- depeg feedback loops;
- liquidation cascades;
- circular collateral;
- protocol-owned liquidity assumptions;
- governance changes during stress.

A nominal one-dollar accounting value is not the same as realizable one-dollar liquidity.

---

# 19. Derivatives, Perpetuals, and Settlement Systems

Track distinct prices:

```text
index price
mark price
execution price
settlement price
oracle price
```

Research:

- funding rate calculation;
- funding settlement timing;
- mark/index divergence;
- price bands;
- liquidation engine;
- insurance fund;
- ADL or loss socialization;
- unrealized PnL accounting;
- realized PnL timing;
- collateral haircuts;
- open-interest caps;
- settlement finality;
- expiry boundaries;
- stale oracle behavior;
- self-trade / wash effects;
- thin-market manipulation;
- bad-debt waterfall.

Measure whether profitable state manipulation survives unwind and settlement.

---

# 20. Staking, Restaking, Rewards, and Queued Withdrawals

Model principal, claim token, reward index, slash exposure, and withdrawal timing separately.

Research:

- deposit-to-share conversion;
- delayed activation;
- reward index updates;
- reward dilution;
- slash accounting;
- slash timing relative to withdrawal;
- queued withdrawals;
- withdrawal claim ownership;
- claim replay;
- reward harvesting;
- operator delegation;
- validator / operator changes;
- LST/LRT exchange-rate dependencies;
- oracle circularity;
- rehypothecation;
- nested share tokens;
- emergency exits;
- cross-chain representations.

A claim token may remain transferable while the underlying withdrawal is delayed or slash-exposed. Model that gap explicitly.

---

# 21. Governance and Emergency Control

Governance is executable authority.

Map:

```text
proposal creation
voting power source
snapshot
quorum
vote delegation
voting period
queue
timelock
execution
veto / guardian
pause / emergency path
upgrade authority
```

Research:

- flash-acquired voting power;
- voting-power checkpoints;
- delegation timing;
- quorum edge cases;
- proposal threshold manipulation;
- stale voting power;
- executable target restrictions;
- arbitrary calldata;
- timelock bypass;
- cancellation races;
- guardian override;
- emergency role escalation;
- cross-chain governance messages;
- governance executor mismatches across deployments;
- partial multi-chain execution;
- upgrade + governance composition.

Do not label an action safe merely because “governance can do it.”

Ask whether the governance model explicitly grants that effect and whether the acquisition of voting/guardian authority is realistic.

---

# 22. MEV, Ordering, Inclusion, and Transaction Competition

A sequence that works only in an uncontested local environment may not work on-chain.

Model:

- public mempool visibility;
- private order flow;
- builder / proposer ordering;
- sequencer ordering;
- same-block state;
- frontrunning;
- backrunning;
- sandwiching;
- liquidation competition;
- bundle atomicity;
- transaction replacement;
- censorship / delayed inclusion;
- priority fees;
- intent solvers;
- batch auctions;
- cross-domain ordering.

For every ordering-sensitive hypothesis distinguish:

```text
attacker can choose
attacker can bid for
attacker can observe
attacker can only hope for
protocol guarantees
```

Do not silently grant arbitrary ordering.

---

# 23. Economic Manipulation and Realizable Value

A mathematical state transition is not an economic exploit until its resource path closes.

Measure:

```text
capital required
borrowable capital
collateral required
fees
slippage
price impact
priority fee / MEV cost
liquidation exposure
bridge / withdrawal delay
inventory risk
unwind path
repeatability
competition
```

Use multiple profit notions:

```text
gross accounting gain
realizable asset gain
net gain after execution costs
net gain after unwind
capital at risk
```

Research capital sources explicitly:

- attacker-owned capital;
- flash loans;
- flash swaps;
- credit lines;
- protocol-native leverage;
- temporary collateral;
- cross-protocol borrowing.

Never use test-injected balances as evidence that production capital exists.

## 23.1 Sensitivity analysis

Perturb:

- liquidity;
- volatility;
- fees;
- oracle delay;
- block ordering;
- gas;
- available flash liquidity;
- collateral ratios;
- liquidation competition;
- time window.

Classify the hypothesis:

```text
robust
state-sensitive
liquidity-sensitive
timing-sensitive
ordering-sensitive
configuration-sensitive
historical-only
economically infeasible
```

---

# 24. Cross-Protocol Composition

Every external protocol integration imports another state machine and trust model.

For each integration record:

```text
external protocol
version / deployment
asset accepted
function relied on
security property assumed
state relied on
oracle relied on
upgrade authority
pause behavior
failure behavior
callback behavior
```

Search for semantic mismatches:

```text
protocol A assumes X is stable
protocol B allows X to change

protocol A assumes transfer == amount
protocol B charges transfer fee

protocol A assumes share price changes gradually
protocol B permits direct donation

protocol A assumes callback after accounting
protocol B calls back before settlement
```

Composition bugs often exist without either component being locally incorrect.

---

# 25. Cross-Chain and Bridge Security Model

Never treat two chain-side contracts as one synchronous program.

Model the complete message lifecycle:

```text
source state
→ message creation
→ origin identity
→ source finality assumption
→ proof / attestation / verifier
→ transport / relayer
→ destination authentication
→ replay / nonce checks
→ ordering
→ execution
→ failure / retry
→ final state
```

For token bridges add:

```text
lock / burn on source
↔
mint / unlock on destination
```

and derive global supply conservation.

## 25.1 Message identity

Check which fields uniquely bind the message:

- source chain;
- source contract / program;
- destination chain;
- destination contract;
- nonce;
- payload;
- value;
- token identity;
- sender;
- version / domain;
- expiry;
- message index / log identity.

Authentication of the transport contract alone may be insufficient if source application identity is not also authenticated.

## 25.2 Finality is a security parameter

Record:

```text
source finality
reorg tolerance
challenge / dispute period
proof finality
relayer delay
retry window
expiry
```

Research:

- accepting messages before sufficient finality;
- chain reorg after destination action;
- inconsistent finality assumptions across chains;
- paused verifier / relayer;
- delayed message execution;
- duplicate relay;
- reordered messages;
- partial multi-message workflows.

## 25.3 Failure and retry semantics

Asynchronous message systems must define what happens when destination execution fails.

Research:

- who can retry;
- whether original sender/value/payload is preserved;
- gas top-ups;
- expiry;
- escrow;
- refunds;
- duplicate side effects;
- partial state before failure;
- cancel vs retry races.

A retryable message is a state machine, not merely a failed transaction.

## 25.4 Verifier configuration

Treat verifier thresholds, signer sets, guardians, relayers, light clients, and proof systems as first-class configuration.

A secure bridge architecture can become insecure through a weaker production verifier configuration.

---

# 26. L2 and Rollup Semantics

Do not assume an L2 behaves like L1 with cheaper gas.

Map:

- sequencer;
- forced inclusion path;
- batch submission;
- data availability;
- state commitment;
- proof / fault-dispute mechanism;
- challenge period;
- bridge contracts;
- system predeploys;
- address aliasing;
- L1↔L2 message paths;
- withdrawal proof and finalization;
- privileged guardian / security council;
- upgrade keys;
- chain-specific gas model.

## 26.1 Withdrawal lifecycle

Optimistic rollups can require distinct initiate, prove, and finalize phases separated by a challenge period.

Research each phase independently.

Do not model:

```text
L2 withdrawal transaction succeeded
```

as equivalent to:

```text
L1 assets are immediately final and spendable
```

## 26.2 Cross-L2 interoperability

When chains support direct L2-to-L2 messaging, model message identifiers, dependency sets, expiry windows, relayers, and destination validation separately from L1 bridges.

Cross-L2 “fast” messaging can create a new trust/finality layer even when each individual L2 is secure.

---

# 27. Solana / SVM Branch

When the target runs on Solana or an SVM-derived runtime, do not translate EVM assumptions mechanically.

State lives in accounts supplied to instructions.

For every instruction verify the semantic identity and authority of each account.

Record:

```text
account address
owner program
signer?
writable?
executable?
expected PDA seeds
expected mint / token program
expected authority
close authority
```

Research:

- missing signer checks;
- missing owner checks;
- arbitrary account substitution;
- arbitrary program substitution;
- PDA seed collisions / weak namespace design;
- incorrect bump handling;
- PDA authority assumptions;
- `invoke_signed` signer derivation;
- writable-account confusion;
- duplicate-account aliasing;
- stale account data;
- account close / reinitialize behavior;
- rent / lamport effects;
- realloc behavior;
- Token Program vs Token-2022 semantics;
- unchecked mint / decimals;
- CPI privilege propagation;
- compute-budget exhaustion;
- instruction ordering within a transaction;
- program upgrade authority;
- Address Lookup Table assumptions where relevant.

## 27.1 CPI semantics

Solana CPIs propagate signer/writable privileges from caller to callee subject to runtime enforcement, and PDAs can be treated as signers when the owning program invokes with the correct seeds.

Therefore ask:

- which privileges enter the CPI?
- which accounts are caller-controlled?
- can a malicious program be substituted as the callee?
- does the caller validate callee program identity?
- can PDA signing authorize a broader action than intended?
- does state remain consistent across CPI failure?
- is the compute budget sufficient under adversarial input?

Do not copy EVM reentrancy rules onto Solana. Use the current runtime's actual CPI/reentrancy semantics.

---

# 28. Object / Capability-Based VM Branch

For Move-family or object-centric runtimes, derive security from the runtime's actual ownership and capability model.

Map:

- owned objects;
- shared objects;
- immutable objects;
- capabilities;
- module visibility;
- resource creation / destruction;
- object versioning;
- transaction dependencies;
- package upgrade policy.

Research whether authority is represented by:

```text
address identity
object ownership
capability possession
module privilege
shared-object consensus access
```

Do not import EVM authorization expectations such as `msg.sender` when the runtime enforces authority through resources or object capabilities.

Escalate to runtime/dependency inspection when the exact semantics affect exploitability.

---

# 29. Factories, CREATE/Deployment, and Deterministic Addresses

Factories create security assumptions before application logic begins.

Research:

- deterministic address derivation;
- salt reuse;
- deployment races;
- initialization in the same vs later transaction;
- clone implementations;
- immutable args;
- implementation replacement;
- duplicate market creation;
- canonical instance registries;
- chain-specific deployment differences;
- address precomputation used for authorization.

Do not assume a deterministic address implies a deterministic implementation unless the creation inputs are also bound.

---

# 30. Privileged Operations and Operational Security

Protocol-layer security can be bypassed by privileged infrastructure.

Map every authority capable of:

- minting;
- burning;
- pausing;
- unpausing;
- upgrading;
- changing oracle;
- changing verifier;
- changing bridge route;
- seizing funds;
- changing fees;
- changing risk parameters;
- changing caps;
- moving treasury assets;
- rotating signers;
- enabling modules;
- executing arbitrary calls.

For each authority record:

```text
holder
threshold
key custody model
timelock
rotation path
recovery path
scope
on-chain constraints
monitoring
```

Current industry loss data increasingly distinguishes protocol-code risk from custody, key-management, and cross-chain configuration risk. Do not restrict “DeFi security” to Solidity source when a compromised or weakly constrained privileged path can produce the same impact.

---

# 31. Configuration Space

A secure codebase may have unsafe reachable configurations.

Build a configuration matrix for:

- supported assets;
- oracle choices;
- collateral factors;
- caps;
- fee parameters;
- hook addresses;
- bridge routes;
- verifier thresholds;
- guardian settings;
- pause flags;
- strategy adapters;
- implementation versions;
- chain-specific deployments;
- account-abstraction modules;
- allowlists / denylists;
- rate limits.

Classify each configuration:

```text
currently deployed
historically deployed
governance-reachable
upgrade-reachable
factory-creatable
impossible under current controls
```

Do not dismiss a configuration-dependent vulnerability if governance or a permissionless factory can actually create that configuration.

---

# 32. Production-State Research

Some vulnerabilities exist only in state accumulated over time.

Inspect production or faithful fork state for:

- actual liquidity;
- real asset balances;
- share supply;
- debt distribution;
- unhealthy positions;
- dust;
- stale approvals;
- legacy storage;
- old positions spanning upgrades;
- role holders;
- pending governance actions;
- bridge queues;
- oracle configuration;
- deprecated feeds;
- pause state;
- deployed hook / adapter set;
- inactive but reachable markets.

Pin snapshots by block / slot / height when using them as evidence.

“Latest state” is not reproducible evidence.

---

# 33. Invariant and Property Suite

Derive properties before relying on existing tests.

Useful classes include:

## Authorization

```text
unauthorized actor cannot produce privileged state transition
```

## Conservation

```text
claims cannot exceed backing under defined assumptions
```

## Solvency

```text
withdrawable liabilities remain covered by realizable assets
```

## Monotonicity

```text
an operation intended only to repay debt cannot increase that user's debt
```

## Idempotence

```text
replaying a finalized message cannot apply its value effect twice
```

## Cross-chain supply

```text
canonical representations remain globally backed
```

## Price safety

```text
one actor cannot move the accepted price beyond bound B within cost C / window T
```

## State-machine safety

```text
terminal / finalized state cannot return to an economically active pre-final state
```

## Upgrade safety

```text
upgrade preserves required storage and authority invariants
```

Do not copy implementation outputs into invariants before proving those outputs are intended.

---

# 34. Dynamic Research Strategy

Choose tools based on the property.

## Fork testing

Use for:

- deployed configuration;
- actual liquidity;
- real integrations;
- historical state;
- production bytecode;
- economic feasibility.

## Stateful fuzzing

Use for:

- sequence bugs;
- lifecycle transitions;
- invariant violations;
- repeated rounding;
- state-space exploration.

## Differential testing

Compare:

- old vs new implementation;
- preview vs execution;
- reference math vs production math;
- L1 vs L2 implementation;
- sibling chain deployments;
- two oracle paths;
- two token implementations.

## Symbolic / formal methods

Use when bounded properties can be stated precisely.

Audit the specification itself.

## Tracing / state diff

Use for:

- hidden external calls;
- delegated execution;
- callback chains;
- unexpected storage writes;
- balance drift;
- privilege transitions.

A tool result is evidence about a model, not proof that the model is complete.

---

# 35. Attack-Family Portfolio

Do not let all research collapse into the first promising economic primitive.

Maintain materially different families where architecture supports them.

Example portfolio:

```text
authorization / signature
account abstraction / delegation
upgrade / initialization
accounting / rounding
vault / share conversion
oracle / pricing
callback / hook / reentrancy
liquidation / bad debt
MEV / ordering
cross-protocol composition
cross-chain provenance / replay
L2 finality / sequencer
runtime / VM semantics
privileged infrastructure
configuration-specific
```

Negative results in one family are not evidence against another.

---

# 36. Historical and Incident-Guided Research

After first-principles modeling is established, use incidents and patches as research seeds.

For each relevant historical exploit or audit issue extract:

```text
security property
root cause
attacker capability
reachable state
exploit primitive
impact path
fix
assumption introduced by fix
sibling implementations
```

Search for semantic variants, not copied syntax.

Do not assume old exploit popularity predicts current attack probability.

Current aggregate data indicates some classic ecosystem-wide exploit classes have declined substantially while multi-chain, configuration, custody, and operational surfaces remain important. Use that as a prioritization signal, never as permission to skip old classes when architecture exposes them.

---

# 37. Cross-Chain Global Invariants

For multi-chain systems define properties over the whole deployment graph.

Examples:

```text
GLOBAL_SUPPLY
  sum(canonical minted representations)
  <=
  canonical backing

MESSAGE_FINALITY
  a state transition accepted as final on destination
  must correspond to a sufficiently final source event

GLOBAL_GOVERNANCE
  one governance action cannot execute with materially different payload semantics across chains

ROLE_PARITY
  chain-specific role configuration must match intended trust model
```

Check whether partial chain failure violates a global invariant even when each surviving chain remains locally correct.

---

# 38. Blast-Radius Analysis

Do not stop at the directly affected contract.

For every credible violation map dependent systems:

```text
asset holders
vaults
lending markets
LPs
bridges
oracles
integrators
routers
keepers
liquidators
other chains
frontends / automation
```

Distinguish:

- directly extractable value;
- protocol insolvency;
- user-specific loss;
- dependent-protocol loss;
- governance takeover;
- temporary availability loss;
- permanent state corruption;
- market / peg effects.

Current incident research shows dependency effects and tail risk can dominate the headline transaction-level loss. Model the propagation path rather than simply multiplying TVL.

---

# 39. Safe Validation

Prefer controlled environments:

```text
local node
local multi-node cluster
fork pinned to block / slot
isolated deployment
test harness
simulation
```

Do not execute exploit actions against production, public mainnet, live funds, real users, or third-party infrastructure without explicit authorization for that exact action.

When using forks or harnesses, route the candidate through `exploit-validation.md` and account for synthetic state, impersonation, mocked dependencies, test-only liquidity, and other harness powers.

A successful local exploit is only one stage of exploitability proof.

---

# 40. Mandatory Research Artifacts

For a serious smart-contract / DeFi engagement, maintain the subset relevant to the target:

```text
CHAIN_RUNTIME.md
DEPLOYMENT_MAP.md
ASSET_LIABILITY_MAP.md
ATTACK_GRAPH.md
STATE_MACHINE.md
AUTHORITY_MAP.md
TOKEN_MATRIX.md
ACCOUNTING_MODEL.md
ORACLE_MODEL.md
ECONOMIC_MODEL.md
ORDERING_MODEL.md
L2_MODEL.md
CROSS_CHAIN_MODEL.md
GLOBAL_INVARIANTS.md
CONFIG_MATRIX.md
PRODUCTION_STATE.md
HYPOTHESES.md
NEGATIVE_EVIDENCE.md
FINDINGS.md
```

For each external integration include exact deployment identity and security assumptions.

Artifacts should evolve during research, not be reconstructed from memory at the end.

---

# 41. Prohibited Shortcuts

Do not:

- audit only public/external functions;
- treat a contract as isolated from its callers or callees;
- assume ERC-20 semantics from an interface;
- assume an address with no persistent code is permanently a simple EOA;
- use `tx.origin` as an unexamined EOA/security boundary;
- assume one reentrancy guard protects all coupled state;
- assume a nonReentrant modifier eliminates callback-state problems;
- assume an oracle is safe because it is “Chainlink” or another reputable provider;
- omit heartbeat, timestamp, decimals, sequencer, and feed-lifecycle checks;
- equate an AMM spot quote with robust price discovery;
- equate accounting profit with realizable profit;
- assume flash liquidity is unlimited;
- assume arbitrary transaction ordering;
- ignore priority fees / MEV competition;
- assume all L2 transactions have L1 finality;
- equate L2 withdrawal initiation with L1 finalization;
- authenticate only the bridge contract while ignoring source application identity;
- ignore retry / replay / failure semantics in asynchronous messaging;
- assume cross-chain supply is locally enforceable on one chain;
- ignore verifier / signer / guardian configuration;
- review upgrades without deployed storage state;
- assume proxy source identifies the active implementation;
- ignore account abstraction when an application accepts smart accounts or delegated EOAs;
- assume bundler policy equals protocol validity;
- treat transient storage as memory;
- apply EVM reentrancy/authorization assumptions to Solana or Move runtimes;
- accept arbitrary Solana accounts without proving owner/signer/program identity requirements;
- call a test-harness balance an available production capital source;
- conclude “safe” from clean static analysis, fuzzing, or audits;
- rank bug classes only by historical popularity.

---

# 42. Research Loop

Run repeatedly:

```text
bind deployment + runtime
        ↓
map assets / liabilities / authority
        ↓
build state + call + value graph
        ↓
derive invariants
        ↓
select relevant execution / economic surfaces
        ↓
generate materially different hypotheses
        ↓
construct reachable sequences
        ↓
test with appropriate state and dependencies
        ↓
measure state / value / authority deltas
        ↓
attack economic and execution assumptions
        ↓
record blockers / negative evidence
        ↓
perform semantic variant search
        ↓
update global invariants + residual uncertainty
```

The goal is not to “cover Solidity vulnerabilities.”

The goal is to determine which **security properties of the deployed economic system** survive realistic adversarial execution.

---

# 43. 2026 Research Calibration — 2026-08-25

This section records why several surfaces above are first-class in the current playbook.

Re-check these sources and semantics for future engagements because protocol/runtime behavior evolves.

## 43.1 EIP-7702 changes old EOA assumptions

EIP-7702 is active in modern Ethereum environments and allows EOAs to delegate execution to contract code. Its specification explicitly documents broken legacy invariants including changes to EOA balance behavior, nonce behavior, and `tx.origin == msg.sender` assumptions. Its security considerations call out replay protection, signed target/calldata/value/gas, initialization front-running, storage migration, and relayer griefing.

Source:

- https://eips.ethereum.org/EIPS/eip-7702

## 43.2 Transaction-scoped transient state is a real execution surface

EIP-1153 transient storage is cleared at transaction end, not at call return, and follows storage-like ownership/revert semantics across frames. Its own security considerations warn that leaving transient values set can affect later interactions in the same transaction and that it should not be modeled as ordinary memory.

Source:

- https://eips.ethereum.org/EIPS/eip-1153

## 43.3 Account abstraction adds infrastructure and validation layers

Current ERC-4337 documentation models `UserOperation → bundler → EntryPoint → account/paymaster validation → execution`, with bundler simulation and ERC-7562 validation constraints. Paymasters introduce deposit/stake, sponsorship, replay, gas-griefing, and `postOp` surfaces. Current docs also describe EIP-7702 integration and newer EntryPoint/paymaster behavior.

Sources:

- https://docs.erc4337.io/core-standards/erc-4337
- https://docs.erc4337.io/core-standards/erc-7562.html
- https://docs.erc4337.io/paymasters/security-and-griefing.html
- https://docs.erc4337.io/paymasters/paymaster-signature.html

## 43.4 Hook-based AMMs and deferred settlement expand composition surface

Uniswap v4 exposes pool-specific external hooks at initialization, liquidity modification, swaps, and donations, and uses a singleton/flash-accounting architecture. This makes hook identity, permission encoding, temporary deltas, settlement, and callback composition first-class research surfaces.

Sources:

- https://developers.uniswap.org/docs/protocols/v4/concepts/hooks
- https://developers.uniswap.org/docs/protocols/v4/concepts/flash-accounting
- https://developers.uniswap.org/docs/protocols/v4/security

## 43.5 Vault security requires conversion and state-boundary analysis

OpenZeppelin Contracts 5.x continues to document ERC-4626 inflation/donation risk in empty or nearly empty vaults, conversion rounding, and virtual asset/share mitigation. Inherited mitigations do not remove the need to test overrides, fees, losses, asynchronous extensions, and external strategies.

Sources:

- https://docs.openzeppelin.com/contracts/5.x/erc4626
- https://docs.openzeppelin.com/contracts/5.x/api/token/erc20

## 43.6 L2 oracle safety includes sequencer liveness

Current Chainlink guidance treats sequencer downtime as an application risk because normal L2 access can disappear while alternative underlying rollup paths create asymmetric access. It recommends sequencer-status checks and a grace period after recovery before dependent operations resume.

Source:

- https://docs.chain.link/data-feeds/l2-sequencer-feeds

## 43.7 Rollup messaging is asynchronous and multi-stage

Current OP Stack documentation models L2→L1 withdrawals as initiation, proof, and finalization separated by the fault challenge period. Cross-L2 interoperability introduces explicit source-chain/message identity and an execution window. These semantics make “message sent” and “state finalized” distinct security states.

Sources:

- https://docs.optimism.io/op-stack/bridging/withdrawal-flow
- https://docs.optimism.io/app-developers/guides/interoperability/message-passing
- https://docs.optimism.io/op-stack/interop/explainer

## 43.8 Solana security depends on account identity and CPI runtime semantics

Current Solana documentation emphasizes that programs operate on caller-supplied accounts; PDAs derive authority from program ID + seeds; `invoke_signed` can make the owning program's PDA a signer; and CPI propagates signer/writable privileges subject to runtime enforcement. Runtime limits and feature-gated behavior can change, so bind analysis to the target runtime rather than hard-coding historical limits.

Sources:

- https://solana.com/docs/core
- https://solana.com/docs/core/pda
- https://solana.com/docs/core/cpi
- https://solana.com/docs/tokens/advanced/cpi

## 43.9 Incident data changes prioritization, not first principles

Immunefi's April 27, 2026 six-year DeFi-loss analysis reports that classic ecosystem-class attacks and bridge-loss share fell sharply by 2025 while multi-chain, custodial, cross-chain, and operational risks became more prominent. Its March 25, 2026 impact update also shows increasing tail concentration and growing dependency blast radius.

Use these observations only as research priors.

Do not suppress a bug class merely because aggregate historical incidence declined.

Sources:

- https://immunefi.com/blog/research/the-ecosystem-vulnerability-scoreboard-6-years-of-defi-loss-data/
- https://immunefi.com/blog/research/what-an-onchain-hack-actually-costs-2024-2025-update/

---

# 44. Final Research Standard

A serious smart-contract / DeFi review should be able to answer:

```text
What assets and authorities exist?
What properties must remain true?
What runtime actually executes them?
Which state transitions are reachable?
Which external systems participate?
Which prices and market conditions are assumed?
Which ordering/finality assumptions matter?
Which cross-chain states must remain consistent?
Which configurations are currently or eventually reachable?
Which attacker positions were tested?
Which economic paths are actually executable?
Which hypotheses failed, and why?
Which properties remain weakly tested?
```

Do not finish with:

> The contracts look secure.

Finish with bounded evidence about the deployed system:

> These properties were challenged under these attacker positions, execution environments, dependency states, market conditions, and configurations; these violations were established or falsified; these assumptions remain unresolved.
