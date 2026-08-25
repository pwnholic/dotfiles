# Performance Playbook

Load for latency, throughput, CPU, memory, I/O, allocation, startup time, or resource-efficiency work.

## Rule

Do not optimize an unmeasured bottleneck.

## Loop

```text
representative workload
→ baseline
→ profile
→ isolate bottleneck
→ hypothesis
→ change
→ benchmark
→ correctness regression check
```

## Baseline

Capture relevant metrics:

- latency distribution;
- throughput;
- CPU;
- memory;
- allocations;
- I/O;
- query count;
- network calls;
- concurrency;
- startup time.

## Benchmark Quality

Record:

- workload;
- environment;
- dataset/state;
- warmup;
- repeated runs;
- variability;
- baseline;
- changed result.

Do not report percentage improvement without the measurement context.

## Preserve Semantics

Optimization must preserve:

- outputs;
- ordering;
- error behavior;
- durability;
- concurrency safety;
- compatibility;
- resource ownership.

A faster wrong result is not an optimization.
