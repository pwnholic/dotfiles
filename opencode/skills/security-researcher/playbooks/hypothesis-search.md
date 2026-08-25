# Hypothesis Search Playbook

Load for broad vulnerability discovery.

## Start From Properties

Ask:

- what must never happen?
- what asset is protected?
- what mechanism enforces the property?
- what does the system trust but not control?

## Hypothesis Transformations

### Invert an assumption

```text
"X is trusted"
→ what if X is attacker-influenced?
```

### Change order

```text
A → B
→ B → A
```

### Repeat

```text
A
→ A → A → A
```

### Delay

Immediate behavior may differ under asynchronous execution.

### Change context

Replay or reuse the same state/message under another domain, chain, account, caller, or lifecycle phase.

### Remove a required primitive

If the leading attack needs oracle manipulation, search for the same impact without it.

### Add composition

Combine individually legitimate components/actions.

### Move layers

If application logic looks safe, inspect the assumption supplied by framework/runtime/library/database/network behavior.

## Path Ledger

Use:

```text
OPEN
ACTIVE
PROMISING
BLOCKED
EXHAUSTED
CONFIRMED
REJECTED
```

Blocked paths require a concrete blocker and a reopen condition.

Exhausted paths require documented coverage, not merely "nothing found".
