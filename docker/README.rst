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
  ./easy-setup.sh
  docker-compose up -d
  
Advanced Install
================
Note
----
The ``easy-setup.sh`` does the following :
1) Checking that docker and docker-compose are properly installed and available to the user, and installing them if needed
2) Generating SSL certificates for Scirius web interface and a secret key for the underlying Django
2) Creating a ``.env`` file containing environment variables deduced from the user inputs
3) Build the containers

In order to change the options you defined, just run ``easy-setup.sh`` again

Using your own SSL certificate
------------------------------
Put your existing SSL certificate and private key in ``SELKS/docker/containers-data/nginx/ssl`` as ``scirius.crt`` and ``scirius.key`` before running the ``easy-setup.sh`` script

Running the install script without user interaction
---------------------------------------------------
The script provides several command line options to avoid being prompted. This can be useful to automate SELKS deployment


Useful commands
================
Most docker-compose commands will have the following form ``docker-compose COMMAND [container-name]``
Those commands must be run from the SELKS/docker/ directory
If  no container-name is provided, it will be applied to all SELKS containers

Stopping containers
-------------------
.. code-block:: bash

  docker-compose stop [container-name]

Starting containers
-------------------
.. code-block:: bash

  docker-compose start [container-name]

Restarting containers
-------------------
.. code-block:: bash

  docker-compose restart [container-name]

Removing containers along with their data
-------------------
.. code-block:: bash

  docker-compose down -v

Recreating containers
-------------------
.. code-block:: bash

  docker-compose up [container-name] --force-recreate

Updating containers
-------------------
.. code-block:: bash

  docker-compose pull [container-name]
  docker-compose up [container-name] --force-recreate
