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

The example VDB chosen is very simple dynamic (customer-vdb.xml) vdb with a single source to keep the complexity to a minimum. Also, this guide is more about how to deploy the vdb in OpenShift than showing the Teiid VDB capabilities, please refer to other sources for learning about Teiid and Data Virtualization.

By the end of example, we will have VDB based Teiid Service deployed to OpenShift, and you should be able to issue a OData based REST call to fetch data.  

## Pre-Requisites
Before you begin, you must have access to OpenShift Dedicated cluster, or `minishift` or `oc cluster up` running and have access the the instance.

* To install [minishift 3.9+](https://www.okd.io/minishift/); which is available for all the major operating systems (Linux, OS X and Windows). The following examples assume that you have Minishift installed and can be called with minishift from the command line. So, minishift is supposed to be available in your search path, i.e. located in a directory contained in your $PATH environment variable (Linux, macOS) or in a directory from your system path (Windows)

* If you are using minishift for fist time you can start using below command


```
$minishift start --cpus 2 --memory 8196 --vm-driver virtualbox --disk-size 40GB

```

* Log into OpenShift using on the command line. 

```
$oc login host:port
```
* Create a new namespace in the OpenShift, i.e. a new project in OpenShift, this is the namespace we will be deploying the vdb-service into.

```
$oc new-project teiid-dataservice

```

* Using the https://host:port/console log into the OpenShift Web Console application.
* For this example we need a PostgreSQL database. If you already have existing PostgreSQL database available, you can skip step. Otherwise, click on Postgresql database icon and create instance of it. Use user name "user", with password "user". Keep the database name as "sampledb". Note, that this example assumes you created the database on OpenShift. 

## Example Code

* Make a clone of this project, and edit pom.xml with your name of the project. This example makes use of two maven plugins, spring-boot-maven-plugin which converts teiid library into a spring boot executable jar. Then fabric8-maven-plugin, which helps to build a docker image based on that executable and optionally deploy into openShift. Please pom.xml for details.

* Place your -vdb.xml in the `src/main/resource` folder. You can place use .vdb file here.

* Edit `/src/main/java/com/example/DataSources.java` file, and add a @Bean method for each of the data source you are going to need in you VDB. Note the data source name MUST match with configuration property and bean name/method name. The example shown adds a data source for Postgresql database called "sampledb".

* `/src/main/java/com/example/Application.java` file is main spring boot application file, you leave that as is.

* Edit `application.properties` set `teiid.vdb-file` property to your vdb name. Also provide provide `spring.datasource.xxxx.url` kind of properties for each of your data source. Note that the properties you provided here can be replaced with ENVIRONMENT variables in OpenShift, so you can use these properties for connecting to your local test database for testing.

* When working with relational data sources you can *optionally* supply "schema-xxxx.sql" and "data-xxxx.sql" files to define the DDL schema to initialize your schema and data in the database. Note that `xxxx` denotes the data source name you choose in previous steps, and must match exactly. Typically you do not want to do with production databases, so remove them if you do not need to setup database. Here we used strictly to ease the database setup for this example.
 
* Edit `deploymentconfig.yml` in the `src/main/fabric8` folder. This will contains complete DeploymentConfig that used by `fabric8-maven-plugin` to deploy the teiid vdb docker image into OpenShift. This file stays mostly same all projects, except for supplying the properties that you want to override that are defined in the `application.properties`. Please checkout `env` properties like `SPRING_DATASOURCE_SAMPLEDB_USERNAME` that directly replaces a Spring Boot property `spring.datasource.sampledb.username`. Since the ENV properties do not allow `.` in their names, they are converted to underscore `_`. Edit this file to provide any such properties to help configure your data source. Note this example reads these properties from a `secret` called `postgresql` on OpenShift for database credentials. There are many ways securely supply the properties in OpenShift. 

* To use JDBC or OData we need to create services and routes for it on OpenShift. Checkout files `jdbc-svc.yml`, `odata-svc.yml`, `odata-route.yml` in `src/main/fabric8` folder. Make changes to these to fir your needs, mostly you do not need to. 
 
* Add any jdbc drivers that are required by the VDB you are deploying to the pom.xml. For example to enable support for Postgresql, you would add in <dependencies> section the following maven configuration for Postgresql JDBC driver

```xml
<dependency>
  <groupId>org.postgresql</groupId>
  <artifactId>postgresql</artifactId>
  <version>${version.postgresql}</version>
</dependency>
```

Now all the configuration is complete.


## Build Example

Execute following command to deploy custom Teiid image to the OpenShift.
```
$ mvn clean install -Popenshift
```

Once the build is completed, go back OpenShift web-console application and make sure you do not have any errors with deployment. Now go to "Applications/Routes" and find the OData endpoint. Click on the endpoint and you can issue URL, and then issue requests like below using browser.

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



