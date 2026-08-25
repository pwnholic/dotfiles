# Hardened Target Playbook

Load for heavily audited, mature, widely reviewed, or high-assurance targets.

## Doctrine

The disappearance of obvious bugs changes where remaining bugs are likely to hide.

Do not abandon local analysis, but deliberately increase attention to:

- composition;
- trust boundaries;
- cross-component assumptions;
- sequence/timing;
- state-machine reachability;
- external dependencies;
- configuration variants;
- economic behavior;
- upgrade/governance paths;
- off-chain infrastructure.

## Anti-Convergence

Maintain a portfolio of materially different hypotheses.

Example:

```text
authorization
state-machine
oracle/accounting
economic composition
cross-protocol
runtime/dependency
configuration-specific
governance/upgrade
```

Do not send all researchers down the first promising path.

## Negative Evidence

Record why a path failed.

A failed attempt should answer:

- what assumption held?
- what blocker prevented exploitation?
- how strong is that blocker?
- what evidence would reopen the path?

Hardened-target research improves when failure information is retained.
