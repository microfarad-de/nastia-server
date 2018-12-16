#!/bin/bash
#
# Parse the configuration file(s)
#

# Current directory where this script is located
_LIB_DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

_CONFIG="$_LIB_DIR/../etc/nastia-server"


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
        declare -g "CFG_$lhs"="$rhs"
      fi
    done < $file
  fi
}

# Main server configuration file
parseConfig "$_CONFIG.conf"

# Local configuration file has priority
parseConfig "$_CONFIG.local"



