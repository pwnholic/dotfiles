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

## Orchestrator Duties

The root agent must:

- synthesize evidence;
- detect duplicated work;
- detect stale assumptions;
- resolve behavioral conflicts;
- review delegated diffs;
- rerun verification invalidated by later changes.

A sub-agent report is evidence, not completion.
