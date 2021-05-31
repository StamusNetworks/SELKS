# Copyright (C) 2019, Stamus Networks
# Adapted by Raphaël Brogat <rbrogat@stamus-networks.com> based on Gabor Seljan's code
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
"""
Django settings for the Scirius project.
"""

import os
from distutils.util import strtobool

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv('SECRET_KEY')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = bool(strtobool(os.getenv('DEBUG', '0')))

# SECURITY WARNING: don't use '*' in production!
ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', 'localhost 127.0.0.1 [::1]').split(' ')

# 127.0.0.1 must be allowed for container health checking
if '127.0.0.1' not in ALLOWED_HOSTS:
    ALLOWED_HOSTS.append('127.0.0.1')

# Database
DATABASES = {
    'default': {
        'ENGINE': os.getenv('SQL_ENGINE', 'django.db.backends.sqlite3'),
        'NAME': os.getenv('SQL_DATABASE', '/data/scirius.sqlite3')
    }
}

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': True,
    'formatters': {
        'fileformat': {
            'format': '%(asctime)s %(levelname)s %(message)s'
        },
        'raw': {
            'format': '%(asctime)s %(message)s'
        },
    },
    'handlers': {
        'elasticsearch': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': '/logs/elasticsearch.log',
            'formatter': 'raw',
        },
        'error_log': {
            'level': 'DEBUG',
            'class': 'logging.FileHandler',
            'filename': '/logs/django-error.log',
            'formatter': 'fileformat',
        },
        'auth_log': {
            'level': 'DEBUG',
            'class': 'logging.FileHandler',
            'filename': '/logs/django-auth.log',
            'formatter': 'fileformat',
        },
    },
    'loggers': {
        'elasticsearch': {
            'handlers': ['elasticsearch'],
            'level': 'INFO',
            'propagate': True,
        },
        'django.request': {
            'handlers': ['error_log'],
            'level': 'DEBUG',
            'propagate': True,
        },
        'authentication': {
            'handlers': ['auth_log'],
            'level': 'DEBUG',
            'propagate': True,
        },

    }
}

# Scirius
SCIRIUS_HAS_DOC = True
SCIRIUS_IN_SELKS = bool(strtobool(os.getenv('SCIRIUS_IN_SELKS', '0')))

# Internationalization
LANGUAGE_CODE = os.getenv('LANGUAGE_CODE', 'en-us')
TIME_ZONE = os.getenv('TIME_ZONE', 'UTC')

# Static files
STATIC_URL = os.getenv('STATIC_URL', '/static/')
STATIC_ROOT = os.getenv('STATIC_ROOT', '/static')
STATIC_AUTHENTICATED = bool(strtobool(os.getenv('STATIC_AUTHENTICATED', '0')))

# Suricata
SURICATA_UNIX_SOCKET = os.getenv('SURICATA_UNIX_SOCKET', '/var/run/suricata.socket')
SURICATA_NAME_IS_HOSTNAME = bool(strtobool(os.getenv('SURICATA_NAME_IS_HOSTNAME', '0')))

# Elasticsearch
USE_ELASTICSEARCH = bool(strtobool(os.getenv('USE_ELASTICSEARCH', '0')))
ELASTICSEARCH_ADDRESS = os.getenv('ELASTICSEARCH_ADDRESS', 'elasticsearch:9200')
ELASTICSEARCH_LOGSTASH_INDEX = os.getenv('ELASTICSEARCH_LOGSTASH_INDEX', 'logstash-*')
ELASTICSEARCH_LOGSTASH_ALERT_INDEX = os.getenv('ELASTICSEARCH_LOGSTASH_ALERT_INDEX', 'logstash-alert-*')
ELASTICSEARCH_LOGSTASH_TIMESTAMPING = os.getenv('ELASTICSEARCH_LOGSTASH_TIMESTAMPING', 'daily')
ELASTICSEARCH_KEYWORD = os.getenv('ELASTICSEARCH_KEYWORD', 'keyword')
ELASTICSEARCH_HOSTNAME = os.getenv('ELASTICSEARCH_HOSTNAME', 'host')
ELASTICSEARCH_TIMESTAMP = os.getenv('ELASTICSEARCH_TIMESTAMP', '@timestamp')

