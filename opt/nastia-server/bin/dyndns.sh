#!/bin/bash
#
# Update the IP address at the Dynamic DNS service
# Supported services:
# - goip.de
# - anydns.info
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


# Common configuration parameters:
LOG="$CFG_LOG_DIR/dyndns.log"              # Main log file
IPV4_URL="https://www.goip.de/myip"        # URL that returns the current IPv4 address
IPV6_URL="http://www.anydns.info/ip.php"  # URL that returns the current IPv6 address


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
IPV6=$(wget --inet6-only -qO- "$IPV6_URL" 2>&1)
rv=$?
if [[ $rv -ne 0 ]]; then
  warningLog "failed to retrieve current IPv6 address (exit code $rv)"
fi

echo "IP address:"
echo "  IPv4: $IPV4"
echo "  IPv6: $IPV6"

# Loop over configurations
for i in "${!CFG_DYNDNS_DOMAIN[@]}"; do
  domain="${CFG_DYNDNS_DOMAIN[$i]}"
  protocol="${CFG_DYNDNS_PROTOCOL[$i]}"
  main "$domain" "$protocol"
done

exit $EXIT_CODE

