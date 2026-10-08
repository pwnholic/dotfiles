#!/usr/bin/env bash
# Optional check, kept out of the headless suite because it needs its own XDG
# roots: proves that *applying* a plugin update works end to end.
#
# It never touches the real configuration, plugin directory or lockfile. A
# throwaway XDG tree plus a local `file://` fixture repository are used, and the
# update is applied with Neovim's own `vim.pack.update()` -- the same code path
# `:PackUpdate` uses, where `:write` in the review buffer applies.
#
# When `vim.pack.update()` fails, its message goes to stderr (dropped here) and
# the `REV` line of the second session never appears; the last two checks then
# fail, which is exactly the signal we want.
#
# Usage: tests/optional-packupdate-apply.sh
set -uo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export XDG_DATA_HOME="$tmp/data"
export XDG_CONFIG_HOME="$tmp/config"
export XDG_STATE_HOME="$tmp/state"
export XDG_CACHE_HOME="$tmp/cache"

repo="$tmp/repo"
mkdir -p "$repo/lua/probe"
git -C "$repo" init -q -b main .
printf 'return { v = "v1" }\n' >"$repo/lua/probe/init.lua"
git -C "$repo" add -A
git -C "$repo" -c user.email=t@t -c user.name=t commit -qm v1

plugin="$XDG_DATA_HOME/nvim/site/pack/core/opt/probe/lua/probe/init.lua"
fail=0

check() { # check <description> <expected> <actual>
  if [ "$2" = "$3" ]; then
    printf '  ok   %s\n' "$1"
  else
    printf '  FAIL %s\n         expected: %s\n         actual:   %s\n' "$1" "$2" "$3"
    fail=1
  fi
}

# `-u NONE`: this drives `vim.pack` directly, without the configuration. Note that
# `print()` goes to stderr in headless Neovim, so the snippets write to stdout
# explicitly and progress messages are dropped (`2>/dev/null`).
lua_run() { nvim --headless -u NONE -c "lua $1" -c 'qa!' 2>/dev/null; }

add_spec="vim.pack.add({ { src = 'file://$repo', name = 'probe' } }, { load = false, confirm = false })"
print_rev="io.stdout:write('REV ' .. vim.pack.get({ 'probe' })[1].rev .. '\\n')"

lua_run "$add_spec" >/dev/null
check "install cloned v1" "v1" "$(grep -o v1 "$plugin" | head -1)"

rev1="$(lua_run "$add_spec; $print_rev" | grep -oE '[0-9a-f]{40}' | head -1)"
check "installed revision recorded" "40" "$(printf %s "$rev1" | wc -c | tr -d ' ')"

# A new commit upstream.
printf 'return { v = "v2" }\n' >"$repo/lua/probe/init.lua"
git -C "$repo" add -A
git -C "$repo" -c user.email=t@t -c user.name=t commit -qm v2

out="$(lua_run "$add_spec; vim.pack.update({ 'probe' }, { force = true }); $print_rev")"
check "update applied: checkout moved to v2" "v2" "$(grep -o v2 "$plugin" | head -1)"

rev2="$(printf '%s\n' "$out" | grep -oE '[0-9a-f]{40}' | head -1)"
if [ -n "$rev1" ] && [ -n "$rev2" ] && [ "$rev1" != "$rev2" ]; then
  printf '  ok   lockfile revision changed (%s -> %s)\n' "${rev1:0:8}" "${rev2:0:8}"
else
  printf '  FAIL revision unchanged (%s -> %s)\n' "$rev1" "$rev2"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  printf 'PASS: applying a plugin update works\n'
else
  printf 'FAIL\n'
fi
exit "$fail"
