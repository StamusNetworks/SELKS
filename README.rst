=====
SELKS
=====

INTRO
=====

SELKS is a free and open source Debian (with LXDE X-window manager) based IDS/IPS platform 
released under GPLv3 from Stamus Networks (https://www.stamus-networks.com/).

The SELKS ISO is both Live and Installable ISO in one. Once installed it is 
ready to use out of the box solution.

SELKS is comprised of the following major components:

* S - Suricata IDPS - http://suricata-ids.org/
* E - Elasticsearch - http://www.elasticsearch.org/overview/
* L - Logstash - http://www.elasticsearch.org/overview/
* K - Kibana - http://www.elasticsearch.org/overview/
* S - Scirius - https://github.com/StamusNetworks/scirius


HOWTO RUN SELKS
===============

Prerequisites
-------------

The minimal configuration is one single core and 2 Go of memory. A virtual machine with 2 Go of RAM should provide a basic test system.

The recommended configuration is two cores and 4 Go of memory.

Running on a virtual machine
----------------------------

You need to create or reuse a virtual machine.

For VirtualBox, the recommended network setup is to use a ``Bridged adapter`` and to allow
``Promiscuous mode`` on the interface. This way, SELKS will be able to analyse the traffic from the physical host.

To run SELKS, you need to add declare that the ISO image of SELKS is in the CDROM. You can then
reboot the virtual machine. If all goes well, you should see SELKS boot menu. Pressing enter will
lead you to the graphical interface.


Running on a physical box
-------------------------

To run SELKS, you need to burn the ISO image of SELKS on a DVD. After inserting
the DVD into the host drive, you can reboot.

If all goes well, you should see SELKS boot menu. Pressing enter will
lead you to the graphical interface.

USAGE
=====

Default user:
* user: ``selks-user``
* password: ``selks-user``

The default root password is ``StamusNetworks``

SELKS has 7 default IDS dashboards (found under Iceweasel, Bookmarks) - 
ALERTS,HTTP,DNS,TLS,SSH,File Transactions,ALL

Elasticsearch, Logstash and Suricata are build in and can be used as standard services, ex ::

 service suricata restart
 service logstash stop



TUNING,CONFIGURATION AND CONSIDERATIONS
=======================================

Each major component can be independently upgraded of the others.

Tuning Suricata and Elasticsearch is left up to the end user depending 
on the specific traffic needs and volume.

Please carefully consider and test HW needs before putting into production.

Suricata
--------

Suricata is build with dropping privileges capability.
Suricata (2.0.1 stable at the moment of this release) is installed and configured with the following:
Suricata Configuration ::

 Suricata Configuration
  AF_PACKET support:                       yes
  PF_RING support:                         no
  NFQueue support:                         yes
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
  GCC march native enabled:                no
  GCC Profile enabled:                     no


Elasticsearch and Logstash
--------------------------

Elasticsearch and Logstash use the default configuration settings and directories 
with only the following changes/additions for Elasticsearch in ``/etc/default/elasticsearch`` ::

 ES_HEAP_SIZE=1g
 ES_MIN_MEM=1g
 ES_MAX_MEM=1g
 JAVA_HOME=/opt/selks/java-oracle/jdk1.7.0_55/

and in ``/etc/elasticsearch/elasticsearch.yml`` ::

 discovery.zen.ping.multicast.enabled: false
 bootstrap.mlockall: true

Logrotate
---------

There is also automatic log rotation implemented in ``/etc/logrotate.d/suricata``  ::

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

HTTPS ACCESS
============

The Scirius and Kibana dashboards are bookmarked in Iceweasel and could be used 
directly with just a click once logged in the SELKS desktop.

If you wish to remotely (from a different PC on your network) access the 
dashboards you could do that as follows (in your browser):

https://your.selks.IP.here/rules/ - Scirius ruleset management
https://your.selks.IP.here/log/#/dashboard/file/ALL
https://your.selks.IP.here/log/#/dashboard/file/ALERTS
https://your.selks.IP.here/log/#/dashboard/file/HTTP
https://your.selks.IP.here/log/#/dashboard/file/DNS
https://your.selks.IP.here/log/#/dashboard/file/TLS
https://your.selks.IP.here/log/#/dashboard/file/FILE-Transactions
https://your.selks.IP.here/log/#/dashboard/file/SSH


NOTE
----

Remote access to the web interfaces is currently only httpS protected. It can be 
further protected with firewall rules and/or authentication or simply by using 
"service nginx start/stop"

Firewall rules
--------------
 
By default there are no firewall rules implemented.

SSH
----

SSH is enabled and both the root user and the ``selks-user`` can ssh to the box
by default.


DESKTOP MANAGER
===============

SELKS uses LXDE as a desktop windows manager. If you wish to uninstall 
the Desktop Manager (GUI) and run the server/machine just with command shell 
you can remove the desktop installation as follows after the installation:

"
apt-get remove lxde lxde-common lxde-core lxde-icon-theme lightdm \
hunspell-en-us hyphen-en-us iceweasel lxlauncher lxtask
"

This will not affect the services and/or scripts. SELKS would still continue 
to operate and function as desired.


GETTING HELP
============

You can get more information on SELKS wiki: https://github.com/StamusNetworks/SELKS/wiki

You can get help about SELKS on Freenode IRC on the #SELKS channel.

If you encounter a problem, you can open a ticket on https://github.com/StamusNetworks/SELKS/issues
