# Performance Playbook

Load for latency, throughput, CPU, memory, I/O, allocation, startup time, or resource-efficiency work.

## Rule

Do not optimize an unmeasured bottleneck.

Define the performance contract first:

```text
operation/user journey
load and concurrency model
latency/throughput/resource objective
tail percentile and error budget
correctness/durability constraints
target hardware/runtime/environment
acceptable regression dimensions
```

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

Distinguish open-loop arrival rate from closed-loop client concurrency. A
closed-loop benchmark can reduce offered load while the system stalls and hide
user-visible latency.

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

Also record:

- tool/runtime/compiler and frequency/power settings;
- open/closed-loop generator and offered vs achieved load;
- sample count, confidence interval and outlier policy;
- p50/p95/p99/max rather than averages alone;
- GC/JIT/cache state and whether steady state was reached;
- saturation, queueing and errors/timeouts;
- profiler overhead and benchmark perturbation.

Guard against coordinated omission: if slow responses pause request generation
or sampling, correct the measurement or use an independent schedule. Report
both uncorrected and corrected distributions when useful.

Compare interleaved or randomized baseline/change runs when environmental drift
is material. A statistically detectable difference may still be operationally
irrelevant; define the minimum meaningful effect before measuring.

## Bottleneck Proof

Use profiles and resource telemetry to connect:

```text
workload → saturated resource/queue → causal code/path
→ proposed change → reduced bottleneck → end-to-end improvement
```

A microbenchmark improvement does not establish end-to-end benefit. Check for
bottleneck displacement, additional memory/CPU/I/O, tail regression, cold-start
cost, and degraded behavior under overload.

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

Before delivery rerun correctness tests under representative concurrency and
state, then verify the improvement in the deployment environment or state why
that evidence remains pending.

## Current semantic sources

- Google Benchmark guidance: https://google.github.io/benchmark/user_guide.html
- HdrHistogram and coordinated-omission correction:
  https://github.com/HdrHistogram/HdrHistogram
