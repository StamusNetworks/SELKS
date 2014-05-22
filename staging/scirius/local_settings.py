"""
Django settings for scirius project.

For more information on this file, see
https://docs.djangoproject.com/en/1.6/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/1.6/ref/settings/
"""

# Build paths inside the project like this: os.path.join(BASE_DIR, ...)
import os
BASE_DIR = os.path.dirname(os.path.dirname(__file__))


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/1.6/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
# FIXME: generate this
SECRET_KEY = 'p8o5%vq))8h2li08c%k3id(wwo*u(^dbdmx2tv#t(tb2pr9@n-'

USE_ELASTICSEARCH = True
ELASTICSEARCH_ADDRESS = "localhost:9200"

STATIC_ROOT="/var/www/static/"

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR, 'db', 'db.sqlite3'),
    }
}

USE_KIBANA = False
KIBANA_URL = "/log/"
