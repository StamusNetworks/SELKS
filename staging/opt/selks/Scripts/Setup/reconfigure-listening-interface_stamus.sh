#!/bin/bash

# Copyright Stamus Networks
# All rights reserved
# Debian SELKS script - oss@stamus-networks.com
#
# Please run on Debian
#
# This script comes with ABSOLUTELY NO WARRANTY!
# It can be used/modified/redistributed without any permission.


echo -e "\nPlease supply a network interface for inspection (mirror or inbound)"
echo -e "Example - eth1"
echo -e "\nThe script will make adjustments for(or in): "
echo -e "    1) the interface provided"
echo -e "    2) kernel tuning"
echo -e "    3) /etc/default/suricata"
echo -e "    4) /etc/suricata/suricata.yaml"

echo "INTERFACE: "
read interface

echo -e "\nThe supplied network interface is:  ${interface} \n";


  if ! grep --quiet "${interface}" /proc/net/dev
    then
      echo -e "\nUSAGE: `basename $0` -> the script requires 1 argument - a network interface!"
      echo -e "\nPlease supply a correct/existing network interface or check your spelling. Ex - eth1 \n"
      exit 1;
  fi

# Edit the /etc/default/suricata
echo -e "\nEditing the /etc/default/suricata"
sed -i -e "s/^IFACE=.*/IFACE=${interface}/g" /etc/default/suricata

# Adjusting the /etc/suricata/suricata.yaml
echo -e "\nAdjust the /etc/suricata/suricata.yaml"
sed -i -e "/^af-packet:/{\$!N; s/  - interface: .*/  - interface: ${interface}/}" /etc/suricata/suricata.yaml

# Calling disable-interface-offloading_stamus.sh
echo -e "\nCalling disable-interface-offloading_stamus.sh"
./opt/selks/Scripts/Tuning/disable-interface-offloading_stamus.sh ${interface}

# Calling kernel-tuneup_stamus.sh
echo -e "\nCalling kernel-tuneup_stamus.sh"
./opt/selks/Scripts/Tuning/kernel-tuneup_stamus.sh



