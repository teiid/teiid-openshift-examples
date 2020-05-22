# Teiid JDBC Simple Client

Runs a simple query against a Teiid JDBC or PG endpoint using a Spring JDBC template.  

Edit the src/main/resources/application.properties and/or one of the profile properties to match the username, password, and url of the Teiid instance you are testing against.  This example assumes the ClientZip view exists, which is exposed by the rdbms and security examples.

Build using:

```
$mvn clean install
```

Run using:

```
java -jar target/simple-jdbc-client-0.1.0.jar
```