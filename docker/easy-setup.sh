#!/bin/bash
#
# Copyright(C) 2021, Stamus Networks
# Written by Raphaël Brogat <rbrogat@stamus-networks.com> based on the work of Peter Manev <pmanev@stamus-networks.com>
#
# Please run on Debian
#
# This script comes with ABSOLUTELY NO WARRANTY!
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

MINIMAL_DOCKER_VERSION="17.06.0"
MINIMAL_COMPOSE_VERSION="1.27.0"

############################################################
# Help Function                                           #
############################################################
function Help(){
  # Display Help
  { echo
    echo "SELKS setup script"
    echo
    echo -e "\t Syntax: easy-setup.sh [-h|--help] [-d|--debug] [-i|--interfaces <eth0 eth1 eth2 ...>] [-n|--non-interactive] [--skip-checks] [--scirius-version <version>] [--elk-version <version>] [--es-datapath <path>]"
    echo
    echo "OPTIONS"
    echo -e " -h, --help"
    echo -e "       Display this help menu\n"
    echo -e " -d,--debug"
    echo -e "       Activate debug mode for scirius and nginx."
    echo -e "       The interactive prompt regarding this option will be skipped\n"
    echo -e " -i,--interface <interface>"
    echo -e "       Defines an interface on which SELKS should listen."
    echo -e "       This options can be called multiple times. Ex : easy-setup.sh -i eth0 -i eth1"
    echo -e "       The interactive prompt regarding this option will be skipped\n"
    echo -e " -n,--non-interactive"
    echo -e "       Run the script without interacive prompt. This will activate the '--skip-checks' option. '--interfaces' option is required\n"
    echo -e " --iD,--install-docker"
    echo -e "       Install docker\n"
    echo -e " --iC,--install-docker-compose"
    echo -e "       Install docker-compose\n"
    echo -e " --iP,--install-portainer"
    echo -e "       Install portainer\n"
    echo -e " --iA,--install-all"
    echo -e "       equivalent to \"-iD -iC -iP\", install docker, docker-compose and portainer\n"
    echo -e " -s,--skip-checks"
    echo -e "       Run the scirpt without checking if docker and docker-compose are installed. Use this only if you know that both docker and docker-compose are already installed with proper versions. Otherwise, the script will probably fail\n"
    echo -e " --scirius-version <version>"
    echo -e "       Defines the version of scirius to use. The version can be a branch name, a github tag or a commit hash. Default is 'master'\n"
    echo -e " --elk-version <version>"
    echo -e "       Defines the version of the ELK stack to use. Default is '7.15.1'. The version should match a tag of Elasticsearch, Kibana and Logstash images on the dockerhub\n"
    echo -e " --es-datapath <path>"
    echo -e "       Defines the path where Elasticsearch will store it's data. The path must already exists and the current user must have write permissions. Default will be in a named docker volume ('/var/lib/docker')"
    echo -e "       The interactive prompt regarding this option will be skipped\n"
    echo -e " --es-memory"
    echo -e "       Amount of memory to give to the elasticsearch java heap. Accepted units are 'm','M','g','G'. ex \"--es-memory 512m\" or \"--es-memory 4G\". Default is '2G'\n"
    echo -e " --ls-memory"
    echo -e "       Amount of memory to give to the logstash java heap. Accepted units are 'm','M','g','G'. ex \"--es-memory 512m\" or \"--es-memory 4G\". Default is '2G'\n"
    echo -e " --restart-mode"
    echo -e "       'no': never restart automatically the containers, 'always': automatically restart the containers even if they have been manually stopped, 'on-failure': only restart the containers if they failed,'unless-stopped': always restart the container except if it has been manually stopped"
    echo -e " --print-options"
    echo -e "       Print how the command line options have been interpreted \n"
  } | fmt
}

