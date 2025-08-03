#!/bin/bash
#
# Download the contents of the "Camera Uploads" folder from Dropbox
# This script depends on dropbox_uploader.sh from
# https://github.com/andreafabrizi/Dropbox-Uploader
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


# Current directory where this script is located
DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# Include common configuration file
source "$DIR/common.sh"


# Source directory in dropbox - it contains the photos to be downloaded
SOURCE_DIR="Camera Uploads"

# Local destination directory - will be created under ROOT_DIR, photos will be downloaded here
DESTINATION_DIR="CameraUploads"

# Local root folder - a sub-folder with containing the downloaded photos will be created here
ROOT_DIR="$CFG_MEDIA_ROOT_DIR/$CFG_MEDIA_DROPBOX_DIR"

# Temporary folder in dropbox - for moving photos prior to download, avoids race conditions
TEMP_DIR=$(date "+temp-%Y-%m-%d-%H%M%S")

# Log and lock files
LOG="$CFG_LOG_DIR/dropbox-photos.log"
LOCK="$CFG_TMPFS_DIR/dropbox-photos.lock"

# Commands
DROPBOX_UPLOADER="$DIR/../lib/dropbox_uploader.sh"


# Maximum number of failed command execution attempts
MAX_ATTEMPTS=5


# Print to log file
function infoLog {
  _infoLog "$1" "dropbox-photos" "$LOG" "ecd"
}

# Print warning message
function warningLog {
  _warningLog "$1" "dropbox-photos" "$LOG" "ecd"
}

# Print error message
function errorLog {
  _errorLog "$1" "dropbox-photos" "$LOG" "ecd"
  semaphoreRelease "$LOCK"
  exit 1
}

# execute a Dropbox Uploader command
function execute {
  local command=$1
  local arg1=$2
  local arg2=$3
  local logCmd=$4
  local marker=$5
  local result=""
  local rv=10
  local attempt=0

  if [[ "$marker" != "" ]]; then
    marker=" ($marker)"
  fi

  while [[ $rv -ne 0 && $attempt -lt $MAX_ATTEMPTS ]]; do
    result=$($DROPBOX_UPLOADER "$command" "$arg1" "$arg2" 2>&1)
    rv="$?"
    let attempt=attempt+1
  done

  if [[ $attempt -gt 1 && $rv -eq 0 ]]; then
    warningLog "$command $arg1 $arg2 took $attempt attempts$marker"
  elif [[ $rv -ne 0 ]]; then
    $logCmd "$command $arg1 $arg2 failed after $attempt attempts$marker"
  fi

  echo "$result"
  return $rv
}




#################
####  START  ####
#################


# Check if the script is already running
semaphoreLock "$LOCK"
if [[ $? -ne 0 ]]; then
  warningLog "an instance of the current script is already running (please remove $LOCK)"
  exit 1
fi

echo "SCRIPT STARTED"



# Check the internet connectivity
execute "info" "" "" "warningLog"
if [[ $? -ne 0 ]]; then
  semaphoreRelease "$LOCK"
  exit 1
fi


# Create the source directory if it does not exist
result=$(execute "list" "" "" "warningLog" "1" | grep "$SOURCE_DIR")
if [[ "$result" == "" ]]; then
  execute "mkdir" "$SOURCE_DIR" "" "warningLog" "1"
fi


# Check if the source folder contains pictures
result=$(execute "list" "$SOURCE_DIR" "" "warningLog" "2" 2>&1)
echo "$result"
if [[ "$result" != *"[F]"* ]]; then
  echo "No photos to download"
  semaphoreRelease "$LOCK"
  exit 0
fi


# Create root directory if does not exist
install -d "$ROOT_DIR"
rv="$?"
if [[ $rv -ne  0 ]]; then
  errorLog "install returned $rv"
fi


# Move photos to temporary directory
execute "move" "$SOURCE_DIR" "$TEMP_DIR/$DESTINATION_DIR" "errorLog"


# Re-create the source directory
result=$(execute "list" "" "" "warningLog" "3" | grep "$SOURCE_DIR")
if [[ "$result" == "" ]]; then
  execute "mkdir" "$SOURCE_DIR" "" "warningLog" "2"
fi


# Download photos
infoLog "DOWNLOADING..."
execute "download" "$TEMP_DIR/$DESTINATION_DIR" "$ROOT_DIR" "errorLog" >> "$LOG"


# Delete temporary directory
execute "delete" "$TEMP_DIR" "" "warningLog"


echo "SUCCESS"

# Release lock
semaphoreRelease "$LOCK"
exit 0

