# Monitoring with Prometheus

This example is continuation of "rdbms-example", so if you have not gone through that project yet, the tasks in there should be completed first before going through this example.

The main aim in this example is to expose the Data Integration metrics that you deployed in the previous project using Prometheus. Note that in this example, he installation of Prometheus is done using a template file `prometheus.yml`, however if you already have Syndesis environment set up Prometheus is already installed for you. Also, there is Prometheus Operator avilable but in this example not going to be using it. Hopefully very near future this example will be updated to use Prometheus Operator for install.

## Install
To install Prometheus, make sure you have a running OpenShift environment and logged into using

```
$oc login
```

make sure that the project(namespace) you are currently logged into is the same one that previous `rdbmd-example` is deployed into. You can check that by issuing command 

```
oc project
```

Now, let's install the Prometheus template into your namespace and create a instance of it

```
oc create -f prometheus.yml
oc process prometheus -p OPENSHIFT_PROJECT=`oc project -q` | oc create -f -
```

At this time, if you log into your OpenShift console, you should see the Prometheus installed in the same namespace as your project.

Grafana dashboard integration is upcoming as an extension to this example, until then you can create route to Prometheus service and see some simple graphs. To do that, go to services page, find `prometheus` service and client `create route` and access the console using the url provided.