############################################################
# Docker-related Functions                                 #
############################################################
function is_docker_installed(){
  dockerV=$(docker -v 2>/dev/null)
  if [[ "${dockerV}" == *"Docker version"* ]]; then
    echo "yes"
  else
    echo "no"
  fi
}
function is_compose_installed(){
  composeV=$(docker-compose --version 2>/dev/null)
  if [[ $composeV == *"docker-compose version"* ]]; then
    echo "yes"
  else
    echo "no"
  fi
}
function is_docker_availabale_for_user(){
  dockerV=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
  if [[ ! -z "$dockerV" ]]; then
    echo "yes"
  else
    echo "no"
  fi
}
function test_docker(){
  hello=$(docker run --rm hello-world) || \
  echo "${red}-${reset} Docker test failed"
  
  if [[ $hello == *"Hello from Docker"* ]]; then
    echo -e "${green}+${reset} Docker seems to be installed properly"
  else
    echo -e "${red}-${reset} Error running docker."
    exit 1
  fi
}
function install_docker(){
  curl -fsSL https://get.docker.com -o get-docker.sh && \
  sh get-docker.sh || \
  { echo "${red}-${reset} Docker installation failed" && exit ; }
  echo "${green}+${reset} Docker installation succeeded"
  systemctl enable docker && \
  systemctl start docker
}
function install_docker_compose(){
  curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
  chmod +x /usr/local/bin/docker-compose && \
  echo "${green}+${reset} docker-compose installation succeeded" || \
  { echo "${red}-${reset} docker-compose installation failed" && exit ; }
}
function install_portainer(){
  docker volume create portainer_data && \
  docker run -d -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce --logo "https://www.stamus-networks.com/hubfs/stamus_logo_blue_cropped-2.png" && \
  PORTAINER_INSTALLED="true" && \
  echo -e "${green}+${reset} Portainer has been installed and will be available on port 9443" || \
  echo -e "${red}-${reset} Portainer installation failed\n"
}
function Version(){
  # $1-a $2-op $3-$b
  # Compare a and b as version strings. Rules:
  # R1: a and b : dot-separated sequence of items. Items are numeric. The last item can optionally end with letters, i.e., 2.5 or 2.5a.
  # R2: Zeros are automatically inserted to compare the same number of items, i.e., 1.0 < 1.0.1 means 1.0.0 < 1.0.1 => yes.
  # R3: op can be '=' '==' '!=' '<' '<=' '>' '>=' (lexicographic).
  # R4: Unrestricted number of digits of any item, i.e., 3.0003 > 3.0000004.
  # R5: Unrestricted number of items.
  local a=$1 op=$2 b=$3 al=${1##*.} bl=${3##*.}
  while [[ $al =~ ^[[:digit:]] ]]; do al=${al:1}; done
  while [[ $bl =~ ^[[:digit:]] ]]; do bl=${bl:1}; done
  local ai=${a%$al} bi=${b%$bl}

  local ap=${ai//[[:digit:]]} bp=${bi//[[:digit:]]}
  ap=${ap//./.0} bp=${bp//./.0}

  local w=1 fmt=$a.$b x IFS=.
  for x in $fmt; do [ ${#x} -gt $w ] && w=${#x}; done
  fmt=${*//[^.]}; fmt=${fmt//./%${w}s}
  printf -v a $fmt $ai$bp; printf -v a "%s-%${w}s" $a $al
  printf -v b $fmt $bi$ap; printf -v b "%s-%${w}s" $b $bl

  case $op in
    '<='|'>=' ) [ "$a" ${op:0:1} "$b" ] || [ "$a" = "$b" ] ;;
    * )         [ "$a" $op "$b" ] ;;
  esac
}
function check_docker_version(){
  dockerV=$(docker version --format '{{.Server.Version}}')

  if Version $dockerV '<' "${MINIMAL_DOCKER_VERSION}"; then
    echo -e "${red}-${reset} Docker version is too old, please upgrade it to ${MINIMAL_DOCKER_VERSION} minimum"
    exit
  fi
}
function check_compose_version(){
  composeV=$(docker-compose --version)
  composeV=( $composeV )
  composeV=$( echo ${composeV[2]} |tr ',' ' ')

  if Version $composeV '<' "${MINIMAL_COMPOSE_VERSION}"; then
    echo -e "${red}-${reset} Docker version is too old, please upgrade it to ${MINIMAL_COMPOSE_VERSION} minimum"
    exit
  fi
}

##################################################################################
#                                    START                                       #
##################################################################################

# Parse command-line options

# Option strings
SHORT=hdi:ns
LONG=help,debug,interfaces:,non-interactive,skip-checks,install-docker,iD,install-docker-compose,iC,install-portainer,iP,install-all,iA,scirius-version:,elk-version:,es-datapath:,es-memory:,print-options

# read the options
OPTS=$(getopt -o $SHORT -l $LONG --name "$0" -- "$@")

if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi

eval set -- "$OPTS"

# set initial values
INTERACTIVE="true"
DEBUG="false"
SKIP_CHECKS="false"
INTERFACES=""
ELASTIC_DATAPATH=""
ELASTIC_MEMORY=""
PRINT_PARAM="false"
INSTALL_PORTAINER="false"
INSTALL_DOCKER="false"
INSTALL_COMPOSE="false"

# extract options and their arguments into variables.
while true ; do
  case "${1}" in
    -h | --help )
      Help
      exit
      ;;
    --print-options )
      PRINT_PARAM="true"
      shift
      ;;
    -d | --debug )
      DEBUG="true"
      shift
      ;;
    -i | --interfaces )
      INTERFACES="${INTERFACES} $2"
      shift 2
      ;;
    -n | --non-interactive )
      INTERACTIVE="false"
      shift
      ;;
    -s | --skip-checks )
      SKIP_CHECKS="true"
      shift
      ;;
    --iD | --install-docker )
      INSTALL_DOCKER="true"
      shift
      ;;
    --iC | --install-docker-compose )
      INSTALL_COMPOSE="true"
      shift
      ;;
    --iP | --install-portainer )
      INSTALL_PORTAINER="true"
      shift
      ;;
    --iA | --install-all )
      INSTALL_DOCKER="true"
      INSTALL_COMPOSE="true"
      INSTALL_PORTAINER="true"
      shift
      ;;
    --scirius-version )
      SCIRIUS_VERSION="$2"
      shift 2
      ;;
    --elk-version)
      ELK_VERSION="$2"
      shift 2
      ;;
    --es-datapath)
      ELASTIC_DATAPATH="$2"
      shift 2
      ;;
    --es-memory)
      ELASTIC_MEMORY="$2"
      shift 2
      ;;
    --ls-memory)
      LOGSTASH_MEMORY="$2"
      shift 2
      ;;
    --restart-mode)
      RESTART_MODE="$2"
      shift 2
      ;;
      
    -- )
      shift
      break
      ;;
    *)
      echo "No such option '${1}'"
      exit 1
      ;;
  esac
