
/*
###########################################
# START DATABASE customer
###########################################
*/
CREATE DATABASE customer VERSION '1' OPTIONS (ANNOTATION 'Customer VDB');
USE DATABASE customer VERSION '1';

--############ Servers ############
CREATE SERVER sampledb TYPE 'NONE' FOREIGN DATA WRAPPER postgresql;


--############ Schemas ############
CREATE SCHEMA accounts SERVER sampledb;

CREATE VIRTUAL SCHEMA portfolio;


--############ Schema:accounts ############
SET SCHEMA accounts;


--############ Schema:portfolio ############
SET SCHEMA portfolio;

CREATE VIEW CustomerZip (
	id long,
	name string,
	ssn string,
	zip string,
	PRIMARY KEY(id)
)
AS
SELECT c.ID AS id, c.NAME AS name, c.SSN AS ssn, a.ZIP AS zip FROM accounts.CUSTOMER AS c LEFT OUTER JOIN accounts.ADDRESS AS a ON c.ID = a.CUSTOMER_ID;
/*
###########################################
# END DATABASE customer
###########################################
*/

