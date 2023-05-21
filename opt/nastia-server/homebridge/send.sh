#!/bin/bash
#
# KHr

CMD="$1"
DEV="$2"

echo "$CMD" > "/tmp/serial-daemon-in-$DEV"

sleep 2

head -n1 "/tmp/serial-daemon-out-$DEV"

result=$(head -n1 "/tmp/serial-daemon-out-$DEV" | grep "$CMD")

if [[ -n "$result" ]]; then
  echo "Success"
  exit 0
else
  echo "Failure"
  exit 1
fi

