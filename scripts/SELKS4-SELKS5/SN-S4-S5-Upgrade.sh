#!/bin/bash

# Copyright(C) 2018, Stamus Networks
# All rights reserved
# Written by Peter Manev <pmanev@stamus-networks.com>
#
# Please run on Debian
#
# This script comes with ABSOLUTELY NO WARRANTY!
# 

# exit on error
set -ex

if (( $EUID != 0 )); then
     echo -e "Please run this script as root or with \"sudo\".\n"
     exit 1
fi

# make place holder for all pre upgrade configs that have been overwritten 
mkdir -p /opt/selks/preupgrade

/bin/systemctl stop elasticsearch
/bin/systemctl stop kibana
/bin/systemctl stop logstash
/bin/systemctl stop suricata
/usr/bin/supervisorctl stop scirius

# ELK 6 upgrade prep

sed -i 's/ELASTICSEARCH_VERSION = 5/ELASTICSEARCH_VERSION = 6/g' /etc/scirius/local_settings.py
sed -i 's/KIBANA_VERSION=4/KIBANA_VERSION = 6/g' /etc/scirius/local_settings.py
sed -i 's/KIBANA_INDEX = "kibana-int"/KIBANA_INDEX = ".kibana"/g' /etc/scirius/local_settings.py
sed -i 's/KIBANA_DASHBOARDS_PATH = "\/opt\/selks\/kibana5-dashboards\/"/KIBANA_DASHBOARDS_PATH = "\/opt\/selks\/kibana6-dashboards\/"/g' /etc/scirius/local_settings.py
echo "ELASTICSEARCH_KEYWORD = \"keyword\"" >> /etc/scirius/local_settings.py


#todo
if [ -f /etc/apt/sources.list.d/elastic-6.x.list ];
then
    
    # if the filename exists - make sure we don't overwrite.
    mv /etc/apt/sources.list.d/elastic-6.x.list /opt/selks/preupgrade/elastic-6.x.list.orig
    
fi

cat >> /etc/apt/sources.list.d/elastic-6.x.list <<EOF
deb https://artifacts.elastic.co/packages/6.x/apt stable main
EOF

if [ -f /etc/apt/sources.list.d/curator5.list ];
then
    
    # if the filename exists - make sure we don't overwrite.
    mv /etc/apt/sources.list.d/curator5.list /opt/selks/preupgrade/curator5.list.orig
    
fi

cat >> /etc/apt/sources.list.d/curator5.list <<EOF
deb [arch=amd64] https://packages.elastic.co/curator/5/debian9 stable main
EOF

if [ -f /etc/nginx/sites-available/default ];
then
    
    # if the filename exists - make sure we don't overwrite.
    mv /etc/nginx/sites-available/default /opt/selks/preupgrade/default-nginx
    
fi

rm -rf /etc/nginx/sites-enabled/default

if [ -f /etc/nginx/sites-available/selks4.conf ];
then
    
    # if the filename exists - make sure we don't overwrite.
    mv /etc/nginx/sites-available/selks4.conf /opt/selks/preupgrade/selks4.conf
    
fi

rm -rf /etc/nginx/sites-available/selks4.conf
rm -rf /etc/nginx/sites-enabled/selks4.conf

if [ -f /etc/nginx/sites-available/selks5.conf ];
then
    
    # if the filename exists - make sure we don't overwrite.
    mv /etc/nginx/sites-available/selks5.conf /opt/selks/preupgrade/selks5.conf
    
fi


cat >> /etc/nginx/sites-available/selks5.conf <<EOF
server {
    listen 127.0.0.1:80;
    listen 127.0.1.1:80;
    listen 443 default_server ssl;
    ssl_certificate /etc/nginx/ssl/scirius.crt;
    ssl_certificate_key /etc/nginx/ssl/scirius.key;
    server_name SELKS;
    access_log /var/log/nginx/scirius.access.log;
    error_log /var/log/nginx/scirius.error.log;

    # https://docs.djangoproject.com/en/dev/howto/static-files/#serving-static-files-in-production
    location /static/ { # STATIC_URL
        alias /var/lib/scirius/static/; # STATIC_ROOT
        expires 30d;
    }

    location /media/ { # MEDIA_URL
        alias /var/lib/scirius/static/; # MEDIA_ROOT
        expires 30d;
    }

    location /app/moloch/ {
        proxy_pass https://127.0.0.1:8005;
        proxy_redirect off;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_read_timeout 600;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect off;
    }

}
EOF

