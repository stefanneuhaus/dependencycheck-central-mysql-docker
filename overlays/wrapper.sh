#!/bin/sh

if [ -z "${NVD_API_KEY}" ]; then
  echo "--------------------------------------------------------------------------------"
  echo "  Detected that environment variable NVD_API_KEY was not set."
  echo "  Please provide an NVD API key! Updates will be very slow without it."
  echo "  Visit https://nvd.nist.gov/developers/request-an-api-key to get one."
  echo "--------------------------------------------------------------------------------"
fi

# Schedule regular updates
supercronic /dependencycheck/database-update-schedule &

# Trigger initial update (once DB ready)
until mysqladmin ping -udc -pdc; do sleep 1; done && /dependencycheck/update.sh && echo "Initial update done." &

# Start MYSQL
/usr/local/bin/docker-entrypoint.sh --user=root
