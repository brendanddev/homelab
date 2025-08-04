#!/bin/bash

# A simple script to output network information
# Usage: ./netinfo.sh


echo "=== NETWORK INFORMATION ==="
echo "External IP: $(curl -s ifconfig.me || echo 'Unable to fetch')"
echo "Internal IP: $(hostname -I | awk '{print $1}')"
echo "Gateway: $(ip route | grep default | awk '{print $3}')"
echo "DNS Servers: $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | tr '\n' ' ')"
echo ""
echo "=== ACTIVE CONNECTIONS ==="
ss -tuln | grep LISTEN | head -10