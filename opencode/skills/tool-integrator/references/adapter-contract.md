# Tool Adapter Contract

Read when creating or revising an adapter in `../adapters/`. Adapters are
trusted repository-local operating contracts, but the external tool and its
output remain evidence to evaluate.

## Required Frontmatter

```yaml
---
tool: executable-or-server-name
kind: cli | mcp | cli-mcp
adapter-version: 1
tested-version: exact observed version
version-probe: safe command or protocol operation
calibrated: YYYY-MM-DD
calibration-level: documented | source-bound | observed-partial | observed
canonical-source: https://canonical.example/tool
---
```

Rules:

- filename must equal `<tool>.md`;
- bind an exact tested version; do not write `latest`, ranges, or `unknown` in a
  maintained adapter;
- `version-probe` must be safe and non-mutating by design;
- `calibrated` is the date the recorded behavior was last assessed, not the date
  the file was reformatted;
- `calibration-level` describes the strongest overall evidence, while sections
  preserve weaker individual claims;
- `canonical-source` identifies the producer-controlled source or specification,
  not a search result or package mirror.

If exact identity cannot yet be bound, keep discovery notes outside the adapter
and do not publish a maintained contract.

## Required Sections

Every adapter contains these headings:

```text
# Tool Adapter: <tool>
## Use When
## Do Not Use As
## Identity and Freshness
## Capability Contract
## State and Prerequisites
## Command Risk Matrix
## Data, Network, Secrets, and Cost
## Evidence Contract
## Blind Spots
## Safe Invocation Patterns
## Post-Action Verification
## Calibration Record
## Routing
## Reopen Triggers
```

## Command Risk Rows

Use one row per materially different effect:

```text
invocation | effect | authority/data boundary | maturity | required post-check
```

Allowed effect vocabulary:

```text
READ_ONLY
LOCAL_DERIVED_STATE
TARGET_MUTATION
EXTERNAL_MUTATION
DESTRUCTIVE
PERSISTENT_PROCESS
UNKNOWN_EFFECT
```

Split commands when flags change risk. For example, local indexing and cloud
embedding are not one row; dry-run and apply are not one row; stdio and network
servers are not one row.

Use evidence maturity labels consistently:

```text
OBSERVED | SOURCE_BOUND | DOC_BOUND | INFERRED | UNKNOWN
```

## Evidence Contract

State each important output as:

```text
output/signal | can support | cannot establish | confirmation needed
```

Explicit non-capabilities are mandatory. They prevent contextual or proxy tools
from silently becoming correctness or security oracles.

## Safe Examples

Examples must:

- use explicit targets and bounded output when supported;
- avoid secrets and production identities;
- identify whether they only read or also refresh/write derived state;
- avoid unresolved variables, broad globs, auto-confirm, or destructive flags;
- show a resulting-state/freshness check when state changes;
- be valid for `tested-version`.

Do not include installation, deletion, deployment, registration, or global
configuration examples as routine safe invocations. Route them through the
installation lifecycle and explicit authorization.

## Reopen Triggers

At minimum cover:

```text
tool version or resolved artifact changes
relevant help/schema/annotations change
plugin, parser, model, provider, or backend changes
configuration changes capability or data flow
calibration fails or real usage contradicts the adapter
new security/provenance issue affects the integration
```

Invalidate only affected claims. Preserve prior observations as historical
evidence rather than silently rewriting what was tested.
