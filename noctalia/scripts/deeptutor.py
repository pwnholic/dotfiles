#!/usr/bin/env python3
"""Toggle DeepTutor and clean up leftover server processes."""

import fcntl
import json
import os
import shutil
import signal
import subprocess
import sys
import time
from collections.abc import Callable
from contextlib import redirect_stderr, redirect_stdout
from dataclasses import dataclass
from datetime import datetime
from io import StringIO
from pathlib import Path
from typing import cast

# Prevent this script's filename from shadowing the installed DeepTutor package.
SCRIPT_DIR: Path = Path(__file__).resolve().parent
sys.path[:] = [
    entry for entry in sys.path if Path(entry or os.getcwd()).resolve() != SCRIPT_DIR
]

try:
    from deeptutor.modules.catalog import require_module
    from deeptutor.runtime.launcher import start as start_web
    from deeptutor.runtime.launcher import stop as stop_web
except ImportError as error:
    print(
        f"Unable to import DeepTutor modules: {error}\n"
        f"Run `uv sync --project {SCRIPT_DIR}` and try again.",
        file=sys.stderr,
    )
    raise SystemExit(1) from None

LOCK_FILE: Path = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")).joinpath(
    f"deeptutor-{os.getuid()}.lock"
)
WORKSPACE_POINTER_FILE: Path = Path(
    os.environ.get("XDG_STATE_HOME", str(Path.home().joinpath(".local", "state")))
).joinpath("deeptutor-control", "workspace-home")
VAULT_DIR: Path = Path.home().joinpath("Vault")
GIT_TIMEOUT_SECONDS: int = 120
NODE_FALLBACK_DIRS: tuple[Path, ...] = (
    Path.home().joinpath(".local", "share", "pi-node", "current", "bin"),
    Path.home().joinpath(".local", "bin"),
    Path("/usr/local/bin"),
)
USAGE: str = "Usage: deeptutor [toggle|start|stop|status]"


@dataclass(frozen=True, slots=True)
class ProcessInfo:
    """Linux process information used to identify and stop a service tree."""

    pid: int
    ppid: int
    args: list[str]
    home: str
    cwd: str


ProcessMap = dict[int, ProcessInfo]
CleanupResult = tuple[int, list[int]]


def notify(summary: str, body: str) -> None:
    """Send a best-effort notification without interrupting process management."""
    try:
        _ = subprocess.run(
            ["notify-send", "--app-name=DeepTutor", summary, body],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
            timeout=5,
        )
    except (OSError, subprocess.TimeoutExpired):
        # Notification delivery must not mask the operation's actual result.
        pass


def read_process(pid: int) -> ProcessInfo | None:
    """Return process details from procfs, or None if the process is gone."""
    try:
        proc_dir: Path = Path("/proc").joinpath(str(pid))
        raw_stat: str = proc_dir.joinpath("stat").read_text(encoding="ascii")
        stat_fields: list[str] = raw_stat.rsplit(") ", 1)[1].split()
        if stat_fields[0] == "Z":
            return None
        raw_args: list[bytes] = proc_dir.joinpath("cmdline").read_bytes().split(b"\0")
        args: list[str] = [arg.decode(errors="replace") for arg in raw_args if arg]
        environ: list[bytes] = proc_dir.joinpath("environ").read_bytes().split(b"\0")
        process_home: str = next(
            (
                entry.partition(b"=")[2].decode(errors="replace")
                for entry in environ
                if entry.startswith(b"DEEPTUTOR_HOME=")
            ),
            "",
        )
        try:
            cwd: str = str(proc_dir.joinpath("cwd").resolve())
        except OSError:
            cwd = ""
        return ProcessInfo(
            pid=pid,
            ppid=int(stat_fields[1]),
            args=args,
            home=process_home,
            cwd=cwd,
        )
    except (OSError, ValueError, IndexError):
        return None


def belongs_to_workspace(process: ProcessInfo, expected_home: Path) -> bool:
    """Match only the DeepTutor launcher and servers for this workspace."""
    try:
        process_home: Path = Path(process.home).expanduser().resolve()
        same_home: bool = process_home == expected_home
    except (OSError, RuntimeError):
        return False
    if not same_home:
        return False

    if "deeptutor_cli.main" in process.args and "start" in process.args:
        return True
    if "deeptutor.api.main:app" in process.args and any(
        "uvicorn" in arg for arg in process.args
    ):
        return True

    is_web_process: bool = Path(process.cwd) == WEB_RUNTIME_DIR
    return is_web_process and any(
        arg.startswith("next-server") or Path(arg).name == "server.js"
        for arg in process.args
    )


