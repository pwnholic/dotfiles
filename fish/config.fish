set -g fish_greeting

set -gx SSH_AUTH_SOCK /run/user/(id -u)/ssh-agent.socket
if not test -S "$SSH_AUTH_SOCK"
    set -e SSH_AUTH_SOCK
end

set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx SUDO_EDITOR nvim

set -gx GOPATH $HOME/.local/share/go
fish_add_path $GOPATH/bin

set -gx CRG_EMBEDDING_MODEL Qwen/Qwen3-Embedding-0.6B

if test -f "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
end
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.config/.foundry/bin
fish_add_path $HOME/.local/share/solana/install/active_release/bin
fish_add_path $HOME/.avm/bin
fish_add_path $HOME/.pdtm/go/bin

if status is-interactive
    if type -q direnv
        direnv hook fish | source
    end

    if type -q atuin
        set -gx ATUIN_NOBIND true
        atuin init fish | source
    end

    if type -q starship
        starship init fish | source
    end

    if type -q fzf
        fzf --fish | source
        if type -q rg
            set -gx RIPGREP_CONFIG_PATH $HOME/.config/rg/ripgrep.conf
            set -gx FZF_DEFAULT_COMMAND 'rg --files --hidden --follow --glob "!.git/*"'
            set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
        end
        if type -q bat
            set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
        end
    end

    if type -q eza
        abbr --add ls eza --icons
        abbr --add ll eza --icons --long --header
        abbr --add la eza --icons --long --header --all
        abbr --add lt eza --icons --tree
    end

    if type -q bat
        abbr --add cat bat
        set -gx BAT_THEME ansi
    end

    abbr --add vim nvim
    abbr --add vi nvim
    abbr --add v nvim
    abbr --add nv nvim
    abbr --add vimdiff nvim -d

    function multicd
        echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
    end
    abbr --add dotdot --regex '^\.\.+$' --function multicd

end


# Generated for pdtm. Do not edit.
fish_add_path /home/pwnholic/.pdtm/go/bin


# Added by codebase-memory-mcp install
fish_add_path /home/pwnholic/.local/bin
