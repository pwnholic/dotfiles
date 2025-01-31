# source /usr/share/cachyos-fish-config/cachyos-config.fish

abbr -a nv nvim
abbr -a nvo --set-cursor "cd % && nvim"
abbr -a nvp nvim +Man!

# Git abbreviations.
abbr -a g git
abbr -a ga git add
abbr -a gb git branch
abbr -a gc git commit --verbose
abbr -a gco git checkout
abbr -a gf git fetch
abbr -a gl lazygit
abbr -a gm git merge
abbr -a gp git push
abbr -a gst git status

# Linux maintenance.
abbr -a --position anywhere s sudo
abbr -a j journalctl

# Remove the gretting message.
set -U fish_greeting

# Vi mode.
set -g fish_key_bindings fish_vi_key_bindings
set fish_vi_force_cursor 1
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore


alias gitcred="sh ~/.config/fish/scripts/gitcred"
alias mpvyt='mpv --input-ipc-server=~/.socket_yt --vo=null --ytdl-raw-options="yes-playlist=,format=best*[vcodec=none]"'
alias aria2cflag='aria2c --file-allocation=none -c -j 10 -x 16 -s 16 -k 1M'

starship init fish | source
