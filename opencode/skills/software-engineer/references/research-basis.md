# Research Basis for the Software-Engineer Skill

Maintainer reference. Load when revising the methodology, auditing its
assumptions, or evaluating whether the skill improves agent behavior. It is not
required during ordinary engineering.

## Review Scope

Evidence was retrieved through 2026-08-26. This is a structured evidence
synthesis, not a formal systematic review or meta-analysis.

The review separates:

```text
NORMATIVE       a standard or required semantic contract
SUPPORTED       peer-reviewed or repeatedly demonstrated operational evidence
EMERGING        recent conference evidence with transfer limits
PROVISIONAL     preprint or narrow benchmark; method lead only
```

Project behavior and version-pinned runtime semantics outrank generic method
evidence for a concrete change.

## Processed Evidence Matrix

| Method claim                                                                                            | Evidence                                         | Applicability boundary                                                                               | Skill decision                                                                                       |
| ------------------------------------------------------------------------------------------------------- | ------------------------------------------------ | ---------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Skills must be tested against observable task outcomes                                                  | PROVISIONAL plus low-regret evaluation principle | SkillsBench spans selected domains, models, and harnesses                                            | Maintain paired with-skill/without-skill behavioral evals with deterministic checks where possible   |
| More skill content is not automatically better                                                          | PROVISIONAL                                      | SkillsBench reports focused skills outperforming larger bundles; this is not a universal size law    | Keep the entrypoint focused and load playbooks only on matching triggers                             |
| Skill guidance can add cost or harm when mismatched to project state                                    | PROVISIONAL                                      | SWE-Skills-Bench is a 2026 preprint over selected public skills and repositories                     | Test marginal utility, token cost, version compatibility, and negative routing cases                 |
| Repository task benchmarks need pinned, reproducible environments                                       | PROVISIONAL                                      | SWE-rebench V2 studies benchmark confounders rather than every production workflow                   | Bind evidence to revision, dependencies, fixtures, and runtime; isolate eval trials                  |
| Passing tests can be a lucky trajectory rather than reliable behavior                                   | PROVISIONAL                                      | AgentLens studies selected coding-agent trajectories                                                 | Record retries and nondeterminism; distinguish one success from consistent success                   |
| Verification quality depends on whether the oracle contains information capable of detecting the defect | PROVISIONAL                                      | ORACLE-SWE is benchmark-specific                                                                     | Require claim-to-evidence mapping and challenge weak oracles with causal witnesses                   |
| Refactor and migration correctness includes structural completeness as well as behavior                 | PROVISIONAL                                      | SWE Refactor Bench targets selected transformations                                                  | Verify the old mechanism was removed or disconnected, not merely that tests pass                     |
| Flaky-failure diagnosis cannot rely on source shape alone                                               | PROVISIONAL                                      | Recent studies use selected flaky-test datasets and detection settings                               | Record order, seed, environment, repetition, and runtime evidence; do not rerun until green          |
| Debugging requires evidence-producing discriminators, not repeated plausible edits                      | SUPPORTED operational methodology                | SRE guidance is operational and organization-derived                                                 | Preserve competing hypotheses and choose tests that discriminate among them                          |
| Multi-agent gains depend on task topology and coordination                                              | PROVISIONAL                                      | Recent team-agent studies use selected repositories, models, and orchestration                       | Default to one behavioral owner; parallelize only independent evidence or disjoint writes            |
| Production delivery performance and stability are multiple dimensions                                   | SUPPORTED industry evidence                      | DORA results are observational and organization-dependent                                            | Treat speed, recovery, change failure, and rework as separate operational signals                    |
| An architecture description should address stakeholder concerns through explicit views and models       | NORMATIVE scope                                  | ISO/IEC/IEEE 42010:2022 specifies architecture-description concepts, not a design method             | Select only concern-relevant views and keep identities and boundaries consistent across them         |
| Quality characteristics provide a design/evaluation vocabulary, not a universal checklist               | NORMATIVE scope                                  | ISO/IEC 25010:2023 defines a nine-characteristic product-quality model across ICT products           | Elicit architecturally significant quality scenarios and prioritize only those that shape decisions  |
| Functional requirements, quality requirements, and constraints should drive iterative decomposition     | SUPPORTED method                                 | SEI ADD has broad historical use but is a method family rather than comparative proof of superiority | Design iteratively from prioritized drivers; choose tactics and allocate responsibilities explicitly |
| Architecture tradeoffs can be challenged before full implementation                                     | SUPPORTED method with cost boundary              | ATAM is a facilitated multi-stakeholder method and can be excessive for small reversible designs     | Use lightweight challenge by default and formal tradeoff review only when risk justifies it          |
| Large-system designs need concrete capacity, failure-domain, and operational reasoning                  | SUPPORTED organizational practice                | Google NALSD is experience-derived from large production systems                                     | Begin with a design that works in principle, then test feasibility, resilience, and physical limits  |
| Reliability objectives should express user-relevant measurable behavior rather than absolutes           | SUPPORTED organizational practice                | Google SRE practices are service-oriented and organization-derived                                   | Turn material quality goals into measurable scenarios; avoid “always available” or “infinite scale”  |
| Security and trustworthiness must trace through lifecycle decisions and system elements                 | NORMATIVE guidance                               | NIST SP 800-160 Vol. 1 Rev. 1 is systems-security engineering guidance, not exploit validation       | Model trust/protection requirements in architecture while keeping security verdicts with specialists |
| Capturing every decision creates overhead; durable rationale is useful only for material choices        | SUPPORTED observational evidence                 | A 2023 MSR study observes ADR use in open-source GitHub projects and cannot prove causal benefits    | Record only decisions whose rationale affects implementation, operation, or evolution                |
| Reliability mechanisms can increase security surface, cost, latency, and operational complexity         | CURRENT vendor operational guidance              | Azure/AWS guidance is cloud- and provider-contextual                                                 | Make cross-quality consequences explicit and do not add redundancy without an active requirement     |

