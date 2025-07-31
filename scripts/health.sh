#!/bin/bash

# Displays system health information

CONFIG_FILE="${HOME}/health.conf"
DISK_THRESHOLD=85
MEMORY_THRESHOLD=80
CPU_THRESHOLD=75

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

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
    cpu_usage=${cpu_usage%.*}
    
    if [[ $cpu_usage -gt $CPU_THRESHOLD ]]; then
        echo -e "${RED}CPU Usage: ${cpu_usage}%${NC}"
    else
        echo -e "${GREEN}CPU Usage: ${cpu_usage}%${NC}"
    fi
}

# Function to get disk usage
get_disk_usage() {
    echo -e "${CYAN}Disk Usage:${NC}"
    df -h | awk 'NR==1{print $0}'
    df -h | awk 'NR>1 && $5+0 > 0 {
        usage = substr($5, 1, length($5)-1)
        if (usage > '$DISK_THRESHOLD') 
            printf "\033[0;31m%s\033[0m\n", $0
        else 
            printf "\033[0;32m%s\033[0m\n", $0
    }'
}

# Function to get temperature (if available)
get_temperature() {
    if command -v sensors >/dev/null 2>&1; then
        echo -e "${CYAN}System Temperature:${NC}"
        sensors 2>/dev/null | grep -E "(Core|temp)" | head -5
    elif [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        local temp
        temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        temp=$((temp / 1000))
        echo -e "${CYAN}CPU Temperature:${NC} ${temp}°C"
    fi
}

# Function to get recent system errors
get_system_errors() {
    echo -e "${CYAN}Recent System Errors (Last 10):${NC}"
    journalctl -p err -n 10 --no-pager 2>/dev/null || tail -10 /var/log/syslog | grep -i error || echo "No recent errors found"
}

# Function to get system load
get_system_load() {
    local load_avg
    load_avg=$(uptime | awk -F'load average:' '{print $2}')
    echo -e "${CYAN}Load Average:${NC}$load_avg"
    
    local cpu_cores
    cpu_cores=$(nproc)
    echo -e "${CYAN}CPU Cores:${NC} $cpu_cores"
}

# Function to get network information
get_network_info() {
    echo -e "${CYAN}Network Interfaces:${NC}"
    ip -4 addr show | grep -E '^[0-9]+:|inet ' | sed 's/^[0-9]*: //' | paste - - | column -t
    
    echo -e "\n${CYAN}Active Network Connections (Top 10):${NC}"
    netstat -tuln 2>/dev/null | head -15 || ss -tuln | head -15
}