#!/bin/bash
#
# Initialization Script
# This script is called by systemd after booting the system.
# Must run as root
#

# Current directory where this script is located
DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# Include common configuration file
source "$DIR/common.sh"



# Configuration parameters
LOG="$CFG_LOG_DIR/init.log"  # Main log file


# Print info message to log file
function infoLog {
  _infoLog "$1" "init" "$LOG" "ecdp"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_INFO_LOG"
}

# Print warning message to log file
function warningLog {
  _warningLog "$1" "init" "$LOG" "ecdp"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_WARNING_LOG"
}

# Print error message to log file
function errorLog {
  _errorLog "$1" "init" "$LOG" "ecdp"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_ERROR_LOG"
  exit 1
}



#################
####  START  ####
#################

infoLog "system startup..."

# Disable WLAN
if [[ $CFG_WLAN_DISABLE -eq 1 ]]; then
  /bin/sleep 10
  /sbin/ifconfig "$CFG_WLAN_INTERFACE" down
  rv=$?
  if [[ $rv -eq 0 ]]; then
    infoLog "$CFG_WLAN_INTERFACE disabled"
  else
    errorLog "failed to disable $CFG_WLAN_INTERFACE (exit code $?)"
  fi
fi

exit 0


