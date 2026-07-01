#!/bin/bash

# ==============================
# Enterprise Backup Script
# ==============================

BACKUP_SOURCE="/home/ubuntu/enterprise-backup-platform/test-data/application"
BUCKET_NAME="company-backups"
ENVIRONMENT="development"

DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

BACKUP_NAME="app_backup_${TIMESTAMP}.tar.gz"

TEMP_DIR="/home/ubuntu/enterprise-backup-platform/backups"

LOG_FILE="/home/ubuntu/enterprise-backup-platform/logs/backup.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $1" | tee -a "$LOG_FILE"
}

if [ ! -d "$BACKUP_SOURCE" ]; then
    log_message "ERROR: Source directory not found: $BACKUP_SOURCE"
    exit 1
fi

mkdir -p "$TEMP_DIR"

aws s3api head-bucket --bucket "$BUCKET_NAME" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    log_message "ERROR: Bucket $BUCKET_NAME does not exist."
    exit 1
fi

log_message "Pre-flight checks completed successfully."


