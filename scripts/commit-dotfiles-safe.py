#!/usr/bin/env python3
"""Commit and push dotfiles while keeping local secrets out of Git.

The working tree is never rewritten. A temporary Git index is populated from
the current tree, secret values are replaced with REDACTED in that index, and
only that sanitized index is committed and pushed. The original local files
therefore keep their real credentials after the operation.

Usage:
    scripts/commit-dotfiles-safe.py [commit message]
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path


REDACTED = "REDACTED"

# High-confidence provider/token formats.
DIRECT_SECRET_PATTERNS = [
    (re.compile(r"gho_[A-Za-z0-9_\-]{20,}"), "GitHub OAuth token"),
    (re.compile(r"github_pat_[A-Za-z0-9_\-]{20,}"), "GitHub fine-grained token"),
    (re.compile(r"ghp_[A-Za-z0-9_\-]{20,}"), "GitHub token"),
    (re.compile(r"xox[baprs]-[A-Za-z0-9-]{10,}"), "Slack token"),
    (re.compile(r"AKIA[0-9A-Z]{16}"), "AWS access key"),
    (re.compile(r"AIza[0-9A-Za-z_\-]{30,}"), "Google API key"),
    (re.compile(r"sk_(?:live|test)_[A-Za-z0-9]{16,}"), "Stripe key"),
    (re.compile(r"\beyJ[A-Za-z0-9_\-]{20,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\b"), "JWT"),
]

PRIVATE_KEY = re.compile(
    r"-----BEGIN [^-\r\n]+ PRIVATE KEY-----.*?-----END [^-\r\n]+ PRIVATE KEY-----",
    re.DOTALL,
)

# Covers JSON, YAML, TOML, shell, and dotenv-style assignments without
# treating ordinary prose containing words like "secret" as a credential.
ASSIGNED_SECRET = re.compile(
    r"(?P<prefix>(?<![\w-])(?:[\"']?(?:oauth[_-]?token|access[_-]?token|"
    r"refresh[_-]?token|restore[_-]?token|api[_-]?key|client[_-]?secret|secret[_-]?key|"
    r"private[_-]?key|password|mnemonic|token)[\"']?\s*[:=]\s*))"
    r"(?P<quote>[\"']?)(?P<value>[^\"',\r\n#}]*) (?P=quote)",
    re.IGNORECASE | re.VERBOSE,
)

URL_PASSWORD = re.compile(
    r"(?P<prefix>://[^\s:@/]+:)(?P<password>[^\s/@]+)(?P<suffix>@)",
)

SOLANA_KEY_ARRAY = re.compile(r"^\s*\[(?:\s*\d{1,3}\s*,){31,}\s*\d{1,3}\s*\]\s*$")

TRACKED_JUNK_PREFIXES = ("go/telemetry/local/",)
TRACKED_JUNK_FILES = {"pgcli/history", "pgcli/log"}


def run(args: list[str], *, env: dict[str, str] | None = None, text: bool = False) -> subprocess.CompletedProcess:
    return subprocess.run(args, check=True, env=env, text=text)


def output(args: list[str], *, env: dict[str, str] | None = None) -> bytes:
    return subprocess.check_output(args, env=env)


def repo_root() -> Path:
    return Path(output(["git", "rev-parse", "--show-toplevel"]).decode().strip())


def sanitize(path: str, data: bytes) -> tuple[bytes, list[str]]:
    """Return sanitized bytes and high-level findings, never secret values."""
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        # Binary credential stores should not be committed as binary blobs.
        if Path(path).name.lower() in {"credentials", "keyring", "id_rsa", "id_ed25519"}:
            return (REDACTED + "\n").encode(), ["binary credential store"]
        return data, []

    findings: list[str] = []

    if Path(path).name == "id.json" and SOLANA_KEY_ARRAY.fullmatch(text):
        text = ("[\"" + REDACTED + "\"]\n")
        findings.append("private-key array")

    if Path(path).name == "upload.token" and text.strip():
        text = REDACTED + "\n"
        findings.append("token file")

    def private_key_replacement(match: re.Match[str]) -> str:
        findings.append("private key block")
        return REDACTED

    text = PRIVATE_KEY.sub(private_key_replacement, text)

    for pattern, label in DIRECT_SECRET_PATTERNS:
        def direct_replacement(match: re.Match[str], label: str = label) -> str:
            findings.append(label)
            return REDACTED

        text = pattern.sub(direct_replacement, text)

    def assignment_replacement(match: re.Match[str]) -> str:
        value = match.group("value").strip()
        if not value or value == REDACTED:
            return match.group(0)
        findings.append("credential assignment")
        quote = match.group("quote")
        return match.group("prefix") + quote + REDACTED + quote

    config_suffixes = {
        ".bash", ".conf", ".cfg", ".config", ".desktop", ".env", ".fish",
        ".ini", ".json", ".jsonc", ".properties", ".sh", ".toml", ".yaml", ".yml", ".zsh",
    }
    config_like = Path(path).suffix.lower() in config_suffixes or Path(path).name.lower() in {
        "config", "env", "hosts",
    }

    def url_replacement(match: re.Match[str]) -> str:
        findings.append("URL password")
        return match.group("prefix") + REDACTED + match.group("suffix")

    # Apply line-oriented assignments while leaving comments and empty values
    # intact. This avoids changing descriptive documentation unnecessarily and
    # prevents source code such as ``token:gsub(...)`` from being altered.
    sanitized_lines: list[str] = []
    for line in text.splitlines(keepends=True):
        if line.lstrip().startswith(("#", ";", "//")):
            sanitized_lines.append(line)
            continue
        if config_like:
            line = ASSIGNED_SECRET.sub(assignment_replacement, line)
        line = URL_PASSWORD.sub(url_replacement, line)
        sanitized_lines.append(line)
    text = "".join(sanitized_lines)
    return text.encode("utf-8"), findings


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
    for mode, oid, path in index_entries(index_env):
        if mode == "160000":
            continue  # Git submodule entry; its commit is not a blob.
        data = output(["git", "cat-file", "blob", oid])
        sanitized, file_findings = sanitize(path, data)
        if not file_findings:
            continue
        findings.extend((path, finding) for finding in sorted(set(file_findings)))
        new_oid = subprocess.check_output(
            ["git", "hash-object", "-w", "--stdin"], input=sanitized, env=index_env
        ).strip().decode()
        run(["git", "update-index", "--add", "--cacheinfo", f"{mode},{new_oid},{path}"], env=index_env)
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
    for mode, oid, path in index_entries(index_env):
        if mode == "160000":
            continue
        data = output(["git", "cat-file", "blob", oid])
        sanitized, findings = sanitize(path, data)
        if findings or sanitized != data:
            unresolved.append(path)
    return sorted(set(unresolved))


def main() -> int:
    root = repo_root()
    os.chdir(root)

    status = output(["git", "status", "--porcelain=v1"]).decode()
    if not status.strip():
        print("Tidak ada perubahan untuk di-commit.")
        return 0
    # Preserve the user's real index. The script intentionally refuses to
    # combine with pre-existing staged work because that is easy to mismerge.
    staged = subprocess.run(["git", "diff", "--cached", "--quiet"]).returncode
    if staged != 0:
        print("Abort: ada perubahan yang sudah di-stage. Commit/stash dulu perubahan tersebut.", file=sys.stderr)
        return 2

    branch = output(["git", "branch", "--show-current"]).decode().strip()
    if not branch:
        print("Abort: HEAD detached; branch diperlukan untuk push.", file=sys.stderr)
        return 2

    message = " ".join(sys.argv[1:]).strip() or "Update dotfiles safely"
    with tempfile.TemporaryDirectory(prefix="dotfiles-safe-") as temp_dir:
        temp_index = str(Path(temp_dir) / "index")
        index_env = os.environ.copy()
        index_env["GIT_INDEX_FILE"] = temp_index

        # Start the temporary index from HEAD, never from the user's index.
        run(["git", "read-tree", "HEAD"], env={**os.environ, "GIT_INDEX_FILE": temp_index})
        index_env["GIT_INDEX_FILE"] = temp_index
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
        if findings:
            for path, kind in sorted(set(findings)):
                print(f"  {path}: {kind}")

        if subprocess.run(["git", "diff", "--cached", "--quiet"], env=index_env).returncode == 0:
            print("Tidak ada perubahan konfigurasi yang berguna setelah file sampah diabaikan.")
            return 0

        run(["git", "diff", "--cached", "--stat"], env=index_env)
        run(["git", "commit", "-m", message], env=index_env)
        commit = output(["git", "rev-parse", "HEAD"]).decode().strip()
        run(["git", "push", "origin", branch])

        # Point the real index at the new sanitized commit. Working-tree files
        # containing secrets remain untouched and appear as local modifications.
        run(["git", "read-tree", commit])
        print(f"Push berhasil: {commit[:12]} ({branch}).")
        print("Key lokal tidak diubah; file yang berisi key akan tampak sebagai perubahan lokal karena commit berisi REDACTED.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
