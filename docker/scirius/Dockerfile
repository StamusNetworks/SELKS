# Copyright(C) 2021, Stamus Networks and Gabor Seljan
# Written by Raphaël Brogat <rbrogat@stamus-networks.com> based on Gabor Seljan work
#
# This file comes with ABSOLUTELY NO WARRANTY!
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#Download STEP
FROM python:3.8.6-slim-buster as download
ARG VERSION
ENV VERSION ${VERSION:-master}

RUN \
    echo "**** install packages ****" && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        apt-utils \
        wget
RUN \
  echo "**** download Kibana dashboards ****" && \
  wget --no-check-certificate --content-disposition -O /tmp/kibana7-dashboards.tar.gz https://github.com/StamusNetworks/KTS7/tarball/master && \
  mkdir /tmp/kibana7-dashboards && \
  tar zxf /tmp/kibana7-dashboards.tar.gz -C /tmp/kibana7-dashboards --strip-components 1 && \
  mv /tmp/kibana7-dashboards /opt/kibana7-dashboards
RUN \
    echo "**** download Scirius ****" && \
    wget --no-check-certificate --content-disposition -O /tmp/scirius.tar.gz https://github.com/StamusNetworks/scirius/tarball/${VERSION} && \
    mkdir /tmp/scirius && \
    tar zxf /tmp/scirius.tar.gz -C /tmp/scirius --strip-components 1 && \
    mv /tmp/scirius /opt/scirius

    

# BUILD JS stuff
FROM python:3.8.6-slim-buster as static

RUN \
    echo "**** install packages ****" && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        apt-utils && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        make \
        wget \
        gcc \
        libc-dev
        
RUN \
    echo "**** add NodeSource repository ****" && \
    wget -O- https://deb.nodesource.com/setup_12.x | bash -
    
RUN \
    echo "**** install Node.js ****" && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        nodejs

COPY --from=download /opt/scirius /opt/scirius
WORKDIR /opt/scirius

RUN echo "**** install Node.js dependencies for Scirius ****" && \
    npm install && \
    npm install -g webpack@3.11 && \
    webpack && \
    cd hunt && \
    npm install && \
    npm run build
    
    
#BUILD doc 
FROM python:3.8.6-slim-buster as docs

RUN \
    echo "**** install packages ****" && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        apt-utils && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        make \
        gcc \
        libc-dev \
        python-sphinx
        

COPY --from=download /opt/scirius /opt/scirius
RUN \
    echo "**** build docs ****" && \
    cd /opt/scirius/doc && \
    make html


#

# PACKAGING STEP
FROM python:3.8.6-slim-buster

ARG BUILD_DATE
ARG VCS_REF

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
    curl \
    gunicorn \
    git \
    gnupg2 \
    gcc \
    libc-dev \
    libsasl2-dev \
    libldap2-dev \
    libssl-dev \
    python-pip \
    python-dev \
    suricata && \
  rm -rf /var/lib/apt/lists/*
    
COPY --from=download /opt/scirius /opt/scirius

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
    django-webpack-loader==0.7 \
    pyinotify && \
  python -m pip install -r requirements.txt  

COPY --from=static /opt/scirius/rules/static /opt/scirius/rules/static
COPY --from=docs /opt/scirius/doc/_build/html /static/doc
COPY --from=download /opt/kibana7-dashboards /opt/kibana7-dashboards

COPY scirius/ /tmp/scirius
RUN \
    echo "**** install util scripts ****" && \
    cp -Rf /tmp/scirius/* /opt/scirius && \
    chmod ugo+x /opt/scirius/bin/* && \
    rm -rf /tmp/*
    
    
    
HEALTHCHECK --start-period=3m \
  CMD curl --silent --fail http://127.0.0.1:8000 || exit 1

VOLUME /rules /data /static /logs

EXPOSE 8000

ENTRYPOINT ["/opt/scirius/bin/start-scirius.sh"]
