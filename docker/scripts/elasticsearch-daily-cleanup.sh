#! /bin/sh
# © Charles BLANC-ROLIN - https://pawpatrules.fr
# This script comes with ABSOLUTELY NO WARRANTY!
# License : GPLv3
# This script delete Logstash indexes on Elastic Search containter.
# It is intended to be used daily via cron, if data is older than the number of retention days you set, it will not be deleted.

# To enable, uncomment the last line of the script and add this line in OS crontab (not in container) for root user :
# 00 03 * * * sh /opt/selksd/SELKS/docker/scripts/elasticsearch-daily-cleanup.sh

# Define number of days (>1) you want to keep :

RETENTION=15

echo "\n##########################################################\nElastic Search Daily Cleanup Script for SELKS with Docker\n##########################################################\n"
echo "You've choosed $RETENTION days of retention\n"
echo "These indexes will be deleted :\n"
docker exec scirius curl -s http://elasticsearch:9200/_cat/indices/*`date +%Y.%m.%d -d "-$RETENTION days"`?pretty
echo "\nDeletion process starting..."
#docker exec scirius curl -X DELETE -s -i http://elasticsearch:9200/*`date +%Y.%m.%d -d "-$RETENTION days"`?pretty
