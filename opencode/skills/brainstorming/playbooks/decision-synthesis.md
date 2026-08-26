# Decision Synthesis Playbook

Load when an option space must become a shortlist, recommendation, portfolio, roadmap, or experiment plan.

## Define the Decision

State:

```text
decision owner
decision deadline or horizon
hard gates
ranking criteria
risk tolerance
evidence available
cost of delay
reversibility
```

Do not rank options against criteria that were inferred as hard requirements without checking the user's intent.

## Gate Before Ranking

Remove or quarantine options that violate genuine hard constraints. Record the exact failed gate; do not quietly delete them.

Keep an option conditional when a missing fact, negotiable constraint, or feasible modification could restore it.

## Build Evidence Cards

For each serious candidate record:

```text
mechanism and expected outcome
supporting facts
critical assumptions
material unknowns
dependencies
upside
downside and second-order effects
reversibility
cheapest disconfirming test
```

Evaluate candidates independently before pairwise comparison to reduce halo effects from the current favorite.

When feasible, separate candidate authorship from consequential evaluation. Use domain expertise to assess novelty, feasibility, and dependencies, but keep the decision owner's risk incentives visible because accountability can bias selection toward familiar options.

## Compare Without False Precision

Use only decision-relevant criteria. Anchor qualitative judgments with observable meanings.

Prefer:

- hard gates for non-negotiable constraints;
- pairwise comparison for close alternatives;
- Pareto analysis when criteria conflict;
- scenarios or sensitivity analysis when assumptions vary;
- expected learning value when evidence is weak.

Avoid a single weighted score when weights are unknown, contested, or capable of hiding a fatal weakness.

## Challenge the Leaders

For each leading option ask:

- What must be true for this to work?
- What evidence would reverse the ranking?
- How could it fail despite competent execution?
- What dependency or stakeholder can veto it?
- What second-order cost appears after initial success?
- What simpler option captures most of the value?
- What opportunity is lost by choosing it?

Treat an unchallenged winner as provisional.

Explicitly retain originality during screening. Evaluators often favor feasible and immediately desirable ideas at the cost of less familiar candidates; this is a selection bias to inspect, not a reason to prefer novelty unconditionally.

Do not accept an LLM's self-evaluation as an independent oracle. Ground factual premises externally and use human or executable validation when the decision permits it.

## Synthesize the Outcome

Choose the form that matches the evidence:

- one recommendation when a candidate clearly dominates;
- a Pareto shortlist when tradeoffs require user judgment;
- a portfolio when uncertainty and option value justify parallel bets;
- a staged sequence when one option creates evidence or capabilities for another;
- an experiment plan when no candidate is sufficiently evidenced.

Do not force a winner merely to appear decisive.

## Experiment Design

Prefer experiments that discriminate between candidates or test a critical assumption.

For each experiment specify:

```text
uncertainty reduced
competing predictions
minimum credible setup
observable decision threshold
cost and time
what decision follows each outcome
```

Avoid tests that collect interesting data without changing the decision.

## Deliverable

Return:

```text
decision frame
gated options and reasons
comparison with evidence quality
challenge results
recommendation / shortlist / portfolio
assumptions that could reverse it
next experiment or handoff
```
