#!/bin/bash
#
# Backup important configuration files
# Must run as root
#
# This source file is part of the follwoing repository:
# http://www.github.com/microfarad-de/nastia-server
#
# Please visit:
#   http://www.microfarad.de
#   http://www.github.com/microfarad-de
#
# Copyright (C) 2019 Karim Hraibi (khraibi@gmail.com)
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
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Path to the current directory where this script is located
DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# Include common configuration file
source "$DIR/common.sh"



# Configuration parameters
DESTINATION="$CFG_BACKUP_CONFIG_DESTINATION"
LOG_PREFIX="backup-config"
USER="$CFG_USER"
GROUP="$CFG_GROUP"
DMODE="$CFG_DMODE"
FMODE="$CFG_FMODE"




#################
####  START  ####
#################


# Convert array to string
for i in "${!CFG_BACKUP_CONFIG_SOURCE[@]}"; do
  if [[ "${CFG_BACKUP_CONFIG_SOURCE[$i]}" == "" ]]; then
    SOURCE="$SOURCE %"
  else
    SOURCE="$SOURCE ${CFG_BACKUP_CONFIG_SOURCE[$i]}"
  fi
  if [[ "${CFG_BACKUP_CONFIG_EXCLUDE[$i]}" == "" ]]; then
    EXCLUDE="$EXCLUDE %"
  else
    EXCLUDE="$EXCLUDE $(echo ${CFG_BACKUP_CONFIG_EXCLUDE[$i]} | tr ' ' '#')"
  fi
done


# Call the copy script
$DIR/../lib/copy.sh "$SOURCE" "$EXCLUDE" "$DESTINATION" "$LOG_PREFIX" "chmod"
rv=$?

# Set output ownership and permissions
chown -R "$USER":"$GROUP" "$DESTINATION"
find "$DESTINATION" -type d -exec chmod "$DMODE" {} +
find "$DESTINATION" -type f -exec chmod "$FMODE" {} +

exit $rv
