#!/bin/bash
#
# Initalize GPIO during boot time
# This is needed to work-around the issue where GPIO cannot be initalizing during boot time
# by a non-root user (despite proper group assingment)
#


# Current directory where this script is located
DIR=$(dirname $(readlink -f "$BASH_SOURCE"))

# Include common configuration file
source "$DIR/common.sh"



# Configuration parameters
LOG="$CFG_LOG_DIR/init.log"   # Main log file
GPIO_PIN="$CFG_FAN_GPIO_PIN"  # GPIO pin connected to the fan


# Print info message to log file
function infoLog {
  _infoLog "$1" "init-gpio" "$LOG" "ecdp"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_INFO_LOG"
}

# Print warning message to log file
function warningLog {
  _warningLog "$1" "init-gpio" "$LOG" "ecdp"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_WARNING_LOG"
}

# Print error message to log file
function errorLog {
  _errorLog "$1" "init-gpio" "$LOG" "ecdp"
  chown "$CFG_USER":"$CFG_GROUP" "$CFG_ERROR_LOG"
  exit 1
}



#################
####  START  ####
#################

infoLog "inializing GPIO..."


# Initialize GPIO
if [[ ! -e "/sys/class/gpio/gpio$GPIO_PIN" ]]; then
  echo "$GPIO_PIN" > "/sys/class/gpio/export"
  rv=$?
  if [[ $rv -ne 0 ]]; then
    errorLog "failed to initialize GPIO pin $GPIO_PIN (exit code $rv)"
  else
    infoLog "initialized GPIO pin $GPIO_PIN"
  fi
else
  infoLog "GPIO pin $GPIO_PIN already initialized"
fi

DIRECTION=$(cat "/sys/class/gpio/gpio$GPIO_PIN/direction")

# Set the GPIO direction
if [[ $DIRECTION != "out" ]]; then
  echo "out" > "/sys/class/gpio/gpio$GPIO_PIN/direction"
  rv=$?
  if [[ $rv -ne 0 ]]; then
    errorLog "failed to set GPIO pin $GPIO_PIN direction (exit code $rv)"
  else
    infoLog "GPIO pin $GPIO_PIN direction set to 'out'"
  fi
else
  infoLog "GPIO pin $GPIO_PIN direction already set to 'out'"
fi


exit 0

