FROM --platform=linux/amd64 alpine:latest AS supercronic-amd64

ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=cd48d45c4b10f3f0bfdd3a57d054cd05ac96812b

RUN set -ex  \
    && apk add curl \
    && curl -fsSLO "$SUPERCRONIC_URL" \
    && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
    && chmod +x "$SUPERCRONIC" \
    && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
    && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic


FROM --platform=linux/arm64 alpine:latest AS supercronic-arm64

ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-arm64 \
    SUPERCRONIC=supercronic-linux-arm64 \
    SUPERCRONIC_SHA1SUM=512f6736450c56555e01b363144c3c9d23abed4c

RUN set -ex  \
    && apk add curl \
    && curl -fsSLO "$SUPERCRONIC_URL" \
    && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
    && chmod +x "$SUPERCRONIC" \
    && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
    && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

### at the COPY --from you can't use global ARGs. Because of this it needs to be wrapped here!!!
FROM supercronic-${TARGETARCH} AS supercronic


FROM mysql:8.0.35

LABEL maintainer="Stefan Neuhaus <stefan@stefanneuhaus.org>"

# these ENV variables will used by MYSQL for startup
ENV MYSQL_DATABASE=dependencycheck \
    MYSQL_RANDOM_ROOT_PASSWORD=true \
    MYSQL_ONETIME_PASSWORD=true \
    MYSQL_USER=dc \
    MYSQL_PASSWORD=dc

WORKDIR /dependencycheck

RUN set -ex && \
    microdnf install java-21-openjdk-headless procps; \
    microdnf clean all

COPY overlays/wrapper.sh /
COPY overlays/dependencycheck /dependencycheck/
COPY overlays/docker-entrypoint-initdb.d /docker-entrypoint-initdb.d/

RUN set -ex && \
    /dependencycheck/gradlew wrapper; \
    echo "0/2 * * * *  /dependencycheck/update.sh" > /dependencycheck/database-update-schedule; \
    chown --recursive mysql:mysql /dependencycheck


COPY --from=supercronic /usr/local/bin/supercronic /usr/local/bin/

VOLUME /var/lib/mysql
VOLUME /var/lib/owasp-db-cache

EXPOSE 3306

CMD ["/wrapper.sh"]
