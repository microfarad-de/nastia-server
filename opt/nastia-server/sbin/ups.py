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


# Initialize the serial port
ser = serial.Serial(DEVICE, BAUD_RATE, timeout=1)


# Main loop
while 1:

    rx = " "

    # Flush the FIFO
    while len(rx) > 0:
        rx = ser.readline()
        sys.stdout.write(rx)

    ser.write('stat\n')
    rx = ser.readline()
    sys.stdout.write(rx)

    time.sleep(INTERVAL)

