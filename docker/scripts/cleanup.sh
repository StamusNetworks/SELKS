#!/bin/bash
#
# Copyright(C) 2021, Stamus Networks
# Written by Raphaël Brogat <rbrogat@stamus-networks.com>
#
# This script comes with ABSOLUTELY NO WARRANTY!
#
# GPLv3 <http://www.gnu.org/licenses/>.

#BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
BASEDIR="/opt/selksd/SELKS/docker/"


## TEMPORARY FIX WHILE PERMISSION ISSUE
if (( $EUID != 0 )); then
     echo -e "Please run this script as root or with \"sudo\".\n"
     exit 1
fi

# TEST IF DOCKER IS ACCESSIBLE TO THIS USER ##
dockerV=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
if [[ -z "$dockerV" ]]; then
  echo "Please run this script as root or with sudo"
  exit 1
fi

echo "Delete suricata logs:"
rm -rf ${BASEDIR}/containers-data/suricata/logs/* && echo -e "OK\n" || { echo -e "ERROR\n" && exit 1; }

echo "Deleting data from arkime"
docker exec arkime bash -c "printf 'WIPE\n' | /opt/arkime/db/db.pl http://elasticsearch:9200 wipe" | grep -q "Finished" && echo -e "OK\n" || echo -e "ERROR\n"

echo "send SIGHUP to suricata:"
docker kill --signal=HUP suricata | grep -q "suricata" && echo -e "OK\n" || echo -e "ERROR\n"

echo "Delete elasticsearch indexes:"
OUT=$( docker exec scirius curl -s -X DELETE -i 'http://elasticsearch:9200/logstash-*' )
echo "${OUT}" | grep -q "200 OK" && echo -e "OK\n" || { echo -e "ERROR\n ${OUT}\n" && exit 1; }
