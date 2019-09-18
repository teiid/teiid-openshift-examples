# Teiid OpenShift Deployment Example

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

## Prerequisites

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
$oc new-project myproject

```

* Log into the OpenShift Web Console application using the https://ip:8443/console.

## Sample Database (Optional Step)	

For this example we need a PostgreSQL database. If you already have existing PostgreSQL database available, or using Data Integration with some other database like SQLServer or MySQL you can skip this step. However, in the configuration defined in next steps, you need to provide appropriate credentials.

 If you are loggined into OpenShift Console click on Postgresql database icon and create an instance of it. Use user name "user", with password "mypassword". Keep the database name as "sampledb". Note, that this example assumes you created the database on OpenShift. If you use different values than above, please make sure you have changed the appropriate configuration.

 You can also create this database from command line by executing the following	

 ```bash
oc new-app \
  -e POSTGRESQL_USER=user \
  -e POSTGRESQL_PASSWORD=mypassword \
  -e POSTGRESQL_DATABASE=sampledb \
  postgresql:9.5
```	

The above command automatically creates `secret` in OpenShift for you, from where the credentials are read for the application. If you are working with your own database, then create a `secret` as shown below

To create a `secret`, create a file `secret.yaml` with values like below, make sure properties reflect your database. If you wish to add additional properties like `url`, it should be fine to add here. You can also name it specific to your needs. Note that these will be referenced in a file called `deploymentconfig.yml` and that needs to reflect any name changes or additional properties.

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

To create the secret in OpenShift, execute the following

```
$oc create -f ./secret.yaml
```

Now setup is complete, on to main example.

## Example

* Make a clone of this project, and edit pom.xml with your name of the project.

```
git clone https://github.com/teiid/teiid-openshift-examples.git
cd rdbms-example
vi pom.xml
```

This example makes use of two maven plugins

1. spring-boot-maven-plugin which converts teiid library into a spring boot executable jar.
2. fabric8-maven-plugin, which helps to build a docker image based on that executable and optionally deploy into openShift.

### Java File Changes

The below are the code changes that are required to make it customizable for your environment.

* Edit `/src/main/java/com/example/DataSources.java` file, and add a @Bean method for each data source your VDB will need to access.  Note, the data source name MUST match with configuration property and bean name/method name. The example shown adds a data source for PostgreSQL database called "sampledb". Notice, that "sampledb" is same name used in your VDB's `SERVER` name and its `jndi-name` definition.
 
* `/src/main/java/com/example/Application.java` file is main spring boot application file, you can leave that as is, it is the main file that bootstraps the rest of the application.

### Virtual Database

This example requires the VDB to be supplied as DDL based text file. The `src/main/resource` folder contains this example's `customer-vdb.ddl`. If you are using your own virtual database replace that file with yours.

If your virtual database is not in the DDL form, but in .vdb or -vdb.xml format, then you can use the VDB Migration utility to convert into DDL form. For more information see [here](../README.md).

Make sure you have your VDB copied over to `src/main/resource` folder, and then edit `/src/main/resources/application.properties` set `teiid.vdb-file` property to your vdb name.  The default is set to the `customer-vdb.ddl` example vdb.

### Configuration

There are multiple files that define the configuration for this application. We will separate them by if they are static in nature from environment to environment like UA to PROD.

#### application.properties

This file is located at `/src/main/resource/application.properties`, can be used define any **application** properties that are static in nature. For example, we used to define `customer-vdb.ddl` file above. If you want you can define data source properties in here, but they can not be changed once application deployed to OpenShift.

#### deploymentconfig.yml

This file is located at`/src/main/fabric8/deploymentconfig.yml` can be used to define any application or OpenShift specific properties. The advantage is, the properties can be updated even after the application is deployed to OpenShift. For example you want to move the database from testing to production.

During the build of the image, the `fabric8-maven-plugin` uses this file to create the needed configuration to deploy image to OpenShift. Typically in Spring Boot application, the application looks for properties like below. The properties below are **specifically** to define a relational database. (If you are working with other types of sources like salesforce, google-sheets etc, then properties are entirely different, check the documentation for specific properties)

```
spring.datasource.sampledb.jdbc-url=jdbc:postgresql://localhost/sampledb	
spring.datasource.sampledb.username=user	
spring.datasource.sampledb.password=user	
spring.datasource.sampledb.driver-class-name=org.postgresql.Driver	
spring.datasource.sampledb.platform=sampledb
```

Now, you can define above properties in `deploymentconfig.yml` instead of `application.properties` by defining below

```
- name: SPRING_DATASOURCE_SAMPLEDB_JDBCURL
  value: jdbc:postgresql://localhost/sampledb
