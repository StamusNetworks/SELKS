FROM debian:bullseye

# Declare args
ARG ARKIME_VERSION=3.2.1
ARG UBUNTU_VERSION=20.04
ARG ARKIME_DEB_PACKAGE="arkime_"$ARKIME_VERSION"-1_amd64.deb"

# Declare envs vars for each arg
ENV ARKIME_VERSION $ARKIME_VERSION
ENV ES_HOST "elasticsearch"
ENV ES_PORT 9200
ENV ARKIME_ADMIN_USERNAME "selks-user"
ENV ARKIME_ADMIN_PASSWORD "selks-user"
ENV ARKIME_HOSTNAME "arkime"
ENV ARKIMEDIR "/opt/arkime"

# Add entrypoint
COPY start-arkimeviewer.sh /start-arkimeviewer.sh

# Install Arkime
RUN apt-get update && \
    apt-get install -y curl libmagic-dev wget logrotate && \
    mkdir -p /data && \
    mkdir -p /suricata-logs && \
    cd /data && \
    wget -q "https://s3.amazonaws.com/files.molo.ch/builds/ubuntu-"$UBUNTU_VERSION"/"$ARKIME_DEB_PACKAGE && \
    apt-get install -y ${PWD}/$ARKIME_DEB_PACKAGE && \
    mv $ARKIMEDIR/etc /data/config && \
    ln -s /data/config $ARKIMEDIR/etc && \
    ln -s /data/logs $ARKIMEDIR/logs && \
    ln -s /data/pcap $ARKIMEDIR/raw && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/* && \
    rm /data/$ARKIME_DEB_PACKAGE && \
    $ARKIMEDIR/bin/arkime_update_geo.sh && \
    chmod 755 /start-arkimeviewer.sh && \
    mkdir -p /readpcap

# add config
COPY arkimepcapread-selks-config.ini /data/config/config.ini

VOLUME ["/data/pcap", "/data/config", "/data/logs"]
EXPOSE 8005
WORKDIR $ARKIMEDIR

ENTRYPOINT ["/start-arkimeviewer.sh"]