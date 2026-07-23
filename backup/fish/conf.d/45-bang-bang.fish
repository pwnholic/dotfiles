# Bash-style `!!` (rerun last command) and `!$` (insert last argument),
# bound to the `!` and `$` keys. Optional migration aid; delete this file to
# remove the behaviour entirely.

if status is-interactive
    function __fish_bang_bang_last_command
        switch (commandline -t)
            case '!'
                commandline -t $history[1]
                commandline -f repaint
            case '*'
                commandline -i '!'
        end
    end

    function __fish_bang_bang_last_argument
        switch (commandline -t)
            case '!'
                commandline -t ''
                commandline -f history-token-search-backward
            case '*'
                commandline -i '$'
        end
    end

    # Bind in emacs mode (default) and, if vi mode is enabled, in vi insert mode.
    bind '!' __fish_bang_bang_last_command
    bind '$' __fish_bang_bang_last_argument
    if test "$fish_key_bindings" = fish_vi_key_bindings
        bind -Minsert '!' __fish_bang_bang_last_command
        bind -Minsert '$' __fish_bang_bang_last_argument
    end
end
