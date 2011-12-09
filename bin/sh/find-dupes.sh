#!/bin/sh

if [ $1 ]; then
  DIR="$1"
  shift
else
  DIR="."
fi

find "$DIR" -type f $* -print0 | \
  xargs -0 md5sum | \
  sort | \
  uniq --all-repeated=prepend -w 32
