#!/bin/sh

USER="$1";
HOST="$2";

# echo -n does not print a newline
echo -n "Enter your new password: "
# read -s does not emit characters, silent mode
read -s PASS 
echo "CHANGE PASSWORD '$USER'@'$HOST' = password('"$PASS"');"
