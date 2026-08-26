---
tool: code-review-graph
kind: cli-mcp
adapter-version: 1
tested-version: 2.3.8
version-probe: code-review-graph --version
calibrated: 2026-08-26
calibration-level: observed-partial
canonical-source: https://github.com/tirth8205/code-review-graph
---

# Tool Adapter: code-review-graph

Persistent incremental source-structure graph exposed through CLI and MCP.
This adapter binds the locally installed `2.3.8` artifact and selected producer
documentation retrieved on the calibration date.

## Use When

Use as contextual or proxy evidence for:

- architecture and community reconstruction in an existing codebase;
- callers, callees, imports, inheritors, children, and test relationships;
- execution-flow discovery recorded by the graph;
- changed-file impact and blast-radius prioritization;
- candidate dead code, large functions, and graph-backed refactor previews;
- bounded structural context retrieval for coding or validation agents;
- evaluating the graph's own retrieval, flow, impact, build, or token-efficiency
  behavior through its benchmark command.

Prefer direct source search for trivial one-hop questions or small repositories
where graph state and maintenance add no decision value.

## Do Not Use As

Do not treat this tool alone as proof of:

- runtime behavior, dynamic dispatch, reflection, configuration-driven edges,
  external-service behavior, or deployed state;
- semantic correctness, test adequacy, compatibility, migration completeness,
  security, exploit reachability, or impact;
- safe deletion merely because `dead-code` reports no callers/tests;
- complete blast radius merely because `impact` or `detect-changes` is short;
- independent confirmation when another tool consumes the same parser/graph;
- current source state when graph freshness has not been checked;
- agent-result validity merely because `code-review-graph eval` passes.

Do not use `--churn` as a shortcut for first-principles on-chain vulnerability
discovery. It explicitly incorporates git history and is only a prioritization
signal where history use is permitted.

## Identity and Freshness

Observed locally on 2026-08-26:

```text
resolved command: /home/pwnholic/.local/bin/code-review-graph
resolved target:  /home/pwnholic/.local/share/uv/tools/code-review-graph/bin/code-review-graph
installation:     uv tool
distribution:     code-review-graph 2.3.8
entry points:     code-review-graph, crg-daemon
repository:       https://github.com/tirth8205/code-review-graph
```

Before relying on the adapter:

```bash
command -v code-review-graph
code-review-graph --version
code-review-graph status --repo /absolute/repository/path
```

The adapter matches only when version output is `code-review-graph 2.3.8` and
the resolved artifact is the intended installation. `status` is a graph-state
observation; inspect whether the registered/indexed repository and statistics
correspond to the target.

Use `update --brief` after a rebase, large change set, disabled watcher, or any
other reason to suspect stale graph state. This writes derived graph state. Use
`detect-changes --brief` only when existing graph freshness is already
established; producer documentation and CLI help classify it as read-only.

## Capability Contract

| Capability                           | Class       | Evidence maturity                                  | Boundary                                     |
| ------------------------------------ | ----------- | -------------------------------------------------- | -------------------------------------------- |
| symbol/file relationship query       | CONTEXT     | help observed; implementation untested             | graph-recorded static relationships only     |
| architecture/community/flow overview | CONTEXT     | help observed; implementation untested             | reconstruction aid, not architecture truth   |
| change impact/risk summary           | PROXY       | help/docs bound; implementation untested           | prioritization, not completeness/correctness |
| tests-for relationship               | CONTEXT     | help observed; implementation untested             | test reference/discovery, not oracle quality |
| dead-code/large-function output      | PROXY       | help observed; implementation untested             | candidate generation only                    |
| refactor preview                     | CONTEXT     | command description bound; implementation untested | preview, not authorized source mutation      |
| semantic/FTS search                  | CONTEXT     | help/docs bound; embeddings not calibrated         | ranking/retrieval only                       |
| benchmark suite                      | CONTROL     | help observed; benchmarks not executed             | evaluates configured graph/tool behavior     |
| source/runtime correctness           | UNSUPPORTED | explicit adapter boundary                          | use source/runtime/domain verification       |

