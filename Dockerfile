FROM mysql:5.7.20

LABEL maintainer="Stefan Neuhaus <stefan@stefanneuhaus.org>"

ENV MYSQL_DATABASE=dependencycheck \
    MYSQL_ROOT_PASSWORD=v3ry-s3cr3t

WORKDIR /dependencycheck

COPY gradle/wrapper/* /dependencycheck/gradle/wrapper/
COPY gradlew /dependencycheck/

RUN set -ex && \
    echo "deb http://http.debian.net/debian jessie-backports main" >/etc/apt/sources.list.d/jessie-backports.list; \
    apt-get update; \
    apt-get install -y -t jessie-backports openjdk-8-jre-headless cron; \
    apt-get purge -y --auto-remove; \
    rm -rf /var/lib/apt; \
    /dependencycheck/gradlew --no-daemon wrapper; \
    echo "0 * * * *  /dependencycheck/update.sh" >/etc/cron.d/dependencycheck-database-update; \
    crontab /etc/cron.d/dependencycheck-database-update

COPY initialize.sql database.gradle update.sh /dependencycheck/
COPY initialize.sh /docker-entrypoint-initdb.d/
COPY wrapper.sh /wrapper.sh

EXPOSE 3306

CMD ["/wrapper.sh"]
