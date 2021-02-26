FROM python:3.8.6-slim-buster

ARG VERSION
ARG BUILD_DATE
ARG VCS_REF

ENV VERSION ${VERSION:-main}

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/sgabe/docker-scirius.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="1.0.0-rc1"

COPY scirius/ /tmp/scirius

RUN \
    echo "**** install packages ****" && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        make \
        curl \
        wget \
        git \
        gcc \
        libc-dev \
        gunicorn \
        python-sphinx \
        gnupg2 && \
    echo "**** add NodeSource repository ****" && \
    wget -O- https://deb.nodesource.com/setup_12.x | bash - && \
    echo "**** install Node.js ****" && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        nodejs && \
    echo "**** download Scirius ****" && \
    wget -O /tmp/scirius-${VERSION}.tar.gz https://codeload.github.com/sgabe/scirius/tar.gz/${VERSION} && \
    tar zxf /tmp/scirius-${VERSION}.tar.gz -C /tmp && \
    mv /tmp/scirius-${VERSION} /opt/scirius && \
    echo "**** download Kibana dashboards ****" && \
    git clone https://github.com/StamusNetworks/KTS6.git /opt/kibana-dashboards/ && \
    echo "**** install Python dependencies for Scirius ****" && \
    cd /opt/scirius && \
    python -m pip install --upgrade \
        pip \
        wheel \
        setuptools && \
    python -m pip install --upgrade \
        six \
        python-daemon \
        suricatactl && \
    python -m pip install \
        django-bootstrap3==11.1.0 \
        elasticsearch-curator==5.6 && \
    python -m pip install -r requirements.txt && \
    echo "**** install Node.js dependencies for Scirius ****" && \
    npm install -g \
        npm \
        webpack && \
    npm install \
        node-sass \
        node-gyp && \
    npm install && \
    echo "**** install Node.js dependencies for Hunt ****" && \
    cd /opt/scirius/hunt && \
    npm install && \
    npm run build && \
    echo "**** install util scripts ****" && \
    cp -Rf /tmp/scirius/* /opt/scirius && \
    chmod ugo+x /opt/scirius/bin/* && \
    echo "**** build docs ****" && \
    cd /opt/scirius/doc && \
    make html && \
    echo "**** cleanup ****" && \
    apt-get purge -y --auto-remove gcc libc-dev make python-sphinx && \
    apt-get clean && \
    rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/tmp/*

WORKDIR /opt/scirius

HEALTHCHECK --start-period=3m \
  CMD curl --silent --fail http://127.0.0.1:8000 || exit 1

VOLUME /rules /data /static /logs

EXPOSE 8000

ENTRYPOINT ["/opt/scirius/bin/scirius.sh"]
