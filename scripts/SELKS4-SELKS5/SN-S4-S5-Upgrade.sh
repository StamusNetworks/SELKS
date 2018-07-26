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

# make place holder for all pre upgrade configs that have been overwritten 
mkdir -p /opt/selks/preupgrade

/bin/systemctl stop elasticsearch
/bin/systemctl stop kibana
/bin/systemctl stop logstash
/bin/systemctl stop suricata
/usr/bin/supervisorctl stop scirius

# ELK 6 upgrade prep

sed -i 's/ELASTICSEARCH_VERSION = 5/ELASTICSEARCH_VERSION = 6/g' /etc/scirius/local_settings.py

#todo
if [ -f /etc/apt/sources.list.d/elastic-6.x.list ];
then
    
    # if the filename exists - make sure we don't overwrite.
    mv /etc/apt/sources.list.d/elastic-6.x.list /opt/selks/preupgrade/elastic-6.x.list.orig
    
fi

cat >> /etc/apt/sources.list.d/elastic-6.x.list <<EOF
deb https://artifacts.elastic.co/packages/6.x/apt stable main
EOF

#todo
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


cat >> /etc/systemd/system/molochpcapread-selks.service <<EOF
[Unit]
Description=Moloch Pcap Read
After=network.target
#Requires=network.target

#After=network.target elasticsearch.service
#Requires=network.target elasticsearch.service

[Service]
Type=simple
#Restart=on-failure
StandardOutput=tty
#ExecStartPre=-/data/moloch/bin/moloch_config_interfaces.sh
ExecStart=/bin/sh -c '/data/moloch/bin/moloch-capture -c /data/moloch/etc/config.ini -m -s -R /data/nsm/  >> /data/moloch/logs/capture.log 2>&1'
WorkingDirectory=/data/moloch
LimitCORE=infinity
Restart=always
RestartSec=90
StartLimitInterval=600
StartLimitBurst=4

[Install]
WantedBy=multi-user.target
EOF

cat >> /etc/systemd/system/molochviewer-selks.service << EOF
[Unit]
Description=Moloch Viewer
After=network.target

[Service]
Type=simple
#Restart=on-failure
StandardOutput=tty
ExecStart=/bin/sh -c '/data/moloch/bin/node viewer.js -c /data/moloch/etc/config.ini >> /data/moloch/logs/viewer.log 2>&1'
WorkingDirectory=/data/moloch/viewer
Restart=always
RestartSec=90
StartLimitInterval=600
StartLimitBurst=4

[Install]
WantedBy=multi-user.target
EOF

#Moloch deps

mkdir -p /opt/molochtmp
cd /opt/molochtmp/ && \
apt-get update && apt-get install -y libjson-perl libyaml-dev libcrypto++6
wget http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u8_amd64.deb
dpkg -i libssl1.0.0_1.0.1t-1+deb8u8_amd64.deb

wget https://files.molo.ch/builds/ubuntu-14.04/moloch_1.1.1-1_amd64.deb
dpkg -i moloch_1.1.1-1_amd64.deb
#apt-get install ./moloch_1.1.1-1_amd64.deb -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew"

/data/moloch/db/db.pl http://localhost:9200 init
# get some default answers so we generate all needed configs for Moloch
printf '\n\n\nno\n' | /data/moloch/bin/Configure

/data/moloch/bin/moloch_add_user.sh admin "Admin User" selks-user --admin

# clean up the downloaded deb pkgs
rm /opt/molochtmp -r

# Set up Moloch pcap reader ini for SELKS
# this conf file is then used for - /data/moloch/etc/config.ini

#todo
if [ -f /data/moloch/etc/molochpcapread-selks-config.ini ];
then
    
    # if the filename exists - make sure we don't overwrite.
    mv /data/moloch/etc/molochpcapread-selks-config.ini /opt/molochpcapread-selks-config.ini
    
fi

cat >> /data/moloch/etc/molochpcapread-selks-config.ini <<EOF
# Latest settings documentation: https://github.com/aol/moloch/wiki/Settings
#
# Moloch uses a tiered system for configuration variables.  This allows Moloch
# to share one config file for many machines.  The ordering of sections in this
# file doesn't matter.
#
# Order of config variables:
# 1st) [optional] The section titled with the node name is used first.
#      Moloch will always tag sessions with node:<node name>
# 2nd) [optional] If a node has a nodeClass variable, the section titled with
#      the nodeClass name is used next.  Sessions will be tagged with
#      node:<node class name> which is useful if watching different
#      network classes.
# 3rd) The section titled "default" is used last.

