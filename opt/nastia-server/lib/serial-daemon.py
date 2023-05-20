#!/usr/bin/env python
#
# Serial port daemon, sends commands and check the response
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
import sys
import time
import signal
import os
import traceback

# Current directory where this script is located
DIR = os.path.dirname(os.path.abspath(__file__))

# Print info log message
def info_log ( text ):
  global LOG
  print (text)
  os.popen ( DIR + "/infoLog.sh \"" + text + "\" '" + LOG + "' '' 'cd'" )


# Print warning log message
def warning_log ( text ):
  global LOG
  print ("[WARNING] " + text)
  os.popen ( DIR + "/warningLog.sh \"" + text + "\" '" + LOG + "' '' 'cd'" )


# Print error log message
def error_log ( text ):
  global LOG
  print ("[ERROR] " + text)
  os.popen ( DIR + "/errorLog.sh \"" + text + "\" '" + LOG + "' '' 'cd'" )




# Read the contents of the receive buffer
def read():
  global DEVICE
  rx = " "
  result = ""
  while len(rx) > 0:
    try:
      rx = ser.readline().decode()
      result = result + rx
    except:
      #print(traceback.format_exc())
      error_log("Failed to read from " + str(DEVICE))
  return result

# Write to the transmit buffer
def write(str):
  global DEVICE
  try:
    ser.write(str.encode())
  except:
    #print(traceback.format_exc())
    error_log("Failed to write to " + str(DEVICE))

# Handle Ctrl+C
def signal_handler(sig, frame):
  global terminate
  terminate = True
  print ("\nInterrupted by user\n")
  time.sleep(0.5)
  raise SystemExit(0)


#################
####  START  ####
#################
if __name__=='__main__':

  # Handle Ctrl+C
  signal.signal(signal.SIGINT, signal_handler)
  terminate = False

  # Check for correct number of arguments
  if len(sys.argv) < 3:
    print("Usage: " + sys.argv[0] + " DEVICE LOG [BAUD_RATE]\n")
    sys.exit()

  DEVICE = sys.argv[1] # Serial device name
  LOG    = sys.argv[2] # Log file prefix

  if len(sys.argv) < 4:
    BAUD_RATE = 9600
  else:
    BAUD_RATE = sys.argv[2] # Serial baud rate

  # System-wide lock ensures mutually exclusive access to the serial port
  lock = ilock.ILock(DEVICE, timeout=600)

  # Initialize the serial port
  try:
    with lock:
      ser = serial.Serial(DEVICE, BAUD_RATE, timeout=0.1)
    info_log ("Connected to " + str(DEVICE) + " at " + str(BAUD_RATE) + " baud")
  except:
    error_log("Failed to connect to " + str(DEVICE))

  in_file  = "/tmp/serial-daemon-in"  + str(DEVICE).replace("/", "-")
  out_file = "/tmp/serial-deamon-out" + str(DEVICE).replace("/", "-")
  print ("Input file: ", in_file)
  print ("Output file:", out_file)

  while 1:

    try:
      input = open(in_file, 'r')
      os.remove(in_file)
    except:
      #print("DBG failed to open")
      #print(traceback.format_exc())
      time.sleep(0.3)
      continue

    tx = input.read()
    print(tx)

    with lock:
      write(tx)
      rx = read()

    if rx:
      print(rx)
      output = open(out_file, 'w')
      output.write(rx)
      output.close()

    if terminate:
      break


