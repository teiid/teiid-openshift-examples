# Securing With Keycloak

This example is continuation of "rdbms-example", so if you have not gone through that project yet, the tasks in there should be completed first before going through this example.

The main aim in this example is to secure the Data Integration's OData API interface using the Keycloak. We will be used OpenID to authentication mechnism to secure the API. Note that in this example, the installation of Keycloak is done using a template file from Keycloak, however if you already have Keycloak environment set up in OPenShift then we suggest you use that instance. We only showing this step here for illustration purposes only.

## Install Keycloak

To install Keycloak on the same namespace as your project, execute the following `oc` commands. The first one installs a template, and second one instantiates a Keycloak instance with predefined username and password.

```
oc create --force -f "https://raw.githubusercontent.com/jboss-dockerfiles/keycloak/master/openshift-examples/keycloak-https.json"
oc process keycloak-https -p KEYCLOAK_USER=admin -p KEYCLOAK_PASSWORD=admin -p NAMESPACE=`oc project -q` | oc create -f -
```
Note: In future these above command will be replaced with an Operator and CRD.

Now, using log into the OpenShift console using your web browser and find out the route (URL) to your installed Keycloak server. My instance the URL is like

```
https://secure-keycloak-teiid-dataservice.192.168.99.100.nip.io/auth/
```

using your web browser log into the admin console of the Keycloak. This will take you the "master" realm. In this example, I will be using the "master" realm and will be creating a "client" for the Data Integration called "di". Click on the left side navigation on clients

![](images/keycloak1.png)

Click "create", to create a new client called "di" and select client protocol as "openid-connect" and save.

![](images/keycloak2.png)

Click "users", to create a new user and provide the name and details to create one. The screen shows creating user by the name "user" 

![](images/keycloak4.png)

Click "roles", to create a new role and create a role called "odata". This role will be used to validate user's access to the OData service. Repeat this step to add any other roles you want to give your user.

![](images/keycloak3.png)

Go back to the "users" panel, find the user you created in the previous step and grant him/her the role of "odata". Note, create any number of roles you need to manage your Data Integration's RBAC based access and assign them to the user. Mapping to LDAP/Active Directory based roles is beyond this example, however it is supported as federation through Keycloak. Refer to Keycloak's documentation.

For this example purpose create another role called `ReadOnly` and assign this to the `user`. Create another user called `developer` and assign the `odata` role but without `ReadOnly` role, so that you can verify functionality of Data Roles later in the example.

Note that the `odata` is to provide access to the OData API endpoint, where as `ReadOnly` is being used in the Data Roles for this application. If you want you could reuse single role for both.

![](images/keycloak5.png)

Using your OpenShift console in the Keycloak's project namespace, go to services menu option and find the "keycloak" service and its URL. Note that the service name may be different in your workspace as it depends on the name given during the Keycloak installation. This URL typically looks like (this service's URL, NOT route's, as this is going to be inter-cluster access without the https)

```
http://keycloak-teiid-dataservice.192.168.99.100.nip.io
```

## Changes to code to enable Keycloak based security on OData API

So far we have setup the Keycloak server in OpenShift and configured it for to be used with Data Integration. But before we can use KeyCloak based security on OData API, the example needs to be modified to make use of the Keycloak. For it make the below code changes.

#### pom.xml
The `pom.xml` needs to be added with additional dependencies for Keycloak, as described below

in the "dependencies" section add

```
<dependency>
  <groupId>org.teiid</groupId>
  <artifactId>spring-keycloak-odata</artifactId>
</dependency> 
```

this should replace previous dependency

```
<dependency>
  <groupId>org.teiid</groupId>
  <artifactId>spring-odata</artifactId>
</dependency> 
```

#### application.properties

The `src/main/resources/application.properties` needs to be added with following additional properties

```
keycloak.realm = master
keycloak.auth-server-url = http://keycloak-teiid-dataservice.192.168.99.100.nip.io/auth
keycloak.ssl-required = external
keycloak.resource = di
keycloak.public-client = true
```

Note that depending on your environment, the above properties may have different values, especially from environment to environment and how you setup your Keycloak server.

#### deploymentconfig.yml

The `src/main/fabric8/deploymentconfig.yml` needs to be added with ENVIRONMENT variables that may be different in different deployments. If you are deploying application in DEV and PROD environments, you need a mechanism to switch the configuration.

Especially the property `keycloak.auth-server-url`. Add the following to configure a configmap then use that in your deployment

```
oc create configmap my-config --from-literal=keycloak.auth-server-url=http://keycloak-teiid-dataservice.192.168.99.100.nip.io/auth
```

Above creates a config map called `my-config` in OpenShift, that can be referenced from your deployment config as shown below. Between DEV and PROD make sure the name of the config map stays same but the contents will vary. Note there are many ways to create config maps, the above is a simple example.

Then in the `src/main/fabric8/deploymentconfig.yml` add

```
- name: KEYCLOAK_AUTHSERVERURL
  valueFrom:
     configMapKeyRef:
       name: <config-name>
       key: keycloak.auth-server-url
```
Note that if you used different realm or client by the environment you would have to adjust all those properties using the deploymentconfig.yml file.

## customer-vdb.ddl

The previous example's virtual database does not define any Data Roles. Add these following two lines to the .DDL file at `src/main/resources/customer-vdb.ddl`

```
CREATE ROLE ReadOnly WITH JAAS ROLE ReadOnly;
GRANT SELECT ON TABLE "accounts.customer" TO ReadOnly
```

In the above, the first line is creating role called "ReadOnly" and mapping to the role we created earlier in Keycloak's role with same name of "ReadOnly". They can be different, but here for simplicity the same name is used. The second line gives the SELECT permissions to the `accounts.customer` table to the user with "ReadOnly" permissions.

## Build Example

Execute following command to build and deploy a custom Teiid image to the OpenShift.

```
$ mvn clean install -Popenshift
```

## Post Deployment

Now you should see that the image you deployed into the OpenShift is active and running. It has an OData route to it. Before we proceed, we need to add a "Valid Redirect URIs" for the client we created. In this example it is "di", so click on "clients", select "di" client and provide the "Valid Redirect URIs" field as your OData services root URL appended with "*", for example:

```
http://keycloak-dv-example-odata-teiid-dataservice.192.168.99.100.nip.io/*
```

Click "Save", for saving the profile. Note this example used Keycloak template that does not persist configuration changes over the pod restarts. In real world examples, you want to switch the "h2" database into "postgresql" database with persistent volumes for the Keycloak template such that the configuration survives the pod restarts.

##  Testing

Now using the browser you can issue an OData API call such as

```
http://keycloak-rdbms-example-odata-teiid-dataservice.192.168.99.100.nip.io/customer
```

You will presented with a login page, where you use the user credentials you created in previous steps and access the service. If you use `user` as user name when you login you will be granted to view the data of the customer view. If you used `developer` as the user name the permission to view the customer data is not granted, as the `developer` user does not have the `ReadOnly` role. 

Note that urls like `/$metadata` are specifically excluded from security such that they can be discovered by other services.
