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



# Configuration parameters
DEVICE    = '/dev/ttyUSB0'    # RS232 device name
BAUD_RATE = 19200             # Serial baud rate
INTERVAL  =     5             # Polling interval in seconds


# Read the contents of the receive buffer
def read():
    rx = " "
    while len(rx) > 0:
        rx = ser.readline()
        sys.stdout.write(rx)
    #time.sleep(0.5)

# Write to the transmit buffer
def write(str):
    ser.write(str)
    #time.sleep(0.5)



# Initialize the serial port
ser = serial.Serial(DEVICE, BAUD_RATE, timeout=0.5)


# A serial connection will cause the MCU to reboot
# The following will flush the initial boot message
# and wait until the MCU is up and running
time.sleep(1)
read()
time.sleep(5)


count = 0

# Main loop
while 1:

    write('stat\n')
    read()
    count += 1

    if count == 3:
        write('status\n')
        read()
        count = 0

    time.sleep(INTERVAL)


