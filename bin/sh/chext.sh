#!/usr/bin/env bash

if [ $# -ne 2 ]; then
    echo "usage: $0 oldext newext"
    exit 1
fi

find . -type f -name "*.$1" | while read i
do
    mv -v "$i" "${i%%.$1}.$2"
done
