# Variant Analysis Playbook

Load after a root cause or concrete mechanism is established.

## Goal

Search for sibling instances of the same underlying flaw.

Do not search only for identical syntax.

Abstract the root cause:

```text
security property
+ missing/incorrect enforcement
+ reachable condition
```

Then search for equivalent forms across:

- sibling functions/contracts/services;
- copied helpers;
- alternate adapters;
- chain-specific implementations;
- duplicated authorization patterns;
- serializers/parsers;
- proxy/upgrade paths;
- shared libraries;
- other deployment variants.

## Historical Material

After first-principles discovery is established, history, patches, CVEs, prior audit reports, and version diffs may be used for:

- variant analysis;
- affected-version analysis;
- incomplete-fix detection;
- regression identification.

Label provenance honestly:

```text
independent discovery
history-assisted variant
patch-derived lead
```

Do not present patch archaeology as independent discovery.

## Patch Completeness

When analyzing a remediation, ask whether it fixed:

- only the reported path;
- the full root cause;
- sibling variants;
- alternate configurations;
- equivalent dependency paths.