[default]
# Comma seperated list of elasticsearch host:port combinations.  If not using a
# elasticsearch VIP, a different elasticsearch node in the cluster can be specified
# for each Moloch node to help spread load on high volume clusters
elasticsearch=http://localhost:9200

# How often to create a new elasticsearch index. hourly,hourly6,daily,weekly,monthly
# Changing the value will cause previous sessions to be unreachable
rotateIndex=daily

# Cert file to use, comment out to use http instead
# certFile=/data/moloch/etc/moloch.cert
certFile=/etc/nginx/ssl/scirius.crt

# File with trusted roots/certs. WARNING! this replaces default roots
# Useful with self signed certs and can be set per node.
# caTrustFile=/data/moloch/etc/roots.cert

# Private key file to use, comment out to use http instead
# keyFile=/data/moloch/etc/moloch.key
keyFile=/etc/nginx/ssl/scirius.key

# Password Hash and S2S secret - Must be in default section. Since elasticsearch
# is wide open by default, we encrypt the stored password hashes with this
# so a malicous person can't insert a working new account.  It is also used
# for secure S2S communication. Comment out for no user authentication.
# Changing the value will make all previously stored passwords no longer work.
# Make this RANDOM, you never need to type in
passwordSecret = no

# Use a different password for S2S communication then passwordSecret.
# Must be in default section.  Make this RANDOM, you never need to type in
#serverSecret=

# HTTP Digest Realm - Must be in default section.  Changing the value
# will make all previously stored passwords no longer work
httpRealm = Moloch

# The base path for Moloch web access.  Must end with a / or bad things will happen
# Default: "/"
# webBasePath = /moloch/

# Semicolon ';' seperated list of interfaces to listen on for traffic
interface=enp0s3

# The bpf filter of traffic to ignore
#bpf=not port 9200

# The yara file name
#yara=

# Host to connect to for wiseService
#wiseHost=127.0.0.1

# Log viewer access requests to a different log file
#accessLogFile = /data/moloch/logs/access.log

# The directory to save raw pcap files to
pcapDir = /data/moloch/raw

# The max raw pcap file size in gigabytes, with a max value of 36G.
# The disk should have room for at least 10*maxFileSizeG
maxFileSizeG = 12

# The max time in minutes between rotating pcap files.  Default is 0, which means
# only rotate based on current file size and the maxFileSizeG variable
#maxFileTimeM = 60

# TCP timeout value.  Moloch writes a session record after this many seconds
# of inactivity.
tcpTimeout = 600

# Moloch writes a session record after this many seconds, no matter if
# active or inactive
tcpSaveTimeout = 720

# UDP timeout value.  Moloch assumes the UDP session is ended after this
# many seconds of inactivity.
udpTimeout = 30

# ICMP timeout value.  Moloch assumes the ICMP session is ended after this
# many seconds of inactivity.
icmpTimeout = 10

# An aproximiate maximum number of active sessions Moloch/libnids will try
# and monitor
maxStreams = 1000000

# Moloch writes a session record after this many packets
maxPackets = 10000

# Delete pcap files when free space is lower then this in gigabytes OR it can be
# expressed as a percentage (ex: 5%).  This does NOT delete the session records in
# the database. It is recommended this value is between 5% and 10% of the disk.
# Database deletes are done by the db.pl expire script
freeSpaceG = 5%

# The port to listen on, by default 8005
viewPort = 8005

# The host/ip to listen on, by default 0.0.0.0 which is ALL
#viewHost = localhost

# By default the viewer process is https://hostname:<viewPort> for each node.
#viewUrl = https://HOSTNAME:8005

# Path of the maxmind geoip country file.  Download free version from:
#  https://updates.maxmind.com/app/update_secure?edition_id=GeoLite2-Country
geoLite2Country = /data/moloch/etc/GeoLite2-Country.mmdb

# Path of the maxmind geoip ASN file.  Download free version from:
#  https://updates.maxmind.com/app/update_secure?edition_id=GeoLite2-ASN
geoLite2ASN = /data/moloch/etc/GeoLite2-ASN.mmdb

# Path of the rir assignments file
#  https://www.iana.org/assignments/ipv4-address-space/ipv4-address-space.csv
rirFile = /data/moloch/etc/ipv4-address-space.csv

