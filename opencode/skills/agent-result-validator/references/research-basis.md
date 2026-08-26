# Research Basis for Agent Result Validation

Maintainer reference. Load when revising the validator methodology, auditing
its assumptions, or measuring whether it improves real acceptance decisions.
It is not required during ordinary result validation.

## Review Scope

Evidence was retrieved through 2026-08-26. This is a structured evidence
synthesis, not a formal systematic review or meta-analysis.

Evidence labels:

```text
NORMATIVE       standard or governance requirement
SUPPORTED       peer-reviewed or repeatedly demonstrated operational evidence
EMERGING        current official draft or narrow recent empirical result
PROVISIONAL     preprint, benchmark-specific result, or method lead
```

Concrete target behavior, independently observed state, and version-pinned
domain semantics outrank generic evaluation guidance for a particular verdict.

## Processed Evidence Matrix

| Method claim                                                                                                                          | Evidence                               | Applicability boundary                                                                                     | Skill decision                                                                                                     |
| ------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| TEVV must be tailored to the actual use, goal, and impact                                                                             | EMERGING official framework            | NIST AI 200-2 TEVV-Athlon is an initial public draft, not a final standard                                 | Freeze a task-specific validation contract; do not apply one universal checklist                                   |
| Agent prose and final environment outcome are different evidence objects                                                              | SUPPORTED organizational practice      | Anthropic guidance is experience-derived and product-contextual                                            | Prefer observable outcome; inspect transcript only where it changes validity                                       |
| Model, scaffold, tools, harness, budgets, scoring, and review procedure jointly shape an agent-evaluation result                      | SUPPORTED organizational practice      | OpenAI and Anthropic guidance concerns agent evaluation rather than every one-off artifact audit           | Bind the evaluated system and environment; do not report a model-only conclusion from a harnessed run              |
| Evaluation validity can be distorted by reward hacking, contamination, broken tasks, evaluation awareness, or selective procedure     | SUPPORTED operational evidence         | Frequency and severity vary by benchmark and model                                                         | Load evaluation-integrity only when the result depends on a harness, trace, or performance claim                   |
| Deterministic replay and state-based graders improve objectivity for executable outcomes                                              | SUPPORTED domain example               | EVMbench covers selected historical on-chain tasks in a local environment and has documented scope gaps    | Prefer executable domain predicates and disclose environment limitations; do not generalize benchmark scores       |
| Monitors and graders require labeled controls or other ground truth before their reliability is assumed                               | SUPPORTED dataset evidence             | METR MALT focuses on selected software/research agent transcripts and partially prompted integrity threats | Calibrate evaluator false acceptance/rejection using known-good and known-bad controls                             |
| High variance, surprising successes, spurious failures, and dev/test gaps are evaluation red flags                                    | SUPPORTED operational method           | METR capability-elicitation guidance targets capability evaluations                                        | Inspect distributions, exclusions, retries, and traces when aggregate validity is consequential                    |
| LLM judges can approximate human preferences in some settings but exhibit position, verbosity, self-enhancement, and reasoning biases | SUPPORTED peer-reviewed evidence       | MT-Bench/Chatbot Arena study concerns selected chat tasks and models                                       | Use calibrated model grading as a bounded signal, not universal ground truth                                       |
| Position bias varies by judge, candidate, task, and comparison setting                                                                | SUPPORTED peer-reviewed evidence       | IJCNLP-AACL 2025 studies selected judges and benchmarks                                                    | Swap/randomize order and escalate unstable pairwise verdicts when comparison is causal                             |
| Superficial code variations can bias model judges even when semantic correctness is unchanged                                         | SUPPORTED peer-reviewed evidence       | EACL 2026 covers five languages, selected tasks, and tested judge models                                   | Prefer execution or semantic oracles; include surface-invariant calibration cases for code grading                 |
| Model-generated tests or explanations do not by themselves eliminate judge bias                                                       | SUPPORTED peer-reviewed evidence       | Demonstrated for the tested code-evaluation setup                                                          | Treat judge rationales as hypotheses and test-generation as evidence only when executed against capable predicates |
| Automated graders may be less reliable than domain experts on complex real-world deliverables                                         | SUPPORTED provider study               | GDPval uses selected occupational tasks, rubrics, and blind expert comparisons                             | Retain human/domain escalation for consequential open-ended judgments; human review is still bounded evidence      |
| Overseers can themselves become an attack or failure surface                                                                          | PROVISIONAL safety-evaluation evidence | Anthropic sabotage demonstrations study intentionally elicited behaviors in artificial settings            | Do not trust evaluator role labels; audit whether the judge, trace, or scorer can be influenced by the candidate   |

## Derived Core Rules

1. Validate against the original authorized request, not the candidate's
   restatement.
2. Bind candidate identity, target state, environment, and evidence freshness.
3. Decompose acceptance into claim-level predicates before issuing an aggregate
   verdict.
4. Prefer direct state and executable invariants over narration or style.
5. Audit both false acceptance and false rejection capability of the oracle.
6. Inspect process only when it affects authorization, safety, provenance,
   reproducibility, or construct validity.
7. Keep producer self-verification distinct from independent acceptance.
8. Keep domain truth with its domain specialist; the validator owns
   request-to-evidence traceability and bounded acceptance.
