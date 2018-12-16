#!/bin/bash
#
# A multi-purpose semaphore implementation
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


