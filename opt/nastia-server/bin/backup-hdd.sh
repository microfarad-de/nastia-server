#!/bin/bash
#
# This script performs an incremental backup from SRC to DST
# emulating the behavior of Apple Time Machine
#

# Path to the current directory where this script is located
DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# Include common configuration file
source "$DIR/common.sh"

# Configuration parameters
SRC="${CFG_BACKUP_SOURCE[*]}"
DST="$CFG_BACKUP_DESTINATION"
EXCLUDE=($CFG_BACKUP_EXCLUDE)
OPTIONS="-av" # -a = -rlptgoD
LOCK="$CFG_TMPFS_DIR/backup-hdd.lock"
LOG="$CFG_LOG_DIR/backup-hdd.log"
CLEANUP_SCRIPT="$DIR/../lib/cleanup.py"
DATE=$(date "+%Y-%m-%d-%H%M%S")

# Global variables
DRYRUN=""


# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
exec > >(tee -i -a "$LOG")
exec 2>&1

# Info log messages
function infoLog {
  _infoLog "$1" "backup-hdd" "" "c"
}

# Warning log messages
function warningLog {
  _warningLog "$1" "backup-hdd" "" "ec"
}

# Error log messages
function errorLog {
  _errorLog "$1" "backup-hdd" "" "ec"
}



################
#### START  ####
################



# Parse the the argument if available
if [[ "$1" = "--dry-run" ]]; then
  DRYRUN="--dry-run"
fi

# Avoid multiple instances of this script
if [[ "$DRYRUN" == "" ]]; then
  semaphoreLock "$LOCK"
  if [[ $? -ne 0 ]]; then
    warningLog "an instance of the current script is already running (please remove $LOCK)"
    exit 1
  fi
fi

echo " "
echo " "
echo "##############################"
echo "Backup Started"
date
echo "##############################"
echo " "

if [[ "$DRYRUN" != "" ]]; then
  infoLog "dry run, no files will be backed-up"
  echo "***   D r y   R u n   ***"
  echo " "
fi


# Process excluded file list
for x in "${EXCLUDE[@]}"; do
  OPTIONS="$OPTIONS --exclude=$x"
done

# Remove temprary folders
if [[ "$DRYRUN" == "" ]]; then
  rm -rf $DST/*.inprogress
fi

rsync $OPTIONS $DRYRUN --link-dest=$DST/Latest ${SRC[@]} $DST/$DATE.inprogress
rv=$?

# Backup successful
if [[ $rv -eq 0 || $rv -eq 23 || $rv -eq 24 ]]; then
  if [[ "$DRYRUN" == "" ]]; then
    mv "$DST/$DATE.inprogress" "$DST/$DATE"
    rm -f "$DST/Latest"
    ln -s "$DATE" "$DST/Latest"
    infoLog "backup successful: $DATE"
  fi
  if [[ $rv -eq 23 ]]; then
    warningLog "rsync returned $rv (partial transfer due to error)"
  fi
  if [[ $rv -eq 24 ]]; then
    warningLog "rsync returned $rv (partial transfer due to vanished source files)"
  fi
  # delete old backups and check free disk space
  $CLEANUP_SCRIPT "$DST" "$DRYRUN"

# Backup failed
else
  errorLog "rsync returned $rv"
  if [[ "$DRYRUN" == "" ]]; then
    semaphoreRelease "$LOCK"
  fi
  exit 1
fi

if [[ "$DRYRUN" == "" ]]; then
  semaphoreRelease "$LOCK"
fi
exit 0
