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
#set -ex
set -x

if (( $EUID != 0 )); then
     echo -e "Please run this script as root or with \"sudo\".\n"
     exit 1
fi

# make place holder for all pre upgrade configs that have been overwritten 
mkdir -p /opt/selks/preupgrade
mkdir -p /opt/selks/preupgrade/elasticsearch/etc/elasticsearch
mkdir -p /opt/selks/preupgrade/elasticsearch/etc/default/

mv /etc/alternatives/desktop-background  /opt/selks/preupgrade

/bin/systemctl stop elasticsearch
/bin/systemctl stop kibana
/bin/systemctl stop logstash
/bin/systemctl stop suricata
/usr/bin/supervisorctl stop scirius

# ELK 6 upgrade prep

if [ -f /etc/apt/sources.list.d/elastic-6.x.list ];
then
    
    # if the filename exists - make sure we don't overwrite.
    mv /etc/apt/sources.list.d/elastic-6.x.list /opt/selks/preupgrade/elastic-6.x.list.orig
    
fi

cat >> /etc/apt/sources.list.d/elastic-7.x.list <<EOF
deb https://artifacts.elastic.co/packages/7.x/apt stable main
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

if [ -f /etc/nginx/sites-available/selks5.conf ];
then
    
    # if the filename exists - make sure we don't overwrite.
    mv /etc/nginx/sites-available/selks5.conf /opt/selks/preupgrade/selks5.conf
    
fi

rm -rf /etc/nginx/sites-available/selks5.conf
rm -rf /etc/nginx/sites-enabled/selks5.conf

if [ -f /etc/nginx/sites-available/selks5.conf ];
then
    
    # if the filename exists - make sure we don't overwrite.
    mv /etc/nginx/sites-available/selks5.conf /opt/selks/preupgrade/selks5.conf
    rm /etc/nginx/sites-enabled/selks5.conf
fi


