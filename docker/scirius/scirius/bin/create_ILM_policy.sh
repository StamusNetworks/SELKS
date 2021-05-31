#!/bin/bash

# Copyright(C) 2019, Stamus Networks
# All rights reserved
# Written by Raphaël Brogat <rbrogat@stamus-networks.com>
#
# Designed for Debian
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

