#!/bin/bash

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





















curl=$(curl -V)
if [[ -z "$curl" ]]; then
  echo -e "\n\n  Please install curl and re-run the script\n"
  exit
fi

time=$(time echo "" && echo "time is installed")
if [[ -z "$time" ]]; then
  echo -e "\n\n  Please install time and re-run the script\n"
  exit
else
  clear
fi

############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":hv:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      v) # Enter a name
         SCIRIUS_VERSION=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

red=`tput setaf 1``tput bold`
green=`tput setaf 2``tput bold`
reset=`tput sgr0`
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


echo -e "DISCLAIMER : This conveniance script comes with absolutely no warranty. It provides a quick and easy way to install SELKS on your system\n
Altough this script should run properly on major linux distribution, it has only been tested on Debian 10 (buster)\n\n
Press any key to continue or ^c to exit"
read

echo -e "  This version of SELKS relies on docker containers. We will now check if docker is already installed"

echo -e "\n"
echo "##################"
echo "#  INSTALLATION  #"
echo "##################"
echo -e "\n"

#############################
#          DOCKER           #
#############################
function test_docker_user(){
  hello=$(docker run --rm hello-world) || \
  echo "${red}-${reset} Docker test failed"
  
  if [[ $hello == *"Hello from Docker"* ]]; then
    echo -e "${green}+${reset} Docker seems to be installed properly"
  else
    echo -e "${red}-${reset} Error running docker."
    exit
  fi
}
function install_docker(){
  curl -fsSL https://get.docker.com -o get-docker.sh && \
  sh get-docker.sh && \
  echo "${green}+${reset} Docker installation succeeded" || \
  echo "${red}-${reset} Docker installation failed"
}
function adduser_to_docker(){
  sudo groupadd docker
  sudo usermod -aG docker $USER && \
  echo -e "${green}+${reset} Added user to docker group successfully \n  Please logout and login again for the group permissions to be applied, and re-run the script" || \
  echo "${red}-${reset} Error while adding user to docker group"
}
function install_docker_compose(){
  sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
  sudo chmod +x /usr/local/bin/docker-compose && \
  echo "${green}+${reset} docker-compose installation succeeded" || \
  echo "${red}-${reset} docker-compose installation failed"
}
function install_portainer(){
  docker volume create portainer_data && \
  docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce --logo "https://www.stamus-networks.com/hubfs/stamus_logo_blue_cropped-2.png" && \
  echo -e "${green}+${reset} Portainer has been installed and will be available on port 9000" || \
  echo -e "${red}-${reset} Portainer installation failed\n"
}


dockerV=$(docker -v)
if [[ $dockerV == *"Docker version"* ]]; then
  echo -e "${green}+${reset} Docker installation found: $dockerV"
else
  echo -e "${red}-${reset} No docker installation found\n\n  We can try to install docker for you"
  read -p "  Do you want to install docker automatically? [y/N] " yn
  case $yn in
      [Yy]* ) install_docker;;
      * ) echo -e "  See https://docs.docker.com/engine/install to learn how to install docker on your system"; exit;;
  esac
fi

dockerV=$(docker version --format '{{.Server.Version}}')

if [[ ! -z "$dockerV" ]]; then
  echo -e "${green}+${reset} Docker is available to the current user"
  test_docker_user
else
  echo -e "${red}-${reset} Docker engine is not available to the current user.\n  Either allow current user to execute docker commands or run this script as privileged user.\n"
  read -p "  Do you want to allow '${USER}' to run docker commands? [y/N] " yn
  case $yn in
      [Yy]* ) adduser_to_docker; exit;;
      * ) echo -e "  See https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user to learn how to allow current standard user to run docker commands."; exit;;
  esac
fi

dockerV=$(docker version --format '{{.Server.Version}}')

if Version $dockerV '<' 17.06.0; then
  echo -e "${red}-${reset} Docker version is too old, please upgrade it to 17.06.0 minimum"
  exit
fi

#############################
#      DOCKER-COMPOSE       #
#############################

dockerV=$(docker-compose --version)

if [[ $dockerV == *"docker-compose version"* ]]; then
  echo -e "${green}+${reset} docker-compose installation found"
else
  echo -e "${red}-${reset} No docker-compose installation found, see https://docs.docker.com/compose/install/ to learn how to install docker-compose on your system"
  read -p "  Do you want to install docker-compose automatically? [y/N] " yn
  case $yn in
      [Yy]* ) install_docker_compose;;
      * ) echo -e "  See https://docs.docker.com/compose/install/ to learn how to install docker-compose on your system"; exit;;
  esac
fi


dockerV=( $dockerV )
dockerV=$( echo ${dockerV[2]} |tr ',' ' ')
if Version $dockerV '<' 1.27.0; then
  echo -e "${red}-${reset} Docker version is too old, please upgrade it to 1.27.0 minimum"
  exit
fi
#############################
#         PORTAINER         #
#############################
if $(docker ps | grep -q 'portainer'); then
  echo -e "  Found existing portainer installation, skipping...\n"