done

if [[ "${INTERACTIVE}" == "false" ]] && [[ "${INTERFACES}" == "" ]]; then
  echo "ERROR: --non-interactive option must be use with --interface option"
  exit 1
fi

if [[ "${PRINT_PARAM}" == "true" ]]; then
  # Print the variables
  echo "DEBUG = ${DEBUG}"
  echo "INTERFACES = ${INTERFACES}"
  echo "INTERACTIVE = ${INTERACTIVE}"
  echo "SKIP_CHECKS = ${SKIP_CHECKS}"
  echo "INSTALL_PORTAINER = ${INSTALL_PORTAINER}"
  echo "SCIRIUS_VERSION = ${SCIRIUS_VERSION}"
  echo "ELK_VERSION = ${ELK_VERSION}"
  echo "ELASTIC_DATAPATH = ${ELASTIC_DATAPATH}"
  if [[ "${INTERACTIVE}" == "true" ]] ; then
    read
  fi
  exit 0
fi


#################################################
# Check if root and curl are needed             #
#################################################


if [[ $(is_docker_installed) == "no" || $(is_compose_installed) == "no" ]]; then
  if [[ $EUID -ne 0 ]]; then
   ROOT_NEEDED="true"
  fi
  if [[ -z "$(curl -V)" ]]; then
    CURL_NEEDED="true"
  fi
else
  if [[ $(is_docker_availabale_for_user) == "no" ]]; then
    ROOT_NEEDED="true"
  fi
fi

if [[ "${CURL_NEEDED}" == "true" && "${ROOT_NEEDED}" == "true" ]]; then
  echo "Curl not found. Please install curl and re-run this script as root or with sudo"
  exit 1
fi

if [[ "${ROOT_NEEDED}" == "true" ]]; then
  echo "Please run this script as root or with sudo"
  exit 1
fi


##########################
# Set the colors         #
##########################

red=`tput setaf 1``tput bold`
green=`tput setaf 2``tput bold`
reset=`tput sgr0`
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


