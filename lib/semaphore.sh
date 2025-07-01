#!/bin/bash
#
# A multi-purpose semaphore implementation
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


# Semaphore timeout in seconds
_SEMAPHORE_TIMEOUT=600


# Lock the semaphore to protect against race conditions
function semaphoreLock {
  local lock="$1"
  local mode="$2"
  local t1=$(date +%s)
  local t2
  while true; do
    mkdir "$lock" > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
      return 0
    fi
    # Default mode: non-blocking
    if [[ "$mode" != "b" ]]; then
      return 1
    fi
    t2=$(date +%s)
    if [[ $((t2-t1)) -gt $_SEMAPHORE_TIMEOUT ]]; then
      return 1
    fi
    sleep 1
  done
}

# Release the semaphore
function semaphoreRelease {
  local lock="$1"
  if [[ -e "$lock" ]]; then
    rm -rf "$lock"
    return 0
  else
    return 1
  fi
}


