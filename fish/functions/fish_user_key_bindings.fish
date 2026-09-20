function fish_user_key_bindings --description 'Keep fuzzy search and editor access in Vi modes'
    # Reapply when Fish rebuilds bindings.
    if functions -q fzf_key_bindings
        fzf_key_bindings
    end
    # In normal mode Ctrl+R should remain Vim's redo, not history search.
    bind -M default ctrl-r redo
    for mode in insert default visual
        # Edit the command in $VISUAL, then return it to the prompt.
        bind -M $mode ctrl-g edit_command_buffer
    end
end
