# Distributed Systems Playbook

Load when correctness depends on multiple processes/services, queues, replicated state, asynchronous delivery, partial failure, or network behavior.

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

Do not call a distributed change correct because all individual services pass isolated unit tests.
