#!/usr/bin/env python
#
# Serial port daemon, sends commands and check the response
#
# This version has been adapted for instable rfcoomm serial
# connection on Victron Venus OS
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
import time
import signal
import os
import traceback
import re


# Current directory where this script is located
dir = os.path.dirname(os.path.abspath(__file__))

# Enable transmit/receive logging
TRX_LOG = False


# Print info log message
def info_log(text):
    global dir
    global log
    print(text)
    os.popen(dir + "/infoLog.sh \"" + text + "\" '" + log + "' '' 'cd'")


# Print warning log message
def warning_log(text):
    global dir
    global log
    print("[WARNING] " + text)
    os.popen(dir + "/warningLog.sh \"" + text + "\" '" + log + "' '' 'cd'")


# Print error log message
def error_log(text):
    global dir
    global log
    print("[ERROR] " + text)
    os.popen(dir + "/errorLog.sh \"" + text + "\" '" + log + "' '' 'cd'")


# Print transmit/receive log message
def trx_log(text):
    global log_trx
    if TRX_LOG:
        # Remove empty lines
        text = re.sub(r'\n\s*\n','\n',text,re.MULTILINE)
        print(text)
        os.popen(dir + "/infoLog.sh \"\n" + text + "\" '" + log_trx + "' '' 'd'")


# Read the contents of the receive buffer
def read():
    global dev
    global ser
    rx = " "
    result = ""
    while len(rx) > 0:
        try:
            rx = ser.readline().decode()
            result = result + rx
            time.sleep(0.1)
        except:
            error_log("Failed to read from " + dev)
            raise
    return result


# Write to the transmit buffer
def write(str):
    global dev
    global ser
    try:
        ser.write(str.encode())
    except:
        error_log("Failed to write to " + dev)
        raise

# Handle Ctrl+C
def signal_handler(sig, frame):
    print("\nInterrupted by user\n")
    time.sleep(0.3)
    sys.exit(0)


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

    # Check for correct number of arguments
    if len(sys.argv) < 3:
        print("Usage: " + sys.argv[0] + " <device> <log> [baud rate]\n")
        sys.exit(1)

    dev_short = str(sys.argv[1]).replace("/dev/", "")  # Serial device name without the /dev prefix
    dev = "/dev/" + dev_short  # Serial device name
    log = sys.argv[2]  # Log file prefix
    log_trx = log + "-" + dev_short  # Transmit/receive log

    if len(sys.argv) < 4:
        baud_rate = 9600
    else:
        baud_rate = sys.argv[2]  # Serial baud rate

    in_file = "/tmp/serial-daemon-in-" + dev_short
    out_file = "/tmp/serial-daemon-out-" + dev_short
    print("Input file: ", in_file)
    print("Output file:", out_file)

    try:
        os.remove(out_file)
    except:
        pass

    # System-wide lock ensures mutually exclusive access to the serial port
    lock = ILockE(dev, timeout=600)


    retry = 10
    while retry > 0:
        try:
            with serial.Serial(dev, baud_rate, timeout=0.1) as ser:
                info_log ("Connected to " + dev + " at " + str(baud_rate) + " baud")
                while True:
                    tx  = ""
                    rx  = ""
                    trx = ""

                    try:
                        with open(in_file, 'r') as f:
                            tx = f.read()
                            os.remove(in_file)
                    except:
                        time.sleep(1)

                    if tx:
                        with lock:
                            write(tx)
                            time.sleep(0.2)
                            rx = read()
                        trx = tx + rx

                    if tx and rx:
                        try:
                            with open(out_file, 'w') as f:
                                f.write(rx)
                        except:
                            error_log("Failed to open file" + out_file)

                    if trx:
                        trx_log(trx)

                    retry = 10

        except:
            error_log("Failed to connect to " + dev)
            time.sleep(5)
            retry -= 1

    sys.exit(1)
