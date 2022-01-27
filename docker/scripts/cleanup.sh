#!/bin/bash
#
# Copyright(C) 2021, Stamus Networks
# Written by Raphaël Brogat <rbrogat@stamus-networks.com>
#
# This script comes with ABSOLUTELY NO WARRANTY!
#
# GPLv3 <http://www.gnu.org/licenses/>.

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"

function Help(){
  # Display Help
  { echo "***  cleanup.sh help  ***"
    echo
    echo "Use this script to remove all data from elasticsearch and suricata"
    echo "Containers must be running for the data to be removed"
    echo
    echo -e " Syntax: cleanup.sh"
    echo
    echo

  } | fmt
}

if [ $# -gt 0 ]; then
    Help
    exit -1
fi


## TEST IF DOCKER IS ACCESSIBLE TO THIS USER ##
dockerV=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
if [[ -z "$dockerV" ]]; then
  echo "Please run this script as root or with sudo"
  exit 1
fi

echo "Delete suricata logs:"
rm -f ${BASEDIR}/containers-data/suricata/logs/* && echo -e "OK\n" || { echo -e "ERROR\n" && exit 1; }

echo "send SIGHUP to suricata:"
docker kill --signal=HUP suricata | grep -q "suricata" && echo -e "OK\n" || echo -e "ERROR\n"

echo "Delete elasticsearch indexes:"
OUT=$( docker exec scirius curl -s -X DELETE -i 'http://elasticsearch:9200/logstash-*' )
echo "${OUT}" | grep -q "200 OK" && echo -e "OK\n" || { echo -e "ERROR\n ${OUT}\n" && exit 1; }
