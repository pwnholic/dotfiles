# Fish 4.9+ | Vim-oriented daily setup
# Docs: https://fishshell.com/docs/current/interactive.html

# Preserve a working inherited/forwarded SSH agent.
if not set -q SSH_AUTH_SOCK; or not test -S "$SSH_AUTH_SOCK"
    set -l agent_socket /run/user/(id -u)/ssh-agent.socket
    if test -S "$agent_socket"
        set -gx SSH_AUTH_SOCK "$agent_socket"
    else
        set -e SSH_AUTH_SOCK
    end
end

set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx SUDO_EDITOR nvim
set -gx GOPATH $HOME/.local/share/go
set -gx CRG_EMBEDDING_MODEL Qwen/Qwen3-Embedding-0.6B
set -gx TYPESAFE_API_KEY apikey_20d05901a452874a62ac10adb83d5e1a6c_ac51dff896147d9022ba4d50a2ebc4cc2bac8920559de8be6930b1062ac79e04
set -gx SYSTEM_ONE_BASE_URL https://api.typesafe.ai
set -gx SYSTEM_ONE_API_KEY $TYPESAFE_API_KEY
set -gx SYSTEM_ONE_MODEL jev-latest


if test -f "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
end
# Session-scoped, deduplicated additions; retain toolchain precedence.
fish_add_path --global $GOPATH/bin
fish_add_path --global $HOME/.local/bin
fish_add_path --global $HOME/.cargo/bin
fish_add_path --global $HOME/.config/.foundry/bin
fish_add_path --global $HOME/.local/share/solana/install/active_release/bin
fish_add_path --global $HOME/.avm/bin
fish_add_path --global $HOME/.pdtm/go/bin

if status is-interactive
    set -g fish_greeting
    fish_vi_key_bindings
    set -g fish_cursor_default block
    set -g fish_cursor_insert line
    set -g fish_cursor_replace_one underscore
    set -g fish_cursor_replace underscore
    set -g fish_cursor_visual block
    set -g fish_cursor_external block

    # Catppuccin Mocha: distinguish commands, errors and suggestions.
    set -g fish_color_normal cdd6f4
    set -g fish_color_command 89b4fa
    set -g fish_color_keyword cba6f7
    set -g fish_color_quote a6e3a1
    set -g fish_color_redirection f5c2e7
    set -g fish_color_end fab387
    set -g fish_color_error f38ba8
    set -g fish_color_param cdd6f4
    set -g fish_color_comment 9399b2
    set -g fish_color_selection --bold --background=45475a
    set -g fish_color_search_match --background=45475a
    set -g fish_color_operator 94e2d5
    set -g fish_color_escape f5c2e7
    set -g fish_color_autosuggestion 9399b2
    set -g fish_color_cancel f38ba8
    set -g fish_color_valid_path --underline
    set -g fish_pager_color_progress cba6f7
    set -g fish_pager_color_prefix 89b4fa --bold
    set -g fish_pager_color_completion cdd6f4
    set -g fish_pager_color_description a6adc8
    set -g fish_pager_color_selected_background --background=45475a

    if type -q direnv
        direnv hook fish | source
    end
    if type -q atuin
        # Retain Atuin recording; Ctrl+R consistently uses fzf.
        set -gx ATUIN_NOBIND true
        atuin init fish | source
    end
    if type -q zoxide
        # z <name> jumps to a frequent directory; zi selects interactively.
        zoxide init fish | source
    end

    if type -q fzf
        set -gx FZF_DEFAULT_OPTS '--height=60% --layout=reverse --border=rounded --info=inline --cycle --bind=ctrl-j:down,ctrl-k:up --color=bg+:#313244,fg:#cdd6f4,fg+:#cdd6f4,hl:#f38ba8,hl+:#f38ba8,prompt:#cba6f7,pointer:#f5e0dc,marker:#a6e3a1,spinner:#f5e0dc,header:#89b4fa'
        if type -q rg
            if test -f "$__fish_config_dir/../rg/ripgrep.conf"
                set -gx RIPGREP_CONFIG_PATH "$__fish_config_dir/../rg/ripgrep.conf"
            end
            # Keep Git ignore rules; ignore unrelated global rg display flags.
            set -gx FZF_DEFAULT_COMMAND 'rg --files --hidden --glob "!.git" --no-config'
            set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
        end
        if type -q bat
            set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --style=numbers --line-range=:300 {}' --preview-window=right:55%:wrap --bind=ctrl-/:toggle-preview"
        end
        fzf --fish | source
    end

    abbr --add vim nvim
    abbr --add vi nvim
    abbr --add v nvim
    abbr --add nv nvim
    abbr --add vimdiff nvim -d

    function multicd --description 'Expand ... into cd ../..'
        echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
    end
    abbr --add dotdot --regex '^\.\.+$' --function multicd

    # Starship has built-in insert/normal/visual mode indicators.
    if type -q starship
        starship init fish | source
    end
    fish_user_key_bindings
end
