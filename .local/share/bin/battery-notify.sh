#!/bin/bash

# Battery notification script
# Requires: upower, libnotify

BATTERY=$(upower -e | grep BAT | head -n 1)

PERCENT=$(upower -i "$BATTERY" | awk '/percentage:/ {print $2}' | tr -d '%')

if [ "$PERCENT" -le 20 ]; then
    notify-send -u critical "Battery Low"
elif [ "$PERCENT" -ge 80 ]; then
    notify-send -u normal "Battery Charged"
fi
