# Introduction
This project provides Docker images to periodically back up a PostgreSQL database(s) to S3 like providers, and to restore from the backup as needed.

# Usage
## Backup
```yaml
services:
  postgres:
    image: postgres:17
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password

  backup:
    image: darokel/postgres-backup-s3:17
    environment:
      SCHEDULE: '@weekly'     # optional
      BACKUP_KEEP_DAYS: 7     # optional
      PASSPHRASE: passphrase  # optional
      S3_REGION: region
      S3_ACCESS_KEY_ID: key
      S3_SECRET_ACCESS_KEY: secret
      S3_BUCKET: my-bucket
      S3_PREFIX: backup
      POSTGRES_HOST: postgres
      # For single database
      POSTGRES_DATABASE: dbname
      # For multiple databases
      #POSTGRES_DATABASE: 'dbname1,dbname2,dbname3'
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
```

- Images are tagged by the major PostgreSQL version supported: `15`, `16` or `17`.
- The `SCHEDULE` variable determines backup frequency. See go-cron schedules documentation [here](http://godoc.org/github.com/robfig/cron#hdr-Predefined_schedules). Omit to run the backup immediately and then exit.
- If `PASSPHRASE` is provided, the backup will be encrypted using GPG.
- Run `docker exec <container name> sh backup.sh` to trigger a backup ad-hoc.
- If `BACKUP_KEEP_DAYS` is set, backups older than this many days will be deleted from S3.
- Set `S3_ENDPOINT` if you're using a non-AWS S3-compatible storage provider.
- Multiple databases can be backed up by providing a comma-separated list in `POSTGRES_DATABASE`
- Each database will be backed up to its own file with format: `{database_name}_{timestamp}.dump`
- When using `BACKUP_KEEP_DAYS`, old backups are cleaned up per database

## Restore
> [!CAUTION]
> DATA LOSS! All database objects will be dropped and re-created.

### ... from latest backup
```sh
# Restore all configured databases
docker exec <container name> sh restore.sh

# Restore a specific database
docker exec <container name> sh restore.sh "" database-name
```

> [!NOTE]
> - If your bucket has more than 1000 files, the latest may not be restored -- only one S3 `ls` command is used
> - When restoring all databases, each database will be restored from its latest backup
> - Databases must exist before attempting to restore
> - If a backup is not found for a database, it will be skipped

### ... from specific backup
```sh
# Restore all databases from a specific timestamp
docker exec <container name> sh restore.sh <timestamp>

# Restore specific database from a specific timestamp
docker exec <container name> sh restore.sh <timestamp> <database-name>
```

The timestamp parameter should match the timestamp portion of the backup filename (format: YYYY-MM-DDThh:mm:ss).

# Development

## Build the image locally

`POSTGRES_VERSION` determines Postgres version.

```sh
DOCKER_BUILDKIT=1 docker build --build-arg POSTGRES_VERSION=17 .
```
## Run a simple test environment with Docker Compose

```sh
cp template.env .env
# fill out your secrets/params in .env
docker compose up -d
```

# Acknowledgements

This project is a fork of [eeshugerman/postgres-backup-s3](https://github.com/eeshugerman/postgres-backup-s3), which itself restructured from the  @schickling's [postgres-backup-s3](https://github.com/schickling/dockerfiles/tree/master/postgres-backup-s3) and [postgres-restore-s3](https://github.com/schickling/dockerfiles/tree/master/postgres-restore-s3). So Kudos to those original authors for all the initial work in this project.

## Fork goals

This fork was largely made to enhance the project by supporting multiple database backups (as well as being able to make changes/updates unqique to my needs).
