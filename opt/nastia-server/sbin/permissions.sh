#!/bin/bash
#
# Recursively fix file permissions
# Must run as root
#

# Path to the current directory where this script is located
DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# Include common configuration file
source "$DIR/common.sh"

# Log file
LOG="$CFG_LOG_DIR/permissions.log"


# Print an info log message
function infoLog {
  _infoLog "$1" "permissions" "$LOG" "ecd"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_INFO_LOG"
}

# Print a warning log message
function warningLog {
  _warningLog "$1" "permissions" "$LOG" "ecd"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_WARNING_LOG"
}

# Print an error log message
function errorLog {
  _errorLog "$1" "permissions" "$LOG" "ecd"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_ERROR_LOG"
}


RV=0


chown -R mysql:mysql "$CFG_MYSQL_DIR"
rv=$?; let RV=RV+rv
find "$CFG_MYSQL_DIR" -type d -exec chmod g+rwx {} +
rv=$?; let RV=RV+rv
find "$CFG_MYSQL_DIR" -type f -exec chmod g+rw {} +
rv=$?; let RV=RV+rv


chown -R www-data:www-data "$CFG_WWW_DIR"
rv=$?; let RV=RV+rv
find "$CFG_WWW_DIR" -type d -exec chmod g+rwx {} +
rv=$?; let RV=RV+rv
find "$CFG_WWW_DIR" -type f -exec chmod g+rw {} +
rv=$?; let RV=RV+rv


if [[ $RV -eq 0 ]]; then
  infoLog "succeeded to set file permissions"
else
  errorLog "failed to set file permissions (exit code $RV)"
fi


exit $RV
