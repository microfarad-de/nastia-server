#!/bin/bash
#
# Backup SD card image to external HDD
# Must run as root
#

# Path to the current directory where this script is located
DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# Include common configuration file
source "$DIR/common.sh"


# Configuration parameters
OUTDIR="$CFG_BACKUP_SD_DESTINATION"
DEVICE="$CFG_BACKUP_SD_DEVICE"
LOCK="$CFG_TMPFS_DIR/backup-sd.lock"
LOG="$CFG_LOG_DIR/backup-sd.log"


function infoLog {
  _infoLog "$1" "backup-sd" "$LOG" "ecd"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_INFO_LOG"
}

function warningLog {
  _warningLog "$1" "backup-sd" "$LOG" "ecd"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_WARNING_LOG"
}

function errorLog {
  _errorLog "$1" "backup-sd" "$LOG" "ecd"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_ERROR_LOG"
  semaphoreRelease "$LOCK"
  exit 1
}


################
#### START  ####
################

# avoid multiple instances of this script
semaphoreLock "$LOCK"
if [[ $? -ne 0 ]]; then
  warningLog "an instance of the current script is already running (please remove $LOCK)"
  exit 1
fi


# Recreate output directory
rm -rf "$OUTDIR"
rv=$?
if [[ $rv -ne 0 ]]; then
  errorLog "failed to remove $OUTDIR (exit code $rv)"
fi

mkdir -p "$OUTDIR"
rv=$?
if [[ $rv -ne 0 ]]; then
  errorLog "failed to create $OUTDIR (exit code $rv)"
fi

cd "$OUTDIR"
rv=$?
if [[ $rv -ne 0 ]]; then
  errorLog "failed to open $OUTDIR (exit code $rv)"
fi

# Read disk image and split into chunks
dd if="$DEVICE" | split -b 1000m - chunk_
rv=${PIPESTATUS[0]}
if [[ $rv -eq 0 ]]; then
  infoLog "$DEVICE backed-up to $OUTDIR"
else
  errorLog "failed to back-up $DEVICE (exit code $rv)"
fi

# Set output ownership and permissions
chown -R "$CFG_USER":"$CFG_GROUP" "$OUTDIR"
find "$OUTDIR" -type d -exec chmod "$CFG_DMODE" {} +
find "$OUTDIR" -type f -exec chmod "$CFG_FMODE" {} +

semaphoreRelease "$LOCK"
exit 0
