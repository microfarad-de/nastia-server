#!/bin/bash
#
# Update the IP address at the Dynamic DNS service
# Supported services:
# - goip.de
# - anydns.info
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
DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# Include common configuration file
source "$DIR/common.sh"


# goip.de configuration parameters:
GOIP_USERNAME="$CFG_DYNDNS_GOIP_USERNAME"
GOIP_PASSWORD="$CFG_DYNDNS_GOIP_PASSWORD"


# anydns.info configuration parameters:
ANYDNS_USERNAME="$CFG_DYNDNS_ANYDNS_USERNAME"
ANYDNS_PASSWORD="$CFG_DYNDNS_ANYDNS_PASSWORD"

# IPv6 support flag
IPV6_ENABLED="$CFG_DYNDNS_IPV6_ENABLED"

# Common configuration parameters:
LOG="$CFG_LOG_DIR/dyndns.log"     # Main log file
IPV4_URL="$CFG_DYNDNS_IPV4_URL"   # URL that returns the current IPv4 address
IPV6_URL="$CFG_DYNDNS_IPV6_URL"   # URL that returns the current IPv6 address


# Global variables
EXIT_CODE=0  # script exit code
IPV4=""      # ipv4 public address
IPV6=""      # ipv6 public address
#IPV6=$(hostname -I | awk '{print $2}')



# Print info message to log file
function infoLog {
  _infoLog "$1" "dyndns" "$LOG" "ecd"
}


# Print warning message to log file
function warningLog {
  _warningLog "$1" "dyndns" "$LOG" "ecd"
  EXIT_CODE=1
}


# Print error message to log file
function errorLog {
  _errorLog "$1" "dyndns" "$LOG" "ecd"
  EXIT_CODE=1
}



# Update IP address at goip.de
function updateGoip {
  local domain="$1"
  local protocol="$2"
  local option
  local ip
  local lastIp
  local tmp
  local result
  local rv

  if [[ "$protocol" == "ipv6" ]]; then
    option="&ip6=$IPV6"
    ip="$IPV6"
  elif [[ "$protocol" == "ipv4" ]]; then
    option=""
    ip="$IPV4"
  else
    errorLog "$domain: invalid protocol $protocol"
    return
  fi

  tmp="$CFG_TMP_DIR/dyndns-$domain-$protocol.tmp"
  if [[ -f "$tmp" ]]; then
    lastIp=$(cat "$tmp")
  fi
  if [[ "$ip" == "$lastIp" || "$ip" == "" ]]; then
    return
  fi

  result=$(wget --inet4-only -qO- "https://www.goip.de/setip?username=$GOIP_USERNAME&password=$GOIP_PASSWORD&subdomain=$domain&shortResponse=true$option" 2>&1)
  rv=$?

  if [[ $rv -eq 0 ]]; then
    infoLog "$domain/$protocol: $ip"
    echo "$ip" > "$tmp"
  elif [[ $rv -eq 4 ]]; then
    warningLog "$domain/$protocol: server not reachable"
  else
    errorLog "$domain/$protocol: failed to update the IP address ($ip, exit code $rv)"
  fi
}



# Update IP address at anydns.info
function updateAnydns {
  local domain="$1"
  local protocol="$2"
  local option
  local ip
  local lastIp
  local tmp
  local result

  if [[ "$protocol" == "ipv6" ]]; then
    option="--inet6-only"
    ip="$IPV6"
  elif [[ "$protocol" == "ipv4" ]]; then
    option="--inet4-only"
    ip="$IPV4"
  else
    errorLog "$domain: invalid protocol $protocol"
    return
  fi

  tmp="$CFG_TMP_DIR/dyndns-$domain-$protocol.tmp"
  if [[ -f "$tmp" ]]; then
    lastIp=$(cat "$tmp")
  fi
  if [[ "$ip" == "$lastIp" || "$ip" == "" ]]; then
    return
  fi

  result=$(wget "$option" -qO- "http://www.anydns.info/update.php?user=$ANYDNS_USERNAME&password=$ANYDNS_PASSWORD&host=$domain" 2>&1)

  if [[ "$result" == *"OK"* ]]; then
    infoLog "$domain/$protocol: $ip"
    echo "$ip" > "$tmp"
  elif [[ "$result" == *"NO"* ]]; then
    errorLog "$domain/$protocol: failed to update the IP address"
  else
    warningLog "$domain/$protocol: server not reachable"
  fi
}



# Main routine
function main {
  local domain="$1"
  local protocol="$2"

  if [[ "$protocol" == "ipv6" && $IPV6_ENABLED -ne 1 ]]; then
    warningLog "$domain/$protocol: IPv6 is disabled"
    return
  fi
  if [[ "$domain" == *"goip.de" ]]; then
    updateGoip "$domain" "$protocol"
  elif [[ "$domain" == *"anydns.info" ]]; then
    updateAnydns "$domain" "$protocol"
  fi
}





#################
####  START  ####
#################


# Retrieve the public IPv4 addresses
IPV4=$(wget --inet4-only -qO- "$IPV4_URL" 2>&1)
rv=$?
if [[ $rv -ne 0 ]]; then
  warningLog "failed to retrieve current IPv4 address (exit code $rv)"
fi

# Retrieve the public IPv6 address
if [[ $IPV6_ENABLED -eq 1 ]]; then
  IPV6=$(wget --inet6-only -qO- "$IPV6_URL" 2>&1)
  rv=$?
  if [[ $rv -ne 0 ]]; then
   warningLog "failed to retrieve current IPv6 address (exit code $rv)"
  fi
fi

echo "IP address:"
echo "  IPv4: $IPV4"
if [[ $IPV6_ENABLED -eq 1 ]]; then
  echo "  IPv6: $IPV6"
fi

# Loop over configurations
for i in "${!CFG_DYNDNS_DOMAIN[@]}"; do
  domain="${CFG_DYNDNS_DOMAIN[$i]}"
  protocol="${CFG_DYNDNS_PROTOCOL[$i]}"
  main "$domain" "$protocol"
done

exit $EXIT_CODE

