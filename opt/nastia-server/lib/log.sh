#!/bin/bash
#
# Common logging funcitions
#


# Time and date stamp - usage: $(eval $LOG_STAMP)
LOG_STAMP_STR="+%Y-%m-%d %T"
LOG_STAMP="date '$LOG_STAMP_STR'"

# Semaphore: temporary directory and tiemout in seconds
_LOG_SEMAPHORE="$CFG_TMPFS_DIR/log-semaphore.lock"


# Lock the semaphore to protect against race conditions
function logSemaphoreLock {
  semaphoreLock "$_LOG_SEMAPHORE" "b"
  return $?
}

# Release the semaphore
function logSemaphoreRelease {
  semaphoreRelease "$_LOG_SEMAPHORE"
  return $?
}



# Print a log message
function _printLog {
  local text="$1"
  local prefix="$2"
  local log="$3"
  local mode="$4"
  local clog="$5"
  local dprefix=""

  if [[ "$mode" != *"+"* ]]; then
    logSemaphoreLock
  fi

  if [[ "$prefix" != "" ]]; then
    prefix=" [$prefix]"
  fi

  if [[ "$mode" == *"p"* ]]; then
    dprefix="$prefix"
  fi

  # Print an echo log message
  if [[ "$mode" == *"e"* ]]; then
    echo -e "$text"
  fi

  # Print a dedicated log message
  if [[ "$mode" == *"d"* ]]; then
    echo -e "$(eval $LOG_STAMP):$dprefix $text" >> "$log"
  fi

  # Print a common log message (used by monitor.sh)
  if [[ "$mode" == *"c"* ]]; then
    echo -e "$(eval $LOG_STAMP):$prefix $text" >> "$clog"
  fi

  if [[ "$mode" != *"+"* ]]; then
    logSemaphoreRelease
  fi
}


# Print an info message
function _infoLog {
  _printLog "$1" "$2" "$3" "$4" "$CFG_INFO_LOG"
}


# Print a warning message
function _warningLog {
  _printLog "[WARNING] $1" "$2" "$3" "$4" "$CFG_WARNING_LOG"
}


# Print an error message
function _errorLog {
  _printLog "[ERROR] $1" "$2" "$3" "$4" "$CFG_ERROR_LOG"
}

