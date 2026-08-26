# Installation and Lifecycle Playbook

Load when installing, configuring, registering, exposing, updating, disabling,
uninstalling, or retiring a CLI/MCP tool.

## Preflight

Bind:

```text
requested capability and users
target machine/repository/account/platform
installation scope: project, user, system, container, CI, or remote
package/artifact identity, version, source, integrity/provenance
runtime and dependency changes
files/config/hooks/instructions/services/credentials to be created or changed
network/data/cost behavior
rollback and ownership
```

Inspect existing configuration and unrelated user state. Prefer project-local or
user-scoped, version-pinned, reversible integration when equivalent.

## Preview and Authority

Use supported dry-run/plan modes and explicit targets where available. A dry run
is evidence about declared intent, not proof of every actual write.

Separate authorization for:

```text
package installation or update
dependency/runtime installation
configuration mutation
instruction/skill/hook injection
MCP exposure and tool allowlist
credential creation/access
daemon/watcher/service startup
external registration or paid provider use
```

Do not use auto-confirm flags until the exact plan and authority are established.

## Apply and Observe

After each material change:

1. inspect resulting files/config/registrations/processes;
2. verify the exact version and executable/server selected;
3. confirm only intended tool capabilities are exposed;
4. run a harmless health or known fixture check;
5. inspect network/data behavior where causal;
6. record rollback artifacts and remaining state.

Do not report installation success from the package-manager exit code alone.

## Update

Before updating, identify adapter claims affected by version, dependency,
configuration, schema, command, output, or side-effect changes. Preserve the old
working version or recovery method when risk justifies it.

After update, recalibrate affected commands before relying on prior evidence.
Do not use a changelog as the only verification of new behavior.

## Disable, Uninstall, and Retire

Resolve exact tool-owned state before removal:

```text
binary/package and dependencies
project/user/system configuration
MCP registrations and allowlists
generated instructions, skills, hooks, and reports
indexes, caches, databases, logs, and credentials
daemons/watchers/services and remote resources
```

Preview deletion when supported. Remove only owned targets, preserve unrelated
configuration, and state whether data is recoverable. Verify the tool is no
longer active/exposed and disclose retained state.

## Completion

Return exact installed/configured identity, observed state changes, capability
exposure, calibration status, data/network implications, rollback procedure,
and update/retirement trigger.
