#!/bin/bash
# Network status - shows connected network name or IP

if command -v nmcli &> /dev/null; then
    conn=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -1)
    if [ -n "$conn" ]; then
        echo "$conn"
    else
        echo "No WiFi"
    fi
else
    ip addr show | grep "inet " | head -1 | awk '{print $2}' | cut -d'/' -f1
fi
