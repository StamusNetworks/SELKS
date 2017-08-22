#!/bin/bash

# Copyright(C) 2017, Stamus Networks
# All rights reserved
# Written by Peter Manev <pmanev@stamus-networks.com>
#
# Please run on Debian
#
# This script comes with ABSOLUTELY NO WARRANTY!
# 

# exit on error
set -e

# not needed as ES5 has it by default
/usr/share/elasticsearch/bin/plugin remove delete-by-query

/bin/systemctl stop kibana

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get --yes -o Dpkg::Options::="--force-confnew" --force-yes dist-upgrade
/bin/systemctl stop elasticsearch
/bin/systemctl stop kibana
/bin/systemctl stop logstash
/bin/systemctl stop suricata
service scirius stop

apt-get install --yes apt-transport-https

# Pre Scirius upgrade tasks
rm -rf /etc/init.d/scirius && \
rm -rf /etc/init.d/suri_reloader 

cp /etc/nginx/ssl/server.crt /etc/nginx/ssl/scirius.crt
cp /etc/nginx/ssl/server.key /etc/nginx/ssl/scirius.key

sudo mkdir -p /var/lib/scirius/
sudo cp -ar /opt/selks/scirius/db/ /var/lib/scirius/
sudo cp -ar /opt/selks/scirius/git-sources/ /var/lib/scirius/

# Set up new SELKS 4 repos
rm -rf /etc/apt/sources.list.d/selks.list
cat >> /etc/apt/sources.list.d/selks4.list <<EOF
# SELKS4 Stamus Networks repos
#
# Manual changes here can be overwritten during 
# SELKS updates and upgrades

deb http://packages.stamus-networks.com/selks4/debian/ jessie main
deb http://packages.stamus-networks.com/selks4/debian-kernel/ jessie main
#deb http://packages.stamus-networks.com/selks4/debian-test/ jessie main
EOF

wget -qO - http://packages.stamus-networks.com/packages.selks4.stamus-networks.com.gpg.key | apt-key add - 

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes -o Dpkg::Options::="--force-confnew" --force-yes scirius

rm -rf /etc/nginx/sites-enabled/stamus.conf

if [ -f /etc/nginx/sites-available/selks4.conf ];
then
    
    # if the filename exists - make sure we don't overwrite.
    mv /etc/nginx/sites-available/selks4.conf /etc/nginx/sites-available/selks4.conf.orig
    
fi

cat >> /etc/nginx/sites-available/selks4.conf <<EOF
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

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_read_timeout 600;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect off;
    }

}
EOF

ln -s /etc/nginx/sites-available/selks4.conf /etc/nginx/sites-enabled/selks4.conf

# supervisor conf
ln -s /usr/share/doc/scirius/examples/scirius-supervisor.conf /etc/supervisor/conf.d/scirius-supervisor.conf

cd /usr/share/python/scirius/ && \
source bin/activate
python bin/manage.py loaddata /etc/scirius/scirius.json
deactivate

# Set permissions for Scirius 
touch /var/log/scirius.log
touch /var/log/scirius-error.log
chown www-data /var/log/scirius*
chown -R www-data /var/lib/scirius/git-sources/
chown -R www-data /var/lib/scirius/db/
chown -R www-data.www-data /etc/suricata/rules/

/usr/bin/supervisorctl reread && \
/usr/bin/supervisorctl update && \
/usr/bin/supervisorctl restart scirius && \
/bin/systemctl restart nginx
/bin/systemctl enable supervisor.service

/bin/systemctl stop elasticsearch
/bin/systemctl stop kibana
/bin/systemctl stop logstash

# Switch on to Debian Stretch - upgrade partial packages only
sed -i 's/jessie/stretch/g' /etc/apt/sources.list
sed -i 's/jessie/stretch/g'  /etc/apt/sources.list.d/selks4.list
rm -rf /etc/apt/sources.list.d/elasticsearch.list

apt-get update 
apt-get install -y ca-certificates-java openjdk-8-jre-headless \
openjdk-8-jdk openjdk-8-jre openjdk-8-jdk-headless libhyperscan4

# Remove old java here in case it is the only one running before upgrade above
apt-get remove --yes openjdk-7-jdk openjdk-7-jre openjdk-7-jre-headless

# echo -e "\nPLEASE SELECT JAVA8 AS DEFAULT:\n"
# update-alternatives --config java

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list

# Replace logsatsh.conf while saving the old one - in the parent folder
if [ -f /etc/logstash/conf.d/logstash.conf ];
then
    
    # If the filename exists - make sure we don't overwrite.
    mv /etc/logstash/conf.d/logstash.conf /etc/logstash/logstash.conf.selks3.orig
    
fi

# Set up new logstash.conf
cat >> /etc/logstash/conf.d/logstash.conf << EOF
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
      add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
      add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}"  ]
    }
    mutate {
      convert => [ "[geoip][coordinates]", "float" ]
    }
    if ![geoip.ip] {
      if [dest_ip]  {
        geoip {
          source => "dest_ip"
          target => "geoip"
          #database => "/opt/logstash/vendor/geoip/GeoLiteCity.dat"
          add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
          add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}"  ]
        }
        mutate {
          convert => [ "[geoip][coordinates]", "float" ]
        }
      }
    }
  }
}

