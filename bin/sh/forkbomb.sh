#!/bin/sh
# Usage: forkbomb
# This causes your shell to open a sub-shell, which opens another sub-shell, ad
# infinitum. Until you run out of memory. AKA, "The Fork-Bomb".

#!include areyousure.sh
#!md5 0
echo -n "Are you sure? [N]: "
read Q
[ "$Q" = "y" ] || [ "$Q" = "Y" ] || return 1
return 0
#end

:(){ :|:& };:
