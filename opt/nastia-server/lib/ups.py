#!/usr/bin/env python
#
# Uninterruptible Power Supply (UPS) Control
#
# Note:
#   Must run as root to be able to perform a system shutdown
#
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
#

import serial  # pip install pyserial
import ilock  # pip install ilock
import sys
import os
import time
import datetime

# Current directory where this script is located
DIR = os.path.dirname(os.path.abspath(__file__))

# Polling interval in seconds
INTERVAL = 5

# If the battery gets trickle charged more often than
# the follwoing threshold (in hours), then a bad battery
# warning will be written into the trace log.
BAD_BATTERY_THRESHOLD = 48


# Print info log message
def infoLog(text):
    print(text.rstrip())
    os.popen(DIR + "/infoLog.sh \"" + text.rstrip() + "\" 'ups' '' 'cd'")


# Print warning log message
def warningLog(text):
    print("[WARNING] " + text.rstrip())
    os.popen(DIR + "/warningLog.sh \"" + text.rstrip() + "\" 'ups' '' 'cd'")


# Print error log message
def errorLog(text):
    print("[ERROR] " + text.rstrip())
    os.popen(DIR + "/errorLog.sh \"" + text.rstrip() + "\" 'ups' '' 'cd'")


# Print a log message to the measurements log file
def measLog(text):
    os.popen(DIR + "/infoLog.sh \"" + text.rstrip() + "\" 'ups-meas' '' 'd'")


# Read the contents of the receive buffer
def read():
    global DEVICE
    global ser
    rx = " "
    result = ""
    while len(rx) > 0:
        try:
            rx = ser.readline().decode()
            result = result + rx
        except:
            print("Failed to read from", DEVICE)
            sys.exit(1)
    time.sleep(0.1)
    return result


# Write to the transmit buffer
def write(str):
    global DEVICE
    global ser
    try:
        ser.write(str.encode())
    except:
        print("Failed to write to", DEVICE)
        sys.exit(1)
    time.sleep(0.1)


# Extends ILock with exception handling
class ILockE(ilock.ILock):
    def __enter__(self):
        while 1:
            try:
                super(ILockE, self).__enter__()
                break
            except PermissionError:
                pass
    def __exit__(self, exc_type, exc_val, exc_tb):
        while 1:
            try:
                super(ILockE, self).__exit__(exc_type, exc_val, exc_tb)
                break
            except PermissionError:
                pass


#################
####  START  ####
#################

# Check for correct number of arguments
if len(sys.argv) < 2:
    print("usage: " + sys.argv[0] + " DEVICE BAUD_RATE")
    sys.exit()

DEVICE = sys.argv[1]  # RS232 device name
BAUD_RATE = sys.argv[2]  # Serial baud rate

# System-wide lock ensures mutually exclusive access to the serial port
lock = ILockE(DEVICE, timeout=600)

infoLog("UPS service started")

# Initialize the serial port
with lock:  # Ensure exclusive access through system-wide lock
    ser = serial.Serial(DEVICE, BAUD_RATE, timeout=0.1)

# A serial connection will cause the MCU to reboot
# The following will flush the initial boot message
# and wait until the MCU is up and running
time.sleep(2)
with lock:
    result = read()
sys.stdout.write(result)
time.sleep(2)

lastResult = ""
lastMeasResult = ""
measCount = 0
chargingFlag = False
wasOnBatteryFlag = True
lastChargeTime = datetime.datetime(1970, 1, 1)

# Main loop
while 1:

    # Read the UPS status
    with lock:
        write("stat\n")
        result = read()

    # Trace the UPS status
    if result != lastResult:
        lastResult = result
        if "BATTERY" in result:
            wasOnBatteryFlag = True
            warningLog(result)
        elif "ERROR" in result:
            errorLog(result)
        else:
            # Bad battery detection
            if "CHARGING" in result and not chargingFlag:
                chargeTime = datetime.datetime.now()
                delta = chargeTime - lastChargeTime
                deltaHours = round(delta.days * 24 + delta.seconds / 3600)
                lastChargeTime = chargeTime
                infoLog(result.rstrip() + " (delta = " + str(deltaHours) +
                        "h)")
                if deltaHours < BAD_BATTERY_THRESHOLD and not wasOnBatteryFlag:
                    warningLog("bad battery (delta = " + str(deltaHours) +
                               "h)")
                chargingFlag = True
                wasOnBatteryFlag = False
            elif "CHARGING" in result:
                infoLog(result)
            else:
                chargingFlag = False
                infoLog(result)

    # Handle low battery condition
    if "BATTERY 0" in result:
        with lock:
            write("halt\n")
            result = read()
        if "SHUTDOWN" in result:
            errorLog(result)
            os.popen("sudo halt")
        else:
            errorLog("shutdown failed")

    # Read the UPS measurements
    with lock:
        write("meas\n")
        result = read()

    # Trace the UPS measurements
    if result != lastMeasResult:
        lastMeasResult = result
        if measCount == 0:
            measLog("V_in   V_ups  V_batt I_batt PWM")
        measLog(result)
        measCount += 1
        if measCount >= 20:
            measCount = 0

    time.sleep(INTERVAL)
