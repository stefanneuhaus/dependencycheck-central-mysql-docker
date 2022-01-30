-- "dc-update" user: change password and restrict to local access
CREATE USER 'dc-update'@127.0.0.1 IDENTIFIED BY '<DC_UPDATE_PASSWORD>';
GRANT SELECT, INSERT, UPDATE, DELETE ON dependencycheck.* TO 'dc-update'@127.0.0.1;
GRANT EXECUTE ON PROCEDURE dependencycheck.save_property TO 'dc-update'@127.0.0.1;
GRANT EXECUTE ON PROCEDURE dependencycheck.merge_ecosystem TO 'dc-update'@127.0.0.1;
GRANT EXECUTE ON PROCEDURE dependencycheck.cleanup_orphans TO 'dc-update'@127.0.0.1;
GRANT EXECUTE ON PROCEDURE dependencycheck.update_vulnerability TO 'dc-update'@127.0.0.1;
GRANT EXECUTE ON PROCEDURE dependencycheck.insert_software TO 'dc-update'@127.0.0.1;
GRANT EXECUTE ON PROCEDURE dependencycheck.update_ecosystems TO 'dc-update'@127.0.0.1;
GRANT EXECUTE ON PROCEDURE dependencycheck.update_ecosystems2 TO 'dc-update'@127.0.0.1;

-- dependency-check user: restrict to read-only access
REVOKE ALL PRIVILEGES, GRANT OPTION FROM '<MYSQL_USER>';
GRANT SELECT ON dependencycheck.* TO '<MYSQL_USER>';
