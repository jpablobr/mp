#!/usr/bin/env bash
# Clear $? by doing something that always succeeds
echo > /dev/null

while [ "$?" -eq "0" ]; do
    $*
done

