#!/bin/bash

# Copyright Stamus Networks
# All rights reserved
# Debian SELKS script - oss@stamus-networks.com
#
# Please run on Debian


echo -e "\n Adjusting kernel parameters in /etc/sysctl.conf ... \n";

  if grep --quiet "### STAMUS Networks" /etc/sysctl.conf 
    then
      sed -i -e  '/### STAMUS Networks/,/### STAMUS Networks/d' /etc/sysctl.conf
  fi



echo '### STAMUS Networks ' >> /etc/sysctl.conf
echo '' >> /etc/sysctl.conf
echo 'net.core.netdev_max_backlog=250000' >> /etc/sysctl.conf
echo 'net.core.rmem_max=16777216' >> /etc/sysctl.conf
echo 'net.core.rmem_default=16777216' >> /etc/sysctl.conf
echo 'net.core.optmem_max=16777216' >> /etc/sysctl.conf
echo '' >> /etc/sysctl.conf
echo '### STAMUS Networks ' >> /etc/sysctl.conf

/sbin/sysctl -p
echo -e "\n DONE adjusting kernel parameters in /etc/sysctl.conf \n";
