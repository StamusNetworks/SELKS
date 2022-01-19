SELKS on Docker
===============

Intro
-----

This version of SELKS is based on docker and intended to provide easier deployment and management.

For informations on standard SELKS implementation, see https://github.com/StamusNetworks/SELKS#selks

Minimum Requirements
--------------------
- 2 cores
- 8 GB of free RAM
- 10 GB of free disk space (actual disk occupation will mainly depend of the number of rules and the amount of traffic on the network). 200GB+ SSD grade is recommended.
- ``git``, ``curl``
- ``docker`` > 17.06.0 (will be installed during SELKS initial setup)
- ``docker-compose`` > 1.27.0 (will be installed during SELKS initial setup)

Install process
---------------
### Basic installation

```bash
git clone https://github.com/StamusNetworks/SELKS.git
cd SELKS/docker/
./easy-setup.sh
docker-compose up -d
```

Once the containers are up and running, you should just point your browser to `https://your.selks.IP.here/`
If you chose to install Portainer during the installation, you must visit `https://your.selks.IP.here:9443` to set portainer's admin password

If the setup script fails and you think it's a bug,  please [Report an issue](#report-an-issue). You can also take a look at the [manual setup process](https://github.com/StamusNetworks/SELKS/wiki/Manual-Docker-install) 

### Credentials and log in

In order to access scirius, you will need following credentials:

-   user: `selks-user`
-   password: `selks-user`

### Wiki

More info and details can be found on our [wiki](https://github.com/StamusNetworks/SELKS/wiki/Docker)


### Advanced installation

For detailed instructions, please visit the advanced installation guide - [wiki](https://github.com/StamusNetworks/SELKS/wiki/Docker#understanding-the-setup-script)

Report an issue
---------------

If you've encoutered an issue please let us know: [Report Issue](https://github.com/StamusNetworks/SELKS/issues/new?labels[]=Docker&title=Docker:%20Issue%20summary&body=%3C%21--%0AUse%20the%20commands%20below%20to%20provide%20key%20information%20from%20your%20environment%3A%0AYou%20do%20NOT%20have%20to%20include%20this%20information%20if%20this%20is%20a%20FEATURE%20REQUEST%0A--%3E%0A%0A%2A%2ADescription%2A%2A%0A%0A%0A%2A%2ASteps%20to%20reproduce%20the%20issue%3A%2A%2A%0A1.%0A2.%0A3.%0A%0A%2A%2ADescribe%20the%20results%20you%20received%3A%2A%2A%0A%0A%0A%2A%2ADescribe%20the%20results%20you%20expected%3A%2A%2A%0A%0A%0A%2A%2AAdditional%20information%20you%20deem%20important%20%28e.g.%20issue%20happens%20only%20occasionally%29%3A%2A%2A%0A%0A%2A%2AOutput%20of%20%60docker%20version%60%3A%2A%2A%0A%0A%60%60%60%0A%28paste%20your%20output%20here%29%0A%60%60%60%0A%0A%2A%2AOutput%20of%20%60docker-compose%20version%60%3A%2A%2A%0A%0A%60%60%60%0A%28paste%20your%20output%20here%29%0A%60%60%60%0A%0A%2A%2AOutput%20of%20%60lsb_release%20-a%60%3A%2A%2A%0A%0A%60%60%60%0A%28paste%20your%20output%20here%29%0A%60%60%60%0A%0A%2A%2AAdditional%20environment%20details%3A%2A%2A%0A)
