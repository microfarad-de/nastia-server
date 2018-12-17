#!/bin/bash
#
# Monitor the server status and send email notification upon errors
# Depends on:
# - speedtest-cli
# - lynx
#

# Current directory where this script is located
DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# Include the common configuration file
# Provides the paths for the temporary log files
source "$DIR/common.sh"


# Configuration parameters:
RECIPIENT="$CFG_EMAIL"                              # Email address where the report is to be sent
SUBJECT="$CFG_EMAIL_SUBJECT_PREFIX"                 # Prefix for the email subject
FORMAT="$CFG_EMAIL_FORMAT"                          # Email message format
DOMAIN_NAME="$CFG_DOMAIN_NAME"                      # IPv4 domain name for the ping test
DOMAIN_NAME_V6="$CFG_DOMAIN_NAME"                   # IPv6 domain name for the ping test
DISK_SPACE_THRESHOLD="$CFG_MONITOR_DISK_THRESHOLD"  # Threshold in percent of free disk space to trigger a disk warning
DISK_SPACE_DISKS=("${CFG_MONITOR_DISK[@]}")         # List of disk mount points to be monitored
SPEED_TEST_RUNS="$CFG_MONITOR_SPEED_RUNS"           # Number of internet speed test runs to be executed
SPEED_TEST_PING_THRESHOLD="$CFG_MONITOR_SPEED_PING_THRESHOLD"  # Maximum acceptable ping duration in ms
SPEED_TEST_DL_THRESHOLD="$CFG_MONITOR_SPEED_DL_THRESHOLD"      # Minimum acceptable downlink internet connection speed in Mbps
SPEED_TEST_UL_THRESHOLD="$CFG_MONITOR_SPEED_UL_THRESHOLD"      # Minimum acceptable uplink internet connection speed in Mbps
SERVICES=("${CFG_MONITOR_SERVICE[@]}")              # List of services to be checked
CRON_PREFIXES=("${CFG_MONITOR_CRON_PREFIX[@]}")     # List of log prefixes for the cron jobs to be monitored
CRON_INTERVALS=("${CFG_MONITOR_CRON_INTERVAL[@]}")  # List of cron job execution intervals

# List of available testcases
TESTCASES=(
  "system-status"
  "disk-space"
  "speed-test"
  "cron-check"
  "script-errors"
  "script-warnings"
  "script-info"
  "ping-v4"
  "ping-v6"
  "service-status"
)



# Global variables:
LOG="$CFG_LOG_DIR/monitor.log"        # Main log file
LOCK="$CFG_TMPFS_DIR/monitor.lock"      # Lock file, avoids running multiple instances of this script
MAIL_BODY=""
WARNING_FLAG=0
ERROR_FLAG=0
SCRIPT_ERRORS=0
SCRIPT_WARNINGS=0
SCRIPT_INFO=0

# Log a info, writes to log file only
function infoLog {
  _infoLog "$1" "" "$LOG" "ed+"
}

# Log a info, writes to email report only
function mailLog {
  _infoLog "$1" "" "$LOG" "e+"
  MAIL_BODY="${MAIL_BODY}$1"$'\n'
}

# Log an OK message, writes to email report only
function okLog {
  _infoLog "$1" "" "$LOG" "e+"
  if [[ "$2" == "inline" ]]; then
    MAIL_BODY="${MAIL_BODY}<font class='ok'>[OK]</font>"$'\n'
  else
    MAIL_BODY="${MAIL_BODY}<p><font class='ok'>[OK]</font> $1</p>"$'\n'
  fi
}

# Log a warning, writes to both email report and log file
function warningLog {
  _warningLog "$1" "" "$LOG" "ed+"
  if [[ "$2" == "inline" ]]; then
    MAIL_BODY="${MAIL_BODY}<font class='warning'>[WARNING]</font>"$'\n'
  else
    MAIL_BODY="${MAIL_BODY}<p><font class='warning'>[WARNING]</font> $1</p>"$'\n'
  fi
  WARNING_FLAG=1
}

