#!/bin/bash

# Copyright(C) 2018, Stamus Networks
# All rights reserved
# Written by Laurent Defert <lds@stamus-networks.com>
#
# Please run on Debian
#
# This script comes with ABSOLUTELY NO WARRANTY!
# 


set -x

LOGFILE=/var/log/logstash-migration.log
ERRFILE=/var/log/logstash-migration-error.log
ELASTICSEARCH=http://localhost:9200
IDXFILE=/.reindex
TODAY="$(cat "$IDXFILE")"

if [ "$TODAY" == "" ]
then
    date "+%Y.%m.%d" > /.reindex
    TODAY="$(cat "$IDXFILE")"
fi

function curl_es()
{
    curl --silent --show-error "$@" 2>&1
    return $?
}

function curl_simple()
{
    res="$(curl_es "$@")"
    if [ $? != 0 ]
    then
        return 1
    fi
        if [ "$(jq .acknowledged <<< "$res")" != true ]
    then
        return 1
    fi
}

function reindex()
{
    index="$1"
    echo -n "Reindexing $index... " >> $LOGFILE
    size="$(curl_es "$ELASTICSEARCH/$index/_stats/store" | jq ._all.total.store.size_in_bytes)"
    free="$(curl_es "$ELASTICSEARCH/_cluster/stats" | jq .nodes.fs.available_in_bytes)"

    if [ "$size" == "" ] || [ "$free" == "" ]
    then
        echo "Cannot parse disk space for index $index" >> $ERRFILE
        echo "failed" >> $LOGFILE
        return 1
    fi

    if [ "$size" -gt "$free" ]
    then
        echo "Not enough space available for index $index ($size > $free)" >> $ERRFILE
        echo "failed" >> $LOGFILE
        return 1
    fi

    res="$(curl_es -XPOST -H 'Content-Type: application/json' "$ELASTICSEARCH/_reindex" -d '
        {
          "conflicts": "proceed",
          "source": {
            "index": "'"$index"'"
          },
          "dest": {
            "index": "'"$index-1"'",
            "op_type": "create"
          }
        }')"
    status=$?

    failures="$(echo "$res" | jq -r '.failures | .[] | ([.index, .cause.type, ":", .cause.reason] | join(" "))')"

    if [ "$failures" != "" ]
    then
        echo "Failures occured while reindexing $index:" >> $ERRFILE
        echo "$failures" >> $ERRFILE
        status=1
    fi

    if [ "$status" == 0 ]
    then
        curl_simple -XDELETE "$ELASTICSEARCH/$index"
        echo "ok" >> $LOGFILE
    else
        echo "Reindexing $index failed" >> $ERRFILE
        echo "failed" >> $LOGFILE
    fi
    return $status
}

echo "Reindex start: $(date)"

if [ "$1" == "today" ]
then
    # Lookup today indices
    ret=0
    for index in $(curl $ELASTICSEARCH/_cat/indices | grep '^green \+open \+logstash-' | awk '{print $3}' | grep "$TODAY$")
    do
        reindex "$index" || ret=1
    done
    exit $ret
else
    today_nbr="$(tr -d . <<< "$TODAY")"
    ret=0
    for index in $(curl $ELASTICSEARCH/_cat/indices | grep '^green \+open \+logstash-\([a-z]\+-\)\?[0-9]\{4\}\.[0-9]\{2\}\.[0-9]\{2\} ' | awk '{print $3}' | sort -r -s -t - -k3)
    do
        date="$(sed -e 's/^.*-//' <<< "$index" | tr -d .)"
        if [ "$date" -lt "$today_nbr" ]
        then
            reindex "$index" || ret=1
        fi
    done
    if [ "$ret" == 0 ] && [ "$1" == 0 ]
    then
        rm $IDXFILE
    fi
    echo Done >> $LOGFILE
fi

echo "Reindex end: $(date)"
