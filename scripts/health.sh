#!/bin/bash

# Displays system health information

CONFIG_FILE="${HOME}/health.conf"
DISK_THRESHOLD=85
MEMORY_THRESHOLD=80
CPU_THRESHOLD=75

# Load config file if it exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Check uptime
get_uptime() {
    uptime_info=$(uptime -p 2>/dev/null || uptime)
    echo "$uptime_info"
}

# Function to get memory usage
get_memory_usage() {
    local mem_info
    mem_info=$(free -h | awk '/^Mem:/ {printf "Used: %s/%s (%.1f%%)", $3, $2, ($3/$2)*100}')
    local mem_percent
    mem_percent=$(free | awk '/^Mem:/ {printf "%.0f", ($3/$2)*100}')
    
    if [[ $mem_percent -gt $MEMORY_THRESHOLD ]]; then
        echo -e "${RED}$mem_info${NC}"
    else
        echo -e "${GREEN}$mem_info${NC}"
    fi
}