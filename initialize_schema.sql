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
 https://github.com/jeremylong/DependencyCheck/blob/master/core/src/main/resources/data/initialize_mysql.sql

 Modifications applied:
 - Drop and merge statements: the original script evolved over time and provided
   capabilities for upgrading from an older schema definition. This upgrade
   capability is not needed in the Docker context.
 - Remove setup of security aspects: user, password, and permissions
 - Reorder statements
 - Reformatting
 */
CREATE TABLE properties (id varchar(50) PRIMARY KEY, value varchar(500));

CREATE TABLE vulnerability (id int auto_increment PRIMARY KEY, cve VARCHAR(20) UNIQUE,
  description VARCHAR(8000), cvssV2Score DECIMAL(3,1), cvssV2AccessVector VARCHAR(20),
  cvssV2AccessComplexity VARCHAR(20), cvssV2Authentication VARCHAR(20), cvssV2ConfidentialityImpact VARCHAR(20),
  cvssV2IntegrityImpact VARCHAR(20), cvssV2AvailabilityImpact VARCHAR(20), cvssV2Severity VARCHAR(20),
  cvssV3AttackVector VARCHAR(20), cvssV3AttackComplexity VARCHAR(20), cvssV3PrivilegesRequired VARCHAR(20),
  cvssV3UserInteraction VARCHAR(20), cvssV3Scope VARCHAR(20), cvssV3ConfidentialityImpact VARCHAR(20),
  cvssV3IntegrityImpact VARCHAR(20), cvssV3AvailabilityImpact VARCHAR(20), cvssV3BaseScore DECIMAL(3,1),
  cvssV3BaseSeverity VARCHAR(20));

CREATE TABLE reference (cveid INT, name VARCHAR(1000), url VARCHAR(1000), source VARCHAR(255),
  CONSTRAINT fkReference FOREIGN KEY (cveid) REFERENCES vulnerability(id) ON DELETE CASCADE);

CREATE TABLE cpeEntry (id INT auto_increment PRIMARY KEY, part CHAR(1), vendor VARCHAR(255), product VARCHAR(255),
  version VARCHAR(255), update_version VARCHAR(255), edition VARCHAR(255), lang VARCHAR(20), sw_edition VARCHAR(255),
  target_sw VARCHAR(255), target_hw VARCHAR(255), other VARCHAR(255), ecosystem VARCHAR(255));

CREATE TABLE software (cveid INT, cpeEntryId INT, versionEndExcluding VARCHAR(50), versionEndIncluding VARCHAR(50),
  versionStartExcluding VARCHAR(50), versionStartIncluding VARCHAR(50), vulnerable BOOLEAN,
  CONSTRAINT fkSoftwareCve FOREIGN KEY (cveid) REFERENCES vulnerability(id) ON DELETE CASCADE,
  CONSTRAINT fkSoftwareCpeProduct FOREIGN KEY (cpeEntryId) REFERENCES cpeEntry(id));

CREATE TABLE cweEntry (cveid INT, cwe VARCHAR(20),
  CONSTRAINT fkCweEntry FOREIGN KEY (cveid) REFERENCES vulnerability(id) ON DELETE CASCADE);


CREATE INDEX idxVulnerability ON vulnerability(cve);
CREATE INDEX idxReference ON reference(cveid);
CREATE INDEX idxCwe ON cweEntry(cveid);
CREATE INDEX idxCpe ON cpeEntry(vendor, product);
CREATE INDEX idxCpeEntry ON cpeEntry(part, vendor, product, version);
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


INSERT INTO properties(id, value) VALUES ('version', '4.1');
