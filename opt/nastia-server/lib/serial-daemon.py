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


# Print transmit/receive log message
def trx_log ( text ):
  global LOG_TRX
  print (text)
  os.popen ( DIR + "/infoLog.sh \"\n" + text + "\" '" + LOG_TRX + "' '' 'd'" )



# Read the contents of the receive buffer
def read():
  global DEV
  global ser
  rx = " "
  result = ""
  while len(rx) > 0:
    try:
      rx = ser.readline().decode()
      result = result + rx
      time.sleep (0.1)
    except:
      #print(traceback.format_exc())
      error_log("Failed to read from " + DEV)
      exit_failure ()
  return result


# Write to the transmit buffer
def write(str):
  global DEV
  global ser
  try:
    ser.write(str.encode())
  except:
    #print(traceback.format_exc())
    error_log("Failed to write to " + DEV)
    exit_failure ()


# Handle Ctrl+C
def signal_handler(sig, frame):
  global terminate
  terminate = True
  print ("\nInterrupted by user\n")
  time.sleep (0.3)
  sys.exit (0)


# Exit due to failure
def exit_failure ():
  global status_file
  try:
    os.remove(status_file)
  except:
    pass
  sys.exit (1)



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

  DEV_SHORT = str(sys.argv[1]).replace("/dev/", "")  # Serial device name without the /dev prefix
  DEV       = "/dev/" + DEV_SHORT                    # Serial device name
  LOG       = sys.argv[2]                            # Log file prefix
  LOG_TRX   = LOG + "-" + DEV_SHORT                  # Transmit/receive log

  if len(sys.argv) < 4:
    BAUD_RATE = 9600
  else:
    BAUD_RATE = sys.argv[2]  # Serial baud rate

  in_file     = "/tmp/serial-daemon-in-"     + DEV_SHORT
  out_file    = "/tmp/serial-daemon-out-"    + DEV_SHORT
  status_file = "/tmp/serial-daemon-status-" + DEV_SHORT
  print ("Input file: ", in_file)
  print ("Output file:", out_file)
  print ("Status file:", status_file)

  try:
    os.remove(out_file)
  except:
    pass


  # System-wide lock ensures mutually exclusive access to the serial port
  lock = ilock.ILock(DEV, timeout=600)

  # Initialize the serial port
  try:
    with lock:
      ser = serial.Serial(DEV, BAUD_RATE, timeout=0.1)
    info_log ("Connected to " + DEV + " at " + str(BAUD_RATE) + " baud")
  except:
    error_log("Failed to connect to " + DEV)
    exit_failure ()


  while 1:
    if terminate:
      break

    try:
      input = open(in_file, 'r')
      os.remove(in_file)
    except:
      #print("DBG failed to open")
      #print(traceback.format_exc())
      time.sleep (0.3)
      continue

    tx  = input.read()
    trx = tx

    try:
      with lock:
        write(tx)
        rx  = read()
        trx = trx + rx
    except:
      pass

    if rx:
      try:
        output = open(out_file, 'w')
        output.write(rx)
        output.close()
      except:
        error_log("Failed to open file" + out_file)

    trx_log(trx)
