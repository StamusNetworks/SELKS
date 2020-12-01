# Scirius

[![Gitlab pipeline status](https://img.shields.io/gitlab/pipeline/sgabe/scirius)](https://gitlab.com/sgabe/scirius/-/pipelines)
[![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/sgabe/scirius)](https://hub.docker.com/r/sgabe/scirius/builds)
[![Docker Cloud Automated build](https://img.shields.io/docker/cloud/automated/sgabe/scirius)](https://hub.docker.com/r/sgabe/scirius/builds)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/sgabe/scirius/latest)](https://hub.docker.com/r/sgabe/scirius)
[![GitHub](https://img.shields.io/github/license/sgabe/scirius)](LICENSE)

Scirius Community Edition is a web interface dedicated to [Suricata IDS](https://suricata-ids.org/) ruleset management and was originally [developed](https://github.com/StamusNetworks/scirius) and [dockerized](https://github.com/StamusNetworks/scirius-docker) by [Stamus Networks](https://www.stamus-networks.com/). This Docker image has been created for a [fork](https://github.com/sgabe/scirius) of the original project instead of using the official image provided by the authors.

## Usage

    docker run -p 127.0.0.1:8000:8000 \
        -e "SECRET_KEY=<YOUR SECRET KEY>" \
        -v /path/to/scirius/data:/data \
        -v /path/to/scirius/logs:/logs \
        -v /path/to/scirius/static:/static \
        -v /path/to/suricata/rules:/rules \
        -v /path/to/suricata/suricata.socket:/var/run/suricata.socket \
        sgabe/scirius

## Environment variables

Most of the configuration options defined in the built-in `settings.py` shipped with the original project are exposed via environment variables in the `local_settings.py` file used in the container. This allows you to customize Scirius without creating or modifying configuration files. The below table summarizes the available environment variables and their default settings. For more information on how to configure Scirius, please refer to the original project documentation available [here](https://scirius.readthedocs.io/en/latest/).

| Variable                             | Default                               | 
| -------------------------------------|---------------------------------------| 
| **Django**                                                                   |
| `SECRET_KEY`                         | `None`                                |
| `DEBUG`                              | `False`                               |
| `ALLOWED_HOSTS`                      | `localhost 127.0.0.1 [::1]`           |
| Internationalization                                                         |
| `LANGUAGE_CODE`                      | `en-us`                               |
| `TIME_ZONE`                          | `UTC`                                 |
| Static files                                                                 |
| `STATIC_URL`                         | `/static/`                            |
| `STATIC_ROOT`                        | `/static`                             |
| `STATIC_AUTHENTICATED`               | `False`                               |
| **Suricata**                                                                 |
| `SURICATA_UNIX_SOCKET`               | `/var/run/suricata.socket`            |
| `SURICATA_NAME_IS_HOSTNAME`          | `False`                               |
| **Elasticsearch**                                                            |
| `USE_ELASTICSEARCH`                  | `False`                               |
| `ELASTICSEARCH_URL`                  | `http://elasticsearch:9200`           |
| `ELASTICSEARCH_LOGSTASH_INDEX`       | `logstash-*`                          |
| `ELASTICSEARCH_LOGSTASH_ALERT_INDEX` | `logstash-alert-*`                    |
| `ELASTICSEARCH_LOGSTASH_TIMESTAMPING`| `daily`                               |
| `ELASTICSEARCH_KEYWORD`              | `raw`                                 |
| `ELASTICSEARCH_HOSTNAME`             | `host`                                |
| `ELASTICSEARCH_TIMESTAMP`            | `@timestamp`                          |
| **Kibana**                                                                   |
| `USE_KIBANA`                         | `False`                               |
| `KIBANA_PROXY`                       | `False`                               |
| `KIBANA_URL`                         | `http://kibana:9292`                  |
| `KIBANA_INDEX`                       | `.kibana`                             |
| `KIBANA_DASHBOARDS_PATH`             | `/opt/kibana-dashboards/`             |
| `KIBANA6_DASHBOARDS_PATH`            | `/opt/kibana6-dashboards/`            |
| `KIBANA_ALLOW_GRAPHQL`               | `True`                                |
| **Evebox**                                                                   |
| `USE_EVEBOX`                         | `False`                               |
| `EVEBOX_URL`                         | `http://evebox:5636`                  |
| `USE_SURICATA_STATS`                 | `False`                               |
| `USE_LOGSTASH_STATS`                 | `False`                               |
| **InfluxDB**                                                                 |
| `USE_INFLUXDB`                       | `False`                               |
| `INFLUXDB_HOST`                      | `influxdb`                            |
| `INFLUXDB_PORT`                      | `8086`                                |
| `INFLUXDB_USER`                      | `grafana`                             |
| `INFLUXDB_PASSWORD`                  | `grafana`                             |
| `INFLUXDB_DATABASE`                  | `scirius`                             |
| **Moloch**                                                                   |
| `USE_MOLOCH`                         | `False`                               |
| `MOLOCH_URL`                         | `http://moloch:8005`                  |
| **Proxy settings**                                                           |
| `USE_PROXY`                          | `False`                               |
| `HTTP_PROXY`                         | `http://proxy:3128`                   |
| `HTTPS_PROXY`                        | `http://proxy:3128`                   |
| **Content Security Policy settings**                                         |
| `CSP_DEFAULT_SRC`                    | `'self'`                              |
| `CSP_SCRIPT_SRC`                     | `'self' 'unsafe-inline'`              |
| `CSP_STYLE_SRC`                      | `'self' 'unsafe-inline'`              |
| `CSP_INCLUDE_NONCE_IN`               | `script-src`                          |
| `CSP_EXCLUDE_URL_PREFIXES`           | `/evebox`                             |

## Volumes

The below table summarizes the volumes available to be shared with the host or other containers. Mainly the `/rules` folder should be available to Suricata while resources in the `/static` directory should be served through a reverse proxy.

| Volume    | Function                                                         |
| ----------|------------------------------------------------------------------|
| `/data`   | Persistent data stored in `scirius.sqlite3`                      |
| `/logs`   | Logs generated by ES interaction and rule updates                |
| `/rules`  | Generated rules to be used by Suricata                           |
| `/static` | Static files to be served by a reverse proxy                     |

## Link with Suricata

To interact with Suricata, you need to bind-mount Suricata's command socket into the Scirius container. By default, Scirius will expect the Unix socket file to be available at `/var/run/suricata.socket`, however, you can specify another path in the `SURICATA_UNIX_SOCKET` environment variable.

    -v /path/to/suricata/suricata-command.socket:/var/run/suricata.socket
