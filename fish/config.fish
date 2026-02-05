abbr -a nv nvim
abbr -a nvp nvim +Man!

set -U fish_greeting

set -g fish_key_bindings fish_vi_key_bindings

set fish_vi_force_cursor 1
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore

set -g direnv_fish_mode eval_on_arrow

starship init fish | source
direnv hook fish | source
