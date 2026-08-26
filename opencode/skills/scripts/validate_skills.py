#!/usr/bin/env python3
"""Validate the local specialist-skill system without third-party packages."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AGENTS = ROOT.parent / "AGENTS.md"
SKILLS = ("brainstorming", "software-engineer", "onchain-security-researcher")
REQUIRED_CASE_FIELDS = {
    "id",
    "prompt",
    "expected_primary_skill",
    "expected_playbooks",
    "forbidden_primary_skills",
    "required_behaviors",
    "forbidden_behaviors",
    "expected_handoff",
}
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)]+)\)")


def error(errors: list[str], message: str) -> None:
    errors.append(message)


def parse_frontmatter(path: Path, errors: list[str]) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        error(errors, f"{path}: missing opening frontmatter delimiter")
        return {}
    try:
        closing = lines.index("---", 1)
    except ValueError:
        error(errors, f"{path}: missing closing frontmatter delimiter")
        return {}
    values: dict[str, str] = {}
    for line in lines[1:closing]:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if ":" not in line:
            error(errors, f"{path}: unsupported frontmatter line: {line!r}")
            continue
        key, value = line.split(":", 1)
        values[key.strip()] = value.strip().strip('"\'')
    return values


def validate_skills(errors: list[str]) -> None:
    for name in SKILLS:
        directory = ROOT / name
        skill_file = directory / "SKILL.md"
        if not skill_file.is_file():
            error(errors, f"missing {skill_file}")
            continue
        frontmatter = parse_frontmatter(skill_file, errors)
        if frontmatter.get("name") != name:
            error(errors, f"{skill_file}: name must match directory {name!r}")
        description = frontmatter.get("description", "")
        if not description:
            error(errors, f"{skill_file}: description is required")
        elif len(description) > 1024:
            error(errors, f"{skill_file}: description exceeds 1024 characters")
        research = directory / "references" / "research-basis.md"
        if not research.is_file():
            error(errors, f"missing maintainer evidence {research}")
        if skill_file.read_text(encoding="utf-8").count("\n") + 1 > 500:
            error(errors, f"{skill_file}: entrypoint exceeds 500 lines")


def validate_links(errors: list[str]) -> None:
    files = [AGENTS, *ROOT.glob("**/*.md")]
    for path in files:
        text = path.read_text(encoding="utf-8")
        for target in LINK_RE.findall(text):
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            local = target.split("#", 1)[0]
            if local and not (path.parent / local).resolve().exists():
                error(errors, f"{path}: broken relative link {target!r}")


def validate_router(errors: list[str]) -> None:
    text = AGENTS.read_text(encoding="utf-8")
    for name in SKILLS:
        if f"`{name}/SKILL.md`" not in text:
            error(errors, f"{AGENTS}: missing router entry for {name}")
    stale = re.search(r"(?<!onchain-)security-researcher", text)
    if stale:
        error(errors, f"{AGENTS}: stale generic security-researcher name")
    if "all specialist tasks" not in text:
        error(errors, f"{AGENTS}: shared core is not declared for all specialists")
    for path in [*ROOT.glob("**/*.md"), *ROOT.glob("**/*.jsonl")]:
        if re.search(r"(?<!onchain-)security-researcher", path.read_text(encoding="utf-8")):
            error(errors, f"{path}: stale generic security-researcher name")


def validate_eval_cases(errors: list[str]) -> None:
    path = ROOT / "evals" / "skill-routing.jsonl"
    if not path.is_file():
        error(errors, f"missing {path}")
        return
    cases: list[dict[str, object]] = []
    ids: set[str] = set()
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip():
            continue
        try:
            case = json.loads(raw)
        except json.JSONDecodeError as exc:
            error(errors, f"{path}:{number}: invalid JSON: {exc}")
            continue
        missing = REQUIRED_CASE_FIELDS - case.keys()
        extra = case.keys() - REQUIRED_CASE_FIELDS
        if missing:
            error(errors, f"{path}:{number}: missing fields {sorted(missing)}")
        if extra:
            error(errors, f"{path}:{number}: unexpected fields {sorted(extra)}")
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id:
            error(errors, f"{path}:{number}: id must be a non-empty string")
        elif case_id in ids:
            error(errors, f"{path}:{number}: duplicate id {case_id!r}")
        else:
            ids.add(case_id)
        primary = case.get("expected_primary_skill")
        if primary is not None and primary not in SKILLS:
            error(errors, f"{path}:{number}: invalid expected primary {primary!r}")
        for field in ("expected_playbooks", "forbidden_primary_skills", "required_behaviors", "forbidden_behaviors"):
            if not isinstance(case.get(field), list):
                error(errors, f"{path}:{number}: {field} must be a list")
        for playbook in case.get("expected_playbooks", []):
            if not isinstance(playbook, str) or not (ROOT / playbook).is_file():
                error(errors, f"{path}:{number}: missing expected playbook {playbook!r}")
            elif primary is None or not playbook.startswith(f"{primary}/playbooks/"):
                error(errors, f"{path}:{number}: playbook {playbook!r} does not belong to primary {primary!r}")
        for forbidden in case.get("forbidden_primary_skills", []):
            if forbidden not in SKILLS:
                error(errors, f"{path}:{number}: invalid forbidden primary {forbidden!r}")
        cases.append(case)
    if not 20 <= len(cases) <= 50:
        error(errors, f"{path}: expected an initial 20-50 cases, found {len(cases)}")
    for name in SKILLS:
        if not any(case.get("expected_primary_skill") == name for case in cases):
            error(errors, f"{path}: no positive routing case for {name}")
        if not any(name in case.get("forbidden_primary_skills", []) for case in cases):
            error(errors, f"{path}: no negative routing case for {name}")
    if not any(case.get("expected_primary_skill") is None for case in cases):
        error(errors, f"{path}: no deliberate specialist-fallback case")


def main() -> int:
    errors: list[str] = []
    validate_skills(errors)
    validate_links(errors)
    validate_router(errors)
    validate_eval_cases(errors)
    if errors:
        for message in errors:
            print(f"ERROR: {message}", file=sys.stderr)
        print(f"Validation failed with {len(errors)} error(s).", file=sys.stderr)
        return 1
    print("Validated 3 skills, local links, router invariants, and behavioral eval schema.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