echo -e "DISCLAIMER : This script comes with absolutely no warranty. It provides a quick and easy way to install SELKS on your system\n
Altough this script should run properly on major linux distribution, it has only been tested on Debian 10, Debian 11, Ubuntu 20.04 and Centos 8\n"

if [[ "${INTERACTIVE}" == "true" ]] ; then
  echo "Press any key to continue or ^c to exit"
  read
fi
echo -e "  This version of SELKS relies on docker containers. We will now check if docker is already installed"

echo -e "\n"
echo "##################"
echo "#  INSTALLATION  #"
echo "##################"
echo -e "\n"

if [[ "${SKIP_CHECKS}" == "false" ]] ; then
  
  #############################
  #          DOCKER           #
  #############################  

  if [[ $(is_docker_installed) == "yes" ]]; then
    echo -e "${green}+${reset} Docker installation found: $(docker -v)"
  else
    echo -e "${red}-${reset} No docker installation found\n\n  We can try to install docker for you"
    echo -e "  Do you want to install docker automatically? [y/N] "
    if [[ "${INSTALL_DOCKER}" == "true" ]]; then
      yn="y"
      echo "y"
    else
      if [[ "${INTERACTIVE}" == "true" ]]; then
        read yn
      else
        yn="N"
        echo "N"
      fi
    fi
    case $yn in
        [Yy]* ) install_docker;;
        * ) echo -e "  See https://docs.docker.com/engine/install to learn how to install docker on your system"; exit;;
    esac
  fi

  check_docker_version

  test_docker

  #############################
  #      DOCKER-COMPOSE       #
  #############################

  if [[ "$(is_compose_installed)" == "yes" ]]; then
    echo -e "${green}+${reset} docker-compose installation found"
  else
    echo -e "${red}-${reset} No docker-compose installation found, see https://docs.docker.com/compose/install/ to learn how to install docker-compose on your system"
    echo -e "  Do you want to install docker-compose automatically? [y/N] "
    if [[ "${INSTALL_COMPOSE}" == "true" ]]; then
      yn="y"
      echo "y"
    else
      if [[ "${INTERACTIVE}" == "true" ]]; then
        read yn
      else
        yn="N"
        echo "N"
      fi
    fi
    case $yn in
        [Yy]* ) install_docker_compose;;
        * ) echo -e "  See https://docs.docker.com/compose/install/ to learn how to install docker-compose on your system"; exit;;
    esac
  fi

  check_compose_version


  #############################
  #         PORTAINER         #
  #############################
  
  if $(docker ps | grep -q 'portainer'); then
    echo -e "  Found existing portainer installation, skipping...\n"
  else
    echo -e "\n  Portainer is a web interface for managing docker containers. It is recommended if you are not experienced with docker."
    while true; do
        echo -e "  Do you want to install Portainer ? [y/n] "
        if [[ "${INSTALL_PORTAINER}" == "true" ]]; then
          yn="y"
          echo "y"
        else
          if [[ "${INTERACTIVE}" == "true" ]]; then
            read yn
          else
            yn="N"
            echo "N"
          fi
        fi
        case $yn in
            [Yy]* ) install_portainer; break;;
            [Nn]* ) break;;
            * ) echo -e "  Please answer Y or N";;
        esac
    done
  fi
  
fi

#############################
# GENERATE SSL CERTIFICATES #
#############################
SSLDIR="${BASEDIR}/containers-data/nginx/ssl"

function check_scirius_key_cert(){
  # usage : check_scirius_key_cert [path_to_files] [filename_without_extension]
  # example : check_scirius_key_cert [path_to_files] [filename_without_extension]
  output=$(docker run --rm -it -v ${1}:/etc/nginx/ssl nginx /bin/bash -c "openssl x509 -in /etc/nginx/ssl/scirius.crt -pubkey -noout -outform pem | sha256sum; openssl pkey -in /etc/nginx/ssl/scirius.key -pubout -outform pem | sha256sum" || echo -e "${red}-${reset} Error while checking certificate against key")
  
  SAVEIFS=$IFS   # Save current IFS
  IFS=$'\n'      # Change IFS to new line
  output=($output) # split to array $names
  IFS=$SAVEIFS   # Restore IFS
  
  if [[ ${output[0]}==${output[1]} ]]; then
    echo -e "${green}+${reset} Certificate match private key"
    return 0
  else
    echo -e "${red}-${reset} Certificate does not match private key"
    echo -e "${output[0]}"
    echo -e "${output[1]}"
    return 1

  fi
}
function generate_scirius_certificate(){
  docker run --rm -it -v ${1}:/etc/nginx/ssl nginx openssl req -new -nodes -x509 -subj "/C=FR/ST=IDF/L=Paris/O=Stamus/CN=SELKS" -days 3650 -keyout /etc/nginx/ssl/scirius.key -out /etc/nginx/ssl/scirius.crt -extensions v3_ca && echo -e "${green}+${reset} Certificate generated successfully" || echo -e "${red}-${reset} Error while generating certificate with openssl"
  check_scirius_key_cert ${1}
  return $?
}


