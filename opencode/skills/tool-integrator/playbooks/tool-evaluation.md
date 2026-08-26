# Tool Evaluation Playbook

Load when comparing concrete tools or measuring whether a tool materially
improves a workflow.

## Evaluation Contract

Freeze:

```text
workflow and decision owner
claim/tool capability being evaluated
candidate versions and configurations
representative task/fixture distribution
baseline without the candidate tool
oracle and error direction
resource, latency, monetary, context, privacy, and operational budgets
decision threshold and transfer boundary
```

Do not choose metrics merely because the candidate already reports them.

## Capability and Error Measurement

Measure dimensions separately where their consequences differ:

- target/relationship coverage;
- precision and false-positive burden;
- false-negative or omission behavior;
- result freshness after target changes;
- deterministic stability or trial variance;
- output/schema stability;
- time, CPU, memory, storage, network, and paid cost;
- model-context consumed and evidence retained;
- setup, update, failure recovery, and maintenance burden;
- data exposure and required privilege.

Use known-positive, known-negative, boundary, and unsupported cases. For
discovery/ranking tools, measure whether the relevant item is found early enough
to change the downstream decision, not merely whether any result is returned.

## Comparative Design

Hold causally relevant conditions constant:

```text
repository/task state
hardware/runtime
tool budget and timeout
index/cache warmness
configuration and plugins
network/provider state
oracle and aggregation
```

Separate cold-start, steady-state, and incremental performance when relevant.
Compare a simple built-in baseline; a new tool must justify its integration and
maintenance cost.

Do not use one scalar score to hide fatal differences. Use hard gates, a Pareto
comparison, or scenario-specific recommendations when tradeoffs conflict.

## Robustness and Transfer

Challenge candidates with:

- repository/language/framework variation;
- generated, dynamic, reflective, or configuration-driven behavior;
- stale indexes and partial updates;
- malformed input and partial failure;
- large output and timeout/cancellation;
- renamed/reordered but semantically equivalent cases;
- unavailable provider/network/credential;
- candidate-specific benchmark optimization.

Report what the fixture distribution omits. A benchmark on one repository does
not prove suitability on another.

## Verdict

Return:

```text
ADOPT          meets hard gates and adds material net value
CONDITIONAL    useful only for stated workflows/configurations
EXPERIMENT     evidence insufficient; next discriminator is defined
REJECT         fails a hard gate or is dominated
RETIRE         existing integration no longer justifies its cost/risk
```

Bind the verdict to exact versions, configuration, tasks, and date. Do not turn
producer benchmark claims into local observations.
