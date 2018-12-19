#!/bin/bash
#
# Backup important configuration files
# Must run as root
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