def all_processes() -> ProcessMap:
    """Collect non-zombie processes owned by the current user."""
    processes: ProcessMap = {}
    for entry in Path("/proc").iterdir():
        if not entry.name.isdigit():
            continue
        try:
            process: ProcessInfo | None = read_process(int(entry.name))
            if process is not None and entry.stat().st_uid == os.getuid():
                processes[process.pid] = process
        except OSError:
            continue
    return processes


def read_workspace_pointer() -> Path | None:
    """Return the remembered workspace home, or None when unavailable."""
    try:
        raw: str = WORKSPACE_POINTER_FILE.read_text(encoding="utf-8").strip()
    except OSError:
        return None
    if not raw:
        return None
    try:
        return Path(raw).expanduser().resolve()
    except (OSError, RuntimeError):
        return None


def write_workspace_pointer(home: Path) -> None:
    """Remember the resolved workspace home for later calls."""
    try:
        WORKSPACE_POINTER_FILE.parent.mkdir(parents=True, exist_ok=True)
        WORKSPACE_POINTER_FILE.write_text(f"{home}\n", encoding="utf-8")
    except OSError:
        # Best-effort only; resolution still works without persistence.
        pass


def resolve_workspace_home() -> Path:
    """Pick the workspace where DeepTutor runs, remembering the choice.

    The bar widget runs without DEEPTUTOR_HOME in its environment, so relying
    on that variable alone would point status checks at a different workspace
    than the one the launcher was started with. A single live workspace wins,
    and the choice is persisted so later start/stop calls from any environment
    keep using the same workspace.
    """
    env_default: Path = (
        Path(
            os.environ.get(
                "DEEPTUTOR_HOME",
                str(Path.home().joinpath(".local", "share", "deeptutor")),
            )
        )
        .expanduser()
        .resolve()
    )
    persisted: Path | None = read_workspace_pointer()

    homes: list[Path] = []
    for process in all_processes().values():
        if not process.home:
            continue
        joined_args: str = " ".join(process.args)
        if not any(
            marker in joined_args
            for marker in ("deeptutor_cli.main", "deeptutor.api.main:app")
        ):
            continue
        try:
            home: Path = Path(process.home).expanduser().resolve()
        except (OSError, RuntimeError):
            continue
        if home not in homes:
            homes.append(home)

    if len(homes) == 1:
        write_workspace_pointer(homes[0])
        return homes[0]
    if homes:
        # More than one live workspace: keep the remembered one when it is
        # among them, otherwise settle on the first one found.
        if persisted is not None and persisted in homes:
            return persisted
        write_workspace_pointer(homes[0])
        return homes[0]
    if persisted is not None:
        return persisted
    return env_default


DEEPTUTOR_HOME: Path = resolve_workspace_home()
RUNTIME_DIR: Path = DEEPTUTOR_HOME.joinpath("data", "user", "runtime")
STATE_FILE: Path = RUNTIME_DIR.joinpath("launcher.json")
WEB_RUNTIME_DIR: Path = RUNTIME_DIR.joinpath("web")


def launcher_pid(processes: ProcessMap | None = None) -> int | None:
    """Read the detached launcher PID and verify its process identity."""
    try:
        payload: object = cast(
            object, json.loads(STATE_FILE.read_text(encoding="utf-8"))
        )
    except (OSError, ValueError, TypeError, json.JSONDecodeError):
        return None
    if not isinstance(payload, dict):
        return None
    state: dict[str, object] = cast(dict[str, object], payload)
    raw_pid: object = state.get("pid")
    if not isinstance(raw_pid, int) or isinstance(raw_pid, bool) or raw_pid <= 0:
        return None
    processes = all_processes() if processes is None else processes
    process: ProcessInfo | None = processes.get(raw_pid)
    if process and belongs_to_workspace(process, DEEPTUTOR_HOME):
        return raw_pid
    return None


def managed_pids(processes: ProcessMap) -> set[int]:
    """Find launcher, backend, and frontend PIDs for the configured workspace."""
    return {
        pid
        for pid, process in processes.items()
        if belongs_to_workspace(process, DEEPTUTOR_HOME)
    }


def add_descendants(targets: set[int], processes: ProcessMap) -> None:
    """Include child processes before stopping a leftover service tree."""
    pending: list[int] = list(targets)
    while pending:
        parent_pid: int = pending.pop()
        for pid, process in processes.items():
            if process.ppid == parent_pid and pid not in targets:
                targets.add(pid)
                pending.append(pid)


def signal_process(pid: int, sig: signal.Signals) -> bool:
    """Send one signal and report whether the target existed and was permitted."""
    try:
        os.kill(pid, sig)
        return True
    except (ProcessLookupError, PermissionError):
        return False


