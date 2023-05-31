#!/usr/bin/env python
#
# Serial Port Console
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
#import traceback
from threading import Thread, Semaphore
from time import sleep, gmtime, strftime
from optparse import OptionParser


# Read the contents of the receive buffer
def read():
    global device
    global ser
    global terminate
    rx = " "
    result = ""
    while len(rx) > 0:
        try:
            rx = ser.readline().decode()
            result = result + rx
        except:
            print("Failed to read from", device)
            terminate = True
            break
    return result


# Write to the transmit buffer
def write(str):
    global device
    global ser
    global terminate
    try:
        ser.write(str.encode())
    except:
        print("Failed to write to", device)
        terminate = True


# Handle Ctrl+C
def signal_handler(sig, frame):
    global terminate
    global thread
    print("\nInterrupted by user\n")
    terminate = True
    thread.join()
    sys.exit(0)


# Timestamp generator
def ts():
    global timestamp
    if timestamp:
        return strftime("%Y-%m-%d %H:%M:%S %Z:\r\n", gmtime())
    else:
        return ""


# Run receiving loop as a thread
def rx_thread():
    global sema
    global terminate
    while 1:
        sleep(0.1)
        sema.acquire()
        with lock:
            rx = read()
        sema.release()
        if rx:
            sys.stdout.write(ts() + rx)
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

    # Handle Ctrl+C
    signal.signal(signal.SIGINT, signal_handler)

    print("\nInteractive Serial Console\n")

    parser = OptionParser("Usage: %prog <device> [baud rate] [options]")

    parser.add_option("-t", "--timestamp" ,
                      action="store_true",
                      dest="timestamp",
                      default=False,
                      help="Add time stamps to console output")

    (options, args) = parser.parse_args()

    timestamp = options.timestamp

    # Check for correct number of arguments
    if len(args) < 1:
        parser.print_help()
        sys.exit(1)

    device = str(args[0])  # Serial device name

    if len(args) < 2:
        baud_rate = 9600
    else:
        baud_rate = args[1]

    # System-wide lock ensures mutually exclusive access to the serial port
    lock = ILockE(device, timeout=600)

    # Initialize the serial port
    try:
        with lock:
            ser = serial.Serial(device, baud_rate, timeout=0.1)
        print("Connected to " + device + " at " + str(baud_rate) + " baud")
        print("Waiting for user input (press Ctrl+C to exit)...\n")
    except:
        print("Failed to connect to " + device)
        #traceback.print_exc()
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
            sys.stdout.write(ts() + rx)

        if terminate:
            thread.join()
            sys.exit(0)
