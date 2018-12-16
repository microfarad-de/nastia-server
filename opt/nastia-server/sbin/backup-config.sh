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
SOURCE="$CFG_BACKUP_CONFIG_SOURCE"
EXCLUDE="$CFG_BACKUP_CONFIG_EXCLUDE"
OUTDIR="$CFG_BACKUP_CONFIG_DESTINATION"
LOCK="$CFG_TMPFS_DIR/backup-config.lock"
LOG="$CFG_LOG_DIR/backup-config.log"
PREFIX="backup-config"

# Global variables
EXIT_CODE=0


# Source, exclude list, output directory and log prefix may be passed as arguments
if [[ "$1" != "" ]]; then SOURCE=($1)  ; fi
if [[ "$2" != "" ]]; then EXCLUDE=($2) ; fi
if [[ "$3" != "" ]]; then OUTDIR="$3"  ; fi
if [[ "$4" != "" ]]; then
  LOG="$CFG_LOG_DIR/$4.log"
  PREFIX="$4"
fi

README="$OUTDIR/README.txt"




# Print an info log message
function infoLog {
  _infoLog "$1" "$PREFIX" "$LOG" "ecd"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_INFO_LOG"
}

# Print a warning log message
function warningLog {
  _warningLog "$1" "$PREFIX" "$LOG" "ecd"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_WARNING_LOG"
}

# Print an error log message
function errorLog {
  _errorLog "$1" "$PREFIX" "$LOG" "ecd"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_ERROR_LOG"
  EXIT_CODE=1
}



# Main execution routine
function main {
  local source="$1"
  local options="$2"
  local dir
  local file

  # Ensure that the source files are readable
  find "$source" -type d -exec chmod u+rx {} +
  find "$source" -type f -exec chmod u+r {} +

  # Check if source is a file or a directory
  if [[ -f "$source" ]]; then
    dir=$(dirname "$source")
    file=$(basename "$source")
  else
    dir="$source"
    file=""
  fi

  # Create the output directory
  mkdir -p "$OUTDIR/$dir"
  rv=$?
  if [[ $rv -ne 0 ]]; then
    errorLog "failed to create $OUTDIR/$source (exit code $rv)"
  fi

  echo ""
  echo ""
  echo "$dir/$file:"
  rsync -rltDv --delete $options $dir/$file $OUTDIR/$dir
  local rv=$?
  if [[ $rv -ne 0 ]]; then
    errorLog "failed to back-up $source (exit code $rv)"
  fi

  if [[ "$options" != "" ]]; then
    options="($options)"
  fi
  echo "$source $options" >> "$README"
}




#################
####  START  ####
#################

# Avoid multiple instances of this script
semaphoreLock "$LOCK"
if [[ $? -ne 0 ]]; then
  warningLog "an instance of the current script is already running (please remove $LOCK)"
  exit 1
fi



# Update the readme file
echo "List of files and directories:" > "$README"


# Loop over sources
for i in "${!SOURCE[@]}"; do
  source="${SOURCE[$i]}"
  exclude="${EXCLUDE[$i]}"
  exclude=($exclude)
  options=""
  for x in "${exclude[@]}"; do
    options="$options --exclude=$x"
  done
   main "$source" "$options"
done

# Set output ownership and permissions
chown -R "$CFG_USER":"$CFG_GROUP" "$OUTDIR"
find "$OUTDIR" -type d -exec chmod "$CFG_DMODE" {} +
find "$OUTDIR" -type f -exec chmod "$CFG_FMODE" {} +

if [[ $EXIT_CODE -eq 0 ]]; then
  infoLog "backup successful"
else
  echo "errors during backup"
fi

semaphoreRelease "$LOCK"
exit $EXIT_CODE
