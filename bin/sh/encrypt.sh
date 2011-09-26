#!/bin/sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Tars, compresses and encrypts a file or directory.
#
# Note that passphrases are handled by commands and hence accessible in history. 
# Do not use in multi-user environments with very sensitive data.
#
# Bryan Smith - bryanesmith@gmail.com
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# Check parameters
if [ "$#" -ne 2 ]; then
  echo "Expecting two arguments: (i) path to directory and (ii) passphrase"
  exit 1
fi

# Remove trailing slash, if one
Dir=`echo "$1" | awk '{sub(/\/$/,"");print}'`
echo "For directory: $Dir"

# Check for file. If already exists, would block script waiting for confirmation
if [ -e "$Dir.tar.gz.gpg" ]; then
   echo "$Dir.tar.gz.gpg already exists. Aborting."
   exit 2
fi

Passphrase=$2

# Archive input
tar cvf "$Dir.tar" $Dir
TarExit=$?

if [ "$TarExit" -ne "0" ]; then
  echo "tar command exited with non-zero code $TarExit"
  exit $TarExit
fi

# Compress input
gzip "$Dir.tar"
GzipExit=$?

if [ "$GzipExit" -ne "0" ]; then
   echo "gzip command exited with non-zero command $GzipExit"
   exit $GzipExit
fi

# Encrypt input
echo "$Passphrase" | gpg --passphrase-fd 0 --no-tty --symmetric "$Dir.tar.gz"
GpgExit=$?

if [ "$GpgExit" -ne "0" ]; then
   echo "gpg command exited with non-zero command $GpgExit"
   exit $GpgExit
fi

# Remove tar archive (artifact of shell script)
rm "$Dir.tar.gz"

