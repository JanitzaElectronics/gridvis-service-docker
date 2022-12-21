# Maintenance Mode
The maintenance mode of this docker image provides an easy start into GridVis.
Core features of the maintenance mode:
* Automatically create a new project and set up the database
* Automatically perform all necessary database migration
* Import devices from a CSV file into the project
  Presently, the maintenance mode only supports on project per GridVis Service.

## Setup
### General setup
To make use of the maintenance mode, just use a docker image with a `-m`suffix. If you do not specify any environment variables, a JanDB project with project name "default" will be created.

| Environment variable | Description | Default |
|------|------|--------|
| PROJECT_NAME | Defines the name of the project. This is used during creation of  the project and cannot be changes afterwards. If you change this variable, a new project will be created. | `default` |
| DB_TYPE | Specifies the database to use for the project. Possible values are: `jandb`,  `mariadb` and `mssql`.| `jandb` |
### JanDB
For a JanDB project, no further configuration is required.

For the easiest setup, you can have a look at our [example](../examples) collection.
### MariaDB
You need to set `DB_TYPE` to `mariadb`. For more information how to set up a database, please visit the documentation of the database supplier.

| Environment variable | Description | Default |
|------|------|--------|
| DB_HOST| The host to connect to. In a `docker-compose` environment, the name of the service. |`database`|
|DB_PORT| The port to connect to. |`3306`|
|DB_USER| The user in use to connect to the database. |`root`|
|DB_PASSWORD| The password used to connect to the database. |`rootPWD`|
|DB_DATABASE| The database to use on the database server. This is independent of the name of the project. |`GridVis`|

For the easiest setup, you can have a look at our [example](../examples) collection.

###  Microsoft SQL Server
You need to set `DB_TYPE` to `mssql`. For more information how to set up a database, please visit the documentation of the database supplier.

| Environment variable | Description | Default |
|------|------|--------|
| DB_HOST| The host to connect to. In a `docker-compose` environment, the name of the service. |`database`|
|DB_PORT| The port to connect to. |`1433`|
|DB_USER| The user in use to connect to the database. |`sa`|
|DB_PASSWORD| The password used to connect to the database. |`saPWD`|
|DB_DATABASE| The database to use on the database server. This is independent of the name of the project. |`GridVis`|

For the easiest setup, you can have a look at our [example](../examples) collection.

## Automatic device import
You can add a file `devices.csv`into the GridVis Data directory, and GridVis will import the devices specified once per minute. 
Devices already imported will be skipped. This way you can add new devices to the CSV file and only the new devices will be created.