#!/bin/bash

# Copyright Stamus Networks
# All rights reserved
# Debian Live/Install ISO script - oss@stamus-networks.com
#
# Please RUN ON Debian Wheezy only !!!

set -e

usage()
{
cat << EOF

usage: $0 options

SELKS build your own ISO options

OPTIONS:
   -h      Help info
   -g      GUI option - can be "no-desktop"
   -p      Add package(s) to the build - can be one-package or "package1 package2 package3...." (should be confined to up to 10 packages)
   -k      Kernel option - can be the stable standard version of the kernel you wish to deploy - 
           aka "3.8" or "3.10" or "3.15.1" 
           
   By default no options are required. The options presented here are if you wish to enable/disable/add components.
   By default SELKS will be build with a standard Debian Wheezy 64 bit distro and kernel ver 3.2.
   
   Example: 
   ./build-debian-live.sh 
   ./build-debian-live.sh -k 3.15.3 
   ./build-debian-live.sh -k 3.10.44 -p one-package
   ./build-debian-live.sh -k 3.9.0 -g no-desktop -p one-package
   ./build-debian-live.sh -k 3.14.10 -g no-desktop -p "package1 package2 package3"
   
   
   
EOF
}

GUI=
KERNEL_VER=

while getopts “hg:k:p:” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         g)
             GUI=$OPTARG
             if [[ "$GUI" != "no-desktop" ]]; 
             then
               echo -e "\n Please check the option's spelling \n"
               usage
               exit 1;
             fi
             ;;
         k)
             KERNEL_VER=$OPTARG
             if [[ "$KERNEL_VER" =~ ^[3-4]\.[0-9]+?\.?[0-9]+$ ]];
             then
               echo -e "\n Kernel version set to ${KERNEL_VER} \n"
             else
               echo -e "\n Please check the option's spelling \n"
               usage
               exit 1;
             fi
             ;;
         p)
             PKG_ADD+=("$OPTARG")
             #echo "The first value of the pkg array 'PKG_ADD' is '$PKG_ADD'"
             #echo "The whole list of values is '${PKG_ADD[@]}'"
             echo "Packages to be added to the build: ${PKG_ADD[@]} "
             #exit 1;
             ;;
         ?)
             GUI=
             KERNEL_VER=
             PKG_ADD=
             echo -e "\n Using the default options for the SELKS ISO build \n"
             ;;
     esac
done
shift $((OPTIND -1))

# Begin
# Pre staging
#

mkdir -p Stamus-Live-Build

