#!/bin/bash
#
# Stage the nastia-server software package for a GitHub commit
# This script copies all relevant files into the GitHub repository.
#

# Path to the current directory where this script is located
DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# Include common configuration file
source "$DIR/common.sh"


# Path to the GitHub repository
REPOSITORY="$CFG_GIT_REPOSITORY"


# Source directories to be copied
SOURCE[0]="/opt/nastia-server"
EXCLUDE[0]="nastia-server.local"
SOURCE[1]="/etc/cron.d/nastia-server"
SOURCE[2]="/etc/systemd/system/init.service"
SOURCE[3]="/etc/systemd/system/init-gpio.service"
SOURCE[4]="/etc/systemd/system/fan.service"
SOURCE[5]="/etc/logrotate.d/nastia-server"

# Convert array to string
for i in "${!SOURCE[@]}"; do
  if [[ "${SOURCE[$i]}" == "" ]]; then
    SOURCE_ARG="$SOURCE_ARG %"
  else
    SOURCE_ARG="$SOURCE_ARG ${SOURCE[$i]}"
  fi
  if [[ "${EXCLUDE[$i]}" == "" ]]; then
    EXCLUDE_ARG="$EXCLUDE_ARG %"
  else
    EXCLUDE_ARG="$EXCLUDE_ARG $(echo ${EXCLUDE[$i]} | tr ' ' '#')"
  fi
done


# Call the copy script
$DIR/../lib/copy.sh "$SOURCE_ARG" "$EXCLUDE_ARG" "$REPOSITORY" "" ""
rv=$?

exit $rv



