#!/usr/bin/env python
#
# Uninterruptible Power Supply (UPS) Control
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

import serial    # pip install pyserial
import sys
import time
import os


# Current directory where this script is located
DIR = os.path.dirname(os.path.abspath(__file__))


# Configuration parameters
INTERVAL = 5  # Polling interval in seconds


# Print info log message
def infoLog ( text ):
    print(text.rstrip() )
    os.popen( DIR + "/infoLog.sh \"" + text.rstrip() + "\" 'ups' '' 'cd'" )


# Print warning log message
def warningLog ( text ):
    print("[WARNING] " + text.rstrip() )
    os.popen( DIR + "/warningLog.sh \"" + text.rstrip() + "\" 'ups' '' 'cd'" )


# Print error log message
def errorLog ( text ):
    print("[ERROR] " + text.rstrip() )
    os.popen( DIR + "/errorLog.sh \"" + text.rstrip() + "\" 'ups' '' 'cd'" )



# Read the contents of the receive buffer
def read():
    rx = " "
    result = ""
    while len(rx) > 0:
        rx = ser.readline()
        result = result + rx
    time.sleep(0.1)
    return result

# Write to the transmit buffer
def write(str):
    ser.write(str)
    time.sleep(0.1)







#################
####  START  ####
#################


# Check for correct number of arguments
if len(sys.argv) < 2:
    print "usage: " + sys.argv[0] + " DEVICE BAUD_RATE"
    sys.exit()

DEVICE    = sys.argv[1]    # RS232 device name
BAUD_RATE = sys.argv[2]    # Serial baud rate

infoLog("UPS service started")

# Initialize the serial port
ser = serial.Serial(DEVICE, BAUD_RATE, timeout=0.1)


# A serial connection will cause the MCU to reboot
# The following will flush the initial boot message
# and wait until the MCU is up and running
time.sleep(2)
result = read()
sys.stdout.write(result)
time.sleep(2)


lastResult = ""

# Main loop
while 1:

    write("stat\n")
    result = read()
    #sys.stdout.write(result)

    if result != lastResult:
        lastResult = result
        if "BATTERY" in result:
            warningLog(result)
        elif "ERROR" in result:
            errorLog(result)
        else:
            infoLog(result)

    if "BATTERY 0" in result:
        write("halt\n")
        result = read()
        if "SHUTDOWN" in result:
            errorLog(result)
            os.popen("halt")
        else:
            errorLog("shutdown failed")


    time.sleep(INTERVAL)