# Log an error, writes to both email report and log file
function errorLog {
  _errorLog "$1" "" "$LOG" "ed+"
  if [[ "$2" == "inline" ]]; then
    MAIL_BODY="${MAIL_BODY}<font class='error'>[ERROR]</font>"$'\n'
  else
    MAIL_BODY="${MAIL_BODY}<p><font class='error'>[ERROR]</font> $1</p>"$'\n'
  fi
  ERROR_FLAG=1
}


# Construct an email message
function constructMail {
  status="$1"
  echo "to: $RECIPIENT"
  echo "cc:"
  echo "bcc:"
  echo "Subject: $SUBJECT $status ($(date '+%Y%m%d%H%M'))"
  echo "MIME-Version: 1.0"
  if [[ "$FORMAT" == "html" ]]; then
    echo "Content-Type: multipart/alternative; boundary=Next_Part_qwwertzuiopasdfghjklyxcvbnm"
    echo "--Next_Part_qwwertzuiopasdfghjklyxcvbnm"
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    echo "$MAIL_BODY" | lynx -stdin -dump -width=300
    echo ""
    echo "--Next_Part_qwwertzuiopasdfghjklyxcvbnm"
    echo "Content-Type: text/html; charset=utf-8"
    echo ""
    echo "$MAIL_BODY"
    echo "--Next_Part_qwwertzuiopasdfghjklyxcvbnm--"
    echo ""
  elif [[ "$FORMAT" == "preformat" ]]; then
    echo "Content-Type: text/html; charset=utf-8"
    echo ""
    echo "<pre>"
    echo "$MAIL_BODY" | lynx -stdin -dump -width=300
    echo "</pre>"
    echo ""
  else
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    echo "$MAIL_BODY" | lynx -stdin -dump -width=300
    echo ""
  fi
}


# Send an email message
function sendMail {
  local status="$1"
  constructMail "$status" | /usr/sbin/ssmtp -t
  local rv=${PIPESTATUS[1]}
  if [[ $rv -ne 0 ]]; then
    errorLog "mail returned $rv while sending to $RECIPIENT"
    return 1
  else
    infoLog "email sent to: $RECIPIENT"
    return 0
  fi
}



# Executes a testcase, prevents executing arbitrary commands
function execute {
  testcase="$1"
  if [[ "$testcase" == "" ]]; then
    return 0
  fi
  local t
  for t in "${TESTCASES[@]}"; do
    if [[ "$testcase" == "$t" ]]; then
      $testcase
      return $?
    fi
  done
  errorLog "invalid test $testcase"
  echo "available tests:"
  for command in "${TESTCASES[@]}"; do
    echo "  $command"
  done
  return 1
}



#####################
####  TESTCASES  ####
#####################


# System statistics
function system-status {
  mailLog "<h2>System Status</h2>"
  mailLog "<table>"
  mailLog "<tr><th class='padded'>Uptime:</th><td class='padded'>$(/usr/bin/uptime -p)</td></tr>"
  mailLog "<tr><th class='padded'>System time:</th><td class='padded'>$(date)</td></tr>"
  mailLog "<tr><th class='padded'>Load average:</th><td class='padded'>$(cat /proc/loadavg)</td></tr>"
  mailLog "</table>"
  mailLog "<p>&nbsp;</p>"
}