## State and Prerequisites

The tool depends on a persistent graph database derived from repository source.
Relevant state can include:

```text
repository identity and revision/working tree
graph database and last update base
postprocessed flows, communities, and FTS
optional vector embeddings and provider/model
ignore rules and parser/language support
multi-repo registry
hooks, generated instructions/skills, MCP config
watchers, daemon, or MCP server processes
```

Bind `--repo` explicitly when auto-detection could select the wrong repository.
Do not assume `watch` or a daemon is active; observe status. Indexes and
embeddings derived under different ignore rules, parsers, provider/model, or
repository state are different evidence states.

## Command Risk Matrix

| Invocation family                                                                                                                                                | Effect              | Authority/data boundary                                                                                                                                     | Maturity     | Required post-check                                                                                                   |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ | --------------------------------------------------------------------------------------------------------------------- |
| `--help`, `--version`                                                                                                                                            | READ_ONLY           | local process metadata                                                                                                                                      | OBSERVED     | inspect output/identity                                                                                               |
| `repos`, `daemon status`, bounded `daemon logs`                                                                                                                  | READ_ONLY           | local registry/process/log state                                                                                                                            | SOURCE_BOUND | reconcile target/process identity                                                                                     |
| `status`, `query`, `impact`, `search`, `flows`, `flow`, `communities`, `community`, `architecture`, `large-functions`, `dead-code`, `detect-changes`, `refactor` | LOCAL_DERIVED_STATE | target-reading operation, but opening an existing SQLite graph can create WAL files, initialize schema, or run migrations; `--churn` also reads git history | SOURCE_BOUND | bind graph freshness, inspect graph-file state when strict non-mutation matters, and confirm critical edges in source |
| `forget --dry-run`                                                                                                                                               | LOCAL_DERIVED_STATE | does not remove matched records, but opens the graph with the same possible SQLite maintenance effects                                                      | SOURCE_BOUND | inspect planned exact records and graph-file state                                                                    |
| `build`, `update`, `postprocess`, local `embed`, `forget`                                                                                                        | LOCAL_DERIVED_STATE | writes, refreshes, or removes graph/index records                                                                                                           | SOURCE_BOUND | `status`, target state, and known-positive/negative queries                                                           |
| cloud-enabled `build`, `update`, `postprocess`, `watch`, or `embed`                                                                                              | LOCAL_DERIVED_STATE | writes graph/index state and may transmit source-derived text to the selected provider and incur cost                                                       | SOURCE_BOUND | verify provider/model, authorized egress/cost, graph state, and provider-side expectations                            |
| `visualize`, `wiki`, `eval`                                                                                                                                      | LOCAL_DERIVED_STATE | generates or overwrites exports/reports; paths and metadata may be sensitive                                                                                | SOURCE_BOUND | resolve generated paths and inspect artifacts                                                                         |
| `visualize --serve`                                                                                                                                              | PERSISTENT_PROCESS  | writes the visualization, then binds a localhost HTTP server on port 8765                                                                                   | SOURCE_BOUND | inspect artifact/listener and terminate the server                                                                    |
| `register`, `daemon add`                                                                                                                                         | LOCAL_DERIVED_STATE | adds repository or watch configuration                                                                                                                      | SOURCE_BOUND | inspect `repos`/daemon status and exact config                                                                        |
| `unregister`, `daemon remove`                                                                                                                                    | DESTRUCTIVE         | removes registry or watch configuration, not source or graph data by itself                                                                                 | SOURCE_BOUND | inspect registry/config and retained graph state                                                                      |
| `watch`, `daemon start`/`stop`/`restart`, `daemon logs --follow`, `serve`/`mcp` stdio                                                                            | PERSISTENT_PROCESS  | watches or updates files, controls a long-running process, tails output, or exposes tools through a local process                                           | SOURCE_BOUND | process/status/tool-list, graph freshness, and stop path                                                              |
| `serve --http`                                                                                                                                                   | PERSISTENT_PROCESS  | binds a network listener, default localhost; exposes selected or all tools                                                                                  | SOURCE_BOUND | verify bind address/port/tool allowlist and terminate                                                                 |
| `install --dry-run`, `init --dry-run`, `uninstall --dry-run`                                                                                                     | READ_ONLY           | computes and prints platform/config/hook/instruction/removal plans without applying them                                                                    | SOURCE_BOUND | inspect exact targets, ownership, preservation flags, and scope                                                       |
| `install`/`init`                                                                                                                                                 | TARGET_MUTATION     | may write MCP config, hooks, generated skills, and inject repository/platform instructions                                                                  | SOURCE_BOUND | inspect every target/config and tool exposure                                                                         |
| `uninstall`                                                                                                                                                      | DESTRUCTIVE         | removes CRG-owned integration/data depending on repository, platform, and preservation flags                                                                | SOURCE_BOUND | verify intended removal and preserved unrelated state                                                                 |

