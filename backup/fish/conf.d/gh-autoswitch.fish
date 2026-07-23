# Auto-switch the active `gh` account based on the current directory.
# Personal (pwnholic) is the default everywhere except ~/Projects/work,
# which uses the work account (tpid-tono). Mirrors the git includeIf split.
#
# _gh_last_target caches the active target so `gh auth switch` only runs on a
# real boundary crossing, not on every `cd`. After authenticating a NEW account,
# run `set -e _gh_last_target` (or open a new shell) so detection retriggers.
function _gh_autoswitch --on-variable PWD
    command -q gh; or return

    set -l target pwnholic
    if string match -q -- "$HOME/Projects/work" $PWD; or string match -q -- "$HOME/Projects/work/*" $PWD
        set target tpid-tono
    end

    test "$_gh_last_target" = "$target"; and return

    set -g _gh_last_target $target
    gh auth switch --user $target >/dev/null 2>&1
end