def force_cleanup(pids: set[int]) -> CleanupResult:
    """Terminate managed processes, then escalate leftovers to SIGKILL."""
    processes: ProcessMap = all_processes()
    targets: set[int] = {pid for pid in pids if pid in processes and pid > 1}
    add_descendants(targets, processes)
    if not targets:
        return 0, []

    signaled: int = 0
    for pid in sorted(targets, reverse=True):
        if signal_process(pid, signal.SIGTERM):
            signaled += 1

    remaining: list[int] = []
    deadline: float = time.monotonic() + 3
    while time.monotonic() < deadline:
        remaining = [pid for pid in targets if read_process(pid) is not None]
        if not remaining:
            return signaled, []
        time.sleep(0.1)
    for pid in remaining:
        _ = signal_process(pid, signal.SIGKILL)
    time.sleep(0.2)
    return signaled, [pid for pid in targets if read_process(pid) is not None]


def call_launcher(
    operation: Callable[[], object], *, require_success: bool = False
) -> tuple[bool, str]:
    """Call a launcher function and retain its console output for errors."""
    console_output = StringIO()
    try:
        with redirect_stdout(console_output), redirect_stderr(console_output):
            result: object = operation()
        if require_success and result is not True:
            output: str = console_output.getvalue().strip()
            return False, output or "The DeepTutor launcher did not complete the stop."
    except SystemExit as error:
        if error.code in (None, 0):
            return True, console_output.getvalue()
        output: str = console_output.getvalue().strip() or str(error)
        return False, output[-1500:]
    except Exception as error:  # noqa: BLE001 - launcher errors belong in a notification
        output = console_output.getvalue().strip() or str(error)
        return False, output[-1500:]
    return True, console_output.getvalue()


def run_git(arguments: list[str]) -> subprocess.CompletedProcess[str]:
    """Run a non-interactive Git command in the Vault repository."""
    return subprocess.run(
        ["git", "-C", str(VAULT_DIR), *arguments],
        stdin=subprocess.DEVNULL,
        capture_output=True,
        text=True,
        check=False,
        timeout=GIT_TIMEOUT_SECONDS,
        env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
    )


def git_error(step: str, result: subprocess.CompletedProcess[str]) -> str:
    """Include Git's diagnostic output when a Vault backup step fails."""
    output: str = "\n".join(
        part.strip() for part in (result.stdout, result.stderr) if part.strip()
    )
    message: str = f"Vault {step} failed with exit code {result.returncode}."
    return f"{message}\n{output}" if output else message


def backup_vault() -> tuple[bool, bool, str]:
    """Commit Vault changes, then try to push the current branch.

    Returns (committed, pushed, output). Only a failure to commit locally is
    fatal for a stop: the working tree would otherwise lose its history.
    A failed push keeps the commit and merely warns, so an offline machine
    can still stop DeepTutor.
    """
    try:
        result: subprocess.CompletedProcess[str] = run_git(["add", "--all"])
        if result.returncode != 0:
            return False, False, git_error("staging", result)

        result = run_git(["diff", "--cached", "--name-only"])
        if result.returncode != 0:
            return False, False, git_error("change detection", result)
        changed_files: list[str] = [path for path in result.stdout.splitlines() if path]
        has_changes: bool = bool(changed_files)
        if has_changes:
            timestamp: str = (
                datetime.now().astimezone().strftime("%Y-%m-%d %H:%M:%S %z")
            )
            commit_message: str = f"{', '.join(changed_files)} | {timestamp}"
            result = run_git(["commit", "-m", commit_message])
            if result.returncode != 0:
                return False, False, git_error("commit", result)

        result = run_git(["push", "--set-upstream", "origin", "HEAD"])
        if result.returncode != 0:
            return True, False, git_error("push", result)
    except (OSError, subprocess.TimeoutExpired) as error:
        return False, False, f"Vault backup could not run: {error}"

    if has_changes:
        return True, True, "Vault changes committed and pushed."
    return True, True, "Vault has no new changes; existing commits pushed."


def node_is_usable(node: str) -> bool:
    """Check that a Node.js binary can actually execute."""
    try:
        result: subprocess.CompletedProcess[bytes] = subprocess.run(
            [node, "--version"],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
            timeout=10,
        )
    except (OSError, subprocess.TimeoutExpired):
        return False
    return result.returncode == 0


