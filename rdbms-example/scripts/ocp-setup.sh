#CREATE PROJECT IN OPENSHIFT
oc new-project myproject

# DEPLOY POSTGRES DATABASE
oc new-app \
  -e POSTGRESQL_USER=user \
  -e POSTGRESQL_PASSWORD=mypassword \
  -e POSTGRESQL_DATABASE=sampledb \
  postgresql:9.5

# CREATE SECRET TO CONNECT TO DATABASE (ADJUST TO YOUR VALUES)
oc create -f secret.yaml

# DEPLOY APPLICATION 
# cd rdbms-example
# mvn clean install -Popenshift -Dfabric8.namespace=`oc project -q`
