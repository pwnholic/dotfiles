# fzf integration.
# Modern fzf (>= 0.48) ships its own fish setup via `fzf --fish`, which registers
# the CTRL-T / CTRL-R / ALT-C bindings. This is the officially recommended
# method and replaces the older `source key-bindings.fish` approach.
# Ref: https://junegunn.github.io/fzf/shell-integration/

if type -q fzf
    # --- Finders -----------------------------------------------------------
    # ripgrep lists files for the default finder and CTRL-T (respects
    # .gitignore, includes hidden files, skips .git).
    set -gx FZF_DEFAULT_COMMAND 'rg --files --hidden --glob "!.git/*"'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    # fd lists directories for the ALT-C (cd) finder.
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'

    # --- Preview / UI ------------------------------------------------------
    set -gx FZF_DEFAULT_OPTS '--height=40% --layout=reverse --border --info=inline-right --prompt="> " --pointer=">" --marker="v" --walker-skip=.git,node_modules,target'

    set -gx FZF_CTRL_T_OPTS '--preview="bat -n --color=always {}" --bind="ctrl-/:change-preview-window(down|hidden|)"'
    set -gx FZF_CTRL_R_OPTS '--header="CTRL-R history" --color header:italic'
    set -gx FZF_ALT_C_OPTS '--preview="eza --tree --color=always --level=2 {}"'

    # --- Bindings (interactive only) --------------------------------------
    if status is-interactive
        fzf --fish | source
    end
end
