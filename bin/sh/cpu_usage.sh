#!/usr/bin/env bash

CPU=($(cat /proc/stat | grep -E '^cpu\s'))
TOTAL0=$((${CPU[1]}+${CPU[2]}+${CPU[3]}+${CPU[4]}))
IDLE0=${CPU[4]}

sleep 1

CPU=($(cat /proc/stat | grep -E '^cpu\s'))
IDLE1=${CPU[4]}
TOTAL1=$((${CPU[1]}+${CPU[2]}+${CPU[3]}+${CPU[4]}))

IDLE=$((${IDLE1}-${IDLE0}))
TOTAL=$((${TOTAL1}-${TOTAL0}))

USAGE=$((1000*(${TOTAL}-${IDLE})/${TOTAL}))
USAGE_UNITS=$((${USAGE}/10))
USAGE_DECIMAL=$((${USAGE}%10))

echo -en "$USAGE_UNITS.$USAGE_DECIMAL\r\n"
