#!/bin/bash
#
# Bryan Smith - 2008

if [ "$#" -ne "1" ]
then
echo "Expecting one argument: directory to count files"
exit 1
fi

FileCount=0
Bytes=0

Files=("$1")

# Depth-first search through directories
while [ "${#Files[@]}" -ne "0" ]
do

Current=${Files[0]}

# Shift
Files=(${Files[@]:1})

# Uncomment to see directories printed to standard out
#echo "$Current"

SubfileNames=`ls -1 $Current `

for SubfileName in $SubfileNames
do
Subfile="$Current/$SubfileName"
if [ -d $Subfile ]
then
# Unshift the directory
Files=($Subfile ${Files[@]})
else
# Increment counter for regular file
FileCount=`expr $FileCount + 1`;

FileSize=`du -sb $Subfile | sed "s/\s.*//"`
Bytes=`expr $Bytes + $FileSize`
fi
done
done

echo "Total for regular (non-directory) files in $1"
echo " Files: $FileCount"
echo " Size: $Bytes"