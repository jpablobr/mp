#!/bin/bash

# Recursively counts number of lines of Java code in a directory.
# Bryan Smith on Mon April 7 2008

if [ $# != 1 ]; then
echo "USAGE: recursiveLinesJavaCodeCount.sh [directory]";
exit 1
fi

SOURCE=$1

if [ ! -d $1 ]; then
echo "ERROR: verify that source $SOURCE exists and is a directory"
exit 2
fi

# Get all results
LIST_RESULTS=`ls -R1 $SOURCE`

# Keep track of current directory.
# This will change as recursively iterate
# directories.
CURRENT_DIR=$SOURCE;

FILE_COUNT=0
LINE_COUNT=0

for result in $LIST_RESULTS ; do
# Remove comment to check next line of output
#echo "$result";

# Try to match directories, which will end with colons
GREP_DIRECTORY=`echo $result | grep -i "\:\$"`
GREP_RESULT_FOR_DIRECTORY=$?

# Remove comment to check return code
#echo "-> $GREP_RESULT_FOR_DIRECTORY"

# Try to match java files, which end with .java
GREP_JAVA_FILE=`echo $result | grep -i "\.\(java\|jsp\|fx\)\$"`
GREP_RESULT_FOR_JAVA_FILE=$?

# Remove comment to check return code
#echo "-> $GREP_RESULT_FOR_JAVA_FILE"

# If matched the grep, so is a directory,
# then update current dir
if [ "$GREP_RESULT_FOR_DIRECTORY" -eq "0" ]; then
  # Replace the final colon with a slash so have a path
  CURRENT_DIR="${GREP_DIRECTORY/\://}"

  # Remove comment to print out when
  # changes to new current dir
  #echo "---> SET CURRENT DIRECTORY: $CURRENT_DIR"

# If match the grep, so is a Java file,
# then deal with next Java file
elif [ "$GREP_RESULT_FOR_JAVA_FILE" -eq "0" ]; then
  JAVA_PATH="$CURRENT_DIR$GREP_JAVA_FILE"

  # Uncomment to print out when finds next Java file
  #echo "---> FOUND JAVA FILE: $JAVA_PATH"

  # Increment number of files
  FILE_COUNT=`expr $FILE_COUNT + 1`

  FILE_LINE_COUNT=`cat $JAVA_PATH | wc -l`
  LINE_COUNT=`expr $LINE_COUNT + $FILE_LINE_COUNT`
fi
done

echo "Found $FILE_COUNT Java source files with $LINE_COUNT lines."
