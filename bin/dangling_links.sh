#/bin/sh

find ${HEAD} -type l -print | while read TARGET; do
    SRC=$(readlink ${TARGET})
    if [ ! -e ${SRC} ]; then
        echo "BAD LINK: ${SRC} -> ${TARGET}";
    fi
done