# Check remaining disk space
function disk-space {
  local disk freeSpace totalSpace rv freePercent
  mailLog "<h2>Available Disk Space</h2>"
  mailLog "<table>"
  mailLog "<tr><th>Disk</th><th>Size</th><th>Avail</th><th>Avail%</th><th>Status</th></tr>"
  for disk in "${DISK_SPACE_DISKS[@]}"; do
    mailLog "<tr>"
    mailLog "<td>$disk</td>"
    if mount | grep "$disk" > /dev/null; then
      freeSpace=$(df --block-size=1G  "$disk" | tail -1 | awk '{print $4}')
      totalSpace=$(df --block-size=1G  "$disk" | tail -1 | awk '{print $2}')
      rv=$?
      freePercent=$(( freeSpace * 100 / totalSpace ))
      mailLog "<td>${totalSpace}G</td><td>${freeSpace}G</td><td>${freePercent}%</td>"
      if [[ $rv -ne 0 ]]; then
        mailLog "<td>"
        errorLog "df failed with error code $rv while checking $disk" "inline"
        mailLog "</td>"
      else
        #mailLog "$disk: $freeSpace GB ($freePercent%) free"
        if [[ $freePercent -lt $DISK_SPACE_THRESHOLD ]]; then
          mailLog "<td>"
          warningLog "$disk is running out of space" "inline"
          mailLog "</td>"
        else
          mailLog "<td>"
          okLog "OK" "inline"
          mailLog "</td>"
        fi
      fi
    else
      mailLog "<td> - </td><td> - </td><td> - </td>"
      mailLog "<td>"
      errorLog "$disk is not mounted" "inline"
      mailLog "</td>"
      let error=error+1
    fi
    mailLog "</tr>"
  done
  mailLog "</table>"
  mailLog "<p>&nbsp;</p>"
}


# Check internet speed
function speed-test {
  local result rv 
  local count=0
  local png dl ul
  local pngMin=9999
  local dlMax=0
  local ulMax=0
  mailLog "<h2>Internet Connection Speed Test</h2>"
  mailLog "<table>"
  mailLog "<tr><th></th><th>Ping</th><th>Download</th><th>Upload</th></tr>"
  while [[ count -lt $SPEED_TEST_RUNS ]]; do
    let count=count+1
    result=$(/usr/local/bin/speedtest-cli --simple 2>&1)
    rv=$?
    png=$(echo "$result" | grep "Ping" | cut -f2 -d" " | cut -f1 -d".")
    dl=$(echo "$result" | grep "Download" | cut -f2 -d" " | cut -f1 -d".")
    ul=$(echo "$result" | grep "Upload"   | cut -f2 -d" " | cut -f1 -d".")
    mailLog "<tr><th>Run $count:</th>"
    if [[ $rv -eq 0 ]]; then
      mailLog "<td>$png ms</td><td>$dl Mbit/s</td><td>$ul Mbit/s</td>"
    else
      mailLog "<td>"
      errorLog "speedtest-cli failed (exit code $rv)" "inline"
      mailLog "</td><td> - </td><td> - </td>"
    fi
    mailLog "</tr>"
    if [[ "$png" == "" ]];     then png=9999;    fi
    if [[ $png -lt $pngMin ]]; then pngMin=$png; fi
    if [[ $dl -gt $dlMax ]];   then dlMax=$dl;   fi
    if [[ $ul -gt $ulMax ]];   then ulMax=$ul;   fi
  done
  mailLog "<tr><th>Best:</th><td>$pngMin ms</td><td>$dlMax Mbit/s</td><td>$ulMax Mbit/s</td></tr>"
  mailLog "<tr><th>Status:</th><td>"
  if [[ $pngMin -gt $SPEED_TEST_PING_THRESHOLD ]]; then
    warningLog "slow ping ($pngMin ms)" "inline"
  else
    okLog "OK" "inline"
  fi
  mailLog "</td><td>"
  if [[ $dlMax -lt $SPEED_TEST_DL_THRESHOLD ]]; then
    warningLog "slow download speed ($dlMax Mbit/s)" "inline"
  else
    okLog "OK" "inline"
  fi
  mailLog "</td><td>"
  if [[ $ulMax -lt $SPEED_TEST_UL_THRESHOLD ]]; then
    warningLog "slow upload speed ($ulMax Mbit/s)" "inline"
  else
    okLog "OK" "inline"
  fi
  mailLog "</td></tr></table>"
  mailLog "<p>&nbsp;</p>"
}


