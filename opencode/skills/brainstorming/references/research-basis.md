# Research Basis for the Brainstorming Skill

Maintainer reference. Load when revising the methodology, auditing its assumptions, or explaining why the workflow is structured this way. It is not required during ordinary brainstorming.

## Review Scope

Evidence was retrieved through 2026-08-26. This is a structured evidence synthesis, not a formal systematic review or meta-analysis.

The review asked four operational questions:

1. Which ideation structures improve useful idea generation without collapsing diversity?
2. Which human-group findings transfer plausibly to human-AI or LLM workflows, and which do not?
3. How should ideas be evaluated when novelty, usefulness, feasibility, and risk conflict?
4. Which recent LLM and multi-agent results are mature enough to encode as rules?

Search and selection favored:

- meta-analyses and integrative reviews for established human mechanisms;
- peer-reviewed experiments with direct ideation or idea-selection outcomes;
- official publisher, DOI, conference, or author records;
- recent conference papers and preprints for LLM-specific method leads;
- studies that report task, population, evaluation method, and limitations.

The synthesis excluded marketing claims, unsourced tutorials, popularity-based technique lists, and benchmark claims that did not map to a real skill decision.

## Evidence Classes

These labels express how strongly a finding should constrain the skill:

```text
ESTABLISHED   convergent meta-analytic, review, or replicated evidence;
SUPPORTED     direct peer-reviewed evidence with material domain boundaries;
EMERGING      peer-reviewed conference evidence or recent results awaiting broader replication;
PROVISIONAL   preprint or narrow-domain method lead;
UNRESOLVED    conflicting or insufficient evidence; do not encode as a universal rule.
```

Evidence class is not a quality score for a paper. It describes confidence in transferring a result into a domain-general agent instruction.

## Processed Evidence Matrix

