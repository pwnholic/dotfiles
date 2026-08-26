# Research Basis for the On-Chain Security Researcher Skill

Maintainer reference. Load when revising search, validation, or coordination
methodology. Runtime and protocol specifications remain near the playbook that
uses them and must be re-checked against the exact deployed target.

## Review Scope

Evidence was retrieved through 2026-08-26. This synthesis asks which current
methods justify changes to discovery, fuzzing, variant analysis, dependency
closure, and multi-researcher coordination. It is not a claim that any method
transfers automatically to a new chain, runtime, or protocol.

Evidence classes:

```text
NORMATIVE       executable or final semantic specification
SUPPORTED       peer-reviewed evidence with a released artifact or dataset
EMERGING        peer-reviewed recent method with material transfer limits
PROVISIONAL     preprint or narrow artifact; method lead only
```

For concrete findings, deployed state and reproducible execution remain above
all method papers.

## Processed Evidence Matrix

| Method claim                                                                                    | Evidence                                           | Applicability boundary                                                              | Skill decision                                                                                                      |
| ----------------------------------------------------------------------------------------------- | -------------------------------------------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Search feedback beyond line coverage can expose deeper state transitions                        | PROVISIONAL                                        | Vulseye evaluates selected EVM contracts and target feedback                        | Treat state/code-target feedback as an optional discriminator and calibrate on known positives and near misses      |
| Profit-aware objectives can improve search for economically meaningful behavior                 | PROVISIONAL                                        | VERITE uses selected DeFi targets and an experimental economic model                | Separate property violation, executable value path, feasible region, and realized impact                            |
| Multiple feedback signals may improve stateful fuzzing                                          | PROVISIONAL                                        | LLAMA is a recent preprint with tool- and dataset-specific results                  | Adopt only after target-specific comparison against a simpler baseline                                              |
| Fuzzing outcomes depend on human workflow and oracle interpretation                             | PROVISIONAL                                        | Human-side smart-contract fuzzing study covers a bounded participant/tool setting   | Use results to improve assignments and feedback, not as a universal team-size rule                                  |
| Cross-chain findings require resource, identity, message, and destination-effect closure        | EMERGING                                           | SmartAxe studies selected cross-chain applications                                  | Model the complete cross-domain causal chain and finality/retry semantics                                           |
| Historical storage analysis can reveal upgrade and patch siblings                               | EMERGING                                           | CollisionRepair studies historical storage-collision cases                          | Use only after first-principles mechanism discovery; label historical provenance                                    |
| Compiler/VM equivalence cannot be assumed from high-level source                                | EMERGING                                           | zkEVM and Move-to-EVM studies demonstrate bounded translation/verification failures | Inspect causal runtime and dependency source directly when behavior depends on implementation detail                |
| New account delegation semantics create configuration- and activation-sensitive attack surfaces | EMERGING                                           | USENIX Security 2026 EIP-7702 study covers a particular ecosystem snapshot          | Bind EIP status, chain activation, wallet/account implementation, and deployed configuration separately             |
| Multiple researchers add value only when their evidence is materially independent               | PROVISIONAL plus low-regret coordination principle | Available studies do not establish a domain-general optimal agent count             | Partition by exploit family or falsification question, preserve blocked paths, and measure correlation              |
| A primitive is not an exploit finding without constructive reachability and impact              | NORMATIVE methodology decision                     | This is an assurance gate, not a benchmark-derived rate                             | Require complete chain, realistic starting privilege, target configuration, negative control, and observable impact |

## Encoded as Core Rules

1. Bind the executing deployment, configuration, runtime, and state.
2. Derive target-specific security properties before choosing tools.
3. Preserve hypothesis diversity and negative evidence.
4. Inspect causal implementation details directly.
5. Chain primitives until the success predicate and impact are reached.
6. Independently challenge promoted findings when an authorized validator exists.
7. Keep discovery provenance separate from history-assisted variant analysis.

## Conditional, Not Universal

The evidence does not justify requiring:

- one fuzzer, feedback vector, exploit family list, or sequence depth;
- multi-agent research for every engagement;
- historical incidents, CVEs, or patched diffs during first-principles discovery;
- profit as the only impact oracle;
- EVM semantics for SVM, Move, or another runtime;
- current TVL as the maximum blast radius;
- a finding verdict from analyzer cleanliness or coverage percentage.

## Freshness Protocol

Re-check paper version, artifact commit, dataset, target families, runtime
version, and replication status before promoting a method lead. Re-check every
semantic source against chain activation and the deployed implementation.
Contradictory target execution invalidates a generic source claim for that
finding.

## Source Ledger

1. [Vulseye: state/code-target feedback](https://arxiv.org/abs/2408.10116), preprint.
2. [VERITE: profit-centric smart-contract fuzzing](https://arxiv.org/abs/2501.08834), preprint.
3. [LLAMA: adaptive multi-feedback fuzzing](https://arxiv.org/abs/2507.12084), preprint.
4. [The Human Side of Smart Contract Fuzzing](https://arxiv.org/abs/2506.07389), preprint.
5. [SmartAxe cross-chain resource and check analysis](https://www.usenix.org/conference/usenixsecurity25/presentation/ruaro), USENIX Security 2025.
6. [CollisionRepair historical storage analysis](https://www.usenix.org/conference/usenixsecurity25/presentation/pan-yu), USENIX Security 2025.
7. [zkEVM verification case study](https://www.usenix.org/conference/usenixsecurity25/presentation/peng-xinghao), USENIX Security 2025.
8. [Move-to-EVM security-preservation study](https://www.usenix.org/conference/usenixsecurity25/presentation/benetollo), USENIX Security 2025.
9. [EIP-7702 empirical risk study](https://www.usenix.org/conference/usenixsecurity26/presentation/huang-mingyuan), USENIX Security 2026.
10. [Ethereum execution specifications](https://github.com/ethereum/execution-specs) and [execution tests](https://github.com/ethereum/execution-spec-tests).
11. [Foundry invariant testing](https://getfoundry.sh/forge/invariant-testing).
