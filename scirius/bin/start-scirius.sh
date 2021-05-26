#!/bin/bash

cd /opt/scirius/

migrate_db() {
    python manage.py migrate --noinput
    python manage.py collectstatic  --noinput
}

set_elastic_ilm() {
    
    
    until [[ $response == *"\"acknowledged\" : true"* ]]; do
      sleep 5
      ELASTICSEARCH_ADDRESS=$(python manage.py diffsettings --all |grep 'ELASTICSEARCH_ADDRESS' | cut -d"'" -f 2)
      echo "found elastic address : $ELASTICSEARCH_ADDRESS"
      response=$(curl -X PUT "$ELASTICSEARCH_ADDRESS/_ilm/policy/logstash-autodelete?pretty" -H 'Content-Type: application/json' -d'
{
  "policy": {
    "phases": {
      "hot": {                      
        "actions": {
          "rollover": {
            "max_size": "50GB",     
            "max_age": "1d"
          }
        }
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
    done
    
    echo "ILM properly set"
}

create_db() {
    python manage.py migrate --noinput

    echo "from django.contrib.auth.models import User; User.objects.create_superuser(***)"
    if [ -n "$DJANGO_SUPERUSER_USERNAME" ] && [ -n "$DJANGO_SUPERUSER_EMAIL" ] ; then
        echo "from django.contrib.auth.models import User; User.objects.create_superuser('$DJANGO_SUPERUSER_USERNAME', '$DJANGO_SUPERUSER_EMAIL', '$DJANGO_SUPERUSER_PASSWORD')" | python manage.py shell
    else
        echo "from django.contrib.auth.models import User; User.objects.create_superuser('selks-user', 'selks-user@selks.com', 'selks-user')" | python manage.py shell
    fi
    echo "from django.contrib.auth.models import User, Group; u = User.objects.filter(username='selks-user').first(); g = Group.objects.filter(name='Superuser').first(); g.user_set.add(u)" | python manage.py shell

    python manage.py createcachetable my_cache_table
    python manage.py addsource "ETOpen Ruleset" https://rules.emergingthreats.net/open/suricata-5.0/emerging.rules.tar.gz http sigs
    python manage.py addsource "SSLBL abuse.ch" https://sslbl.abuse.ch/blacklist/sslblacklist.rules http sig
    python manage.py addsource "PT Research Ruleset" https://github.com/ptresearch/AttackDetection/raw/master/pt.rules.tar.gz http sigs
    python manage.py defaultruleset "Default ruleset"
    python manage.py disablecategory "Default ruleset" stream-events
    python manage.py addsuricata suricata "Suricata" /rules "Default ruleset"
    python manage.py updatesuricata
    python manage.py collectstatic --noinput
}

start() {
    #webpack
    # cd hunt
    # npm run build
    # cd ..
    # cp -rT doc/_build/html /static/doc
    python manage.py collectstatic --noinput
    echo "Starting suri-reloader daemon..."
    rm -f /var/run/suri_reloader.pid
    python /opt/scirius/suricata/scripts/suri_reloader &
    echo "Starting scirius server..."
    if [[ -n "$DEBUG" ]] ; then
        echo DEBUG
        python manage.py runserver 0.0.0.0:8000
    else
        gunicorn -w $(($(nproc --all)*2+1)) -t 120 -b 0.0.0.0:8000 scirius.wsgi
    fi
}

if [ ! -e "/data/scirius.sqlite3" ]; then
    /opt/scirius/bin/reset_dashboards.sh &
    create_db &
    /opt/scirius/bin/create_ILM_policy.sh
else
    migrate_db
fi

if [ -n "$KIBANA_RESET_DASHBOARDS" ]; then
    /opt/scirius/bin/reset_dashboards.sh &
fi

start
