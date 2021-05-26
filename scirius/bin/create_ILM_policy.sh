#!/bin/bash

while true
do
  ELASTICSEARCH_ADDRESS=$(python manage.py diffsettings --all |grep 'ELASTICSEARCH_ADDRESS' | cut -d"'" -f 2)
  echo "found elastic address : $ELASTICSEARCH_ADDRESS"
  response=$(curl -X PUT "$ELASTICSEARCH_ADDRESS/_ilm/policy/logstash-autodelete?pretty" -H 'Content-Type: application/json' -d'
  {
    "policy": {
      "phases": {
        "hot": {
          "actions": {
            "set_priority": {
              "priority": 100
            }
          },
          "min_age": "0ms"
        },
        "delete": {
          "min_age": "14d",
          "actions": {
            "delete": {}
          }
        }
      }
    }
  }
 ')
 
  if [[ $response == *"\"acknowledged\" : true"* ]]; then
    echo "ILM policy set"
    break
  else
    echo "ILM policy :"
    echo $response
    sleep 5
  fi
done


while true
do
  response=$(curl -X PUT "$ELASTICSEARCH_ADDRESS/_template/logstash-with-ilm?pretty" -H 'Content-Type: application/json' -d'
  {
    "index_patterns": ["logstash-*"],
    "order": 100,
    "settings": {
      "index.lifecycle.name": "logstash-autodelete"
    }
  }
  ')
 
  if [[ $response == *"\"acknowledged\" : true"* ]]; then
    echo "logstash template for ILM set"
    break
  else
    echo "logstash template :"
    echo $response
    sleep 5
  fi
 
done