# Kibana
USE_KIBANA = bool(strtobool(os.getenv('USE_KIBANA', '0')))
KIBANA_PROXY = bool(strtobool(os.getenv('KIBANA_PROXY', '0')))
KIBANA_URL = os.getenv('KIBANA_URL', 'http://kibana:5601')
KIBANA_INDEX = os.getenv('KIBANA_INDEX', '.kibana')
KIBANA_DASHBOARDS_PATH = os.getenv('KIBANA_DASHBOARDS_PATH', '/opt/kibana-dashboards/')
KIBANA6_DASHBOARDS_PATH = os.getenv('KIBANA6_DASHBOARDS_PATH', '/opt/kibana6-dashboards/')
KIBANA7_DASHBOARDS_PATH = os.getenv('KIBANA6_DASHBOARDS_PATH', '/opt/kibana7-dashboards/')
KIBANA_ALLOW_GRAPHQL = bool(strtobool(os.getenv('KIBANA_ALLOW_GRAPHQL', '1')))

# EveBox
USE_EVEBOX = bool(strtobool(os.getenv('USE_EVEBOX', '0')))
EVEBOX_ADDRESS = os.getenv('EVEBOX_ADDRESS', 'http://evebox:5636')
USE_SURICATA_STATS = bool(strtobool(os.getenv('USE_SURICATA_STATS', '0')))
USE_LOGSTASH_STATS = bool(strtobool(os.getenv('USE_LOGSTASH_STATS', '0')))

# CyberChef
USE_CYBERCHEF = bool(strtobool(os.getenv('USE_CYBERCHEF', '0')))
CYBERCHEF_URL = os.getenv('CYBERCHEF_URL', '/static/cyberchef/')

# InfluxDB
USE_INFLUXDB = bool(strtobool(os.getenv('USE_INFLUXDB', '0')))
INFLUXDB_HOST = os.getenv('INFLUXDB_HOST', 'influxdb')
INFLUXDB_PORT = os.getenv('INFLUXDB_PORT', 8086)
INFLUXDB_USER = os.getenv('INFLUXDB_USER', 'grafana')
INFLUXDB_PASSWORD = os.getenv('INFLUXDB_PASSWORD', 'grafana')
INFLUXDB_DATABASE = os.getenv('INFLUXDB_DATABASE', 'scirius')

# Moloch
USE_MOLOCH = bool(strtobool(os.getenv('USE_MOLOCH', '0')))
MOLOCH_URL = os.getenv('MOLOCH_URL', 'http://moloch:8005')

# Proxy settings
USE_PROXY = bool(strtobool(os.getenv('USE_PROXY', '0')))
HTTP_PROXY = os.getenv('HTTP_PROXY', 'http://proxy:3128')
HTTPS_PROXY = os.getenv('HTTPS_PROXY', 'http://proxy:3128')
PROXY_PARAMS = {'http': HTTP_PROXY, 'https': HTTPS_PROXY}

# Content Security Policy settings
CSP_DEFAULT_SRC = tuple(os.getenv('CSP_DEFAULT_SRC', "'self'").split(' '))
CSP_SCRIPT_SRC = tuple(os.getenv('CSP_SCRIPT_SRC', "'self' 'unsafe-inline'").split(' '))
CSP_STYLE_SRC = tuple(os.getenv('CSP_STYLE_SRC', "'self' 'unsafe-inline'").split(' '))
CSP_INCLUDE_NONCE_IN = os.getenv('CSP_INCLUDE_NONCE_IN', 'script-src').split(' ')
CSP_EXCLUDE_URL_PREFIXES = tuple(os.getenv('CSP_EXCLUDE_URL_PREFIXES', '/evebox').split(' '))
