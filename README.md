# GridVis Service Docker Container

## Persistent Data
GridVis needs to store configuration files and project files. There are several ways to manage persistent data while using docker.
We recommend using two docker volumes. Thus, most examples contain the following components:
```
  volumes:
  	- ./GridVisProjects:/opt/GridVisProjects
  	- ./GridVisData:/opt/GridVisData
```

If you combine the gridvis docker with a **database** docker, the same extends to the data of this database.

**Further Information:**
[https://docs.docker.com/storage/](https://docs.docker.com/storage/)

## Examples
You can find different usage examples in our [example repository](examples).

## Maintenance Mode
This image now supports an automatic project maintenance mode. To find out more head over to our [Maintenance Documentation](maintenance)