`forget` is classified as local-derived-state mutation, but may destroy useful
graph records. Resolve exact targets and recovery before use.

The producer describes several analysis commands as read-only with respect to
source and logical graph contents. The installed `GraphStore` nevertheless
opens SQLite in WAL mode, initializes schema, and runs pending migrations.
Therefore this adapter conservatively classifies graph-opening analysis as
`LOCAL_DERIVED_STATE`; use a copied graph or filesystem observation when a
strict no-write guarantee is causal.

## Data, Network, Secrets, and Cost

Producer documentation describes normal graph building/querying as local-first
with zero telemetry, and cloud embeddings as opt-in. This was not independently
verified by network capture during calibration.

The installed help explicitly warns that cloud embedding providers can transmit
source-derived text and incur API cost. Treat provider selection and API keys as
separate authority. Local graph exports can include absolute paths and code
structure metadata; sanitize before external publication.

`serve --http` creates a network-reachable process according to its bind
address. Restrict to explicit localhost unless broader exposure is authorized
and protected. `serve` exposes all MCP tools when `--tools` and `CRG_TOOLS` are
unset; prefer a task-specific allowlist.

Do not expose provider keys in commands, logs, adapter files, or reports.

## Evidence Contract

| Output/signal                    | Can support                                      | Cannot establish                                  | Confirmation needed                                   |
| -------------------------------- | ------------------------------------------------ | ------------------------------------------------- | ----------------------------------------------------- |
| caller/import/test relationships | structural search and review scope               | runtime invocation or complete consumer set       | source/runtime inspection for critical edges          |
| architecture/communities/flows   | brownfield orientation and hypotheses            | intended architecture or all runtime flows        | owners, configuration, source, and runtime evidence   |
| impact/risk result               | review prioritization and candidate blast radius | safe change or complete blast radius              | direct consumers, tests, contracts, runtime           |
| dead-code result                 | candidate unreachable symbol search              | safe removal                                      | dynamic/config/generated usage and relevant execution |
| token-savings panel              | tool-reported context comparison                 | downstream task quality or correctness            | bound tokenizer/config plus behavioral outcome eval   |
| benchmark result                 | tool behavior on selected benchmark/config       | project-specific utility or agent-result validity | representative local tasks and independent oracle     |

## Blind Spots

Material blind spots include:

- Tree-sitter/static graph limitations;
- reflection, dynamic loading/dispatch, dependency injection, metaprogramming;
- generated code and ignored/vendor/submodule paths;
- runtime configuration, feature flags, environment variables, data and schema;
- external services, databases, networks, deployments, chain state;
- parser/language coverage and unresolved symbols;
- stale or partially postprocessed graph state;
- semantic-search provider/model drift;
- max-depth/frontier/result limits that truncate relationships;
- correlation with other tools that consume the same graph or parser outputs.

Inspect configuration limits when an absence or small result is causal.

## Safe Invocation Patterns

Target-reading, bounded examples for the tested CLI:

