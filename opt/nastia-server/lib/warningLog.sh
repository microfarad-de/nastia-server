#!/bin/bash
#
# Wrapper for sending info log messages via command line
#

# Current directory where this script is located
_LIB_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# Common code
source "$_LIB_DIR/common.sh"


_warningLog "$1" "$2" "$3" "$4"
