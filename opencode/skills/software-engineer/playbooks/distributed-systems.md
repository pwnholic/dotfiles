# Distributed Systems Playbook

Load when correctness depends on multiple processes/services, queues, replicated state, asynchronous delivery, partial failure, or network behavior.

`system-design.md` owns the overall architecture. This playbook owns the
correctness and failure semantics of distributed edges and returns those
constraints to the design.

## Model

Do not reason only about happy-path request/response.

Model:

```text
state
+ message
+ timing
+ failure
+ retry
+ duplicate
+ reordering
+ partial visibility
```

Record an operation history where correctness is contested:

```text
operation/request id
actor and intent
invocation and response time
input/output/error
state or message version
retry/duplicate lineage
observed commit/visibility point
```

State the required safety and liveness properties. Names such as “strong
consistency” or “exactly once” are insufficient without the scope, history,
failure model, and boundary across which they hold.

## Questions

- What happens if a message is duplicated?
- What happens if it is delayed?
- What happens if responses arrive out of order?
- Is retry idempotent?
- What happens after timeout when the remote side actually succeeded?
- Can state diverge between cache/source-of-truth/replica?
- What happens under process restart?
- What is the consistency model?
- What are the transaction boundaries?
- What is the delivery guarantee: at-most-once, at-least-once, effectively-once?
- What happens during partial dependency failure?
- What is the backpressure behavior?
- Can retries amplify an outage?

## Retry and Idempotency Contract

For a retriable mutation bind:

```text
caller identity and intent
idempotency-key scope and generation
atomicity of key recording with side effects
retention/expiry and reuse behavior
semantic response on duplicate
late-arriving retry after deletion or state change
downstream side effects outside the transaction
```

Identical parameters do not necessarily mean identical intent. Prefer an
explicit caller-provided request identifier where the API contract supports
it. A timeout is an unknown outcome until reconciled.

Budget retries across layers. Define retryable errors, attempt/deadline limit,
exponential backoff, jitter, cancellation, circuit/load shedding, and
backpressure. Uncoordinated retries can multiply load during partial failure.

## Verification

Where relevant test:

- duplicate delivery;
- delayed delivery;
- reordering;
- retry after uncertain outcome;
- dependency timeout;
- partial outage;
- process restart;
- stale replica/cache;
- concurrent updates.

Add faults at semantic boundaries:

- loss, duplication, corruption, delay and reordering;
- crash before/after durable write or acknowledgement;
- partition, asymmetric reachability and clock discontinuity;
- stale cache/replica, leader change and recovery;
- disk/full resource pressure and slow—not only failed—dependencies.

Prefer deterministic or seeded simulation for deep failure schedules when the
system supports it. Preserve the seed/history and minimize while retaining the
violated property. Complement simulation with real-runtime integration tests
because the simulator is itself a model.

Use correlated traces, logs, metrics and operation IDs to reconstruct causal
history; telemetry alone is not the consistency oracle.

Do not call a distributed change correct because all individual services pass isolated unit tests.

## Current semantic sources

- Jepsen consistency models: https://jepsen.io/consistency
- FoundationDB deterministic simulation:
  https://apple.github.io/foundationdb/testing.html
- AWS idempotent API design:
  https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/
- Kafka delivery semantics:
  https://docs.confluent.io/kafka/design/delivery-semantics.html
