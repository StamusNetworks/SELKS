#!/bin/bash

echo "Giving ES time to start..."
until curl -sS "http://$ES_HOST:$ES_PORT/_cluster/health?wait_for_status=yellow" > /dev/null 2>&1
do
    echo "Waiting for ES to start"
    sleep 3
done

echo
echo "ES started..."

until [[ -d "/suricata-logs/fpc" ]]
do
    echo "Waiting for Suricata to populate FPC"
    sleep 3
done

# set runtime environment variables
export ARKIME_ELASTICSEARCH="http://"$ES_HOST":"$ES_PORT

if [ ! -f $ARKIMEDIR/etc/.initialized ]; then
    echo INIT | $ARKIMEDIR/db/db.pl $ARKIME_ELASTICSEARCH init
    $ARKIMEDIR/bin/arkime_add_user.sh $ARKIME_ADMIN_USERNAME "SELKS Admin User" $ARKIME_ADMIN_PASSWORD --admin
    $ARKIMEDIR/bin/arkime_add_user.sh moloch moloch moloch --admin --webauth
    echo $ARKIME_VERSION > $ARKIMEDIR/etc/.initialized
else
    # possible update
    read old_ver < $ARKIMEDIR/etc/.initialized
    # detect the newer version
    newer_ver=`echo -e "$old_ver\n$ARKIME_VERSION" | sort -rV | head -n 1`
    # the old version should not be the same as the newer version
    # otherwise -> upgrade
    if [ "$old_ver" != "$newer_ver" ]; then
        echo "Upgrading ES database..."
        echo UPGRADE | $ARKIMEDIR/db/db.pl http://$ES_HOST:$ES_PORT upgrade
        echo $ARKIME_VERSION > $ARKIMEDIR/etc/.initialized
    fi
fi

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
$ARKIMEDIR/bin/node $ARKIMEDIR/viewer/viewer.js >> $ARKIMEDIR/logs/viewer.log 2>&1
