#!/bin/bash

# A security script to check for common vulnerabilities
# August 1, 2025
# Usage: ./security.sh


# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper function to print status messages
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK") echo -e "${GREEN}[OK]${NC} $message" ;;
        "WARNING") echo -e "${YELLOW}[WARNING]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "INFO") echo -e "${BLUE}[INFO]${NC} $message" ;;
        *) echo "$message" ;;
    esac
}

# Require root privileges to run
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR]${NC} Please run this script as root (with sudo)"
  exit 1
fi

echo "=========================================="
echo "    HOMELAB SECURITY MONITOR REPORT"
echo "    Generated: $(date)"
echo "=========================================="

# Check SSH port
echo ""
echo "=== SSH SECURITY CHECK ==="
SSH_PORT=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
if [ "$SSH_PORT" = "22" ]; then
    print_status "WARNING" "SSH is running on default port 22"
else
    print_status "OK" "SSH is running on port $SSH_PORT"
fi

# Check password authentication
PASS_AUTH=$(grep "^PasswordAuthentication" /etc/ssh/sshd_config | awk '{print $2}')
if [ "$PASS_AUTH" = "no" ]; then
    print_status "OK" "Password authentication is disabled"
else
    print_status "ERROR" "Password authentication is enabled - SECURITY RISK!"
fi

# Check root login
ROOT_LOGIN=$(grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}')
if [ "$ROOT_LOGIN" = "no" ]; then
    print_status "OK" "Root login is disabled"
else
    print_status "WARNING" "Root login may be enabled"
fi

# All recent SSH activity
echo ""
echo "=== RECENT SSH ACTIVITY ==="
print_status "INFO" "Recent successful SSH logins:"
last | grep -E "(ssh|pts)" | head -5

print_status "INFO" "Recent failed SSH attempts:"
if [ -f /var/log/auth.log ]; then
    FAILED_COUNT=$(grep "Failed password" /var/log/auth.log | grep "$(date '+%b %d')" | wc -l)
    if [ $FAILED_COUNT -gt 0 ]; then
        print_status "WARNING" "Found $FAILED_COUNT failed SSH attempts today"
        grep "Failed password" /var/log/auth.log | grep "$(date '+%b %d')" | tail -3
    else
        print_status "OK" "No failed SSH attempts today"
    fi
fi

# Firewall status
echo ""
echo "=== FIREWALL STATUS ==="
if command -v ufw >/dev/null 2>&1; then
    UFW_STATUS=$(ufw status | grep "Status:" | awk '{print $2}')
    if [ "$UFW_STATUS" = "active" ]; then
        print_status "OK" "UFW firewall is active"
        echo "Active rules:"
        ufw status numbered | grep -E "ALLOW|DENY"
    else
        print_status "ERROR" "UFW firewall is not active!"
    fi
else
    print_status "WARNING" "UFW firewall not installed"
fi

# Fail2ban status
echo ""
echo "=== FAIL2BAN STATUS ==="
if command -v fail2ban-client >/dev/null 2>&1; then
    if systemctl is-active --quiet fail2ban; then
        print_status "OK" "Fail2ban is running"
        BANNED_IPS=$(fail2ban-client status sshd | grep "Banned IP list" | awk -F: '{print $2}' | xargs)
        if [ -n "$BANNED_IPS" ]; then
            print_status "INFO" "Banned IPs: $BANNED_IPS"
        else
            print_status "INFO" "No IPs currently banned"
        fi
    else
        print_status "ERROR" "Fail2ban is installed but not running"
    fi
else
    print_status "WARNING" "Fail2ban not installed"
fi

# Log open ports
echo ""
echo "=== OPEN NETWORK PORTS ==="
ss -tuln | awk 'NR==1 || $1 ~ /LISTEN/' | while read -r line; do
    print_status "INFO" "$line"
done

# Check for package updates
echo ""
echo "=== PACKAGE UPDATES ==="
UPDATES=$(apt list --upgradable 2>/dev/null | grep -v "Listing")
if [ -n "$UPDATES" ]; then
    print_status "WARNING" "Packages available for update:"
    echo "$UPDATES"
else
    print_status "OK" "All packages are up to date"
fi