if [[ -n "$KERNEL_VER" ]]; 
then 
  
  ### Kernel Version choice ###
  
  cd Stamus-Live-Build && mkdir -p kernel-misc && cd kernel-misc 
  wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-${KERNEL_VER}.tar.xz
  if [ $? -eq 0 ];
  then
    echo -e "Downloaded successfully linux-${KERNEL_VER}.tar.xz "
  else
    echo -e "\n Please check your connection \n"
    echo -e "CAN NOT download the requested kernel from - \n"
    echo -e "https://www.kernel.org/pub/linux/kernel/v3.x/linux-${KERNEL_VER}.tar.xz \n"
    exit 1;
  fi

  tar xfJ linux-${KERNEL_VER}.tar.xz 
  cd linux-${KERNEL_VER}
  
  #default linux kernel config
  make defconfig 
  
  #set up concurrent jobs with respect to number of CPUs +1
  # make deb-pkg LOCALVERSION=-selks KDEB_PKGVERSION=3.15.2
  make defconfig && \
  make clean && \
  make -j `getconf _NPROCESSORS_ONLN` deb-pkg LOCALVERSION=-selks KDEB_PKGVERSION=${KERNEL_VER}
  cd ../../
  
  # directory where the kernel image and headers are copied to
  mkdir -p config/packages.chroot/
  # directory that needs to be present for the Kernel Version choice to work
  mkdir -p cache/contents.chroot/
  # hook directory for the initramfs script to be copied to
  mkdir -p config/hooks/
  
  # copy the kernel image and headers
  mv kernel-misc/*.deb config/packages.chroot/
  cp ../staging/config/hooks/all_chroot_update-initramfs.sh config/hooks/all_chroot_update-initramfs.chroot
  
  
  ### Kernel Version choice ## 
  
  lb config \
  -a amd64 -d wheezy  \
  --swap-file-size 2048 \
  --bootloader syslinux \
  --linux-packages linux-image-${KERNEL_VER} \
  --linux-flavour selks \
  --debian-installer live \
  --bootappend-live "boot=live config username=selks-user live-config.user-default-groups=audio,cdrom,floppy,video,dip,plugdev,scanner,bluetooth,netdev,sudo" \
  --iso-application SELKS - Suricata Elasticsearch Logstash Kibana Scirius \
  --iso-preparer Stamus Networks \
  --iso-publisher Stamus Networks \
  --iso-volume Stamus-SELKS $LB_CONFIG_OPTIONS
  
else

  cd Stamus-Live-Build && lb config \
  -a amd64 -d wheezy \
  --swap-file-size 2048 \
  --debian-installer live \
  --bootappend-live "boot=live config username=selks-user live-config.user-default-groups=audio,cdrom,floppy,video,dip,plugdev,scanner,bluetooth,netdev,sudo" \
  --iso-application SELKS - Suricata Elasticsearch Logstash Kibana Scirius \
  --iso-preparer Stamus Networks \
  --iso-publisher Stamus Networks \
  --iso-volume Stamus-SELKS $LB_CONFIG_OPTIONS
  
fi

# create dirs if not existing for the custom config files
mkdir -p config/includes.chroot/etc/logstash/conf.d/
mkdir -p config/includes.chroot/etc/skel/.local/share/applications/
mkdir -p config/includes.chroot/etc/skel/Desktop/
mkdir -p config/includes.chroot/usr/share/applications
mkdir -p config/includes.chroot/etc/logrotate.d/
mkdir -p config/includes.chroot/etc/default/
mkdir -p config/includes.chroot/etc/init.d/
mkdir -p config/includes.binary/isolinux/
mkdir -p config/includes.chroot/etc/nginx/sites-available/
mkdir -p config/includes.chroot/var/log/suricata/StatsByDate/
mkdir -p config/includes.chroot/etc/logrotate.d/
mkdir -p config/includes.chroot/usr/share/images/desktop-base/
mkdir -p config/includes.chroot/opt/selks/
mkdir -p config/includes.chroot/etc/suricata/rules/
mkdir -p config/includes.chroot/etc/kibana/
mkdir -p config/includes.chroot/etc/profile.d/
mkdir -p config/includes.chroot/root/Desktop/
mkdir -p config/includes.chroot/etc/iceweasel/profile/
mkdir -p config/includes.chroot/etc/apt/sources.list.d/



# kibana install
mkdir -p config/includes.chroot/var/www && \
tar -C config/includes.chroot/var/www --strip=1 -xzf ../staging/stamus/kibana-3.1.0-stamus.tgz


cd config/includes.chroot/opt/selks/ && \
git clone -b scirius-0.5 https://github.com/StamusNetworks/scirius.git
cd ../../../../../


# reverse proxy with nginx and ssl
cp staging/etc/nginx/sites-available/stamus.conf  Stamus-Live-Build/config/includes.chroot/etc/nginx/sites-available/
# copy kibana config
cp staging/etc/kibana/config.js  Stamus-Live-Build/config/includes.chroot/etc/kibana/
# cp README and LICENSE files to the user's desktop
cp LICENSE Stamus-Live-Build/config/includes.chroot/etc/skel/Desktop/
cat README.rst | sed -e 's/https:\/\/your.selks.IP.here/http:\/\/selks/' | rst2html > Stamus-Live-Build/config/includes.chroot/etc/skel/Desktop/README.html
# the same as above but for root
cp LICENSE Stamus-Live-Build/config/includes.chroot/root/Desktop/
cat README.rst | sed -e 's/https:\/\/your.selks.IP.here/http:\/\/selks/' | rst2html > Stamus-Live-Build/config/includes.chroot/root/Desktop/README.html
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
mkdir -p Stamus-Live-Build/config/includes.chroot/opt/selks/scirius/db/
cp staging/scirius/local_settings.py Stamus-Live-Build/config/includes.chroot/opt/selks/scirius/scirius/
# copy suricata.yaml using scirius.rules
cp staging/scirius/suricata.yaml Stamus-Live-Build/config/includes.chroot/etc/suricata
cp staging/etc/profile.d/pythonpath.sh Stamus-Live-Build/config/includes.chroot/etc/profile.d/
# copy init script for suri_reloader
cp staging/scirius/suri_reloader Stamus-Live-Build/config/includes.chroot/etc/init.d/
# copy init script for djando
cp staging/scirius/django-init Stamus-Live-Build/config/includes.chroot/etc/init.d/django
# copy elasticsearch repo file
cp staging/etc/apt/sources.list.d/elasticsearch.list Stamus-Live-Build/config/includes.chroot/etc/apt/sources.list.d/


# add packages to be installed
echo "
libpcre3 libpcre3-dbg libpcre3-dev 
build-essential autoconf automake libtool libpcap-dev libnet1-dev 
libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 
make flex bison git git-core libmagic-dev libnuma-dev pkg-config
libnetfilter-queue-dev libnetfilter-queue1 libnfnetlink-dev libnfnetlink0 
ethtool bwm-ng iptraf htop libjansson-dev libjansson4 libnss3-dev libnspr4-dev 
libgeoip1 libgeoip-dev openjdk-7-jre-headless
rsync wireshark tcpreplay sysstat hping3 screen terminator ngrep tcpflow 
dsniff mc python-daemon libnss3-tools curl 
python-crypto libgmp10 libyaml-0-2 python-simplejson
python-yaml ssh sudo tcpdump nginx openssl 
python-pip debian-installer-launcher live-build " \
>> Stamus-Live-Build/config/package-lists/StamusNetworks.list.chroot

# unless otherwise specified the ISO will be with a Desktop Environment
if [[ -z "$GUI" ]]; then 
  echo " lxde " >> Stamus-Live-Build/config/package-lists/StamusNetworks.list.chroot
fi

# if -p (add packages) option is used - add those packages to the build
if [[ -n "${PKG_ADD}" ]]; then 
  echo " ${PKG_ADD[@]} " >> Stamus-Live-Build/config/package-lists/StamusNetworks.list.chroot
fi

# add specific tasks(script file) to be executed 
# inside the chroot environment
cp staging/config/hooks/chroot-inside-Debian-Live.chroot Stamus-Live-Build/config/hooks/

# Edit menu names for Live and Install
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
