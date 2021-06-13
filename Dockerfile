FROM debian:stable-slim@sha256:db5d246d767a1daf54aecdf0e888925e78174b2051bc571337e1ae72aa722b5d AS supercronic

ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=048b95b48b708983effb2e5c935a1ef8483d9e3e

RUN apt-get update; apt-get install -y curl \
 && curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic



FROM mysql:5.7.31

LABEL maintainer="Stefan Neuhaus <stefan@stefanneuhaus.org>"

ENV MYSQL_DATABASE=dependencycheck \
    MYSQL_RANDOM_ROOT_PASSWORD=true \
    MYSQL_ONETIME_PASSWORD=true \
    MYSQL_USER=dc \
    MYSQL_PASSWORD=dc

WORKDIR /dependencycheck

COPY gradle/wrapper/* /dependencycheck/gradle/wrapper/
COPY gradlew /dependencycheck/
COPY settings.gradle /dependencycheck/

RUN set -ex && \
    echo "deb http://http.debian.net/debian buster-backports main" >/etc/apt/sources.list.d/buster-backports.list; \
    apt-get update; \
    mkdir -p /usr/share/man/man1; \
    apt-get install -y openjdk-11-jre-headless procps cron; \
    apt-get purge -y --auto-remove; \
    rm -rf /var/lib/apt; \
    /dependencycheck/gradlew --no-daemon wrapper; \
    echo "0 * * * *  /dependencycheck/update.sh" > /dependencycheck/dependencycheck-database-update; \
    cat /dev/urandom | tr -dc _A-Za-z0-9 | head -c 32 >/dependencycheck/dc-update.pwd; \
    chmod 400 /dependencycheck/dc-update.pwd; \
    chown --recursive mysql:mysql /dependencycheck

COPY --from=supercronic /usr/local/bin/supercronic /usr/local/bin/
COPY database.gradle update.sh /dependencycheck/
COPY initialize_schema.sql /docker-entrypoint-initdb.d/
COPY initialize_security.sql /docker-entrypoint-initdb.d/

RUN set -ex && \
    sed -i "s/<DC_UPDATE_PASSWORD>/`cat /dependencycheck/dc-update.pwd`/" /dependencycheck/database.gradle; \
    sed -i "s/<DC_UPDATE_PASSWORD>/`cat /dependencycheck/dc-update.pwd`/" /docker-entrypoint-initdb.d/initialize_security.sql; \
    sed -i "s/<MYSQL_USER>/${MYSQL_USER}/" /docker-entrypoint-initdb.d/initialize_security.sql

COPY wrapper.sh /wrapper.sh

EXPOSE 3306

CMD ["/wrapper.sh"]
