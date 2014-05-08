#!/bin/bash

# Copyright Stamus Networks
# All rights reserved
# Debian Live ISO script - pmanev@stamus-networks.com
#

set -e

# Begin
# Pre staging
#
mkdir -p Stamus-Live-Build
cd Stamus-Live-Build && lb config -a amd64 -d wheezy --debian-installer live \
--iso-application SELKS - Suricata Elasticsearch Logstash Kibana Scirius \
--iso-preparer Stamus Networks --iso-publisher Stamus Networks \
--iso-volume Stamus-SELKS

# create dirs if not existing for the custom config files
mkdir -p config/includes.chroot/etc/logstash/conf.d/
mkdir -p config/includes.chroot/etc/elasticsearch/
mkdir -p config/includes.chroot/etc/default/
mkdir -p config/includes.chroot/etc/init.d/
mkdir -p config/includes.binary/isolinux/
mkdir -p config/includes.chroot/var/log/suricata/StatsByDate/
mkdir -p config/includes.chroot/etc/logrotate.d/
mkdir -p config/includes.chroot/opt/
cd config/includes.chroot/opt/ && \
git clone https://github.com/StamusNetworks/scirius.git 

cd ../../../../


# add config and menu colored files
# logstash
cp staging/etc/logstash/conf.d/logstash.conf Stamus-Live-Build/config/includes.chroot/etc/logstash/conf.d/ 
# elasticsearch config with multicasting disbaled 
# to remedy errs when changing IPs of the system/server
# (also threadpooling increased for perf)
cp staging/etc/elasticsearch/elasticsearch.yml Stamus-Live-Build/config/includes.chroot/etc/elasticsearch/
# suricata init script
cp staging/etc/default/suricata Stamus-Live-Build/config/includes.chroot/etc/default/
cp staging/etc/init.d/suricata Stamus-Live-Build/config/includes.chroot/etc/init.d/
# menu colors
cp staging/stdmenu.cfg Stamus-Live-Build/config/includes.binary/isolinux/
cp staging/etc/oinkmaster.conf Stamus-Live-Build/config/includes.chroot/etc/
# logrotate config for eve.json
cp staging/etc/logrotate.d/suricata Stamus-Live-Build/config/includes.chroot/etc/logrotate.d/
# add the Stmaus Networs logo for the boot screen
cp staging/splash.png Stamus-Live-Build/config/includes.binary/isolinux/

# add packages to be installed
echo "
libpcre3 libpcre3-dbg libpcre3-dev 
build-essential autoconf automake libtool libpcap-dev libnet1-dev 
libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 
make flex bison git git-core subversion libmagic-dev libnuma-dev pkg-config 
ethtool bwm-ng iptraf htop libjansson-dev libjansson4 libnss3-dev libnspr4-dev 
libgeoip1 libgeoip-dev apache2 openjdk-7-jdk openjdk-7-jre-headless 
rsync wireshark tcpreplay sysstat 
python-crypto libgmp10 libyaml-0-2  
python-yaml ssh sudo tcpdump oinkmaster 
python-pip task-lxde-desktop debian-installer-launcher " \
>> Stamus-Live-Build/config/package-lists/StamusNetworks.list.chroot


# add specific tasks(script file) to be executed 
# inside the chroot environment
cp staging/config/hooks/chroot-inside-Debian-Live.chroot Stamus-Live-Build/config/hooks/
# Edit the menues names - add  Stamus
cp staging/config/hooks/menues-changes.binary Stamus-Live-Build/config/hooks/

# debian installer preseed.cfg
echo "
d-i netcfg/get_hostname string SELKS

d-i passwd/user-fullname string selks-user User
d-i passwd/username string selks-user
d-i passwd/user-password password selks-user
d-i passwd/user-password-again password selks-user

d-i passwd/root-password password StamusNetworks
d-i passwd/root-password-again password StamusNetworks
" > Stamus-Live-Build/config/debian-installer/preseed.cfg

# build the ISO
cd Stamus-Live-Build && ( lb build 2>&1 | tee build.log )
mv binary.hybrid.iso SELKS.iso
