# Multi-Agent Engineering Playbook

Load only when multiple agents/workers are actually useful.

## Default

Prefer one behavioral owner.

Parallelism is conditional, not inherently superior.

## Good Parallel Work

- read-only repository exploration;
- environment reproduction;
- test/oracle construction;
- compatibility analysis;
- isolated modules with disjoint write ownership;
- independent review;
- independent verification.

Run genuinely independent assignments concurrently. Sequence work when one
worker's output defines another worker's contract, migration order, shared
interface, or acceptance oracle.

## Risky Parallel Work

Avoid parallel agents that:

- edit the same file;
- change the same public interface;
- make competing architectural decisions;
- depend heavily on one another's unfinished outputs.

## Assignment Contract

Every worker receives:

```text
MISSION
DEFINITION OF DONE
READ SCOPE
WRITE SCOPE
OUT OF SCOPE
KNOWN CONSTRAINTS
REQUIRED VERIFICATION
EXPECTED OUTPUT
```

## Shared Workspace Rules

- Inspect current state before writing.
- Never revert another agent's work.
- Keep write ownership disjoint where possible.
- Report conflicts immediately.
- Mechanical conflicts may be resolved mechanically.
- Behavioral/design conflicts return to the orchestrator.

Maintain a lightweight ownership graph:

```text
behavior/interface → owner
file/module → writer
shared assumption → evidence owner
verification claim → independent checker
```

Shared files can reduce repeated messages when they are the natural contract;
they add overhead when file boundaries already communicate the work. Choose
the coordination channel from task topology rather than team size alone.

## Orchestrator Duties

The root agent must:

- synthesize evidence;
- detect duplicated work;
- detect stale assumptions;
- resolve behavioral conflicts;
- review delegated diffs;
- rerun verification invalidated by later changes.

Run synthesis after material evidence, a shared-assumption change, conflict,
worker completion, or integration failure. Reprioritize or redirect work, but
record what the previous assignment established so coverage is not lost.

## Independent Integration Gate

Before accepting delegated work:

```text
inspect actual diff and resulting state
check scope and ownership
reconcile interface/behavior assumptions
run claim-capable verification
challenge high-risk changes with an independent oracle
```

Do not expose hidden tests, grading artifacts, secrets, or irrelevant workspace
data to improve an agent's success. Evaluation evidence must come from
authorized project artifacts and observable behavior.

A sub-agent report is evidence, not completion.
