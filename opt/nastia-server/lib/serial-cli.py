#!/usr/bin/env python
#
# RS232 Serial Port Console
#
# This source file is part of the follwoing repository:
# http://www.github.com/microfarad-de/nastia-server
#
# Please visit:
#   http://www.microfarad.de
#   http://www.github.com/microfarad-de
#
# Copyright (C) 2023 Karim Hraibi (khraibi@gmail.com)
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

import serial  # pip install pyserial
import ilock   # pip install ilock
from threading import Thread, Semaphore
import sys
import time
import signal


# Read the contents of the receive buffer
def read():
    rx = " "
    result = ""
    while len(rx) > 0:
        rx = ser.readline().decode()
        result = result + rx
    return result

# Write to the transmit buffer
def write(str):
    ser.write(str.encode())

# Handle Ctrl+C
def signal_handler(sig, frame):
    global terminate 
    terminate = True
    print ("\nInterrupted by user\n")
    time.sleep(0.3)
    thread.join();
    raise SystemExit(0)

# Run receiving loop as a thread
def rx_thread():
    global terminate
    while 1:
        sema.acquire()
        with lock:
            rx = read()
        sema.release()
        time.sleep(0.1)
        if rx:
            sys.stdout.write(rx)
        if terminate:
            break


#################
####  START  ####
#################
if __name__=='__main__':

    print("\nInteractive Serial Console\n")

    # Handle Ctrl+C
    signal.signal(signal.SIGINT, signal_handler)

    # Check for correct number of arguments
    if len(sys.argv) < 2:
        print("Usage: " + sys.argv[0] + " DEVICE [BAUD_RATE]\n")
        sys.exit()

    DEVICE    = sys.argv[1] # RS232 device name
    if len(sys.argv) < 3:
        BAUD_RATE = 9600
    else:
        BAUD_RATE = sys.argv[2] # Serial baud rate

    # System-wide lock ensures mutually exclusive access to the serial port
    lock = ilock.ILock(DEVICE, timeout=600)

    # Initialize the serial port
    with lock:
        ser = serial.Serial(DEVICE, BAUD_RATE, timeout=0.1)
        print("Connected to " + str(DEVICE) + " at " + str(BAUD_RATE) + " baud")
        print("Waiting for user input (press Ctrl+C to exit)...\n")

    # Run receive routine as a thread
    terminate = False
    sema = Semaphore()
    thread = Thread(target = rx_thread)
    thread.start()

    while 1:
        tx = sys.stdin.readline()
        sema.acquire()
        with lock:
            write(tx)
        sema.release()
        time.sleep(0.1)
        if terminate:
            break


