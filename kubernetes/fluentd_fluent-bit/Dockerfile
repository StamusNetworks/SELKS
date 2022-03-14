FROM fluent/fluentd-kubernetes-daemonset:v1.14.5-debian-elasticsearch7-amd64-1.1
USER root
RUN ["gem", "install", "fluent-plugin-record-modifier", "--no-document"]
RUN ["gem", "install", "fluent-plugin-ua-parser", "--no-document"]

# GeoIP requires some more build options, rather than just a simple plugin.
# RUN ["gem", "install", "fluent-plugin-geoip", "--no-document"]
USER fluent