# Path of the OUI file from whareshark
#  https://raw.githubusercontent.com/wireshark/wireshark/master/manuf
ouiFile = /data/moloch/etc/oui.txt

# User to drop privileges to. The pcapDir must be writable by this user or group below
dropUser=nobody

# Group to drop privileges to. The pcapDir must be writable by this group or user above
dropGroup=daemon

# Semicolon ';' seperated list of tags which once capture sets for a session causes the
# remaining pcap from being saved for the session.  It is likely that the initial packets
# WILL be saved for the session since tags usually aren't set until after several packets
# Each tag can optionally be followed by a :<num> which specifies how many total packets to save
#dontSaveTags=

# Header to use for determining the username to check in the database for instead of
# using http digest.  Use this if apache or something else is doing the auth.
# Set viewHost to localhost or use iptables
# Might need something like this in the httpd.conf
# RewriteRule .* - [E=ENV_RU:%{REMOTE_USER}]
# RequestHeader set MOLOCH_USER %{ENV_RU}e
#userNameHeader=moloch_user

# Should we parse extra smtp traffic info
parseSMTP=true

# Should we parse extra smb traffic info
parseSMB=true

# Should we parse HTTP QS Values
parseQSValue=false

# Should we calculate sha256 for bodies
supportSha256=false

# Only index HTTP request bodies less than this number of bytes */
maxReqBody=64

# Only store request bodies that Utf-8?
config.reqBodyOnlyUtf8 = true

# Semicolon ';' seperated list of SMTP Headers that have ips, need to have the terminating colon ':'
smtpIpHeaders=X-Originating-IP:;X-Barracuda-Apparent-Source-IP:

# Semicolon ';' seperated list of directories to load parsers from
parsersDir=/data/moloch/parsers

# Semicolon ';' seperated list of directories to load plugins from
pluginsDir=/data/moloch/plugins

# Semicolon ';' seperated list of plugins to load and the order to load in
# plugins=tagger.so; netflow.so

# Plugins to load as root, usually just readers
#rootPlugins=reader-pfring; reader-daq.so

# Semicolon ';' seperated list of viewer plugins to load and the order to load in
# viewerPlugins=wise.js

# NetFlowPlugin
# Input device id, 0 by default
#netflowSNMPInput=1
# Outout device id, 0 by default
#netflowSNMPOutput=2
# Netflow version 1,5,7 supported, 7 by default
#netflowVersion=1
# Semicolon ';' seperated list of netflow destinations
#netflowDestinations=localhost:9993

# Specify the max number of indices we calculate spidata for.
# ES will blow up if we allow the spiData to search too many indices.
spiDataMaxIndices=4

# Uncomment the following to allow direct uploads.  This is experimental
#uploadCommand=/data/moloch/bin/moloch-capture --copy -n {NODE} -r {TMPFILE} -c {CONFIG} {TAGS}

# Title Template
# _cluster_ = ES cluster name
# _userId_  = logged in User Id
# _userName_ = logged in User Name
# _page_ = internal page name
# _expression_ = current search expression if set, otherwise blank
# _-expression_ = " - " + current search expression if set, otherwise blank, prior spaces removed
# _view_ = current view if set, otherwise blank
# _-view_ = " - " + current view if set, otherwise blank, prior spaces removed
#titleTemplate=_cluster_ - _page_ _-view_ _-expression_

# Number of threads processing packets
packetThreads=2

# ADVANCED - Semicolon ';' seperated list of files to load for config.  Files are loaded
# in order and can replace values set in this file or previous files.
#includes=

# ADVANCED - How is pcap written to disk
#  simple          = use O_DIRECT if available, writes in pcapWriteSize chunks,
#                    a file per packet thread.
#  simple-nodirect = don't use O_DIRECT.  Required for zfs and others
pcapWriteMethod=simple

# ADVANCED - Buffer size when writing pcap files.  Should be a multiple of the raid 5 or xfs
# stripe size.  Defaults to 256k
pcapWriteSize = 262143

# ADVANCED - Number of bytes to bulk index at a time
dbBulkSize = 300000

# ADVANCED - Compress requests to ES, reduces ES bandwidth by ~80% at the cost
# of increased CPU. MUST have "http.compression: true" in elasticsearch.yml file
compressES = false

# ADVANCED - Max number of connections to elastic search
maxESConns = 30

# ADVANCED - Max number of es requests outstanding in q
maxESRequests = 500

