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

Treat a canary as a bounded experiment with a comparable control. Define
allocation unit, population/traffic comparability, observation window,
expected baseline variation, minimum useful sample, contamination risks, and
guardrail metrics. A small canary may miss rare failures; a non-representative
canary may validate the wrong workload.

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

Separate rollout-controller progress from application correctness. Ready
replicas or a completed controller state do not establish request correctness,
data integrity, dependency compatibility, or business health.

Use an explicit state machine:

```text
PREPARED → EXPOSED → OBSERVING → PROMOTED
                       ├→ PAUSED
                       └→ ABORTED → RECOVERED
```

Promotion requires sufficient observation and all critical guardrails; absence
of alerts alone is not success. Preserve the exact artifact/config/feature-flag
identity for canary and control.

## Operational Gates

Before increasing exposure verify as applicable:

- capacity and `maxSurge`/unavailable resource headroom;
- dependency and mixed-version compatibility;
- schema/data migration phase and write compatibility;
- feature flag/config propagation and default behavior;
- queue/backlog and delayed asynchronous effects;
- regional/tenant/user concentration;
- error budget and cost impact;
- operator authority and stop/rollback mechanism.

## Rollback

Know whether rollback is actually safe.

Code rollback may not reverse:

- schema changes;
- destructive migrations;
- externally visible side effects;
- data-format transitions.

State irreversible effects explicitly.

After rollback, verify resulting artifact/configuration, service health, data
reconciliation, queue/event effects, caches, feature flags, and external side
effects. A rollback command's success is not recovery evidence.

Track delivery metrics per application/service and over time. Do not compare
unrelated systems as a leaderboard. Current DORA guidance distinguishes
throughput (lead time, deployment frequency, failed-deployment recovery) from
instability (change-fail and deployment-rework rates).

## Current operational sources

- Google SRE canarying: https://sre.google/workbook/canarying-releases/
- Kubernetes Deployment behavior:
  https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Argo Rollouts analysis:
  https://argo-rollouts.readthedocs.io/en/stable/features/analysis/
- Current DORA delivery metrics:
  https://dora.dev/guides/dora-metrics-four-keys/
