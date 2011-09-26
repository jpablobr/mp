#!/bin/sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Decrypts, decompresses and untars a file or directory.
#
# Note that passphrases are handled by commands and hence accessible in history. 
# Do not use in multi-user environments with very sensitive data.
#
# Bryan Smith - bryanesmith@gmail.com
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# Check parameters
if [ "$#" -ne 2 ]; then
  echo "Expecting two arguments: (i) path to .tar.gz.gpg file and (ii) passphrase"
  exit 1
fi

# Parse out various file names
GpgFile=$1
GzipFile=`echo "$GpgFile" | awk '{sub(/\.gpg$/,"");print}'`
TarFile=`echo "$GzipFile" | awk '{sub(/\.gz$/,"");print}'`
Passphrase=$2

# Decrypt input
echo "$Passphrase" | gpg --passphrase-fd 0 --no-tty --decrypt $GpgFile > $GzipFile
GpgExit=$?
if [ "$GpgExit" -ne "0" ]; then
   echo "gpg command exited with non-zero command $GpgExit"
   exit $GpgExit
fi

# Uncompress input
gunzip $GzipFile
GunzipExit=$?
if [ "$GunzipExit" -ne "0" ]; then
   echo "gunzip command exited with non-zero command $GunzipExit"
   exit $GunzipExit
fi

# Unarchive input
tar xvf $TarFile
TarExit=$?
if [ "$TarExit" -ne "0" ]; then
   echo "tar command exited with non-zero command $TarExit"
   exit $TarExit
fi

# Remove the tar file (artifact of shell script)
rm $TarFile

