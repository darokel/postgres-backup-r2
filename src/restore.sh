#! /bin/sh

set -u # `-e` omitted intentionally, but i can't remember why exactly :'(
set -o pipefail

source ./env.sh

s3_uri_base="s3://${S3_BUCKET}/${S3_PREFIX}"

if [ -z "$PASSPHRASE" ]; then
  file_type=".dump"
else
  file_type=".dump.gpg"
fi

restore_database() {
    local current_db=$1
    local timestamp=$2

    echo "Processing restore for database ${current_db}..."

    if [ -n "$timestamp" ]; then
        key_suffix="${current_db}_${timestamp}${file_type}"
    else
        echo "Finding latest backup for ${current_db}..."
        key_suffix=$(
            aws $aws_args s3 ls "${s3_uri_base}/${current_db}" \
            | sort \
            | tail -n 1 \
            | awk '{ print $4 }'
        )
    fi

    if [ -z "$key_suffix" ]; then
        echo "No backup found for database ${current_db}, skipping..."
        return 1
    fi

    echo "Fetching backup from S3..."
    aws $aws_args s3 cp "${s3_uri_base}/${key_suffix}" "db${file_type}"

    if [ -n "$PASSPHRASE" ]; then
        echo "Decrypting backup..."
        gpg --decrypt --batch --passphrase "$PASSPHRASE" db.dump.gpg > db.dump
        rm db.dump.gpg
    fi

    conn_opts="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d ${current_db}"

    echo "Restoring ${current_db} from backup..."
    pg_restore $conn_opts --clean --if-exists db.dump
    rm db.dump

    echo "Restore complete for ${current_db}."
}

# Check arguments
timestamp=""
specific_db=""

case $# in
    0)  # No args - restore all databases from latest backup
        ;;
    1)  # One arg - timestamp only, restore all databases
        timestamp="$1"
        ;;
    2)  # Two args - timestamp and specific database
        timestamp="$1"
        specific_db="$2"
        ;;
    *)  echo "Usage: restore.sh [timestamp] [database-name]"
        exit 1
        ;;
esac

if [ -n "$specific_db" ]; then
    # Restore specific database
    restore_database "$specific_db" "$timestamp"
else
    # Restore all databases
    for CURRENT_DB in $(echo $POSTGRES_DATABASE | tr ',' '\n' | sed 's/^ *//g' | sed 's/ *$//g')
    do
        restore_database "$CURRENT_DB" "$timestamp"
    done
    echo "All database restores completed."
fi
