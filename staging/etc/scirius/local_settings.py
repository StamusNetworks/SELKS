
import os


USE_ELASTICSEARCH = True
ELASTICSEARCH_ADDRESS = "localhost:9200"
ELASTICSEARCH_2X = True
KIBANA_VERSION=4
KIBANA_INDEX = ".kibana"
KIBANA_URL = "http://localhost:5601"

SURICATA_UNIX_SOCKET = "/var/run/suricata/suricata-command.socket"

USE_KIBANA = True

USE_SURICATA_STATS = True
BASE_DIR = os.path.dirname(os.path.dirname(__file__))
USE_LOGSTASH_STATS = True
STATIC_ROOT="/var/www/static/"

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR, 'db', 'db.sqlite3'),
    }
}

