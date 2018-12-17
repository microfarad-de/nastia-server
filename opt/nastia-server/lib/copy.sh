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
if [[ "$1" != "" ]]; then SOURCE=($1) ; fi # List of files and directories to be copied
if [[ "$2" != "" ]]; then EXCLUDE=($2); fi # Excluded files
if [[ "$3" != "" ]]; then OUTDIR="$3" ; fi # Output directory
if [[ "$4" != "" ]]; then                  # Log prefix, logfile basename
  LOG="$CFG_LOG_DIR/$4.log"
  LOCK="$CFG_TMPFS_DIR/$4.lock"
  PREFIX="$4"
fi
if [[ "$5" != "" ]]; then CHMOD="$5" ; fi  # "chmod" = change source file permissions

# Readme file name
README="$OUTDIR/README.txt"


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


if [[ $EXIT_CODE -eq 0 ]]; then
  infoLog "success"
else
  echo "ERROR"
fi

semaphoreRelease "$LOCK"
exit $EXIT_CODE
