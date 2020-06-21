![Docker hub - abeltramo/backup](https://img.shields.io/badge/docker-abeltramo%2Fbackup-success)![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/abeltramo/backup)![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/abeltramo/backup)

# Table of Contents

- [Supported tags](#supported-tags)
- [Introduction](#introduction)
    - [Version](#version)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)

## Supported tags

- `abeltramo/backup:latest`

## Introduction

Dockerfile to build an image which allows to create backup archives on daily
basic. This image is based on [Alpine Linux](http://www.alpinelinux.org) and
[s3cmd](http://s3tools.org/s3cmd) tool. You can use this image to create
backup archives and store them on local folder or upload to S3.
Include also `mysqldump` in order to create a mysql dump, gzip it and backup it up to S3.

## Installation

Pull the image from the [docker registry](https://hub.docker.com/r/abeltramo/backup).
This is the recommended method of installation as it is easier to update image.
These builds are performed by the **Docker Trusted Build** service.

```bash
docker pull abeltramo/backup:latest
```

Alternately you can build the image locally.

```bash
git clone https://github.com/abeltramo/docker-backup.git
cd docker-backup
docker build --tag="$USER/backup" .
```

## Quick start

At first if you want to upload backups to AWS S3 you need to create new
bucket on S3 and create an user in IAM with next policy (don't forget to
update bucket locations)

```xml
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1412062044000",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::your-backup-us-west-2/*"
            ]
        },
        {
            "Sid": "Stmt1412062097000",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListAllMyBuckets"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Stmt1412062128000",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-backup-us-west-2"
            ]
        }
    ]
}
```

> NOTE: I'm not a AWS expert, so if you think that it is possible to give less
> permissions - please let me know.

```bash
docker run -d \
    -e "SYNC_FOLDER=/etc/" \
    -e "BACKUP_AWS_KEY=AWS_KEY" \
    -e "BACKUP_AWS_SECRET=AWS_SECRET" \
    -e "BACKUP_AWS_S3_PATH=s3://your-backup-us-west-2" \
    abeltramo/backup:latest
```

## Configuration

### Common

- `BACKUP_AWS_KEY` - AWS Key.
- `BACKUP_AWS_SECRET` - AWS Secret.
- `BACKUP_AWS_S3_PATH` - path to S3 bucket, like `s3://your-backup-us-west-2`.
    Default value is empty, which means that archives will not be uploaded.
- `BACKUP_TIMEZONE` - change timezone from UTC to
    [tz database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones),
    for example `America/Los_Angeles`. Defaults to empty.
- `BACKUP_CRON_SCHEDULE` - specify when and how often you want to run backup
    script. Defaults to `0 2 * * *` (every day at 2am).

### MYSQL

- `BACKUP_DEST_FOLDER` - if you want to keep backups locally you can change
    destination folder which is used to create backup archives. Default
    value is `/var/tmp`
- `BACKUP_DELETE_LOCAL_COPY` - if you want to keep backups in
    `BACKUP_DEST_FOLDER` set it to `true`. Default value is `true`.
- `MYSQL_HOST`
- `MYSQL_USER`
- `MYSQL_PASSWORD`

### Local folder

Setting `SYNC_FOLDER` will sync the local folder to the remote S3 bucket, it will also delete things that will no longer exists locally.

## Examples

### Backing up MariaDB tables using mysqldump

```yaml

database:
    image: mariadb
    environment:
      - MYSQL_ROOT_PASSWORD=password
      - MYSQL_DATABASE=testDB

backup:
  image: abeltramo/backup:latest
  environment:
    - BACKUP_AWS_KEY=AWS_KEY
    - BACKUP_AWS_SECRET=AWS_SECRET
    - BACKUP_AWS_S3_PATH=s3://my-backup-bucket
    - MYSQL_HOST=database
    - MYSQL_USER=root
    - MYSQL_PASSWORD=password
  restart: always
```

### Backing up Jenkins data folder

```yaml
vdata:
  image: busybox
  volumes:
    - /var/jenkins_home
  command: chown -R 1000:1000 /var/jenkins_home

jenkins:
  build: jenkins:latest
  volumes_from:
    - vdata
  restart: always

backup:
  image: abeltramo/backup:latest
  environment:
    - BACKUP_AWS_KEY=AWS_KEY
    - BACKUP_AWS_SECRET=AWS_SECRET
    - BACKUP_AWS_S3_PATH=s3://my-backup-bucket
    - SYNC_FOLDER=/var/jenkins_home/ -path "/var/jenkins_home/.ssh/*" -o -path "/var/jenkins_home/plugins/*.jpi" -o -path "/var/jenkins_home/users/*" -o -path "/var/jenkins_home/secrets/*" -o -path "/var/jenkins_home/jobs/*" -o -regex "/var/jenkins_home/[^/]*.xml" -o -regex "/var/jenkins_home/secret.[^/]*"
  volumes_from:
    - vdata
  restart: always
```
