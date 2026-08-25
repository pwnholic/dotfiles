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

Conceptually distinguish:

```text
source provenance
build provenance
artifact identity
test attestations
vulnerability-scan attestations
SBOM
signatures
```

Use project-standard SLSA/provenance mechanisms when present.

Do not invent a provenance system when the repository has none unless the task explicitly asks for one.

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

## Release Correspondence

Where relevant establish:

```text
expected source revision
→ expected build inputs
→ produced artifact digest
→ published artifact
```

Do not treat a successful package upload as proof that the intended source produced the artifact.
