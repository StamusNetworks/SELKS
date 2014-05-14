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
--bootappend-live "boot=live config username=selks-user live-config.user-default-groups=audio,cdrom,floppy,video,dip,plugdev,scanner,bluetooth,netdev,sudo" \
--iso-application SELKS - Suricata Elasticsearch Logstash Kibana Scirius \
--iso-preparer Stamus Networks --iso-publisher Stamus Networks \
--iso-volume Stamus-SELKS

# create dirs if not existing for the custom config files
mkdir -p config/includes.chroot/etc/logstash/conf.d/
mkdir -p config/includes.chroot/etc/skel/.local/share/applications/
mkdir -p config/includes.chroot//usr/share/applications/
mkdir -p config/includes.chroot/etc/iceweasel/profile/
mkdir -p config/includes.chroot/etc/logrotate.d/
mkdir -p config/includes.chroot/etc/default/
mkdir -p config/includes.chroot/etc/init.d/
mkdir -p config/includes.binary/isolinux/
mkdir -p config/includes.chroot/var/log/suricata/StatsByDate/
mkdir -p config/includes.chroot/etc/logrotate.d/
mkdir -p config/includes.chroot/usr/share/images/desktop-base/
mkdir -p config/includes.chroot/opt/
mkdir -p config/includes.chroot/etc/suricata/rules/
cd config/includes.chroot/opt/ && \
git clone https://github.com/StamusNetworks/scirius.git 
cd ../../../../


# add config and menu colored files
# Launch-Scirius menu icon/launcher under "SystemTools" in LXDE for root plus every user
cp staging/usr/share/applications/Launch-Scirius.desktop Stamus-Live-Build/config/includes.chroot/usr/share/applications/
cp staging/usr/share/applications/Launch-Scirius.desktop Stamus-Live-Build/config/includes.chroot/etc/skel/.local/share/applications/
# logstash
cp staging/etc/logstash/conf.d/logstash.conf Stamus-Live-Build/config/includes.chroot/etc/logstash/conf.d/ 
# suricata init script
cp staging/etc/default/suricata Stamus-Live-Build/config/includes.chroot/etc/default/
cp staging/etc/init.d/suricata Stamus-Live-Build/config/includes.chroot/etc/init.d/
# Iceweasel bookmarks
cp staging/etc/iceweasel/profile/bookmarks.html Stamus-Live-Build/config/includes.chroot/etc/iceweasel/profile/
# logrotate config for eve.json
cp staging/etc/logrotate.d/suricata Stamus-Live-Build/config/includes.chroot/etc/logrotate.d/
# add the Stmaus Networs logo for the boot screen
cp staging/splash.png Stamus-Live-Build/config/includes.binary/isolinux/
# add the SELKS wallpaper
cp staging/wallpaper/joy-wallpaper_1920x1080.svg Stamus-Live-Build/config/includes.chroot/usr/share/images/desktop-base/
# copy banners
cp staging/etc/motd Stamus-Live-Build/config/includes.chroot/etc/
cp staging/etc/issue.net Stamus-Live-Build/config/includes.chroot/etc/
# install scirius db
cp staging/scirius/db.sqlite3 Stamus-Live-Build/config/includes.chroot/opt/scirius/
# install default scirius ruleset
tar -x -C Stamus-Live-Build/config/includes.chroot/etc/suricata/ -f staging/scirius/ruleset.tgz
# copy suricata.yaml using scirius.rules
cp staging/scirius/suricata.yaml Stamus-Live-Build/config/includes.chroot/etc/suricata
# copy init script for suri_reloader
cp staging/scirius/suri_reloader Stamus-Live-Build/config/includes.chroot/etc/init.d/

# add packages to be installed
echo "
libpcre3 libpcre3-dbg libpcre3-dev 
build-essential autoconf automake libtool libpcap-dev libnet1-dev 
libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 
make flex bison git git-core subversion libmagic-dev libnuma-dev pkg-config 
libnetfilter-queue-dev libnetfilter-queue1 libnfnetlink-dev libnfnetlink0 
ethtool bwm-ng iptraf htop libjansson-dev libjansson4 libnss3-dev libnspr4-dev 
libgeoip1 libgeoip-dev apache2 openjdk-7-jdk openjdk-7-jre-headless 
rsync wireshark tcpreplay sysstat hping3 screen terminator ngrep tcpflow 
dsniff mc python-daemon
python-crypto libgmp10 libyaml-0-2  
python-yaml ssh sudo tcpdump
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
d-i passwd/user-default-groups string audio cdrom floppy video dip plugdev scanner bluetooth netdev sudo

d-i passwd/root-password password StamusNetworks
d-i passwd/root-password-again password StamusNetworks
" > Stamus-Live-Build/config/debian-installer/preseed.cfg

# build the ISO
cd Stamus-Live-Build && ( lb build 2>&1 | tee build.log )
mv binary.hybrid.iso SELKS.iso
