SELKS on Kubernetes
===============

Intro
-----

This version of SELKS is based on docker and intended to provide easier deployment and management on Kubernetes

For informations on standard SELKS implementation, see https://github.com/StamusNetworks/SELKS#selks

Minimum Requirements
--------------------
- 2 cores
- 8 GB of free RAM
- 10 GB of free disk space (actual disk occupation will mainly depend of the number of rules and the amount of traffic on the network). 200GB+ SSD grade is recommended.
- ``git``, ``curl``
- ``Kubernetes`` >= 1.21 (tested on k3s 1.22)
- ``docker or containerd``

Install process
---------------
### Basic installation
Clone the Git repository from SELKS

```bash
git clone https://github.com/StamusNetworks/SELKS.git
cd SELKS/kubernetes/
```

Update the PV's and storage class according to your own needs. Replace username and password in the secret definitions.

Choose between Logstash with Filebeat, or Fluentd with Fluent-bit. Fluentd uses rather significantly less memory (Logstash uses 1G to 1,5G by default, Fluentd uses about 100M), but you need to build your own container image with certain plugins and push to a (self-hosted) Private Docker Registry in order to use all of the features available by default via Logstash. We've included some basic Kubernetes logging in the Fluentd/Fluent-bit configuration.

```bash
# Setup storage
mkdir -p /data/arkime/{pcap,logs} /data/suricata/{logrotate,rules,run,logs/fpc} /data/scirius/{data,logs,static} /data/elasticsearch
chown -R 997:995 /data/suricata
chown -R 1000:995 /data/scirius
chown -R 1000:1000 /data/elasticsearch
chown -R 1000:1000 /data/arkime

# Create NGINX TLS keys and create secret template
openssl req -new -nodes -x509 -subj "/C=FR/ST=IDF/L=Paris/O=Stamus/CN=SELKS" -days 3650 -keyout ./tls.key -out tls.crt -extensions v3_ca
kubectl create secret tls nginx-tls --cert=tls.crt --key=tls.key --dry-run -o yaml > nginx/nginx-secret.yaml

chmod +x install.sh
./install.sh

# To load the Kibana dashboards, once Kibana is up and running
kubectl create --save-config -f kibana/alpine.yaml
```
Once the services have been applied, you can get the NodePort using the following command:
```
kubectl get svc -n suricata nginx
```
In the example below, 31584 is the NodePort to connect to.
```
NAME    TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
nginx   NodePort   10.43.233.61   <none>        443:31584/TCP,80:30831/TCP   27h
```

Once the deployments are up and running, you should just point your browser to `https://your.selks.IP.here:31584/`

Alternatively, you can alter and apply the nginx-ingress YAML definition and access the cluster via FQDN.

### Credentials and log in

In order to access scirius, you will need following credentials:

-   user: `selks-user`
-   password: `selks-user`

### Wiki

More info and details can be found on our [wiki](https://github.com/StamusNetworks/SELKS/wiki/Docker)


Getting help
------------

There are many ways to get help including in our live chat - [Getting Help](https://github.com/StamusNetworks/SELKS/wiki/Getting-Help)

Report an issue
---------------

If you've encoutered an issue please let us know: [Report Issue](https://github.com/StamusNetworks/SELKS/issues/new?labels[]=Docker&title=Docker:%20Issue%20summary&body=%3C%21--%0AUse%20the%20commands%20below%20to%20provide%20key%20information%20from%20your%20environment%3A%0AYou%20do%20NOT%20have%20to%20include%20this%20information%20if%20this%20is%20a%20FEATURE%20REQUEST%0A--%3E%0A%0A%2A%2ADescription%2A%2A%0A%0A%0A%2A%2ASteps%20to%20reproduce%20the%20issue%3A%2A%2A%0A1.%0A2.%0A3.%0A%0A%2A%2ADescribe%20the%20results%20you%20received%3A%2A%2A%0A%0A%0A%2A%2ADescribe%20the%20results%20you%20expected%3A%2A%2A%0A%0A%0A%2A%2AAdditional%20information%20you%20deem%20important%20%28e.g.%20issue%20happens%20only%20occasionally%29%3A%2A%2A%0A%0A%2A%2AOutput%20of%20%60docker%20version%60%3A%2A%2A%0A%0A%60%60%60%0A%28paste%20your%20output%20here%29%0A%60%60%60%0A%0A%2A%2AOutput%20of%20%60docker-compose%20version%60%3A%2A%2A%0A%0A%60%60%60%0A%28paste%20your%20output%20here%29%0A%60%60%60%0A%0A%2A%2AOutput%20of%20%60lsb_release%20-a%60%3A%2A%2A%0A%0A%60%60%60%0A%28paste%20your%20output%20here%29%0A%60%60%60%0A%0A%2A%2AAdditional%20environment%20details%3A%2A%2A%0A)
