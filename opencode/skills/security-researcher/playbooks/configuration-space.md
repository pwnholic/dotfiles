# Configuration-Space Playbook

Load when behavior varies by deployment, build flags, feature flags, chain, mode, environment, or dependency features.

## Security Property May Be Configuration-Specific

Model:

```text
source
+ build options
+ runtime configuration
+ deployment topology
+ dependency feature set
= actual security behavior
```

## Relevant Dimensions

Depending on system:

- compile-time features;
- environment variables;
- proxy/upgrade mode;
- chain/network;
- token mode;
- legacy compatibility;
- authentication mode;
- storage backend;
- oracle source;
- bridge adapter;
- dependency version/features;
- admin/governance configuration.

## Search Strategy

Do not enumerate every theoretical combination.

Prioritize configurations that are:

- commonly deployed;
- security-sensitive;
- materially different in control/data flow;
- historically supported;
- externally selectable;
- likely to weaken enforcement.

## Evidence

Record the exact configuration for every exploit reproduction.

A finding in configuration A is not automatically a finding in configuration B.
