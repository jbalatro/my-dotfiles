#!/bin/sh
# Wallpaper by time of day: night (20:00-07:00) vs day.
# `wallpaper.sh toggle` flips it manually; the override lasts until the next automatic switch.
DIR=/home/sdf/dotfiles/.config/wallpaper
STATE=${XDG_RUNTIME_DIR:-/tmp}/wallpaper_override
PIDFILE=${XDG_RUNTIME_DIR:-/tmp}/wallpaper.pid
# the quickshell bar/runner watch this file to switch their light/dark palette
THEMEFILE=${XDG_RUNTIME_DIR:-/tmp}/happybar_theme

auto_mode() {
    h=$(date +%-H)
    if [ "$h" -ge 20 ] || [ "$h" -lt 7 ]; then echo dark; else echo light; fi
}

current_mode() {
    if [ -f "$STATE" ]; then cat "$STATE"; else auto_mode; fi
}

if [ "$1" = toggle ]; then
    if [ "$(current_mode)" = dark ]; then echo light > "$STATE"; else echo dark > "$STATE"; fi
    [ -f "$PIDFILE" ] && kill -USR1 "$(cat "$PIDFILE")" 2>/dev/null
    exit 0
fi

[ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null
echo $$ > "$PIDFILE"
trap : USR1

pkill -x swaybg
pgrep -x awww-daemon >/dev/null || { awww-daemon >/dev/null 2>&1 & sleep 1; }

shown=""
last_auto=$(auto_mode)
while true; do
    auto=$(auto_mode)
    if [ "$auto" != "$last_auto" ]; then
        rm -f "$STATE"
        last_auto=$auto
    fi
    mode=$(current_mode)
    if [ "$mode" != "$shown" ]; then
        echo "$mode" > "$THEMEFILE"
        # terminal: use the matching kitty palette and reload every running kitty
        mkdir -p "$HOME/.cache/happybar"
        cp "$HOME/dotfiles/.config/kitty/themes/$mode.conf" "$HOME/.cache/happybar/kitty-theme.conf"
        pkill -USR1 -x kitty
        # browser and GTK apps: follow the same light/dark choice
        if [ "$mode" = dark ]; then gsettings set org.gnome.desktop.interface color-scheme prefer-dark
        else gsettings set org.gnome.desktop.interface color-scheme prefer-light; fi
        awww img "$DIR/wallpaper_$mode.png" --resize crop \
            --transition-type fade --transition-duration 3 --transition-fps 60
        shown=$mode
    fi
    sleep 60 &
    wait $!
    kill $! 2>/dev/null
done
