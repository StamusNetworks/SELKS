#!/bin/bash

# Copyright Stamus Networks
# All rights reserved
# Debian Live ISO script - oss@stamus-networks.com
#

set -e

# Install needed packages for default build
apt-get -y install xorriso live-build syslinux squashfs-tools python-docutils

# Install needed packages for the choose your own kernel option
apt-get -y install wget fakeroot kernel-package gcc libncurses5-dev bc \
ca-certificates pkg-config make flex bison build-essential autoconf \
automake aptitude