if [ -f "${SSLDIR}/scirius.crt" ] && [ -f "${SSLDIR}/scirius.key" ] && check_scirius_key_cert ${SSLDIR}; then
  echo -e "  A valid SSL certificate has been found:\n\t${SSLDIR}/scirius.crt"
  echo -e "  Skipping SSL generation..."
else
  generate_scirius_certificate ${SSLDIR}
fi



echo -e "\n"
echo "##################"
echo "#    SETTINGS    #"
echo "##################"
echo -e "\n"


######################
# Setting Stack name #
######################
echo "COMPOSE_PROJECT_NAME=SELKS" > ${BASEDIR}/.env

#############
# INTERFACE #
#############

function getInterfaces {
  echo -e " Network interfaces detected:"
  intfnum=0
  for interface in $(ls /sys/class/net); do echo "${intfnum}: ${interface}"; ((intfnum++)) ; done
  
  echo -e "Please type in interface or space delimited interfaces below and hit \"Enter\"."
  echo -e "Choose the interface(s) that is (are) one the network(s) you want to monitor"
  echo -e "Example: eth1"
  echo -e "OR"
  echo -e "Example: eth1 eth2 eth3"
  echo -e "\nConfigure threat detection for INTERFACE(S): "
  
  if [[ "${INTERFACES}" == "" ]] && [[ "${INTERACTIVE}" == "true" ]]; then
    read interfaces
  else
    echo "${INTERFACES}"
    interfaces=${INTERFACES}
  fi
    
  echo -e "\nThe supplied network interface(s):  ${interfaces}"
  echo "";
  INTERFACE_EXISTS="YES"
  if [ -z "${interfaces}" ] ; then
    echo -e "\nNo input provided at all."
    echo -e "Exiting with ERROR...."
    INTERFACE_EXISTS="NO"
    exit 1
  fi
  
  for interface in ${interfaces}
  do
    if ! cat /sys/class/net/${interface}/operstate > /dev/null 2>&1 ; then
        echo -e "\nUSAGE: `basename $0` -> the script requires at least 1 argument - a network interface!"
        echo -e "#######################################"
        echo -e "Interface: ${interface} is NOT existing."
        echo -e "#######################################"
        echo -e "Please supply a correct/existing network interface or check your spelling.\n"
        INTERFACE_EXISTS="NO"
    fi
    
  done
}


getInterfaces

while [[ ${INTERFACE_EXISTS} == "NO"  ]]; do
  INTERFACES=""
  if [[ ${INTERACTIVE} == "false" ]]; then
    echo "This interface does not exists"
    exit 1
  fi
  getInterfaces
done

for interface in ${interfaces}
do
  INTERFACES_LIST=${INTERFACES_LIST}\ -i\ ${interface}
done

echo "INTERFACES=${INTERFACES_LIST}" >> ${BASEDIR}/.env


##############
# DEBUG MODE #
##############

echo -e "Do you want to use debug mode? [y/N] "
if [[ "${DEBUG}" == "true" ]]; then
  echo "y"
  yn="y"
else
  if [[ ${INTERACTIVE} == "true" ]]; then
    read yn
  else
    echo "N"
    yn="n"
  fi
fi
case $yn in
    [Yy]* ) echo "SCIRIUS_DEBUG=True" >> ${BASEDIR}/.env; echo "NGINX_EXEC=nginx-debug" >> ${BASEDIR}/.env; break;;
    * ) ;;
esac

echo

################
# RESTART MODE #
################

