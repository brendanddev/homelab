#!/bin/bash

# Basic backup script
# Usage: ./backup.sh

BACKUP_SRC="/home/brendan"
BACKUP_DEST="/mnt/backup"
RETENTION_DAYS=7

# Create backup filename with date
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_NAME="backup_$DATE.tar.gz"

# Make sure backup destination exists
mkdir -p "$BACKUP_DEST"

# Create the backup archive
tar -czf "$BACKUP_DEST/$BACKUP_NAME" -C "$(dirname "$BACKUP_SRC")" "$(basename "$BACKUP_SRC")"

# Delete backups older than retention period
find "$BACKUP_DEST" -type f -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -exec rm {} \;

echo "Backup completed: $BACKUP_NAME"
