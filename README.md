GridVis Service Docker Container
======================
Minimal example for GridVis behind a TLS terminating reverse proxy using traefik:
```yaml
version: "3.9"

services:
  traefik:
    image: "traefik:v2.8"
    command:
        - "--providers.docker=true"
        - "--providers.docker.exposedbydefault=false"
        - "--entrypoints.web.address=:80"
        - "--entrypoints.websecure.address=:443"
        - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
        - "--certificatesresolvers.myresolver.acme.email=example@email.com"
        - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./letsencrypt:/letsencrypt"
  gridvis:
    image: jnza/gridvis-service:nightly #Dragons ahead! nightly is at the moment the only version supporting reverseproxy
    shm_size: "1gb" # Required to produce the PDF files in the background

    environment:
      - FEATURE_TOGGLES=de.pasw.jetty.reverseproxy
    labels:
        - "traefik.enable=true"
        - "traefik.http.routers.whoami.rule=Host(`gridvis.example.com`)"
        - "traefik.http.routers.whoami.entrypoints=web,websecure"
        - "traefik.http.routers.whoami.tls.certresolver=myresolver"
    volumes:
      - ./GridVisData:/opt/GridVisData
      - ./GridVisProject:/opt/GridVisProjects
```
Be careful to replace all *example.com parts with your own data.
At the moment it is not possible to use a different URI. You can not redirect GridVis to serve as `https://ssl.example.com/gridvis`