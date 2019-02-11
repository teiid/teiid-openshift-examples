# Teiid OpenShift Deployment Example

This execute this sample project requires basic knowledge in
* OpenShift
* Teiid
* Maven and Java
* Spring Boot

## Introduction
This project serves as an example, how to deploy a Teiid VDB on OpenShift cluster. This example shows how to configure and deploy your VDB using [fabric8-maven-plugin](https://maven.fabric8.io/) using Spring Boot based Teiid as a MicroService on OpenShift. 

This project will show you 
* How Build Spring Boot based Teiid instance based Maven pom.xml file.
* Configure to deploy a vdb in the project 
* Configure the connection details for your Data Source(s)
* Configure OData route in OpenShift for REST access.

The example VDB chosen is very simple vdb defined using DDL (customer-vdb.ddl), that contains a single source to keep the complexity to a minimum. Also, this guide is more about how to deploy the vdb in OpenShift than showing the Teiid VDB capabilities, please refer to other sources for learning about Teiid and Data Virtualization.

By the end of example, we will have a VDB based Teiid Service deployed to OpenShift, and you should be able to issue an OData based REST call to fetch data.

## Pre-Requisites
Before you begin, you must have access to OpenShift Dedicated cluster, or `minishift` or `oc cluster up` running and have access the the instance.

* Requires minishift 1.25+ and openshift client 3.9+.   Minishift 1.31 defaults to its own 3.10 version of oc client.

* To install [minishift](https://www.okd.io/minishift/); which is available for all the major operating systems (Linux, OS X and Windows). This example assumes that you have Minishift installed and can be called from the command line. So, minishift must be available in your search path, i.e. located in a directory contained in your $PATH environment variable (Linux, macOS) or in a directory from your system path (Windows)

* If you are using minishift for fist time you can start using the below command


```
$minishift start --cpus 2 --memory 8196 --vm-driver virtualbox --disk-size 40GB

```

* Log into OpenShift using on the command line.   Can use the default username/password of developer/developer, if no credentials have been configured.

```
$oc login host:port
```
* Create a new namespace in the OpenShift, i.e. a new project in OpenShift, this is the namespace we will be deploying the vdb-service into.

```
$oc new-project teiid-dataservice

```

* Log into the OpenShift Web Console application using the https://host:port/console.

## Create an sample Database (Optional)
For this example we need a PostgreSQL database. If you already have existing PostgreSQL database available, or using Data Integration with some other database like SQLServer you can skip this step. 

Otherwise, click on Postgresql database icon and create an instance of it. Use user name "user", with password "user". Keep the database name as "sampledb". Note, that this example assumes you created the database on OpenShift.

If you are using your instance of the database, make sure you have the right credentials available to access in `application.properties` file. 

## Example

Make a clone of this project, and edit pom.xml with your name of the project. This example makes use of two maven plugins, see pom.xml for details. 
 ..* spring-boot-maven-plugin which converts teiid library into a spring boot executable jar. 
 ..* fabric8-maven-plugin, which helps to build a docker image based on that executable and optionally deploy into openShift. 

### Java File Changes
* Edit `/src/main/java/com/example/DataSources.java` file, and add a @Bean method for each data source your VDB will need to access.  Note, the data source name MUST match with configuration property and bean name/method name. The example shown adds a data source for PostgreSQL database called "sampledb".
 
* `/src/main/java/com/example/Application.java` file is main spring boot application file, you can leave that as is, it is the main file that bootstraps the rest of the application.

### Virtual Database
This example requires the VDB to be supplied as DDL based text file. The `src/main/resource` folder contains this example's customer-vdb.ddl. If you are using your own virtual database replace that file with yours.

If your virtual database is not in the DDL form, but in .vdb or -vdb.xml format, follow the below procedure to convert the virtual database to DDL form.

```
 # TODO: fill in details here
```

make sure you have your VDB copied over to `src/main/resource` folder, and then edit `/src/main/resources/application.properties` set `teiid.vdb-file` property to your vdb name.  The default is set to the `customer-vdb.ddl` example vdb. 

### Data Sources Configuration

#### Local Mode
Edit `/src/main/resources/application.properties` provide `spring.datasource.xxxx.jdbc-url` kind of properties for each of your data source. Note that the properties you will be providing here will be replaced with ENVIRONMENT variables in OpenShift, so you can use these properties for connecting to your local test database for testing before deploying into the OpenShift. These properties are optional.

#### OpenShift Mode
* Edit `/src/main/fabric8/deploymentconfig.yml` file. This contains a complete Deployment Configuration that is used by `fabric8-maven-plugin` to deploy the Teiid VDB docker image into OpenShift. This file stays mostly same for all projects, except for supplying the properties that you want to override that are defined in the `application.properties`. 

* The properties you define in either `application.properties` or in `deploymentconfig.yml` for data sources are **very specific** to a given data source type. The properties mentioned in this example are only for a relational database store. Please consult data source specific documentation for details for other types data sources.

* Note that an environment properties like `SPRING_DATASOURCE_SAMPLEDB_USERNAME` directly replaces a Spring Boot property `spring.datasource.sampledb.username` in `application.properties` file. Since the ENVIRONMENT properties do not allow `.` in their names, all the `.` are converted to underscore `_` which application understands to convert into correct configuration.
 
* Edit `/src/main/fabric8/deploymentconfig.yml` file to provide ALL ENVIRONMENT properties to configure your data source(s). Note this example reads these properties from a `secret` called `postgresql` on OpenShift for database credentials. For example:

```
- name: SPRING_DATASOURCE_SAMPLEDB_DATABASENAME
  valueFrom:
     secretKeyRef:
       name: postgresql
       key: database-name
```
The above configuration is defining an environment property called  `SPRING_DATASOURCE_SAMPLEDB_DATABASENAME` where the `database-name` property is read from a secret defined in OpenShift by the name `postgresql`. As a OpenShift user you can create secrets in the OpenShift using OpenShift web-console or using command line scripting 

```
oc create secret generic my-secret --from-file=path/to/bar
```
Where the `bar` file has all the secret passwords along with any other configuration in key value format 

```
database-name=sampledb
username=user
password=mysecret
```
#### Data Source, sample schema and data population (ONLY FOR TESTING, DANGER WILL OVERIDE DATA IN DATABASE) 
When working with relational data sources you can supply "schema-xxxx.sql" and "data-xxxx.sql" files to define the DDL to initialize your schema and DML to pre-load data into the database. Note that `xxxx` denotes the data source name you choose in previous steps, and must match exactly. Typically you do not want to do this with production databases, so remove these files if you do not need to setup a database. They are used in this example strictly to ease the database setup.

NOTE: This only works for relational databases, not for any other sources.
 
### Drivers or Additional dependencies for your VDB 
Add any jdbc drivers, which are required by the data sources for the VDB that is being deployed, to the pom.xml. For example, to add the Postgresql JDBC driver, you would add in the following maven configuration within the <dependencies> section of the `pom.xml` file. 

```xml
<dependency>
  <groupId>org.postgresql</groupId>
  <artifactId>postgresql</artifactId>
  <version>${version.postgresql}</version>
</dependency>
```
Note, that all dependencies must be supplied as maven artifacts to build a successful docker image. In some cases like Oracle, there is no JDBC driver that is publicly available, in those situations you need to create a local maven repository with required configuration and deploy the driver there and use it the above process.

### OpenShift Services to Expose 

To use JDBC or OData we need to create services and routes for it on OpenShift. Checkout files `jdbc-svc.yml`, `odata-svc.yml`, `odata-route.yml` in `src/main/fabric8` folder. Make changes to these to fit your needs, but mostly these don't need to be changed.


## Build Example

Execute following command to build and deploy a custom Teiid image to the OpenShift.

```
$ cd rdbms-example
$ mvn clean install -Popenshift
```

Once the build is completed, go back to the OpenShift web-console application and make sure you do not have any errors with deployment. Now go to "Applications/Routes" and find the OData endpoint. Click on the endpoint and then issue requests like below using browser.

```
http://rdbms-example-odata-teiid-dataservice.192.168.99.100.nip.io/customer?$format=json

Response:
{
  "@odata.context": "http://rdbms-example-odata-teiid-dataservice.192.168.99.100.nip.io/$metadata#customer",
  "value": [
    {
      "id": 10,
      "ssn": "CST01002                 ",
      "name": "Joseph Smith"
    },
    {
      "id": 11,
      "ssn": "CST01003                 ",
      "name": "Nicholas Ferguson"
    },
    {
      "id": 12,
      "ssn": "CST01004                 ",
      "name": "Jane Aire"
    }
  ]
}

```

If you want to use the JDBC, it is not exposed to outside applications by default (no route created). It is only suitable for applications in the cloud. If you have another application that is using JDBC, ODBC or SQL-Alchemy you can connect to the JDBC service exposed and issue SQL queries against the virtual database deployed. 