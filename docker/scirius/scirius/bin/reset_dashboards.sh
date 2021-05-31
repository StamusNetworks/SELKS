#!/bin/bash

# Copyright(C) 2019, Stamus Networks
# All rights reserved
# Written by Raphaël Brogat <rbrogat@stamus-networks.com>
#
# Designed for Debian
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

cd /opt/scirius/

KIBANA_LOADED="/data/kibana_dashboards"

reset_dashboards() {
    for I in $(seq 0 20); do
        python manage.py kibana_reset 2>/dev/null && return 0
        echo "Kibana dashboards reset: Elasticsearch not ready, retrying in 10 seconds."
        sleep 10
    done
    return -1
}


if [ ! -e $KIBANA_LOADED ]; then
    reset_dashboards && touch $KIBANA_LOADED
fi
