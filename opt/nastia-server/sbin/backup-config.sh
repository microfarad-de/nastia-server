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
SOURCE=(${CFG_BACKUP_CONFIG_SOURCE[*]})
EXCLUDE=(${CFG_BACKUP_CONFIG_EXCLUDE[*]})
DESTINATION="$CFG_BACKUP_CONFIG_DESTINATION"
LOG_PREFIX="backup-config"
USER="$CFG_USER"
GROUP="$CFG_GROUP"
DMODE="$CFG_DMODE"
FMODE="$CFG_FMODE"




#################
####  START  ####
#################



# Call the copy script
$DIR/../lib/copy.sh "${SOURCE[*]}" "${EXCLUDE[*]}" "$DESTINATION" "$LOG_PREFIX"
rv=$?

# Set output ownership and permissions
chown -R "$USER":"$GROUP" "$OUTDIR"
find "$OUTDIR" -type d -exec chmod "$DMODE" {} +
find "$OUTDIR" -type f -exec chmod "$FMODE" {} +

exit rv
