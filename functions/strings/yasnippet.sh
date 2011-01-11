#!/usr/bin/env bash

for f in *; do
    if [[ $f =~ ".yasnippet" ]] ; then
        echo $f
    else
        mv $f $f.yasnippet
        echo $f
    fi
    # chmod -wx $f
done
echo "Files modifieded"