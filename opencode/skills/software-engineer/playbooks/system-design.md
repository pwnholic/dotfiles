# System Design Playbook

Load when the requested deliverable is an implementation-ready architecture for
a new system, subsystem, service, or material redesign. Do not load it for a
small local code change whose contracts and structure are already clear.

## Boundary and Ownership

This playbook owns the architecture decision set, concern-to-view traceability,
and implementation handoff. It does not own:

- open-ended option discovery before commitment—use `brainstorming`;
- distributed execution semantics—load `distributed-systems.md` when causal;
- test verdicts—use `verification.md`;
- persistent-state transition completeness—use `migrations.md`;
- deployed-state claims—use `production-rollout.md`;
- attacker-oriented validation—use the matching security specialist when one
  exists.

Architecture is not a diagram or technology list. Produce a bounded set of
decisions connecting stakeholder outcomes and constraints to components,
interfaces, state, deployment, operations, and evidence.

## Proportional Depth

Start with the least complex design capable of satisfying known requirements.
Escalate only when a requirement, measured constraint, failure domain, or
evolution path demands it.

```text
simple/local
→ boundary + contracts + state + failures + verification

multi-component
→ add ownership + interaction + deployment + operability views

distributed/stateful/high-risk
→ add explicit consistency, capacity, failure, recovery, migration,
  rollout, and assurance models through matching playbooks
```

Simple does not mean undocumented. Complex does not justify speculative
components, generic microservices, premature replication, or arbitrary future
scale.

## Design Inputs

Establish only inputs that can change architectural decisions:

```text
stakeholders and observable outcomes
scope, environment, non-goals, and system boundary
functional flows and critical user/operational journeys
architecturally significant quality requirements
legal, policy, compatibility, technology, staffing, and cost constraints
current system/dependencies for brownfield work
load shape, data lifetime, growth horizon, and failure assumptions
decision horizon and required deliverable
```

Do not convert “fast,” “scalable,” “reliable,” “secure,” or “simple” directly
into architecture. Turn a material quality requirement into a scenario:

```text
source/stimulus | environment | affected artifact
expected response | measurable response threshold | evidence method
```

Treat thresholds supplied without provenance as assumptions until validated.
Avoid demanding precise estimates when a range or sensitivity boundary is the
stronger honest input.

## Architecture Drivers

Prioritize the small set of requirements that materially shape structure:

- critical functional flows;
- safety, correctness, privacy, or trust boundaries;
- latency, throughput, availability, durability, and recovery targets;
- consistency, ordering, and concurrency requirements;
- change frequency and compatibility obligations;
- cost, staffing, operational, and delivery constraints.

Separate hard constraints from preferences. Record conflicts instead of hiding
them in one score. A target that does not affect a decision is not currently an
architecture driver.

## Iterative Design Loop

```text
select the highest-leverage unresolved driver
→ propose the simplest coherent mechanism
→ allocate responsibilities and ownership
→ define interfaces, state, and deployment consequences
→ stress with quality scenarios and failure cases
→ quantify feasibility where causal
→ compare a material alternative or counterfactual
→ record decision, assumption, tradeoff, and evidence gap
→ repeat only while unresolved drivers can change the design
```

Begin with a design that works in principle. Add distribution, caching,
replication, asynchronous processing, partitioning, or regional redundancy only
after identifying the threshold or failure mode it addresses and the new
complexity it creates.

## Minimum Useful Views

Choose views by stakeholder concern; do not create every diagram by default.

Possible views:

```text
context       actors, external systems, trust and ownership boundaries
functional    responsibilities, components, and dependency direction
runtime       critical flows, protocols, ordering, timeout, and failure behavior
data/state    source of truth, schema, lifecycle, consistency, retention
deployment    processes, nodes, zones/regions, networks, configuration
operations    health, observability, scaling, recovery, maintenance ownership
evolution     compatibility, migration, rollout, deprecation, reversibility
```

For every included view state the concern it answers. Reconcile identities and
boundaries across views; conflicting diagrams are unresolved design evidence.

## Interface, Data, and Ownership Contracts

