#!/bin/sh
# (>>>FILE<<<)
# (>>>DESC<<<)
# Author: (>>>USER_NAME<<<) <(>>>AUTHOR<<<)>
# Created: (>>>CDATE<<<)
# Version: 0.1.0

old_IFS="$IFS"
IFS=:
  echo "-------------------------------------------------------------------------"
  echo "(>>>DESC<<<)"
  echo "-------------------------------------------------------------------------"
  echo "---"
  read str
IFS=$old_IFS