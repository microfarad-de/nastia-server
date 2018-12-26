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

EXIT_CODE=0

# Print an info log message
function infoLog {
  _infoLog "$1" "permissions" "$LOG" "ecd"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_INFO_LOG" > /dev/null 2>&1
}

# Print a warning log message
function warningLog {
  _warningLog "$1" "permissions" "$LOG" "ecd"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_WARNING_LOG" > /dev/null 2>&1
}

# Print an error log message
function errorLog {
  _errorLog "$1" "permissions" "$LOG" "ecd"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_ERROR_LOG" > /dev/null 2>&1
  EXIT_CODE=1
}


function main {
  local dir="$1"
  local user="$2"
  local group="$3"
  local dmode="$4"
  local fmode="$5"

  chown -R "$user":"$group" "$dir"
  echo chown -R "$user":"$group" "$dir"
  rv=$?;
  if [[ $rv -ne 0 ]]; then
    errorLog "chown $user:$group $dir failed (exit code $rv)"
  fi
  echo find "$dir" -type d -exec chmod "$dmode" {} +
  find "$dir" -type d -exec chmod "$dmode" {} +
  rv=$?
  if [[ $rv -ne 0 ]]; then
    errorLog "chmod $dmode $dir (d) failed (exit code $rv)"
  fi
  echo find "$dir" -type f -exec chmod "$fmode" {} +
  find "$dir" -type f -exec chmod "$fmode" {} +
  rv=$?
  if [[ $rv -ne 0 ]]; then
    errorLog "chmod $fmode $dir (f) failed (exit code $rv)"
  fi
}


#################
####  START  ####
#################



# Loop over config items
for i in "${!CFG_PERMISSION_SET[@]}"; do
  main ${CFG_PERMISSION_SET[$i]}
done

if [[ $EXIT_CODE -eq 0 ]]; then
  infoLog "permissions applied successfully"
fi

exit $EXIT_CODE