cat >> /etc/nginx/sites-available/selks6.conf <<EOF
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

    location /plugins/ {
        proxy_pass http://127.0.0.1:5601/plugins/;
        proxy_redirect off;
    }

    location /dlls/ {
        proxy_pass http://127.0.0.1:5601/dlls/;
        proxy_redirect off;
    }

    location /socket.io/ {
        proxy_pass http://127.0.0.1:5601/socket.io/;
        proxy_redirect off;
    }

    location /dataset/ {
        proxy_pass http://127.0.0.1:5601/dataset/;
        proxy_redirect off;
    }

    location /translations/ {
        proxy_pass http://127.0.0.1:5601/translations/;
        proxy_redirect off;
    }

    location ^~ /built_assets/ {
        proxy_pass http://127.0.0.1:5601/built_assets/;
        proxy_redirect off;
    }

    location /ui/ {
        proxy_pass http://127.0.0.1:5601/ui/;
        proxy_redirect off;
    }

   location /spaces/ {
        proxy_pass http://127.0.0.1:5601/spaces/;
        proxy_redirect off;
    }

  location /node_modules/ {
        proxy_pass http://127.0.0.1:5601/node_modules/;
        proxy_redirect off;
    }

  location /internal/ {
        proxy_pass http://127.0.0.1:5601/internal/;
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
ln -s /etc/nginx/sites-available/selks6.conf /etc/nginx/sites-enabled/selks6.conf

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
      template => "/etc/logstash/elasticsearch7-template.json"
    }
  } else {
    elasticsearch {
      hosts => "127.0.0.1"
      index => "logstash-%{+YYYY.MM.dd}"
      template_overwrite => true
      template => "/etc/logstash/elasticsearch7-template.json"
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

cat >> /etc/logstash/elasticsearch7-template.json <<EOF 
{
  "template" : "logstash-*",
  "version" : 60001,
  "settings" : {
    "number_of_replicas": 0,
    "index.refresh_interval" : "5s"
  },
  "mappings" : {
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
EOF

#todo
if [ -f /etc/apt/sources.list.d/selks5.list ];
then
    
    # if the filename exists - make sure we don't overwrite.
    mv /etc/apt/sources.list.d/selks5.list /opt/selks/preupgrade/selks5.list.orig
    
fi
cat >> /etc/apt/sources.list.d/selks6.list <<EOF
# SELKS5 Stamus Networks repos
#
# Manual changes here can be overwritten during 
# SELKS updates and upgrades
deb http://packages.stamus-networks.com/selks6/debian/ buster main
deb http://packages.stamus-networks.com/selks6/debian-kernel/ buster main
#deb http://packages.stamus-networks.com/selks6/debian-test/ buster main
EOF

wget -qO - http://packages.stamus-networks.com/packages.selks6.stamus-networks.com.gpg.key | apt-key add - 

/bin/systemctl stop kibana

if [ -f /usr/lib/systemd/system/elasticsearch.service ];
then
    
  cp /usr/lib/systemd/system/elasticsearch.service /opt/selks/preupgrade/elasticsearch.service.orig
 
fi 

cp -r /etc/elasticsearch/* /opt/selks/preupgrade/elasticsearch/etc/
cp /etc/default/elasticsearch /opt/selks/preupgrade/elasticsearch/etc/default/

sed -i 's/stretch/buster/g' /etc/apt/sources.list


#apt-get update && apt-get -o Dpkg::Options::="--force-confnew"  -y dist-upgrade
apt-get update && \
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -y dist-upgrade

exit_status=$?
if [[ ${exit_status} -ne 0 ]]; then
rm -f /var/lib/dpkg/info/python-minimal* ; rm -f /var/lib/dpkg/info/python2-minimal* ;
apt --fix-broken -y install
apt-get update && \
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -y dist-upgrade
fi

chown root:elasticsearch /etc/default/elasticsearch

if [ -f /usr/lib/systemd/system/elasticsearch.service.dpkg-new ];
then
    
  mv /usr/lib/systemd/system/elasticsearch.service.dpkg-new /usr/lib/systemd/system/elasticsearch.service
 
fi 

if [ -f /etc/default/elasticsearch.dpkg-new ];
then
    
  mv /etc/default/elasticsearch.dpkg-new /etc/default/elasticsearch
 
fi 

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

# Install elasticsearch-curator
apt-get update && apt-get -y install elasticsearch-curator

# rm old curator start line
mv /opt/selks/delete-old-logs.sh /opt/selks/preupgrade/delete-old-logs.sh 

# create the new clean up
cat >> /opt/selks/delete-old-logs.sh <<EOF
#!/bin/bash

/usr/bin/curator_cli delete_indices --filter_list \
'
[
  {
    "filtertype": "age",
    "source": "creation_date",
    "direction": "older",
    "unit": "days",
    "unit_count": 14
  },
  {
    "filtertype": "pattern",
    "kind": "prefix",
    "value": "logstash*"
  }
]
'
EOF

# Install Moloch
mkdir -p /opt/molochtmp
cd /opt/molochtmp/ && \
apt-get -y install libwww-perl libjson-perl libyaml-dev libcrypto++6
wget https://files.molo.ch/builds/ubuntu-18.04/moloch_2.2.3-1_amd64.deb
dpkg -i moloch_2.2.3-1_amd64.deb

cd /opt/
# clean up the downloaded deb pkgs
rm /opt/molochtmp -r

# make sure we hold the moloch pkg version unless explicit upgrade is wanted/needed
apt-mark hold moloch

# Set up a daily clean up cron job for Moloch
echo "0 3 * * * root ( /data/moloch/db/db.pl http://127.0.0.1:9200 expire daily 14 )" >> /etc/crontab

# Scrius conf prep
sed -i 's/ELASTICSEARCH_VERSION = 6/ELASTICSEARCH_VERSION = 7/g' /etc/scirius/local_settings.py
sed -i 's/KIBANA_VERSION = 6/KIBANA_VERSION = 7/g' /etc/scirius/local_settings.py
sed -i 's/KIBANA_INDEX = "kibana-int"/KIBANA_INDEX = ".kibana"/g' /etc/scirius/local_settings.py
sed -i 's/KIBANA6_DASHBOARDS_PATH = "\/opt\/selks\/kibana6-dashboards\/"/KIBANA6_DASHBOARDS_PATH = "\/opt\/selks\/kibana7-dashboards\/"/g' /etc/scirius/local_settings.py
#echo "ELASTICSEARCH_KEYWORD = \"keyword\"" >> /etc/scirius/local_settings.py
echo "ELASTICSEARCH_KEYWORD = \"keyword\"" >> /etc/scirius/local_settings.py
echo "USE_MOLOCH = True" >> /etc/scirius/local_settings.py
echo "MOLOCH_URL = \"http://localhost:8005\"" >> /etc/scirius/local_settings.py
/usr/bin/supervisorctl restart scirius 

# reset and reload the new KTS6 dashboards and Kibana indexes
curl -XDELETE 'http://localhost:9200/.kibana*'
/bin/systemctl restart kibana && sleep 20

selks-first-time-setup_stamus
# systemctl status suricata elasticsearch logstash kibana evebox molochviewer-selks molochpcapread-selks