# enable sites
ln -s /etc/nginx/sites-available/selks5.conf /etc/nginx/sites-enabled/selks5.conf
/bin/systemctl restart nginx

if [ -f /etc/logstash/conf.d/logstash.conf ];
then
    
    # if the filename exists - make sure we don't overwrite.
    mv /etc/logstash/conf.d/logstash.conf /opt/selks/preupgrade/logstash.conf.orig
    
fi

cat >> /etc/logstash/conf.d/logstash.conf  <<EOF
input {
  file { 
    path => ["/var/log/suricata/*.json"]
    #sincedb_path => ["/var/lib/logstash/"]
    sincedb_path => ["/var/cache/logstash/sincedbs/since.db"]
    codec =>   json 
    type => "SELKS" 
  }

}

filter {
  if [type] == "SELKS" {
    
    date {
      match => [ "timestamp", "ISO8601" ]
    }
    
    ruby {
      code => "
        if event.get('[event_type]') == 'fileinfo'
          event.set('[fileinfo][type]', event.get('[fileinfo][magic]').to_s.split(',')[0])
        end
      "
    }
    ruby {
      code => "
        if event.get('[event_type]') == 'alert'
          sp = event.get('[alert][signature]').to_s.split(' group ')
          if (sp.length == 2) and /\A\d+\z/.match(sp[1])
            event.set('[alert][signature]', sp[0])
          end
        end
      "
     }
  
    metrics {
      meter => [ "eve_insert" ]
      add_tag => "metric"
      flush_interval => 30
    }
  }

  if [http] {
    useragent {
       source => "[http][http_user_agent]"
       target => "[http][user_agent]"
    }
  }
  if [src_ip]  {
    geoip {
      source => "src_ip" 
      target => "geoip" 
      #database => "/opt/logstash/vendor/geoip/GeoLiteCity.dat" 
      #add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
      #add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}"  ]
    }
  }
    if [dest_ip]  {
    geoip {
      source => "dest_ip" 
      target => "geoip" 
      #database => "/opt/logstash/vendor/geoip/GeoLiteCity.dat" 
      #add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
      #add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}"  ]
    }
  }
}

output {
  if [event_type] and [event_type] != 'stats' {
    elasticsearch {
      hosts => "127.0.0.1"
      index => "logstash-%{event_type}-%{+YYYY.MM.dd}"
      template_overwrite => true
      template => "/etc/logstash/elasticsearch6-template.json"
    }
  } else {
    elasticsearch {
      hosts => "127.0.0.1"
      index => "logstash-%{+YYYY.MM.dd}"
      template_overwrite => true
      template => "/etc/logstash/elasticsearch6-template.json"
    }
  }
}
EOF

#todo
if [ -f /etc/logstash/elasticsearch6-template.json ];
then
    
    # if the filename exists - make sure we don't overwrite.
    mv /etc/logstash/elasticsearch6-template.json /opt/selks/preupgrade/elasticsearch6-template.json
    
fi

cat >> /etc/logstash/elasticsearch6-template.json <<EOF 

{
  "template" : "logstash-*",
  "version" : 60001,
  "settings" : {
    "number_of_replicas": 0,
    "index.refresh_interval" : "5s"
  },
  "mappings" : {
    "_default_" : {
      "dynamic_templates" : [ {
        "message_field" : {
          "path_match" : "message",
          "match_mapping_type" : "string",
          "mapping" : {
            "type" : "text",
            "norms" : false
          }
        }
      }, {
        "string_fields" : {
          "match" : "*",
          "match_mapping_type" : "string",
          "mapping" : {
            "type" : "text", "norms" : false,
            "fields" : {
              "keyword" : { "type": "keyword", "ignore_above": 256 }
            }
          }
        }
      } ],
      "properties" : {
        "@timestamp": { "type": "date"},
        "@version": { "type": "keyword"},
        "geoip"  : {
          "dynamic": true,
          "properties" : {
            "ip": { "type": "ip" },
            "location" : { "type" : "geo_point" },
            "latitude" : { "type" : "half_float" },
            "longitude" : { "type" : "half_float" }
          }
        }
      }
    }
  }
}
EOF

