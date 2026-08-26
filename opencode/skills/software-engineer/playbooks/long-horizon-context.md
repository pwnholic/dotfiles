# Long-Horizon Context Playbook

Load for long-running tasks, many-file changes, many tool calls, multi-stage work, or tasks likely to survive interruptions.

## Objective

Prevent context explosion, semantic drift, repeated work, and stale conclusions.

Use the shared core's stable task semantics, working set, and evidence ledger.
This playbook adds milestone checkpoints, loop detection, and resume
reconciliation; it does not duplicate those shared structures.

Maintain one additional invalidation map when the dependency graph is complex:

```text
claim/evidence → source revision, config, dependency, environment or artifact
```

When one binding changes, invalidate dependent evidence without discarding
unaffected work.

## Checkpoints

Create a logical checkpoint after meaningful milestones:

```text
milestone
→ summarize state
→ mark stale evidence
→ update next actions
```

A checkpoint must enable another agent/session to continue without redoing completed investigation.

Checkpoint contents:

```text
objective/scope/non-goals
current repository and environment state
decisions with rationale
changed files and behavioral ownership
verified, failed, stale and unverified claims
active blocker and reopen condition
exact next discriminator or implementation step
```

## Progress and Loop Detection

Treat repeated searches, edits, test reruns, or tool failures as a loop when
they add no new evidence. Before another attempt, state what new information it
can produce. On a plateau:

1. preserve the current diff and evidence;
2. identify whether the blocker is strategy, environment, oracle, or context;
3. change the discriminator or narrow the problem;
4. restart from a clean reasoning context only when durable state is captured;
5. inspect, apply, or discard the prior diff explicitly.

Fail-fast/restart strategies are method leads, not universal policy: false
positives can terminate a trajectory that would succeed.

## Resume Contract

On resume, re-check current repository state before trusting old working-set details.

Reconcile the checkpoint against current files, dependencies, generated
artifacts, running processes, and prior verification freshness before writing.
