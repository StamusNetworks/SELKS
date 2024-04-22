

FROM debian:bullseye as installer

# Declare args
ARG ARKIME_VERSION=5.0.0
ARG UBUNTU_VERSION=20.04
ARG ARKIME_DEB_PACKAGE="arkime_"$ARKIME_VERSION"-1_amd64.deb"
ARG ARKIMEDIR "/opt/arkime"

ENV ARKIME_VERSION $ARKIME_VERSION
ENV UBUNTU_VERSION $UBUNTU_VERSION
ENV ARKIME_DEB_PACKAGE $ARKIME_DEB_PACKAGE
ENV ARKIMEDIR "/opt/arkime"


# Install Arkime
RUN apt-get update && apt-get install -y curl libmagic-dev wget logrotate
RUN mkdir -p /data /suricata-logs

WORKDIR /data
RUN wget -q "https://s3.amazonaws.com/files.molo.ch/builds/ubuntu-"$UBUNTU_VERSION"/"$ARKIME_DEB_PACKAGE
RUN apt-get install -y ./$ARKIME_DEB_PACKAGE


# add config

FROM debian:bookworm-slim as runner

# Declare args

ENV ES_HOST "elasticsearch"
ENV ES_PORT 9200
ENV ARKIME_ADMIN_USERNAME "selks-user"
ENV ARKIME_ADMIN_PASSWORD "selks-user"
ENV ARKIME_HOSTNAME "arkime"
ENV ARKIMEDIR "/opt/arkime"

COPY --from=installer $ARKIMEDIR $ARKIMEDIR

RUN $ARKIMEDIR/bin/arkime_update_geo.sh

COPY start-arkimeviewer.sh /start-arkimeviewer.sh
COPY arkimepcapread-selks-config.ini /opt/arkime/etc/config.ini

RUN chmod 755 /start-arkimeviewer.sh && \
    mkdir -p /readpcap

EXPOSE 8005
WORKDIR $ARKIMEDIR

ENTRYPOINT [ "bash", "-c" ]
CMD ["/start-arkimeviewer.sh"]
