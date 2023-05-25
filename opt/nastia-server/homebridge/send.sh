#!/bin/bash
#
# KHr

CMD="$1"
DEV="$2"

echo "$CMD" > "/tmp/serial-daemon-in-$DEV"
sleep 1
exit 1


