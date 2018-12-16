#!/bin/bash
#
# Automatic fan control via GPIO
#
# Dependencies:
# - init-gpio.sh must run first
#

# Current directory where this script is located
DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# Include common configuration file
source "$DIR/common.sh"


THRESHOLD="$CFG_FAN_TEMPERATURE"   # temparature threshold in degrees Celsius
INTERVAL="$CFG_FAN_INTERVAL"       # temperature sampling interval in seconds

LOG="$CFG_LOG_DIR/fan.log"    # Main log file
GPIO_PIN="$CFG_FAN_GPIO_PIN"  # GPIO pin connected to the fan


# Print info message to log file
function infoLog {
  _infoLog "$1" "fan" "$LOG" "ed+"
}

# Print warning message to log file
function warningLog {
  _warningLog "$1" "fan" "$LOG" "ecd"
}

# Print error message to log file
function errorLog {
  _errorLog "$1" "fan" "$LOG" "ecd"
  exit 1
}



#################
####  START  ####
#################

infoLog "fan control service started"

# Wait to ensure that the GPIO is initialized
sleep 2

# Initialize GPIO
#if [[ ! -e "/sys/class/gpio/gpio$GPIO_PIN" ]]; then
#  echo "$GPIO_PIN" > "/sys/class/gpio/export"
#  rv=$?
#  if [[ $rv -ne 0 ]]; then
#    errorLog "failed to initialize GPIO pin $GPIO_PIN (exit code $rv)"
#  else
#    infoLog "initialized GPIO pin $GPIO_PIN"
#  fi
#fi

#DIRECTION=$(cat "/sys/class/gpio/gpio$GPIO_PIN/direction")

# Set the GPIO direction
#if [[ $DIRECTION != "out" ]]; then
#  echo "out" > "/sys/class/gpio/gpio$GPIO_PIN/direction"
#  rv=$?
#  if [[ $rv -ne 0 ]]; then
#    errorLog "failed to set GPIO pin $GPIO_PIN direction (exit code $rv)"
#  else
#    infoLog "GPIO pin $GPIO_PIN direction set to 'out'"
#  fi
#fi


# Periodically poll the CPU temperature
while true; do

  TEMP=$(vcgencmd measure_temp | cut -c6,7)
  rv=$?
  if [[ $rv -ne 0 ]]; then
    errorLog "failed to read temperature value (exit code $rv)"
  fi

  STATUS=$(cat "/sys/class/gpio/gpio$GPIO_PIN/value")
  rv=$?
  if [[ $rv -ne 0 ]]; then
    errorLog "failed to read the status of GPIO pin $GPIO_PIN (exit code $rv)"
  fi

  if [[ $TEMP -ge $THRESHOLD && $STATUS -eq 0 ]]; then
    echo "1" > "/sys/class/gpio/gpio$GPIO_PIN/value"
    rv=$?
    if [[ $rv -ne 0 ]]; then
      errorLog "failed to turn on GPIO pin $GPIO_PIN (exit code $rv)"
    else
      infoLog "start ($TEMP'C)"
    fi
  elif [[ $TEMP -lt $THRESHOLD  &&  $STATUS -eq 1 ]]; then
    echo "0" > "/sys/class/gpio/gpio$GPIO_PIN/value"
    rv=$?
    if [[ $rv -ne 0 ]]; then
      errorLog "failed to turn off GPIO pin $GPIO_PIN (exit code $rv)"
    else
      infoLog "stop  ($TEMP'C)"
    fi
  fi

  sleep $INTERVAL

done


