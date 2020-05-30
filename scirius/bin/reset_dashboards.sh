#!/bin/bash

cd /opt/scirius/

KIBANA_LOADED="/data/kibana_dashboards"

reset_dashboards() {
    for I in $(seq 0 20); do
        python manage.py kibana_reset 2>/dev/null && return 0
        echo "Kibana dashboards reset: Elasticsearch not ready, retrying in 10 seconds."
        sleep 10
    done
    return -1
}


if [ ! -e $KIBANA_LOADED ]; then
    reset_dashboards && touch $KIBANA_LOADED
fi
