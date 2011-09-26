#/usr/bin/sh

# Recursive copy that staggers so if fails, directory can remount.
# Used to get data off disk that unmounts and remounts sporadically.
#
# Will generate a shell script for failed directories.
#
# Bryan Smith Sat Mar 15 2008

if [ $# != 3 ]; then 
  echo "USAGE: ircp.sh   ";
  echo "Where  can be \"false\" or \"true\", without the quotes"
  
  exit 2 
fi

SOURCE=$1
DEST=$2
USESUDO=$3

# Make sure exists and are directories
BAD_ARGS=0

if [ ! -d $1 ]; then
  echo "ERROR: verify that source $SOURCE exists and is a directory"
  BAD_ARGS=1
fi

if [ ! -d $2 ]; then
  echo "ERROR: verify that destination $DEST exists and is a directory"
  BAD_ARGS=1
fi

if [ $BAD_ARGS != 0 ]; then
  exit 3
fi

# Make sure user provided valid use sudo? variable
if [ $USESUDO = 'true' ]; then
  echo "Using sudo..."
elif [ $USESUDO = 'false' ]; then
  echo "Not using sudo..."
else
  echo "Expecting true or false, found $USESUDO."
  exit 4
fi

echo ""
echo "Incrementally and recursively copying all files from $SOURCE to $DEST"
echo ""

# Clear the fail file log
FAIL_FILE="./ircp.failed-copies"
echo 'Tool started at '`date` > $FAIL_FILE

# Create a shell script that will download failed items
FAIL_SHELL='./ircp.failed.sh'
echo '#/usr/bin/sh' > $FAIL_SHELL
echo '# '`date` >> $FAIL_SHELL

chmod +x $FAIL_SHELL

echo "All failed copies will be recorded at $FAIL_FILE"
echo "  Also, generating shell script with commands to reattempt all failed items at $FAIL_SHELL"

# For each file (directory or normal), recursively copy to dest and sleep
for file in $1/* ; do
  #echo "Copying $file to $DEST"

  if [ $USESUDO = 'true' ]; then
    sudo cp -r $file $DEST
  else
    cp -r $file $DEST
  fi

  # Check whether exitted normally. If not, write failure to failure file
  #echo "Copy exited with value $?"  
  COPY_STATUS=$?
  if [ $COPY_STATUS != 0 ]; then
    # Add entry to fail log
    echo "Failed to copy $file to $DEST" >> $FAIL_FILE
    echo "cp exitted with code $COPY_STATUS" >> $FAIL_FILE
    echo "" >> $FAIL_FILE

    # Add entry to shell script
    echo "echo \"Copying next file/directory $file\"" >> $FAIL_SHELL
    if [ $USESUDO = 'true' ]; then
      echo "sudo cp -r $file $DEST" >> $FAIL_SHELL
    else
      echo "cp -r $file $DEST" >> $FAIL_SHELL
    fi
    echo "sleep 1" >> $FAIL_SHELL
    echo "" >> $FAIL_SHELL 
  fi

  # Sleep one second perchance drive unmounts then remounts
  sleep 1
done