| Method claim                                                                     | Evidence                        | Observed result                                                                                                                                                                                                                                                                        | Applicability boundary                                                                                          | Skill decision                                                                                                                 |
| -------------------------------------------------------------------------------- | ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Generate independently before interactive synthesis                              | ESTABLISHED                     | A brainstorming meta-analysis found interactive groups less productive than nominal groups; four experiments identified production blocking as a major mechanism; a later experiment found hybrid individual-then-group work outperformed team-only work on generation and discernment | Primarily human verbal or organizational ideation; model agents do not experience human turn-taking             | Require an independent baseline before shared discussion; do not prohibit later interaction                                    |
| Interaction can stimulate and interfere                                          | ESTABLISHED                     | Cognitive work on group ideation shows others' ideas can activate relevant knowledge while turn-taking and interference reduce production                                                                                                                                              | Benefit depends on timing, semantic diversity, medium, and task                                                 | Use cross-pollination after independent lanes exist; treat interaction as a controlled phase                                   |
| Examples cause both fixation and inspiration                                     | ESTABLISHED                     | A 43-study design meta-analysis found examples narrowed exploration and variety while sometimes improving novelty and quality                                                                                                                                                          | Design tasks; effect varies with example uncommonness and presentation                                          | Preserve an example-free baseline, vary examples, and measure diversity separately from quality                                |
| Incubation can help, but is moderated                                            | ESTABLISHED                     | A problem-solving meta-analysis found a positive incubation effect, stronger for divergent tasks and sensitive to preparation and intervening-task demand                                                                                                                              | Human cognition; literal waiting does not map directly to model inference                                       | Do not require incubation; when stuck, use a clean context, reframing, or neglected lane as an analogous reset                 |
| Idea count is not sufficient performance evidence                                | ESTABLISHED                     | Hybrid-work research models best-idea performance through quantity, mean quality, variance, and discernment; selection research shows more output does not guarantee better chosen ideas                                                                                               | Exact metrics are task-dependent                                                                                | Track mechanism coverage and candidate quality; never use an arbitrary idea count as completion evidence                       |
| Selection systematically trades originality against feasibility                  | SUPPORTED                       | Idea-selection experiments found participants favored feasible and desirable ideas at the cost of originality; explicit originality instructions changed the tradeoff rather than eliminating it                                                                                       | Laboratory tasks and evaluator context                                                                          | Keep originality visible during screening, apply hard gates separately, and show tradeoffs instead of hiding them in one score |
| Expertise helps evaluation, but decision accountability can suppress novelty     | SUPPORTED                       | A 2024 experiment and an 11-month organizational field study found expertise aided recognition of novel ideas while a decision-maker role reduced novel-idea selection                                                                                                                 | Novelty recognition in scholarly and organizational settings                                                    | Use relevant expertise for consequential evaluation and make the decision owner's risk incentives explicit                     |
| Problem construction matters most for ambiguous problems                         | SUPPORTED, HETEROGENEOUS        | Problem-finding synthesis reported a moderate relationship with creativity; team and design studies connect active problem construction or high-level questions with solution originality and reframing                                                                                | Constructs and effects vary by domain, age, and task; correlation is not universal causation                    | Route to problem framing only when ambiguity or competing frames can materially alter the solution space                       |
| Structured human-AI scaffolding can outperform generic chat                      | SUPPORTED                       | In a two-problem experiment with 152 generators and 505 evaluators, structured Ideator support produced higher rated innovativeness than generic ChatGPT or human-only conditions                                                                                                      | Two text problems, GPT-3.5-era system, users spent different amounts of time and saw different numbers of ideas | Use structured framing and search lanes, but do not claim a universal tool advantage                                           |
| Differentiated human-AI search can improve value without matching human novelty  | SUPPORTED                       | An Organization Science study used 125 solvers, 234 solutions, and 300 external evaluators; human solutions were more novel, while human-AI solutions scored higher on several value and viability measures; differentiated prompting improved the human-AI condition                  | Circular-economy business challenge with strategic prompting                                                    | Separate novelty from value and instruct new passes to differ by mechanism, not just request "more ideas"                      |
| AI assistance may improve individual outputs while homogenizing a pool           | SUPPORTED                       | A Science Advances experiment found story assistance improved ratings, especially for lower-baseline writers, while assisted stories became more similar; a 2025 Nature Human Behaviour report found lower brainstorming diversity with ChatGPT                                        | Creative writing and product ideation; model and interface versions change quickly                              | Treat AI as one source in a portfolio, preserve independent human/user generation, and audit pool-level diversity              |
| Functional diversity and network density interact with task                      | SUPPORTED, CONTEXT-DEPENDENT    | Three online experiments with 617 students found background distribution and network topology affected diversity and utility differently; fully connected networks improved subjective experience without reliably improving objective outcomes                                        | Two text ideation tasks; some collective-level comparisons lacked power                                         | Partition collaboration into distinct lanes; do not assume dense all-to-all discussion or more contributors is better          |
| LLM research ideas can be novel while generation and self-ranking remain brittle | EMERGING                        | ICLR 2025 used 49 expert idea writers and 79 expert reviewers; LLM ideas rated more novel and slightly less feasible, only about 200 of 4,000 seed ideas survived the study's duplicate threshold, and LLM ranking diverged from expert ranking                                        | NLP research proposals, specific models, prompt pipeline, and expert rubric                                     | Deduplicate by mechanism, do not trust generator self-ranking, and require domain validation before calling an idea viable     |
| Multi-agent debate can break a fixed reasoning path                              | EMERGING, INDIRECT              | EMNLP 2024 reported gains over reflection on two counter-intuitive reasoning datasets with adaptive stopping and moderate debate intensity                                                                                                                                             | Reasoning tasks, not open-ended ideation; compute and judge effects are material                                | Keep multi-agent debate optional and purpose-bound; do not encode it as universally superior brainstorming                     |
| Structured reasoning and situated personas may improve LLM diversity             | PROVISIONAL                     | A 2026 four-study preprint attributes LLM diversity loss to fixation and knowledge aggregation; structured reasoning and ordinary personas improved diversity in its tasks                                                                                                             | Preprint, task-specific prompting effects, diversity rather than utility                                        | Prefer knowledge- or incentive-bearing perspectives, but treat persona choice as a method lead rather than a requirement       |
| A synthesis leader and cognitive diversity may improve multi-agent proposals     | PROVISIONAL                     | A 2025 scientific-ideation preprint reports better proposal quality with cognitively diverse, sufficiently expert teams and leader synthesis                                                                                                                                           | Scientific proposal generation; no domain-general replication                                                   | Assign a coordinator for operational ownership, but do not claim that leadership or more agents guarantees better ideas        |
| Creativity measures do not transfer uniformly across constructs                  | PROVISIONAL WITH STRONG CAUTION | A 2026 systematic LLM study found no single tested creativity measure predicted creative writing, divergent thinking, and scientific ideation equally well                                                                                                                             | Preprint and benchmark-dependent; predictive measurement is not real-world success                              | Use task-specific criteria and separate diversity, novelty, usefulness, and feasibility; avoid a universal creativity score    |
| Automated semantic and multi-agent judges are promising, not acceptance oracles  | PROVISIONAL                     | A 2026 preprint reports semantic-entropy and retrieval-based judging results across three open-ended benchmarks                                                                                                                                                                        | Automated metrics, selected benchmarks, and unreplicated judge architecture                                     | Do not make automated creativity metrics mandatory; require human, domain, or executable checks when consequences matter       |
| Latest product-idea results preserve the quality-diversity tradeoff              | PROVISIONAL                     | A July 2026 preprint reports higher purchase intent and more top-decile product ideas from GPT-4, alongside lower perceived novelty and higher pairwise similarity                                                                                                                     | One product brief, model generation setup, predicted purchase intent                                            | Optimize both top-candidate quality and pool diversity; do not infer broad market success                                      |