9. Treat LLM and human judges as measurement instruments requiring calibration,
   not intrinsic ground truth.
10. Report blocked and unverified claims rather than converting missing evidence
    into a pass or a numeric confidence.

## Tradeoffs Encoded

### Independence versus coordination cost

A separate specialist reduces self-confirmation and makes the acceptance
artifact explicit, but adds context, routing, and handoff cost. Therefore it is
activated only when independent audit is the requested deliverable or the
decision consequence justifies it; it is not a mandatory second pass.

### Cross-domain coverage versus duplicated expertise

A generic validator can detect scope drift, stale evidence, weak oracles,
unsupported claims, and outcome/trace mismatches. It cannot responsibly replace
software compatibility proof, exploit-chain validation, or domain decision
quality. Therefore domain mechanisms are handed off rather than copied into the
validator.

### Outcome focus versus process blindness

Direct state is usually stronger than agent narration, but a valid-looking
outcome can still result from unauthorized actions, leakage, reward hacking, or
unsafe shortcuts. Therefore process is inspected when it is part of the
contract or threatens validity, not as a universal style review.

### Automation scale versus evaluator bias

Code and model graders scale, while capable human/domain review is expensive.
No grader class is universally superior. Therefore deterministic checks are
preferred for objective properties, model judges are calibrated and bounded,
and consequential ambiguity escalates to a capable domain oracle.

### Reproducibility versus cost and side effects

Repeated replay strengthens evidence but may be expensive, nondeterministic, or
unsafe. Therefore repetition follows decision risk and variance; production or
destructive actions are not repeated without authorization.

### Repair speed versus clean diagnosis

Repairing during audit can erase evidence about the original candidate and
turn acceptance into implementation. Therefore the pre-repair verdict is frozen
and repair is a specialist handoff followed by targeted revalidation.

## Conditional, Not Universal

The evidence does not justify requiring:

- a separate validator after every agent turn;
- another agent merely to claim independence;
- every playbook for every validation;
- full transcript review when direct outcome evidence is sufficient;
- repeated trials for deterministic low-risk artifacts;
- an LLM panel or majority vote for every subjective judgment;
- human review as infallible ground truth;
- one scalar score across unlike acceptance dimensions;
- numeric confidence without a calibrated measurement model;
- rejection of a correct benign alternative path merely because it differed
  from the evaluator's expected process;
- repair permission from an audit request;
- universal correctness from a scoped `PASS`.

## Forward-Evaluation Protocol

Evaluate this skill on realistic result packages, not wording conformance.
Include:

```text
true pass and true failure candidates
plausible prose with missing/false outcome
correct outcome reached through a prohibited action
stale or wrong-environment evidence
candidate-authored weak tests
valid alternative rejected by a narrow grader
LLM-judge order/style perturbations
domain claim requiring explicit handoff
blocked evidence and incomplete artifacts
audit-plus-repair requests
```

Measure false acceptance and false rejection separately, plus routing accuracy,
unnecessary verification cost, domain-handoff quality, and whether the final
verdict preserves unresolved uncertainty. Run previous-versus-candidate trials
in isolated environments when a production-equivalent harness exists.

## Source Ledger

1. NIST, [The TEVV-Athlon Framework for Evaluating AI Systems](https://www.nist.gov/artificial-intelligence/ai-research/tevv-athlon-framework-evaluating-ai-systems), initial public draft announcement, 2026.
2. NIST, [Artificial Intelligence Risk Management Framework: Generative Artificial Intelligence Profile](https://doi.org/10.6028/NIST.AI.600-1), 2024.
3. Anthropic Engineering, [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents), 2026.
4. OpenAI, [A shared playbook for trustworthy third-party evaluations](https://openai.com/index/trustworthy-third-party-evaluations-foundations/), 2026.
5. OpenAI and Paradigm, [Introducing EVMbench](https://openai.com/index/introducing-evmbench/), 2026.
6. OpenAI, [Measuring the performance of our models on real-world tasks (GDPval)](https://openai.com/index/gdpval/), 2025.
7. METR, [MALT: A Dataset of Natural and Prompted Behaviors That Threaten Eval Integrity](https://metr.org/blog/2025-10-14-malt-dataset-of-natural-and-prompted-behaviors/), 2025.
8. METR, [Guidelines for capability elicitation](https://metr.org/blog/2024-03-15-guidelines-for-capability-elicitation/), 2024.
9. Zheng et al., [Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena](https://proceedings.neurips.cc/paper_files/paper/2023/hash/91f18a1287b398d378ef22505bf41832-Abstract-Datasets_and_Benchmarks.html), NeurIPS 2023.
10. Shi et al., [Judging the Judges: A Systematic Study of Position Bias in LLM-as-a-Judge](https://aclanthology.org/2025.ijcnlp-long.18/), IJCNLP-AACL 2025.
11. Moon et al., [Don't Judge Code by Its Cover: Exploring Biases in LLM Judges for Code Evaluation](https://doi.org/10.18653/v1/2026.findings-eacl.70), EACL Findings 2026.
12. Chen et al., [Humans or LLMs as the Judge? A Study on Judgement Bias](https://aclanthology.org/2024.emnlp-main.474/), EMNLP 2024.
13. Anthropic, [Sabotage evaluations for frontier models](https://www.anthropic.com/research/sabotage-evaluations), 2024.
