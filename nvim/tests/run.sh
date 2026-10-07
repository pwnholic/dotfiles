#!/usr/bin/env bash
# Headless test suite for this configuration.
#
# Each test file runs in its own Neovim process with the real configuration and
# an isolated state directory (so the user's real `stdpath('state')` is not
# touched). Plugins are never installed: headless sessions refuse to install,
# and t06 uses local `file://` fixtures instead of network sources.
#
# Usage: tests/run.sh [pattern] [--filter=pattern]
#
# Every suite must print its `RESULT:` line: a suite that dies before finishing
# (for example an early `qa!`) is reported as a failure instead of silently
# passing with exit code 0.
set -uo pipefail

config_dir="${CORE_NVIM_CONFIG:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
pattern=""
for arg in "$@"; do
  case "$arg" in
    --filter=*) pattern="${arg#--filter=}" ;;
    -h | --help)
      sed -n '2,14p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      printf 'unknown option: %s\n' "$arg" >&2
      exit 2
      ;;
    *) pattern="$arg" ;;
  esac
done
pattern="${pattern:-t*.lua}"

tmp_state="$(mktemp -d)"
trap 'rm -rf "$tmp_state"' EXIT

export XDG_STATE_HOME="$tmp_state"
export XDG_CONFIG_HOME="$(dirname "$config_dir")"

failed=0
ran=0
for test_file in "$config_dir"/tests/$pattern; do
  [ -e "$test_file" ] || continue
  ran=$((ran + 1))
  printf '\n=== %s\n' "$(basename "$test_file")"
  # A hanging test must not hang the suite: each file gets a hard timeout.
  started=$SECONDS
  output="$(timeout "${CORE_TEST_TIMEOUT:-240}" nvim --headless -c "luafile $test_file" 2>&1)"
  status=$?
  printf '%s\n' "$output"
  if [ "$status" -ne 0 ]; then
    printf '  ERROR: suite exited with status %d\n' "$status"
    failed=$((failed + 1))
  elif ! grep -q '^RESULT:' <<<"$output"; then
    printf '  ERROR: no RESULT line -- the suite did not run to completion\n'
    failed=$((failed + 1))
  else
    printf '  (%ss)\n' "$((SECONDS - started))"
  fi
done

printf '\n%d test file(s) run, %d failed\n' "$ran" "$failed"
exit "$failed"
