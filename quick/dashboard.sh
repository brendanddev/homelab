#!/bin/bash

# A simple script to output a brief monitoring dashboard for the server
# Usage: ./dashboard.sh

while true; do
    clear
    echo "==================== HOME SERVER DASHBOARD ===================="
    echo "Time: $(date)"
    echo "Uptime: $(uptime -p)"
    echo "Load: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
    echo "Memory: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
    echo "Disk: $(df / | tail -1 | awk '{print $5}')"
    echo "Network: $(cat /proc/net/dev | grep eth0 | awk '{print "RX:", $2/1024/1024"MB TX:", $10/1024/1024"MB"}' || echo 'N/A')"
    echo "=============================================================="
    echo "Press Ctrl+C to exit"
    sleep 5
done