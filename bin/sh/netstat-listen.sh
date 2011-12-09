#!/bin/sh

netstat -natp | \
grep --color=never "LISTEN"
