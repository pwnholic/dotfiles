#!/usr/bin/env python3
"""Validate the local specialist-skill system without third-party packages."""

from __future__ import annotations

import json
import re
import sys
from datetime import date
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AGENTS = ROOT.parent / "AGENTS.md"
SKILLS = (
    "agent-result-validator",
    "brainstorming",
    "software-engineer",
    "onchain-security-researcher",
    "tool-integrator",
)
ADAPTER_ROOT = ROOT / "tool-integrator" / "adapters"
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
OPTIONAL_CASE_FIELDS = {
    "expected_tool_adapters",
    "forbidden_tool_adapters",
}
REQUIRED_ADAPTER_FIELDS = {
    "tool",
    "kind",
    "adapter-version",
    "tested-version",
    "version-probe",
    "calibrated",
    "calibration-level",
    "canonical-source",
}
REQUIRED_ADAPTER_SECTIONS = (
    "Use When",
    "Do Not Use As",
    "Identity and Freshness",
    "Capability Contract",
    "State and Prerequisites",
    "Command Risk Matrix",
    "Data, Network, Secrets, and Cost",
    "Evidence Contract",
    "Blind Spots",
    "Safe Invocation Patterns",
    "Post-Action Verification",
    "Calibration Record",
    "Routing",
    "Reopen Triggers",
)
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


def validate_adapters(errors: list[str]) -> None:
    adapters = sorted(ADAPTER_ROOT.glob("*.md"))
    if not adapters:
        error(errors, f"missing tool adapters under {ADAPTER_ROOT}")
        return
    for path in adapters:
        frontmatter = parse_frontmatter(path, errors)
        missing = REQUIRED_ADAPTER_FIELDS - frontmatter.keys()
        if missing:
            error(errors, f"{path}: missing adapter fields {sorted(missing)}")
        tool = frontmatter.get("tool")
        if tool != path.stem:
            error(errors, f"{path}: tool must match filename stem {path.stem!r}")
        if frontmatter.get("kind") not in {"cli", "mcp", "cli-mcp"}:
            error(errors, f"{path}: invalid adapter kind {frontmatter.get('kind')!r}")
        if frontmatter.get("adapter-version") != "1":
            error(errors, f"{path}: unsupported adapter-version {frontmatter.get('adapter-version')!r}")
        tested = frontmatter.get("tested-version", "")
        if not tested or tested.lower() in {"latest", "unknown", "*"}:
            error(errors, f"{path}: tested-version must bind an exact version")
        if not frontmatter.get("version-probe"):
            error(errors, f"{path}: version-probe is required")
        calibrated = frontmatter.get("calibrated", "")
        try:
            date.fromisoformat(calibrated)
        except ValueError:
            error(errors, f"{path}: calibrated must use YYYY-MM-DD")
        if frontmatter.get("calibration-level") not in {
            "documented",
            "source-bound",
            "observed-partial",
            "observed",
        }:
            error(errors, f"{path}: invalid calibration-level {frontmatter.get('calibration-level')!r}")
        if not frontmatter.get("canonical-source", "").startswith("https://"):
            error(errors, f"{path}: canonical-source must be an https URL")
        text = path.read_text(encoding="utf-8")
        if f"# Tool Adapter: {path.stem}" not in text:
            error(errors, f"{path}: missing matching adapter title")
        for section in REQUIRED_ADAPTER_SECTIONS:
            if f"## {section}" not in text:
                error(errors, f"{path}: missing adapter section {section!r}")


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
        extra = case.keys() - REQUIRED_CASE_FIELDS - OPTIONAL_CASE_FIELDS
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
        for field in (
            "expected_playbooks",
            "forbidden_primary_skills",
            "required_behaviors",
            "forbidden_behaviors",
        ):
            if not isinstance(case.get(field), list):
                error(errors, f"{path}:{number}: {field} must be a list")
        for field in OPTIONAL_CASE_FIELDS:
            if field in case and not isinstance(case.get(field), list):
                error(errors, f"{path}:{number}: {field} must be a list")
        for playbook in case.get("expected_playbooks", []):
            if not isinstance(playbook, str) or not (ROOT / playbook).is_file():
                error(errors, f"{path}:{number}: missing expected playbook {playbook!r}")
            elif primary is None or not playbook.startswith(f"{primary}/playbooks/"):
                error(errors, f"{path}:{number}: playbook {playbook!r} does not belong to primary {primary!r}")
        for forbidden in case.get("forbidden_primary_skills", []):
            if forbidden not in SKILLS:
                error(errors, f"{path}:{number}: invalid forbidden primary {forbidden!r}")
        expected_adapters = case.get("expected_tool_adapters", [])
        forbidden_adapters = case.get("forbidden_tool_adapters", [])
        for field, adapters in (
            ("expected_tool_adapters", expected_adapters),
            ("forbidden_tool_adapters", forbidden_adapters),
        ):
            for adapter in adapters:
                adapter_path = ROOT / adapter if isinstance(adapter, str) else None
                if adapter_path is None or not adapter_path.is_file():
                    error(errors, f"{path}:{number}: missing {field} entry {adapter!r}")
                elif not adapter.startswith("tool-integrator/adapters/"):
                    error(errors, f"{path}:{number}: adapter path outside registry {adapter!r}")
        overlap = set(expected_adapters) & set(forbidden_adapters)
        if overlap:
            error(errors, f"{path}:{number}: adapters both expected and forbidden {sorted(overlap)}")
        cases.append(case)
    if not 20 <= len(cases) <= 80:
        error(errors, f"{path}: expected 20-80 cases, found {len(cases)}")
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
    validate_adapters(errors)
    validate_router(errors)
    validate_eval_cases(errors)
    if errors:
        for message in errors:
            print(f"ERROR: {message}", file=sys.stderr)
        print(f"Validation failed with {len(errors)} error(s).", file=sys.stderr)
        return 1
    print(
        f"Validated {len(SKILLS)} skills, {len(list(ADAPTER_ROOT.glob('*.md')))} tool adapters, "
        "local links, router invariants, and behavioral eval schema."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
