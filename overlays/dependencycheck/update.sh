#!/bin/sh

pgrep -a java && echo "INFO: Update already running." && exit 1
touch /dependencycheck/update.log
(cd /dependencycheck && ./gradlew -s update >>/dependencycheck/update.log 2>&1) || (echo "ERROR: update failed." && exit 2)
