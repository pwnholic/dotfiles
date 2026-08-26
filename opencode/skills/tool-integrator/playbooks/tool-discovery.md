# Tool Discovery Playbook

Load for an unfamiliar CLI or MCP server when identity, capability, behavior,
or suitability must be reconstructed before maintained use.

## Discovery Order

Use the least invasive evidence first:

```text
resolve executable/server identity
→ version and package metadata
→ top-level help / tools-list schema
→ relevant subcommand/tool help
→ version-pinned official docs or source
→ isolated runtime probes
→ state and data-flow observation
```

Do not run install, init, build, update, login, register, daemon, watch, serve,
uninstall, cleanup, or similarly stateful commands merely to discover what they
do. Inspect help/source first and request appropriate authority if calibration
requires them.

## Identity Record

Capture:

```text
command/server name
resolved binary/package/server endpoint
version probe and observed version
installation mechanism and package ecosystem
canonical producer/source/documentation
artifact integrity/provenance evidence
runtime and dependency environment
license/maintenance/support information when causal
```

Names can be shadowed by PATH, wrappers, aliases, containers, plugins, or
remote servers. Resolve the artifact actually invoked.

## Capability Reconstruction

Inventory only capabilities relevant to the workflow. For each command/tool:

```text
inputs and target resolution
outputs and schema/stability
state read and state written
network/external entities contacted
credentials/privilege required
idempotency/retry/timeout/cancellation
partial failure and recovery
evidence claims supported and excluded
```

Treat help/docs as producer claims until observed. For MCP, inspect input and
output schemas, annotations, task support, list-change behavior, authentication,
and the subset of tools actually exposed.

## Safe Calibration

Use an isolated temporary repository, fixture, test account, local endpoint, or
mock only when it preserves the semantics being tested. Record divergences from
the intended environment.

For a safe probe:

1. snapshot relevant filesystem/config/process/network state;
2. invoke with explicit bounded target and timeout;
3. capture stdout, stderr, exit/result status, and structured output;
4. inspect files, config, processes, network, and remote state afterward;
5. repeat only when idempotency or nondeterminism matters;
6. clean up only tool-owned isolated state.

An exit status of zero does not establish the advertised outcome. An error can
still leave partial state.

## Triage Result

Classify:

```text
ADAPT_NOW      causal capability demonstrated and recurring use justified
ONE_OFF        safe bounded use is enough; maintained adapter has low value
CALIBRATE_MORE a material semantic or risk claim remains unknown
QUARANTINE     provenance, side effect, data exposure, or reliability is unacceptable
REJECT         cannot satisfy the required capability or hard constraints
```

Return the evidence behind the classification and the cheapest discriminator
for unresolved material questions.
