# Variant Analysis Playbook

Load after a concrete root cause, historical finding, incident mechanism, or
patch exists and the task is to find semantic siblings, affected
versions/deployments, or incomplete remediation.

## Entry gate

Calibrate the seed before searching:

```text
violated property
precise root cause
missing/incorrect enforcement
attacker primitive and capability
reachable trigger state/sequence
source/sink and state/value effect
known affected identity/configuration
patch or mitigation, if any
provenance
```

If only symptom or impact is known, return to hypothesis search. Searching too
early overfits wording and produces noisy analogies.

## Semantic fingerprint

Create a fingerprint independent of names:

```text
resource/authority protected
trusted identity or data origin
required check and where it should dominate
representation/unit/domain conversion
state/history precondition
attacker-controlled edge
effect and success predicate
failure/retry/temporal behavior
```

Include stable structural facts, variable semantic facts, and target-specific
facts separately. Variants may share the first two while differing completely
in syntax.

## Abstraction ladder

Search from high precision to broad semantics:

1. exact symbol/string/selector;
2. structural/AST shape;
3. API or modifier semantics;
4. data flow from attacker-controlled source to protected sink;
5. control-flow/dominance of the required check;
6. lifecycle/state-machine pattern;
7. invariant negation and equivalent attacker primitive.

Do not jump directly from one seed to a universal abstraction. At each level
inspect false positives and missed near-neighbors, then decide whether to
broaden or specialize.

## Search dimensions

Search across:

- sibling functions, overloads, internal helpers, fallback/receive;
- routers, adapters, hooks, modules, libraries, generated code;
- proxy, beacon, facets, clones, factories, implementations;
- old/new branches, forks, vendored copies, package versions;
- every chain, market, token, oracle, bridge, EntryPoint, and runtime;
- initialization, upgrade, migration, pause, retry, and emergency paths;
- source, bytecode, storage layout, deployment payload, and configuration;
- call/message counterparts on destination domains;
- legacy funded or still-approved deployments.

Search where the bug was introduced and propagated, not only where it was
fixed.

## Query calibration

Maintain a labeled sample:

```text
positive seed
known semantic sibling
near miss with one critical difference
benign negative
unknown candidates sampled across topologies
```

For each query or detector record which fingerprint elements it represents,
expected blind spots, result counts, reviewed sample, false positives, and
known misses. Iterate:

```text
query → label sample → explain errors → refine abstraction
→ rerun → preserve versioned query and evidence
```

Do not report precision/recall beyond the labeled sample. A quiet query does
not close the search space.

## Candidate triage

Record:

```text
candidate identity and lineage
matched fingerprint elements
missing/different elements
reachable actor/state/configuration
protected resource and effect
production exposure
evidence level
next discriminator
```

Rank by semantic match, reachability, exposure, and information gain—not
lexical similarity. Merge only identical mechanisms/properties; retain
separate variants when configuration, attacker, or impact changes.

## Reachability decomposition

Avoid one vague `reachable` flag:

```text
code/artifact reachable
entrypoint/message reachable
attacker input/capability reachable
required state/history reachable
configuration/deployment reachable
runtime/dependency semantic reachable
economic realization reachable
```

A source copy that is undeployed may be a latent variant; a deployed copy with
no attacker path may be blocked. Preserve the distinction and reopen
conditions.

## History and persistent authority

Build lineage:

```text
introduction commit/release
→ branches/forks/packages
→ deployments/upgrades
→ patch and backports
→ current funded/approved state
```

Patch deployment does not erase persistent state. Search old approvals,
delegations, signatures, modules, storage, queued messages/withdrawals,
mis-minted claims, cached oracle data, and compromised configuration that may
remain exploitable after code changes.

Label discovery provenance honestly. Historical material can guide variants
after the mechanism exists; it cannot be presented as independent discovery.

Do not use git history, changelogs, CVE/incident databases, prior reports, or
patched-version diffs to shortcut first-principles discovery. Once the seed
mechanism is independently established or explicitly supplied as historical,
these sources may be used for semantic variants, introduction/propagation,
affected versions, persistent exposure, and patch completeness. Preserve that
provenance in every resulting candidate.

## Patch completeness: triple gate

A remediation is complete only if all three pass:

### Semantic gate

The root cause is removed for every equivalent source/sink, identity
representation, state transition, and failure path.

### Propagation gate

The fix reaches all affected branches, packages, generated artifacts, proxies,
facets, markets, chains, and legacy deployments.

### State/authority gate

Unsafe persistent state, approvals, delegations, roles, messages, claims, and
configuration are migrated, revoked, bounded, or otherwise made harmless.

Also test patch bypass: alternate entrypoint, reordered check, callback,
different encoding/domain, old implementation, partial migration, downgrade,
or unsafe configuration.

## Dynamic confirmation

Static similarity creates candidates. Validate high-priority variants with the
smallest discriminator, then a target-specific reproduction using the ordinary
attacker model and exact deployment/configuration. Differentially test
vulnerable vs patched and sibling vs seed where equivalence is assumed.

Send concrete variants to `exploit-validation.md`; do not invent a weaker
validation standard here.

## Coverage and closure

Report:

```text
seed and semantic fingerprint
abstraction levels and query versions used
repositories/branches/deployments/configurations searched
labeled calibration sample and known query blind spots
confirmed, latent, blocked, false-positive candidates
affected version/deployment intervals
patch triple-gate result
unsearched topology and reopen conditions
```

Closure means the declared semantic transformations and propagation surfaces
were searched with recorded limitations. It never means no other variant
exists.
