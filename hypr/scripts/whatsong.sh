#!/bin/bash
# Current playing song

if command -v playerctl &> /dev/null; then
    status=$(playerctl status 2>/dev/null)
    if [ "$status" = "Playing" ]; then
        title=$(playerctl metadata title 2>/dev/null)
        artist=$(playerctl metadata artist 2>/dev/null)
        if [ -n "$artist" ]; then
            echo "$artist - $title"
        else
            echo "$title"
        fi
    else
        echo ""
    fi
else
    echo ""
fi
