# Production Rollout Playbook

Load for deployment, production configuration, feature enablement, canary, staged rollout, or operationally consequential change.

## Before Rollout

Define:

- expected effect;
- blast radius;
- health signals;
- rollback path;
- data compatibility;
- observability;
- authorization;
- cost/risk constraints.

## Prefer Progressive Exposure

When supported and useful:

- feature flags;
- canary;
- staged rollout;
- partial traffic;
- shadow traffic;
- progressive region/user exposure.

## Closed-Loop Rollout

Do not stop at "deployed".

Use:

```text
deploy
→ observe explicit signals
→ compare against acceptance thresholds
→ continue OR rollback
```

Define measurable success and rollback triggers where practical.

Examples:

- error rate;
- latency;
- saturation;
- queue depth;
- invariant checks;
- data consistency;
- business-critical health signal.

## Rollback

Know whether rollback is actually safe.

Code rollback may not reverse:

- schema changes;
- destructive migrations;
- externally visible side effects;
- data-format transitions.

State irreversible effects explicitly.
