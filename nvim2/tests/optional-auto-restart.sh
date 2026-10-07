#!/usr/bin/env bash
# Optional check: `reload.auto_restart = true` restarts Neovim after an applied
# plugin update fires `PackChanged` (the default only asks for `:restart`).
#
# Environment gate: `:restart` needs a terminal. Measured facts: in headless mode it
# is a no-op (a probe that writes its PID, calls `:restart`, and writes again at the
# replayed `-c` argument only produced the first file), and under `script`'s pty it
# re-executes. The gate therefore probes a pty, and when even that fails the script
# reports SKIP instead of failing.
#
# The probe loads the *real* modules under test (`core.defaults` + `core.pack`) over
# a prepended runtimepath -- no plugin installation, and the user's data directory,
# lockfile and configuration are not touched.
#
# Observation: the probe counts its own executions in a file. A restart re-executes
# Neovim with the same arguments, so the probe runs a second time with a different
# PID -- that is the difference between a restart and a soft reload.
#
# Usage: tests/optional-auto-restart.sh
set -uo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export XDG_DATA_HOME="$tmp/data"
export XDG_CONFIG_HOME="$tmp/config"
export XDG_STATE_HOME="$tmp/state"
export XDG_CACHE_HOME="$tmp/cache"
export CORE_A3_MARKER="$tmp/runs.txt"
export CORE_A3_REPO="$tmp/repo"
export CORE_A3_RTP="${CORE_NVIM_CONFIG:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

mkdir -p "$XDG_CONFIG_HOME" "$CORE_A3_REPO/lua/probe"
git -C "$CORE_A3_REPO" init -q -b main .
printf 'return { v = "v1" }\n' >"$CORE_A3_REPO/lua/probe/init.lua"
git -C "$CORE_A3_REPO" add -A
git -C "$CORE_A3_REPO" -c user.email=t@t -c user.name=t commit -qm v1

# --- does `:restart` re-execute here (pty)? ---------------------------------
# Marker based: `:restart` replays the same command line, so the probe must take the
# "second run" branch -- otherwise it would restart in an endless loop and the gate
# would never observe anything.
cat >"$tmp/gate.lua" <<'LUA'
local path = assert(os.getenv("CORE_A3_GATE"), "gate marker")
local runs = tonumber((vim.fn.readfile(path)[1] or "0")) or 0
runs = runs + 1
vim.fn.writefile({ tostring(runs) }, path)
vim.fn.writefile({ tostring(vim.fn.getpid()) }, path .. "." .. runs)
if runs == 1 then
    vim.cmd("restart")
else
    vim.cmd("qa!")
end
LUA
export CORE_A3_GATE="$tmp/gate.runs"
echo 0 >"$CORE_A3_GATE"
timeout 30 script -qec "nvim -u NONE -c 'luafile $tmp/gate.lua'" /dev/null >/dev/null 2>&1
if [ ! -f "$CORE_A3_GATE.2" ]; then
  printf 'SKIP: `:restart` does not re-execute in this environment (no usable tty).\n'
  printf '      The restart path itself lives in lua/core/pack/init.lua (flush_updates).\n'
  exit 0
fi
printf '  (environment gate: `:restart` works here, pid %s -> %s)\n' "$(cat "$CORE_A3_GATE.1")" "$(cat "$CORE_A3_GATE.2")"

echo 0 >"$CORE_A3_MARKER"

cat >"$tmp/probe.lua" <<'LUA'
-- Results go to files, so the probe does not depend on how a session routes stdout.
vim.opt.runtimepath:prepend(assert(os.getenv("CORE_A3_RTP"), "config runtimepath"))
local marker = assert(os.getenv("CORE_A3_MARKER"), "marker path")
local runs = tonumber((vim.fn.readfile(marker)[1] or "0")) or 0
runs = runs + 1
vim.fn.writefile({ tostring(runs) }, marker)
vim.fn.writefile({ tostring(vim.fn.getpid()) }, marker .. "." .. runs)

if runs == 1 then
    local defaults = require("core.defaults")
    defaults.values.reload.auto_restart = true

    -- The real module under test: `setup()` installs the `PackChanged` autocmd that
    -- leads to `flush_updates()` -> `vim.cmd.restart()`.
    local pack = require("core.pack")
    pack.setup(defaults.get("pack", {}))
    pack.setup_triggers()
    pack.register({ src = "file://" .. assert(os.getenv("CORE_A3_REPO")), name = "probe" })
    vim.api.nvim_exec_autocmds(
        "PackChanged",
        { pattern = "probe", data = { kind = "update", spec = { name = "probe" } } }
    )
    vim.defer_fn(function()
        vim.fn.writefile({ "NO_RESTART" }, marker .. ".timeout")
        vim.cmd("qa!")
    end, 20000)
else
    vim.fn.writefile({ "RESTARTED" }, marker .. ".restarted")
    vim.cmd("qa!")
end
LUA

timeout 90 script -qec "nvim -u NONE -c 'luafile $tmp/probe.lua'" /dev/null >/dev/null 2>&1

fail=0
check() { # check <description> <expected> <actual>
  if [ "$2" = "$3" ]; then
    printf '  ok   %s\n' "$1"
  else
    printf '  FAIL %s (expected %s, got %s)\n' "$1" "$2" "$3"
    fail=1
  fi
}

pid1="$(cat "$CORE_A3_MARKER.1" 2>/dev/null || true)"
pid2="$(cat "$CORE_A3_MARKER.2" 2>/dev/null || true)"

check "the first run recorded itself" "yes" "$([ -f "$CORE_A3_MARKER.1" ] && echo yes || echo no)"
if [ -n "$pid1" ] && [ -n "$pid2" ] && [ "$pid1" != "$pid2" ]; then
  printf '  ok   process restarted (%s -> %s)\n' "$pid1" "$pid2"
else
  printf '  FAIL process did not restart (pid1=%s pid2=%s)\n' "${pid1:-?}" "${pid2:-?}"
  fail=1
fi
check "the restarted session recorded itself" "RESTARTED" "$(cat "$CORE_A3_MARKER.restarted" 2>/dev/null || true)"
check "no timeout fallback was needed" "" "$(cat "$CORE_A3_MARKER.timeout" 2>/dev/null || true)"

if [ "$fail" -eq 0 ]; then
  printf 'PASS: auto_restart restarts Neovim after an update\n'
else
  printf 'FAIL\n'
fi
exit "$fail"
