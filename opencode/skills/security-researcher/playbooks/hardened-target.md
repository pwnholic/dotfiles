# Hardened-Target Playbook

Load when prior audits, formal verification, extensive fuzzing, mature tests,
large production exposure, or repeated review materially changes the search
strategy.

## Objective

Do not repeat assurance work at greater volume. Find the differential between
what prior assurance established and what the current deployed system requires:

```text
required security model
- actually assured model
+ deployment/runtime/history drift
= residual search surface
```

Retain a light baseline for simple defects; hardened does not mean locally
bug-free.

## Evidence pack

Before deep review, gather only relevant:

- exact source/build/deployed identity and current configuration;
- architecture, assets, invariants, threat model, and trust assumptions;
- prior audits/findings, formal properties/proofs, fuzz harnesses/corpora;
- patches, upgrades, migrations, storage layouts, governance changes;
- production deployments, balances/approvals, incidents, and dependencies;
- known exclusions, accepted risks, mocks, and operational assumptions.

Treat each assurance artifact as an executable claim about a bounded target,
not as a badge.

## Assurance-differential matrix

For every protected property record:

```text
property and asset
artifact/method that claims coverage
source/version/configuration covered
actors and state depth
external semantics modeled
oracle/model independence
known exclusions and assumptions
current target delta
strongest untested mutation
residual priority
```

Classify gaps:

```text
TARGET_DRIFT        code/build/deployment changed
STATE_DRIFT         old state now interpreted differently
CONFIG_DRIFT        roles/parameters/integrations changed
RUNTIME_DRIFT       chain/compiler/dependency semantics changed
MODEL_GAP           actor/state/economics/finality omitted
ORACLE_GAP          property circular, weak, or unmutated
COMPOSITION_GAP     component proof did not cover integration
HISTORY_GAP         earlier states or patches not searched
```

Do not convert this matrix into a fake security percentage.

## Assurance inversion

Attack the assumptions that made previous assurance tractable:

- bounded sequence depth or one-transaction models;
- canonical configuration/token/oracle only;
- honest or mocked external contracts;
- no upgrades, delegation, cross-domain delay, or runtime drift;
- implementation-derived oracle/reference model;
- privileged behavior declared out of scope;
- current-state-only analysis;
- proof of local function properties without global solvency/impact.

For formal verification, bind source/bytecode, compiler semantics, axioms,
environment model, quantified actors/states, and property strength. Prove that
the verified property implies the actual security claim; do not infer it from
proof success.

For fuzzing, mutate the implementation and oracle, inspect handler restrictions
and unreachable states, vary sequence depth/configuration/actors, and replay
historical bad states. A mature harness may encode the same assumptions as the
implementation.

## Historical and storage interpretation

Build a timeline:

```text
release/commit → deployment/upgrade → configuration change
→ incident/finding → patch/migration → current state
```

Search not only the textual patch but the violated invariant, missing
enforcement, sibling entrypoints, old funded deployments, and configurations
where the patch is absent or bypassed.

For upgradeable systems recover historical storage ownership from compiler
layouts, namespaces, executed upgrades, state diffs, and traces. Test old
state/new code, new state/rollback code, partial migration, reinitializer
omission, facet/beacon divergence, and legacy data that violates new
assumptions. Use gas-aware differential comparison when it prevents
misclassifying a semantic delta.

## Composition and production parity

Reconcile:

```text
reviewed source ↔ built artifact ↔ deployed code
documented roles/config ↔ on-chain state
mocked dependency ↔ deployed implementation
assumed liquidity/order/finality ↔ executable conditions
```

Prioritize boundaries between independently assured components: adapters,
hooks, routers, account modules, proxies, bridges, oracle fallbacks, factories,
and shared share/debt/message representations.

Search configurations beyond the canonical instance only when they exist or
are reachable through governance, factory creation, upgrades, or runtime
activation.

## Risk-weighted mutation portfolio

Choose mutations by:

```text
residual priority
= property criticality × assurance gap × reachability
  × composition leverage × blast radius / validation cost
```

High-value mutations:

- remove/weaken the exact enforcement a proof/test depends on;
- change actor or checked identity;
- increase state/history depth;
- cross upgrade/pause/epoch/finality boundaries;
- swap supported dependency/configuration/version;
- preserve local assertions while violating a global invariant;
- exploit approvals, delegations, or external claims beyond held TVL;
- force fail/retry/partial-completion paths.

The score ranks work; it is not exploit likelihood.

## Anti-correlation

Vary question, model, oracle, and method. Static analyzer, tests, audit, and
formal proof are not independent if they share the same specification or
exclude the same state. When multiple researchers are explicitly active, use
`multi-agent-research.md` and reserve an independent falsifier.

## Candidate promotion

Use the ordinary finding gate. Prior assurance neither lowers the evidence
required nor raises severity. Before validation provide:

```text
property and exact target
assurance claim bypassed or outside-model gap
attacker baseline and constructive path
mechanism and dependency claims
production parity and exposure
strongest prior control and why it does not close the claim
```

Route concrete mechanisms to `exploit-validation.md` and root-cause siblings
to `variant-analysis.md`.

## Closure

Report:

- which assurance artifacts were bound to which target;
- differential gaps and mutations exercised;
- historical/storage/configuration/runtime drift covered;
- independent vs correlated evidence;
- confirmed, blocked, and unresolved candidates;
- remaining assurance blind spots and reopen conditions.

The conclusion is about residual surface examined, never “audits/proofs imply
secure.”
