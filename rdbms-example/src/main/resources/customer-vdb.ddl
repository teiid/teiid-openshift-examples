-- This is simple VDB that connects to a single PostgreSQL database and exposes it 
-- as a Virtual Database.

-- create database  
CREATE DATABASE customer OPTIONS (ANNOTATION 'Customer VDB');
USE DATABASE customer;

-- create translators and connections to source
CREATE FOREIGN DATA WRAPPER postgresql;
CREATE SERVER sampledb TYPE 'NONE' FOREIGN DATA WRAPPER postgresql OPTIONS ("jndi-name" 'sampledb');

-- create schema, then import the metadata from the PostgreSQL database
CREATE SCHEMA accounts SERVER sampledb;
CREATE VIRTUAL SCHEMA portfolio;

SET SCHEMA accounts;
IMPORT FOREIGN SCHEMA public FROM SERVER sampledb INTO accounts OPTIONS("importer.useFullSchemaName" 'false');

SET SCHEMA portfolio;

CREATE VIEW CustomerZip(id bigint PRIMARY KEY, name string, ssn string, zip string) AS 
    SELECT c.ID as id, c.NAME as name, c.SSN as ssn, a.ZIP as zip 
    FROM accounts.CUSTOMER c LEFT OUTER JOIN accounts.ADDRESS a 
    ON c.ID = a.CUSTOMER_ID;   