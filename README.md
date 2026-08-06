# GridVis Service Docker Container

## Admin password

The GridVis admin password is initialized once for each persistent `/opt/GridVisData` volume. On the first start, the container uses the first applicable source in this order:

1. `GRIDVIS_ADMIN_PASSWORD_FILE`: read the password from the first line of this file. This is the recommended option for Docker Secrets.
2. `GRIDVIS_ADMIN_PASSWORD`: use the value of this environment variable.
3. If neither setting is present, generate a cryptographically secure random password.

An empty variable, an empty or unreadable password file, or a missing file is an error. Passwords must satisfy the GridVis policy: 8–20 characters with upper- and lower-case letters, a digit, a special character, and no whitespace. Passwords supplied through a variable or file are never written to the container logs. A generated password is printed once after initialization succeeds, so save it from the first-start logs and change it after your first login.

After successful initialization, the container creates:

```text
/opt/GridVisData/.admin-password-initialized
```

As long as this marker remains in the persistent volume, later starts skip password initialization and start GridVis normally. Before GridVis starts, the entrypoint uses the Groovy runtime already contained in GridVis to write the encrypted fallback password to `/opt/GridVisData/config/server.conf`. The password is passed to Groovy through standard input, not as a command-line argument. The marker and generated-password log are produced only after this succeeds.

No installer is stored in the runtime image or downloaded during container startup. The Docker build still uses the installer to create the GridVis installation, with an internally generated temporary password which is neither logged nor retained as a build argument.

Existing volumes without the marker are initialized as well. This method configures GridVis' service fallback realm in `server.conf`; an independently configured user database is not changed and must be rotated using GridVis' REST API or its administration UI. To retain the password of an existing installation instead, set `GRIDVIS_INITIALIZE_ADMIN_PASSWORD=false`; no marker is created, so removing that setting later enables initialization. Do not disable initialization for a new volume because the temporary build-time password is intentionally not exposed.

### Local test image

`Dockerfile.local` builds a test image from the published GridVis runtime. It avoids downloading or storing a GridVis installer during the local Docker build:

```bash
docker buildx build --load -f Dockerfile.local \
  -t gridvis-service:admin-password-local \
  .
```

No local GridVis build or code modification is required.

### Docker Compose

Provide the password through the deployment environment rather than committing it to the Compose file:

```yaml
services:
  gridvis:
    image: jnza/gridvis-service:nightly
    environment:
      GRIDVIS_ADMIN_PASSWORD: ${GRIDVIS_ADMIN_PASSWORD:?set GRIDVIS_ADMIN_PASSWORD}
    volumes:
      - ./GridVisProjects:/opt/GridVisProjects
      - ./GridVisData:/opt/GridVisData
    ports:
      - "8080:8080"
```

### Docker Secrets

```yaml
services:
  gridvis:
    image: jnza/gridvis-service:nightly
    environment:
      GRIDVIS_ADMIN_PASSWORD_FILE: /run/secrets/gridvis_admin_password
    secrets:
      - gridvis_admin_password
    volumes:
      - ./GridVisProjects:/opt/GridVisProjects
      - ./GridVisData:/opt/GridVisData

secrets:
  gridvis_admin_password:
    file: ./secrets/gridvis_admin_password.txt
```

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
