===============
SELKS on Docker
===============

BETA
=====
This project is in beta. Following functionalities are not yet implemented :

- Full Packet Capture


Intro
=====
This version of SELKS is based on docker and intended to provide easier deployment and management.

For informations on standard SELKS implementation, see https://github.com/StamusNetworks/SELKS#selks

Requirements
=====
- 2 cores
- 8 GB of free RAM
- 10 GB of free disk space
- Debian Buster (other distributions/versions are probably OK but are not officially supported)
- docker > 17.06.0 (will be automatically installed if not found on the system)
- docker-compose > 1.27.0 (will be automatically installed if not found on the system)
- git, curl and time installed

Install
=======
.. code-block:: bash

  git clone https://github.com/StamusNetworks/SELKS.git
  cd SELKS/docker/
  ./easy-install.sh
  docker-compose up -d
  
Advanced Install
================
Using your own SSL certificate
------------------------------
Put your existing SSL certificate and private key in ``SELKS/docker/containers-data/nginx/ssl`` as ``scirius.crt`` and ``scirius.key``


Useful commands
================
Most docker-compose commands will have the following form ``docker-compose COMMAND [container-name]``
Those commands must be run from the SELKS/docker directory
If  no container-name is provided, it will be applied to all SELKS containers

Stopping containers
-------------------
``docker-compose stop [container-name]``

Starting containers
-------------------
``docker-compose start [container-name]``

Restarting containers
-------------------
``docker-compose restart [container-name]``

Removing containers along with their data
-------------------
``docker-compose down -v``

Recreating containers
-------------------
``docker-compose up [container-name] --force-recreate``
