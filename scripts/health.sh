#!/bin/bash

# Displays system health information
# Thresholds can be overridden in ~/health.conf
# Usage: ./health.sh [--log <file>]

CONFIG_FILE="${HOME}/health.conf"
DISK_THRESHOLD=85
MEMORY_THRESHOLD=80
CPU_THRESHOLD=75

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

LOGFILE=""

# Parse arguments for --log <file>
if [[ "$1" == "--log" && -n "$2" ]]; then
    LOGFILE="$2"
    # Create/clear log file
    > "$LOGFILE"
fi

# Load config file if it exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Helper print function
print() {
    if [[ -n "$LOGFILE" ]]; then
        echo -e "$@" >> "$LOGFILE"
    else
        echo -e "$@"
    fi
}

# Check uptime
get_uptime() {
    uptime_info=$(uptime -p 2>/dev/null || uptime)
    echo "$uptime_info"
}

# Function to get memory usage
get_memory_usage() {
    local mem_info mem_percent
    mem_info=$(free -h | awk '/^Mem:/ {printf "Used: %s/%s (%.1f%%)", $3, $2, ($3/$2)*100}')
    mem_percent=$(free | awk '/^Mem:/ {printf "%.0f", ($3/$2)*100}')
    
    if [[ $mem_percent -gt $MEMORY_THRESHOLD ]]; then
        print "${RED}$mem_info${NC}"
    else
        print "${GREEN}$mem_info${NC}"
    fi
}

# Function to get CPU usage
get_cpu_usage() {
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d'.' -f1)  # Total CPU usage
    if [[ $cpu_usage -gt $CPU_THRESHOLD ]]; then
        print "${RED}CPU Usage: ${cpu_usage}%${NC}"
    else
        print "${GREEN}CPU Usage: ${cpu_usage}%${NC}"
    fi
}

# Function to get disk usage
get_disk_usage() {
    print "${CYAN}Disk Usage:${NC}"
    df -h | awk 'NR==1{print $0}' | while IFS= read -r line; do print "$line"; done
    df -h | awk 'NR>1 && $5+0 > 0 {
        usage = substr($5, 1, length($5)-1)
        if (usage > '"$DISK_THRESHOLD"') 
            printf "\033[0;31m%s\033[0m\n", $0
        else 
            printf "\033[0;32m%s\033[0m\n", $0
    }' | while IFS= read -r line; do print "$line"; done
}

# Function to get temperature (if available)
get_temperature() {
    if command -v sensors >/dev/null 2>&1; then
        print "${CYAN}System Temperature:${NC}"
        sensors 2>/dev/null | grep -E "(Core|temp)" | head -5 | while IFS= read -r line; do print "$line"; done
    elif [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        local temp
        temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        temp=$((temp / 1000))
        print "${CYAN}CPU Temperature:${NC} ${temp}°C"
    fi
}

# Function to get recent system errors
get_system_errors() {
    print "${CYAN}Recent System Errors (Last 10):${NC}"
    if journalctl -p err -n 10 --no-pager 2>/dev/null; then
        journalctl -p err -n 10 --no-pager 2>/dev/null | while IFS= read -r line; do print "$line"; done
    else
        tail -10 /var/log/syslog | grep -i error | while IFS= read -r line; do print "$line"; done || print "No recent errors found"
    fi
}

# Function to get system load
get_system_load() {
    local load_avg cpu_cores
    load_avg=$(uptime | awk -F'load average:' '{print $2}')
    cpu_cores=$(nproc)
    print "${CYAN}Load Average:${NC}$load_avg"
    print "${CYAN}CPU Cores:${NC} $cpu_cores"
}

# Function to get network information
get_network_info() {
    print "${CYAN}Network Interfaces:${NC}"
    ip -4 addr show | grep -E '^[0-9]+:|inet ' | sed 's/^[0-9]*: //' | paste - - | column -t | while IFS= read -r line; do print "$line"; done
    
    print "\n${CYAN}Active Network Connections (Top 10):${NC}"
    if command -v ss >/dev/null 2>&1; then
        ss -tuln | head -15 | while IFS= read -r line; do print "$line"; done
    else
        netstat -tuln 2>/dev/null | head -15 | while IFS= read -r line; do print "$line"; done
    fi
}

# Main func to display all health info
main() {
    print "=== System Health Report ==="
    print "Uptime: $(get_uptime)"
    print ""
    get_memory_usage
    get_cpu_usage
    get_disk_usage
    get_temperature
    get_system_errors
    get_system_load
    get_network_info
}

main