echo -e "Do you want the containers to restart automatically on startup? [Y/n] "
if [[ ! -z "${RESTART_MODE}" ]]; then
  echo "${RESTART_MODE}"
  yn="${RESTART_MODE}"
else
  if [[ ${INTERACTIVE} == "true" ]]; then
    read answer
  else
    echo "Y"
    yn="Y"
  fi
fi
case $yn in
    [Nn]* ) echo "RESTART_MODE=on-failure" >> ${BASEDIR}/.env; break;;
    * ) ;;
esac

echo

######################
# ELASTIC DATA PATH #
######################

docker_root_dir=$(docker system info |grep "Docker Root Dir")
docker_root_dir=${docker_root_dir/'Docker Root Dir: '/''}

echo ""
echo -e "By default, elasticsearch database is stored in a docker volume in ${docker_root_dir} (free space: $(df --output=avail -h ${docker_root_dir} | tail -n 1 )"
echo -e "With SELKS running, database can take up a lot of disk space"
echo -e "You might want to save them on an other disk/partition"
echo -e "Alternatively, You can specify a path where you want the data to be saved, or hit enter for default."

if [[ "${ELASTIC_DATAPATH}" == "" ]] && [[ "${INTERACTIVE}" == "true" ]]; then
  read elastic_data_path
else
  echo "${ELASTIC_DATAPATH}"
  elastic_data_path=${ELASTIC_DATAPATH}
fi

if ! [ -z "${elastic_data_path}" ]; then

  while ! [ -w "${elastic_data_path}" ]; do 
    echo -e "\nYou don't seem to own write access to this directory\n"
    echo -e "You can specify a path where you want the data to be saved, or hit ENTER to use a [docker volume]."
    if [[ "${INTERACTIVE}" == "true" ]]; then
      read elastic_data_path
    else
      exit
    fi

  done
echo "ELASTIC_DATAPATH=${elastic_data_path}" >> ${BASEDIR}/.env
fi

#####################
# ELASTIC MEMORY    #
#####################
: '
echo -e "By default, elasticsearch will get attributed 2G of RAM"
echo -e "You can specify a different value or hit enter : [2G]"
echo -e "(Accepted units are 'm','M','g','G'. Ex: \"512m\" or \"4G\")"

if [[ "${ELASTIC_MEMORY}" == "" ]] && [[ "${INTERACTIVE}" == "true" ]]; then
  read ELASTIC_MEMORY
else
  echo "${ELASTIC_MEMORY}"
fi

if ! [ -z "${ELASTIC_MEMORY}" ]; then
  echo "ELASTIC_MEMORY=${ELASTIC_MEMORY}" >> ${BASEDIR}/.env
fi
'

###########################
# Generate KEY FOR DJANGO #
###########################

output=$(docker run --rm -it python:3.9.5-slim-buster /bin/bash -c "python -c \"import secrets; print(secrets.token_urlsafe())\"")

echo "SCIRIUS_SECRET_KEY=${output}" >> ${BASEDIR}/.env



##################################
# Setting Scirius branch to use #
##################################
if [ ! -z "${SCIRIUS_VERSION}" ] ; then
  echo "SCIRIUS_VERSION=$SCIRIUS_VERSION" >> ${BASEDIR}/.env
fi

#############################
# Setting ELK VERSION to use #
#############################
if [ ! -z "${ELK_VERSION}" ] ; then
  echo "ELK_VERSION=$ELK_VERSION" >> ${BASEDIR}/.env
fi


#######################################
# Disable ML if SSE 4.2 not supported #
#######################################

if ! grep -q sse4_2 /proc/cpuinfo; then
  echo "ML_ENABLED=false" >> ${BASEDIR}/.env
fi



echo -e "\n"
echo "#######################"
echo "# CREATING CONTAINERS #"
echo "#######################"
echo -e "\n"
######################
# BUILDING           #
######################

echo -e "Pulling containers \n"

docker-compose pull || exit


######################
# Starting           #
######################
echo -e "\n\n${green}To start SELKS, run 'sudo docker-compose up -d'${reset}\n"

if [[ "$PORTAINER_INSTALLED" == "true" ]]; then
  echo -e "${red}IMPORTANT:${reset} You chose to install Portainer, visit https://localhost:9443 to set your portainer admin password"
fi