# ADVANCED - Number of packets to ask libnids/libpcap to read per poll/spin
# Increasing may hurt stats and ES performance
# Decreasing may cause more dropped packets
packetsPerPoll = 50000

# ADVANCED - Moloch will try to compensate for SYN packet drops by swapping
# the source and destination addresses when a SYN-acK packet was captured first.
# Probably useful to set it false, when running Moloch in wild due to SYN floods.
antiSynDrop = true

# DEBUG - Write to stdout info every X packets.
# Set to -1 to never log status
logEveryXPackets = 100000

# DEBUG - Write to stdout unknown protocols
logUnknownProtocols = false

# DEBUG - Write to stdout elastic search requests
logESRequests = true

# DEBUG - Write to stdout file creation information
logFileCreation = true


### High Performance settings
# https://github.com/aol/moloch/wiki/Settings#High_Performance_Settings
# magicMode=basic
# pcapReadMethod=tpacketv3
# tpacketv3NumThreads=2
# pcapWriteMethod=simple
# pcapWriteSize = 2560000
# packetThreads=5
# maxPacketsInQueue = 200000

### Low Bandwidth settings
# packetThreads=1
# pcapWriteSize = 65536


##############################################################################
# Classes of nodes
# Can override most default values, and create a tag call node:<classname>
[class1]
freeSpaceG = 10%

##############################################################################
# Nodes
# Usually just use the hostname before the first dot as the node name
# Can override most default values

[node1]
nodeClass = class1
# Might use a different elasticsearch node
elasticsearch=elasticsearchhost1

# Uncomment if this node should process the cron queries, only ONE node should process cron queries
# cronQueries = true

[node2]
nodeClass = class2
# Might use a different elasticsearch node
elasticsearch=elasticsearchhost2
# Uses a different interface
interface = eth4

##############################################################################
# override-ips is a special section that overrides the MaxMind databases for
# the fields set, but fields not set will still use MaxMind (example if you set
# tags but not country it will use MaxMind for the country)
# Spaces and capitalization is very important.
# IP Can be a single IP or a CIDR
# Up to 10 tags can be added
#
# ip=tag:TAGNAME1;tag:TAGNAME2;country:3LetterUpperCaseCountry;asn:ASN STRING
#[override-ips]
#10.1.0.0/16=tag:ny-office;country:USA;asn:AS0000 This is an ASN

##############################################################################
# It is now possible to define in the config file extra http/email headers
# to index.  They are accessed using the expression http.<fieldname> and
# email.<fieldname> with optional .cnt expressions
#
# Possible config atributes for all headers
#   type:<string> (string|integer|ip)  = data type                (default string)
#  count:<boolean>                     = index count of items     (default false)
#  unique:<boolean>                    = only record unique items (default true)

# headers-http-request is used to configure request headers to index
#[headers-http-request]
#referer=type:string;count:true;unique:true

# headers-http-response is used to configure http response headers to index
#[headers-http-response]
#location=type:string;count:true

# headers-email is used to configure email headers to index
#[headers-email]
#x-priority=type:integer


##############################################################################
# If you have multiple clusters and you want the ability to send sessions
# from one cluster to another either manually or with the cron feature fill out
# this section

#[moloch-clusters]
#forensics=url:https://viewer1.host.domain:8005;passwordSecret:password4moloch;name:Forensics Cluster
#shortname2=url:http://viewer2.host.domain:8123;passwordSecret:password4moloch;name:Testing Cluster



# WARNING: This is an ini file with sections, most likely you don't want to put a setting here.
#          New settings usually go near the top in the [default] section, or in [nodename] sections.
EOF

cp -f /data/moloch/etc/config.ini /data/moloch/etc/config.ini.orig
cp -f /data/moloch/etc/molochpcapread-selks-config.ini /data/moloch/etc/config.ini

/bin/systemctl disable molochcapture.service
/bin/systemctl disable molochviewer.service

/bin/systemctl enable molochpcapread-selks.service
/bin/systemctl enable molochviewer-selks.service
/bin/systemctl daemon-reload
/bin/systemctl start molochpcapread-selks.service
/bin/systemctl restart molochviewer-selks.service

# make sure we hold the moloch pkg version unless explicit upgrade is wanted/needed
apt-mark hold moloch

# systemctl status suricata elasticsearch logstash kibana evebox molochviewer-selks molochpcapread-selks






