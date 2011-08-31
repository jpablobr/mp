#!/bin/bash
# Recursively look at paths for files and report if find
# any duplicates. Used to look for potential problems in
# custom database system, but can be used to find
# duplicate files with the same paths.
#
# A file is considered a duplicate if it has the same
# path in two different directories. Doesn't matter
# if one file is regular and the other directory; they
# are considered duplicates for purposes of this script.
#
# Bryan Smith - 2008

# Make sure there are two parameters at least
if [ $# -lt 2 ]; then
  echo "Must offer at least two paths"
  exit 1
fi

declare -a Directories

# Read all script arguments into Directories array
Index="0"
while [ "$#" -ne "0" ]; do

  Directories[$Index]=$1
  shift

  Index=`expr $Index + 1`
done

EscapePattern='s/\//|/g'

TotalMatches=0

# Keeps track of which directory is being iterated
# in outer loop. Compare with inner loop so
# don't recompare same directories twice.
OuterLoopCounter=0
InnerLoopCounter=0

for Directory in ${Directories[@]}
do

  DateString=`date`
  echo
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  echo "= Checking $Directory"
  echo "= Started at $DateString"
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="

  DirectoryMatches=0

  EscapedDirectory=`echo $Directory | sed $EscapePattern`

  Files=`find $Directory -type f -print`

  for FullPathFile in ${Files}
  do
    EscapedFile=`echo $FullPathFile | sed $EscapePattern`
    RelativeNameFile=`echo $EscapedFile | sed "s/$EscapedDirectory//"`

    InnerLoopCounter=0

    # Need to look for any other directories containing that name
    for CompareDirectory in ${Directories[@]}
    do
      # Don't compare a directory to itself. However, don't need,
      # since below couters will not only skip same directory,
      # will also skip directories that were already compared to directory.
      # if [ $Directory = $CompareDirectory ]
      # then
      # continue
      # fi

      # Any directory at index InnerLoopCounter less than OuterLoopCounter
      # has already been iterated (in the outer loop) and does not need
      # to be checked again.
      #
      # Any directory at index InnerLoopCounter equal to OuterLoopCounter
      # has already been checked and does not need to be checked again.
      if [ $InnerLoopCounter -le $OuterLoopCounter ]
      then
        InnerLoopCounter=`expr $InnerLoopCounter + 1`
        continue
      fi

      CompareEscapedDirectory=`echo $CompareDirectory | sed $EscapePattern`

      CompareFiles=`find $CompareDirectory -type f -print`
      for CompareFullPathFile in ${CompareFiles}
      do
        CompareEscapedFile=`echo $CompareFullPathFile | sed $EscapePattern`

        CompareRelativeNameFile=`echo $CompareEscapedFile | sed "s/$CompareEscapedDirectory//"`

        # Do they match?
        if [ $CompareRelativeNameFile = $RelativeNameFile ]
        then
          # Yes, same paths from different directories
          echo " + Matched files $FullPathFile and $CompareFullPathFile"

          # Increment count for directory
          DirectoryMatches=`expr $DirectoryMatches + 1`
        fi

      done # Iterating each file in other directories,
           # looking for match

      # Update counter for inner loop so can quickly compare
      # against outer loop to avoid rechecking
      # earlier directories
      InnerLoopCounter=`expr $InnerLoopCounter + 1`
    done # Iterating each other directory, recursively
         # searching for regular files

  done # Iterating each file in directory

  echo "Finished $Directory, found $DirectoryMatches matches in other directories."

  # Update total count to include this directory
  TotalMatches=`expr $TotalMatches + $DirectoryMatches`

  # Update counter to keep track of which dir is
  # currently being iterated.
  OuterLoopCounter=`expr $OuterLoopCounter + 1`

done # Iterating each directory, recursively searching
     # for regular files

echo "~ fin, found $TotalMatches matches altogether ~"