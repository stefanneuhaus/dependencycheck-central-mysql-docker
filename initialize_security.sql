-- "root" user: change password
ALTER USER 'root'@'localhost' IDENTIFIED BY '<MYSQL_ROOT_PASSWORD>';

-- "dc-update" user: change password and restrict to local access
CREATE USER 'dc-update'@127.0.0.1 IDENTIFIED BY '<DC_UPDATE_PASSWORD>';
GRANT SELECT, INSERT, DELETE, UPDATE ON dependencycheck.* TO 'dc-update'@127.0.0.1;
GRANT EXECUTE ON PROCEDURE dependencycheck.save_property TO 'dc-update'@127.0.0.1;
GRANT EXECUTE ON PROCEDURE dependencycheck.update_ecosystems TO 'dc-update'@127.0.0.1;
GRANT EXECUTE ON PROCEDURE dependencycheck.cleanup_orphans TO 'dc-update'@127.0.0.1;

-- dependency-check user: restrict to read-only access
REVOKE ALL PRIVILEGES, GRANT OPTION FROM '<MYSQL_USER>';
GRANT SELECT ON dependencycheck.* TO '<MYSQL_USER>';