def ensure_working_node() -> str | None:
    """Prepend a working Node.js to PATH when the default one is broken.

    The bar widget runs with a minimal system PATH, so a broken system Node
    (for example after a shared-library upgrade) would otherwise make the
    frontend exit immediately and take the backend down with it. Returns an
    error message when no usable Node.js can be found.
    """
    current: str | None = shutil.which("node")
    if current is not None and node_is_usable(current):
        return None
    for directory in NODE_FALLBACK_DIRS:
        candidate: Path = directory.joinpath("node")
        if candidate.is_file() and node_is_usable(str(candidate)):
            os.environ["PATH"] = f"{directory}{os.pathsep}{os.environ.get('PATH', '')}"
            return None
    return "No working Node.js found; repair or install Node.js first."


def start_deeptutor() -> tuple[bool, str]:
    """Start Web through the same launcher module used by the CLI."""

    def launch() -> None:
        node_error: str | None = ensure_working_node()
        if node_error is not None:
            raise RuntimeError(node_error)
        require_module("server")
        require_module("web")
        start_web(home=DEEPTUTOR_HOME, detach=True)

    return call_launcher(launch)


def stop_deeptutor(launcher: int | None) -> tuple[int, list[int], str]:
    """Stop the launcher gracefully, then clean up all remaining service PIDs."""
    output: str = ""
    if launcher is not None:
        stopped: bool
        stopped, output = call_launcher(
            lambda: stop_web(home=DEEPTUTOR_HOME), require_success=True
        )
        if not stopped:
            print(output, file=sys.stderr)

    killed: int
    remaining: list[int]
    killed, remaining = force_cleanup(managed_pids(all_processes()))
    return killed, remaining, output


def main(action: str) -> int:
    """Dispatch one toggle, start, stop, or read-only status operation."""
    if action not in {"toggle", "start", "stop", "status"}:
        print(USAGE, file=sys.stderr)
        return 2

    processes: ProcessMap = all_processes()
    launcher: int | None = launcher_pid(processes)
    running: set[int] = managed_pids(processes)
    if launcher is not None:
        running.add(launcher)

    if action == "status":
        if running:
            print(f"running ({len(running)} managed processes)")
        else:
            print("stopped")
        return 0

    if running and action != "start":
        committed: bool
        pushed: bool
        backup_output: str
        committed, pushed, backup_output = backup_vault()
        if not committed:
            details: str = (
                f"{backup_output}\nDeepTutor stop cancelled; it is still running."
            )
            notify("Vault backup failed", details)
            print(details, file=sys.stderr)
            return 1
        if not pushed:
            notify("Vault push failed", backup_output)
            print(backup_output, file=sys.stderr)
        else:
            print(backup_output)
            notify("Vault backup", backup_output)

        killed: int
        remaining: list[int]
        output: str
        killed, remaining, output = stop_deeptutor(launcher)
        if output:
            print(output, file=sys.stderr)

        if remaining:
            details: str = f"Unable to kill PIDs: {', '.join(map(str, remaining))}"
            notify("DeepTutor stop incomplete", details)
            print(details, file=sys.stderr)
            return 1
        message: str = "DeepTutor stopped."
        if killed:
            message += f" Auto-killed {killed} leftover process(es)."
        notify("DeepTutor", message)
        return 0

    if action == "stop":
        notify("DeepTutor", "DeepTutor is already stopped.")
        return 0
    if running:
        notify("DeepTutor", f"DeepTutor is already running ({len(running)} processes).")
        return 0

    success: bool
    success, output = start_deeptutor()
    if not success:
        notify("DeepTutor failed to start", output)
        print(output, file=sys.stderr)
        return 1
    notify("DeepTutor", "Launcher started; the frontend is getting ready.")
    print("DeepTutor launcher started.")
    return 0


if __name__ == "__main__":
    action: str = sys.argv[1] if len(sys.argv) > 1 else "toggle"
    # Status is read-only: never compete with a start/stop lock or notify spam.
    if action == "status":
        raise SystemExit(main(action))

    try:
        lock = LOCK_FILE.open("w")
    except OSError as error:
        print(f"Unable to open DeepTutor lock file: {error}", file=sys.stderr)
        raise SystemExit(1) from None

    with lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            details: str = "Another DeepTutor operation is still running."
            notify("DeepTutor busy", details)
            print(details, file=sys.stderr)
            raise SystemExit(1)
        except OSError as error:
            print(f"Unable to lock DeepTutor operation: {error}", file=sys.stderr)
            raise SystemExit(1) from None

        try:
            exit_code: int = main(sys.argv[1] if len(sys.argv) > 1 else "toggle")
        except (OSError, ValueError) as error:
            details: str = f"DeepTutor operation failed safely: {error}"
            notify("DeepTutor error", details)
            print(details, file=sys.stderr)
            raise SystemExit(1) from None
        raise SystemExit(exit_code)
