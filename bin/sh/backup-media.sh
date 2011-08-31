#!/bin/bash

# ------------------------------------------------------------
# Conditionally backups up mounted media a maximum of once
# a day and performs backup rotation.
# 
# Bryan Smith - bryanesmith at gmail.com.
# Monday October 4 2010
# ------------------------------------------------------------

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# VARIABLES
#   Make any changes here!
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BackupToDir="${HOME}/backups"

BackupFromDir="/media"

Rotate=14

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

usage() {
    cat <<MYUSAGE

USAGE
  ./backup-media.sh [media]

  Where [media] is the name of the directory/file you want to
  backup. (_Not_ the path to the directory. See NOTES for more 
  info)

DESCRIPTION
  Conditionally backups the media to tarball with format:
    
    [media].mm-dd-yyyy.tar.gz

  Only backs up if mounted and this file does not exist.

  This script also rotates. The number of backups kept is a
  variable (default: ${Rotate}).

NOTES
  * This script has variables that set where to backup from 
    (default: ${BackupFromDir}) and where to backup to 
    (default: ${BackupToDir}).


HOW TO SET UP 

    1. Create ${BackupToDir} directory or specify another location to
       store backups in variables

    2. If want to backup from directory other than ${BackupFromDir} (e.g.,
       /mnt), specify different location in variable

    3. If want to change number of backups to keep (default: ${Rotate}), 
       specify different value in variable.

    4. Create a cron job to run this script (with media parameter). I set it
       up to run every 30 minutes.

ERROR CODES
  Since this is a cron job and expects that the media will not be
  mounted most of the time, the only errors occur when the wrong 
  number of arguments are specified or if the backup fails.

MYUSAGE
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

error() {
    if [ "$#" -eq "2" ]; then
        echo
        echo "ERROR: $2"
    fi

    usage

    exit $1
} 

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

rotateMediaInPwd() {

  Media=$1

  BackupCount=`ls -n ${Media}.* | wc -l`

  for Backup in `ls -1 ${Media}.*` ; do

    BackupCount=`ls -1 ${Media}.* | wc -l`
    
    if [ "$BackupCount" -le "$Rotate" ]; then
      break
    fi

    echo "--- Removing ${Backup} ---"
    rm $Backup

  done # while: rotate
  
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

if [ "$#" -ne "1" ]; then
  error 1
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Media=$1

BackupFrom="$BackupFromDir/$Media"

BackupTo=$Media.`date +"%Y-%m-%d"`
BackupToTar="${BackupTo}.tar"
BackupToTarball="${BackupToTar}.gz"


if [ -e $BackupFrom ]; then

  cd $BackupToDir
  
  if [ ! -e "${BackupToTarball}" ]; then

    if [ "$?" -ne "0" ]; then

      error $? "Could not change to directory $BackupToDir. Check exists/permissions."

    fi
    
    cp -r $BackupFrom $BackupTo

    if [ "$?" -ne "0" ]; then

      rm -rf $BackupTo
      error $? "Copy from $BackupFrom to $BackupTo failed."

    fi

    tar cvf $BackupToTar $BackupTo > /dev/null
    gzip $BackupToTar > /dev/null

    if [ -e $BackupToTar ]; then
      rm -rf $BackupToTar
    fi

    rm -rf $BackupTo

  fi # if: backup doesn't already exist

  rotateMediaInPwd $Media

fi # if: media mounted