output {
  if [event_type] and [event_type] != 'stats' {
    elasticsearch {
      hosts => "127.0.0.1"
      index => "logstash-%{event_type}-%{+YYYY.MM.dd}"
      template => "/etc/logstash/elasticsearch5-template.json"
    }
  } else {
    elasticsearch {
      hosts => "127.0.0.1"
      index => "logstash-%{+YYYY.MM.dd}"
      template => "/etc/logstash/elasticsearch5-template.json"
    }
  }
}
EOF

# Set up Elasticsearch 5 template
# Avoids unassigned shards
cat >> /etc/logstash/elasticsearch5-template.json << EOF
{
  "template" : "logstash-*",
  "version" : 50001,
  "settings" : {
    "number_of_replicas": 0,
    "index.refresh_interval" : "5s"
  },
  "mappings" : {
    "_default_" : {
      "_all" : {"enabled" : true, "norms" : false},
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
              "keyword" : { "type": "keyword", "index": "not_analyzed", "ignore_above": 256 },
              "raw" : { "type": "keyword", "index": "not_analyzed", "ignore_above": 256 }
            }
          }
        }
      } ],
      "properties" : {
        "@timestamp": { "type": "date", "include_in_all": false },
        "@version": { "type": "keyword", "include_in_all": false },
        "geoip"  : {
          "dynamic": true,
          "properties" : {
            "ip": { "type": "ip" },
            "location" : { "type" : "geo_point" },
            "latitude" : { "type" : "half_float" },
            "longitude" : { "type" : "half_float" }
          }
        },
        "dest_ip": { 
            "type": "ip",
            "fields": {
                "raw": {"index": "not_analyzed", "type": "keyword"},
                "keyword": {"index": "not_analyzed", "type": "keyword"}
             }
        },
        "src_ip": { 
            "type": "ip",
            "fields": {
                "raw": {"index": "not_analyzed", "type": "keyword"},
                "keyword": {"index": "not_analyzed", "type": "keyword"}
             }
        }
      }
    }
  }
}
EOF

# make sure we keep some of the SELKS settings
mkdir -p /opt/stretch-upgrade-temp/
cp /etc/motd /opt/stretch-upgrade-temp/
cp /etc/issue.net /opt/stretch-upgrade-temp/
mv /etc/alternatives/desktop-background /opt/stretch-upgrade-temp/

# Full switch to Debian Stretch - upgrade all
apt-get update
apt-get -y upgrade && \
DEBIAN_FRONTEND=noninteractive apt-get --yes -o Dpkg::Options::="--force-confnew" --force-yes dist-upgrade

/bin/systemctl daemon-reload
/bin/systemctl enable logstash
/bin/systemctl start elasticsearch
sleep 30

# upgrade to Stretch kernel
apt-get install -y linux-image-amd64 linux-headers-amd64

# install virtual guest deps (handy if it is a virtual guest deployment)
apt-get install -y build-essential module-assistant

# move back some of the original SELKS settings
mv -f /opt/stretch-upgrade-temp/motd /etc/ 
mv -f /opt/stretch-upgrade-temp/issue.net /etc/
mv -f /opt/stretch-upgrade-temp/desktop-background /etc/alternatives/
rm -rf /opt/stretch-upgrade-temp

# reset the dashboards after the package upgrade
rm -rf /etc/kibana/kibana-dashboards-loaded
/etc/init.d/kibana-dashboards-stamus reset

update_evebox() {
    # Use new "stable" EveBox repo.
    echo "deb http://files.evebox.org/evebox/debian stable main" > \
	 /etc/apt/sources.list.d/evebox.list
    wget -qO - https://evebox.org/files/GPG-KEY-evebox | sudo apt-key add -

    # Make sure EveBox only binds to localhost.
    echo "EVEBOX_OPTS=\"--host localhost\"" > /etc/default/evebox

    # Update without overriding config files.
    apt-get update
    apt-get install -y -o Dpkg::Options::="--force-confdef" \
	    -o Dpkg::Options::="--force-confold" evebox
}

update_evebox

/bin/systemctl restart elasticsearch
/bin/systemctl start kibana
/bin/systemctl start logstash
/bin/systemctl restart evebox

echo "deb http://packages.elastic.co/curator/4/debian stable main" > /etc/apt/sources.list.d/curator4.list
apt-get update
apt-get install --yes elasticsearch-curator

# Set up a curator old logs removal 
# Remove old cronjob first
sed -e '/\/usr\/local\/bin\/curator delete indices --older-than 16/ s/^#*/#/' -i /etc/crontab
 
cat >> /opt/selks/delete-old-logs.sh <<EOF
#!/bin/bash

/opt/elasticsearch-curator/curator_cli delete_indices --filter_list \
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

chmod 755 /opt/selks/delete-old-logs.sh

# Set up a cron jobs for Logstash, Suricata, rule updates
echo "0 2 * * * www-data ( cd /usr/share/python/scirius/ && . bin/activate && python bin/manage.py updatesuricata && deactivate )" >> /etc/crontab
echo "0 4 * * * root /opt/selks/delete-old-logs.sh" >> /etc/crontab
# Alway leave a empty line before cron files end
echo "" >> /etc/crontab

# (re)setup IDS sniffing interface for Suricata
/opt/selks/Scripts/Setup/setup-selks-ids-interface.sh

# Clean up
rm -rf /opt/selks/scirius/
rm -rf /opt/kibana/

apt-get -y clean && apt-get -y autoremove

#reboot

