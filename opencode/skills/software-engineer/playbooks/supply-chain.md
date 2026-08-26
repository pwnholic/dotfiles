# Software Supply-Chain Playbook

Load for dependency upgrades, package/release work, build systems, CI provenance, artifact publication, SBOM, signing, or high-assurance delivery.

## Dependency Identity

Check when relevant:

- exact version;
- lockfile state;
- transitive dependencies;
- source origin;
- hashes/digests;
- build inputs;
- generated artifacts.

## Provenance

For high-assurance build/release workflows, inspect available provenance and attestations.

Distinguish independent claims:

```text
REPRODUCIBLE same declared inputs can produce the artifact
ATTESTED     an identified builder signed a statement
AUTHORIZED  policy permits the builder, inputs and output
INVENTORIED  an SBOM describes components/relationships
PUBLISHED    the digest exists in the intended registry/channel
DEPLOYED     that exact digest is active in the target environment
```

None implies the next. Use project-standard SLSA/provenance mechanisms when
present.

Do not invent a provenance system when the repository has none unless the task explicitly asks for one.

Verify attestations against artifact digest, signer/workload identity, trusted
root, source/material digests, build type/parameters, and an explicit policy.
Presence of a signature or bundle is not verification. For offline
verification, record trusted-root freshness and revocation limitations.

## SBOM, Vulnerability and VEX Semantics

Bind the SBOM format/version, subject artifact, generation stage/tool, component
identity, dependency relationships, completeness limits, and signature. An
SBOM is inventory evidence, not proof that a component is reachable,
exploitable, tested, or safe.

VEX or embedded vulnerability status must bind product/artifact identity,
vulnerability, status (`affected`, `not_affected`, `fixed`,
`under_investigation`), justification, evidence, author and update time.
Re-evaluate when the artifact, configuration, threat evidence, or dependency
graph changes.

## Dependency Changes

Evaluate:

- API/ABI changes;
- release notes;
- transitive changes;
- license;
- build/runtime impact;
- security implications;
- performance;
- reproducibility.

Test the project after resolving the new dependency graph, not only the direct
package. Check lockfile consistency, removed/added transitives, install/build
scripts, platform artifacts, minimum runtime/toolchain, generated code,
licenses, vulnerability applicability, and rollback.

## Release Correspondence

Where relevant establish:

```text
expected source revision
→ expected build inputs
→ produced artifact digest
→ published artifact
```

Do not treat a successful package upload as proof that the intended source produced the artifact.

Extend correspondence where risk warrants:

```text
source revision and materials
→ isolated/reproducible build
→ artifact digest
→ verified attestations and SBOM
→ authorized publication
→ consumer/deployment digest
```

## Current semantic sources

- SLSA v1.2: https://slsa.dev/spec/v1.2/
- SPDX 3.0.1: https://github.com/spdx/spdx-spec/releases/tag/3.0.1
- CycloneDX 1.7: https://cyclonedx.org/specification/overview/
- Sigstore attestation verification:
  https://docs.sigstore.dev/cosign/verifying/attestation/
- CISA minimum VEX requirements:
  https://www.cisa.gov/resources-tools/resources/minimum-requirements-vulnerability-exploitability-exchange-vex

Re-check current versions before relying on them in a new release.