#todo
if [ -f /etc/apt/sources.list.d/selks5.list ];
then
    
    # if the filename exists - make sure we don't overwrite.
    mv /etc/apt/sources.list.d/selks5.list /opt/selks/preupgrade/selks5.list.orig
    
fi
cat >> /etc/apt/sources.list.d/selks5.list <<EOF
# SELKS5 Stamus Networks repos
#
# Manual changes here can be overwritten during 
# SELKS updates and upgrades
deb http://packages.stamus-networks.com/selks5/debian/ stretch main
deb http://packages.stamus-networks.com/selks5/debian-kernel/ stretch main
#deb http://packages.stamus-networks.com/selks5/debian-test/ stretch main
EOF

wget -qO - http://packages.stamus-networks.com/packages.selks5.stamus-networks.com.gpg.key | apt-key add - 

/bin/systemctl stop kibana

apt-get update && apt-get -y dist-upgrade -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew"

chown -R kibana /usr/share/kibana/optimize/

/bin/systemctl restart elasticsearch
/bin/systemctl restart kibana
/usr/share/logstash/bin/logstash-plugin install logstash-filter-geoip
/bin/systemctl restart logstash

#make sure Suricata can write in /data/nsm
chown logstash -R /data/nsm/

/bin/systemctl restart suricata
/usr/bin/supervisorctl restart scirius 

sleep 30

curl -X PUT "localhost:9200/.kibana-6" -H 'Content-Type: application/json' -d'
{
  "settings" : {
    "number_of_shards" : 1,
    "number_of_replicas": 0,
    "index.mapper.dynamic": false
  },
  "mappings" : {
    "doc": {
      "properties": {
        "type": {
          "type": "keyword"
        },
        "updated_at": {
          "type": "date"
        },
        "config": {
          "properties": {
            "buildNum": {
              "type": "keyword"
            }
          }
        },
        "index-pattern": {
          "properties": {
            "fieldFormatMap": {
              "type": "text"
            },
            "fields": {
              "type": "text"
            },
            "intervalName": {
              "type": "keyword"
            },
            "notExpandable": {
              "type": "boolean"
            },
            "sourceFilters": {
              "type": "text"
            },
            "timeFieldName": {
              "type": "keyword"
            },
            "title": {
              "type": "text"
            }
          }
        },
        "visualization": {
          "properties": {
            "description": {
              "type": "text"
            },
            "kibanaSavedObjectMeta": {
              "properties": {
                "searchSourceJSON": {
                  "type": "text"
                }
              }
            },
            "savedSearchId": {
              "type": "keyword"
            },
            "title": {
              "type": "text"
            },
            "uiStateJSON": {
              "type": "text"
            },
            "version": {
              "type": "integer"
            },
            "visState": {
              "type": "text"
            }
          }
        },
        "search": {
          "properties": {
            "columns": {
              "type": "keyword"
            },
            "description": {
              "type": "text"
            },
            "hits": {
              "type": "integer"
            },
            "kibanaSavedObjectMeta": {
              "properties": {
                "searchSourceJSON": {
                  "type": "text"
                }
              }
            },
            "sort": {
              "type": "keyword"
            },
            "title": {
              "type": "text"
            },
            "version": {
              "type": "integer"
            }
          }
        },
        "dashboard": {
          "properties": {
            "description": {
              "type": "text"
            },
            "hits": {
              "type": "integer"
            },
            "kibanaSavedObjectMeta": {
              "properties": {
                "searchSourceJSON": {
                  "type": "text"
                }
              }
            },
            "optionsJSON": {
              "type": "text"
            },
            "panelsJSON": {
              "type": "text"
            },
            "refreshInterval": {
              "properties": {
                "display": {
                  "type": "keyword"
                },
                "pause": {
                  "type": "boolean"
                },
                "section": {
                  "type": "integer"
                },
                "value": {
                  "type": "integer"
                }
              }
            },
            "timeFrom": {
              "type": "keyword"
            },
            "timeRestore": {
              "type": "boolean"
            },
            "timeTo": {
              "type": "keyword"
            },
            "title": {
              "type": "text"
            },
            "uiStateJSON": {
              "type": "text"
            },
            "version": {
              "type": "integer"
            }
          }
        },
        "url": {
          "properties": {
            "accessCount": {
              "type": "long"
            },
            "accessDate": {
              "type": "date"
            },
            "createDate": {
              "type": "date"
            },
            "url": {
              "type": "text",
              "fields": {
                "keyword": {
                  "type": "keyword",
                  "ignore_above": 2048
                }
              }
            }
          }
        },
        "server": {
          "properties": {
            "uuid": {
              "type": "keyword"
            }
          }
        },
        "timelion-sheet": {
          "properties": {
            "description": {
              "type": "text"
            },
            "hits": {
              "type": "integer"
            },
            "kibanaSavedObjectMeta": {
              "properties": {
                "searchSourceJSON": {
                  "type": "text"
                }
              }
            },
            "timelion_chart_height": {
              "type": "integer"
            },
            "timelion_columns": {
              "type": "integer"
            },
            "timelion_interval": {
              "type": "keyword"
            },
            "timelion_other_interval": {
              "type": "keyword"
            },
            "timelion_rows": {
              "type": "integer"
            },
            "timelion_sheet": {
              "type": "text"
            },
            "title": {
              "type": "text"
            },
            "version": {
              "type": "integer"
            }
          }
        },
        "graph-workspace": {
          "properties": {
            "description": {
              "type": "text"
            },
            "kibanaSavedObjectMeta": {
              "properties": {
                "searchSourceJSON": {
                  "type": "text"
                }
              }
            },
            "numLinks": {
              "type": "integer"
            },
            "numVertices": {
              "type": "integer"
            },
            "title": {
              "type": "text"
            },
            "version": {
              "type": "integer"
            },
            "wsState": {
              "type": "text"
            }
          }
        }
      }
    }
  }
}
'

