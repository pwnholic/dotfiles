# Runtime and Dependency Escalation Playbook

Load when the exploit hypothesis materially depends on behavior outside the top-level target source.

## Escalation Path

```text
application
→ framework
→ library
→ runtime / VM
→ database/storage
→ network/protocol semantics
```

## Verify Actual Behavior

When causal to the exploit:

1. identify the exact version/configuration;
2. inspect authoritative source or specification;
3. reproduce with a minimal controlled test;
4. compare expected and observed behavior.

Do not rely on:

- function names;
- comments;
- folklore;
- generic documentation for another version;
- "the library probably does X".

## Common Surfaces

- serializer/parser behavior;
- middleware ordering;
- transaction/isolation semantics;
- cache invalidation;
- queue delivery guarantees;
- VM/chain semantics;
- compiler transformations;
- standard-library behavior;
- RPC edge cases;
- token/bridge/oracle implementation details.

Dependency behavior that is necessary for the exploit must be evidence-backed.
