FROM --platform=$BUILDPLATFORM ubuntu:18.04 AS build

ENV HOME /root
ENV VERSION 7.4.63

COPY response.varfile /response.varfile

RUN apt-get update && apt-get install -y openjdk-8-jre ttf-ubuntu-font-family wget gzip bash && rm -rf /var/lib/apt/lists/*
RUN wget -q -O hub.sh http://gridvis.janitza.de/download/${VERSION}/GridVis-Hub-${VERSION}-unix.sh \
    && sh hub.sh -q -varfile /response.varfile \
    && echo "Installer finished" \
    && rm hub.sh

FROM ubuntu:18.04

RUN useradd -r gridvis -u 101 && apt-get update && apt-get install -y openjdk-8-jre ttf-ubuntu-font-family && rm -rf /var/lib/apt/lists/*
COPY --from=build /usr/local/GridVisHub /usr/local/GridVisHub

RUN mkdir -p /opt/GridVisHubData \
    && mkdir -p /opt/GridVisProjects \
    && ln -s /opt/GridVisHubData/security.properties /opt/security.properties \
    && sed -i 's#default_userdir.*$#default_userdir=/opt/GridVisHubData#' /usr/local/GridVisHub/etc/hub.conf \
    && chown gridvis:gridvis /opt/GridVisHubData /opt/GridVisProjects /usr/local/GridVisHub/etc/hub.conf

ENV USER_TIMEZONE UTC
ENV USER_LANG en
ENV FEATURE_TOGGLES NONE
ENV LANG=en_US.UTF-8
ENV HUB_PARAMS NONE
ENV MAX_RAM_SIZE_MB 512

VOLUME ["/opt/GridVisHubData", "/opt/GridVisProjects"]
COPY gridvis-hub.sh /gridvis-hub.sh

EXPOSE 8080

USER gridvis
CMD ["/gridvis-hub.sh"]

