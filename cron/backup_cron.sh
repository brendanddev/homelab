#!/bin/bash

# A wrapper to run the backup script and log output as a cron job
# Intended crontab schedule: (Everyday at 2 AM)
# 0 2 * * * /homelab/cron/backup_cron.sh

REPO_DIR="/home/Brendan/homelab"
SCRIPT="$REPO_DIR/scripts/backup.sh"
LOG_DIR="$REPO_DIR/logs"
LOG_FILE="$LOG_DIR/backup_$(date +'%Y-%m-%d').log"

# Ensure log dir exists
mkdir -p "$LOG_DIR"

# Run backup script and log output
echo "=== Backup started at $(date) ===" >> "$LOG_FILE"
bash "$SCRIPT" >> "$LOG_FILE" 2>&1
echo "=== Backup ended at $(date) ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"