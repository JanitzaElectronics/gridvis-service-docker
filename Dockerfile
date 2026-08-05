FROM --platform=$BUILDPLATFORM debian:13.4-slim AS builder

ENV HOME=/root
ARG VERSION=9.2.101

COPY response.varfile /response.varfile
RUN useradd -r gridvis -u 101 \
 && apt-get update \
 && apt-get install -y --no-install-recommends openjdk-25-jre fontconfig fonts-freefont-ttf wget gzip bash \
 && rm -rf /var/lib/apt/lists/*

# Locate the Java directory and create a link to it in the path expected by the silent installer so that JxBrowser can be extracted.
RUN JAVA_BIN="$(readlink -f "$(command -v java)")" \
 && JAVA_HOME="$(dirname "$(dirname "$JAVA_BIN")")" \
 && mkdir -p /usr/local/GridVis \
 && ln -s "$JAVA_HOME" /usr/local/GridVis/jre

RUN echo Fetching https://gridvis.janitza.de/download/${VERSION}/GridVis-Installer-${VERSION}-unix.sh
RUN wget -q -O installer.sh https://gridvis.janitza.de/download/${VERSION}/GridVis-Installer-${VERSION}-unix.sh
RUN TEMP_ADMIN_PASSWORD="Aa1!$(head -c 12 /dev/urandom | base64)" \
 && if [ "${#TEMP_ADMIN_PASSWORD}" -ne 20 ]; then \
      echo "Could not generate temporary GridVis admin password during image build" >&2; \
      exit 1; \
    fi \
 && if ! sh installer.sh -q -varfile /response.varfile -VserviceAdminPassword="$TEMP_ADMIN_PASSWORD" >/dev/null 2>&1; then \
      echo "GridVis installer failed during image build" >&2; \
      exit 1; \
    fi

FROM debian:13.4-slim
RUN useradd -r gridvis -u 101 \
 && apt-get update \
 && apt-get install -y --no-install-recommends openjdk-25-jre fontconfig fonts-freefont-ttf xvfb libgtk-3-0t64 libxss1 libgbm1 util-linux \
 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/GridVis /usr/local/GridVis

RUN mkdir /opt/GridVisData \
 && chown gridvis -R /opt/GridVisData \
 && chown gridvis -R /usr/local/GridVis/GridVis\ Service/etc \
 && sed -i -e "/jdkhome/d" /usr/local/GridVis/GridVis\ Service/etc/server.conf \
 && mkdir /home/gridvis \
 && chown gridvis:gridvis /home/gridvis

ENV USER_TIMEZONE=UTC
ENV USER_LANG=en
ENV FEATURE_TOGGLES=NONE
ENV LANG=C.UTF-8
ENV SERVICE_PARAMS=NONE
ENV MAX_RAM_SIZE_MB=1024

VOLUME ["/opt/GridVisData", "/opt/GridVisProjects"]
COPY gridvis-service.sh /gridvis-service.sh
COPY write-admin-password.groovy /usr/local/lib/gridvis/write-admin-password.groovy
RUN chmod 0755 /gridvis-service.sh

EXPOSE 8080

CMD ["/gridvis-service.sh"]
