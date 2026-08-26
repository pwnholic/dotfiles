# Build, Deployment, and Supply-Chain Playbook

Load when security depends on source-to-artifact correspondence, build inputs,
dependencies, deployment or upgrade transactions, proxy/program linkage,
initialization, or executable provenance.

## Objective

Prove each boundary independently:

```text
reviewed source
→ pinned source/dependencies/toolchain
→ reproducible artifact
→ authorized release
→ deployment/upgrade transaction
→ active proxy/program linkage
→ initialized configuration
```

Verification metadata is evidence of correspondence, not evidence of safety.

## Four independent claims

```text
REPRODUCIBLE  declared inputs can produce the artifact
ATTESTED      an identified builder signed provenance
AUTHORIZED    release policy allowed builder/inputs/output
DEPLOYED      the exact artifact became reachable at the target
```

None implies the next. Record artifact digest, builder and trust base,
source/material digests, resolved dependencies, build type and parameters,
signer, verification policy, and target address/program.

## Source and build identity

Bind:

- repository commit/tag, submodules, vendored/generated sources;
- package locks, remappings, git dependencies, codegen inputs;
- compiler/toolchain/framework, optimizer, IR, runtime target;
- metadata settings, libraries, immutables, constructor arguments;
- factory child bytecode, salts, init code, clone implementations;
- Rust/SBF or Move compiler/runtime targets where relevant.

A movable tag, lockfile alone, or “similar bytecode” does not close identity.
For high-impact artifacts, use an independent controlled rebuild. When output
differs, localize toolchain, environment, timestamps/metadata, dependencies,
generated sources, linked values, and nondeterminism. Never normalize away an
unexplained difference.

## Artifact correspondence

For EVM, reconstruct standard-json inputs where possible and compare creation
and runtime bytecode while accounting for metadata, libraries, immutables, and
constructor data. Record exact-vs-partial match semantics and independently
fetch current on-chain code for high assurance.

Verification APIs are versioned dependencies. Pin endpoint and response
semantics; Sourcify's legacy v1 API was disabled on 2026-07-07, so current
tooling must validate v2 behavior rather than silently weakening exact-match or
proxy-resolution evidence.

For Solana, compare the controlled-build executable hash with the current
on-chain executable and bind program ID, loader, ProgramData, deployed slot,
and upgrade authority.

## Deployment and upgrade provenance

Trace the transaction that actually executed:

```text
deployer/factory or governance proposal
creation/implementation artifact and calldata
salt, libraries, constructor/init values
proxy/beacon/facet linkage
initializer/reinitializer/migration
role/ownership transfer
chain and block/slot
```

Treat every upgrade as a new release. Check storage-layout validation,
historical storage ownership/interpretation, initializer coupling, timelock
and emergency routes, one-chain/facet drift, unreviewed validation bypasses,
and whether source patches actually reached each funded deployment.

Use gas-aware differential tests when reconstructing historical storage
behavior so gas changes are not mistaken for semantic preservation or
divergence.

## Configuration and authority boundary

Artifact identity does not prove initialized state, roles, oracle/bridge/token
addresses, risk parameters, pause state, or current authority. Handoff those
facts to `configuration-space.md`.

Operational key security is in scope only through its on-chain authority
effect. Model multisig threshold, timelock, guardian/emergency path, release
signer, upgrade authority, and whether authority can be rotated or removed;
do not expand into generic enterprise IAM.

Generated ABI/IDL/SDK artifacts matter only when they alter signing, account
selection, call/instruction construction, message domains, or deployment
configuration and the on-chain system accepts the resulting unsafe action.

## Variant search

After a mismatch, search:

- every supported chain and funded legacy deployment;
- proxies, beacons, facets, clones, factories, and registries;
- canonical and emergency upgrade paths;
- release branches and generated artifacts;
- source, build, bytecode, storage, payload, and configuration diffs.

Send root-cause propagation to `variant-analysis.md`.

## Output and closure

Maintain `DEPLOYMENT_PROVENANCE`:

```text
source revision and dependency lock
build inputs/toolchain and reproducibility
attestation/authorization policy
expected and observed artifact digests
verification semantics
deployment/upgrade transaction
proxy/program linkage and authority
initializer/migration/configuration handoff
mismatches and residual uncertainty
```

Conclude which source produced which artifact, how that artifact reached the
exact target, what can still replace it, which initialization/configuration
was applied, and what remains unverified.

## Current semantic sources

- SLSA v1.2 provenance: https://slsa.dev/spec/v1.2/build-provenance
- Sigstore verification: https://docs.sigstore.dev/cosign/verifying/verify/
- Sourcify match/API semantics: https://docs.sourcify.dev/docs/api/
- OpenZeppelin upgrade rules: https://docs.openzeppelin.com/upgrades-plugins/writing-upgradeable
- Solana verified builds: https://solana.com/docs/programs/verified-builds
