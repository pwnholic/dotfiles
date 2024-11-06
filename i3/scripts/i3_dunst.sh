DIR="$HOME/.config/i3"

# Launch dunst daemon
if [[ $(pidof dunst) ]]; then
    pkill dunst
fi

dunst -config "$DIR"/dunstrc &
