#!/bin/bash
#
# Common shell script to be included by all scripts
#


# Current directory where this script is located
_LIB_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# Configuration file parsing
source "$_LIB_DIR/config.sh"

# Semaphore
source "$_LIB_DIR/semaphore.sh"

# Logging functions
source "$_LIB_DIR/log.sh"


