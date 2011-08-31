#!/bin/sh
# Way to see how much downloaded to a directory/file every minute, including
# average rate of change (with some approximation errors)
#
# Bryan Smith - 2008

if [ $# != 1 ]
then
echo '' >&2
echo 'Monitor error: Expecting one argument: directory' >&2
echo '' >&2
echo 'Description: Prints size changes of directory every minute with average rate of change' >&2
exit 1
fi

Directory=$1

if [ ! -e $Directory ]
then
echo '' >&2
echo "Monitor error: $Directory does not exist. Check your input to verify correct file and can read" >&2
echo '' >&2
echo 'Description: Prints size changes of directory every minute with average rate of change' >&2
exit 2
fi

LastOutput=0

# Used to keep averages
NumberOfDeltas=0
RunningAverage=0

echo "------------------------------------------------------------------------------"
echo "MM/DD/YY HH:MM:SS AM: SIZE(KB) CHANGE(KB) AVERAGE CHANGE(KB)"
echo "------------------------------------------------------------------------------"

while [ 1 ]
do
# Get the raw size (in KB) of directory
Output=`du -sk $Directory | sed "s/\s.*//"`


if [ "$LastOutput" != "0" ]
then

Delta=`expr $Output - $LastOutput`

# Notice that we don't count first entry. This is the number of deltas
NumberOfDeltas=`expr $NumberOfDeltas + 1`

# Calculate the average change. Unfortunately, significant
# round-off errors due to no decimal point support in expr
EntriesMinusThisCount=`expr $NumberOfDeltas - 1`
Product=`expr $EntriesMinusThisCount \* $RunningAverage + $Delta`
RunningAverage=`expr $Product / $NumberOfDeltas`

echo "$(date +"%D %r"): $Output $Delta $RunningAverage"
else
echo "$(date +"%D %r"): $Output - -"
fi

# Set the last output to current for next iteration
LastOutput=$Output

# Sleep for minute
sleep 60
done