```bash
code-review-graph status --repo /absolute/repository/path
code-review-graph architecture --detail-level minimal --repo /absolute/repository/path
code-review-graph query callers_of qualified.symbol --repo /absolute/repository/path
code-review-graph query tests_for path/to/file.py --repo /absolute/repository/path
code-review-graph impact --files path/to/changed.py --depth 2 --max-results 50 --repo /absolute/repository/path
code-review-graph detect-changes --base HEAD~1 --brief --repo /absolute/repository/path
```

These commands do not intend to change source or logical graph contents, but
the installed graph-opening path can perform SQLite WAL/schema maintenance as
described in the risk matrix. The last command assumes the graph is already
fresh. Avoid unresolved paths, broad repositories, or `--churn` unless
history-based prioritization is in scope.

Refreshing derived state requires explicit intent:

```bash
code-review-graph update --base HEAD~1 --brief --repo /absolute/repository/path
code-review-graph status --repo /absolute/repository/path
```

Do not add cloud embedding flags unless data transmission, provider/model, API
cost, and credentials are authorized.

## Post-Action Verification

After graph refresh/build/postprocess/embed:

1. run `status` for the exact repository;
2. confirm expected files/entities/flows are represented;
3. query a known-positive and known-negative relationship;
4. inspect provider/model and egress expectations if embeddings were involved;
5. bind subsequent evidence to the refreshed repository state.

After registration or process startup, inspect `repos`, process/daemon status,
listener/tool allowlist, and stop/cleanup path. After installation/uninstallation,
inspect actual platform configs, hooks, instructions, generated skills, and
retained graph data.

## Calibration Record

Observed on 2026-08-26:

- resolved executable and symlink target;
- `code-review-graph --version` returned `2.3.8`;
- `uv tool list` bound the package and entry points;
- installed Python distribution metadata bound canonical homepage, repository,
  documentation, and entry points;
- top-level help and relevant subcommand help were inspected, including build,
  update, install, uninstall, register, unregister, repos, status, forget,
  postprocess, embed, watch, daemon and its subcommands, visualize, wiki,
  detect-changes, impact, architecture, query, flows, dead-code, refactor, eval,
  search, and serve;
- installed `2.3.8` source was inspected for dispatch, graph opening,
  SQLite/schema initialization, read-only missing-graph guards, export paths,
  HTTP serving, registry changes, and uninstall dry-run/apply separation.

Not executed during calibration:

- graph build/update/query behavior on a fixture;
- install/uninstall/config injection;
- MCP server/network behavior;
- daemon/watch behavior;
- local or cloud embeddings;
- benchmark accuracy/performance;
- filesystem/network side-effect capture.

Therefore inspected dispatch and state-opening claims are `SOURCE_BOUND`, while
uninspected capability internals remain `DOC_BOUND` or unverified. None of the
stateful runtime paths above were executed, so the overall calibration remains
`observed-partial`.

## Routing

- `software-engineer`: reconstruction, impact prioritization, test discovery,
  refactor completeness hypotheses, and brownfield system design.
- `agent-result-validator`: independent scope/consumer/test omission search;
  never use graph output as the only acceptance oracle.
- `onchain-security-researcher`: optional structural mapping only; exploit
  reachability, runtime semantics, configuration, economics, and impact require
  domain evidence. Do not use churn/history for independent discovery.
- `tool-integrator`: installation, adapter updates, tool benchmarks, MCP
  exposure, or multi-tool orchestration.
- `brainstorming`: do not load merely to generate ideas unrelated to concrete
  graph capabilities.

## Reopen Triggers

Reopen affected claims when:

- installed/resolved version is not `2.3.8`;
- executable path, installation mechanism, dependency environment, or package
  provenance changes;
- relevant CLI help, MCP tool list/schema, defaults, or annotations change;
- parser/language support, ignore rules, graph limits, hooks, postprocessing,
  embeddings provider/model, or repository registration changes;
- the graph contradicts direct source/runtime evidence;
- a calibration fixture exposes missed edges, false relationships, unexpected
  writes/network access, or non-idempotent behavior;
- a security or maintenance issue changes the integration risk.
