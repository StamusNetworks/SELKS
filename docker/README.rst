===============
SELKS on Docker
===============

Intro
=====
This version of SELKS is based on docker and intended to provide easier deployment and management.

For informations on standard SELKS implementation, see https://github.com/StamusNetworks/SELKS#selks

Requirements
=====
- 2 cores
- 8 GB of free RAM
- 10 GB of free disk space
- Debian Buster (other distributions/versions are probably OK but are not officially supported)*
- ``docker`` > 17.06.0
- ``docker-compose`` > 1.27.0
- ``git``, ``curl`` and ``time``

\* If installing on other distribution, especially non debian-based, it is highly recommended to properly install and test docker and docker-compose before going through the install process

Install process
===============
.. code-block:: bash

  git clone https://github.com/StamusNetworks/SELKS.git
  cd SELKS/docker/
  ./easy-setup.sh
  docker-compose up -d
  
Once the containers are up and running, you should just point your browser to  ``https://your.selks.IP.here/``

If the setup script fails, please take a look at the manual setup process

Credentials and log in
----------------------
In order to access scirius, you will need following credentials:
 
- user: ``selks-user``
- password: ``selks-user`` 


Advanced Install
================
Note
----
The ``easy-setup.sh`` does the following :

1) Checking that docker and docker-compose are properly installed and available to the user, and installing them if needed

2) Generating SSL certificates for Scirius web interface and a secret key for the underlying Django

3) Creating a ``.env`` file containing environment variables deduced from the user inputs

4) Build the containers

In order to change the options you defined, just run ``easy-setup.sh`` again

Help
----
A help is available

.. code-block:: bash

  ./easy-setup.sh --help


Using your own SSL certificate
------------------------------
Put your existing SSL certificate and private key in ``SELKS/docker/containers-data/nginx/ssl`` as ``scirius.crt`` and ``scirius.key`` before running the ``easy-setup.sh`` script.

Running the install script without user interaction
---------------------------------------------------
The script provides several command line options to avoid being prompted. This can be useful to automate SELKS deployment. Refer to the help

.. code-block:: bash

  ./easy-setup.sh --non-interactive

Changing ELK stack version
--------------------------
You can set a specific ELK stack version

.. code-block:: bash

  ./easy-setup.sh --elk-version <version-number>

The version will be the same for Elasticsearch, Kibana and Logstash. It is not possible (and not recommended) to set them individually.

Changing scirius version
--------------------------
You can set a specific scirius version

.. code-block:: bash

  ./easy-setup.sh --scirius-version <version>

The version can be a branch name, a tag, a release number or a git sha

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
