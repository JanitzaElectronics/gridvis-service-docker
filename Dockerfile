FROM --platform=$BUILDPLATFORM ubuntu:20.04 AS builder

ENV HOME /root
ARG VERSION=8.0.101

COPY response.varfile /response.varfile
RUN useradd -r gridvis -u 101 && apt update && apt -y install openjdk-11-jre fontconfig ttf-ubuntu-font-family wget gzip bash
RUN echo Fetching https://gridvis.janitza.de/download/${VERSION}/GridVis-Service-${VERSION}-unix.sh
RUN wget -q -O service.sh https://gridvis.janitza.de/download/${VERSION}/GridVis-Service-${VERSION}-unix.sh
RUN sh service.sh -q -varfile /response.varfile \
RUN sed -i 's#default_userdir.*$#default_userdir=/opt/GridVisData#' /usr/local/GridVisService/etc/server.conf

FROM ubuntu:20.04
RUN useradd -r gridvis -u 101 && apt update && apt -y install --no-install-recommends openjdk-11-jre fontconfig ttf-ubuntu-font-family xvfb libgtk-3-0 libxss1 libgbm1 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/GridVisService /usr/local/GridVisService

RUN mkdir /opt/GridVisData \
 && chown gridvis -R /opt/GridVisData \
 && ln -s /opt/GridVisData/license2.lic /usr/local/GridVisService/license2.lic \
 && ln -s /opt/GridVisData/security.properties /opt/security.properties \
 && mkdir /home/gridvis \
 && chown gridvis:gridvis /home/gridvis

ENV USER_TIMEZONE UTC
ENV USER_LANG en
ENV FEATURE_TOGGLES NONE
ENV LANG=en_US.UTF-8
ENV SERVICE_PARAMS NONE
ENV MAX_RAM_SIZE_MB 1024

VOLUME ["/opt/GridVisData", "/opt/GridVisProjects"]
COPY gridvis-service.sh /gridvis-service.sh

EXPOSE 8080

USER gridvis
CMD ["/gridvis-service.sh"]
