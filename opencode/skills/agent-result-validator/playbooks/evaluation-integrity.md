# Evaluation Integrity Playbook

Load when the candidate result depends on a benchmark, grader, evaluation
harness, agent trace, retry policy, aggregate score, or claim about model/agent
performance.

## Evaluation Object

Freeze what was actually evaluated:

```text
claim and intended deployment/use context
task distribution and sampling
model/version/reasoning configuration
agent scaffold, system instructions, tools, and permissions
context, token, turn, time, attempt, and cost budgets
environment, dependencies, fixtures, and network access
grader, rubric, aggregation, exclusions, and review procedure
```

Do not report model capability when only one particular model-plus-harness
configuration was tested. Do not compare scores produced under materially
different budgets, tools, environments, or scoring rules without bounding the
effect.

## Task and Oracle Validity

For each task family ask:

- Does the task represent the claimed capability or deployment outcome?
- Is the success condition complete, reachable, and non-ambiguous?
- Can a wrong result satisfy the grader?
- Can a valid alternative be rejected by an overly narrow reference?
- Are fixtures, gold answers, and reference solutions themselves checked?
- Is the suite diverse enough that duplicates do not dominate the aggregate?
- Are task difficulty and score distributions consistent with observed traces?

Use known-good and known-bad controls. Perturb a causal property and confirm the
grader changes in the expected direction. A grader that cannot reject a
plausible wrong candidate is not capable of supporting a pass.

## Outcome and Trace Audit

Inspect final environment state for task success. Use the trace to explain and
challenge validity:

```text
claimed success without resulting state
reward hacking or grader-targeted shortcuts
test/gold leakage or benchmark contamination
unauthorized tool, network, file, or state access
hidden retries, cherry-picked attempts, or post-hoc exclusions
refusal, crash, timeout, infrastructure, or task failure misclassified as agent failure
evaluation awareness, sandbagging, or suspiciously anomalous strategies
```

Do not infer malicious intent merely from an unexpected shortcut. Classify the
observable integrity effect and whether it inflates, suppresses, or invalidates
the score.

## Variance, Selection, and Aggregation

Record trial count, seed/temperature where available, pass@k or selection rule,
and uncertainty. A best-of-N or oracle-selected result measures a different
property from pass@1.

Challenge:

- rerunning failures but not successes;
- excluding trials after seeing outcomes;
- aggregating incommensurate task scores;
- reporting only the mean when failures are heavy-tailed or bimodal;
- treating one successful trajectory as reliable behavior;
- using the test set to tune prompts, scaffolds, or graders.

Use repeated trials only when nondeterminism matters and cost is justified.
Report the observed distribution; do not manufacture a precise reliability
claim from an inadequate sample.

## Contamination and Evaluation Gaming

Look for exact solution access, grader feedback loops, hidden-test extraction,
memorized public answers, task-specific hardcoding, and manipulation of scoring
or displayed traces. Preserve provenance and separate:

```text
legitimate use of generally available tools or documentation
task ambiguity or unintended but valid solution
benchmark shortcut that breaks construct validity
unauthorized access or grader manipulation
unresolved suspicion
```

Do not use contamination as a generic explanation for surprising success.
Require a concrete indicator and show how it could affect the scored outcome.

## Completion

Return the exact evaluated system, task/score scope, harness and budget effects,
grader capability, outcome/trace discrepancies, trial distribution, integrity
hazards, and the narrower claim the evidence can responsibly support.
