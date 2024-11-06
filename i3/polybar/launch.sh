#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

for mon in $(polybar --list-monitors | cut -d":" -f1); do
    MONITOR=$mon polybar -q main -c "$DIR"/config.ini &
done