## Derived Methodology

### Encoded as Core Rules

The following conclusions have enough convergent support or low-regret operational value to remain in `SKILL.md`:

1. Frame the decision and distinguish facts, constraints, assumptions, preferences, and unknowns.
2. Create an independent baseline before shared discussion or evaluation.
3. Measure diversity by underlying mechanism or search region, not wording or idea count.
4. Separate hard constraints from preference-based ranking.
5. Evaluate novelty and usefulness or task fulfillment separately; add feasibility, risk, and reversibility only when relevant.
6. Preserve outliers long enough to expose the originality-feasibility tradeoff.
7. Do not use the generator's self-ranking as an independent acceptance oracle.
8. Hand off brainstormed hypotheses for implementation or domain validation before calling them proven.

### Encoded Only as Conditional Playbooks

These methods are useful under specific triggers but would overconstrain ordinary ideation:

- problem reframing for ambiguous, contested, or ill-defined tasks;
- broad divergent search when coverage or fixation is material;
- examples and external search after an independent baseline;
- multi-person or multi-agent lanes only when collaboration is actually present and authorized;
- formal decision synthesis when options must become a consequential choice.

### Not Encoded as Universal Rules

The evidence does not justify requiring:

- a fixed number of ideas, agents, rounds, perspectives, or evaluation dimensions;
- group discussion before independent generation;
- celebrity personas or any single persona scheme;
- multi-agent debate for ordinary brainstorming;
- one weighted creativity score;
- LLM self-evaluation or LLM-as-judge as final validation;
- literal incubation or waiting periods;
- external research when facts are not causal to the decision.

## Source Ledger

### Established Human Ideation and Creativity Research

