#!/bin/bash
#
# Recursively copy a list files or directories 
#

# Path to the current directory where this script is located
_LIB_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# Include common configuration file
source "$_LIB_DIR/common.sh"



# Global variables
EXIT_CODE=0
LOG=""
LOG_PREFIX=""
LOG_MODE="e"
LOCK="$CFG_TMPFS_DIR/copy.lock"



# Print an info log message
function infoLog {
  _infoLog "$1" "$LOG_PREFIX" "$LOG" "$LOG_MODE"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_INFO_LOG" > /dev/null 2>&1
}

# Print a warning log message
function warningLog {
  _warningLog "$1" "$LOG_PREFIX" "$LOG" "$LOG_MODE"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_WARNING_LOG" > /dev/null 2>&1
}

# Print an error log message
function errorLog {
  _errorLog "$1" "$LOG_PREFIX" "$LOG" "$LOG_MODE"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_ERROR_LOG" > /dev/null 2>&1
  EXIT_CODE=1
}



# Main execution routine
function main {
  local source="$1"
  local options="$2"
  local dir
  local file

  # Ensure that the source files are readable
  if [[ "$CHMOD" != "" ]]; then
    find "$source" -type d -exec chmod u+rx {} +
    find "$source" -type f -exec chmod u+r {} +
  fi

  # Check if source is a file or a directory
  if [[ -f "$source" ]]; then
    dir=$(dirname "$source")
    file=$(basename "$source")
  else
    dir="$source"
    file=""
  fi

  # Create the output directory
  mkdir -p "$DESTINATION/$dir"
  rv=$?
  if [[ $rv -ne 0 ]]; then
    errorLog "failed to create $DESTINATION/$source (exit code $rv)"
  fi

  echo ""
  echo ""
  echo "$dir/$file:"
  rsync -rltDv --delete-excluded $options $dir/$file $DESTINATION/$dir
  local rv=$?
  if [[ $rv -ne 0 ]]; then
    errorLog "failed to copy $source (exit code $rv)"
  fi

  if [[ "$options" != "" ]]; then
    options="($options)"
  fi
  echo "$source $options" >> "$README"
}




#################
####  START  ####
#################

# Check for correct number of arguments
if [[ $# -ne 5 ]]; then
  errorLog "invalid number of arguments $#"
  exit 1
fi

# Parse the script arguments
# Arg 1:
SOURCE=($1)  # List of files and directories to be copied
# Arg 2:
EXCLUDE=($2) # Excluded files
# Arg 3:
DESTINATION="$3"  # Destination directory
# Arg 4:
if [[ "$4" != "" ]]; then
  LOG="$CFG_LOG_DIR/$4.log"      # Log file
  LOCK="$CFG_TMPFS_DIR/$4.lock"  # Lock file
  LOG_PREFIX="$4"                # Log prefix
  LOG_MODE="ecd"                 # Enable logging
fi
# Arg 5:
CHMOD="$5"   # chmod: change source file permissions


# Readme file name
README="$DESTINATION/README.txt"


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
  exclude=( $(echo "$exclude" | tr "#" " ") )
  options=""
  for x in "${exclude[@]}"; do
    if [[ "$x" != "%" ]]; then
      options="$options --exclude=$x"
    fi
  done

  if [[ "$source" != "" && "$source" != "%" ]]; then
    main "$source" "$options"
  fi
done

echo " "
if [[ $EXIT_CODE -eq 0 ]]; then
  infoLog "success"
else
  echo "ERROR"
fi

semaphoreRelease "$LOCK"
exit $EXIT_CODE
