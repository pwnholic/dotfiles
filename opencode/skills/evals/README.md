# Specialist Skill Behavioral Evals

This suite tests decisions that static Markdown validation cannot establish:

- primary-skill routing and deliberate fallback;
- minimum sufficient playbook selection;
- negative routing and forbidden behavior;
- cross-specialist handoff;
- independent result-validation versus producer/domain verification;
- evidence, authorization, and completion invariants.

## Case Format

Each line in `skill-routing.jsonl` is an independent case:

```text
id | prompt | expected_primary_skill | expected_playbooks
forbidden_primary_skills | required_behaviors | forbidden_behaviors
expected_handoff | optional expected_tool_adapters / forbidden_tool_adapters
```

`expected_primary_skill: null` means no repository specialist matches. The
agent should remain under the shared core and state the gap when material.

Tool-adapter fields are optional because most cases do not require a specific
tool. When present, each entry is a repository-relative path under
`tool-integrator/adapters/`. Loading an adapter does not change the expected
primary specialist.

## Evaluation Protocol

1. Run every case in an isolated clean workspace with the production-equivalent
   agent harness.
2. Do not reveal expected fields to the evaluated agent.
3. Record the selected primary skill, every playbook, and every tool adapter
   actually loaded.
4. Grade routing, playbook selection, and adapter selection deterministically
   from the trace.
5. Grade required/forbidden semantic behaviors with executable checks, human
   review, or a documented rubric. Do not use an LLM judge as the only oracle
   for consequential behavior.
6. Run paired conditions when changing the system: previous version versus
   candidate version. A no-skill baseline is useful when measuring marginal
   value rather than only regression.
7. Repeat enough trials to distinguish a stable effect from a lucky trajectory;
   report both task success and consistency rather than rerunning until green.

Keep positive and negative routing cases balanced. Add real failures when they
occur, but do not encode incidental wording as the expected behavior.

## Static Validation

From this directory's parent:

```bash
python3 scripts/validate_skills.py
```

The validator uses only the Python standard library. It checks frontmatter,
folder/name agreement, relative links, stale names, research references, and
the eval schema. It does not claim that behavioral cases passed.
