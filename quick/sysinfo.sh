#!/bin/bash

# A simple script to output system information
# Usage: ./sysinfo.sh


echo "=== SYSTEM INFORMATION ==="
echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
echo "RAM: $(free -h | grep '^Mem:' | awk '{print $2}')"
echo "Storage: $(lsblk -d -o NAME,SIZE | grep -v NAME | awk '{total+=$2} END {print total"GB"}')"