else
  echo -e "\n  Portainer is a web interface for managing docker containers. It is recommended if you are not experienced with docker."
  while true; do
      read -p "  Do you want to install Portainer ? [y/n] " yn
      case $yn in
          [Yy]* ) install_portainer; break;;
          [Nn]* ) break;;
          * ) echo -e "  Please answer Y or N";;
      esac
  done
fi



#############################
# GENERATE SSL CERTIFICATES #
#############################
SSLDIR="${BASEDIR}/containers-data/nginx/ssl"

function check_key_cert(){
  # usage : check_key_cert [path_to_files] [filename_without_extension]
  # example : check_key_cert [path_to_files] [filename_without_extension]
  output=$(docker run --rm -it -v $1:/etc/nginx/ssl nginx /bin/bash -c "openssl x509 -in /etc/nginx/ssl/scirius.crt -pubkey -noout -outform pem | sha256sum; openssl pkey -in /etc/nginx/ssl/scirius.key -pubout -outform pem | sha256sum" || echo -e "${red}-${reset} Error while checking certificate against key")
  
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
function generate_certificate(){
  docker run --rm -it -v $1:/etc/nginx/ssl nginx openssl req -new -nodes -x509 -subj "/C=FR/ST=IDF/L=Paris/O=Stamus/CN=SELKS" -days 3650 -keyout /etc/nginx/ssl/scirius.key -out /etc/nginx/ssl/scirius.crt -extensions v3_ca && echo -e "${green}+${reset} Certificate generated successfully" || echo -e "${red}-${reset} Error while generating certificate with openssl"
  check_key_cert $1
  return $?
}


if [ -f "${SSLDIR}/scirius.crt" ] && [ -f "${SSLDIR}/scirius.key" ] && check_key_cert ${SSLDIR}; then
  echo -e "  A valid SSL certificate has been found:\n\t${SSLDIR}/scirius.crt"
  echo -e "  Skipping SSL generation..."
else
  generate_certificate ${SSLDIR}
fi



echo -e "\n"
echo "##################"
echo "#    SETTINGS    #"
echo "##################"
echo -e "\n"

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
  read interfaces
  
  echo -e "\nThe supplied network interface(s):  ${interfaces} \n";
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

while [[ ${INTERFACE_EXISTS} != "YES"  ]]; do
  getInterfaces
done

for interface in ${interfaces}
do
  INTERFACES_LIST=${INTERFACES_LIST}\ -i\ ${interface}
done

echo "INTERFACES=${INTERFACES_LIST}" > ${BASEDIR}/.env


##############
# DEBUG MODE #
##############


while true; do
    read -p "Do you want to use debug mode?[Y/N] " yn
    case $yn in
        [Yy]* ) echo "SCIRIUS_DEBUG=True" >> ${BASEDIR}/.env; echo "NGINX_EXEC=nginx-debug" >> ${BASEDIR}/.env; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo ""

######################
# ELASTIC DATA PATH #
######################

docker_root_dir=$(docker system info |grep "Docker Root Dir")
docker_root_dir=${docker_root_dir/'Docker Root Dir: '/''}

echo ""
echo -e "With SELKS running, database can take up a lot of disk space"
echo -e "You might want to save them on an other disk/partition"
echo -e "Docker partition free space : ${docker_root_dir} - $(df --output=avail -h ${docker_root_dir} | tail -n 1 )"
echo -e "Please give the path where you want the data to be saved, or hit enter to use a docker volume in the docker path :"

read elastic_data_path

if ! [ -z "${elastic_data_path}" ]; then

  if ! [ -w elastic_data_path ]; then 
    echo -e "\nYou don't seem to own write access to this directory\n"
    echo -e "Please give the path where you want the data to be saved, or hit enter to use a docker volume in the docker path :"
    read elastic_data_path

  fi
echo "ELASTIC_DATAPATH=${elastic_data_path}" >> ${BASEDIR}/.env
fi

echo "COMPOSE_PROJECT_NAME=SELKS" >> ${BASEDIR}/.env

######################
# Generate KEY FOR DJANGO #
######################

output=$(docker run --rm -it python:3.8.6-slim-buster /bin/bash -c "python -c \"import secrets; print(secrets.token_urlsafe())\"")

echo "SCIRIUS_SECRET_KEY=${output}" >> ${BASEDIR}/.env



######################
# Setting Scirius branch to use #
######################
if [ ! -z "${SCIRIUS_VERSION}" ] ; then
  echo "SCIRIUS_VERSION=$SCIRIUS_VERSION" >> ${BASEDIR}/.env
fi

######################
# Setting Stack name #
######################
echo "COMPOSE_PROJECT_NAME=SELKS" >> ${BASEDIR}/.env




echo -e "\n"
echo "#######################"
echo "# BUILDING CONTAINERS #"
echo "#######################"
echo -e "\n"
######################
# BUILDING           #
######################


echo -e "Building containers, this can take a while... (arround 10 minutes)\n"

now=$(date)
echo -e "BUILD : $now\n\n=========================" >> ${BASEDIR}/build.log
time docker-compose build >> ${BASEDIR}/build.log


######################
# Starting           #
######################
echo -e "\n\nTo start SELKS, run 'docker-compose up -d'"
echo -e "If you have chose to install Portainer, visit http://localhost:9000 to set your portainer password, and select the docker option"
