# AGENTS.md

# Repository Agent Operating System

This file is the **top-level task-classification and skill-invocation instruction** for AI agents operating in this repository.

`AGENTS.md` does not contain the complete security-research or software-engineering methodology. Its only responsibility is to determine **which specialized operating mode applies to the current task** and **invoke the corresponding skill** for it — never to read or reconstruct that methodology itself, and never to fall back to a plain sibling instruction file.

---

## 1. Skill Availability

The two specialized methodologies are packaged as skills, not as files to locate and read:

```text
security-researcher   — adversarial / vulnerability-discovery methodology
software-engineer     — construction / maintenance methodology
```

Before substantive work, confirm both are available (e.g. via the agent's skill listing or skill tool). If a skill is not available in the current environment, say so explicitly rather than silently reconstructing its methodology from memory or from this file — this file is a router, not a substitute for the skill it routes to.

```text
                         ┌─────────────────────┐
                         │      AGENTS.md      │
                         │  Task Router /      │
                         │  Skill Invoker      │
                         └──────────┬──────────┘
                                    │
                     ┌──────────────┴──────────────┐
                     │                             │
                     ▼                             ▼
       ┌────────────────────────┐    ┌────────────────────────┐
       │  security-researcher   │    │   software-engineer    │
       │  (skill)               │    │   (skill)              │
       └────────────────────────┘    └────────────────────────┘
```

---

# 2. Core Responsibility

Before performing substantive work, the agent must determine the **primary objective of the task**.

The agent must classify the task into exactly one of:

```text
MODE=SECURITY
MODE=ENGINEERING
MODE=BOTH
```

The selected mode determines which specialized skill(s) must be invoked.

---

# 3. Mode Selection

## MODE=SECURITY

Invoke the **`security-researcher` skill** when the primary objective is to discover, analyze, validate, reproduce, or reason about security weaknesses or attacker behavior.

Examples include:

- vulnerability research
- bug bounty research
- exploit analysis
- exploit development
- smart-contract security
- blockchain protocol security
- DeFi security
- protocol attack-surface analysis
- adversarial analysis
- threat modeling
- privilege escalation analysis
- authorization bypass analysis
- authentication attacks
- cryptographic misuse
- race-condition analysis
- TOCTOU analysis
- state-machine attacks
- cross-contract attacks
- cross-component attacks
- trust-boundary analysis
- oracle manipulation
- replay attacks
- transaction-ordering attacks
- economic attacks
- MEV-related security analysis
- denial-of-service analysis
- invariant violations
- security-sensitive dependency analysis
- upgradeability attacks
- initialization attacks
- governance attacks
- exploitability analysis
- root-cause analysis of security vulnerabilities
- investigating behavior that may not be visible from straightforward source inspection
- finding vulnerabilities in systems that are already audited or heavily hardened

Security mode applies whenever the primary purpose is **attacker-oriented understanding** of the system.

---

# 4. MODE=ENGINEERING

Invoke the **`software-engineer` skill** when the primary objective is to build, modify, maintain, debug, test, optimize, or improve software without security research being the primary objective.

Examples include:

- implementing features
- fixing ordinary bugs
- refactoring
- API implementation
- API design
- architecture
- code organization
- test development
- unit testing
- integration testing
- end-to-end testing
- CI/CD
- build systems
- dependency management
- package management
- database migrations
- performance optimization
- developer tooling
- observability
- reliability
- maintainability
- documentation
- code generation
- infrastructure changes
- deployment automation
- ordinary debugging

Engineering mode applies when the primary objective is **software construction or maintenance**.

---

# 5. MODE=BOTH

Some tasks genuinely require both methodologies.

Examples:

- discover a vulnerability and patch it
- audit code and implement the remediation
- develop an exploit and then write a regression test
- investigate an attack and modify the implementation
- harden a smart contract
- audit a protocol and implement mitigations
- reproduce a vulnerability and create a permanent test
- perform security analysis and subsequently refactor the vulnerable component

For these tasks, invoke both skills — **in sequence, not simultaneously as a blend**. Auto-triggering alone doesn't guarantee this sequence; state explicitly which skill is active at each stage.

### During security discovery and validation

Invoke the **`security-researcher` skill** as the active methodology.

The agent must prioritize:

- attacker capabilities
- threat models
- attack surfaces
- trust boundaries
- invariants
- exploitability
- unintended behavior
- state transitions
- economic incentives
- cross-component interactions

### During implementation and remediation

Invoke the **`software-engineer` skill** as the active methodology.

The agent must prioritize:

- correctness
- maintainability
- architecture
- testing
- regression prevention
- readability
- reliability
- performance
- integration quality

Security reasoning must continue during implementation. Engineering constraints must never be used as a reason to prematurely dismiss a potentially exploitable security condition.

---

# 6. Primary Objective Rule

Classification must be based on the **actual objective of the task**, not merely on technologies or keywords.

Do not classify a task based solely on words such as:

```text
security
audit
Solidity
Rust
smart contract
API
backend
Docker
cryptography
```

Instead determine what the user is actually trying to accomplish.

Examples:

```text
"Implement an ERC-20 token."
→ MODE=ENGINEERING → invoke software-engineer
```

```text
"Find a way to bypass the ERC-20 allowance invariant."
→ MODE=SECURITY → invoke security-researcher
```

```text
"Audit this ERC-20 and patch anything exploitable."
→ MODE=BOTH → invoke security-researcher, then software-engineer, then security-researcher
```

```text
"Refactor this Solidity contract."
→ MODE=ENGINEERING → invoke software-engineer
```

```text
"Determine whether this Solidity implementation is exploitable."
→ MODE=SECURITY → invoke security-researcher
```

```text
"Write a regression test for this authorization vulnerability."
→ MODE=BOTH → invoke security-researcher, then software-engineer
```

```text
"Optimize this transaction-processing pipeline."
→ MODE=ENGINEERING → invoke software-engineer
```

```text
"Determine whether transaction ordering creates an economically exploitable state."
→ MODE=SECURITY → invoke security-researcher
```

---

# 7. Security Objective Takes Precedence

When a task involves software development but its primary purpose is to understand or exploit security behavior, invoke:

```text
security-researcher
```

Do not allow normal engineering assumptions to suppress adversarial reasoning, and do not substitute the engineering skill's methodology for the security skill's methodology just because the task involves reading or writing code.

For security-related tasks, the agent must consider that the intended behavior of the system may differ from its actual behavior.

Security investigation may require reasoning about:

- attacker-controlled inputs
- malicious users
- malicious contracts
- compromised dependencies
- unexpected state transitions
- privilege boundaries
- authorization boundaries
- trust assumptions
- hidden state
- race conditions
- transaction ordering
- timing
- initialization
- upgrade paths
- configuration
- deployment state
- dependency behavior
- external protocols
- external services
- off-chain/on-chain inconsistencies
- economic incentives
- protocol composition
- emergent behavior
- invariant violations
- discrepancies between specification and implementation
- discrepancies between implementation and deployed behavior

The existence of:

- audits
- formal verification
- extensive tests
- static-analysis tooling
- hardened architecture
- security reviews
- bug bounty programs

does **not** constitute proof that a system is secure.

Never treat "already audited" as a reason to stop security investigation, and never treat it as a reason to skip invoking the `security-researcher` skill.

---

# 8. Behavioral Security Rule

For security tasks, do not automatically restrict investigation to superficial source-code inspection.

When appropriate, reason across multiple layers:

```text
Specification
      ↓
Architecture
      ↓
Source Code
      ↓
Compiler / Build Behavior
      ↓
Runtime Behavior
      ↓
Dependencies
      ↓
Deployment Configuration
      ↓
On-chain / Production State
      ↓
External Systems
      ↓
Economic / Adversarial Behavior
```

The objective is to understand **actual security properties**, not merely whether the source code looks correct. This layered reasoning is the `security-researcher` skill's job once invoked — this file's job is only to make sure it gets invoked when it should.

---

# 9. Mode Resolution Procedure

Before substantive work, perform the following procedure:

```text
STEP 1
Understand the user's actual objective.

STEP 2
Determine whether the objective is primarily:
    Security
    Engineering
    Both

STEP 3
Select:
    MODE=SECURITY
    MODE=ENGINEERING
    MODE=BOTH

STEP 4
Invoke the applicable specialized skill(s) — never substitute this file's
own summary of their methodology for actually invoking them.

STEP 5
Follow the invoked skill's methodology.

STEP 6
Inspect repository-specific constraints.

STEP 7
Perform the task.

STEP 8
Validate the result according to the selected mode(s), per the invoked
skill(s)' own validation guidance.
```

---

# 10. Skill Invocation Rules

## Security Mode

When:

```text
MODE=SECURITY
```

invoke:

```text
security-researcher
```

and treat it as the authoritative specialized methodology for security research for the remainder of the task.

---

## Engineering Mode

When:

```text
MODE=ENGINEERING
```

invoke:

```text
software-engineer
```

and treat it as the authoritative specialized methodology for software engineering for the remainder of the task.

---

## Both Mode

When:

```text
MODE=BOTH
```

invoke both, in the sequence given in §13 — not simultaneously, and not by blending both methodologies into one undifferentiated pass. State which skill is currently active at each stage of the task.

---

# 11. Responsibility Separation

The responsibilities of the router and the two skills must remain clearly separated.

## AGENTS.md (this file)

Responsible for:

- task classification
- mode selection
- skill invocation
- invocation precedence and sequencing
- security/engineering boundaries
- dual-mode orchestration
- repository-level agent workflow

---

## `security-researcher` skill

Responsible for:

- security methodology
- adversarial reasoning
- vulnerability discovery
- exploit reasoning
- threat modeling
- attack-surface analysis
- security validation
- security testing
- protocol security
- smart-contract security
- bug bounty methodology
- attacker modeling
- security-specific research workflows

---

## `software-engineer` skill

Responsible for:

- software development methodology
- implementation
- architecture
- debugging
- testing
- refactoring
- performance
- maintainability
- reliability
- engineering standards
- developer tooling
- code quality

Do not unnecessarily duplicate the contents of either skill inside `AGENTS.md`. If a skill isn't available in the current environment, say so and ask before improvising its methodology from memory — this file routes to the skills, it doesn't stand in for them.

`AGENTS.md` should remain the **router**, not become a third giant methodology document.

---

# 12. Ambiguous Tasks

When task classification is ambiguous, inspect the task wording and repository context before deciding.

Use this decision tree:

```text
Is the primary objective to understand,
discover, validate, or exploit attacker behavior?
            │
           YES
            │
            ▼
     MODE=SECURITY → invoke security-researcher
            │
           NO
            │
            ▼
Is the primary objective to build,
modify, debug, test, or maintain software?
            │
           YES
            │
            ▼
    MODE=ENGINEERING → invoke software-engineer
            │
           NO
            │
            ▼
Does the task explicitly require
both security investigation and implementation?
            │
           YES
            │
            ▼
        MODE=BOTH → invoke both, per §13's sequence
```

If repository context makes the answer obvious, do not ask the user unnecessary clarification questions.

Make the best-supported classification from the available evidence.

---

# 13. Security Research Followed by Engineering

A common workflow is:

```text
Discover
   ↓
Understand
   ↓
Validate
   ↓
Exploit / Reproduce
   ↓
Root Cause
   ↓
Patch
   ↓
Regression Test
   ↓
Validate Patch
```

For such workflows, the agent must not switch entirely from security reasoning to engineering reasoning after discovering a vulnerability, and must not treat a single skill invocation as covering the whole lifecycle.

Instead, invoke in this sequence:

```text
security-researcher (skill)
        ↓
Discovery
        ↓
Validation
        ↓
Root Cause
        │
        ▼
software-engineer (skill)
        ↓
Patch
        ↓
Regression Test
        ↓
Quality Validation
        │
        ▼
security-researcher (skill)
        ↓
Re-assess Exploitability
        ↓
Confirm Mitigation
```

Both skills remain relevant across the lifecycle where necessary — invoking one doesn't retire the other for the rest of the task. This is the sequencing native skill auto-triggering doesn't guarantee on its own, which is the entire reason this router file states it explicitly.

---

# 14. Repository Context

Before making repository changes, inspect the relevant context.

Depending on the task, this may include:

- repository structure
- source files
- tests
- configuration
- dependencies
- build system
- CI configuration
- deployment configuration
- documentation
- generated code
- contracts
- scripts
- infrastructure
- runtime configuration
- repository-specific instructions

Do not assume that a single file represents the complete behavior of the system.

---

# 15. Change Discipline

When modifying the repository:

- preserve existing functionality unless intentionally changing it
- minimize unrelated changes
- avoid unnecessary rewrites
- maintain consistency with the existing architecture
- update tests when behavior changes
- preserve security invariants
- validate changes against the task objective
- avoid introducing unrelated dependencies
- avoid silently changing configuration semantics

For security-related changes, also validate that the patch actually eliminates the underlying attack condition rather than merely hiding the observed symptom — this is the `security-researcher` skill's re-assessment step in §13, not something to skip because the `software-engineer` skill's tests pass.

---

# 16. Validation

The validation strategy must match the selected mode, per the invoked skill's own validation guidance.

## Security

Validation may include:

- exploit reproduction
- adversarial test cases
- invariant validation
- state-transition analysis
- boundary testing
- negative testing
- fuzzing
- property-based testing
- differential testing
- runtime verification
- deployment-state inspection
- protocol interaction testing
- economic reasoning

Use whichever methods the `security-researcher` skill identifies as appropriate to establish exploitability or non-exploitability.

---

## Engineering

Validation may include:

- unit tests
- integration tests
- end-to-end tests
- type checking
- compilation
- linting
- formatting
- static analysis
- benchmarks
- compatibility checks
- build verification
- regression testing

Use the minimum sufficient validation the `software-engineer` skill identifies as required to establish correctness, while applying stronger validation when the change warrants it.

---

## Both

For `MODE=BOTH`, validate:

```text
Security correctness
        +
Implementation correctness
        +
Regression resistance
```

---

# 17. Do Not Confuse "Code Correctness" With "System Security"

A program may be:

- well-written
- type-safe
- tested
- audited
- formally verified
- standards-compliant
- maintainable

and still contain a security vulnerability caused by:

- incorrect assumptions
- protocol composition
- unexpected state transitions
- economic incentives
- integration behavior
- external dependencies
- deployment configuration
- privilege interactions
- timing
- ordering
- cross-component effects
- emergent system behavior

Therefore:

```text
Implementation Correctness ≠ Security Correctness
```

Security tasks must invoke `security-researcher` and evaluate the system from an adversarial perspective — a clean pass from `software-engineer`'s validation guidance is not a substitute.

---

# 18. Default Mode

When there is no meaningful security objective:

```text
MODE=ENGINEERING → invoke software-engineer
```

When security is the primary purpose:

```text
MODE=SECURITY → invoke security-researcher
```

When both security research and implementation are essential:

```text
MODE=BOTH → invoke both, per §13
```

---

# 19. Final Operating Contract

The agent must follow this contract:

```text
1. Read AGENTS.md.

2. Confirm availability of:
   security-researcher (skill)
   software-engineer (skill)

3. Classify the task:
   SECURITY
   ENGINEERING
   BOTH

4. Invoke the appropriate skill(s) — do not read a sibling instruction
   file, and do not reconstruct their methodology from memory.

5. Follow the invoked skill's methodology.

6. Execute the task using repository context.

7. Validate the result.

8. For security-sensitive work, verify the actual security property,
   not merely the apparent correctness of the implementation.
```

The intended hierarchy is:

```text
                     AGENTS.md
                         │
                ┌────────┴────────┐
                │                 │
                ▼                 ▼
     security-researcher     software-engineer
        (skill)                 (skill)
                │                 │
                └────────┬────────┘
                         │
                         ▼
                    Agent Task
```

Unlike a file-based router, this doesn't depend on a fixed directory layout or sibling files staying co-located — skills are discovered by the agent's own skill mechanism, wherever they're installed.

`AGENTS.md` decides **which methodology applies, and in what order**.

`security-researcher` defines **how security research is performed**.

`software-engineer` defines **how software engineering is performed**.
