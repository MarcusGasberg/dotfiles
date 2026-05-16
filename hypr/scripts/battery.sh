#!/bin/bash
# Battery percentage with icon

get_battery() {
    for bat in /sys/class/power_supply/BAT*; do
        if [ -f "$bat/capacity" ]; then
            echo "$bat"
            return 0
        fi
    done
    return 1
}

bat=$(get_battery)

if [ -z "$bat" ]; then
    echo "󰁹 100%"
    exit 0
fi

capacity=$(cat "$bat/capacity" 2>/dev/null || echo 100)
status=$(cat "$bat/status" 2>/dev/null || echo "Unknown")

if [ "$status" = "Charging" ]; then
    icon="󰂄"
elif [ "$capacity" -ge 90 ]; then
    icon="󰁹"
elif [ "$capacity" -ge 80 ]; then
    icon="󰂂"
elif [ "$capacity" -ge 70 ]; then
    icon="󰂁"
elif [ "$capacity" -ge 60 ]; then
    icon="󰂀"
elif [ "$capacity" -ge 50 ]; then
    icon="󰁿"
elif [ "$capacity" -ge 40 ]; then
    icon="󰁾"
elif [ "$capacity" -ge 30 ]; then
    icon="󰁽"
elif [ "$capacity" -ge 20 ]; then
    icon="󰁼"
elif [ "$capacity" -ge 10 ]; then
    icon="󰁻"
else
    icon="󰁺"
fi

echo "$icon $capacity%"
