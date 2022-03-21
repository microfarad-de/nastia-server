#!/bin/bash
#
# Parse the configuration file(s)
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

# Current directory where this script is located
_LIB_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# Configuration parameters
_CONFIG="$_LIB_DIR/../etc/nastia-server"
_TEMP_FILE="/tmp/nastia-server-config.tmp"
_LOCK="/tmp/config.lock"


# Configuration parser function
# - Single line and inline comments;
# - Trimming spaces around = (ie var = value will not fail);
# - Quoted string values;
# - Prepends the CFG_ prefix to all configuration variables
# source: https://stackoverflow.com/questions/16571739/parsing-variables-from-config-file-in-bash
function parseConfig {
  local file="$1"
  local lhs rhs
  if [[ -f "$file" ]]; then
    while IFS='= ' read -r lhs rhs
    do
      if [[ ! $lhs =~ ^\ *# && -n $lhs ]]; then
        rhs="${rhs%%\#*}"    # Del in line right comments
        rhs="${rhs%"${rhs##*[^ ]}"}" # Del trailing spaces
        rhs="${rhs%\"*}"     # Del opening string quotes 
        rhs="${rhs#\"*}"     # Del closing string quotes 
	echo "CFG_$lhs"="\"$rhs\"" >> "$_TEMP_FILE"
      fi
    done < $file
  fi
}


semaphoreLock "$_LOCK" "b"

echo "" > "$_TEMP_FILE"

# Main server configuration file
parseConfig "$_CONFIG.conf"

# Local configuration file has priority
parseConfig "$_CONFIG.local"

source "$_TEMP_FILE"

rm "$_TEMP_FILE"

semaphoreRelease "$_LOCK"
