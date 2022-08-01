#!/bin/sh

supercronic /dependencycheck/database-update-schedule &
/usr/local/bin/docker-entrypoint.sh --user=root
