#!/bin/sh

usage () {
  echo Usage:
  echo mysql-grant_user.sh USER HOST
  exit 1
}

if [ -z $1 ] || [ -z $2 ]; then
  usage
fi

USER="$1"
HOST="$2"

# echo -n does not print a new-line
echo -n "Enter the new password for ${USER}: "
# read -e does not emit characters
read -e PASS
echo "GRANT USAGE ON *.* TO '${USER}'@'${HOST}' IDENTIFIED BY password('${PASS}');"
