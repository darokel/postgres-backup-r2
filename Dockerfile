ARG POSTGRES_VERSION=17
FROM postgres:${POSTGRES_VERSION}-alpine
ARG TARGETARCH

ADD src/install.sh install.sh
RUN sh install.sh && rm install.sh

ENV POSTGRES_DATABASE='' \
    POSTGRES_HOST='' \
    POSTGRES_PORT=5432 \
    POSTGRES_USER='' \
    POSTGRES_PASSWORD='' \
    PGDUMP_EXTRA_OPTS='' \
    S3_ACCESS_KEY_ID='' \
    S3_SECRET_ACCESS_KEY='' \
    S3_BUCKET='' \
    S3_REGION=auto \
    S3_PATH=backup \
    S3_ENDPOINT='' \
    S3_S3V4=no \
    SCHEDULE='' \
    PASSPHRASE='' \
    BACKUP_KEEP_DAYS=''

ADD src/run.sh run.sh
ADD src/env.sh env.sh
ADD src/backup.sh backup.sh
ADD src/restore.sh restore.sh

CMD ["sh", "run.sh"]
