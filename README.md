# Data Virtualization (Teiid) OpenShift Examples - Fuse 7.4 (Q3-19)

This repository contains example projects, designed to be deployed on OpenShift using Teiid Spring Booot, and the VDB Migration Utility.


## Available Examples and Utility
| Example Name  | Description   | Prerequisite  |
| ------------- |:-------------:| :-----|
|[rdbms-example](rdbms-example) |Shows how to deploy a single source VDB into OpenShift  |None |
|[prometheus](prometheus) |Provides a template for installing a Prometheus instance for use with Teiid  |rdbms-example |
|[keycloak](keycloak)     |Provides a example for securing the Data Integration's OData API Interface   |rdbms-example |


## Run the Examples

To run the examples, first read the README.md located within the example directory. These examples require you to have a valid DDL based VDB. Please look below for converting your .vdb or -vdb.xml file into DDL format. Otherwise, head on over to the rdbms-example.


## Run the VDB Migration Utility

### VDB Migration Utility

This VDB Migration Utility is used to convert a VDB (xml format) file to DDL.   If you have a .vdb file, first use Teiid Designer to export the .vdb to an .xml formatted file.

There are two options to running this utility.  The first option is to run the utility, to report any validation errors, by providing only the path to the vdb file to convert.  The second option will also perform the validation reportiing, but will write the converted vdb (assuming no validation errors) to a .ddl file.  This can be executed by providing the second output argument. 


#### Convert VDB

To perform the task of converting a vdb and reporting validation errors, do the following:

Open a terminal and navigate to the teiid-openshift-examples directory.

```
$mvn -s settings.xml exec:java -Dvdb={filepath/to/vdb}
```
This will perform the vdb conversion, reporting any validation errors to the terminal.  If there are no validation errors, the ddl form of the vdb will be written to the terminal.


#### Convert VDB and Write to File

To perform the task of converting a vdb, report validation errors, and writing the result to a file, do the following:

Open a terminal and navigate to the teiid-openshift-examples directory.

```
$mvn -s settings.xml exec:java -Dvdb={filepath/to/vdb} -Doutput={filepath/to/convertedvdb}
```
This will perform the vdb conversion and will write a valid vdb to the specified output file.  The output file will only be written if there are no validation errors.




## Links

* [Teiid OpenShift Examples Repository](https://github.com/teiid/teiid-openshift-examples)
