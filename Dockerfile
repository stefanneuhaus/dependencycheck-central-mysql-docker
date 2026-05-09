FROM oraclelinux:10-slim AS supercronic

ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.45/supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=e894b193bea75a5ee644e700c59e30eedc804cf7 \
    SUPERCRONIC=supercronic-linux-amd64

RUN curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic


FROM mysql:8.4.9

LABEL maintainer="Stefan Neuhaus <stefan@stefanneuhaus.org>"

ENV MYSQL_DATABASE=dependencycheck \
    MYSQL_RANDOM_ROOT_PASSWORD=true \
    MYSQL_ONETIME_PASSWORD=true \
    MYSQL_USER=dc \
    MYSQL_PASSWORD=dc

WORKDIR /dependencycheck

RUN set -ex && \
    microdnf install java-25-openjdk-headless procps; \
    microdnf clean all

COPY overlays/wrapper.sh /
COPY overlays/dependencycheck /dependencycheck/
COPY overlays/docker-entrypoint-initdb.d /docker-entrypoint-initdb.d/

RUN set -ex && \
    /dependencycheck/gradlew wrapper; \
    echo "@hourly  /dependencycheck/update.sh" > /dependencycheck/database-update-schedule; \
    chown --recursive mysql:mysql /dependencycheck

COPY --from=supercronic /usr/local/bin/supercronic /usr/local/bin/

RUN set -ex && \
    PASSWORD="$(tr -dc 'A-Za-z0-9_' </dev/urandom | head -c 32)"; \
    echo "$PASSWORD" >/dependencycheck/dc-update.pwd; \
    sed -i "s/<DC_UPDATE_PASSWORD>/$(cat /dependencycheck/dc-update.pwd)/" /dependencycheck/build.gradle; \
    sed -i "s/<DC_UPDATE_PASSWORD>/$(cat /dependencycheck/dc-update.pwd)/" /docker-entrypoint-initdb.d/initialize_security.sql; \
    sed -i "s/<MYSQL_USER>/${MYSQL_USER}/" /docker-entrypoint-initdb.d/initialize_security.sql

EXPOSE 3306

CMD ["/wrapper.sh"]
