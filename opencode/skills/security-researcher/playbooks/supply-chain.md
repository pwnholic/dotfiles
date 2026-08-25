# Security Supply-Chain Playbook

Load when dependencies, build infrastructure, artifacts, provenance, package identity, or release process are part of the attack surface.

## Model

Security may depend on:

```text
source identity
→ dependency identity
→ build environment
→ build process
→ generated artifact
→ publication
→ deployment
```

## Questions

- Is the dependency/source origin authentic?
- Are lockfiles/hashes/digests enforced?
- Are generated artifacts reproducible or provenance-backed?
- Can CI/build identities be abused?
- Can release artifacts differ from reviewed source?
- Are attestations/signatures verified?
- Are SBOM/provenance claims tied to the artifact actually deployed?

## Evidence

When the environment uses SLSA/provenance/attestations, treat them as evidence with scope—not as magical guarantees.

Inspect:

- source provenance;
- build provenance;
- artifact digest;
- builder identity;
- SBOM;
- test/security attestations;
- signing/verification workflow.

## Boundary

Do not assume every engagement authorizes active interference with real CI, registries, repositories, or release infrastructure.