# Check errors from other scripts
function script-errors {
  local result
  mailLog "<h2>Error Messages</h2>"
  if [[ -e "$CFG_ERROR_LOG" ]]; then
    result=`cat "$CFG_ERROR_LOG"`
    errorLog "the following errors occurred:"
    infoLog $'\n'"$result"
    mailLog "<pre>"
    mailLog "$result"
    mailLog "</pre>"
    SCRIPT_ERRORS=1
  else
    okLog "no error messages"
  fi
  mailLog "<p>&nbsp;</p>"
}


# Check warnings from other scripts
function script-warnings {
  local result
  mailLog "<h2>Warning Messages</h2>"
  if [[ -e "$CFG_WARNING_LOG" ]]; then
    result=`cat "$CFG_WARNING_LOG"`
    warningLog "the following warnings occurred:"
    infoLog $'\n'"$result"
    mailLog "<pre>"
    mailLog "$result"
    mailLog "</pre>"
    SCRIPT_WARNINGS=1
  else
    okLog "no warning messages"
  fi
  mailLog "<p>&nbsp;</p>"
}


# Check info messages from other scripts
function script-info {
  local result
  mailLog "<h2>Info Messages</h2>"
  if [[ -e "$CFG_INFO_LOG" ]]; then
    result=`cat "$CFG_INFO_LOG"`
    mailLog "<pre>"
    mailLog "$result"
    mailLog "</pre>"
    SCRIPT_INFO=1
  else
    mailLog "<p><font class='unsure'>[?]</font> no info messages</p>"
  fi
  mailLog "<p>&nbsp;</p>"
}


# Check IPv4 network connectivity
function ping-v4 {
  local result rv
  mailLog "<h2>IPv4 Ping Test</h2>"
  result=$(ping -c 4 "$DOMAIN_NAME" -4 2>&1)
  rv=$?
  if [[ $rv -ne 0 ]]; then
    errorLog "ping $DOMAIN_NAME failed (exit code $rv)"
  else
    okLog "ping is good"
  fi
  mailLog "<pre>"
  mailLog "$result"
  mailLog "</pre>"
  mailLog "<p>&nbsp;</p>"
}


# Check IPv6 network connectivity
function ping-v6 {
  local result rv
  if [[ "$DOMAIN_NAME_V6" == "" ]]; then
    return
  fi
  mailLog "<h2>IPv6 Ping Test</h2>"
  result=$(ping -c 4 "$DOMAIN_NAME_V6" -6 2>&1)
  rv=$?
  if [[ $rv -ne 0 ]]; then
    errorLog "ping6 $DOMAIN_NAME_V6 failed (exit code $rv)"
  else
    okLog "ping is good"
  fi
  mailLog "<pre>"
  mailLog "$result"
  mailLog "</pre>"
  mailLog "<p>&nbsp;</p>"
}


# Check the various service status
function service-status {
  local service status rv
  for service in "${SERVICES[@]}"; do
    status=$(/usr/sbin/service "$service" status 2>&1)
    rv=$?
    mailLog "<h2>'$service' Service Status</h2>"
    if [[ $rv -ne 0 ]]; then
      errorLog "service '$service' failed:"
    else
      okLog "service '$service' is running"
    fi
    mailLog "<pre>"
    mailLog "$status"
    mailLog "</pre>"
    mailLog "<p>&nbsp;</p>"
  done
}


