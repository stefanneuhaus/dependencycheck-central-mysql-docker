#!/bin/sh

supercronic /dependencycheck/dependencycheck-database-update &
/usr/local/bin/docker-entrypoint.sh --user=root
