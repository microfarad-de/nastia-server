#!/bin/bash
#
# Common logging funcitions
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

  if [[ "$log" == "" && "$prefix" != "" ]]; then
    log="$CFG_LOG_DIR/$prefix.log"
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

