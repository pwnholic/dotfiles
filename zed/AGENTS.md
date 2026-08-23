# AGENTS.md

## Purpose

This file is the **top-level task router and operating policy** for AI agents working in this repository.

Do not treat this file as the complete engineering or security methodology.

Instead, determine which operational mode applies to the current task and load the corresponding instruction file:

- `SECURITY_RESEARCHER.md` — security research, vulnerability discovery, exploit analysis, threat modeling, adversarial analysis, smart-contract security, protocol analysis, bug bounty research, and security validation.
- `SOFTWARE_ENGINEER.md` — software development, implementation, refactoring, debugging, testing, architecture, performance, maintainability, developer tooling, and ordinary engineering tasks.

The agent must select the appropriate mode **before performing substantive work**.

---

## 1. Instruction Priority

Instruction resolution order:

1. System and platform instructions
2. Repository-level instructions with higher precedence, if explicitly applicable
3. `AGENTS.md`
4. Selected operational mode:
   - `SECURITY_RESEARCHER.md`
   - `SOFTWARE_ENGINEER.md`

5. Task-specific instructions from the user

When two instruction sources conflict, follow the higher-priority source.

Never silently ignore a relevant instruction file.

---

## 2. Task Classification

Before acting, classify the user's request into one of these modes:

### `SECURITY`

Use:

```text
SECURITY_RESEARCHER.md
```

when the primary objective is to discover, analyze, validate, exploit, reproduce, or reason about security weaknesses.

Typical signals include:

- vulnerability research
- bug bounty
- exploit development
- smart-contract security
- protocol security
- adversarial analysis
- threat modeling
- attack-surface analysis
- privilege escalation
- authentication or authorization flaws
- cryptographic misuse
- economic/security invariants
- MEV/security analysis
- state-machine attacks
- cross-contract or cross-component attacks
- trust-boundary analysis
- invariant violations
- exploitability analysis
- postmortem/root-cause security analysis
- finding bugs that are intentionally difficult to detect
- analyzing behavior beyond obvious source-code weaknesses

The security mode applies even when the task also requires coding.

---

### `ENGINEERING`

Use:

```text
SOFTWARE_ENGINEER.md
```

when the primary objective is to build, modify, maintain, test, debug, or improve software.

Typical signals include:

- implementing a feature
- fixing an ordinary bug
- refactoring
- API design
- architecture
- code review for maintainability/correctness
- testing
- CI/CD
- build systems
- dependency management
- performance optimization
- developer tooling
- documentation
- code generation
- migrations
- database changes
- observability
- reliability engineering

The engineering mode applies when security is not the primary objective.

---

## 3. Dual-Mode Tasks

Some tasks legitimately require both modes.

Examples:

- implementing a security fix
- writing an exploit reproducer and then patching it
- hardening a smart contract
- auditing a feature and modifying the vulnerable implementation
- researching a vulnerability and building a regression test
- analyzing a protocol and then implementing mitigations

For these tasks:

1. Load `SECURITY_RESEARCHER.md`
2. Load `SOFTWARE_ENGINEER.md`
3. Treat `SECURITY_RESEARCHER.md` as the primary reasoning methodology for identifying and validating the security issue.
4. Treat `SOFTWARE_ENGINEER.md` as the primary methodology for implementation, testing, maintainability, and code quality.
5. Do not let engineering assumptions suppress adversarial security reasoning.

Conceptually:

```text
              ┌──────────────────────┐
              │      User Task       │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Classify Objective  │
              └──────────┬───────────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
              ▼          ▼          ▼
          SECURITY    ENGINEERING   BOTH
              │          │          │
              ▼          ▼          ▼
     SECURITY_...  SOFTWARE_...   BOTH FILES
```

---

## 4. Primary Objective Rule

Classify the task according to its **primary objective**, not merely the technologies involved.

For example:

- "Implement an ERC-20 token" → `ENGINEERING`
- "Find a way to bypass the ERC-20 allowance invariant" → `SECURITY`
- "Audit this ERC-20 and patch the vulnerability" → `BOTH`
- "Refactor this Solidity code" → `ENGINEERING`
- "Determine whether this Solidity implementation is exploitable" → `SECURITY`
- "Write a regression test for a discovered authorization bug" → `BOTH`
- "Optimize a transaction-processing pipeline" → `ENGINEERING`
- "Determine whether transaction ordering permits an economically exploitable state" → `SECURITY`

Do not classify solely from keywords such as `Solidity`, `security`, `audit`, `Docker`, `Rust`, or `API`.

Reason about the actual objective.

---

## 5. Security Takes Precedence During Security Analysis

