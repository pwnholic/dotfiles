# Long-Horizon Context Playbook

Load for long-running tasks, many-file changes, many tool calls, multi-stage work, or tasks likely to survive interruptions.

## Objective

Prevent context explosion, semantic drift, repeated work, and stale conclusions.

## Three-Layer State

### Stable Task Semantics

Keep durable:

- requirement;
- scope;
- non-goals;
- acceptance criteria;
- invariants;
- compatibility constraints;
- safety boundaries.

### Working Set

Keep current:

- active files/components;
- current design;
- current hypothesis;
- immediate next steps;
- current blockers.

### Evidence Ledger

Track:

- verified claims;
- evidence source;
- environment/state;
- stale evidence;
- blocked checks;
- unresolved uncertainty.

## Compaction Rule

When context grows:

1. discard redundant narration;
2. summarize completed branches;
3. preserve decisions with their rationale;
4. preserve blockers and negative evidence;
5. preserve unresolved contradictions;
6. preserve exact completion state.

Never compact away the conditions that determine correctness or safety.

## Checkpoints

Create a logical checkpoint after meaningful milestones:

```text
milestone
→ summarize state
→ mark stale evidence
→ update next actions
```

A checkpoint must enable another agent/session to continue without redoing completed investigation.

## Resume Contract

On resume, re-check current repository state before trusting old working-set details.
