if not status is-interactive
    return
end

set -gx FZF_DEFAULT_OPTS "
    --reverse \
    --preview='bat --color=always --style=numbers --line-range=:500 {}' \
    --preview-window=right,55%,border-sharp,nocycle \
    --border \
    --info=inline-right \
    --no-scrollbar \
    --margin=1,0,0 \
    --height=~45% \
    --min-height=16 \
    --scroll-off=999 \
    --multi \
    --ansi \
    --bind=ctrl-k:kill-line \
    --bind=alt-a:toggle-all \
    --bind=shift-up:preview-up,shift-down:preview-down \
    --bind=alt-v:preview-half-page-up,ctrl-v:preview-half-page-down \
    --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up' \
    --color='bg+:#1F2335,bg:#1A1B26,spinner:#7AA2F7,hl:#7AA2F7,fg:#C0CAF5,header:#7AA2F7,info:#7AA2F7,pointer:#7AA2F7,marker:#7AA2F7,fg+:#C0CAF5,prompt:#7AA2F7,hl+:#7AA2F7'
"

if test (tput colors 2>/dev/null) -lt 256
    set -gxa FZF_DEFAULT_OPTS --no-unicode '--marker=+\ ' '--pointer=>\ '
end

set -gx ARIA2C_DEFAULT_FLAG "--file-allocation=none -c -j 10 -x 16 -s 16 -k 1M"