When a task contains both engineering and security concerns, do not prematurely constrain the investigation to normal developer assumptions.

Security analysis must consider:

- unexpected state transitions
- attacker-controlled inputs
- privilege boundaries
- trust assumptions
- cross-component interactions
- race conditions
- TOCTOU conditions
- economic incentives
- oracle manipulation
- initialization and upgrade paths
- replay and ordering behavior
- denial-of-service conditions
- dependency behavior
- configuration-dependent behavior
- external system assumptions
- protocol invariants
- emergent behavior across components
- discrepancies between intended and actual behavior
- discrepancies between off-chain and on-chain behavior
- behavior that cannot be identified through simple source inspection alone

The presence of extensive audits, tests, formal verification, or hardened code does not automatically imply that the system is secure.

---

## 6. Mode Loading Rule

The agent should conceptually resolve instructions as:

```text
AGENTS.md
   │
   ├── Security objective?
   │       └── Load SECURITY_RESEARCHER.md
   │
   ├── Engineering objective?
   │       └── Load SOFTWARE_ENGINEER.md
   │
   └── Both?
           ├── Load SECURITY_RESEARCHER.md
           └── Load SOFTWARE_ENGINEER.md
```

When the files exist, their contents are authoritative for their respective domains.

Do not duplicate their detailed methodologies inside this file unless necessary for routing.

---

## 7. Ambiguous Tasks

If the objective cannot be classified confidently from the request, inspect the repository context and task wording before acting.

Use the following decision rule:

```text
Is the agent primarily being asked to
discover or reason about attacker behavior?
        │
       YES ──> SECURITY
        │
       NO
        │
        ▼
Is the agent primarily being asked to
build, modify, debug, test, or maintain software?
        │
       YES ──> ENGINEERING
        │
       NO
        │
        ▼
Use the closest applicable mode and explicitly state
the chosen operating mode internally before proceeding.
```

Do not ask unnecessary clarification questions when repository context is sufficient to determine the mode.

---

## 8. Execution Discipline

Before making substantive changes:

1. Identify the task objective.
2. Select the operating mode.
3. Load the applicable instruction file(s).
4. Understand repository-specific constraints.
5. Perform the task.
6. Validate the result according to the selected mode(s).

The agent must not:

- assume `AGENTS.md` is the only instruction source
- ignore a relevant mode file
- mix security and engineering methodologies carelessly
- perform implementation-first reasoning when security analysis is the actual objective
- reduce a security investigation to static code reading alone when the task requires behavioral or adversarial analysis

---

## 9. Final Mode Declaration

For internal task control, classify every substantive task as exactly one of:

```text
MODE=SECURITY
MODE=ENGINEERING
MODE=BOTH
```

This classification determines which instruction files are applicable.

Examples:

```text
MODE=SECURITY
→ SECURITY_RESEARCHER.md
```

```text
MODE=ENGINEERING
→ SOFTWARE_ENGINEER.md
```

```text
MODE=BOTH
→ SECURITY_RESEARCHER.md
→ SOFTWARE_ENGINEER.md
```

---

## 10. Separation of Responsibilities

Keep the three files conceptually separate:

### AGENTS.md

Responsible for:

- task classification
- mode selection
- instruction precedence
- orchestration
- security/engineering boundaries
- dual-mode behavior

### SECURITY_RESEARCHER.md

Responsible for:

- security methodology
- adversarial reasoning
- vulnerability discovery
- exploit analysis
- threat modeling
- security validation
- attack-surface methodology
- protocol and smart-contract security methodology

### SOFTWARE_ENGINEER.md

Responsible for:

- implementation methodology
- architecture
- coding standards
- testing
- debugging
- refactoring
- reliability
- performance
- maintainability
- engineering quality

Do not turn `AGENTS.md` into a second copy of either specialized file.

---

## 11. Repository Integrity

The agent should preserve this hierarchy:

```text
AGENTS.md
│
├── routes work
│
├── SECURITY_RESEARCHER.md
│     └── defines security methodology
│
└── SOFTWARE_ENGINEER.md
      └── defines engineering methodology
```

When improving one specialized methodology, modify the corresponding specialized file rather than unnecessarily expanding `AGENTS.md`.

---

## 12. Default

When no security objective exists:

```text
MODE=ENGINEERING
```

When security research is explicitly or implicitly the primary objective:

```text
MODE=SECURITY
```

When the task requires both adversarial security analysis and software implementation:

```text
MODE=BOTH
```

The goal is to ensure that the agent always uses the **smallest correct instruction set necessary for the task**, while still activating both methodologies when the task genuinely spans security and engineering.
