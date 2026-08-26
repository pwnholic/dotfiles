# Tool Orchestration Playbook

Load when several tools are candidates or participants in one workflow.

## Orchestration Graph

Model tools as stateful evidence-producing nodes:

```text
tool/invocation
inputs and provenance
state read/written
output and consumer
claim observed
failure/timeout/cancellation
authority and exposure
```

Draw edges for data, state, ordering, or authority dependencies. A list of tools
is not an orchestration plan.

## Portfolio Design

For each pair classify:

```text
COMPLEMENTARY | INDEPENDENT | CORRELATED | REDUNDANT | DEPENDENT | CONFLICTING
```

Use complementary tools when distinct required claims need distinct oracles.
Use independent tools to challenge consequential results when their mechanisms
are genuinely different. Remove redundant tools that add only output volume or
ceremonial agreement.

Record shared parsers, indexes, language servers, model providers, rule sets,
fixtures, source databases, and generated artifacts. Shared upstream state can
make apparently separate tools fail together.

## Execution Plan

Sequence when:

- one tool produces or refreshes another's input;
- calls mutate shared target/config/index state;
- credentials, ports, files, locks, rate limits, or resources conflict;
- later calls depend on a successful resulting-state check;
- failure requires rollback, cancellation, or operator choice.

Parallelize only bounded read-only operations that do not contend for state and
whose combined outputs can be reconciled without hiding provenance.

For large intermediate outputs, perform deterministic filtering/aggregation
outside model context when possible. Preserve pointers or raw artifacts needed
to reproduce material conclusions.

## Failure and Contradiction

Define per edge:

```text
timeout and retry budget
idempotency assumption
partial-output handling
stale-state detection
fallback and its semantic loss
cancellation/cleanup
```

Do not silently fall back to a weaker tool and preserve the original claim.

When results disagree:

1. bind versions, target state, configuration, and timestamps;
2. compare what property each tool actually observes;
3. inspect shared assumptions and freshness;
4. run the cheapest stronger discriminator;
5. keep unresolved contradiction in the evidence ledger.

Never average incompatible findings into consensus.

## Completion

Return the orchestration graph, minimal tool portfolio, execution ordering,
state/authority boundaries, correlation register, conflict policy, output
reduction plan, and recovery/stop conditions.
