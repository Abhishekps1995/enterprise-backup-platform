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


# Local Floci endpoint
AWS_ENDPOINT="${AWS_ENDPOINT:-http://localhost:4566}"


APPLICATION_NAME="application"

YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)

S3_PREFIX="$ENVIRONMENT/$APPLICATION_NAME/$YEAR/$MONTH/$DAY"


log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $1" | tee -a "$LOG_FILE"
}

aws_cli() {
    aws --endpoint-url="$AWS_ENDPOINT" "$@"
}

create_backup() {

    log_message "Creating backup archive..."

    tar -czf "$TEMP_DIR/$BACKUP_NAME" -C "$BACKUP_SOURCE" .

    if ! tar -czf "$TEMP_DIR/$BACKUP_NAME" -C "$BACKUP_SOURCE" .; then
        log_message "ERROR: Failed to create backup archive."
        exit 1
    fi

    if [ ! -f "$TEMP_DIR/$BACKUP_NAME" ]; then
        log_message "ERROR: Backup archive not found."
        exit 1
    fi

    BACKUP_SIZE=$(du -h "$TEMP_DIR/$BACKUP_NAME" | cut -f1)

    log_message "Backup archive created successfully."

    log_message "Backup Size: $BACKUP_SIZE"
}


main() {

    log_message "==============================="
    log_message "Backup Job Started"
    
    pre_flight_checks 
    create_backup
    upload_backup

    log_message "Backup Job Completed"
    log_message "==============================="
}


echo $AWS_ENDPOINT_URL

pre_flight_checks() {

    if ! command -v aws >/dev/null 2>&1; then
    log_message "ERROR: AWS CLI not installed."
    exit 1
    fi
	
    if [ ! -d "$BACKUP_SOURCE" ]; then
    log_message "ERROR: Source directory not found: $BACKUP_SOURCE"
    exit 1
    fi

    if ! mkdir -p "$TEMP_DIR"; then
    log_message "ERROR: Failed to create backup directory."
    exit 1
    fi

    if ! aws_cli s3api head-bucket --bucket "$BUCKET_NAME" > /dev/null 2>&1; then
        log_message "ERROR: Bucket $BUCKET_NAME does not exist."
        exit 1
    fi

    log_message "Pre-flight checks completed successfully."
}

upload_backup() {

    log_message "Uploading backup to S3..."

    if ! aws_cli s3 cp \
        "$TEMP_DIR/$BACKUP_NAME" \
        "s3://$BUCKET_NAME/$S3_PREFIX/$BACKUP_NAME"; then

   
        log_message "ERROR: Upload failed."
        exit 1
    fi

    log_message "Upload completed."


log_message "Verifying uploaded object..."

if ! aws_cli s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$S3_PREFIX/$BACKUP_NAME" > /dev/null 2>&1; then

    log_message "ERROR: Upload verification failed."
    exit 1

fi

log_message "Upload verification successful."

log_message "Deleting local backup..."

rm -f "$TEMP_DIR/$BACKUP_NAME"

log_message "Local backup removed."

}
main
