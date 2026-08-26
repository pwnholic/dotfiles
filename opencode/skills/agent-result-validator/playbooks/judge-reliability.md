# Judge Reliability Playbook

Load when a consequential verdict depends on human or model grading,
open-ended quality judgments, rubric-based scoring, pairwise comparison, or an
LLM-as-judge pipeline.

## Define the Judged Construct

State what the judge is supposed to measure and what it must ignore:

```text
construct and decision consequence
candidate population and domain
rubric dimensions and hard gates
reference answers or anchors
allowed variation
known confounders
abstention/escalation condition
```

Avoid asking one score to combine factual correctness, requirement coverage,
style, safety, and preference when a failure on one dimension has a different
consequence. Use direct deterministic checks for objective properties before
subjective grading.

## Calibrate Before Reliance

Build or use a representative calibration set containing:

- known valid and invalid outputs;
- close boundary cases;
- semantically equivalent surface variants;
- concise and verbose forms with equal substance;
- reordered candidates for pairwise evaluation;
- misleading confidence, authority, comments, or formatting;
- domain-specific failure cases.

Compare judge outcomes with capable references or qualified reviewers. Measure
false acceptance and false rejection separately; aggregate agreement can hide a
fatal error direction. Keep calibration items separate from the final judged
set when tuning the rubric.

## Blind and Deconfound

When feasible:

- hide author/model identity and prior score;
- randomize or swap candidate order;
- normalize irrelevant presentation without deleting substantive evidence;
- grade dimensions independently before an overall decision;
- require evidence tied to rubric criteria rather than free-form preference;
- repeat or escalate cases whose verdict changes under benign perturbation.

Do not assume multiple LLM judges are independent. Shared model families,
training data, style preferences, or rubric interpretation can produce
correlated agreement.

## Model-Judge Boundary

An LLM judge can be useful for triage, rubric-assisted review, or scalable
signals after calibration. It is not a sole consequential oracle when an
executable check, domain expert, or direct observation is necessary.

For every model judge record:

```text
model/version and settings
prompt/rubric/reference context
candidate-order policy
calibration set and error profile
repetition/aggregation method
known blind spots and escalation threshold
```

Treat judge explanations as hypotheses about the score, not proof that the
score is correct. Generating tests or chain-of-thought before scoring does not by
itself remove bias or establish semantic correctness.

## Human-Judge Boundary

Human review is not automatically ground truth. Bind reviewer qualification,
instructions, blinding, conflicts, workload, agreement, adjudication, and
access to the evidence needed for the construct.

Escalate disagreement on critical factual or domain claims to a stronger oracle
rather than forcing consensus. Preserve minority rationales when they expose a
distinct failure mode.

## Verdict Use

State whether grading supports:

```text
screening/triage
comparative preference in a defined population
rubric compliance
bounded factual or functional acceptance
no responsible verdict
```

Do not generalize beyond the calibrated population, task distribution, and
decision threshold. Report instability or disagreement as uncertainty, not as
an averaged certainty.
