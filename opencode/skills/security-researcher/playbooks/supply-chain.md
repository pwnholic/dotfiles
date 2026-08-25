# Smart-Contract Build, Deployment, and Supply-Chain Playbook

Load when security depends on source-to-bytecode correspondence, compiler/build provenance, dependencies, deployment scripts/transactions, contract verification, proxy upgrades, program binaries, or upgrade authority.

## Smart-Contract Scope Lock

This playbook belongs to a **smart-contract / DeFi security research stack**. Apply it to on-chain programs, protocols, token systems, vaults, AMMs, lending, staking/restaking, governance, account abstraction, bridges, rollups/L2s, cross-chain systems, and infrastructure only when that infrastructure is causally necessary to an on-chain security property.

Do **not** expand the default search into generic web/backend/database/desktop/cloud security. An off-chain component belongs here only when compromising or mis-modeling it can change an on-chain authorization decision, state transition, message provenance, price, ordering/finality assumption, upgrade/deployment state, or realizable economic impact.

When a concrete exploit hypothesis exists, hand validation to `exploit-validation.md`.

# 1. Security Objective

For smart contracts, supply-chain research asks whether the **reviewed source and intended release are the code and configuration that became attacker-reachable on-chain**.

```text
reviewed source
→ pinned dependencies/toolchain
→ compilation inputs
→ bytecode / executable
→ deployment transaction
→ proxy/program linkage
→ initialization/configuration
→ current production state
```

Every arrow is a security boundary.

# 2. Source Identity

Bind repository, commit/tag, submodules, vendored libraries, generated sources, package lockfiles, remappings, git dependencies, and any codegen inputs. A tag name or release page is not enough if it can move or if build inputs come from another revision.

# 3. Dependency Identity

For Solidity/Vyper/Rust/Move dependencies record exact version/source and whether the dependency is compiled into bytecode, linked, dynamically referenced by address, or only used by deployment tooling.

Prioritize dependencies that affect authorization, arithmetic, signatures, proxy/storage, token semantics, serialization, bridge/oracle verification, or code generation.

# 4. Compiler / Toolchain Provenance

Record:

```text
compiler version
optimizer enabled / runs / details
via-IR / Yul settings
EVM version / target runtime
library addresses
metadata settings
build framework version
Rust/Solana toolchain and SBF target when relevant
Move compiler/runtime target when relevant
```

A source audit bound to one compiler configuration does not automatically cover another generated artifact.

# 5. Reproducible Build and Bytecode Correspondence

For EVM deployments prefer reconstructing standard-json compilation inputs and comparing deployed runtime/creation bytecode with the expected output. Solidity metadata records compiler/settings/source information, and Sourcify distinguishes exact matches from matches where metadata differs.

For Solana, verified-build workflows compare the executable hash produced from a controlled build against the on-chain program executable.

Verification proves source↔artifact correspondence, **not security**.

# 6. Linked Libraries, Immutables, Constructor Arguments

Bytecode correspondence must account for:

- linked library addresses;
- immutable references;
- constructor arguments;
- metadata/auxdata;
- factory-embedded child bytecode;
- CREATE2 salts and init code;
- clone implementation addresses.

Do not treat “similar bytecode” as evidence that security-critical deployment inputs match.

# 7. Deployment Transaction Provenance

Trace the actual deployment/upgrade transaction:

- deployer / factory;
- creation bytecode;
- constructor/init calldata;
- deterministic salt;
- implementation address;
- proxy admin/beacon/facet wiring;
- ownership/role transfers;
- initializer/reinitializer execution;
- governance/timelock execution;
- chain and block/slot.

The intended deployment script is weaker evidence than the transaction that actually executed.

# 8. Upgrade Provenance

Treat each upgrade as a new release artifact. Bind proposal/payload, implementation bytecode, storage-layout validation, initialization calldata, admin/upgrade authority, timelock state, and execution transaction.

Search for:

- reviewed implementation ≠ executed implementation;
- omitted reinitializer;
- unsafe validation bypass (`unsafeAllow`, skipped storage check, custom scripts);
- stale beacon/facet/implementation on one deployment;
- unreviewed emergency upgrade path;
- implementation deployed but proxy not upgraded;
- proxy upgraded to a different build than verified source.

