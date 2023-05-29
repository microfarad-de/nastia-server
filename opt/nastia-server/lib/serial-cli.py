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
import ilock  # pip install ilock
import sys
import signal
from threading import Thread, Semaphore
from time import sleep, gmtime, strftime

# Read the contents of the receive buffer
def read():
    global DEVICE
    global ser
    global terminate
    rx = " "
    result = ""
    while len(rx) > 0:
        try:
            rx = ser.readline().decode()
            result = result + rx
        except:
            print("Failed to read from", DEVICE)
            terminate = True
            break
    return result


# Write to the transmit buffer
def write(str):
    global DEVICE
    global ser
    global terminate
    try:
        ser.write(str.encode())
    except:
        print("Failed to write to", DEVICE)
        terminate = True

# Handle Ctrl+C
def signal_handler(sig, frame):
    global terminate
    global thread
    print("\nInterrupted by user\n")
    terminate = True
    thread.join()
    sys.exit(0)


# Run receiving loop as a thread
def rx_thread():
    global sema
    global terminate
    global timestamp
    while 1:
        sleep(0.1)
        sema.acquire()
        with lock:
            rx = read()
        sema.release()
        if rx:
            if timestamp:
                ts = strftime("%Y-%m-%d %H:%M:%S %Z\r\n", gmtime())
            else:
                ts = ""
            sys.stdout.write(ts + rx)
        if terminate:
            break


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
            except FileNotFoundError:
                break

#################
####  START  ####
#################
if __name__ == '__main__':

    print("\nInteractive Serial Console\n")

    # Handle Ctrl+C
    signal.signal(signal.SIGINT, signal_handler)

    timestamp = False

    # Check for correct number of arguments
    if len(sys.argv) < 2:
        print("Usage: " + sys.argv[0] + " DEVICE [BAUD_RATE] [-t]\n")
        sys.exit(1)

    DEVICE = str(sys.argv[1])  # Serial device name

    if len(sys.argv) < 3:
        BAUD_RATE = 9600

    if len(sys.argv) >= 3:
        if sys.argv[2] == "-t":
            timestamp = True  # Use time stamps
            BAUD_RATE = 9600  # Serial baud rate
        else:
            BAUD_RATE = sys.argv[2]

    if len(sys.argv) >= 4:
        if sys.argv[3] == "-t":
            timestamp = True

    # System-wide lock ensures mutually exclusive access to the serial port
    lock = ILockE(DEVICE, timeout=600)

    # Initialize the serial port
    try:
        with lock:
            ser = serial.Serial(DEVICE, BAUD_RATE, timeout=0.1)
        print("Connected to " + DEVICE + " at " + str(BAUD_RATE) + " baud")
        print("Waiting for user input (press Ctrl+C to exit)...\n")
    except:
        print("Failed to connect to " + DEVICE)
        sys.exit(1)

    # Run receive routine as a thread
    terminate = False
    sema = Semaphore()
    thread = Thread(target=rx_thread)
    thread.start()

    while 1:
        sleep(0.1)
        tx = sys.stdin.readline()
        rx = ""

        sema.acquire()
        with lock:
            write(tx)
            rx = read()
        sema.release()

        if rx:
            if timestamp:
                ts = strftime("%Y-%m-%d %H:%M:%S %Z\r\n", gmtime())
            else:
                ts = ""
            sys.stdout.write(ts + rx)

        if terminate:
            thread.join()
            sys.exit(0)
