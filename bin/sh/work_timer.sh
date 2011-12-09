#!/bin/sh
# Timer for productivity and wellness
# Take breaks and get back to work in a timely fashion!
#
# Uses Libnotify and Dbus to put messages in your face.

if [ -z $1 ]; then
  echo "Enter the number of minutes you want the timer to cycle."
  echo "timer.sh WORK_TIME BREAK_TIME [BREAK_MSG] [WORK_MSG]"
  exit 1
fi

VERBOSE="1"

WORK_LIMIT="$1"
BREAK_LIMIT="$2"

if [ -n "$3" ]; then
  MSG1="$3"
else
  MSG1="Take a break..."
fi

if [ -n "$4" ]; then
  MSG2="$4"
else
  MSG2="Back to work..."
fi

if [ -n $VERBOSE ]; then
  echo `date` " Timer started"
fi

while true; do
  sleep ${WORK_LIMIT}m
  if [ -n $VERBOSE ]; then
    echo `date` " Work Timer Triggered"
  fi
  notify-send -u critical -t 15000 "${MSG1}"
  sleep ${BREAK_LIMIT}m
  if [ -n $VERBOSE ]; then
    echo `date` " Break Timer Triggered"
  fi
  notify-send -u critical -t 15000 "${MSG2}"
done
