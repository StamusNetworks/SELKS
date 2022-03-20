#!/bin/bash

kubectl create --save-config -f common/storageclass.yaml
kubectl create --save-config -f common/suricata-ns.yaml
kubectl create --save-config -f common/logging-ns.yaml

kubectl create --save-config -f elasticsearch/elasticsearch-pv.yaml
kubectl create --save-config -f elasticsearch/elasticsearch-pvc.yaml
kubectl create --save-config -f elasticsearch/elasticsearch-statefulset.yaml
kubectl create --save-config -f elasticsearch/elasticsearch-service.yaml

# If you'd like to use Logstash with Filebeat (mutually exclusive with Fluentd with Fuent-bit)
kubectl create --save-config -f logstash_filebeat/logstash-configmap.yaml
kubectl create --save-config -f logstash_filebeat/logstash-statefulset.yaml
kubectl create --save-config -f logstash_filebeat/logstash-service.yaml
kubectl create --save-config -f logstash_filebeat/filebeat-configmap.yaml
kubectl create --save-config -f logstash_filebeat/filebeat-daemonset.yaml

# If you'd like to use Fluentd with Fluent-bit (mutually exclusive with Logstash with Filebeat)
# kubectl create --save-config -f fluentd_fluent-bit/fluentd-configmap.yaml
# kubectl create --save-config -f fluentd_fluent-bit/fluentd-deployment.yaml
# kubectl create --save-config -f fluentd_fluent-bit/fluentd-service.yaml
# kubectl create --save-config -f fluentd_fluent-bit/fluentbit-configmap.yaml
# kubectl create --save-config -f fluentd_fluent-bit/fluentbit-daemonset.yaml
# kubectl create --save-config -f fluentd_fluent-bit/fluentbit-service.yaml

kubectl create --save-config -f evebox/evebox-deployment.yaml
kubectl create --save-config -f evebox/evebox-service.yaml

kubectl create --save-config -f kibana/kibana-deployment.yaml
kubectl create --save-config -f kibana/kibana-service.yaml

kubectl create --save-config -f scirius/scirius-pv.yaml
kubectl create --save-config -f scirius/scirius-pvc.yaml
kubectl create --save-config -f scirius/scirius-secret.yaml
kubectl create --save-config -f scirius/scirius-deployment.yaml
kubectl create --save-config -f scirius/scirius-service.yaml

kubectl create --save-config -f suricata/suricata-pv.yaml
kubectl create --save-config -f suricata/suricata-pvc.yaml
kubectl create --save-config -f suricata/suricata-configmap.yaml
kubectl create --save-config -f suricata/suricata-daemonset.yaml
kubectl create --save-config -f suricata/suricata-cronjob.yaml

kubectl create --save-config -f arkime/arkime-pv.yaml
kubectl create --save-config -f arkime/arkime-pvc.yaml
kubectl create --save-config -f arkime/arkime-secret.yaml
kubectl create --save-config -f arkime/arkime-configmap.yaml
kubectl create --save-config -f arkime/arkime-deployment.yaml

# For a regular NGINX installation
kubectl create --save-config -f nginx/nginx-secret.yaml
kubectl create --save-config -f nginx/nginx-configmap.yaml
kubectl create --save-config -f nginx/nginx-deployment.yaml
kubectl create --save-config -f nginx/nginx-service.yaml
kubectl create --save-config -f nginx/nginx-ingress.yaml

# For a NGINX installation hardened with OWASP mod-security
# kubectl create --save-config -f nginx/nginx-secret.yaml
# kubectl create --save-config -f nginx/nginx-owasp-configmap.yaml
# kubectl create --save-config -f nginx/nginx-owasp-deployment.yaml
# kubectl create --save-config -f nginx/nginx-owasp-service.yaml
# kubectl create --save-config -f nginx/nginx-ingress.yaml
