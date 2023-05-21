#!/bin/bash
#
# KHr

CMD="$1"

echo "$CMD" > "/tmp/serial-daemon-in-dev-rfcomm0"

sleep 1

result=$(head -n1 "/tmp/serial-deamon-out-dev-rfcomm0" | grep "$CMD")

if [[ -n "$result" ]]; then
  echo "Success"
  exit 0
else
  echo "Failure"
  exit 1
fi

