# Teiid OpenShift Deployment Example

This execute this sample project requires basic knowledge in
* OpenShift
* Teiid
* Maven
* Spring Boot

## Introduction
This project serves as an example, how to deploy a Teiid VDB on OpenShift cluster. This example shows how to configure and deploy your VDB using [fabric8-maven-plugin](https://maven.fabric8.io/) using Spring Boot based Teiid as MicroService on OpenShift. 

This project will show you 
* How Build Spring Boot based Teiid instance based Maven pom.xml file.
* Configure to deploy a -vdb.xml in the project 
* Configure the connection details for your Data Source(s)
* Configure OData route.

The example VDB chosen is very simple vdb defined using DDL (customer.ddl), that containis a single source to keep the complexity to a minimum. Also, this guide is more about how to deploy the vdb in OpenShift than showing the Teiid VDB capabilities, please refer to other sources for learning about Teiid and Data Virtualization.

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
* For this example we need a PostgreSQL database. If you already have existing PostgreSQL database available, you can skip this step. Otherwise, click on Postgresql database icon and create an instance of it. Use user name "user", with password "user". Keep the database name as "sampledb". Note, that this example assumes you created the database on OpenShift. 

## Example Code

* Make a clone of this project, and edit pom.xml with your name of the project. This example makes use of two maven plugins, spring-boot-maven-plugin which converts teiid library into a spring boot executable jar. Then fabric8-maven-plugin, which helps to build a docker image based on that executable and optionally deploy into openShift. Please pom.xml for details.

* Place your vdb file into the `src/main/resource` folder. The example customer.ddl should already exist. 

* Edit `/src/main/java/com/example/DataSources.java` file, and add a @Bean method for each data source your VDB will need to access.  Note, the data source name MUST match with configuration property and bean name/method name. The example shown adds a data source for Postgresql database called "sampledb".
 VERSION '1'
* `/src/main/java/com/example/Application.java` file is main spring boot application file, you leave that as is.

* Edit `/src/main/resources/application.properties` set `teiid.vdb-file` property to your vdb name.  The default is set to the customer.ddl example vdb.  Also provide `spring.datasource.xxxx.url` kind of properties for each of your data source. Note that the properties you provided here can be replaced with ENVIRONMENT variables in OpenShift, so you can use these properties for connecting to your local test database for testing.

* *Optionally*, when working with relational data sources you can supply "schema-xxxx.sql" and "data-xxxx.sql" files to define the DDL to initialize your schema and DML to pre-load data into the database. Note that `xxxx` denotes the data source name you choose in previous steps, and must match exactly. Typically you do not want to do this with production databases, so remove these properties if you do not need to setup a database. They are used in this example strictly to ease the database setup.
 
* Edit `/src/main/fabric8/deploymentconfig.yml` file. This contains a complete DeploymentConfig that is used by `fabric8-maven-plugin` to deploy the teiid vdb docker image into OpenShift. This file stays mostly same for all projects, except for supplying the properties that you want to override that are defined in the `application.properties`. Please checkout `env` properties like `SPRING_DATASOURCE_SAMPLEDB_USERNAME` that directly replaces a Spring Boot property `spring.datasource.sampledb.username`. Since the ENV properties do not allow `.` in their names, they are converted to underscore `_`. Edit this file to provide any such properties to help configure your data source. Note this example reads these properties from a `secret` called `postgresql` on OpenShift for database credentials. There are many ways to securely supply the properties in OpenShift. 

* To use JDBC or OData we need to create services and routes for it on OpenShift. Checkout files `jdbc-svc.yml`, `odata-svc.yml`, `odata-route.yml` in `src/main/fabric8` folder. Make changes to these to fit your needs, but mostly these don't need to be changed. 
 
* Add any jdbc drivers, which are required by the data sources for the VDB that is being deployed, to the pom.xml. For example, to add the Postgresql JDBC driver, you would add in the following maven configuration within the <dependencies> section:

```xml
<dependency>
  <groupId>org.postgresql</groupId>
  <artifactId>postgresql</artifactId>
  <version>${version.postgresql}</version>
</dependency>
```

Now the configuration is complete.


## Build Example

Execute following command to build and deploy a custom Teiid image to the OpenShift.
```
$ cd rdbms-example
$ mvn clean install -Popenshift
```

Once the build is completed, go back to the OpenShift web-console application and make sure you do not have any errors with deployment. Now go to "Applications/Routes" and find the OData endpoint. Click on the endpoint and you can issue URL to confi, and then issue requests like below using browser.

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



