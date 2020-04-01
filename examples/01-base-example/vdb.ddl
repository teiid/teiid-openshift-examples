CREATE DATABASE Portfolio OPTIONS (ANNOTATION 'The Portfolio VDB');
USE DATABASE Portfolio;

--############ translators ############
CREATE FOREIGN DATA WRAPPER rest;
CREATE FOREIGN DATA WRAPPER postgresql;

--############ Servers ############
CREATE SERVER "AccountsDB" FOREIGN DATA WRAPPER postgresql;
CREATE SERVER "QuoteSvc" FOREIGN DATA WRAPPER rest;

--############ Schemas ############
CREATE SCHEMA marketdata SERVER "QuoteSvc";
CREATE SCHEMA accounts SERVER "AccountsDB";

CREATE VIRTUAL SCHEMA Portfolio;

--############ Schema:marketdata ############
SET SCHEMA marketdata;

IMPORT FROM SERVER "QuoteSvc" INTO marketdata;

--############ Schema:accounts ############
SET SCHEMA accounts;

IMPORT FROM SERVER "AccountsDB" INTO accounts OPTIONS (
        "importer.useFullSchemaName" 'false',
        "importer.tableTypes" 'TABLE,VIEW');


--############ Schema:Portfolio ############
SET SCHEMA Portfolio;
           
CREATE VIEW StockPrice (
    symbol string,
    price bigdecimal
) AS  
    SELECT SP.symbol, SP.price
    FROM (EXEC MarketData.getTextFiles('*.txt')) AS f, 
    TEXTTABLE(f.file COLUMNS symbol string, price bigdecimal HEADER) AS SP;
          
CREATE VIEW AccountValues (
    LastName string PRIMARY KEY,
    FirstName string,
    StockValue bigdecimal
) AS
    SELECT c.lastname as LastName, c.firstname as FirstName, sum((h.shares_count*sp.price)) as StockValue 
    FROM Customer c JOIN Account a on c.SSN=a.SSN 
    JOIN Holdings h on a.account_id = h.account_id 
    JOIN product p on h.product_id=p.id 
    JOIN StockPrice sp on sp.symbol = p.symbol
    WHERE a.type='Active'
    GROUP BY c.lastname, c.firstname;