# Check if the cron jobs are running
function cron-check {
  local i prefix interval tmp log lastT t delta
  mailLog "<h2>Cron Job Status</h2>"
  mailLog "<table>"
  mailLog "<tr><th>Job</th><th>Interval</th><th>Since</th><th>Status</th></tr>"
  t=$(date +%s)
  for i in "${!CRON_PREFIXES[@]}"; do
    prefix="${CRON_PREFIXES[$i]}"
    interval="${CRON_INTERVALS[$i]}"
    tmp="$CFG_TMP_DIR/monitor-cron-check-$prefix.tmp"
    for log in "$CFG_INFO_LOG" "$CFG_WARNING_LOG" "$CFG_ERROR_LOG"; do
      grep "\[$prefix\]" "$log" > /dev/null 2>&1
      if [[ $? -eq 0 ]]; then
        echo "$t" > "$tmp"
      fi
    done
    if [[ -f "$tmp" ]]; then
      lastT=$(cat "$tmp")
    else
      lastT=0
    fi
    delta=$((t-lastT))
    mailLog "<tr>"
    mailLog "<td>$prefix</td><td>$interval d.<td>$((delta/86400)) d.</td>"
    mailLog "<td>"
    if [[ $delta -gt $((86400*interval)) ]]; then
      warningLog "cron job '$prefix' took $((delta/86400)) (>$interval) days to execute" "inline"
    else
      okLog "OK" "inline"
    fi
    mailLog "</td></tr>"
  done
  mailLog "</table>"
  mailLog "<p>&nbsp;</p>"
}




################
#### START  ####
################


# Check if the script is already running
semaphoreLock "$LOCK"
if [[ $? -ne 0 ]]; then
  warningLog "an instance of the current script is already running (please remove $LOCK)"
  exit 1
fi

# Pause all logging activities by locking the semaphore
logSemaphoreLock
if [[ $? -ne 0 ]]; then
  warningLog "log semaphore locking timeout"
fi

# HTML header
mailLog "<!DOCTYPE html>"
mailLog "<?xml encoding=3D\"UTF-8\"??>"
mailLog "<html><head><style>"
mailLog "* {font-family: Arial, sans-serif;}"
mailLog "pre {font-size: 10px; font-family: Monaco, monospace;}"
mailLog "table {width: 350px;}"
#mailLog "table.spread {border-spacing: 10px;}"
mailLog "th {text-align: left; white-space: nowrap;}"
mailLog "td {text-align: left;}"
mailLog ".padded {padding-bottom: 10px;}"
mailLog "font.ok {font-weight: bold; color: green;}"
mailLog "font.warning {font-weight: bold; color: orange;}"
mailLog "font.error {font-weight: bold; color: red;}"
mailLog "font.unsure {font-weight: bold; color: gray;}"
mailLog "</style></head><body>"


arg=$1
exitCode=0

# If no argument was given - execute all system tests
if [[ "$arg" == "" ]]; then
  for command in "${CFG_MONITOR_TEST[@]}"; do
    execute $command
  done
# Otherwise execute only the test defined by the argument
else
  execute $arg
  if [[ $? -ne 0 ]]; then
    exitCode=1
  fi
fi

# HTML closing tags
mailLog "</body></html>"


# Send email report
if [[ $exitCode -eq 0 ]]; then
  if [[ $ERROR_FLAG -ne 0 ]]; then
    sendMail "System ERROR"
    exitCode=$?
  elif [[ $WARNING_FLAG -ne 0 ]]; then
    sendMail "System WARNING"
    exitCode=$?
  else
    sendMail "System OK"
    exitCode=$?
  fi
fi


# Delete temporary log files
if [[ $exitCode -eq 0 ]]; then
  if [[ SCRIPT_ERRORS -eq 1 ]];   then rm -rf "$CFG_ERROR_LOG"  ; fi
  if [[ SCRIPT_WARNINGS -eq 1 ]]; then rm -rf "$CFG_WARNING_LOG"; fi
  if [[ SCRIPT_INFO -eq 1 ]];     then rm -rf "$CFG_INFO_LOG"   ; fi
fi

# Resume the logging activities
logSemaphoreRelease
if [[ $? -ne 0 ]]; then
  warningLog "log semaphore was not locked"
fi

# Release lock
semaphoreRelease "$LOCK"
exit $exitCode
