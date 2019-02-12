FROM mysql:5.7.25

LABEL maintainer="Stefan Neuhaus <stefan@stefanneuhaus.org>"

ENV MYSQL_DATABASE=dependencycheck \
    MYSQL_ROOT_PASSWORD=password-is-changed-during-initialization \
    MYSQL_USER=dc \
    MYSQL_PASSWORD=dc

WORKDIR /dependencycheck

COPY gradle/wrapper/* /dependencycheck/gradle/wrapper/
COPY gradlew /dependencycheck/

RUN set -ex && \
    echo "deb http://http.debian.net/debian stretch-backports main" >/etc/apt/sources.list.d/stretch-backports.list; \
    apt-get update; \
    mkdir -p /usr/share/man/man1; \
    apt-get install -y -t stretch-backports openjdk-8-jre-headless procps cron; \
    apt-get purge -y --auto-remove; \
    rm -rf /var/lib/apt; \
    /dependencycheck/gradlew --no-daemon wrapper; \
    echo "0 * * * *  /dependencycheck/update.sh" >/etc/cron.d/dependencycheck-database-update; \
    crontab /etc/cron.d/dependencycheck-database-update; \
    cat /dev/urandom | tr -dc _A-Za-z0-9 | head -c 32 >/dependencycheck/dc-update.pwd; \
    chmod 400 /dependencycheck/dc-update.pwd; \
    cat /dev/urandom | tr -dc _A-Za-z0-9 | head -c 32 >/dependencycheck/root.pwd; \
    chmod 400 /dependencycheck/root.pwd; \
    chown --recursive mysql:mysql /dependencycheck

COPY initialize.sql database.gradle update.sh /dependencycheck/
COPY initialize.sh /docker-entrypoint-initdb.d/
COPY wrapper.sh /wrapper.sh

EXPOSE 3306

CMD ["/wrapper.sh"]
