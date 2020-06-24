#!/bin/sh

set -e

docker build -t abeltramo/backup .
echo "test" > /tmp/test.txt
docker run  --name backup-test --rm \
-v /tmp/test.txt:/test.txt \
-e SYNC_FOLDER=/test.txt \
-e BACKUP_AWS_S3_PATH="${BACKUP_AWS_S3_PATH}" \
-e BACKUP_AWS_KEY="${BACKUP_AWS_KEY}" \
-e BACKUP_AWS_SECRET="${BACKUP_AWS_SECRET}" \
abeltramo/backup backup