curl -X POST "localhost:9200/_reindex" -H 'Content-Type: application/json' -d'
{
  "source": {
    "index": ".kibana"
  },
  "dest": {
    "index": ".kibana-6"
  },
  "script": {
    "inline": "ctx._source = [ ctx._type : ctx._source ]; ctx._source.type = ctx._type; ctx._id = ctx._type + \":\" + ctx._id; ctx._type = \"doc\"; ",
    "lang": "painless"
  }
}
'

curl -X POST "localhost:9200/_aliases" -H 'Content-Type: application/json' -d'
{
  "actions" : [
    { "add":  { "index": ".kibana-6", "alias": ".kibana" } },
    { "remove_index": { "index": ".kibana" } }
  ]
}
'

# Install elasticsearch-curator
apt-get update && apt-get -y install elasticsearch-curator

# Install Moloch
mkdir -p /opt/molochtmp
cd /opt/molochtmp/ && \
apt-get -y install libjson-perl libyaml-dev libcrypto++6
wget https://files.molo.ch/builds/ubuntu-18.04/moloch_1.6.2-1_amd64.deb
dpkg -i moloch_1.6.2-1_amd64.deb


cd /opt/
# clean up the downloaded deb pkgs
rm /opt/molochtmp -r

# make sure we hold the moloch pkg version unless explicit upgrade is wanted/needed
apt-mark hold moloch

# Set up a daily clean up cron job for Moloch
echo "0 3 * * * root ( /data/moloch/db/db.pl http://127.0.0.1:9200 expire daily 14 )" >> /etc/crontab

/usr/bin/selks-molochdb-init-setup_stamus.sh
# systemctl status suricata elasticsearch logstash kibana evebox molochviewer-selks molochpcapread-selks

# reset and reload the new KTS6 dashboards
cd /usr/share/python/scirius/ && . bin/activate && python bin/manage.py kibana_reset && deactivate && cd /opt 






