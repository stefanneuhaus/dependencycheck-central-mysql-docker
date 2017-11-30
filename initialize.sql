/*
 Copyright 2017 Stefan Neuhaus

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

/*
 This is a modified version of "initialize_mysql.sql" from OWASP DependencyCheck:
 https://github.com/jeremylong/DependencyCheck/blob/master/dependency-check-core/src/main/resources/data/initialize_mysql.sql

 Modifications applied:
 - Replace hard-coded database user name and password by placeholders
 - Drop and merge statements: the original script evolved over time and provided
   capabilities for upgrading from an older schema definition. This upgrade
   capability is not needed in the Docker context.
 - Reorder statements
 - Reformatting
 */
USE dependencycheck;

CREATE TABLE properties (id varchar(50) PRIMARY KEY, value varchar(500));

CREATE TABLE vulnerability (id int auto_increment PRIMARY KEY, cve VARCHAR(20) UNIQUE,
  description VARCHAR(8000), cwe VARCHAR(10), cvssScore DECIMAL(3,1), cvssAccessVector VARCHAR(20),
  cvssAccessComplexity VARCHAR(20), cvssAuthentication VARCHAR(20), cvssConfidentialityImpact VARCHAR(20),
  cvssIntegrityImpact VARCHAR(20), cvssAvailabilityImpact VARCHAR(20));

CREATE TABLE reference (cveid INT, name VARCHAR(1000), url VARCHAR(1000), source VARCHAR(255),
  CONSTRAINT fkReference FOREIGN KEY (cveid) REFERENCES vulnerability(id) ON DELETE CASCADE);

CREATE TABLE cpeEntry (id INT auto_increment PRIMARY KEY, cpe VARCHAR(250), vendor VARCHAR(255), product VARCHAR(255));

CREATE TABLE software (cveid INT, cpeEntryId INT, previousVersion VARCHAR(50),
  CONSTRAINT fkSoftwareCve FOREIGN KEY (cveid) REFERENCES vulnerability(id) ON DELETE CASCADE,
  CONSTRAINT fkSoftwareCpeProduct FOREIGN KEY (cpeEntryId) REFERENCES cpeEntry(id),
  PRIMARY KEY (cveid, cpeEntryId));

CREATE INDEX idxVulnerability ON vulnerability(cve);
CREATE INDEX idxReference ON reference(cveid);
CREATE INDEX idxCpe ON cpeEntry(cpe);
CREATE INDEX idxCpeEntry ON cpeEntry(vendor, product);
CREATE INDEX idxSoftwareCve ON software(cveid);
CREATE INDEX idxSoftwareCpe ON software(cpeEntryId);


DELIMITER //
CREATE PROCEDURE save_property
(IN prop varchar(50), IN val varchar(500))
BEGIN
INSERT INTO properties (`id`, `value`) VALUES (prop, val)
  ON DUPLICATE KEY UPDATE `value`=val;
END //
DELIMITER ;


INSERT INTO properties(id, value) VALUES ('version', '3.0');


CREATE USER 'dc' IDENTIFIED BY 'change-me';
GRANT SELECT, INSERT, DELETE, UPDATE ON dependencycheck.* TO 'dc';
GRANT EXECUTE ON PROCEDURE dependencycheck.save_property TO 'dc';