For each material boundary define:

```text
responsibility and owner
input/output/schema and versioning
authorization and data classification
state owner and transaction/durability boundary
error, timeout, cancellation, retry, and idempotency behavior
ordering/concurrency assumptions
resource limits and backpressure
observability and support responsibility
compatibility and deprecation path
```

Keep one authoritative owner for mutable state unless an explicitly modeled
consistency protocol says otherwise. A cache, search index, replica, event log,
and database are not interchangeable sources of truth.

## Concrete Feasibility

Quantify only dimensions that can invalidate or reorder designs:

```text
steady, peak, burst, and growth rates
object/event/request sizes and retention
read/write amplification
latency budget across critical path
CPU, memory, storage, network, connection, and concurrency limits
availability, durability, RTO, and RPO targets
unit and operational cost range
```

Show units, assumptions, sensitivity, headroom, and bottleneck. Prefer an
order-of-magnitude range over fabricated precision. Validate uncertain causal
numbers with a benchmark, prototype, trace, or provider/runtime evidence before
making an irreversible choice.

## Failure, Recovery, and Operations

At minimum ask:

- What fails, how is it detected, and what user-visible behavior follows?
- Which state may be lost, duplicated, delayed, stale, or corrupted?
- Can the system degrade safely rather than fail completely?
- How is recovery initiated, verified, and stopped if harmful?
- Who operates the system and what recurring toil does the design create?
- Can it be deployed, observed, migrated, and rolled back with available skills?

When correctness depends on queues, replicas, asynchronous messages, partial
failure, network behavior, or multiple writers, load `distributed-systems.md`.
Do not summarize those semantics as “eventually consistent” or “exactly once.”

## Trust and Protection

Identify protected assets, actors, trust zones, exposed interfaces, privileged
operations, secrets, sensitive data flows, isolation boundaries, audit needs,
and fail-safe behavior. Trace material protection requirements into interfaces,
components, deployment, and verification.

This is design evidence, not an exploitability verdict or claim that the system
is secure. Route attacker-oriented on-chain validation to
`onchain-security-researcher`; state the specialist gap for unsupported security
domains.

## Decisions and Alternatives

Record only decisions whose rationale will matter during implementation,
operation, or evolution:

```text
status and decision owner
context and driving requirements
chosen mechanism
material alternatives considered
rationale and evidence
tradeoffs and consequences
assumptions and invalidation trigger
affected interfaces/artifacts
review or replacement condition
```

Do not create an ADR for every local implementation choice. Do not let an ADR
freeze a decision after its assumptions change.

## Architecture Challenge

Before handoff, challenge the design:

1. trace every material driver to a decision and evidence plan;
2. find components or complexity with no active driver;
3. test critical flows under boundary and failure scenarios;
4. attack the most consequential capacity and dependency assumptions;
5. compare the simplest credible alternative;
6. inspect quality tradeoffs, including operational and organizational cost;
7. identify irreversible choices and create an earlier discriminator;
8. verify that migration, rollout, recovery, and ownership are plausible.

Use a formal multi-stakeholder tradeoff review only when risk and decision cost
justify it. A lightweight review is sufficient for a small reversible system.

## Handoff and Completion

Return the smallest coherent implementation package:

```text
DESIGN_BRIEF              outcomes, scope, constraints, drivers, non-goals
ARCHITECTURE_VIEWS        only views required by stakeholder concerns
INTERFACE_AND_DATA_CONTRACTS
DECISION_RECORDS          material choices, alternatives, consequences
ASSUMPTION_RISK_LEDGER    evidence, owner, discriminator, reopen condition
DELIVERY_EVIDENCE_PLAN    implementation slices, verification, migration,
                          rollout, observability, recovery
```

The design is ready for implementation when critical flows and boundaries are
coherent, material drivers trace to decisions, serious alternatives were
challenged, causal feasibility assumptions have evidence plans, and remaining
uncertainty is explicit. Do not claim the architecture is optimal, future-proof,
scalable, reliable, or secure beyond the requirements and evidence evaluated.