## Encoded as Core Rules

1. Reconstruct current behavior before changing it.
2. Bind verification to the exact claim and state.
3. Separate behavior preservation from transition/refactor completeness.
4. Keep one behavioral owner unless task topology justifies parallel work.
5. Treat empirical results as bounded priors, not project facts.
6. Use progressive routing rather than loading every engineering playbook.
7. Start system design from architecturally significant requirements and the
   least complex coherent mechanism.
8. Trace concerns to views, decisions, contracts, and an evidence plan.
9. Escalate into distributed, performance, migration, and rollout playbooks only
   when their causal triggers are present.

## Conditional, Not Universal

The evidence does not justify requiring:

- every verification layer for every change;
- mutation, property-based, or metamorphic testing for trivial changes;
- multi-agent execution by default;
- restart-on-failure as a universal long-task policy;
- one deployment strategy, benchmark duration, or risk score;
- benchmark pass rates as evidence about the current repository.
- every ISO quality characteristic, architecture view, ADR, or formal ATAM step
  for every system;
- microservices, queues, caching, sharding, replication, or multi-region design
  without a requirement or measured constraint that justifies the complexity;
- precise capacity numbers when the input evidence supports only a range.

## Freshness Protocol

Re-evaluate a matrix row when its cited artifact materially changes, a newer
replication contradicts it, or forward tests show that the encoded instruction
does not improve the intended behavior. Record retrieval date, version, task
distribution, model/harness, verifier, and important negative results.

## Source Ledger

1. [SkillsBench: Benchmarking How Well Agent Skills Work Across Diverse Tasks](https://arxiv.org/abs/2602.12670), 2026 preprint.
2. [SWE-Skills-Bench: Do Agent Skills Actually Help in Real-World Software Engineering?](https://arxiv.org/abs/2603.15401), 2026 preprint.
3. [Skill Coverage: A Test Adequacy Metric for Agent Skills](https://arxiv.org/abs/2606.20659), 2026 preprint.
4. [SWE-rebench V2](https://arxiv.org/abs/2602.23866), 2026 preprint.
5. [AgentLens](https://arxiv.org/abs/2605.12925), 2026 preprint.
6. [ORACLE-SWE](https://arxiv.org/abs/2604.07789), 2026 preprint.
7. [SWE Refactor Bench](https://arxiv.org/abs/2608.23564), 2026 preprint.
8. [Limits of code-only flaky-test detection](https://arxiv.org/abs/2607.09345), 2026 preprint.
9. [Reproducible flaky-failure dataset](https://arxiv.org/abs/2605.21677), 2026 preprint.
10. [FailFast-RestartSmart](https://arxiv.org/abs/2608.03222), 2026 preprint.
11. Google SRE, [Effective Troubleshooting](https://sre.google/sre-book/effective-troubleshooting/).
12. [Coordination measurement across coding-agent teams](https://arxiv.org/abs/2608.16801), 2026 preprint.
13. [OpenTelemetry-aligned multi-agent observability and fault injection](https://arxiv.org/abs/2608.24271), 2026 preprint.
14. DORA, [2025 State of AI-assisted Software Development](https://dora.dev/research/2025/dora-report/).
15. Anthropic Engineering, [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents), 2026 operational guidance.
16. Hypothesis, [Property-based testing documentation](https://hypothesis.readthedocs.io/en/latest/).
17. ISO, [ISO/IEC/IEEE 42010:2022 Architecture Description](https://www.iso.org/standard/74393.html).
18. ISO, [ISO/IEC 25010:2023 Product Quality Model](https://www.iso.org/standard/78176.html).
19. CMU SEI, [Attribute-Driven Design Method Collection](https://www.sei.cmu.edu/library/attribute-driven-design-method-collection/).
20. CMU SEI, [Reasoning About Software Quality Attributes](https://www.sei.cmu.edu/library/reasoning-about-software-quality-attributes/).
21. CMU SEI, [Architecture Tradeoff Analysis Method Collection](https://www.sei.cmu.edu/library/architecture-tradeoff-analysis-method-collection/).
22. Google SRE Workbook, [Non-Abstract Large System Design](https://sre.google/workbook/non-abstract-design/).
23. Google SRE, [Service Level Objectives](https://sre.google/sre-book/service-level-objectives/).
24. NIST, [SP 800-160 Vol. 1 Rev. 1: Engineering Trustworthy Secure Systems](https://csrc.nist.gov/pubs/sp/800/160/v1/r1/final).
25. Buchgeher et al., [Using Architecture Decision Records in Open Source Projects](https://doi.org/10.1109/ACCESS.2023.3287654), IEEE Access 2023.
26. Microsoft Azure, [Develop an Architecture Design Specification](https://learn.microsoft.com/en-us/azure/well-architected/architect-role/architecture-design-specification), updated 2025-12-09.
27. Microsoft Azure, [Reliability Tradeoffs](https://learn.microsoft.com/en-us/azure/well-architected/reliability/tradeoffs), updated 2026-04-27.
28. AWS, [Operational Excellence Pillar](https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/welcome.html), revised 2024-11-06.
