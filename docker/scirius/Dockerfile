FROM python:3.8.6-slim-buster

ARG VERSION
ARG BUILD_DATE
ARG VCS_REF

ENV VERSION ${VERSION:-master}

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/StamusNetworks/SELKS.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="1.0.0-rc1"

RUN \
    echo "**** install packages ****" && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        apt-utils && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        make \
        curl \
        wget \
        git \
        gcc \
        libc-dev \
        gunicorn \
        python-sphinx \
        gnupg2 \
        libsasl2-dev \
        libldap2-dev \
        libssl-dev \
        python-pip \
        python-dev \
        suricata
        
RUN \
    echo "**** add NodeSource repository ****" && \
    wget -O- https://deb.nodesource.com/setup_12.x | bash -
    
RUN \
    echo "**** install Node.js ****" && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        nodejs

RUN \
    echo "**** download Scirius ****" && \
    wget -O /tmp/scirius-${VERSION}.tar.gz https://codeload.github.com/StamusNetworks/scirius/tar.gz/${VERSION} && \
    tar zxf /tmp/scirius-${VERSION}.tar.gz -C /tmp && \
    mv /tmp/scirius-${VERSION} /opt/scirius
    
WORKDIR /opt/scirius
    
RUN \
    echo "**** download Kibana dashboards ****" && \
    git clone https://github.com/StamusNetworks/KTS6.git /opt/kibana6-dashboards/ &&\
    git clone https://github.com/StamusNetworks/KTS7.git /opt/kibana7-dashboards/
    

RUN \
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
        elasticsearch-curator==5.6 \
        django-webpack-loader==0.7 \
        pyinotify && \
    python -m pip install -r requirements.txt  
    
RUN echo "**** install Node.js dependencies for Scirius ****" && \
    npm install && \
    npm install -g webpack@3.11 && \
    webpack && \
    cd hunt && \
    npm install && \
    npm run build

COPY scirius/ /tmp/scirius

RUN \
    echo "**** install util scripts ****" && \
    cp -Rf /tmp/scirius/* /opt/scirius && \
    chmod ugo+x /opt/scirius/bin/*

RUN \
    echo "**** build docs ****" && \
    cd /opt/scirius/doc && \
    make html
    
RUN \
    echo "**** cleanup ****" && \
    apt-get purge -y --auto-remove gcc libc-dev make python-sphinx && \
    apt-get clean && \
    rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/tmp/*

HEALTHCHECK --start-period=3m \
  CMD curl --silent --fail http://127.0.0.1:8000 || exit 1

VOLUME /rules /data /static /logs

EXPOSE 8000

ENTRYPOINT ["/opt/scirius/bin/start-scirius.sh"]
