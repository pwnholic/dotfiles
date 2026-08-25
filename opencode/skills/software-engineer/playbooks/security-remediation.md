# Security Remediation Playbook

Load only after a security issue has a sufficiently established mechanism/root cause to enter implementation.

## Boundary

Do not replace exploit validation with engineering intuition.

The lifecycle is:

```text
security finding
→ root cause
→ remediation design
→ minimal fix
→ regression verification
→ security re-validation
```

## Fix the Security Property

Do not patch only the observed exploit trace if the root cause allows equivalent variants.

Identify:

- violated security property;
- faulty enforcement mechanism;
- required preserved behavior;
- affected variants;
- compatibility impact.

## Regression Test

Where practical, encode the previously exploitable condition so that:

```text
old vulnerable behavior → test fails
fixed behavior          → test passes
```

Also preserve legitimate behavior.

## Handoff Back

After implementation, return to the `security-researcher` methodology for adversarial re-validation.

A passing unit test does not prove exploitability is closed.
