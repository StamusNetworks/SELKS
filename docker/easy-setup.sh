#!/bin/bash

function V() # $1-a $2-op $3-$b
# Compare a and b as version strings. Rules:
# R1: a and b : dot-separated sequence of items. Items are numeric. The last item can optionally end with letters, i.e., 2.5 or 2.5a.
# R2: Zeros are automatically inserted to compare the same number of items, i.e., 1.0 < 1.0.1 means 1.0.0 < 1.0.1 => yes.
# R3: op can be '=' '==' '!=' '<' '<=' '>' '>=' (lexicographic).
# R4: Unrestricted number of digits of any item, i.e., 3.0003 > 3.0000004.
# R5: Unrestricted number of items.
{
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

red=`tput setaf 1``tput bold`
green=`tput setaf 2``tput bold`
reset=`tput sgr0`


BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo -e "  This version of SELKS relies on docker containers. We will now check if docker is already installed\n"

dockerV=$(docker -v)


if [[ $dockerV == *"Docker version"* ]]; then
  echo -e "${green}+${reset} Docker installation found: $dockerV"
else
  echo -e "${red}-${reset} No docker installation found, see https://docs.docker.com/engine/install to learn how to install docker on your system"
  exit
fi

dockerV=$(docker version --format '{{.Server.Version}}')

if [[ -z $dockerV ]]; then
  echo -e "${red}-${reset} Docker engine is not available to the current user. Either add current user to 'docker' group (recommended) or run this script as privileged user.\n\
  See https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user"
  exit
else
  echo -e "${green}+${reset} Docker is available to the current user"
fi


if V $dockerV '<' 17.06.0; then
  echo -e "${red}-${reset} Docker version is too old, please upgrade it"
  exit
fi

dockerV=$(docker-compose version)

if [[ $dockerV == *"docker-compose version"* ]]; then
  echo -e "${green}+${reset} docker-compose installation found"
else
  echo -e "${red}-${reset} No docker-compose installation found, see https://docs.docker.com/compose/install/ to learn how to install docker-compose on your system"
  exit
fi


if $(docker ps | grep -q 'portainer'); then
  echo -e "  Found existing portainer installation, skipping...\n"
else
  echo -e "\n  Portainer is a web interface for managing docker containers. It is recommended if you are not experienced with docker."
  while true; do
      read -p "  Do you want to install Portainer ? [Y/N] " yn
      case $yn in
          [Yy]* ) docker volume create portainer_data && docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce --logo "https://www.stamus-networks.com/hubfs/stamus_logo_blue_cropped-2.png" && echo -e "${green}+${reset} Portainer has been installed and will be available on port 9000\n" || echo -e "${red}-${reset} Portainer installation failed\n";;
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

function copy_existing_certificate(){
  ####################
  # WORK IN PROGRESS #
  ####################
  
  while true; do
    read -p "  Enter the path to your certificate: " fp
    echo "${fp}"
    if [ -f "${fp}" ]; then
      cp $fp $1/scirius.crt || echo -e "${red}-${reset} Error while copying certificate"
      chmod 644 $1/scirius.crt || return 1
    else
      echo -e "File does not exist"
      continue
    fi
    
    read -p "  Enter the path to the private key associated with the certificate: " fp
    if [ -f "${fp}" ]; then
      cp $fp $1/scirius.key || echo -e "${red}-${reset} Error while copying private key"
      chmod 600 $1/scirius.key || return 1
    else
      echo -e "File does not exist"
      continue
    fi
  done

  check_key_cert $1
  return $?
}





if [ -f "${SSLDIR}/scirius.crt" ] && [ -f "${SSLDIR}/scirius.key" ]; then
  echo "  An existing certificate has been found: ${SSLDIR}/scirius.crt"
  echo "  Skipping SSL generation..."
else
  while true; do
    echo "  Stamus dashboards requires an SSL certificate for https access. You can use you own or we can generate one for you."
      read -p "  Do you want us to generate a certificate for you ? [Y/N] " yn
      case $yn in
          [Yy]* ) generate_certificate ${SSLDIR} ; break;;
          [Nn]* ) echo -e "\n  Please copy your ssl certificate and private key in ${SSLDIR} as 'scirius.crt' and 'scririus.key' and come back"; exit;; # copy_existing_certificate ${SSLDIR}; break;;
          * ) echo -e "  Please answer Y or N";;
      esac
  done
fi







#############
# INTERFACE #
#############

function getInterfaces {
  echo -e "\n\n Network interfaces detected:"
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

######################
# SURICATA LOGS PATH #
######################

echo -e "\n\nWith SELKS running, packets captures can take up a lot of disk space"
echo -e "You might want to save them on an other disk/partition"
echo -e "Current partition free space :$(df --output=avail -h . | tail -n 1 )"
echo -e "Please give the path where you want the captures to be saved, or hit enter to use the default value."
echo -e "Default : [${BASEDIR}/containers-data/suricata/log]"

read suricata_logs_path

if ! [ -z "${suricata_logs_path}" ]; then

  if ! [ -w suricata_logs_path ]; then 
    echo -e "\nYou don't seem to own write access to this directory\n"
    echo -e "Please give the path where you want the captures to be saved, or hit enter to use the default value."
    echo -e "Default : [${BASEDIR}/containers-data/suricata/log]"
    read suricata_logs_path

  fi
echo "SURICATA_LOGS_PATH=${suricata_logs_path}" >> ${BASEDIR}/.env
fi

echo "COMPOSE_PROJECT_NAME=SELKS" >> ${BASEDIR}/.env

######################
# Generate KEY FOR DJANGO           #
######################

output=$(docker run --rm -it python:3.8.6-slim-buster /bin/bash -c "python -c \"import secrets; print(secrets.token_urlsafe())\"")

echo "SCIRIUS_SECRET_KEY=${output}" >> ${BASEDIR}/.env
######################
# BUILDING           #
######################


echo -e "Building containers, this can take a while...\n"

docker-compose build >> ${BASEDIR}/build.log


######################
# Starting           #
######################
echo -e "\n\nTo start SELKS, run 'docker-compose up -d'"