1. Mullen, Johnson, and Salas, [Productivity Loss in Brainstorming Groups: A Meta-Analytic Integration](https://doi.org/10.1207/s15324834basp1201_1), _Basic and Applied Social Psychology_ 12(1), 1991.
2. Diehl and Stroebe, [Productivity Loss in Brainstorming Groups: Toward the Solution of a Riddle](https://doi.org/10.1037/0022-3514.53.3.497), _Journal of Personality and Social Psychology_ 53(3), 1987.
3. Nijstad and Stroebe, [How the Group Affects the Mind: A Cognitive Model of Idea Generation in Groups](https://doi.org/10.1207/s15327957pspr1003_1), _Personality and Social Psychology Review_ 10(3), 2006.
4. Girotra, Terwiesch, and Ulrich, [Idea Generation and the Quality of the Best Idea](https://doi.org/10.1287/mnsc.1090.1144), _Management Science_ 56(4), 2010.
5. Sio, Kotovsky, and Cagan, [Fixation or Inspiration? A Meta-Analytic Review of the Role of Examples on Design Processes](https://doi.org/10.1016/j.destud.2015.04.004), _Design Studies_ 39, 2015.
6. Sio and Ormerod, [Does Incubation Enhance Problem Solving? A Meta-Analytic Review](https://doi.org/10.1037/a0014212), _Psychological Bulletin_ 135(1), 2009.
7. Rietzschel, Nijstad, and Stroebe, [The Selection of Creative Ideas After Individual Idea Generation](https://doi.org/10.1348/000712609X414204), _British Journal of Psychology_ 101(1), 2010.
8. Runco and Jaeger, [The Standard Definition of Creativity](https://doi.org/10.1080/10400419.2012.650092), _Creativity Research Journal_ 24(1), 2012. This is a construct reference, not causal evidence.

### Evaluation, Framing, and Collective Structure

9. Criscuolo et al., [Do You See What I See? How Expertise and a Decision-Maker Role Influence the Recognition and Selection of Novel Ideas](https://doi.org/10.1016/j.respol.2024.105139), _Research Policy_ 54(1), 2025 online record / 2024 DOI record.
10. Abdulla, [A Systematic Review and a Meta-Analysis of the Relationship Between Problem Finding and Creativity](https://openscholar.uga.edu/record/21269), doctoral dissertation, 2016. The reported overall relationship was moderate and heterogeneous; it is supporting rather than decisive evidence.
11. Reiter-Palmon et al., [The Effect of Problem Construction on Team Process and Creativity](https://doi.org/10.3389/fpsyg.2018.02098), _Frontiers in Psychology_ 9, 2018.
12. Cao et al., [Effects of Network Connectivity and Functional Diversity Distribution on Human Collective Ideation](https://doi.org/10.1038/s44260-024-00025-9), _npj Complexity_ 2, 2025.

### Human-AI and LLM Ideation

13. Doshi and Hauser, [Generative AI Enhances Individual Creativity but Reduces the Collective Diversity of Novel Content](https://doi.org/10.1126/sciadv.adn5290), _Science Advances_ 10, 2024.
14. Boussioux et al., [The Crowdless Future? Generative AI and Creative Problem-Solving](https://doi.org/10.1287/orsc.2023.18430), _Organization Science_ 35, 2024.
15. Heyman et al., [Supermind Ideator: How Scaffolding Human-AI Collaboration Can Increase Creativity](https://doi.org/10.1177/26339137241305117), _Collective Intelligence_ 3, 2024.
16. Meincke, Nave, and Terwiesch, [ChatGPT Decreases Idea Diversity in Brainstorming](https://doi.org/10.1038/s41562-025-02173-x), _Nature Human Behaviour_ 9, 2025.
17. Si, Yang, and Hashimoto, [Can LLMs Generate Novel Research Ideas?](https://proceedings.iclr.cc/paper_files/paper/2025/hash/ea94957d81b1c1caf87ef5319fa6b467-Abstract-Conference.html), ICLR 2025.
18. Liang et al., [Encouraging Divergent Thinking in Large Language Models Through Multi-Agent Debate](https://doi.org/10.18653/v1/2024.emnlp-main.992), EMNLP 2024.

### Recent Method Leads

19. Deng, Brucks, and Toubia, [Examining and Addressing Barriers to Diversity in LLM-Generated Ideas](https://arxiv.org/abs/2602.20408), preprint, 2026.
20. Chen et al., [Beyond Brainstorming: What Drives High-Quality Scientific Ideas?](https://arxiv.org/abs/2508.04575), preprint, 2025.
21. Schapiro et al., [Assessing the Creativity of Large Language Models: Testing, Limits, and New Frontiers](https://arxiv.org/abs/2605.13450), preprint, 2026.
22. Tan et al., [Automated Creativity Evaluation of Language Models Across Open-Ended Tasks](https://arxiv.org/abs/2606.11762), preprint, 2026.
23. Meincke et al., [Using Large Language Models for Idea Generation in Innovation](https://arxiv.org/abs/2607.27553), preprint version dated 2026-07-30.

## Contradictions and Resolution

The literature does not support a simple claim that AI, groups, examples, or interaction either improve or harm creativity.

The recurring pattern is a tradeoff:

```text
stimulation can improve candidate quality
while exposure can narrow collective diversity;

independent generation can improve breadth
while later interaction can improve discernment or integration;

novelty can increase originality
while reducing perceived feasibility or evaluator comfort.
```

The skill therefore stages these mechanisms instead of choosing one universally:

```text
independent baseline
→ controlled exposure and gap search
→ separate evaluation dimensions
→ independent challenge
→ contextual decision or experiment
```

## Maintenance Rule

When new evidence contradicts this synthesis:

1. identify the exact method claim affected;
2. record study design, population, task, comparator, outcome, and limitation;
3. distinguish a task-specific boundary from general invalidation;
4. update the evidence matrix before changing runtime instructions;
5. change the smallest relevant rule;
6. forward-test the changed skill on realistic requests, not wording checks alone.
