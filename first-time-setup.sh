#!/bin/bash

# Copyright(C) 2019, Stamus Networks
# All rights reserved
# Part of Debian SELKS scripts
# "Written" by Raphaël Brogat <rbrogat@stamus-networks.com>
# ( mostly copy/pasted from the work of Peter Manev <pmanev@stamus-networks.com> )
#
# Please run on Debian
#
# This script comes with ABSOLUTELY NO WARRANTY!
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


# if (( $EUID != 0 )); then
#      echo -e "Please run this script as root or with \"sudo\".\n"
#      exit 1
# fi

function getInterfaces {
  intfnum=0
  for interface in $(ls /sys/class/net); do echo "${intfnum}: ${interface}"; ((intfnum++)) ; done
  
  echo -e "Please type in interface or space delimited interfaces below and hit \"Enter\"."
  echo -e "Choose the interface(s) that is (are) one the network(s) you want to monitor"
  echo -e "Example: eth1"
  echo -e "OR"
  echo -e "Example: eth1 eth2 eth3"
  echo -e "\nConfigure threat detection for INTERFACE(S): "
  read interfaces
  
  echo -e "\nThe supplied network interface(s):  ${interfaces} \n";
  INTERFACE_EXISTS="YES"
  if [ -z "${interfaces}" ] ; then
    echo -e "\nNo input provided at all."
    echo -e "Exiting with ERROR...."
    INTERFACE_EXISTS="NO"
    exit 1
  fi
  
  for interface in ${interfaces}
  do
    if ! cat /sys/class/net/${interface}/operstate > /dev/null 2>&1 ; then
        echo -e "\nUSAGE: `basename $0` -> the script requires at least 1 argument - a network interface!"
        echo -e "#######################################"
        echo -e "Interface: ${interface} is NOT existing."
        echo -e "#######################################"
        echo -e "Please supply a correct/existing network interface or check your spelling.\n"
        INTERFACE_EXISTS="NO"
    fi
    
  done
}

getInterfaces

while [[ ${INTERFACE_EXISTS} != "YES"  ]]; do
  getInterfaces
done

for interface in ${interfaces}
do
  INTERFACES_LIST=${INTERFACES_LIST}\ -i\ ${interface}
done

echo INTERFACES=$INTERFACES_LIST > .env

while true; do
    read -p "Do you want to use debug mode?[Y/N] " yn
    case $yn in
        [Yy]* ) echo SCIRIUS_DEBUG=True >> .env; echo NGINX_EXEC=nginx-debug >> .env; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
