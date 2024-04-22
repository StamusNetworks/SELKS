#!/bin/bash

until [[ -d "/suricata-logs/fpc" ]] && [[ -f "/suricata-logs/eve.json" ]]
do
    echo "Waiting for Suricata to populate FPC and eve.json"
    sleep 3
done

# set runtime environment variables
export ARKIME_ELASTICSEARCH="http://"$ES_HOST":"$ES_PORT

echo "Init ES database..."
echo INIT | $ARKIMEDIR/db/db.pl $ARKIME_ELASTICSEARCH init
echo "Upgrading ES database..."
echo UPGRADE | $ARKIMEDIR/db/db.pl $ARKIME_ELASTICSEARCH upgrade
echo "Creating user..."
$ARKIMEDIR/bin/arkime_add_user.sh $ARKIME_ADMIN_USERNAME "SELKS Admin User" $ARKIME_ADMIN_PASSWORD --admin
echo $ARKIME_VERSION > $ARKIMEDIR/etc/.initialized
$ARKIMEDIR/bin/arkime_add_user.sh moloch moloch moloch --admin --webauth
echo $ARKIME_VERSION > $ARKIMEDIR/etc/.initialized


echo "Starting Arkime capture in the background..."
exec $ARKIMEDIR/bin/capture -m -s -R /suricata-logs/fpc/ >> $ARKIMEDIR/logs/capture.log 2>&1 &

echo "Look at log files for errors"
echo "  /data/logs/viewer.log"
echo "  /data/logs/capture.log"
echo "Visit http://127.0.0.1:8005 with your favorite browser."
echo "  user: $ARKIME_ADMIN_USERNAME"
echo "  password: $ARKIME_ADMIN_PASSWORD"

echo "Launch viewer..."
cd $ARKIMEDIR/viewer
$ARKIMEDIR/bin/node $ARKIMEDIR/viewer/viewer.js
