#!/bin/sh

if [ -z "${NVD_API_KEY}" ]; then
  echo "--------------------------------------------------------------------------------"
  echo "  Detected that environment variable NVD_API_KEY was not set."
  echo "  Please provide an NVD API key! Updates will be very slow without it."
  echo "  Visit https://nvd.nist.gov/developers/request-an-api-key to get one."
  echo "--------------------------------------------------------------------------------"
fi

supercronic /dependencycheck/database-update-schedule &
/usr/local/bin/docker-entrypoint.sh --user=root
