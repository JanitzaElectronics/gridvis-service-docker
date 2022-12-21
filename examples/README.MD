# Examples
## SSL example
### Reverse proxy
To use GridVis service behind a ssl terminating reverse proxy checkout this example: [docker-compose.yaml](compose-traefik-ssl)

Be careful to replace all *example.com parts with your own data.
At the moment it is not possible to use a different URI. You can not redirect GridVis to serve as `https://ssl.example.com/gridvis`
## Maintenance mode
Here are some usage examples of our integrated maintenance mode. 
All images with maintenance mode support end with `-m` for example `jnza/gridvis-service:nightly-m`.
When using these examples please make sure you understand and respect the EULAs of all suppliers.
* Easy start with our integrated JanDB: [docker-compose.yaml](compose-jandb-maintenance)
* Easy start with MariaDB: [docker-compose.yaml](compose-mariadb-maintenance)
* Easy start with Microsoft SQL Server: [docker-compose.yaml](compose-mssql-maintenance)