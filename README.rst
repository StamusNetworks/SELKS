=====
SELKS
=====

INTRO
=====

SELKS is a free and open source Debian (with LXDE X-window manager) based IDS/IPS platform released under GPLv3 from Stamus Networks.
The SELKS ISO is both Live and Installable ISO in one. 

SELKS is comprised of the following major components:

* S - Suricata IDPS - http://suricata-ids.org/
* E - Elasticsearch - http://www.elasticsearch.org/overview/
* L - Logstash - http://www.elasticsearch.org/overview/
* K - Kibana - http://www.elasticsearch.org/overview/
* S - Scirius - https://github.com/StamusNetworks/scirius


USAGE
=====

Default user ::
* user: ''selks-user''
* password: ''selks-user''

The default root password is ''StamusNetworks''

SELKS has 7 default IDS dashboards (found under Iceweasel, Bookmarks) - 
ALERTS,HTTP,DNS,TLS,SSH,File Transactions,ALL

The Scirius service can be started from the LXDE's "Menu", "System Tools" -> "Launch-Scirius-Daemon"

Elasticsearch, Logstash and Suricata are build in and can be used as standard services, ex ::

 service suricata restart
 service logstash stop


TUNING,CONFIGURATION AND CONSIDERATIONS
=======================================

Each major component can be independently upgraded of the others.
Tuning suricata.yaml is left up to the end user depending on the specific traffic needs and speeds.

Suricata
--------

Suricata (2.0 stable at the moment of this release) is installed and configured with the following:
Suricata Configuration ::

 Suricata Configuration
  AF_PACKET support:                       yes
  PF_RING support:                         no
  NFQueue support:                         no
  IPFW support:                            no
  DAG enabled:                             no
  Napatech enabled:                        no
  Unix socket enabled:                     yes
  Detection enabled:                       yes

  libnss support:                          yes
  libnspr support:                         yes
  libjansson support:                      yes
  Prelude support:                         no
  PCRE jit:                                yes
  libluajit:                               no
  libgeoip:                                yes
  Non-bundled htp:                         no
  Old barnyard2 support:                   no
  CUDA enabled:                            no

  Suricatasc install:                      yes

  Unit tests enabled:                      no
  Debug output enabled:                    no
  Debug validation enabled:                no
  Profiling enabled:                       no
  Profiling locks enabled:                 no
  Coccinelle / spatch:                     no

 Generic build parameters:
  Installation prefix (--prefix):          /usr
  Configuration directory (--sysconfdir):  /etc/suricata/
  Log directory (--localstatedir) :        /var/log/suricata/

  Host:                                    x86_64-unknown-linux-gnu
  GCC binary:                              gcc
  GCC Protect enabled:                     no
  GCC march native enabled:                yes
  GCC Profile enabled:                     no


Elasticsearch and Logstash
--------------------------

Elasticsearch and Logstash use the default configuration settings and directories 
with only the following changes/additions for Elasticsearch in ''/etc/default/elasticsearch'' ::

 ES_HEAP_SIZE=1g
 ES_MIN_MEM=1g
 ES_MAX_MEM=1g

and in ''/etc/elasticsearch/elasticsearch.yml'' ::

 discovery.zen.ping.multicast.enabled: false

Logrotate
---------

There is also automatic log rotation implemented in /etc/logrotate.d/suricata  ::

 /var/log/suricata/eve.json {
	daily
	rotate 30
        olddir /var/log/suricata/StatsByDate/
	compress
	missingok
	notifempty
	dateext
	copytruncate
 }

Running services
----------------

All services (except Scirius) are up and enabled during boot time

NOTE
~~~~

The web interfaces of Kibana and Scirius are without httpS
Remote access to Kibana can be protected with firewall rules, implementations of httpS or simply by using "service apache2 start/stop"

Firewall rules
--------------
 
By default there are no firewall rules implemented.


Getting help
============

You can get more information on SELKS wiki: https://github.com/StamusNetworks/scirius/wiki

You can get help about SELKS on Freenode IRC on the #SELKS channel.

If you encounter a problem, you can open a ticket on https://github.com/StamusNetworks/SELKS/issues
