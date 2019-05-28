# Data Virtualization OpenShift Deployment Example - Fuse 7.3 (Q2-19)

This sample project builds on basic knowledge of
* OpenShift
* Teiid
* Maven and Java
* Spring Boot

## Introduction
This project serves as an example, how to deploy a Teiid VDB on OpenShift cluster. This example shows how to configure and deploy your VDB using [fabric8-maven-plugin](https://maven.fabric8.io/) using Spring Boot based Teiid as a MicroService on OpenShift. 

This project will show you 
* How Build Spring Boot based Teiid instance based Maven.
* Configure to deploy a vdb in the project 
* Configure the connection details for your Data Source(s)
* Configure OData route in OpenShift for REST access.

The example's VDB chosen is very simple vdb defined using DDL (customer-vdb.ddl), that contains a single source to keep the complexity to a minimum. Also, this guide is more about how to deploy the vdb in OpenShift than showing the Teiid VDB capabilities, please refer to other sources for learning about Teiid and Data Virtualization.

By the end of this example, we will have a VDB based Teiid Service deployed to OpenShift, and you should be able to issue an OData based REST call to fetch data.

## Pre-Requisites
Before you begin, you must have access to OpenShift Dedicated cluster, or `minishift` or `oc cluster up` running and have access the the instance.

* Requires minishift 1.25+ and openshift client 3.9+.   Minishift 1.31 defaults to its own 3.10 version of oc client.

* To install [minishift](https://www.okd.io/minishift/); which is available for all the major operating systems (Linux, OS X and Windows). This example assumes that you have Minishift installed and can be called from the command line. So, minishift must be available in your search path, i.e. located in a directory contained in your $PATH environment variable (Linux, macOS) or in a directory from your system path (Windows)

* If you are using minishift for fist time you can start using the below command


```
$minishift start --cpus 2 --memory 8GB --disk-size 40GB

```

* Once the Minishift based OpenShift is started, log into OpenShift using the command line. You can use the default username/password of developer/developer, if no credentials have been configured.

```
$oc login
```

The ip of the minishift instance will be shown by the login, or may be obtained by running `$minishif ip`

* Create a new namespace in the OpenShift, i.e. a new project in OpenShift, this is the namespace we will be deploying the vdb-service into.

```
$oc new-project teiid-dataservice

```

* Log into the OpenShift Web Console application using the https://ip:8443/console.

## Example

* Make a clone of this project, and edit pom.xml with your name of the project. 

```
git clone https://github.com/teiid/teiid-openshift-examples.git
cd rdbms-example
vi pom.xml 
```

* This example makes use of two maven plugins
 ** spring-boot-maven-plugin which converts teiid library into a spring boot executable jar. 
 ** fabric8-maven-plugin, which helps to build a docker image based on that executable and optionally deploy into openShift. 

### Java File Changes
The below are the code changes that are required to make it customizable for your environment.

* Edit `/src/main/java/com/example/DataSources.java` file, and add a @Bean method for each data source your VDB will need to access.  Note, the data source name MUST match with configuration property and bean name/method name. The example shown adds a data source for PostgreSQL database called "sampledb".
 
* `/src/main/java/com/example/Application.java` file is main spring boot application file, you can leave that as is, it is the main file that bootstraps the rest of the application.

### Virtual Database
This example requires the VDB to be supplied as DDL based text file. The `src/main/resource` folder contains this example's `customer-vdb.ddl`. If you are using your own virtual database replace that file with yours.

If your virtual database is not in the DDL form, but in .vdb or -vdb.xml format, then you can use the VDB Migration utility to convert into DDL form. For more information see [here](../README.md)


make sure you have your VDB copied over to `src/main/resource` folder, and then edit `/src/main/resources/application.properties` set `teiid.vdb-file` property to your vdb name.  The default is set to the `customer-vdb.ddl` example vdb. 

### Data Sources Configuration

#### Local Mode
* Edit `/src/main/resources/application.properties` to provide properties for each data source. for ex: the properties for above created datasource can be

```
spring.datasource.sampledb.jdbc-url=jdbc:postgresql://localhost/sampledb
spring.datasource.sampledb.username=user
spring.datasource.sampledb.password=user
spring.datasource.sampledb.driver-class-name=org.postgresql.Driver
spring.datasource.sampledb.platform=sampledb
```

Note: The properties you will be providing here will be replaced with ENVIRONMENT variables in OpenShift, so you can use these properties for connecting to your local test database for testing before deploying into the OpenShift. These properties are optional.

* Note that these properties for each type of data source are different, consult documentation for full set of properties. 

#### OpenShift Mode
* When working with OpenShift, there can be properties that are environment specific, or credentials that need to be securely saved in secrets. For that instead of providing these dynamic properties through `application.properties` we can use OpenShift utilities.

* See the `/src/main/fabric8/deploymentconfig.yml` file. This contains a complete Deployment Configuration that is used by `fabric8-maven-plugin` to deploy the Teiid VDB docker image into OpenShift. This file stays mostly same for all projects, except for supplying the properties that you want to override that are defined in the `application.properties`. 

* The properties you define in either `application.properties` or in `deploymentconfig.yml` for data sources are **very specific** to a given data source type. The properties mentioned in this example are only for a relational database store. Please consult data source specific documentation for details for other types data sources.

* Note that an environment properties like `SPRING_DATASOURCE_SAMPLEDB_USERNAME` directly replaces a Spring Boot property `spring.datasource.sampledb.username` in the `application.properties` file. Since the ENVIRONMENT properties do not allow `.` in their names, all the `.` are converted to underscore `_` which application understands to convert into correct configuration.
 
* You may edit the `/src/main/fabric8/deploymentconfig.yml` file to provide ALL ENVIRONMENT properties to configure your data source(s). Note this example reads these properties from a `secret` called `postgresql` on OpenShift for database credentials. For example:

```
- name: SPRING_DATASOURCE_SAMPLEDB_DATABASENAME
  valueFrom:
     secretKeyRef:
       name: postgresql
       key: database-name
```
The above configuration is defining an environment property called `SPRING_DATASOURCE_SAMPLEDB_DATABASENAME` where the `database-name` property is read from a secret defined in OpenShift by the name `postgresql`. As a OpenShift user you can create secrets in the OpenShift using OpenShift web-console or using command line scripting.

For example, create a postgresql instance with the following - substituting whatever you want for user, password and database name:

```
$oc new-app -e POSTGRESQL_USER=user -e POSTGRESQL_PASSWORD=mypassword -e POSTGRESQL_DATABASE=sampledb postgresql
```

Then create the secret file, secret.yaml with those values:

```
apiVersion: v1
kind: Secret
metadata:
  name: postgresql
type: Opaque
stringData:
  database-user: user
  database-name: sampledb
  database-password: mypassword
```

And create the secret:

```
$oc create -f ./secret.yaml
```

Note that just creating or altering a secret does not automatically restart pods that use that secret.

#### Data Source, sample schema and data population (ONLY FOR TESTING, DANGER WILL OVERIDE DATA IN DATABASE)
When working with relational data sources you can supply "schema-xxxx.sql" and "data-xxxx.sql" files to define the DDL to initialize your schema and DML to pre-load data into the database. Note that `xxxx` denotes the data source name you choose in previous steps, and must match exactly. Typically you do not want to do this with production databases, so remove these files if you do not need to setup a database. They are used in this example strictly to ease the database setup.

NOTE: This only works for relational databases, not for any other sources.
 
### Drivers or Additional dependencies for your VDB 
Add any jdbc drivers, which are required by the data sources for the VDB that is being deployed, to the pom.xml. For example, to add the Postgresql JDBC driver, you would add in the following maven configuration within the <dependencies> section of the `pom.xml` file. 

```xml
<dependency>
  <groupId>org.postgresql</groupId>
  <artifactId>postgresql</artifactId>
</dependency>
```
Note, that all dependencies must be supplied as maven artifacts to build a successful docker image. In some cases like Oracle, there is no JDBC driver that is publicly available, in those situations you need to create a local maven repository with required configuration and deploy the driver there and use it in the above process.

### OpenShift Services to Expose 

To use JDBC or OData we need to create services and routes for it on OpenShift. Checkout files `jdbc-svc.yml`, `odata-svc.yml`, `odata-route.yml` in `src/main/fabric8` folder. Make changes to these to fit your needs, but mostly these don't need to be changed.


## Build Example

Execute following command to build and deploy a custom Teiid image to the OpenShift.

```
$mvn -s ../settings.xml clean install -Popenshift
```

Once the build is completed, go back to the OpenShift web-console application and make sure you do not have any errors with deployment. Now go to "Applications/Routes" and find the OData endpoint. Click on the endpoint and then issue requests like below using browser.

```
http://rdbms-example-odata-teiid-dataservice.{ip}.nip.io/CustomerZip?$format=json

Response:
{
  "@odata.context": "http://rdbms-example-odata-teiid-dataservice.192.168.99.100.nip.io/portfolio/$metadata#CustomerZip",
  "value": [
    {
      "id": 10,
      "name": "Joseph Smith",
      "ssn": "CST01002                 ",
      "zip": "12345     "
    },
    {
      "id": 11,
      "name": "Nicholas Ferguson",
      "ssn": "CST01003                 ",
      "zip": null
    },
    {
      "id": 12,
      "name": "Jane Aire",
      "ssn": "CST01004                 ",
      "zip": null
    }
  ]
}

```

### 3Scale Integration
By default the OData service that is defined in this example defines necessary annotations to be discovered by 3Scale API management system. The annotations defined are

```
discovery.3scale.net/scheme: "http"
discovery.3scale.net/port: "8080"
discovery.3scale.net/description-path: "/swagger.json" 
```

If the 3Scale system is defined to same cluster and namespace then your OData API is automatically discovered by 3Scale, where user can configure the API management features.  

### JDBC

If you want to use the JDBC, it is not exposed to outside applications by default (no route created). It is only suitable for applications in the cloud. 

If you have an external application that is using JDBC or the Postgres protocol issue the following:

```
$oc create -f - <<INGRESS
apiVersion: v1
kind: Service
metadata:
  name: rdbms-example-ingress
spec:
  ports:
  - name: teiid
    port: 31000
  type: LoadBalancer 
  selector:
    app: rdbms-example
  sessionAffinity: ClientIP
INGRESS
```

To determine the ip/port run: 

```
$oc get svc rdbms-example-ingress
```

See more at [the OpenShift docs.](https://docs.openshift.com/container-platform/3.11/dev_guide/expose_service/expose_internal_ip_load_balancer.html#getting-traffic-into-cluster-load)