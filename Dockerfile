FROM alpine:latest

RUN apk add --update-cache py-pip ca-certificates tzdata mysql-client curl \
    && pip install s3cmd \
    && rm -fR /etc/periodic \
    && rm -rf /var/cache/apk/*

COPY backup /usr/local/bin/
RUN chmod +x /usr/local/bin/backup

COPY s3cfg /root/.s3cfg
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod +x /sbin/entrypoint.sh

CMD /sbin/entrypoint.sh
