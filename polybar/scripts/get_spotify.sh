#!/bin/bash

PARENT_BAR="now-playing"
PARENT_BAR_PID=$(pgrep -a "polybar" | grep "$PARENT_BAR" | cut -d" " -f1)

# Set the source audio player here.
# Players supporting the MPRIS spec are supported.
# Examples: spotify, vlc, chrome, mpv and others.
# Use `playerctld` to always detect the latest player.
# See more here: https://github.com/altdesktop/playerctl/#selecting-players-to-control
PLAYER="playerctld"

FORMAT="{{ title }} - {{ artist }}"

update_hooks() {
    while IFS= read -r id
    do
        polybar-msg -p "$id" hook spotify-play-pause "$2" 1>/dev/null 2>&1
    done < <(echo "$1")
}

# Switch to last playing player
switch_players() {
    while [ true ]
    do
        # status=$(playerctl --player=$PLAYER status)
        # echo "$status"
        # if [ "$status" = "Playing" -o "$status" = "No player could handle this command" ]; then
            # break
        # fi
        if playerctl --player=$PLAYER metadata 1>/dev/null 2>&1; then
            playerctld shift
        else
            break
        fi
    done
}

PLAYERCTL_STATUS=$(playerctl --player=$PLAYER status 2>/dev/null)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    STATUS=$PLAYERCTL_STATUS
else
    STATUS="No player is running"
fi

if [ "$1" == "--status" ]; then
    echo "$STATUS"
else
    if [ "$STATUS" = "Stopped" ]; then
        echo "Offline"
        # switch_players
    elif [ "$STATUS" = "Paused"  ]; then
        update_hooks "$PARENT_BAR_PID" 2
        playerctl --player=$PLAYER metadata --format "$FORMAT"
    elif [ "$STATUS" = "No player is running"  ]; then
        echo "Offline"
    else
        update_hooks "$PARENT_BAR_PID" 1
        playerctl --player=$PLAYER metadata --format "$FORMAT"
    fi
fi
