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

# Function to get CPU usage
get_cpu_usage() {
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    cpu_usage=${cpu_usage%.*}  # Remove decimal part
    
    if [[ $cpu_usage -gt $CPU_THRESHOLD ]]; then
        echo -e "${RED}CPU Usage: ${cpu_usage}%${NC}"
    else
        echo -e "${GREEN}CPU Usage: ${cpu_usage}%${NC}"
    fi
}

# Function to get disk usage
get_disk_usage() {
    echo -e "${CYAN}Disk Usage:${NC}"
    df -h | awk 'NR==1{print $0}' # Header
    df -h | awk 'NR>1 && $5+0 > 0 {
        usage = substr($5, 1, length($5)-1)
        if (usage > '$DISK_THRESHOLD') 
            printf "\033[0;31m%s\033[0m\n", $0
        else 
            printf "\033[0;32m%s\033[0m\n", $0
    }'
}