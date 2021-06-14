=====
SELKS on Docker
=====

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
- Debian Buster (other distributions/versiosn are probably OK but are not officially supported)
- docker > 17.06.0 (will be automatically installed if not found on the system)
- docker-compose (will be automatically installed if not found on the system)
- git

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


