#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["detect-secrets>=1.5.0"]
# ///

"""Commit and push dotfiles while keeping local secrets out of Git.

The working tree is never rewritten. A temporary Git index is populated from
the current tree, ``detect-secrets`` scans each staged blob, and detected
values are replaced with ``REDACTED`` in that index only. Local credential
files remain untouched and ignored by ``.gitignore``.

Usage:
    scripts/commit-dotfiles-safe.py [commit message]
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path

from detect_secrets.core import scan as secret_scan
from detect_secrets.settings import default_settings

REDACTED = "REDACTED"
SOLANA_KEY_ARRAY = re.compile(r"^\s*\[(?:\s*\d{1,3}\s*,){31,}\s*\d{1,3}\s*\]\s*$")
RESTORE_TOKEN_ASSIGNMENT = re.compile(
    r"(?P<prefix>[\"']?restore[_-]?token[\"']?\s*[:=]\s*)"
    r"(?P<quote>[\"']?)(?P<value>[^\"',\r\n#}]*)(?P=quote)",
    re.IGNORECASE,
)

TRACKED_JUNK_PREFIXES = ("go/telemetry/local/",)
TRACKED_JUNK_FILES = {"pgcli/history", "pgcli/log"}


def run(
    args: list[str],
    *,
    env: dict[str, str] | None = None,
    text: bool = False,
    input_data: bytes | None = None,
) -> subprocess.CompletedProcess:
    return subprocess.run(args, check=True, env=env, text=text, input=input_data)


def output(args: list[str], *, env: dict[str, str] | None = None) -> bytes:
    return subprocess.check_output(args, env=env)


def repo_root() -> Path:
    return Path(output(["git", "rev-parse", "--show-toplevel"]).decode().strip())


def ignore_detector_finding(secret: object, scan_data: bytes) -> bool:
    """Filter documented/configuration false positives without hiding values."""
    line_number = getattr(secret, "line_number", 0)
    lines = scan_data.decode("utf-8", errors="replace").splitlines()
    line = lines[line_number - 1] if 0 < line_number <= len(lines) else ""
    stripped = line.lstrip()
    if stripped.startswith(("#", ";", "//")):
        return True

    value = (getattr(secret, "secret_value", None) or "").strip().lower()
    if getattr(secret, "type", "") == "Secret Keyword" and value in {
        "false", "true", "default", "none", "null", "empty", "[]", "{}", "0", "1",
    }:
        return True

    # Hashes, checksums, and version ignore markers are identifiers, not
    # credentials. This avoids redacting normal tool metadata flagged by the
    # entropy detector.
    if getattr(secret, "type", "") == "Hex High Entropy String" and re.search(
        r"(?i)(hash|checksum|digest|version)", line,
    ):
        return True
    return False


def detect_and_redact(path: str, data: bytes) -> tuple[bytes, list[str]]:
    """Use detect-secrets and return sanitized bytes without exposing values."""
    try:
        data.decode("utf-8")
    except UnicodeDecodeError:
        if Path(path).name.lower() in {"credentials", "keyring", "id_rsa", "id_ed25519"}:
            return (REDACTED + "\n").encode(), ["binary credential store"]
        return data, []

    scan_data = data
    findings: list[str] = []
    suffix = Path(path).suffix or ".conf"

    # scan_file() intentionally stops after the first line containing a
    # finding. Re-scan after masking each finding so later lines are covered.
    with tempfile.NamedTemporaryFile(suffix=suffix) as candidate:
        for _ in range(256):
            candidate.seek(0)
            candidate.truncate()
            candidate.write(scan_data)
            candidate.flush()
            potential = list(secret_scan.scan_file(candidate.name))
            if not potential:
                break

            progress = False
            for secret in potential:
                value = secret.secret_value
                if not value or value == REDACTED:
                    continue
                raw = value.encode("utf-8")

                # GitHub's detector can also report a short provider prefix
                # (e.g. ``gho``). Mask it only in the scan copy so the real
                # longer token on this or a later line can still be found.
                if len(raw) < 4:
                    if raw in scan_data:
                        scan_data = scan_data.replace(raw, REDACTED.encode())
                        progress = True
                    continue

                if ignore_detector_finding(secret, scan_data):
                    if raw in scan_data:
                        scan_data = scan_data.replace(raw, REDACTED.encode())
                        progress = True
                    continue

                if raw in data:
                    data = data.replace(raw, REDACTED.encode())
                    scan_data = scan_data.replace(raw, REDACTED.encode())
                    findings.append(secret.type)
                    progress = True

            if not progress:
                break

    text = data.decode("utf-8")

    # Format-specific values that are not reliably detected by heuristics:
    # Solana's JSON keypair array and OBS's opaque RestoreToken.
    if Path(path).name == "id.json" and SOLANA_KEY_ARRAY.fullmatch(text):
        text = f'["{REDACTED}"]\n'
        findings.append("Solana private-key array")

    if Path(path).name == "upload.token" and text.strip():
        text = REDACTED + "\n"
        findings.append("token file")

    def restore_replacement(match: re.Match[str]) -> str:
        value = match.group("value").strip()
        if not value or value == REDACTED:
            return match.group(0)
        findings.append("opaque restore token")
        quote = match.group("quote")
        return match.group("prefix") + quote + REDACTED + quote

    lines: list[str] = []
    for line in text.splitlines(keepends=True):
        if not line.lstrip().startswith(("#", ";", "//")):
            line = RESTORE_TOKEN_ASSIGNMENT.sub(restore_replacement, line)
        lines.append(line)
    return "".join(lines).encode("utf-8"), findings


def index_entries(index_env: dict[str, str]) -> list[tuple[str, str, str]]:
    raw = output(["git", "ls-files", "-s", "-z"], env=index_env)
    entries: list[tuple[str, str, str]] = []
    for record in raw.rstrip(b"\0").split(b"\0"):
        if not record:
            continue
        meta, path_bytes = record.rsplit(b"\t", 1)
        mode, oid, _stage = meta.decode().split()
        entries.append((mode, oid, os.fsdecode(path_bytes)))
    return entries


def sanitize_index(index_env: dict[str, str]) -> list[tuple[str, str]]:
    findings: list[tuple[str, str]] = []
    with default_settings():
        for mode, oid, path in index_entries(index_env):
            if mode == "160000":
                continue  # Git submodule entry; its commit is not a blob.
            data = output(["git", "cat-file", "blob", oid])
            sanitized, file_findings = detect_and_redact(path, data)
            if not file_findings:
                continue
            findings.extend((path, finding) for finding in sorted(set(file_findings)))
            new_oid = subprocess.check_output(
                ["git", "hash-object", "-w", "--stdin"],
                input=sanitized,
                env=index_env,
            ).strip().decode()
            run(
                ["git", "update-index", "--add", "--cacheinfo", f"{mode},{new_oid},{path}"],
                env=index_env,
            )
    return findings


def remove_tracked_junk(index_env: dict[str, str]) -> None:
    """Drop old cache/history entries from the commit without deleting locals."""
    paths = [
        path
        for _mode, _oid, path in index_entries(index_env)
        if path in TRACKED_JUNK_FILES or path.startswith(TRACKED_JUNK_PREFIXES)
    ]
    if paths:
        run(["git", "update-index", "--force-remove", "--", *paths], env=index_env)


def verify_index(index_env: dict[str, str]) -> list[str]:
    unresolved: list[str] = []
    with default_settings():
        for mode, oid, path in index_entries(index_env):
            if mode == "160000":
                continue
            data = output(["git", "cat-file", "blob", oid])
            sanitized, findings = detect_and_redact(path, data)
            if findings or sanitized != data:
                unresolved.append(path)
    return sorted(set(unresolved))


def main() -> int:
    root = repo_root()
    os.chdir(root)

    if not output(["git", "status", "--porcelain=v1"]).strip():
        print("Tidak ada perubahan untuk di-commit.")
        return 0

    # Do not combine with pre-existing staged work; that could mismerge user
    # intent into the temporary sanitized index.
    if subprocess.run(["git", "diff", "--cached", "--quiet"]).returncode != 0:
        print("Abort: ada perubahan yang sudah di-stage. Commit/stash dulu perubahan tersebut.", file=sys.stderr)
        return 2

    branch = output(["git", "branch", "--show-current"]).decode().strip()
    if not branch:
        print("Abort: HEAD detached; branch diperlukan untuk push.", file=sys.stderr)
        return 2

    base_message = " ".join(sys.argv[1:]).strip() or "Update dotfiles safely"
    timestamp = datetime.now().astimezone().isoformat(timespec="seconds")
    message = f"{base_message} ({timestamp})"

    with tempfile.TemporaryDirectory(prefix="dotfiles-safe-") as temp_dir:
        temp_index = str(Path(temp_dir) / "index")
        index_env = os.environ.copy()
        index_env["GIT_INDEX_FILE"] = temp_index

        run(["git", "read-tree", "HEAD"], env=index_env)
        run(["git", "add", "-A", "--", "."], env=index_env)
        remove_tracked_junk(index_env)

        findings = sanitize_index(index_env)
        unresolved = verify_index(index_env)
        if unresolved:
            print("Abort: secret masih terdeteksi setelah sanitasi pada:", file=sys.stderr)
            for path in unresolved:
                print(f"  {path}", file=sys.stderr)
            return 3

        print(f"Sanitasi selesai; {len(findings)} temuan diganti menjadi REDACTED.")
        for path, kind in sorted(set(findings)):
            print(f"  {path}: {kind}")

        if subprocess.run(["git", "diff", "--cached", "--quiet"], env=index_env).returncode == 0:
            print("Tidak ada perubahan konfigurasi yang berguna setelah file sampah diabaikan.")
            return 0

        run(["git", "diff", "--cached", "--stat"], env=index_env)
        run(["git", "commit", "-m", message], env=index_env)
        commit = output(["git", "rev-parse", "HEAD"]).decode().strip()
        run(["git", "push", "origin", branch])

        # The index now describes the sanitized commit. Local files containing
        # real credentials are untouched and may appear as local modifications.
        run(["git", "read-tree", commit])
        print(f"Push berhasil: {commit[:12]} ({branch}).")
        print("Key lokal tidak diubah; file yang berisi key akan tampak sebagai perubahan lokal karena commit berisi REDACTED.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
