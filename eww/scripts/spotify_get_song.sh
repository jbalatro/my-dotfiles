#!/bin/sh
SPOTIFY_ID=$(playerctl --player=spotify metadata mpris:trackid)
SPOTIFY_URL=$(playerctl --player=spotify metadata mpris:artUrl)
SPOTIFY_TITLE=$(playerctl --player=spotify metadata xesam:title)
SPOTIFY_ARTIST=$(playerctl --player=spotify metadata xesam:artist)
SPOTIFY_PREFIX="/com/spotify/track/"
SPOTIFY_IMG_PATH="$HOME/.config/eww/assets/player-imgs"



for img in `ls $SPOTIFY_IMG_PATH`; do
    if [[ ${img%".jpg"} == ${SPOTIFY_ID#"$SPOTIFY_PREFIX"} ]]; then
        jq -n \
            --arg sid "${SPOTIFY_ID#"$SPOTIFY_PREFIX"}" \
            --arg stit "$SPOTIFY_TITLE" \
            --arg sart "$SPOTIFY_ARTIST" \
            '{id: $sid, title: $stit, artist: $sart}'
        exit
    fi

    rm "$SPOTIFY_IMG_PATH/$img"
done

wget -nv -O "$SPOTIFY_IMG_PATH/${SPOTIFY_ID#"$SPOTIFY_PREFIX"}.jpg" $SPOTIFY_URL > /dev/null 2>&1


jq -n \
    --arg sid "${SPOTIFY_ID#"$SPOTIFY_PREFIX"}" \
    --arg stit "$SPOTIFY_TITLE" \
    --arg sart "$SPOTIFY_ARTIST" \
    '{id: $sid, title: $stit, artist: $sart}'