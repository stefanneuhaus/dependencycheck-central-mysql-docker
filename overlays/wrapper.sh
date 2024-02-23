#!/bin/bash

### warning if no NVD_API_KEY is set
if [ -z "${NVD_API_KEY}" ]; then
  echo "--------------------------------------------------------------------------------"
  echo "  Detected that environment variable NVD_API_KEY was not set."
  echo "  Please provide an NVD API key! Updates will be very slow without it."
  echo "  Visit https://nvd.nist.gov/developers/request-an-api-key to get one."
  echo "--------------------------------------------------------------------------------"
fi

### set variables for locations to use at script
DATA_DIR_MYSQL=/var/lib/mysql
DATA_DIR_OWASP_DB_CACHE=/var/lib/owasp-db-cache
if [ ! -d ${DATA_DIR_OWASP_DB_CACHE} ]; then
  mkdirs ${DATA_DIR_OWASP_DB_CACHE}
fi
PASSWORD_FILE_DC_UPDATE_USER=${DATA_DIR_OWASP_DB_CACHE}/dc-update.pwd
BASE_PATH_MD5FILES=${DATA_DIR_OWASP_DB_CACHE}/md5

### methods for reuse in script
reset_mysql_dir() {
  rm -rf ${DATA_DIR_MYSQL}/*
}

reset_config_dir() {
  # do only remove the md5sum files
  rm -rf ${BASE_PATH_MD5FILES}*
}

create_md5sums() {
  echo "create md5sum files of SQL scripts"
  for CURRENT_SQL_FILE in /docker-entrypoint-initdb.d/*
  do
    echo "create md5sum file for $CURRENT_SQL_FILE"
    CURRENT_FILE_MD5SUM=`md5sum ${CURRENT_SQL_FILE} | cut -c -32`
    CURRENT_FILE_MD5SUM_STORAGE=${BASE_PATH_MD5FILES}_${CURRENT_FILE_MD5SUM}.md5
    echo "${CURRENT_FILE_MD5SUM}" > ${CURRENT_FILE_MD5SUM_STORAGE}
    echo "created md5sum file: ${CURRENT_FILE_MD5SUM_STORAGE}"
  done
}

### check if database scripts changed - if reset database
#   TODO: if you remove a SQL script it will not be recognized
# check if data directory of mysql is empty
RESET_DATABASE=FALSE
if [ -z "$(ls -A ${DATA_DIR_MYSQL})" ]; then
  echo "the data directory of mysql database is empty - new installation"
  echo "cleanup config directory"
  reset_config_dir
  create_md5sums
else
  echo "the data directory of mysql database contains data - check SQL changes"
  for CURRENT_SQL_FILE in /docker-entrypoint-initdb.d/*
  do
    echo "analyze file: $CURRENT_SQL_FILE"
    CURRENT_FILE_MD5SUM=`md5sum ${CURRENT_SQL_FILE} | cut -c -32`
    CURRENT_FILE_MD5SUM_STORAGE=${BASE_PATH_MD5FILES}_${CURRENT_FILE_MD5SUM}.md5
    # this file only exists if the md5sum was not changed!
    if [ -f ${CURRENT_FILE_MD5SUM_STORAGE} ]
    then
      echo "SQL file ${CURRENT_SQL_FILE}: NOT CHANGED - md5sum is now ${CURRENT_FILE_MD5SUM}"
    else
      echo "SQL file ${CURRENT_SQL_FILE}: CHANGED - md5sum is now ${CURRENT_FILE_MD5SUM}"
      RESET_DATABASE=TRUE
    fi
  done
fi

### if RESET_DATABASE is TRUE - a change of at least one SQL file was detected
if [ "${RESET_DATABASE}" = TRUE ]; then
  echo "delete content of MYSQL data directory"
  reset_mysql_dir
  echo "delete content of owasp config data directory"
  reset_config_dir
  create_md5sums
fi

### create a random password - if not already exists
#   store this at config data directory, because the volume will store this for next start of container
if [ ! -f ${PASSWORD_FILE_DC_UPDATE_USER} ]
then
  cat /dev/urandom | tr -dc _A-Za-z0-9 | head -c 32 > ${PASSWORD_FILE_DC_UPDATE_USER}
  chmod 400 ${PASSWORD_FILE_DC_UPDATE_USER}
  echo "created MYSQL password for user dc-update"
else
  echo "reuse MYSQL password for user dc-update"
fi

### patch scripts - use password file and env variables
sed -i "s/<DC_UPDATE_PASSWORD>/$(cat ${PASSWORD_FILE_DC_UPDATE_USER})/" /dependencycheck/build.gradle
sed -i "s/<DC_UPDATE_PASSWORD>/$(cat ${PASSWORD_FILE_DC_UPDATE_USER})/" /docker-entrypoint-initdb.d/initialize_security.sql
sed -i "s/<MYSQL_USER>/${MYSQL_USER}/" /docker-entrypoint-initdb.d/initialize_security.sql

supercronic /dependencycheck/database-update-schedule &
/usr/local/bin/docker-entrypoint.sh --user=root
