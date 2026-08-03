# direnv: auto-load .envrc per directory and export its env vars.
# Ref: https://direnv.net/docs/hook.html
# `direnv hook fish` installs the prompt-level reload hook; it is idempotent
# and safe to source on every shell start.

if type -q direnv
    direnv hook fish | source
end