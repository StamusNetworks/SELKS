#!/bin/bash

# Copyright Stamus Networks
# All rights reserved
# Debian Live/Install ISO script - oss@stamus-networks.com
#
# Please RUN ON Debian Jessie only !!!

set -e

usage()
{
cat << EOF

usage: $0 options

###################################
#!!! RUN on Debian Jessie ONLY !!!#
###################################

SELKS build your own ISO options

OPTIONS:
   -h      Help info
   -g      GUI option - can be "no-desktop"
   -p      Add package(s) to the build - can be one-package or "package1 package2 package3...." (should be confined to up to 10 packages)
   -k      Kernel option - can be the stable standard version of the kernel you wish to deploy - 
           aka you can choose any kernel "3.x.x" you want.
           Example: "3.10" or "3.19.6" or "3.18.11" 
           
           More info on kernel versions and support:
           https://www.kernel.org/
           https://www.kernel.org/category/releases.html
           
   By default no options are required. The options presented here are if you wish to enable/disable/add components.
   By default SELKS will be build with a standard Debian Jessie 64 bit distro and kernel ver 3.16.
   
   EXAMPLE (default): 
   ./build-debian-live.sh 
   The example above (is the default) will build a SELKS standard Debian Jessie 64 bit distro (with kernel ver 3.16)
   
   EXAMPLE (customizations): 
   
   ./build-debian-live.sh -k 3.19.6 
   The example above will build a SELKS Debian Jessie 64 bit distro with kernel ver 3.19.6
   
   ./build-debian-live.sh -k 3.18.11 -p one-package
   The example above will build a SELKS Debian Jessie 64 bit distro with kernel ver 3.18.11
   and add the extra package named  "one-package" to the build.
   
   ./build-debian-live.sh -k 3.18.11 -g no-desktop -p one-package
   The example above will build a SELKS Debian Jessie 64 bit distro, no desktop with kernel ver 3.18.11
   and add the extra package named  "one-package" to the build.
   
   ./build-debian-live.sh -k 3.18.11 -g no-desktop -p "package1 package2 package3"
   The example above will build a SELKS Debian Jessie 64 bit distro, no desktop with kernel ver 3.18.11
   and add the extra packages named  "package1", "package2", "package3" to the build.
   
   
   
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
               echo -e "\n Please check the option's spelling "
               echo -e " Also - only kernel versions >3.0 are supported !! \n"
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

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Begin
# Pre staging
#

mkdir -p Stamus-Live-Build

if [[ -n "$KERNEL_VER" ]]; 
then 
  
  ### START Kernel Version choice ###
  
  cd Stamus-Live-Build && mkdir -p kernel-misc && cd kernel-misc 
  if [[ ${KERNEL_VER} == 3* ]];
  then 
    wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-${KERNEL_VER}.tar.xz
  elif [[ ${KERNEL_VER} == 4* ]];
  then
     wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-${KERNEL_VER}.tar.xz
  else
    echo "Unsupported kernel version! Only kernel >3.0 are supported"
    exit 1;
  fi

  if [ $? -eq 0 ];
  then
    echo -e "Downloaded successfully linux-${KERNEL_VER}.tar.xz "
  else
    echo -e "\n Please check your connection \n"
    echo -e "CAN NOT download the requested kernel. Please make sure the kernel version is present here - \n"
    echo -e "https://www.kernel.org/pub/linux/kernel/v3.x/ \n"
    echo -e "or here respectively \n"
    echo -e "https://www.kernel.org/pub/linux/kernel/v4.x/ \n"
    exit 1;
  fi

  tar xfJ linux-${KERNEL_VER}.tar.xz 
  cd linux-${KERNEL_VER}
  
  # Default linux kernel config
  # Set up concurrent jobs with respect to number of CPUs
  
  make defconfig && \
  make clean && \
  make -j `getconf _NPROCESSORS_ONLN` deb-pkg LOCALVERSION=-stamus KDEB_PKGVERSION=${KERNEL_VER}
  cd ../../
  
  # Directory where the kernel image and headers are copied to
  mkdir -p config/packages.chroot/
  # Directory that needs to be present for the Kernel Version choice to work
  mkdir -p cache/contents.chroot/
  # Hook directory for the initramfs script to be copied to
  mkdir -p config/hooks/
  
  # Copy the kernel image and headers
  mv kernel-misc/*.deb config/packages.chroot/
  cp ../staging/config/hooks/all_chroot_update-initramfs.sh config/hooks/all_chroot_update-initramfs.chroot
    
  
  ### END Kernel Version choice ## 
  
  lb config \
  -a amd64 -d jessie  \
  --archive-areas "main contrib" \
  --swap-file-size 2048 \
  --bootloader syslinux \
  --debian-installer live \
  --bootappend-live "boot=live swap config username=selks-user live-config.hostname=SELKS live-config.user-default-groups=audio,cdrom,floppy,video,dip,plugdev,scanner,bluetooth,netdev,sudo" \
  --linux-packages linux-image-${KERNEL_VER} \
  --linux-flavour stamus \
  --iso-application SELKS - Suricata Elasticsearch Logstash Kibana Scirius \
  --iso-preparer Stamus Networks \
  --iso-publisher Stamus Networks \
  --iso-volume Stamus-SELKS $LB_CONFIG_OPTIONS
  
else

  cd Stamus-Live-Build && lb config \
  -a amd64 -d jessie \
  --archive-areas "main contrib" \
  --swap-file-size 2048 \
  --debian-installer live \
  --bootappend-live "boot=live swap config username=selks-user live-config.hostname=SELKS live-config.user-default-groups=audio,cdrom,floppy,video,dip,plugdev,scanner,bluetooth,netdev,sudo" \
  --iso-application SELKS - Suricata Elasticsearch Logstash Kibana Scirius \
  --iso-preparer Stamus Networks \
  --iso-publisher Stamus Networks \
  --iso-volume Stamus-SELKS $LB_CONFIG_OPTIONS
  
fi

# Create dirs if not existing for the custom config files
mkdir -p config/includes.chroot/etc/logstash/conf.d/
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
mkdir -p config/includes.chroot/etc/suricata/rules/
mkdir -p config/includes.chroot/etc/profile.d/
mkdir -p config/includes.chroot/root/Desktop/
mkdir -p config/includes.chroot/etc/iceweasel/profile/
mkdir -p config/includes.chroot/etc/apt/sources.list.d/
mkdir -p config/includes.chroot/etc/conky/
mkdir -p config/includes.chroot/etc/alternatives/


cd ../

# cp README and LICENSE files to the user's desktop
cp LICENSE Stamus-Live-Build/config/includes.chroot/etc/skel/Desktop/
cp LICENSE Stamus-Live-Build/config/includes.chroot/etc/skel/
# some README adjustments - in order to add a http link
# to point to the latest README version located on SELKS github
# The same as above but for root
cp LICENSE Stamus-Live-Build/config/includes.chroot/root/Desktop/
# some README adjustments - in order to add a http link
# to point to the latest README version located on SELKS github
echo -e "\nPlease make sure you have the latest README copy -> https://github.com/StamusNetworks/SELKS/tree/master \n\n" > TMP.rst
cat README.rst >> TMP.rst
cat TMP.rst | sed -e 's/https:\/\/your.selks.IP.here/http:\/\/selks/' | rst2html > Stamus-Live-Build/config/includes.chroot/etc/skel/Desktop/README.html
# same as above but for root
cat TMP.rst | sed -e 's/https:\/\/your.selks.IP.here/http:\/\/selks/' | rst2html > Stamus-Live-Build/config/includes.chroot/root/Desktop/README.html
rm TMP.rst 
# cp Dashboards and Scirius desktop shortcuts
cp staging/usr/share/applications/Dashboards.desktop Stamus-Live-Build/config/includes.chroot/etc/skel/Desktop/
cp staging/usr/share/applications/Scirius.desktop Stamus-Live-Build/config/includes.chroot/etc/skel/Desktop/
# Same as above but for root
cp staging/usr/share/applications/Dashboards.desktop Stamus-Live-Build/config/includes.chroot/root/Desktop/
cp staging/usr/share/applications/Scirius.desktop Stamus-Live-Build/config/includes.chroot/root/Desktop/
# Logstash
cp staging/etc/logstash/conf.d/logstash.conf Stamus-Live-Build/config/includes.chroot/etc/logstash/conf.d/ 
# Overwrite Suricata default script
cp staging/etc/default/suricata Stamus-Live-Build/config/includes.chroot/etc/default/
# Iceweasel bookmarks
cp staging/etc/iceweasel/profile/bookmarks.html Stamus-Live-Build/config/includes.chroot/etc/iceweasel/profile/
# Logrotate config for eve.json
cp staging/etc/logrotate.d/suricata Stamus-Live-Build/config/includes.chroot/etc/logrotate.d/
# Add the Stmaus Networs logo for the boot screen
cp staging/splash.png Stamus-Live-Build/config/includes.binary/isolinux/
# Add the SELKS wallpaper
cp staging/wallpaper/joy-wallpaper_1920x1080.svg Stamus-Live-Build/config/includes.chroot/etc/alternatives/desktop-background
# Copy banners
cp staging/etc/motd Stamus-Live-Build/config/includes.chroot/etc/
cp staging/etc/issue.net Stamus-Live-Build/config/includes.chroot/etc/
# Copy pythonpath.sh
cp staging/etc/profile.d/pythonpath.sh Stamus-Live-Build/config/includes.chroot/etc/profile.d/
# Copy init script for suri_reloader
cp staging/scirius/suri_reloader Stamus-Live-Build/config/includes.chroot/etc/init.d/
# Copy elasticsearch repo file
cp staging/etc/apt/sources.list.d/elasticsearch.list Stamus-Live-Build/config/includes.chroot/etc/apt/sources.list.d/
# Copy stamus debian repo list file - 
# holding latest Suricata,libhtp,Scirius and kernel packages
cp staging/etc/apt/sources.list.d/selks.list Stamus-Live-Build/config/includes.chroot/etc/apt/sources.list.d/

# Add core system packages to be installed
echo "
libpcre3 libpcre3-dbg libpcre3-dev ntp
build-essential autoconf automake libtool libpcap-dev libnet1-dev 
libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 
make flex bison git git-core libmagic-dev libnuma-dev pkg-config
libnetfilter-queue-dev libnetfilter-queue1 libnfnetlink-dev libnfnetlink0 
libjansson-dev libjansson4 libnss3-dev libnspr4-dev libgeoip1 libgeoip-dev 
rsync mc python-daemon libnss3-tools curl virtualbox-guest-utils 
python-crypto libgmp10 libyaml-0-2 python-simplejson python-pygments
python-yaml ssh sudo tcpdump nginx openssl jq  
python-pip debian-installer-launcher live-build " \
>> Stamus-Live-Build/config/package-lists/StamusNetworks-CoreSystem.list.chroot

# Add system tools packages to be installed
echo "
ethtool bwm-ng iptraf htop rsync tcpreplay sysstat hping3 screen ngrep 
tcpflow dsniff mc python-daemon wget curl vim bootlogd lsof" \
>> Stamus-Live-Build/config/package-lists/StamusNetworks-Tools.list.chroot

# Unless otherwise specified the ISO will be with a Desktop Environment
if [[ -z "$GUI" ]]; then 
  echo "
  lxde fonts-lyx wireshark terminator conky" \
  >> Stamus-Live-Build/config/package-lists/StamusNetworks-Gui.list.chroot
  # Copy conky conf file
  cp staging/etc/conky/conky.conf Stamus-Live-Build/config/includes.chroot/etc/conky/
  # Copy the menu shortcuts for Kibana and Scirius
  # this is for the lxde menu widgets - not the desktop shortcuts
  cp staging/usr/share/applications/Dashboards.desktop Stamus-Live-Build/config/includes.chroot/usr/share/applications/
  cp staging/usr/share/applications/Scirius.desktop Stamus-Live-Build/config/includes.chroot/usr/share/applications/
  
fi

# If -p (add packages) option is used - add those packages to the build
if [[ -n "${PKG_ADD}" ]]; then 
  echo " ${PKG_ADD[@]} " >> \
  Stamus-Live-Build/config/package-lists/StamusNetworks-UsrPkgAdd.list.chroot
fi

# Add specific tasks(script file) to be executed 
# inside the chroot environment
cp staging/config/hooks/chroot-inside-Debian-Live.chroot Stamus-Live-Build/config/hooks/

# Edit menu names for Live and Install
if [[ -n "$KERNEL_VER" ]]; 
then
  
   # IF kustom kernel option is chosen "-k ...":
   # remove the live menu since different kernel versions and custom flavours  
   # can potentially fail to load in LIVE depending on the given environment.
   # So we create a file for execution at the binary stage to remove the 
   # live menu choice. That leaves the options to install.
   cp staging/config/hooks/menues-changes-live-custom-kernel-choice.binary Stamus-Live-Build/config/hooks/
   cp staging/config/hooks/menues-changes.binary Stamus-Live-Build/config/hooks/
   
else
  
  cp staging/config/hooks/menues-changes.binary Stamus-Live-Build/config/hooks/
  
fi

# Debian installer preseed.cfg
echo "
d-i netcfg/hostname string SELKS

d-i passwd/user-fullname string selks-user User
d-i passwd/username string selks-user
d-i passwd/user-password password selks-user
d-i passwd/user-password-again password selks-user
d-i passwd/user-default-groups string audio cdrom floppy video dip plugdev scanner bluetooth netdev sudo

d-i passwd/root-password password StamusNetworks
d-i passwd/root-password-again password StamusNetworks
" > Stamus-Live-Build/config/includes.installer/preseed.cfg

# Build the ISO
cd Stamus-Live-Build && ( lb build 2>&1 | tee build.log )
#mv binary.hybrid.iso SELKS.iso
mv live-image-amd64.hybrid.iso SELKS.iso
