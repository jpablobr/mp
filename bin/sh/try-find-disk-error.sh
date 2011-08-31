#!/bin/sh
# Takes in list of mounted disks, and reads files to attempt to replicate disk errors
#
# ./try-find-disk-error.sh [/path/to/mounted/disk1] {[/path/to/mounted/disk2], ...}
#
# Bryan Smith - Monday June 2 2008

# Make sure user specified parameters
if [ $# -ne 0 ]; then

# Iterate each argument, which we expect to be a directory
while [ $# -gt 0 ]; do

# Grab next argument, which should be a directory
NEXT_DIR=$1
shift

echo
echo '-----------------------------------------------------------------'
echo

# Make sure each argument exists and is a directory
if [ ! -d $NEXT_DIR ]; then
echo "$NEXT_DIR does not exist. Skipping."
echo

# Exists, lets test
else
echo "Testing $NEXT_DIR"
echo

# Need to recursively find all items!
CONTENTS=`ls -R1 $NEXT_DIR`
#echo "$CONTENTS"

# Keep track of current directory.
# This will change as recursively iterate
# directories.
CURRENT_DIR="$NEXT_DIR";

for result in $CONTENTS ; do

# Try to match directories, which will end with colons
GREP_DIRECTORY=`echo $result | grep -i "\:\$"`
GREP_RESULT_FOR_DIRECTORY=$?

if [ $GREP_RESULT_FOR_DIRECTORY == 0 ] ; then
# Replace the final colon with a slash so have a path
CURRENT_DIR="${GREP_DIRECTORY/\://}"

# Remove comment to print out when
# changes to new current dir
#echo "---] SET CURRENT DIRECTORY: $CURRENT_DIR"

else

# Keep last item
LAST_FILE=$NEXT_FILE

# Create next file by prepending path to filename
NEXT_FILE="$CURRENT_DIR$result"

# Skip if last item doesn't exist. This happens on first
# run since no last file and every odd run after that.
if [ ! -z $LAST_FILE ]; then

#echo "last=$LAST_FILE; next=$NEXT_FILE"

# Do a diff. Might trigger read errors
diff $NEXT_FILE $LAST_FILE ] /dev/null 2]&1

# Don't need to read same file twice. Set next file to blank
# to skip diff next time around.
# This will effectively run a diff every two loops, comparing everything
# on disk.
NEXT_FILE=""
fi
fi

done
fi

# Give user opportunity to notice current iteration
sleep 3

done # Iterating each argument

echo
echo '-----------------------------------------------------------------'
echo

# Print usage message when no arguments
else
echo
echo 'No arguments provided.'
echo 'Usage: ./try-find-disk-error.sh [/path/to/mounted/disk1] {[/path/to/mounted/disk2], ...}'
echo
echo 'Description: tries to find a bad disk among multiple mounted disk by extensively reading (diff on each file). The arguments are simply directories, and do not necessarily need to be on separate disks, though that\'s the intended purpose.'
echo

exit 1
fi