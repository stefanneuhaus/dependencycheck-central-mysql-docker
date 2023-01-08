FROM debian:stable-20221219-slim AS supercronic

ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.1/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=d7f4c0886eb85249ad05ed592902fa6865bb9d70

RUN apt-get update; apt-get install -y curl \
 && curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic



FROM mysql:5.7.40-debian

LABEL maintainer="Stefan Neuhaus <stefan@stefanneuhaus.org>"

ENV MYSQL_DATABASE=dependencycheck \
    MYSQL_RANDOM_ROOT_PASSWORD=true \
    MYSQL_ONETIME_PASSWORD=true \
    MYSQL_USER=dc \
    MYSQL_PASSWORD=dc

WORKDIR /dependencycheck

RUN set -ex && \
    echo "deb http://http.debian.net/debian buster-backports main" >/etc/apt/sources.list.d/buster-backports.list; \
    apt-get update; \
    mkdir -p /usr/share/man/man1; \
    apt-get install -y openjdk-11-jre-headless procps cron; \
    apt-get purge -y --auto-remove; \
    rm -rf /var/lib/apt

COPY overlays/wrapper.sh /
COPY overlays/dependencycheck /dependencycheck/
COPY overlays/docker-entrypoint-initdb.d /docker-entrypoint-initdb.d/

RUN set -ex && \
    /dependencycheck/gradlew wrapper; \
    echo "0 * * * *  /dependencycheck/update.sh" > /dependencycheck/database-update-schedule; \
    chown --recursive mysql:mysql /dependencycheck

COPY --from=supercronic /usr/local/bin/supercronic /usr/local/bin/

RUN set -ex && \
    cat /dev/urandom | tr -dc _A-Za-z0-9 | head -c 32 >/dependencycheck/dc-update.pwd; \
    chmod 400 /dependencycheck/dc-update.pwd; \
    sed -i "s/<DC_UPDATE_PASSWORD>/`cat /dependencycheck/dc-update.pwd`/" /dependencycheck/build.gradle; \
    sed -i "s/<DC_UPDATE_PASSWORD>/`cat /dependencycheck/dc-update.pwd`/" /docker-entrypoint-initdb.d/initialize_security.sql; \
    sed -i "s/<MYSQL_USER>/${MYSQL_USER}/" /docker-entrypoint-initdb.d/initialize_security.sql

EXPOSE 3306

CMD ["/wrapper.sh"]