```
> NOTE: When defining a environment property, characters like `.` are not allowed, but you can replace them with character `_` and application will convert them automatically at runtime.

The same property, if you defined a value for `url` inside a `secret` can be rewritten as

```
- name: SPRING_DATASOURCE_SAMPLEDB_JDBCURL
  valueFrom:
     secretKeyRef:
       name: postgresql
       key: url
```
Where `name` defines the `secret` name you created, and then `key` defines the property inside the `secret`.

You may edit the `/src/main/fabric8/deploymentconfig.yml` file to provide ALL ENVIRONMENT properties to configure your data source(s). Note this example reads these properties from a `secret` called `postgresql` on OpenShift for database credentials.

### Database Schema/Sample Data (ONLY FOR TESTING, DANGER WILL OVERIDE DATA IN DATABASE)

When working with relational data sources you can supply "schema-xxxx.sql" and "data-xxxx.sql" files to define the DDL to initialize your schema and DML to pre-load data into the database. Note that `xxxx` denotes the data source name you choose in previous steps, and must match exactly. Typically you do not want to do this with production databases, so remove these files if you do not need to setup a database. They are used in this example strictly to ease the database setup.

NOTE: This only works for relational databases, not for any other sources.
 
### Drivers or Additional dependencies for your VDB 

Add any jdbc drivers, which are required by the data sources for the VDB that is being deployed, to the `pom.xml`. For example, to add the Postgresql JDBC driver, you would add in the following maven configuration within the `<dependencies>` section of the `pom.xml` file. 

```xml
<dependency>
  <groupId>org.postgresql</groupId>
  <artifactId>postgresql</artifactId>
  <version>${version.postgresql}</version>
</dependency>
```

Note, that all dependencies must be supplied as maven artifacts to build a successful docker image. In some cases like Oracle, there is no JDBC driver that is publicly available, in those situations you need to create a local maven repository with required configuration and deploy the driver there and use it in the above process.

### OpenShift Services to Expose 

To use JDBC or OData we need to create services and routes for it on OpenShift. Checkout files `jdbc-svc.yml`, `odata-svc.yml`, `odata-route.yml` in `src/main/fabric8` folder. Make changes to these to fit your needs, but mostly these don't need to be changed.


## Build Example

Execute following command to build and deploy a custom Teiid image to the OpenShift.

```bash
$mvn clean install -Popenshift -Dfabric8.namespace=`oc project -q`
```

Once the build is completed, go back to the OpenShift web-console application and make sure you do not have any errors with deployment. Now go to "Applications/Routes" and find the OData endpoint. Click on the endpoint and then issue requests like below using browser.

```bash
http://rdbms-example-odata-myproject.{ip}.nip.io/odata/portfolio/CustomerZip?$format=json

Response:
{
  "@odata.context": "http://rdbms-example-odata-myproject.192.168.99.100.nip.io/odata/portfolio/$metadata#CustomerZip",
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

```bash
discovery.3scale.net/scheme: "http"
discovery.3scale.net/port: "8080"
discovery.3scale.net/description-path: "/swagger.json" 
```

If the 3Scale system is defined to same cluster and namespace then your OData API is automatically discovered by 3Scale, where user can configure the API management features.  

### JDBC Connection

If you want to use JDBC to connect to your virtual databases. You can use 
this [JDBC Driver](https://oss.sonatype.org/service/local/repositories/releases/content/org/teiid/teiid/12.2.1/teiid-12.2.1-jdbc.jar). If you 
would like to use it in your application, use the maven dependency:

```
<dependency>
  <groupId>org.teiid</groupId>
  <artifactId>teiid</artifactId>
  <classifier>jdbc</classifier>
  <version>${version.teiid}</version>
</dependency>
```

To connect to the database, use the following:

URL: `jdbc:teiid:customer@mm://localhost:31000`

JDBC Class: `org.teiid.jdbc.TeiidDriver`

JDBC Driver: `teiid-12.2.1-jdbc.jar`

As this example don't use authentication, no credentials are needed.

### JDBC on Openshift

JDBC it is not exposed to outside applications by default (no route created). It is only suitable for applications in the cloud. 

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
