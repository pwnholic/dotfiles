# AGENTS.md

# Repository Agent Operating System

This file is the **top-level orchestration and task-routing instruction** for AI agents operating in this repository.

`AGENTS.md` does not contain the complete security-research or software-engineering methodology. Its primary responsibility is to determine **which specialized operating mode applies to the current task** and load the corresponding instruction file.

The specialized instruction files are located in the **same directory as this file**.

---

## 1. Instruction File Layout

The repository must maintain the following structure:

```text
<repository-root>/
├── AGENTS.md
├── SECURITY_RESEARCHER.md
└── SOFTWARE_ENGINEER.md
```

The specialized instruction files are therefore resolved relative to `AGENTS.md`:

```text
./SECURITY_RESEARCHER.md
./SOFTWARE_ENGINEER.md
```

Do not assume they exist inside another directory such as:

```text
.github/
docs/
security/
src/
agent/
agents/
.ai/
```

unless the repository explicitly defines another instruction hierarchy.

The three files form one instruction system:

```text
                         ┌─────────────────────┐
                         │      AGENTS.md      │
                         │  Task Router /      │
                         │  Orchestrator       │
                         └──────────┬──────────┘
                                    │
                     ┌──────────────┴──────────────┐
                     │                             │
                     ▼                             ▼
       ┌────────────────────────┐    ┌────────────────────────┐
       │ SECURITY_RESEARCHER.md │    │ SOFTWARE_ENGINEER.md   │
       │ Security Methodology   │    │ Engineering Methodology│
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

The selected mode determines which specialized instruction file(s) must be used.

---

# 3. Mode Selection

## MODE=SECURITY

Select:

```text
./SECURITY_RESEARCHER.md
```

when the primary objective is to discover, analyze, validate, reproduce, or reason about security weaknesses or attacker behavior.

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

Select:

```text
./SOFTWARE_ENGINEER.md
```

when the primary objective is to build, modify, maintain, debug, test, optimize, or improve software without security research being the primary objective.

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

Some tasks genuinely require both security research and software engineering.

Examples:

- discover a vulnerability and patch it
- audit code and implement the remediation
- develop an exploit and then write a regression test
- investigate an attack and modify the implementation
- harden a smart contract
- audit a protocol and implement mitigations
- reproduce a vulnerability and create a permanent test
- perform security analysis and subsequently refactor the vulnerable component

For these tasks, load both files:

```text
./SECURITY_RESEARCHER.md
./SOFTWARE_ENGINEER.md
```

Use the following precedence between the two specialized methodologies:

### During security discovery and validation

Use:

```text
SECURITY_RESEARCHER.md
```

as the primary methodology.

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

Use:

```text
SOFTWARE_ENGINEER.md
```

as the primary methodology.

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
→ MODE=ENGINEERING
```

```text
"Find a way to bypass the ERC-20 allowance invariant."
→ MODE=SECURITY
```

```text
"Audit this ERC-20 and patch anything exploitable."
→ MODE=BOTH
```

```text
"Refactor this Solidity contract."
→ MODE=ENGINEERING
```

```text
"Determine whether this Solidity implementation is exploitable."
→ MODE=SECURITY
```

```text
"Write a regression test for this authorization vulnerability."
→ MODE=BOTH
```

```text
"Optimize this transaction-processing pipeline."
→ MODE=ENGINEERING
```

```text
"Determine whether transaction ordering creates an economically exploitable state."
→ MODE=SECURITY
```

---

# 7. Security Objective Takes Precedence

When a task involves software development but its primary purpose is to understand or exploit security behavior, use:

```text
MODE=SECURITY
```

Do not allow normal engineering assumptions to suppress adversarial reasoning.

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

Never treat "already audited" as a reason to stop security investigation.

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

The objective is to understand **actual security properties**, not merely whether the source code looks correct.

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
Load the applicable specialized instruction file(s).

STEP 5
Read and follow their methodology.

STEP 6
Inspect repository-specific constraints.

STEP 7
Perform the task.

STEP 8
Validate the result according to the selected mode(s).
```

---

# 10. File Loading Rules

## Security Mode

When:

```text
MODE=SECURITY
```

load:

```text
./SECURITY_RESEARCHER.md
```

and treat it as the authoritative specialized methodology for security research.

---

## Engineering Mode

When:

```text
MODE=ENGINEERING
```

load:

```text
./SOFTWARE_ENGINEER.md
```

and treat it as the authoritative specialized methodology for software engineering.

---

## Both Mode

When:

```text
MODE=BOTH
```

load:

```text
./SECURITY_RESEARCHER.md
./SOFTWARE_ENGINEER.md
```

Apply each file to its respective domain.

---

# 11. Instruction Separation

The responsibilities of the three files must remain clearly separated.

## AGENTS.md

Responsible for:

- task classification
- mode selection
- orchestration
- instruction resolution
- instruction precedence
- security/engineering boundaries
- dual-mode behavior
- repository-level agent workflow

---

## SECURITY_RESEARCHER.md

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

## SOFTWARE_ENGINEER.md

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

Do not unnecessarily duplicate the contents of either specialized file inside `AGENTS.md`.

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
     MODE=SECURITY
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
    MODE=ENGINEERING
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
        MODE=BOTH
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

For such workflows, the agent must not switch entirely from security reasoning to engineering reasoning after discovering a vulnerability.

Instead:

```text
SECURITY_RESEARCHER.md
        ↓
Discovery
        ↓
Validation
        ↓
Root Cause
        │
        ▼
SOFTWARE_ENGINEER.md
        ↓
Patch
        ↓
Regression Test
        ↓
Quality Validation
        │
        ▼
SECURITY_RESEARCHER.md
        ↓
Re-assess Exploitability
        ↓
Confirm Mitigation
```

Both methodologies remain active across the lifecycle where necessary.

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

For security-related changes, also validate that the patch actually eliminates the underlying attack condition rather than merely hiding the observed symptom.

---

# 16. Validation

The validation strategy must match the selected mode.

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

Use whichever methods are appropriate to establish exploitability or non-exploitability.

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

Use the minimum sufficient validation required to establish correctness, while applying stronger validation when the change warrants it.

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

Security tasks must evaluate the system from an adversarial perspective.

---

# 18. Default Mode

When there is no meaningful security objective:

```text
MODE=ENGINEERING
```

When security is the primary purpose:

```text
MODE=SECURITY
```

When both security research and implementation are essential:

```text
MODE=BOTH
```

---

# 19. Final Operating Contract

The agent must follow this contract:

```text
1. Read AGENTS.md.

2. Locate:
   ./SECURITY_RESEARCHER.md
   ./SOFTWARE_ENGINEER.md

3. Classify the task:
   SECURITY
   ENGINEERING
   BOTH

4. Load the appropriate specialized instruction file(s).

5. Apply the specialized methodology.

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
     SECURITY_RESEARCHER.md   SOFTWARE_ENGINEER.md
                │                 │
                └────────┬────────┘
                         │
                         ▼
                    Agent Task
```

The files must remain siblings in the repository root:

```text
<repository-root>/
├── AGENTS.md
├── SECURITY_RESEARCHER.md
└── SOFTWARE_ENGINEER.md
```

`AGENTS.md` decides **which methodology applies**.

`SECURITY_RESEARCHER.md` defines **how security research is performed**.

`SOFTWARE_ENGINEER.md` defines **how software engineering is performed**.
