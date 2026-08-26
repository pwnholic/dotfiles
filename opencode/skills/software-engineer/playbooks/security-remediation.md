# Security Remediation Playbook

Load only after a security issue has a sufficiently established mechanism/root cause to enter implementation.

## Boundary

Do not replace exploit validation with engineering intuition.

The lifecycle is:

```text
security finding
→ root cause
→ remediation design
→ minimal fix
→ regression verification
→ security re-validation
```

Require a security handoff containing:

```text
violated property and protected asset
confirmed mechanism and affected variants
attacker starting capability and reachable preconditions
affected versions/configurations/deployments
reproduction and success predicate
impact, assumptions, blockers and evidence freshness
```

If the mechanism is not sufficiently established, return to security research
rather than designing from a severity label or scanner output.

## Fix the Security Property

Do not patch only the observed exploit trace if the root cause allows equivalent variants.

Identify:

- violated security property;
- faulty enforcement mechanism;
- required preserved behavior;
- affected variants;
- compatibility impact.

## Prioritization Signals

Keep separate:

```text
technical severity        CVSS-like intrinsic characteristics
exploit likelihood        EPSS/current threat evidence
known active exploitation KEV or equivalent observation
environment exposure      deployed reachability and asset/user impact
response decision         SSVC/organizational mission and safety context
remediation confidence    mechanism, fix and rollback evidence
```

No single score determines priority. Record vector/version, retrieval time,
target applicability, compensating controls, and changes that require
reassessment.

## Patch Completeness

Check:

- every equivalent entrypoint and variant;
- alternate encodings, error/fallback and retry paths;
- older supported branches and deployed artifacts;
- default and reachable configurations;
- persistent unsafe state, credentials, sessions, tokens or generated data;
- dependency/runtime versions that contain or bypass the fix;
- compatibility and availability impact of stricter enforcement.

Prefer the smallest coherent property repair. A denylist for one observed
payload is incomplete when the same mechanism accepts semantic variants.

## Regression Test

Where practical, encode the previously exploitable condition so that:

```text
old vulnerable behavior → test fails
fixed behavior          → test passes
```

Also preserve legitimate behavior.

Use causal witnesses:

```text
vulnerable version + reachable setup → security predicate fails
fixed version + same setup          → predicate holds
fix removed/weakened                → regression test fails
legitimate boundary cases           → remain supported
```

Do not preserve an unsafe behavior merely because existing tests encode it.

## Operational Mitigation and Rollout

When an immediate code fix cannot be safely deployed, distinguish temporary
mitigation from remediation. Bind mitigation owner, scope, bypass conditions,
monitoring, expiry, and removal trigger. Coordinate credential rotation,
session/token invalidation, data repair, dependency updates, configuration,
rollout and disclosure only within authorization.

## Handoff Back

After implementation, return to the `onchain-security-researcher` methodology
for adversarial re-validation when the target is on-chain. For other security
domains, use the appropriate authorized specialist rather than applying an
on-chain model by analogy.

A passing unit test does not prove exploitability is closed.

Return the exact diff/artifact, regression witnesses, compatibility result,
deployment/configuration scope, residual variants, mitigation state, and
unresolved assumptions for adversarial re-validation.

## Current prioritization sources

- NIST SSDF 1.1: https://csrc.nist.gov/pubs/sp/800/218/final
- CVSS v4.0: https://www.first.org/cvss/v4.0/specification-document
- EPSS: https://www.first.org/epss/
- CISA SSVC:
  https://www.cisa.gov/stakeholder-specific-vulnerability-categorization-ssvc
- CISA Known Exploited Vulnerabilities:
  https://www.cisa.gov/known-exploited-vulnerabilities-catalog