# 9. Storage-Layout Supply Chain

Storage layout is an artifact of source + compiler + inheritance + upgrade pattern. Preserve compiler outputs/build-info needed to compare layouts. For ERC-7201 namespaced storage, verify namespace identifiers and tool support. For traditional layouts, verify packing/order/gaps.

A source diff that looks harmless can change storage interpretation.

# 10. Verification Service Semantics

Explorer verification is evidence, not authority. Record whether verification is exact/matched, which source/settings were supplied, and whether proxy resolution corresponds to current state. Sourcify API v2 exposes richer verification/proxy/storage information and distinguishes exact matches from matches.

Independently fetch on-chain code when high assurance is required.

# 11. Deployment Address / Registry Integrity

Verify canonical addresses from on-chain registries, factories, governance state, or authenticated project release data. Search for stale docs, wrong chain IDs, duplicate deployments, deprecated proxies, malicious lookalikes, and frontend/SDK address drift when those could direct users or automation to a different contract.

# 12. Artifact-to-Configuration Gap

Even perfect bytecode verification does not prove production parity. Separately bind:

- initialized state;
- roles/admins;
- oracle/bridge/token addresses;
- risk parameters;
- pause state;
- governance configuration;
- current implementation/facets;
- Solana upgrade authority.

Route that work to `configuration-space.md`.

# 13. Solana Deployment / Verified-Build Branch

For SVM programs record program ID, loader, ProgramData account, deployed slot, upgrade authority, executable hash, source repository/commit, build arguments/toolchain, and verified-build evidence. Loader-v3 programs remain upgradeable while an upgrade authority exists; setting it to `None` makes them immutable.

After any upgrade, re-establish executable correspondence and authority state.

# 14. Generated Interfaces and Client Artifacts

IDL/ABI/SDK generation matters only when it can change signing, account selection, calldata/instruction construction, message-domain binding, or deployment configuration. Compare generated interface artifacts to the deployed program, but remember: an unsafe client path is not automatically an on-chain vulnerability unless the contract/program accepts the dangerous state or authorization.

# 15. Release-Key and Upgrade-Authority Boundary

Operational key security is in scope when compromise directly grants on-chain upgrade/configuration authority. Model the on-chain authority graph rather than auditing generic enterprise IAM. Record multisig threshold, timelock, guardian/emergency path, program upgrade authority, and whether authority can be rotated or removed.

# 16. Historical Artifact Diffing

For incidents or prior upgrades compare:

```text
source diff
compiler/build diff
bytecode diff
storage-layout diff
deployment payload diff
configuration diff
```

A patch may be present in source but absent from one deployed chain, proxy, facet, or program binary.

# 17. Variant Search

Once a source→artifact or artifact→deployment mismatch is found, search sibling deployments:

- all supported chains;
- all markets/factories;
- all proxies/beacons/facets;
- old but funded deployments;
- test-to-production release branches;
- canonical and emergency upgrade paths.

Route root-cause propagation to `variant-analysis.md`.

# 18. Mandatory Artifact

Maintain `DEPLOYMENT_PROVENANCE.md`:

```text
source revision
dependency lock
build inputs/toolchain
expected artifact hash/bytecode
on-chain artifact identity
verification status
deployment/upgrade tx
proxy/program linkage
initializer/migration payload
authority state
configuration handoff
known mismatches
residual uncertainty
```

# 19. Prohibited Shortcuts

Do not infer:

- audited source == deployed source;
- verified == safe;
- same address on another chain == same code/config;
- same implementation name == same bytecode;
- successful explorer verification == exact build provenance;
- source patch == deployed remediation;
- immutable proxy == immutable external dependencies;
- multisig ownership == safe upgrade process;
- package lockfile == complete deployment provenance.

# 20. Closure

A supply-chain conclusion must state which source revision produced which artifact, how the artifact reached the exact on-chain address/program, whether current proxy/program authority still permits replacement, what initialization/configuration was applied, and which parts remain unverified.

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
