#!/bin/sh

pgrep java && echo "INFO: Update already running." && exit 1
touch /dependencycheck/update.log
(cd /dependencycheck && ./gradlew --no-daemon -b database.gradle update >>/dependencycheck/update.log 2>&1) || echo "ERROR: update failed."
