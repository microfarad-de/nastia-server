#!/usr/bin/env python
#
# Serial port daemon, sends commands and checks the response
#
# This version has been adapted for instable rfcomm serial
# connection on Victron Venus OS
#
# This source file is part of the following repository:
# http://www.github.com/microfarad-de/nastia-server
#
# Please visit:
#   http://www.microfarad.de
#   http://www.github.com/microfarad-de
#
# Copyright (C) 2026 Karim Hraibi (khraibi@gmail.com)
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

import os
import sys
import time
import signal
import re
import errno
import argparse

import serial  # pip install pyserial

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from lib.ulock import ULock, ULockException


# Current directory where this script is located
dir = os.path.dirname(os.path.abspath(__file__))


# Configuration parameters
TRX_LOG     = False  # Enable transmit/receive logging
POLL_RX     = True   # Poll srial port for received data
RETRY_COUNT = 2      # Number of connection retries


# Global state used by helpers
dev = None
log = None
log_trx = None
terminate = False
ser = None


# Print info log message
def info_log(text: str) -> None:
    global dir, log
    print(text)
    os.popen(f"{dir}/infoLog.sh \"{text}\" '{log}' '' 'cd'")


# Print warning log message
def warning_log(text: str) -> None:
    global dir, log
    print(f"[WARNING] {text}")
    os.popen(f"{dir}/warningLog.sh \"{text}\" '{log}' '' 'cd'")


# Print error log message
def error_log(text: str) -> None:
    global dir, log
    print(f"[ERROR] {text}")
    os.popen(f"{dir}/errorLog.sh \"{text}\" '{log}' '' 'cd'")


# Print transmit/receive log message
def trx_log(text: str) -> None:
    global log_trx
    if TRX_LOG:
        # Remove empty lines
        text = re.sub(r"\n\s*\n", "\n", text, flags=re.MULTILINE)
        print(text)
        os.popen(f"{dir}/infoLog.sh \"\n{text}\" '{log_trx}' '' 'd'")


# Read the contents of the receive buffer
def read() -> str:
    global dev, ser
    if ser is None:
        error_log(f"Attempted read but serial port is not open for {dev}")
        return ""

    rx = " "
    result = ""
    while len(rx) > 0:
        try:
            line = ser.readline()
            if not line:
                break
            rx = line.decode(errors="replace")
            result += rx
            time.sleep(0.1)
        except Exception as e:
            raise
    return result


# Write to the transmit buffer
def write(data: str) -> None:
    global dev, ser
    if ser is None:
        error_log(f"Attempted write but serial port is not open for {dev}")
        raise RuntimeError("Serial port not open")

    try:
        ser.write(data.encode())
    except Exception as e:
        raise


# Handle Ctrl+C
def signal_handler(sig, frame):
    global terminate
    print("\nInterrupted by user\n")
    terminate = True
    # Let the main loop cleanly exit based on `terminate`


# Extends ULock with exception handling
class Lock(ULock):
    def __enter__(self):
        try:
            return super().__enter__()
        except ULockException as e:
            error_log(str(e))
            raise

    def __exit__(self, exc_type, exc_val, exc_tb):
        return super().__exit__(exc_type, exc_val, exc_tb)


#################
####  START  ####
#################
if __name__ == "__main__":

    # Handle Ctrl+C
    signal.signal(signal.SIGINT, signal_handler)

    parser = argparse.ArgumentParser(
        description="Serial port daemon, sends commands and checks the response"
    )

    parser.add_argument(
        "device",
        help="Serial device (e.g. /dev/ttyUSB0, /dev/rfcomm0)",
    )

    parser.add_argument(
        "log_prefix",
        help="Log file prefix",
    )

    parser.add_argument(
        "baud_rate",
        nargs="?",
        type=int,
        default=9600,
        help="Baud rate (default: 9600)",
    )

    args = parser.parse_args()

    dev_short = str(args.device).replace("/dev/", "")  # Serial device name without the /dev prefix
    dev = f"/dev/{dev_short}"       # Serial device name
    log = args.log_prefix           # Log file prefix
    log_trx = f"{log}-{dev_short}"  # Transmit/receive log
    baud_rate = args.baud_rate      # Serial baud rate

    in_file = f"/tmp/serial-daemon-in-{dev_short}"
    out_file = f"/tmp/serial-daemon-out-{dev_short}"
    print("Input file: ", in_file)
    print("Output file:", out_file)

    try:
        os.remove(out_file)
    except FileNotFoundError:
        pass
    except OSError as e:
        warning_log(f"Failed to remove old output file {out_file}: {e}")

    # System-wide lock ensures mutually exclusive access to the serial port
    lock = Lock(dev, timeout=45, stale_timeout=30)

    tx = ""
    retry = RETRY_COUNT

    while retry > 0 and not terminate:
        try:
            # Open serial port
            with serial.Serial(dev, baud_rate, timeout=0.1) as ser:
                info_log(f"Connected to {dev} at {baud_rate} baud")

                while not terminate:
                    rx = ""
                    trx = ""

                    # Try to read pending command from input file
                    try:
                        with open(in_file, "r") as f:
                            tx = f.read()
                        os.remove(in_file)
                    except FileNotFoundError:
                        # No command yet; poll again
                        time.sleep(1)
                    except OSError as e:
                        warning_log(f"Failed to read or remove input file {in_file}: {e}")
                        time.sleep(1)


                    with lock:
                        if tx:
                            write(tx)
                            time.sleep(0.2)
                        if tx or POLL_RX:
                            rx = read()
                        trx = tx + rx


                    if rx:
                        try:
                            with open(out_file, "w") as f:
                                f.write(rx)

                            os.chmod(out_file, 0o666)   # rw-rw-rw-

                        except OSError as e:
                            error_log(f"Failed to open file {out_file}: {e}")

                    if trx:
                        trx_log(trx)
                        retry = RETRY_COUNT  # Reset retry counter on successul transmit/receive

                    tx = ""

        except serial.SerialException as e:
            if terminate:
                sys.exit(0)
            else:
                info_log(f"Serial error while connected to {dev}: {e}")
                time.sleep(5)
                retry -= 1
        except Exception as e:
            if terminate:
                sys.exit(0)
            else:
                error_log(f"Unexpected error with {dev}: {e}")
                time.sleep(5)
                retry -= 1

    sys.exit(0 if terminate else 1)

