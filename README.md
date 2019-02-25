# Teiid OpenShift Examples

This repository contains example projects, designed to be deployed on OpenShift using Teiid Spring Booot, and the VDB Migration Utility.


## Available Examples and Utility
| Example Name  | Description   | Prerequisite  |
| ------------- |:-------------:| :-----|
|[rdbms-example](rdbms-example) |Shows how to deploy a single source VDB into OpenShift  |None |
|[prometheus](prometheus) |Provides a template for installing a Prometheus instance for use with Teiid  |rdbms-example |


## Run the Examples

To run the examples, first read the README.md located within the example directory. These examples reqiure you to have valid DDL based VDB. Please look below for converting your .vdb or -vdb.xml file into DDL format. Otherwise, head on over to the rdbms-example.


## Run the VDB Migration Utility

### VDB Migration Utility

This VDB Migration Utility is used to convert a VDB (xml format) file to DDL.   If you have a .vdb file, first use Teiid Designer to export the .vdb to an .xml formatted file.

There are two options to running this utility.  The first option is to run the utility to report an validation errors, providing only the path to the vdb file to convert.  The second option will also perform the validation reportiing, but will write the converted vdb (assuming no validation errors) to a .ddl file.  This can be executed by providing the second output argument. 


#### Convert VDB

To perform the task of converting a vdb and report validation errors, do the following:

Open a terminal and navigate to the vdb-migration directory.

```
$mvn exec:java -Dvdb={filepath/to/vdb}
```
This will perform the vdb conversion, reporting any validation errors to the terminal.


#### Convert VDB and Write to File

To perform the task of converting a vdb, report validation errors, and writing the result to a file, do the following:

```
$mvn exec:java -Dvdb={filepath/to/vdb} -Doutput={filepath/to/convertedvdb}
```
This will perform the vdb conversion and will a valid vdb to the specified output file.  The output file will only be written if there are no validation errors.




## Links

* [Teiid OpenShift Examples Repository](https://github.com/teiid/teiid-openshift-examples)





