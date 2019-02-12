#!/bin/sh

# Alter root user and set password to something generated
MYSQL_ROOT_PASSWORD=$(cat /dependencycheck/root.pwd)
echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';" | mysql --user=root --password=password-is-changed-during-initialization

MYSQL="mysql --user=root --password=${MYSQL_ROOT_PASSWORD} dependencycheck"

$MYSQL < /dependencycheck/initialize.sql

# Create a dc-update user that will update the database
DCUPDATEPWD=$(cat /dependencycheck/dc-update.pwd)
echo "CREATE USER 'dc-update'@127.0.0.1 IDENTIFIED BY '${DCUPDATEPWD}';" | $MYSQL
echo "GRANT SELECT, INSERT, DELETE, UPDATE ON dependencycheck.* TO 'dc-update'@127.0.0.1;" | $MYSQL
echo "GRANT EXECUTE ON PROCEDURE dependencycheck.save_property TO 'dc-update'@127.0.0.1;" | $MYSQL
sed -i "s/password-is-changed-during-initialization/${DCUPDATEPWD}/" /dependencycheck/database.gradle

# Modify default user to be read-only
echo "REVOKE ALL PRIVILEGES, GRANT OPTION FROM ${MYSQL_USER};" | $MYSQL
echo "GRANT SELECT ON dependencycheck.* TO '${MYSQL_USER}';" | $MYSQL
